//
//  IndCSection.swift
//  Generika
//
//  GUI for issue #102 — Indikationscode (BAG XXXXX.NN) integration.
//  Drop-in section view for KostengutspracheViewController.
//

import UIKit

// MARK: - Model

struct IndCEntry {
    let code: String       // e.g. "18923.01"
    let title: String      // first line / short label of the limitations text
    let text: String       // full limitations text

    var requiresKoGu: Bool {
        let lower = text.lowercased()
        return lower.contains("kostengutsprache") || lower.contains("vertrauensarzt")
    }
}

/// Parses the comma-separated `INDIKATIONSCODE` and newline-separated
/// `INDIKATIONSCODE_TEXT` columns shipped by rust2xml >= 3.1.12.
enum IndCParser {
    /// `codeStr`  — "18923.01,18923.02,..."
    /// `textStr`  — "18923.01: <text>\n18923.02: <text>\n..."
    static func parse(codeStr: String?, textStr: String?) -> [IndCEntry] {
        guard let codeStr = codeStr, !codeStr.isEmpty else { return [] }
        let codes = codeStr.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var textByCode: [String: String] = [:]
        if let textStr = textStr {
            for line in textStr.components(separatedBy: "\n") {
                guard let colon = line.firstIndex(of: ":") else { continue }
                let code = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                let text = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                if !code.isEmpty { textByCode[code] = text }
            }
        }

        return codes.map { code in
            let full = textByCode[code] ?? ""
            let title: String
            if let dot = full.range(of: ". ") {
                title = String(full[..<dot.lowerBound])
            } else if full.count > 80 {
                title = String(full.prefix(80)) + "\u{2026}"
            } else {
                title = full
            }
            return IndCEntry(code: code, title: title, text: full)
        }
    }
}

// MARK: - Section View

protocol IndCSectionViewDelegate: AnyObject {
    func indcSectionView(_ view: IndCSectionView, didSelect entry: IndCEntry?)
    func indcSectionView(_ view: IndCSectionView, didChangeOffLabelText text: String)
}

/// Renders the new "Indikationscode (IndC)" section below the medication
/// text view in `KostengutspracheViewController`.
@objc class IndCSectionView: UIView, UITextViewDelegate {

    weak var delegate: IndCSectionViewDelegate?

    private(set) var entries: [IndCEntry] = []
    private(set) var selectedEntry: IndCEntry?
    private(set) var productName: String = ""
    private(set) var gtin: String = ""

    private let stack = UIStackView()
    private let headerLabel = UILabel()
    private let countLabel = UILabel()
    private let productLabel = UILabel()
    private let limTextLabel = UILabel()
    private let limContainer = UIView()
    private let warningContainer = UIView()
    private let warningTitle = UILabel()
    private let offLabelTextView = UITextView()
    private let offLabelHint = UILabel()

    private var radioRows: [IndCRadioRow] = []

    var selectedCode: String? { selectedEntry?.code }
    var selectedTitle: String? { selectedEntry?.title }
    var selectedText: String? { selectedEntry?.text }
    var offLabelText: String { offLabelTextView.text ?? "" }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .firstBaseline
        headerRow.distribution = .equalSpacing
        headerLabel.text = "Indikationscode (IndC)"
        headerLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headerLabel.textColor = .secondaryLabel
        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .tertiaryLabel
        headerRow.addArrangedSubview(headerLabel)
        headerRow.addArrangedSubview(countLabel)
        stack.addArrangedSubview(headerRow)

        productLabel.font = .systemFont(ofSize: 14)
        productLabel.textColor = .label
        productLabel.numberOfLines = 0
        stack.addArrangedSubview(productLabel)

        limContainer.backgroundColor = UIColor.secondarySystemBackground
        limContainer.layer.cornerRadius = 10
        limContainer.layer.borderWidth = 0.5
        limContainer.layer.borderColor = UIColor.separator.cgColor
        limTextLabel.font = .systemFont(ofSize: 13)
        limTextLabel.textColor = .label
        limTextLabel.numberOfLines = 0
        limTextLabel.translatesAutoresizingMaskIntoConstraints = false
        limContainer.addSubview(limTextLabel)
        NSLayoutConstraint.activate([
            limTextLabel.topAnchor.constraint(equalTo: limContainer.topAnchor, constant: 10),
            limTextLabel.leadingAnchor.constraint(equalTo: limContainer.leadingAnchor, constant: 12),
            limTextLabel.trailingAnchor.constraint(equalTo: limContainer.trailingAnchor, constant: -12),
            limTextLabel.bottomAnchor.constraint(equalTo: limContainer.bottomAnchor, constant: -10),
        ])
        stack.addArrangedSubview(limContainer)

