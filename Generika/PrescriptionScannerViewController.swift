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
    private var qrCheckmark = UILabel()

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
        statusLabel.text = "Rezept vor die Kamera halten"
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // QR checkmark (hidden until QR found, next to status label)
        qrCheckmark.text = "\u{2705}"
        qrCheckmark.font = .systemFont(ofSize: 24)
        qrCheckmark.isHidden = true
        qrCheckmark.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCheckmark)

        // Capture button (shutter)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
        captureButton.setImage(UIImage(systemName: "circle.inset.filled", withConfiguration: config), for: .normal)
        captureButton.tintColor = .white
        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        view.addSubview(captureButton)

        // A4 document frame guide
        let frameGuide = UIView()
        frameGuide.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        frameGuide.layer.borderWidth = 1.5
        frameGuide.layer.cornerRadius = 8
        frameGuide.translatesAutoresizingMaskIntoConstraints = false
        frameGuide.isUserInteractionEnabled = false
        view.addSubview(frameGuide)

        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.6),

            qrCheckmark.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 4),
            qrCheckmark.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),

            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // A4 frame guide (210:297 aspect ratio)
            frameGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameGuide.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            frameGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            frameGuide.heightAnchor.constraint(equalTo: frameGuide.widthAnchor, multiplier: 297.0 / 210.0),
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

        guard let results = request.results, !results.isEmpty else { return }

        for obs in results {
            if let payload = obs.payloadStringValue,
               payload.hasPrefix("CHMED16A") || payload.contains("eprescription.hin.ch") {
                qrFound = true
                qrPayload = payload

                DispatchQueue.main.async {
                    self.qrCheckmark.isHidden = false
                    self.statusLabel.text = "QR-Code erkannt\nJetzt aufnehmen f\u{00FC}r OCR"
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

        // Collect all medication names and dosages from OCR
        var medNames: [String] = []
        var dosages: [String] = []

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
                if let commaIdx = trimmed.firstIndex(of: ",") {
                    let afterComma = String(trimmed[trimmed.index(after: commaIdx)...]).trimmingCharacters(in: .whitespaces)
                    if afterComma.range(of: "^(CH-)?\\d{4}\\s+\\S", options: .regularExpression) != nil {
                        let street = String(trimmed[..<commaIdx]).trimmingCharacters(in: .whitespaces)
                        if street.range(of: "\\d", options: .regularExpression) != nil,
                           !street.contains("AHV"),
                           !street.contains("PID"),
                           !street.contains("FID") {
                            result.patientStreet = street
                            let cleaned = afterComma.replacingOccurrences(of: "CH-", with: "")
                            if let plzRange = cleaned.range(of: "^\\d{4}", options: .regularExpression) {
                                result.patientZip = String(cleaned[plzRange])
                                let cityPart = String(cleaned[plzRange.upperBound...]).trimmingCharacters(in: .whitespaces)
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

            // Hospital/Clinic name
            if result.hospitalName.isEmpty {
                let lower = trimmed.lowercased()
                if lower.contains("spital") || lower.contains("klinik") || lower.contains("praxis") || lower.contains("universit") {
                    if trimmed.count > 5 && !lower.contains("strasse") && !lower.contains("str.") {
                        result.hospitalName = trimmed
                    }
                }
            }

            // Department
            if result.departmentName.isEmpty {
                let lower = trimmed.lowercased()
                if lower.contains("gastroenterologie") || lower.contains("hepatologie") ||
                   lower.contains("abteilung") || lower.contains("innere medizin") {
                    if !lower.contains("chefarzt") {
                        result.departmentName = trimmed
                    }
                }
            }

            // Physician name
            if result.physicianFullName.isEmpty {
                if trimmed.range(of: "(Prof\\.?|PD|Dr\\.?)\\s", options: .regularExpression) != nil,
                   !trimmed.lowercased().contains("chefarzt"),
                   !trimmed.lowercased().contains("abteilung") {
                    result.physicianFullName = trimmed
                    if let titleEnd = trimmed.range(of: "med\\.?\\s", options: .regularExpression)?.upperBound {
                        result.physicianTitle = String(trimmed[..<titleEnd]).trimmingCharacters(in: .whitespaces)
                    } else if let titleEnd = trimmed.range(of: "Dr\\.?\\s", options: .regularExpression)?.upperBound {
                        result.physicianTitle = String(trimmed[..<titleEnd]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }

            // --- Medication detection (pattern-based, not table-dependent) ---

            // Medication name: contains dosage form keywords
            let dosageForms = "(Filmtabl|Tabl|Kaps|Drag|Supp|Inf|Inj|Sirup|Tropfen|Salbe|Gel|Creme|L\u{00F6}sung|Susp|Amp|Retard|Depot)"
            if trimmed.range(of: dosageForms, options: .regularExpression) != nil {
                let lower = trimmed.lowercased()
                if !lower.contains("aus medizinischen") && !lower.contains("substituieren") &&
                   !lower.contains("medikamentenname") && !lower.contains("wirkstoff") {
                    // Clean up: remove leading "1 OP" etc.
                    var medName = trimmed.replacingOccurrences(of: "^\\d+\\s*OP\\s*", with: "", options: .regularExpression)
                    medName = medName.trimmingCharacters(in: .whitespaces)
                    if !medName.isEmpty {
                        medNames.append(medName)
                    }
                }
            }

            // Dosage/instruction: "bei Bedarf", "max Nx/d", "täglich", "1-0-1-0" etc.
            let lower = trimmed.lowercased()
            if lower.contains("bedarf") || lower.contains("x/d") ||
               lower.range(of: "max\\s+\\d", options: .regularExpression) != nil ||
               lower.contains("t\u{00E4}glich") ||
               lower.range(of: "^\\d+-\\d+-\\d+", options: .regularExpression) != nil {
                if !lower.contains("medikamentenname") && !lower.contains("rezeptierung") {
                    dosages.append(trimmed)
                }
            }
        }

        // Build medication list from collected names and dosages
        for (i, name) in medNames.enumerated() {
            let dosage = i < dosages.count ? dosages[i] : ""
            result.medications.append((name: name, dosage: dosage))
        }
    }
}
