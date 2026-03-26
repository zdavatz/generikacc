//
//  PrescriptionScannerViewController.swift
//  Generika
//
//  Copyright (c) 2026 ywesee GmbH. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

// MARK: - Result

struct PrescriptionScanResult {
    var ePrescription: EPrescription?

    // OCR-extracted fields (supplement QR data)
    var medications: [(name: String, dosage: String)] = []
    var ahvNumber: String = ""
    var physicianFullName: String = ""
    var physicianTitle: String = ""       // e.g. "Prof. Dr. med."
    var hospitalName: String = ""
    var departmentName: String = ""
    var patientStreet: String = ""
    var patientZip: String = ""
    var patientCity: String = ""
    var patientPhone: String = ""
    var zsrNumber: String = ""
    var prescriptionDate: String = ""
}

// MARK: - Delegate

protocol PrescriptionScannerDelegate: AnyObject {
    func prescriptionScanner(_ scanner: PrescriptionScannerViewController, didScan result: PrescriptionScanResult)
    func prescriptionScannerDidCancel(_ scanner: PrescriptionScannerViewController)
}

// MARK: - ViewController

class PrescriptionScannerViewController: UIViewController {

    weak var delegate: PrescriptionScannerDelegate?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "prescriptionScannerQueue")
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!

    private var qrFound = false
    private var qrPayload: String?
    private var qrIndicatorLayer = CAShapeLayer()

    private let statusLabel = UILabel()
    private let captureButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
        super.viewDidDisappear(animated)
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Camera Setup

    private func setupCamera() {
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Video output for live QR detection
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Photo output for high-res capture
        photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        // QR indicator overlay
        qrIndicatorLayer.strokeColor = UIColor.systemGreen.cgColor
        qrIndicatorLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.1).cgColor
        qrIndicatorLayer.lineWidth = 3
        view.layer.addSublayer(qrIndicatorLayer)
    }

    private func setupUI() {
        // Cancel button
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("Abbrechen", for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 18)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelBtn)

        // Status label
        statusLabel.text = "Rezept in den Rahmen halten"
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Capture button (shutter)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
        captureButton.setImage(UIImage(systemName: "circle.inset.filled", withConfiguration: config), for: .normal)
        captureButton.tintColor = .white
        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        view.addSubview(captureButton)

        // Document frame guide
        let frameGuide = UIView()
        frameGuide.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        frameGuide.layer.borderWidth = 2
        frameGuide.layer.cornerRadius = 12
        frameGuide.translatesAutoresizingMaskIntoConstraints = false
        frameGuide.isUserInteractionEnabled = false
        view.addSubview(frameGuide)

        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.6),

            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // A4-ish frame guide (roughly 3:4 aspect)
            frameGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameGuide.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            frameGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.88),
            frameGuide.heightAnchor.constraint(equalTo: frameGuide.widthAnchor, multiplier: 1.3),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        session.stopRunning()
        delegate?.prescriptionScannerDidCancel(self)
    }

    @objc private func captureTapped() {
        captureButton.isEnabled = false
        statusLabel.text = "Wird verarbeitet\u{2026}"

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Live QR Detection

extension PrescriptionScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if qrFound { return }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])

        guard let results = request.results, !results.isEmpty else {
            DispatchQueue.main.async {
                self.qrIndicatorLayer.path = nil
            }
            return
        }

        for obs in results {
            if let payload = obs.payloadStringValue,
               payload.hasPrefix("CHMED16A") || payload.contains("eprescription.hin.ch") {
                qrFound = true
                qrPayload = payload

                DispatchQueue.main.async {
                    // Highlight the QR code
                    let box = obs.boundingBox
                    let viewW = self.view.bounds.width
                    let viewH = self.view.bounds.height
                    let rect = CGRect(
                        x: box.origin.x * viewW,
                        y: (1 - box.origin.y - box.height) * viewH,
                        width: box.width * viewW,
                        height: box.height * viewH
                    )
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                    self.qrIndicatorLayer.path = path.cgPath

                    self.statusLabel.text = "QR-Code erkannt \u{2705}\nJetzt aufnehmen f\u{00FC}r OCR"
                }
                break
            }
        }
    }
}

// MARK: - Photo Capture + OCR

