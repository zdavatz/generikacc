//
//  KostengutspracheViewController.swift
//  Generika
//
//  Copyright (c) 2024-2026 ywesee GmbH. All rights reserved.
//

import UIKit
import MessageUI

@objc class KostengutspracheViewController: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate, InsuranceCardScannerDelegate, PrescriptionScannerDelegate {

    private var receipt: Receipt
    private var scrollView: UIScrollView!
    private var contentView: UIView!

    // Patient
    private var patientNameField: UITextField!
    private var patientFirstNameField: UITextField!
    private var patientBirthDateField: UITextField!
    private var patientGenderSegment: UISegmentedControl!
    private var patientStreetField: UITextField!
    private var patientZipCityField: UITextField!
    private var patientAHVField: UITextField!

    // Insurance
    private var insurerNameField: UITextField!
    private var insurerNumberField: UITextField!

    // IBD specific
    private var diagnosisSegment: UISegmentedControl!
    private var medicationTextView: UITextView!

    // Physician
    private var physicianNameField: UITextField!
    private var physicianFirstNameField: UITextField!
    private var physicianZSRField: UITextField!
    private var physicianHospitalField: UITextField!
    private var physicianDepartmentField: UITextField!

    // Date
    private var dateField: UITextField!

    @objc init(receipt: Receipt) {
        self.receipt = receipt
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Kostengutsprache"
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupForm()
        prefillFromReceipt()
        registerKeyboardNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "PDF / Email", style: .plain, target: self, action: #selector(generateAndSendPDF))
    }

    @objc private func closeTapped() {
        saveFormToReceipt()
        dismiss(animated: true) {
            NotificationCenter.default.post(name: NSNotification.Name("receiptsDidLoaded"), object: nil)
        }
    }

    private func saveFormToReceipt() {
        // Update patient
        let patient = receipt.patient ?? Patient.import(fromDict: [:]) as! Patient
        patient.familyName = patientNameField.text ?? ""
        patient.givenName = patientFirstNameField.text ?? ""
        patient.birthDate = patientBirthDateField.text ?? ""
        if patientGenderSegment.selectedSegmentIndex == 0 {
            patient.gender = "F"
        } else if patientGenderSegment.selectedSegmentIndex == 1 {
            patient.gender = "M"
        }
        patient.address = patientStreetField.text ?? ""
        let zipCity = patientZipCityField.text ?? ""
        let zipCityParts = zipCity.components(separatedBy: " ")
        if zipCityParts.count >= 1 {
            patient.zipcode = zipCityParts[0]
        }
        if zipCityParts.count >= 2 {
            patient.city = zipCityParts.dropFirst().joined(separator: " ")
        }
        patient.healthCardNumber = insurerNumberField.text ?? ""
        patient.insurerName = insurerNameField.text ?? ""
        patient.ahvNumber = patientAHVField.text ?? ""
        receipt.patient = patient

        // Update operator (physician)
        let op = receipt.operator ?? Operator.import(fromDict: [:]) as! Operator
        op.familyName = physicianNameField.text ?? ""
        op.givenName = physicianFirstNameField.text ?? ""
        op.zsrNumber = physicianZSRField.text ?? ""
        receipt.operator = op

        // Update product names from medication text
        let medLines = (medicationTextView.text ?? "").components(separatedBy: "\n").filter { !$0.isEmpty }
        if let products = receipt.products as? [Product] {
            for (i, product) in products.enumerated() {
                if i < medLines.count {
                    let line = medLines[i]
                    // Split on " – " to separate name and dosage
                    let parts = line.components(separatedBy: " \u{2013} ")
                    product.name = parts[0]
                    if parts.count > 1 {
                        product.comment = parts.dropFirst().joined(separator: " \u{2013} ")
                    }
                }
            }
        }

        // Diagnosis
        if diagnosisSegment.selectedSegmentIndex == 0 {
            receipt.diagnosis = "crohn"
        } else if diagnosisSegment.selectedSegmentIndex == 1 {
            receipt.diagnosis = "colitis"
        }

        // Save
        ReceiptManager.shared().save()
    }