        warningContainer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        warningContainer.layer.cornerRadius = 10
        warningContainer.layer.borderWidth = 0.5
        warningContainer.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.35).cgColor
        warningTitle.text = "\u{26A0}\u{FE0E} Kostengutsprache erforderlich"
        warningTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        warningTitle.textColor = UIColor(red: 0.55, green: 0.27, blue: 0.0, alpha: 1.0)
        warningTitle.numberOfLines = 0
        warningTitle.translatesAutoresizingMaskIntoConstraints = false
        warningContainer.addSubview(warningTitle)

        let warningSub = UILabel()
        warningSub.text = "Vorg\u{00E4}ngige Konsultation des Vertrauensarztes n\u{00F6}tig."
        warningSub.font = .systemFont(ofSize: 12)
        warningSub.textColor = .secondaryLabel
        warningSub.numberOfLines = 0
        warningSub.translatesAutoresizingMaskIntoConstraints = false
        warningContainer.addSubview(warningSub)

        NSLayoutConstraint.activate([
            warningTitle.topAnchor.constraint(equalTo: warningContainer.topAnchor, constant: 10),
            warningTitle.leadingAnchor.constraint(equalTo: warningContainer.leadingAnchor, constant: 12),
            warningTitle.trailingAnchor.constraint(equalTo: warningContainer.trailingAnchor, constant: -12),
            warningSub.topAnchor.constraint(equalTo: warningTitle.bottomAnchor, constant: 2),
            warningSub.leadingAnchor.constraint(equalTo: warningContainer.leadingAnchor, constant: 12),
            warningSub.trailingAnchor.constraint(equalTo: warningContainer.trailingAnchor, constant: -12),
            warningSub.bottomAnchor.constraint(equalTo: warningContainer.bottomAnchor, constant: -10),
        ])
        stack.addArrangedSubview(warningContainer)

        offLabelHint.text = "Kein BAG-Indikationscode vorhanden. Falls Off-Label nach KVV Art. 71b/c, Begr\u{00FC}ndung erfassen:"
        offLabelHint.font = .systemFont(ofSize: 13)
        offLabelHint.textColor = .secondaryLabel
        offLabelHint.numberOfLines = 0

        offLabelTextView.font = .systemFont(ofSize: 14)
        offLabelTextView.layer.borderColor = UIColor.separator.cgColor
        offLabelTextView.layer.borderWidth = 0.5
        offLabelTextView.layer.cornerRadius = 8
        offLabelTextView.delegate = self
        offLabelTextView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        stack.addArrangedSubview(offLabelHint)
        stack.addArrangedSubview(offLabelTextView)

        updateVisibility()
    }

    // MARK: - Public API

    /// Configure the section with parsed IndC entries. Pass empty array
    /// for products without an IndC (off-label fallback shown).
    @objc func configure(productName: String, gtin: String,
                         codeString: String?, textString: String?) {
        self.productName = productName
        self.gtin = gtin
        self.entries = IndCParser.parse(codeStr: codeString, textStr: textString)
        rebuildRadioRows()
        updateVisibility()

        if entries.count == 1 {
            selectEntry(at: 0)
        } else {
            selectedEntry = nil
            limContainer.isHidden = true
            warningContainer.isHidden = true
        }
        delegate?.indcSectionView(self, didSelect: selectedEntry)
    }

    /// Pre-set the off-label justification (used when round-tripping a saved receipt).
    @objc func setOffLabelText(_ text: String) {
        offLabelTextView.text = text
    }

    /// Re-select an entry by code (used when round-tripping a saved receipt).
    @objc func selectEntry(byCode code: String) {
        if let idx = entries.firstIndex(where: { $0.code == code }) {
            selectEntry(at: idx)
        }
    }

    private func rebuildRadioRows() {
        for row in radioRows {
            stack.removeArrangedSubview(row)
            row.removeFromSuperview()
        }
        radioRows.removeAll()

        // Insert new ones after productLabel (header at 0, productLabel at 1)
        for (i, entry) in entries.enumerated() {
            let row = IndCRadioRow(entry: entry)
            row.tapHandler = { [weak self] in self?.selectEntry(at: i) }
            stack.insertArrangedSubview(row, at: 2 + i)
            radioRows.append(row)
        }
    }

    private func selectEntry(at idx: Int) {
        guard entries.indices.contains(idx) else { return }
        selectedEntry = entries[idx]
        for (i, row) in radioRows.enumerated() {
            row.setSelected(i == idx)
        }
        if let entry = selectedEntry {
            limTextLabel.text = entry.text
            limContainer.isHidden = entry.text.isEmpty
            warningContainer.isHidden = !entry.requiresKoGu
        }
        delegate?.indcSectionView(self, didSelect: selectedEntry)
    }

    private func updateVisibility() {
        let hasEntries = !entries.isEmpty
        productLabel.isHidden = !hasEntries
        for row in radioRows { row.isHidden = !hasEntries }

        offLabelHint.isHidden = hasEntries
        offLabelTextView.isHidden = hasEntries

        if !hasEntries {
            limContainer.isHidden = true
            warningContainer.isHidden = true
            countLabel.text = productName.isEmpty ? "" : "0 Indikationen \u{00B7} KVV 71b/c"
            productLabel.text = nil
        } else {
            countLabel.text = entries.count == 1
                ? "1 Indikation \u{00B7} auto"
                : "\(entries.count) Indikationen"
            let attr = NSMutableAttributedString(
                string: productName,
                attributes: [.font: UIFont.systemFont(ofSize: 14)])
            if !gtin.isEmpty {
                attr.append(NSAttributedString(
                    string: "  \(gtin)",
                    attributes: [
                        .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                        .foregroundColor: UIColor.tertiaryLabel,
                    ]))
            }
            productLabel.attributedText = attr
        }
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        delegate?.indcSectionView(self, didChangeOffLabelText: textView.text ?? "")
    }
}

