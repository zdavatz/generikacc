//
//  InteractionsViewController.swift
//  Generika
//
//  Copyright (c) 2024-2026 ywesee GmbH. All rights reserved.
//

import UIKit
import WebKit

@objc class InteractionsViewController: UIViewController {
    private var webView: WKWebView!
    private var products: [Product]

    @objc init(products: [Product]) {
        self.products = products
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interaktionen"
        view.backgroundColor = .white

        setupWebView()
        setupCloseButton()
        loadInteractions()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupCloseButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(closeTapped))
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func loadInteractions() {
        let results = InteractionsManager.shared.checkInteractions(forProducts: products)
        let html = generateHTML(results: results, products: products)
        webView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - HTML Generation

    private func generateHTML(results: [InteractionResult], products: [Product]) -> String {
        let colorCss = loadCSS("color-scheme-light")
        let darkColorCss = loadCSS("color-scheme-dark")

        var html = """
        <html>
        <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="initial-scale=1.0" />
        <meta name="supported-color-schemes" content="light dark" />
        <style type="text/css">\(colorCss)</style>
        <style type="text/css">
        @media (prefers-color-scheme: dark) {
            \(darkColorCss)
        }
        </style>
        <style type="text/css">
        body {
            font-family: -apple-system, "Helvetica Neue", Helvetica, sans-serif;
            margin: 10px;
            font-size: 14px;
        }
        h2 { font-size: 1.1em; margin-top: 1em; }
        .basket-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 1em;
            font-size: 0.9em;
        }
        .basket-table td {
            padding: 4px 8px;
            border-bottom: 1px solid #ddd;
        }
        .basket-table tr:nth-child(even) { background-color: #f5f5f5; }
        @media (prefers-color-scheme: dark) {
            .basket-table tr:nth-child(even) { background-color: #333; }
            .basket-table td { border-bottom-color: #555; }
        }
        .interaction-entry {
            margin-bottom: 12px;
        }
        .interaction-header {
            border-radius: 6px;
            padding: 8px 12px;
            font-size: 0.95em;
            margin-bottom: 4px;
        }
        .interaction-desc {
            padding: 6px 12px;
            font-size: 0.85em;
            background-color: #f0f0f0;
            border-radius: 4px;
            margin-bottom: 2px;
        }
        @media (prefers-color-scheme: dark) {
            .interaction-desc { background-color: #2a2a2a; }
        }
        .interaction-explain {
            padding: 4px 12px;
            font-size: 0.8em;
            color: #888;
        }
        .type-badge {
            font-size: 0.85em;
            opacity: 0.8;
        }
        .legend-table td {
            padding: 4px 8px;
        }
        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 3px;
        }
        .no-interactions {
            padding: 20px;
            text-align: center;
            color: #888;
            font-size: 1em;
        }
        .footnote {
            font-size: 0.75em;
            color: #888;
            margin-top: 2em;
        }
        </style>
        </head>
        <body>
        """

        // Basket table
        html += "<h2>Medikamentenkorb</h2>"
        html += "<table class=\"basket-table\">"
        for (i, product) in products.enumerated() {
            let name = escapeHtml(product.name ?? product.ean ?? "?")
            let ean = escapeHtml(product.ean ?? "")
            html += "<tr><td>\(i + 1)</td><td>\(ean)</td><td>\(name)</td></tr>"
        }
        html += "</table>"

        if results.isEmpty {
            html += "<div class=\"no-interactions\">"
            html += "Zur Zeit sind keine Interaktionen zwischen diesen Medikamenten in der SDIF-Datenbank vorhanden. "
            html += "Weitere Informationen finden Sie in der Fachinformation."
            html += "</div>"
        } else {
            // Interaction results
            html += "<h2>Interaktionen</h2>"
            for ir in results {
                let color = InteractionsManager.severityColor(ir.severityScore)
                let typeBadge: String
                switch ir.interactionType {
                case "substance": typeBadge = "Wirkstoff"
                case "class-level": typeBadge = "Klasse"
                case "CYP": typeBadge = "CYP"
                default: typeBadge = ir.interactionType
                }

                html += "<div class=\"interaction-entry\">"
                html += "<div class=\"interaction-header\" style=\"background-color:\(color);color:#000;\">"
                html += "<b>\(escapeHtml(ir.drugA)) &harr; \(escapeHtml(ir.drugB))</b>"
                html += " &nbsp;<span class=\"type-badge\">[\(typeBadge)]</span>"
                html += " &nbsp;<span class=\"type-badge\">\(escapeHtml(ir.severityIndicator)) \(escapeHtml(ir.severityLabel))</span>"
                html += "</div>"

                html += "<div class=\"interaction-desc\">"
                if !ir.keyword.isEmpty {
                    html += "<b>\(escapeHtml(ir.keyword)):</b> "
                }
                html += escapeHtml(ir.interactionDescription)
                html += "</div>"

                if !ir.explanation.isEmpty {
                    html += "<div class=\"interaction-explain\">\(escapeHtml(ir.explanation))</div>"
                }
                html += "</div>"
            }

            // Legend
            html += "<h2>Legende</h2>"
            html += "<table class=\"legend-table\">"
            html += "<tr><td><div class=\"legend-color\" style=\"background-color:#ff6a6a;\"></div></td><td><b>###</b></td><td>Kontraindiziert</td></tr>"
            html += "<tr><td><div class=\"legend-color\" style=\"background-color:#ff82ab;\"></div></td><td><b>##</b></td><td>Schwerwiegend</td></tr>"
            html += "<tr><td><div class=\"legend-color\" style=\"background-color:#ffb90f;\"></div></td><td><b>#</b></td><td>Vorsicht</td></tr>"
            html += "<tr><td><div class=\"legend-color\" style=\"background-color:#caff70;\"></div></td><td><b>-</b></td><td>Keine Einstufung</td></tr>"
            html += "</table>"
        }

        html += "<p class=\"footnote\">Datenquelle: SDIF (Swiss Drug Interaction Finder) — basierend auf Swissmedic-Fachinformationen.</p>"
        html += "</body></html>"
        return html
    }

    private func loadCSS(_ name: String) -> String {
        guard let path = Bundle.main.path(forResource: name, ofType: "css"),
              let css = try? String(contentsOfFile: path, encoding: .utf8) else {
            return ""
        }
        return css
    }

    private func escapeHtml(_ s: String) -> String {
        return s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