    private func setupForm() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        let m: CGFloat = 16
        var y = contentView.topAnchor

        // Title with prescription scan button
        y = addTitleHeaderWithScan("Kostengutsprache KVV 71 \u{2013} IBD Gastroenterologie", below: y, margin: m)

        // Patient
        y = addSectionHeader("Patient/in", below: y, margin: m)
        patientNameField = addTextField("Name", below: &y, margin: m)
        patientFirstNameField = addTextField("Vorname", below: &y, margin: m)
        patientBirthDateField = addTextField("Geburtsdatum", below: &y, margin: m)

        patientGenderSegment = UISegmentedControl(items: ["\u{2640} W", "\u{2642} M"])
        patientGenderSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(patientGenderSegment)
        NSLayoutConstraint.activate([
            patientGenderSegment.topAnchor.constraint(equalTo: y, constant: 6),
            patientGenderSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
            patientGenderSegment.widthAnchor.constraint(equalToConstant: 140),
        ])
        y = patientGenderSegment.bottomAnchor

        patientStreetField = addTextField("Strasse", below: &y, margin: m)
        patientZipCityField = addTextField("PLZ / Ort", below: &y, margin: m)
        patientAHVField = addTextField("AHV-Nr.", below: &y, margin: m)

        // Insurance (with camera button for card scanning)
        let insuranceHeader = addSectionHeaderWithCamera("Versicherung", below: y, margin: m)
        y = insuranceHeader
        insurerNameField = addTextField("Krankenversicherer", below: &y, margin: m)
        insurerNumberField = addTextField("Versicherten-Nr.", below: &y, margin: m)