extension PrescriptionScannerViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        session.stopRunning()

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.statusLabel.text = "Fehler beim Aufnehmen"
                self.captureButton.isEnabled = true
            }
            return
        }

        // Run QR detection + OCR on the captured photo
        let group = DispatchGroup()
        var ocrTexts: [(String, CGRect)] = []
        var capturedQRPayload: String? = self.qrPayload  // from live detection

        // 1) QR detection on photo (if not already found)
        if capturedQRPayload == nil {
            group.enter()
            let qrRequest = VNDetectBarcodesRequest { request, _ in
                defer { group.leave() }
                guard let results = request.results as? [VNBarcodeObservation] else { return }
                for obs in results {
                    if let payload = obs.payloadStringValue,
                       payload.hasPrefix("CHMED16A") || payload.contains("eprescription.hin.ch") {
                        capturedQRPayload = payload
                        break
                    }
                }
            }
            qrRequest.symbologies = [.qr]

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            sessionQueue.async {
                try? handler.perform([qrRequest])
            }
        }

        // 2) OCR on full image
        group.enter()
        let ocrRequest = VNRecognizeTextRequest { request, _ in
            defer { group.leave() }
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            for obs in results {
                if let candidate = obs.topCandidates(1).first, candidate.confidence > 0.3 {
                    ocrTexts.append((candidate.string, obs.boundingBox.standardized))
                }
            }
        }
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.recognitionLanguages = ["de-DE", "fr-FR"]
        ocrRequest.usesLanguageCorrection = true

        let ocrHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        sessionQueue.async {
            try? ocrHandler.perform([ocrRequest])
        }

        // 3) Combine results
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            var result = PrescriptionScanResult()

            // Parse QR code
            if let payload = capturedQRPayload {
                result.ePrescription = EPrescription(chmed16A1String: payload)
            }

            // Parse OCR text
            self.parseOCRTexts(ocrTexts, into: &result)

            self.delegate?.prescriptionScanner(self, didScan: result)
        }
    }

    // MARK: - OCR Text Parsing

    /// Parse OCR text lines to extract structured prescription data.
    /// Lines are sorted top-to-bottom based on bounding box Y coordinates.
    private func parseOCRTexts(_ texts: [(String, CGRect)], into result: inout PrescriptionScanResult) {
        // Sort top-to-bottom (Vision coordinates: y=0 is bottom, so reverse)
        let sorted = texts.sorted { $0.1.origin.y > $1.1.origin.y }
        let lines = sorted.map { $0.0 }

        // State for medication table parsing
        var inMedicationTable = false
        var currentMedName: String?
        var currentDosage: String?
        var foundMedHeader = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // AHV number: NNN.NNNN.NNNN.NN
            if result.ahvNumber.isEmpty {
                if let range = trimmed.range(of: "\\d{3}\\.\\d{4}\\.\\d{4}\\.\\d{2}", options: .regularExpression) {
                    result.ahvNumber = String(trimmed[range])
                }
            }

            // ZSR number: N followed by digits (e.g. N737201)
            if result.zsrNumber.isEmpty {
                if let range = trimmed.range(of: "ZSR[\\-\\s]*Nr\\.?:?\\s*([A-Z]\\d{4,6})", options: .regularExpression) {
                    let match = String(trimmed[range])
                    // Extract just the number part
                    if let numRange = match.range(of: "[A-Z]\\d{4,6}", options: .regularExpression) {
                        result.zsrNumber = String(match[numRange])
                    }
                }
            }

            // Phone number: Tel.: ...
            if result.patientPhone.isEmpty {
                if let range = trimmed.range(of: "Tel\\.?:?\\s*([\\d\\s\\+]+)", options: .regularExpression) {
                    let match = String(trimmed[range])
                    let phone = match.replacingOccurrences(of: "Tel.:?\\s*", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)
                    if phone.count >= 10 {
                        result.patientPhone = phone
                    }
                }
            }

            // Prescription date: "Rezept vom DD.MM.YYYY"
            if result.prescriptionDate.isEmpty {
                if let range = trimmed.range(of: "\\d{2}\\.\\d{2}\\.\\d{4}", options: .regularExpression),
                   trimmed.lowercased().contains("rezept") {
                    result.prescriptionDate = String(trimmed[range])
                }
            }

            // Patient address: "Strasse Nr, CH-PLZZ Ort" or "Strasse Nr, PLZZ Ort"
            if result.patientStreet.isEmpty {
                // Pattern: line with comma, followed by CH-NNNN or just NNNN
                if let commaIdx = trimmed.firstIndex(of: ",") {
                    let afterComma = String(trimmed[trimmed.index(after: commaIdx)...]).trimmingCharacters(in: .whitespaces)
                    // Check for "CH-8038 Zürich" or "8038 Zürich"
                    if afterComma.range(of: "^(CH-)?\\d{4}\\s+\\S", options: .regularExpression) != nil {
                        let street = String(trimmed[..<commaIdx]).trimmingCharacters(in: .whitespaces)
                        // Only treat as address if it looks like a street (has a number)
                        if street.range(of: "\\d", options: .regularExpression) != nil,
                           !street.contains("AHV"),
                           !street.contains("PID"),
                           !street.contains("FID") {
                            result.patientStreet = street
                            // Extract PLZ and city
                            let cleaned = afterComma.replacingOccurrences(of: "CH-", with: "")
                            if let plzRange = cleaned.range(of: "^\\d{4}", options: .regularExpression) {
                                result.patientZip = String(cleaned[plzRange])
                                let cityPart = String(cleaned[plzRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                                // Remove trailing phone/other info
                                if let commaInCity = cityPart.firstIndex(of: ",") {
                                    result.patientCity = String(cityPart[..<commaInCity]).trimmingCharacters(in: .whitespaces)
                                } else {
                                    result.patientCity = cityPart
                                }
                            }
                        }
                    }
                }
            }

            // Hospital/Clinic name: typically in header, contains "spital", "klinik", "praxis"
            if result.hospitalName.isEmpty {
                let lower = trimmed.lowercased()
                if lower.contains("spital") || lower.contains("klinik") || lower.contains("praxis") || lower.contains("universit") {
                    // Skip if it's too short or contains "strasse"
                    if trimmed.count > 5 && !lower.contains("strasse") && !lower.contains("str.") {
                        result.hospitalName = trimmed
                    }
                }
            }

            // Department: "Gastroenterologie", "Hepatologie", etc.
            if result.departmentName.isEmpty {
                let lower = trimmed.lowercased()
                if lower.contains("gastroenterologie") || lower.contains("hepatologie") ||
                   lower.contains("abteilung") || lower.contains("innere medizin") {
                    if !lower.contains("chefarzt") { // Don't use the doctor title line
                        result.departmentName = trimmed
                    }
                }
            }

            // Physician name: "Prof. Dr. med." or "Dr. med." pattern
            if result.physicianFullName.isEmpty {
                if trimmed.range(of: "(Prof\\.?|PD|Dr\\.?)\\s", options: .regularExpression) != nil,
                   !trimmed.lowercased().contains("chefarzt"),
                   !trimmed.lowercased().contains("abteilung") {
                    result.physicianFullName = trimmed
                    // Extract title
                    if let titleEnd = trimmed.range(of: "med\\.?\\s", options: .regularExpression)?.upperBound {
                        result.physicianTitle = String(trimmed[..<titleEnd]).trimmingCharacters(in: .whitespaces)
                    } else if let titleEnd = trimmed.range(of: "Dr\\.?\\s", options: .regularExpression)?.upperBound {
                        result.physicianTitle = String(trimmed[..<titleEnd]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }

            // Medication table detection
            if trimmed.contains("Medikamentenname") || trimmed.contains("Beginn Rezeptierung") {
                foundMedHeader = true
                inMedicationTable = true
                continue
            }
            if trimmed.contains("Ende Rezeptierung") {
                inMedicationTable = false
                if let name = currentMedName {
                    result.medications.append((name: name, dosage: currentDosage ?? ""))
                    currentMedName = nil
                    currentDosage = nil
                }
                continue
            }

            // Inside medication table: parse medication lines
            if inMedicationTable {
                // Lines starting with "OP" or a number followed by medication name
                if trimmed.range(of: "^\\d+\\s*OP\\s", options: .regularExpression) != nil ||
                   trimmed.range(of: "^OP\\s", options: .regularExpression) != nil {
                    // Save previous medication
                    if let name = currentMedName {
                        result.medications.append((name: name, dosage: currentDosage ?? ""))
                    }
                    // Extract medication name (everything after "OP" marker)
                    let cleaned = trimmed.replacingOccurrences(of: "^\\d*\\s*OP\\s*", with: "", options: .regularExpression)
                    currentMedName = cleaned
                    currentDosage = nil
                }
                // Dosage line: "bei Bedarf", "max 3x/d", "Mo", "Ab", etc.
                else if currentMedName != nil {
                    let lower = trimmed.lowercased()
                    if lower.contains("bedarf") || lower.contains("max") || lower.contains("x/d") ||
                       lower.contains("t\u{00E4}glich") || lower.contains("mg/") || lower.contains("stk") {
                        if currentDosage == nil || currentDosage!.isEmpty {
                            currentDosage = trimmed
                        } else {
                            currentDosage! += ", " + trimmed
                        }
                    }
                    // Wirkstoff line (active ingredient in italics)
                    else if trimmed.range(of: "^[A-Z][a-z].*\\d+\\s*mg", options: .regularExpression) != nil {
                        // This is the active ingredient line, append to med name
                        currentMedName! += " (\(trimmed))"
                    }
                }
            }

            // Also detect medication outside table by pattern:
            // "Dafalgan (Filmtabl 1 g)" etc. — only if no table found
            if !foundMedHeader && result.medications.isEmpty {
                // Common Swiss medication patterns with dosage forms
                if trimmed.range(of: "(Filmtabl|Tabl|Kaps|Supp|Inf|Inj|Sirup|Tropfen|Salbe|Gel|Creme|L\u{00F6}sung)\\b", options: .regularExpression) != nil {
                    let lower = trimmed.lowercased()
                    if !lower.contains("aus medizinischen") && !lower.contains("substituieren") {
                        result.medications.append((name: trimmed, dosage: ""))
                    }
                }
            }
        }

        // Flush last medication if still pending
        if let name = currentMedName {
            result.medications.append((name: name, dosage: currentDosage ?? ""))
        }
    }
}