// MARK: - Radio Row

private class IndCRadioRow: UIControl {
    private let entry: IndCEntry
    private let dot = UIView()
    private let codePill = PaddedLabel()
    private let koguPill = PaddedLabel()
    private let titleLabel = UILabel()
    var tapHandler: (() -> Void)?

    init(entry: IndCEntry) {
        self.entry = entry
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 0.5

        dot.layer.cornerRadius = 11
        dot.layer.borderWidth = 2
        dot.layer.borderColor = UIColor.tertiaryLabel.cgColor
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.isUserInteractionEnabled = false
        addSubview(dot)

        codePill.text = entry.code
        codePill.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        codePill.textColor = .label
        codePill.backgroundColor = UIColor.tertiaryLabel.withAlphaComponent(0.12)
        codePill.layer.cornerRadius = 4
        codePill.layer.masksToBounds = true
        codePill.textInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        codePill.translatesAutoresizingMaskIntoConstraints = false

        koguPill.text = "KoGu"
        koguPill.font = .systemFont(ofSize: 9, weight: .heavy)
        koguPill.textColor = UIColor(red: 0.55, green: 0.27, blue: 0.0, alpha: 1.0)
        koguPill.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.16)
        koguPill.layer.cornerRadius = 4
        koguPill.layer.masksToBounds = true
        koguPill.textInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        koguPill.isHidden = !entry.requiresKoGu
        koguPill.translatesAutoresizingMaskIntoConstraints = false

        let pillRow = UIStackView(arrangedSubviews: [codePill, koguPill])
        pillRow.axis = .horizontal
        pillRow.spacing = 6
        pillRow.alignment = .center
        pillRow.translatesAutoresizingMaskIntoConstraints = false
        pillRow.isUserInteractionEnabled = false
        addSubview(pillRow)

        titleLabel.text = entry.title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isUserInteractionEnabled = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 22),
            dot.heightAnchor.constraint(equalToConstant: 22),
            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            dot.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            pillRow.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 10),
            pillRow.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            pillRow.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),

            titleLabel.leadingAnchor.constraint(equalTo: pillRow.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: pillRow.bottomAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    @objc private func tapped() { tapHandler?() }

    func setSelected(_ on: Bool) {
        if on {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
            dot.layer.borderColor = UIColor.systemBlue.cgColor
            dot.backgroundColor = UIColor.systemBlue
            dot.subviews.forEach { $0.removeFromSuperview() }
            let inner = UIView()
            inner.backgroundColor = .white
            inner.layer.cornerRadius = 4
            inner.translatesAutoresizingMaskIntoConstraints = false
            dot.addSubview(inner)
            NSLayoutConstraint.activate([
                inner.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                inner.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
                inner.widthAnchor.constraint(equalToConstant: 8),
                inner.heightAnchor.constraint(equalToConstant: 8),
            ])
        } else {
            backgroundColor = .systemBackground
            dot.layer.borderColor = UIColor.tertiaryLabel.cgColor
            dot.backgroundColor = .clear
            dot.subviews.forEach { $0.removeFromSuperview() }
        }
    }
}

// Padded label so pill backgrounds get proper inset around text.
private class PaddedLabel: UILabel {
    var textInsets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + textInsets.left + textInsets.right,
                      height: s.height + textInsets.top + textInsets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let s = super.sizeThatFits(size)
        return CGSize(width: s.width + textInsets.left + textInsets.right,
                      height: s.height + textInsets.top + textInsets.bottom)
    }
}