        // Diagnosis (IBD specific)
        y = addSectionHeader("Diagnose", below: y, margin: m)
        diagnosisSegment = UISegmentedControl(items: ["M. Crohn", "Colitis ulcerosa"])
        diagnosisSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(diagnosisSegment)
        NSLayoutConstraint.activate([
            diagnosisSegment.topAnchor.constraint(equalTo: y, constant: 6),
            diagnosisSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
            diagnosisSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -m),
        ])
        y = diagnosisSegment.bottomAnchor

        // Medication
        y = addSectionHeader("Medikament", below: y, margin: m)
        medicationTextView = addTextView(below: &y, margin: m, height: 100)

        // Physician
        y = addSectionHeader("Arzt / \u{00C4}rztin", below: y, margin: m)
        physicianNameField = addTextField("Name", below: &y, margin: m)
        physicianFirstNameField = addTextField("Vorname", below: &y, margin: m)
        physicianZSRField = addTextField("ZSR-Nr.", below: &y, margin: m)
        physicianHospitalField = addTextField("Spital / Praxis", below: &y, margin: m)
        physicianDepartmentField = addTextField("Abteilung", below: &y, margin: m)

        // Date
        dateField = addTextField("Datum", below: &y, margin: m)

        contentView.bottomAnchor.constraint(equalTo: y, constant: 40).isActive = true
    }

    // MARK: - Form Helpers

    private func addTitleHeaderWithScan(_ text: String, below anchor: NSLayoutYAxisAnchor, margin: CGFloat) -> NSLayoutYAxisAnchor {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let scanButton = UIButton(type: .system)
        scanButton.setImage(UIImage(systemName: "doc.viewfinder"), for: .normal)
        scanButton.addTarget(self, action: #selector(scanPrescription), for: .touchUpInside)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.accessibilityLabel = "Rezept scannen"
        container.addSubview(scanButton)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: anchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: scanButton.leadingAnchor, constant: -8),
            scanButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scanButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 40),
            scanButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        return container.bottomAnchor
    }

    private func addSectionHeader(_ text: String, below anchor: NSLayoutYAxisAnchor, margin: CGFloat, bold: Bool = false) -> NSLayoutYAxisAnchor {
        let label = UILabel()
        label.text = text
        label.font = bold ? .boldSystemFont(ofSize: 17) : .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = bold ? .label : .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: anchor, constant: bold ? 16 : 18),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
        ])
        return label.bottomAnchor
    }

    private func addTextField(_ placeholder: String, below anchor: inout NSLayoutYAxisAnchor, margin: CGFloat) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 15)
        field.delegate = self
        field.returnKeyType = .next
        field.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(field)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: anchor, constant: 6),
            field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            field.heightAnchor.constraint(equalToConstant: 40),
        ])
        anchor = field.bottomAnchor
        return field
    }

    private func addSectionHeaderWithCamera(_ text: String, below anchor: NSLayoutYAxisAnchor, margin: CGFloat) -> NSLayoutYAxisAnchor {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let cameraButton = UIButton(type: .system)
        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.addTarget(self, action: #selector(scanInsuranceCard), for: .touchUpInside)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(cameraButton)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: anchor, constant: 18),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            cameraButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: 36),
            cameraButton.heightAnchor.constraint(equalToConstant: 36),
            container.heightAnchor.constraint(equalToConstant: 30),
        ])
        return container.bottomAnchor
    }

    // MARK: - Prescription Scanner

    @objc private func scanPrescription() {
        let scanner = PrescriptionScannerViewController()
        scanner.delegate = self
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    func prescriptionScanner(_ scanner: PrescriptionScannerViewController, didScan result: PrescriptionScanResult) {
        scanner.dismiss(animated: true) {
            self.applyPrescriptionScanResult(result)
        }
    }

    func prescriptionScannerDidCancel(_ scanner: PrescriptionScannerViewController) {
        scanner.dismiss(animated: true)
    }

    private func applyPrescriptionScanResult(_ result: PrescriptionScanResult) {
        // Save Receipt from QR code (like MasterViewController does)
        if let ep = result.ePrescription {
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "yyyy-MM-dd'T'HH.mm.ss"
            dateFmt.timeZone = TimeZone.current
            let amkFilename = "RZ_\(dateFmt.string(from: Date())).amk"
            if let newReceipt = ReceiptManager.shared().importReceipt(fromAMKDict: ep.amkDict(), fileName: amkFilename) as? Receipt {
                ReceiptManager.shared().insertReceipt(newReceipt, at: 0)
                self.receipt = newReceipt
            }
        }

        // Stage 1: QR code data (structured, reliable)
        if let ep = result.ePrescription {
            let fmt = DateFormatter()
            fmt.dateFormat = "dd.MM.yyyy"

            if patientNameField.text?.isEmpty ?? true {
                patientNameField.text = ep.patientLastName
            }
            if patientFirstNameField.text?.isEmpty ?? true {
                patientFirstNameField.text = ep.patientFirstName
            }
            if patientBirthDateField.text?.isEmpty ?? true {
                let bd = ep.patientBirthdate
                if bd != nil {
                    patientBirthDateField.text = fmt.string(from: bd)
                }
            }
            if patientGenderSegment.selectedSegmentIndex == -1 {
                if ep.patientGender.intValue == 2 {
                    patientGenderSegment.selectedSegmentIndex = 0 // W
                } else if ep.patientGender.intValue == 1 {
                    patientGenderSegment.selectedSegmentIndex = 1 // M
                }
            }
            // QR may have patient address
            if patientStreetField.text?.isEmpty ?? true, !ep.patientStreet.isEmpty {
                patientStreetField.text = ep.patientStreet
            }
            if patientZipCityField.text?.isEmpty ?? true {
                let zip = ep.patientZip ?? ""
                let city = ep.patientCity ?? ""
                if !zip.isEmpty || !city.isEmpty {
                    patientZipCityField.text = "\(zip) \(city)".trimmingCharacters(in: .whitespaces)
                }
            }

            // Physician from QR
            if physicianZSRField.text?.isEmpty ?? true, !ep.zsr.isEmpty {
                physicianZSRField.text = ep.zsr
            }

            // Health card number from QR
            for pid in ep.patientIds {
                if pid.type.intValue == 1 {
                    if pid.value.count == 20 || pid.value.contains(".") {
                        if insurerNumberField.text?.isEmpty ?? true {
                            insurerNumberField.text = pid.value
                        }
                    }
                }
            }

            // Medications from QR + OCR (always overwrite — scan data is fresher)
            var medText = ""
            for (index, med) in ep.medicaments.enumerated() {
                var name = ""
                let medId = med.medicamentId ?? ""
                let idType = med.idType.intValue

                if idType == 3 {
                    // Pharmacode — not in AmiKo DB, use OCR text directly
                    if index < result.medications.count {
                        name = result.medications[index].name
                    }
                } else if idType == 2 && !medId.isEmpty {
                    // GTIN — look up in AmiKo DB
                    name = lookupMedNameByGTIN(medId)
                }

                // Fallback: use OCR medication name
                if (name.isEmpty || name == medId), index < result.medications.count {
                    name = result.medications[index].name
                }

                if name.isEmpty { name = medId.isEmpty ? "?" : medId }
                if !medText.isEmpty { medText += "\n" }
                medText += name
                // Dosage: prefer QR appInstr, fallback to OCR dosage
                let instr = med.appInstr ?? ""
                if !instr.isEmpty {
                    medText += " \u{2013} \(instr)"
                } else if index < result.medications.count, !result.medications[index].dosage.isEmpty {
                    medText += " \u{2013} \(result.medications[index].dosage)"
                }
            }
            if !medText.isEmpty {
                medicationTextView.text = medText
            }
        }

        // Stage 2: OCR data (supplements QR, fills gaps)

        // AHV number (never in QR)
        if patientAHVField.text?.isEmpty ?? true, !result.ahvNumber.isEmpty {
            patientAHVField.text = result.ahvNumber
        }

        // Patient address from OCR (if not from QR)
        if patientStreetField.text?.isEmpty ?? true, !result.patientStreet.isEmpty {
            patientStreetField.text = result.patientStreet
        }
        if patientZipCityField.text?.isEmpty ?? true {
            if !result.patientZip.isEmpty || !result.patientCity.isEmpty {
                patientZipCityField.text = "\(result.patientZip) \(result.patientCity)".trimmingCharacters(in: .whitespaces)
            }
        }

        // Phone from OCR
        if result.patientPhone.isEmpty == false {
            // Store phone for later use — could add a phone field if needed
        }

        // Physician from OCR (title, hospital, department)
        if !result.physicianFullName.isEmpty {
            // Parse "Prof. Dr. med. Christoph Gubler" into first/last name
            var fullName = result.physicianFullName
            // Remove title prefix
            let titlePatterns = ["Prof.", "PD", "Dr.", "med.", "Dr"]
            for pattern in titlePatterns {
                fullName = fullName.replacingOccurrences(of: pattern, with: "").trimmingCharacters(in: .whitespaces)
            }
            // Clean up multiple spaces
            while fullName.contains("  ") {
                fullName = fullName.replacingOccurrences(of: "  ", with: " ")
            }
            let parts = fullName.components(separatedBy: " ").filter { !$0.isEmpty }
            if parts.count >= 2 {
                if physicianFirstNameField.text?.isEmpty ?? true {
                    physicianFirstNameField.text = parts.dropLast().joined(separator: " ")
                }
                if physicianNameField.text?.isEmpty ?? true {
                    physicianNameField.text = parts.last
                }
            }
        }
        if physicianZSRField.text?.isEmpty ?? true, !result.zsrNumber.isEmpty {
            physicianZSRField.text = result.zsrNumber
        }
        if physicianHospitalField.text?.isEmpty ?? true, !result.hospitalName.isEmpty {
            physicianHospitalField.text = result.hospitalName
        }
        if physicianDepartmentField.text?.isEmpty ?? true, !result.departmentName.isEmpty {
            physicianDepartmentField.text = result.departmentName
        }

        // Medications from OCR (if QR didn't provide them or they were just GTINs)
        if !result.medications.isEmpty {
            let currentText = medicationTextView.text ?? ""
            // If current text only has GTINs (all numeric), replace with OCR names
            let currentLines = currentText.components(separatedBy: "\n").filter { !$0.isEmpty }
            let allNumericIds = !currentLines.isEmpty && currentLines.allSatisfy { line in
                let cleaned = line.trimmingCharacters(in: .whitespaces)
                return cleaned.allSatisfy { $0.isNumber } && cleaned.count >= 4
            }

            if currentText.isEmpty || allNumericIds {
                var medText = ""
                for med in result.medications {
                    if !medText.isEmpty { medText += "\n" }
                    medText += med.name
                    if !med.dosage.isEmpty {
                        medText += " \u{2013} \(med.dosage)"
                    }
                }
                if !medText.isEmpty {
                    medicationTextView.text = medText
                }
            }
        }

        // Prescription date from OCR
        if !result.prescriptionDate.isEmpty {
            // Convert DD.MM.YYYY to YYYY-MM-DD for the date field
            let parts = result.prescriptionDate.components(separatedBy: ".")
            if parts.count == 3, let day = parts.first, let month = parts.dropFirst().first, let year = parts.last {
                dateField.text = "\(year)-\(month)-\(day)"
            }
        }
    }

    // MARK: - Insurance Card Scanner

    @objc private func scanInsuranceCard() {
        let scanner = InsuranceCardScannerViewController()
        scanner.delegate = self
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    // MARK: - InsuranceCardScannerDelegate

    func insuranceCardScanner(_ scanner: InsuranceCardScannerViewController, didScan result: InsuranceCardResult) {
        scanner.dismiss(animated: true) {
            self.insurerNumberField.text = result.cardNumberString
            if !result.insuranceName.isEmpty {
                self.insurerNameField.text = result.insuranceName
            }
            // Also populate patient fields if they were empty
            if self.patientNameField.text?.isEmpty ?? true {
                self.patientNameField.text = result.familyName
            }
            if self.patientFirstNameField.text?.isEmpty ?? true {
                self.patientFirstNameField.text = result.givenName
            }
            if self.patientBirthDateField.text?.isEmpty ?? true {
                self.patientBirthDateField.text = result.dateString
            }
            if self.patientGenderSegment.selectedSegmentIndex == -1 {
                if result.sexString == "F" {
                    self.patientGenderSegment.selectedSegmentIndex = 0
                } else if result.sexString == "M" {
                    self.patientGenderSegment.selectedSegmentIndex = 1
                }
            }
            // AHV number from insurance card
            if self.patientAHVField.text?.isEmpty ?? true, !result.ahvNumber.isEmpty {
                self.patientAHVField.text = result.ahvNumber
            }
        }
    }

    func insuranceCardScannerDidCancel(_ scanner: InsuranceCardScannerViewController) {
        scanner.dismiss(animated: true)
    }

    private func addTextView(below anchor: inout NSLayoutYAxisAnchor, margin: CGFloat, height: CGFloat) -> UITextView {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.layer.borderWidth = 0.5
        tv.layer.cornerRadius = 6
        tv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tv)
        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: anchor, constant: 6),
            tv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            tv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            tv.heightAnchor.constraint(equalToConstant: height),
        ])
        anchor = tv.bottomAnchor
        return tv
    }

    // MARK: - Prefill

    private func prefillFromReceipt() {
        let patient = receipt.patient
        patientNameField.text = patient?.familyName ?? ""
        patientFirstNameField.text = patient?.givenName ?? ""
        patientBirthDateField.text = patient?.birthDate ?? ""

        if let gender = patient?.gender, !gender.isEmpty {
            let g = gender.lowercased()
            if g == "woman" || g == "2" || g == "w" || g == "f" {
                patientGenderSegment.selectedSegmentIndex = 0
            } else if g == "man" || g == "1" || g == "m" {
                patientGenderSegment.selectedSegmentIndex = 1
            }
        }

        // Address
        patientStreetField.text = patient?.address ?? ""
        let zip = patient?.zipcode ?? ""
        let city = patient?.city ?? ""
        if !zip.isEmpty || !city.isEmpty {
            patientZipCityField.text = "\(zip) \(city)".trimmingCharacters(in: .whitespaces)
        }

        patientAHVField.text = patient?.ahvNumber ?? ""

        insurerNameField.text = patient?.insurerName ?? ""
        insurerNumberField.text = patient?.healthCardNumber ?? ""

        let op = receipt.operator
        physicianNameField.text = op?.familyName ?? ""
        physicianFirstNameField.text = op?.givenName ?? ""
        physicianZSRField.text = op?.zsrNumber ?? ""

        // Medications from receipt — use saved name, show pharmacode alongside
        var medText = ""
        if let products = receipt.products as? [Product] {
            for product in products {
                var name = product.name ?? ""
                let pack = product.pack ?? ""
                let ean = product.ean ?? ""

                // Use pack or name if available (saved from previous OCR scan)
                if !pack.isEmpty {
                    name = pack
                } else if name.isEmpty && !ean.isEmpty {
                    // Try GTIN lookup (only works for 13-digit GTINs)
                    let dbName = lookupMedNameByGTIN(ean)
                    if !dbName.isEmpty {
                        name = dbName
                    }
                }

                // Build display line: "Medikamentenname (Pharmacode: 1234567)"
                if !name.isEmpty && name != ean && !ean.isEmpty && ean.count < 13
                   && !name.contains(ean) {
                    // Pharmacode — show both name and code
                    name = "\(name) (Pharmacode: \(ean))"
                } else if name.isEmpty && !ean.isEmpty {
                    // No name resolved, just show the code
                    name = ean
                }

                if name.isEmpty { name = "?" }
                if !medText.isEmpty { medText += "\n" }
                medText += name
                if let comment = product.comment, !comment.isEmpty {
                    medText += " \u{2013} \(comment)"
                }
            }
        }
        medicationTextView.text = medText

        // Diagnosis
        if let diag = receipt.diagnosis, !diag.isEmpty {
            if diag == "crohn" {
                diagnosisSegment.selectedSegmentIndex = 0
            } else if diag == "colitis" {
                diagnosisSegment.selectedSegmentIndex = 1
            }
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        dateField.text = fmt.string(from: Date())
    }

    // MARK: - Medication Lookup

    private func lookupMedNameByGTIN(_ gtin: String) -> String {
        guard gtin.count == 13 else { return "" }
        guard let rows = AmikoDBManager.shared().find(withGtin: gtin, type: "") as? [AmikoDBRow],
              let row = rows.first else { return "" }
        for pkg in row.parsedPackages() {
            if pkg.gtin == gtin {
                return pkg.name ?? row.title ?? ""
            }
        }
        return row.title ?? ""
    }

    // MARK: - PDF

    @objc private func generateAndSendPDF() {
        let pdfData = renderPDF()
        let patientFullName = "\(patientFirstNameField.text ?? "") \(patientNameField.text ?? "")".trimmingCharacters(in: .whitespaces)

        // Always use share sheet — works even without Mail app configured
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("Kostengutsprache_KVV71.pdf")
        try? pdfData.write(to: tmpURL)
        let ac = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
        ac.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        ac.setValue("Kostengutsprache KVV 71 \u{2013} \(patientFullName)", forKey: "subject")
        present(ac, animated: true)
    }

    private func renderPDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let margin: CGFloat = 40
        let w = pageRect.width - 2 * margin
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            y = drawText("Kostengutsprache zu Art. 71a-d KVV", x: margin, y: y, width: w,
                         font: .boldSystemFont(ofSize: 16))
            y += 2
            y = drawText("IBD Gastroenterologie", x: margin, y: y, width: w,
                         font: .systemFont(ofSize: 12), color: .darkGray)
            y += 16

            // Patient
            y = drawSectionHeader("Patient/in", x: margin, y: y, width: w)
            y = drawRow("Name:", patientNameField.text, x: margin, y: y, width: w)
            y = drawRow("Vorname:", patientFirstNameField.text, x: margin, y: y, width: w)
            y = drawRow("Geburtsdatum:", patientBirthDateField.text, x: margin, y: y, width: w)
            let genderText = patientGenderSegment.selectedSegmentIndex == 0 ? "weiblich" :
                             patientGenderSegment.selectedSegmentIndex == 1 ? "m\u{00E4}nnlich" : ""
            y = drawRow("Geschlecht:", genderText, x: margin, y: y, width: w)
            y = drawRow("Strasse:", patientStreetField.text, x: margin, y: y, width: w)
            y = drawRow("PLZ / Ort:", patientZipCityField.text, x: margin, y: y, width: w)
            y = drawRow("AHV-Nr.:", patientAHVField.text, x: margin, y: y, width: w)
            y += 10

            // Insurance
            y = drawSectionHeader("Versicherung", x: margin, y: y, width: w)
            y = drawRow("Krankenversicherer:", insurerNameField.text, x: margin, y: y, width: w)
            y = drawRow("Versicherten-Nr.:", insurerNumberField.text, x: margin, y: y, width: w)
            y += 10

            // Diagnosis
            y = drawSectionHeader("Diagnose", x: margin, y: y, width: w)
            let diagnosis: String
            if diagnosisSegment.selectedSegmentIndex == 0 {
                diagnosis = "Morbus Crohn"
            } else if diagnosisSegment.selectedSegmentIndex == 1 {
                diagnosis = "Colitis ulcerosa"
            } else {
                diagnosis = ""
            }
            y = drawRow("Diagnose:", diagnosis, x: margin, y: y, width: w)
            y += 10

            // Medication
            y = drawSectionHeader("Medikament", x: margin, y: y, width: w)
            y = drawMultiline(medicationTextView.text ?? "", x: margin, y: y, width: w)
            y += 10

            // Physician
            y = drawSectionHeader("Behandelnder Arzt / \u{00C4}rztin", x: margin, y: y, width: w)
            y = drawRow("Name:", physicianNameField.text, x: margin, y: y, width: w)
            y = drawRow("Vorname:", physicianFirstNameField.text, x: margin, y: y, width: w)
            y = drawRow("ZSR-Nr.:", physicianZSRField.text, x: margin, y: y, width: w)
            y = drawRow("Spital / Praxis:", physicianHospitalField.text, x: margin, y: y, width: w)
            y = drawRow("Abteilung:", physicianDepartmentField.text, x: margin, y: y, width: w)
            y += 10

            y = drawRow("Datum:", dateField.text, x: margin, y: y, width: w)
        }
    }

    // MARK: - PDF Drawing

    @discardableResult
    private func drawText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat,
                          font: UIFont, color: UIColor = .black) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: rect.height), withAttributes: attrs)
        return y + rect.height
    }

    private func drawSectionHeader(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        let lineY = y + 15
        UIColor.gray.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: lineY))
        path.addLine(to: CGPoint(x: x + width, y: lineY))
        path.lineWidth = 0.5
        path.stroke()
        return lineY + 4
    }

    private func drawRow(_ label: String, _ value: String?, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let labelW: CGFloat = 130
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: UIColor.darkGray]
        let valAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.black]
        (label as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: labelAttrs)
        let v = value ?? ""
        let sz = (v as NSString).boundingRect(
            with: CGSize(width: width - labelW, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: valAttrs, context: nil)
        (v as NSString).draw(in: CGRect(x: x + labelW, y: y, width: width - labelW, height: sz.height),
                             withAttributes: valAttrs)
        return y + max(14, sz.height + 2)
    }

    private func drawMultiline(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.black]
        let sz = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: sz.height), withAttributes: attrs)
        return y + sz.height + 2
    }

    // MARK: - Keyboard

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let kb = (n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        scrollView.contentInset.bottom = kb.height
        scrollView.scrollIndicatorInsets.bottom = kb.height
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
