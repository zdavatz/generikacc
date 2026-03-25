//
//  InsuranceCardScanner.swift
//  Generika
//
//  Based on AmiKo-Desitin PatientViewController+smartCard
//  Copyright (c) 2018-2026 ywesee GmbH. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

struct InsuranceCardResult {
    var familyName: String = ""
    var givenName: String = ""
    var cardNumberString: String = ""
    var dateString: String = ""
    var sexString: String = ""
    var bagNumber: String = ""
    var ahvNumber: String = ""
    var insuranceGLN: String = ""
    var insuranceName: String = ""
}

protocol InsuranceCardScannerDelegate: AnyObject {
    func insuranceCardScanner(_ scanner: InsuranceCardScannerViewController, didScan result: InsuranceCardResult)
    func insuranceCardScannerDidCancel(_ scanner: InsuranceCardScannerViewController)
}

class InsuranceCardScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    weak var delegate: InsuranceCardScannerDelegate?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "cardScannerSessionQueue")
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var cardOutlineLayer = CALayer()
    private var videoCaptureFinished = false
    private var savedResult = InsuranceCardResult()

    // Card dimensions (mm) — Swiss health insurance card
    private let cardWidth: CGFloat = 85.6
    private let cardHeight: CGFloat = 53.98
    private let cardIgnoreTop: CGFloat = 35.0
    private let cardKeepLeft: CGFloat = 15.0
    private let minTextHeight: CGFloat = 2.0
    private let rejectBoxWidth: CGFloat = 0.047

    private let numberOfBoxes = 5

    // BAG number to insurance GLN mapping
    private var bagToGLNMapping: [String: String] = [:]
    // BAG number to insurance name mapping
    private var bagToNameMapping: [String: String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        loadMappings()
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

    private func loadMappings() {
        if let path = Bundle.main.path(forResource: "bag-to-insurance-gln", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            bagToGLNMapping = dict
        }
        if let path = Bundle.main.path(forResource: "bag-to-insurance-name", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            bagToNameMapping = dict
        }
    }

    private func setupUI() {
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("Abbrechen", for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 18)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelBtn)

        let label = UILabel()
        label.text = "Versichertenkarte in den Rahmen halten"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // Card outline
        cardOutlineLayer.borderColor = UIColor.systemGreen.cgColor
        cardOutlineLayer.borderWidth = 2
        cardOutlineLayer.cornerRadius = 10
        view.layer.addSublayer(cardOutlineLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateCardOutline()
    }

    private func updateCardOutline() {
        let bounds = view.bounds
        let cardAspect = cardWidth / cardHeight
        let cardX = bounds.width * 0.04
        let cardW = bounds.width - 2 * cardX
        let cardH = cardW / cardAspect
        let cardY = bounds.height / 2 - cardH / 2
        cardOutlineLayer.frame = CGRect(x: cardX, y: cardY, width: cardW, height: cardH)
    }

    private func setupCamera() {
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Lower frame rate
        do {
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 8)
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 4)
            device.unlockForConfiguration()
        } catch {}

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }

    @objc private func cancelTapped() {
        session.stopRunning()
        delegate?.insuranceCardScannerDidCancel(self)
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if videoCaptureFinished { return }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // OCR on full frame — filtering handles discarding irrelevant text
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.02

        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up, options: [:])
        try? handler.perform([request])

        guard let results = request.results, !results.isEmpty else { return }

        let boxedWords = filterBoxedWords(results)
        if boxedWords.count < numberOfBoxes { return }

        let sorted = analyzeBoxedWords(boxedWords)
        if validateOCR(sorted) {
            videoCaptureFinished = true
            DispatchQueue.main.async {
                self.session.stopRunning()
                self.delegate?.insuranceCardScanner(self, didScan: self.savedResult)
            }
        }
    }

    private func filterBoxedWords(_ observations: [VNRecognizedTextObservation]) -> [[String: Any]] {
        var boxedWords: [[String: Any]] = []

        for obs in observations {
            let box = obs.boundingBox
            guard let candidate = obs.topCandidates(1).first else { continue }
            let text = candidate.string
            let confidence = candidate.confidence

            // Skip low confidence
            if confidence < 0.4 { continue }

            // Skip very small boxes
            if box.size.width < 0.03 { continue }

            // Skip unwanted characters
            let unwanted = CharacterSet(charactersIn: "/^•&~!=:(%#_")
            if text.unicodeScalars.contains(where: { unwanted.contains($0) }) { continue }

            // Skip label text on the card
            let unwantedLabels = ["Name", "Vorname", "Cognome", "Karten",
                                  "Geburtsdatum", "Date de", "Data di", "Data da",
                                  "Carte", "Assicurato", "Versicherte"]
            if unwantedLabels.contains(where: { text.contains($0) }) { continue }

            boxedWords.append(["box": NSValue(cgRect: box), "text": text, "conf": confidence])
        }
        return boxedWords
    }

    private func analyzeBoxedWords(_ allBoxes: [[String: Any]]) -> [[String: Any]] {
        // Pattern-match to find the 5 expected fields regardless of position
        var nameBox: [String: Any]?      // "Family, Given"
        var cardBox: [String: Any]?      // 20 digits
        var bagBox: [String: Any]?       // 5 digits
        var ahvBox: [String: Any]?       // NNN.NNNN.NNNN.NN
        var dateSexBox: [String: Any]?   // DD.MM.YYYY M/F

        for box in allBoxes {
            guard let text = box["text"] as? String else { continue }

            // Card number: exactly 20 digits
            if cardBox == nil && text.count == 20 && text.allSatisfy({ $0.isNumber }) {
                cardBox = box; continue
            }
            // BAG number: exactly 5 digits
            if bagBox == nil && text.count == 5 && text.allSatisfy({ $0.isNumber }) {
                bagBox = box; continue
            }
            // AHV number: NNN.NNNN.NNNN.NN
            if ahvBox == nil && text.count == 16 &&
               text.range(of: "^[0-9]{3}\\.[0-9]{4}\\.[0-9]{4}\\.[0-9]{2}$", options: .regularExpression) != nil {
                ahvBox = box; continue
            }
            // Date + Sex: DD.MM.YYYY M or DD.MM.YYYY F
            if dateSexBox == nil &&
               text.range(of: "^\\d{2}\\.\\d{2}\\.\\d{4}\\s+[MF]$", options: .regularExpression) != nil {
                dateSexBox = box; continue
            }
            // Name: contains comma (Family, Given)
            if nameBox == nil && text.contains(",") {
                let parts = text.components(separatedBy: ",")
                if parts.count >= 2 && !parts[1].trimmingCharacters(in: .whitespaces).isEmpty {
                    nameBox = box; continue
                }
            }
        }

        guard let n = nameBox, let c = cardBox, let b = bagBox, let a = ahvBox, let d = dateSexBox else {
            return []
        }
        return [n, c, b, a, d]
    }

    private func validateOCR(_ ocrResults: [[String: Any]]) -> Bool {
        guard ocrResults.count >= numberOfBoxes else { return false }

        // Box 0: FamilyName, GivenName
        let line1 = (ocrResults[0]["text"] as? String) ?? ""
        let parts = line1.components(separatedBy: ",")
        guard parts.count >= 2 else { return false }
        let familyName = parts[0].trimmingCharacters(in: .whitespaces)
        let givenName = parts[1].trimmingCharacters(in: .whitespaces)
        guard !givenName.isEmpty else { return false }

        // Box 1: Card number (20 digits)
        let cardNumber = (ocrResults[1]["text"] as? String) ?? ""
        guard cardNumber.count == 20, cardNumber.allSatisfy({ $0.isNumber }) else { return false }

        // Box 2: BAG number
        let bagNumber = (ocrResults[2]["text"] as? String) ?? ""

        // Box 3: AHV number
        let ahvNumber = (ocrResults[3]["text"] as? String) ?? ""

        // Box 4: Date + Sex
        let line2 = (ocrResults[4]["text"] as? String) ?? ""
        let line2Parts = line2.components(separatedBy: " ").filter { !$0.isEmpty }
        guard line2Parts.count >= 2 else { return false }
        let dateString = line2Parts[0]
        let sexString = line2Parts[1]
        guard sexString == "M" || sexString == "F" else { return false }

        // Look up insurance GLN and name from BAG number
        let bagKey = String(Int(bagNumber) ?? 0)
        let insuranceGLN = bagToGLNMapping[bagKey] ?? ""
        let insuranceName = bagToNameMapping[bagKey] ?? ""

        savedResult = InsuranceCardResult(
            familyName: familyName,
            givenName: givenName,
            cardNumberString: cardNumber,
            dateString: dateString,
            sexString: sexString,
            bagNumber: bagNumber,
            ahvNumber: ahvNumber,
            insuranceGLN: insuranceGLN,
            insuranceName: insuranceName
        )
        return true
    }
}
