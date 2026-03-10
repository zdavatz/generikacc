//
//  InteractionsManager.swift
//  Generika
//
//  Copyright (c) 2024-2026 ywesee GmbH. All rights reserved.
//

import Foundation
import SQLite3

@objc class BasketDrug: NSObject {
    @objc let brand: String
    @objc let substances: [String]
    @objc let atcCode: String
    @objc let interactionsText: String

    init(brand: String, substances: [String], atcCode: String, interactionsText: String) {
        self.brand = brand
        self.substances = substances
        self.atcCode = atcCode
        self.interactionsText = interactionsText
    }
}

@objc class InteractionResult: NSObject {
    @objc let drugA: String
    @objc let drugAAtc: String
    @objc let drugB: String
    @objc let drugBAtc: String
    @objc let interactionType: String // "substance", "class-level", "CYP"
    @objc let severityScore: Int      // 0-3
    @objc let severityLabel: String
    @objc let severityIndicator: String
    @objc let keyword: String
    @objc let interactionDescription: String
    @objc let explanation: String

    init(drugA: String, drugAAtc: String, drugB: String, drugBAtc: String,
         interactionType: String, severityScore: Int, severityLabel: String,
         severityIndicator: String, keyword: String, interactionDescription: String,
         explanation: String) {
        self.drugA = drugA
        self.drugAAtc = drugAAtc
        self.drugB = drugB
        self.drugBAtc = drugBAtc
        self.interactionType = interactionType
        self.severityScore = severityScore
        self.severityLabel = severityLabel
        self.severityIndicator = severityIndicator
        self.keyword = keyword
        self.interactionDescription = interactionDescription
        self.explanation = explanation
    }
}

// MARK: - InteractionsManager

@objc class InteractionsManager: NSObject {
    @objc static let shared = InteractionsManager()

    private var db: OpaquePointer?
    private var downloadTask: URLSessionDownloadTask?

    private override init() {
        super.init()
    }

    // MARK: - Database Paths

    private var externalDBPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let dbDir = (documentsDirectory as NSString).appendingPathComponent("database")
        try? FileManager.default.createDirectory(atPath: dbDir, withIntermediateDirectories: true)
        return (dbDir as NSString).appendingPathComponent("interactions.db")
    }

    private var dbPath: String? {
        if FileManager.default.fileExists(atPath: externalDBPath) {
            return externalDBPath
        }
        return Bundle.main.path(forResource: "interactions", ofType: "db")
    }

    private func openDatabase() -> Bool {
        if db != nil { return true }

        guard let path = dbPath else {
            NSLog("interactions.db not found")
            return false
        }

        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            NSLog("Failed to open interactions.db")
            db = nil
            return false
        }
        return true
    }

    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }

    @objc func reopen() {
        closeDatabase()
        _ = openDatabase()
    }

    // MARK: - Download Update

    @objc func downloadNewDatabase(_ callback: @escaping (Error?) -> Void) -> URLSessionDownloadTask {
        if let existing = downloadTask {
            existing.cancel()
        }

        let url = URL(string: "http://pillbox.oddb.org/interactions.db")!
        let task = URLSession.shared.downloadTask(with: url) { [weak self] location, response, error in
            guard let self = self else { return }
            self.downloadTask = nil

            if let error = error {
                callback(error)
                return
            }
            guard let location = location else {
                callback(NSError(domain: "InteractionsManager", code: -1,
                                 userInfo: [NSLocalizedDescriptionKey: "No file downloaded"]))
                return
            }

            do {
                self.closeDatabase()
                let destPath = self.externalDBPath
                try? FileManager.default.removeItem(atPath: destPath)
                try FileManager.default.moveItem(atPath: location.path, toPath: destPath)
                callback(nil)
            } catch {
                callback(error)
            }
        }
        self.downloadTask = task
        task.resume()
        return task
    }

    @objc func databaseLastUpdate() -> String? {
        guard let path = dbPath else { return nil }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let date = attrs[.modificationDate] as? Date else { return nil }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }

    @objc func dbStat() -> String? {
        guard openDatabase() else { return nil }
        var drugCount: Int32 = 0
        var interactionCount: Int32 = 0
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, "SELECT count(*) FROM drugs", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                drugCount = sqlite3_column_int(stmt, 0)
            }
        }
        sqlite3_finalize(stmt)
        stmt = nil

        if sqlite3_prepare_v2(db, "SELECT count(*) FROM interactions", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                interactionCount = sqlite3_column_int(stmt, 0)
            }
        }
        sqlite3_finalize(stmt)

        return "The database contains:\n- \(drugCount) Drugs\n- \(interactionCount) Interactions"
    }

    // MARK: - Drug Resolution

    @objc func resolveDrug(forProduct product: Product) -> BasketDrug? {
        guard openDatabase() else { return nil }

        // Strategy 1: Match by product name -> brand_name
        if let name = product.name, !name.isEmpty {
            let brandSearch = name.components(separatedBy: CharacterSet(charactersIn: ",("))[0].trimmingCharacters(in: .whitespaces)
            if !brandSearch.isEmpty, let drug = findDrugByBrand(brandSearch) {
                return drug
            }
        }

        // Strategy 2: Match by ATC code
        if let atc = product.atc, !atc.isEmpty {
            let atcCode = atc.components(separatedBy: CharacterSet(charactersIn: ";,"))[0].trimmingCharacters(in: .whitespaces)
            if !atcCode.isEmpty, let drug = findDrugByATC(atcCode) {
                return drug
            }
        }

        // Strategy 3: Use AmikoDBManager to get title, then match
        if let ean = product.ean, !ean.isEmpty {
            let rows = AmikoDBManager.shared().find(withGtin: ean, type: "")
            if let row = rows.first {
                let titleSearch = row.title.components(separatedBy: CharacterSet(charactersIn: ",("))[0].trimmingCharacters(in: .whitespaces)
                if !titleSearch.isEmpty, let drug = findDrugByBrand(titleSearch) {
                    return drug
                }
            }
        }

        return nil
    }

    private func findDrugByBrand(_ brand: String) -> BasketDrug? {
        let sql = "SELECT brand_name, active_substances, atc_code, interactions_text FROM drugs WHERE brand_name LIKE ? ORDER BY length(interactions_text) DESC"
        var stmt: OpaquePointer?
        let pattern = "%\(brand)%"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (pattern as NSString).utf8String, -1, nil)
        if sqlite3_step(stmt) == SQLITE_ROW {
            return basketDrugFromStatement(stmt)
        }
        return nil
    }

    private func findDrugByATC(_ atc: String) -> BasketDrug? {
        let sql = "SELECT brand_name, active_substances, atc_code, interactions_text FROM drugs WHERE atc_code = ? ORDER BY length(interactions_text) DESC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (atc as NSString).utf8String, -1, nil)
        if sqlite3_step(stmt) == SQLITE_ROW {
            return basketDrugFromStatement(stmt)
        }
        return nil
    }

    private func basketDrugFromStatement(_ stmt: OpaquePointer?) -> BasketDrug {
        let brand = columnText(stmt, 0)
        let substStr = columnText(stmt, 1)
        let atc = columnText(stmt, 2)
        let text = columnText(stmt, 3)
        let substances = substStr.isEmpty ? [] : substStr.components(separatedBy: ", ").map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        return BasketDrug(brand: brand, substances: substances, atcCode: atc, interactionsText: text)
    }

    private func columnText(_ stmt: OpaquePointer?, _ col: Int32) -> String {
        if let cStr = sqlite3_column_text(stmt, col) {
            return String(cString: cStr)
        }
        return ""
    }

    // MARK: - Interaction Checking

    @objc func checkInteractions(forProducts products: [Product]) -> [InteractionResult] {
        guard openDatabase() else { return [] }

        // Resolve all products to basket drugs
        var basketDrugs: [BasketDrug] = []
        for product in products {
            if let drug = resolveDrug(forProduct: product) {
                basketDrugs.append(drug)
            }
        }

        var results: [InteractionResult] = []

        for i in 0..<basketDrugs.count {
            for j in (i + 1)..<basketDrugs.count {
                let a = basketDrugs[i]
                let b = basketDrugs[j]

                // Strategy 1: Substance match A->B and B->A
                for subst in b.substances {
                    results.append(contentsOf: substanceMatches(source: a, other: b, substance: subst))
                }
                for subst in a.substances {
                    results.append(contentsOf: substanceMatches(source: b, other: a, substance: subst))
                }

                // Strategy 2: Class-level A->B and B->A
                for hit in findClassInteractions(text: a.interactionsText, otherAtc: b.atcCode) {
                    let sev = InteractionsManager.scoreSeverity(hit.context)
                    let classDesc = InteractionsManager.atcClassDescription(forCode: b.atcCode)
                    results.append(InteractionResult(
                        drugA: a.brand, drugAAtc: a.atcCode,
                        drugB: b.brand, drugBAtc: b.atcCode,
                        interactionType: "class-level", severityScore: sev,
                        severityLabel: InteractionsManager.severityLabel(sev),
                        severityIndicator: InteractionsManager.severityIndicatorStr(sev),
                        keyword: hit.keyword,
                        interactionDescription: hit.context,
                        explanation: "\(b.brand) [\(b.atcCode)] gehört zur Klasse \(classDesc) — Keyword «\(hit.keyword)» gefunden in Fachinformation von \(a.brand)"
                    ))
                }
                for hit in findClassInteractions(text: b.interactionsText, otherAtc: a.atcCode) {
                    let sev = InteractionsManager.scoreSeverity(hit.context)
                    let classDesc = InteractionsManager.atcClassDescription(forCode: a.atcCode)
                    results.append(InteractionResult(
                        drugA: b.brand, drugAAtc: b.atcCode,
                        drugB: a.brand, drugBAtc: a.atcCode,
                        interactionType: "class-level", severityScore: sev,
                        severityLabel: InteractionsManager.severityLabel(sev),
                        severityIndicator: InteractionsManager.severityIndicatorStr(sev),
                        keyword: hit.keyword,
                        interactionDescription: hit.context,
                        explanation: "\(a.brand) [\(a.atcCode)] gehört zur Klasse \(classDesc) — Keyword «\(hit.keyword)» gefunden in Fachinformation von \(b.brand)"
                    ))
                }

                // Strategy 3: CYP A->B and B->A
                for hit in findCypInteractions(text: a.interactionsText, otherAtc: b.atcCode, otherSubstances: b.substances) {
                    let sev = InteractionsManager.scoreSeverity(hit.context)
                    results.append(InteractionResult(
                        drugA: a.brand, drugAAtc: a.atcCode,
                        drugB: b.brand, drugBAtc: b.atcCode,
                        interactionType: "CYP", severityScore: sev,
                        severityLabel: InteractionsManager.severityLabel(sev),
                        severityIndicator: InteractionsManager.severityIndicatorStr(sev),
                        keyword: hit.keyword,
                        interactionDescription: hit.context,
                        explanation: "\(b.brand) ist \(hit.keyword) — Fachinformation von \(a.brand) erwähnt dieses Enzym"
                    ))
                }
                for hit in findCypInteractions(text: b.interactionsText, otherAtc: a.atcCode, otherSubstances: a.substances) {
                    let sev = InteractionsManager.scoreSeverity(hit.context)
                    results.append(InteractionResult(
                        drugA: b.brand, drugAAtc: b.atcCode,
                        drugB: a.brand, drugBAtc: a.atcCode,
                        interactionType: "CYP", severityScore: sev,
                        severityLabel: InteractionsManager.severityLabel(sev),
                        severityIndicator: InteractionsManager.severityIndicatorStr(sev),
                        keyword: hit.keyword,
                        interactionDescription: hit.context,
                        explanation: "\(a.brand) ist \(hit.keyword) — Fachinformation von \(b.brand) erwähnt dieses Enzym"
                    ))
                }
            }
        }

        // Sort by severity descending
        results.sort { $0.severityScore > $1.severityScore }
        return results
    }

    // MARK: - Strategy 1: Substance Lookup

    private func substanceMatches(source: BasketDrug, other: BasketDrug, substance: String) -> [InteractionResult] {
        let sql = "SELECT description, severity_score, severity_label FROM interactions WHERE drug_brand = ? AND interacting_substance = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (source.brand as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (substance as NSString).utf8String, -1, nil)

        var results: [InteractionResult] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let desc = columnText(stmt, 0)
            let score = Int(sqlite3_column_int(stmt, 1))
            let label = columnText(stmt, 2)
            results.append(InteractionResult(
                drugA: source.brand, drugAAtc: source.atcCode,
                drugB: other.brand, drugBAtc: other.atcCode,
                interactionType: "substance", severityScore: score,
                severityLabel: label,
                severityIndicator: InteractionsManager.severityIndicatorStr(score),
                keyword: substance,
                interactionDescription: desc,
                explanation: "Wirkstoff «\(substance)» wird in der Fachinformation von \(source.brand) erwähnt"
            ))
        }
        return results
    }

    // MARK: - Strategy 2: Class-Level Interactions

    private struct ClassHit {
        let keyword: String
        let context: String
    }

    private func findClassInteractions(text: String, otherAtc: String) -> [ClassHit] {
        guard !text.isEmpty, !otherAtc.isEmpty else { return [] }
        let textLower = text.lowercased()
        var hits: [ClassHit] = []

        for entry in InteractionsManager.classKeywords {
            let atcPrefix = entry[0]
            guard otherAtc.hasPrefix(atcPrefix) else { continue }
            for i in 1..<entry.count {
                let keyword = entry[i]
                if textLower.contains(keyword) {
                    let context = InteractionsManager.extractContext(text: text, keyword: keyword)
                    if !context.isEmpty {
                        hits.append(ClassHit(keyword: keyword, context: context))
                        break
                    }
                }
            }
        }
        return hits
    }

    // MARK: - Strategy 3: CYP Enzyme Interactions

    private func findCypInteractions(text: String, otherAtc: String, otherSubstances: [String]) -> [ClassHit] {
        guard !text.isEmpty else { return [] }
        let textLower = text.lowercased()
        let otherSubstLower = otherSubstances.map { $0.lowercased() }
        var hits: [ClassHit] = []

        for cyp in InteractionsManager.cypMap {
            let enzyme = cyp.enzyme
            let mentioned = cyp.patterns.contains { textLower.contains($0) }
            guard mentioned else { continue }

            let isInhibitor = cyp.inhibAtc.contains { otherAtc.hasPrefix($0) }
                || cyp.inhibSubst.contains { otherSubstLower.contains($0) }
            let isInducer = cyp.inducAtc.contains { otherAtc.hasPrefix($0) }
                || cyp.inducSubst.contains { otherSubstLower.contains($0) }

            if isInhibitor || isInducer {
                let role = isInhibitor ? "Hemmer" : "Induktor"
                let context = InteractionsManager.extractContext(text: text, keyword: cyp.patterns[0])
                if !context.isEmpty {
                    hits.append(ClassHit(keyword: "\(enzyme)-\(role)", context: context))
                }
            }
        }
        return hits
    }

    // MARK: - Severity Scoring

    static func scoreSeverity(_ text: String) -> Int {
        let lower = text.lowercased()
        for kw in contraindicatedKeywords {
            if lower.contains(kw) { return 3 }
        }
        for kw in seriousKeywords {
            if lower.contains(kw) { return 2 }
        }
        for kw in cautionKeywords {
            if lower.contains(kw) { return 1 }
        }
        return 0
    }

    static func severityLabel(_ score: Int) -> String {
        switch score {
        case 3: return "Kontraindiziert"
        case 2: return "Schwerwiegend"
        case 1: return "Vorsicht"
        default: return "Keine Einstufung"
        }
    }

    static func severityIndicatorStr(_ score: Int) -> String {
        switch score {
        case 3: return "###"
        case 2: return "##"
        case 1: return "#"
        default: return "-"
        }
    }

    @objc static func severityColor(_ score: Int) -> String {
        switch score {
        case 3: return "#ff6a6a"
        case 2: return "#ff82ab"
        case 1: return "#ffb90f"
        default: return "#caff70"
        }
    }

    // MARK: - Context Extraction

    static func extractContext(text: String, keyword: String) -> String {
        let lower = text.lowercased()
        let keyLower = keyword.lowercased()
        var bestSnippet = ""
        var bestSeverity = -1
        var searchFrom = lower.startIndex

        while searchFrom < lower.endIndex {
            guard let range = lower.range(of: keyLower, range: searchFrom..<lower.endIndex) else { break }
            let pos = range.lowerBound

            // Find sentence boundaries
            var start = lower.startIndex
            var idx = lower.index(before: pos)
            while idx > lower.startIndex {
                let c = lower[idx]
                if c == "." || c == ":" {
                    start = lower.index(after: idx)
                    break
                }
                idx = lower.index(before: idx)
            }

            var end = lower.endIndex
            if let dotRange = lower.range(of: ".", range: pos..<lower.endIndex) {
                end = lower.index(after: dotRange.lowerBound)
            }

            let snippet = String(text[start..<end]).trimmingCharacters(in: .whitespaces)
            let sev = scoreSeverity(snippet)

            if sev > bestSeverity || bestSnippet.isEmpty {
                bestSeverity = sev
                bestSnippet = snippet.count > 500 ? String(snippet.prefix(497)) + "..." : snippet
                if bestSeverity >= 3 { break }
            }

            searchFrom = range.upperBound
        }

        return bestSnippet
    }

    // MARK: - ATC Class Description

    static func atcClassDescription(forCode atcCode: String) -> String {
        for prefix in atcPrefixOrder {
            if atcCode.hasPrefix(prefix) {
                return atcClassDescriptions[prefix] ?? ""
            }
        }
        return ""
    }

    // MARK: - Static Data

    private static let contraindicatedKeywords = [
        "kontraindiziert", "kontraindikation", "darf nicht",
        "nicht angewendet werden", "nicht verabreicht werden",
        "nicht kombiniert werden", "nicht gleichzeitig",
        "ist verboten", "absolut kontraindiziert", "streng kontraindiziert",
        "nicht zusammen", "nicht eingenommen werden", "nicht anwenden"
    ]

    private static let seriousKeywords = [
        "erhöhtes risiko", "erhöhte gefahr", "schwerwiegend", "schwere",
        "lebensbedrohlich", "lebensgefährlich", "gefährlich",
        "stark erhöht", "stark verstärkt", "toxisch", "toxizität",
        "nephrotoxisch", "hepatotoxisch", "ototoxisch", "neurotoxisch", "kardiotoxisch",
        "tödlich", "fatale", "blutungsrisiko", "blutungsgefahr",
        "serotoninsyndrom", "serotonin-syndrom", "qt-verlängerung", "qt-zeit-verlängerung",
        "torsade", "rhabdomyolyse", "nierenversagen", "niereninsuffizienz",
        "nierenfunktionsstörung", "leberversagen", "atemdepression", "herzstillstand",
        "arrhythmie", "hyperkaliämie", "agranulozytose",
        "stevens-johnson", "anaphyla", "lymphoproliferation",
        "immundepression", "immunsuppression", "panzytopenie",
        "abgeraten", "wird nicht empfohlen"
    ]

    private static let cautionKeywords = [
        "vorsicht", "überwach", "monitor", "kontroll", "engmaschig",
        "dosisanpassung", "dosis reduz", "dosis anpassen", "dosisreduktion",
        "sorgfältig", "regelmässig", "regelmäßig", "aufmerksam",
        "cave", "beobacht", "verstärkt", "vermindert", "abgeschwächt",
        "erhöht", "erniedrigt", "beeinflusst", "wechselwirkung",
        "plasmaspiegel", "serumkonzentration", "bioverfügbarkeit",
        "subtherapeutisch", "supratherapeutisch", "therapieversagen",
        "wirkungsverlust", "wirkverlust"
    ]

    private static let classKeywords: [[String]] = [
        ["B01A", "antikoagul", "warfarin", "cumarin", "coumarin", "vitamin-k-antagonist",
         "vitamin k antagonist", "blutgerinnungshemm", "thrombozytenaggregationshemm",
         "plättchenhemm", "antithrombotisch", "heparin", "thrombin-hemm",
         "faktor-xa", "direktes orales antikoagulans", "doak"],
        ["B01AC", "thrombozytenaggregationshemm", "plättchenhemm", "thrombocytenaggregation"],
        ["M01A", "nsar", "nsaid", "nichtsteroidale antiphlogistika", "antiphlogistika",
         "nichtsteroidale antirheumatika", "cox-2", "cox-hemmer", "cyclooxygenase",
         "prostaglandinsynthesehemm", "entzündungshemm"],
        ["N02B", "analgetik", "antipyretik", "acetylsalicylsäure", "paracetamol"],
        ["N02A", "opioid", "opiat", "morphin", "atemdepression", "zns-depression"],
        ["C09A", "ace-hemmer", "ace-inhibitor", "ace inhibitor", "angiotensin-converting"],
        ["C09B", "ace-hemmer", "ace-inhibitor", "angiotensin-converting"],
        ["C09C", "angiotensin", "sartan", "at1-rezeptor", "at1-antagonist", "at1-blocker"],
        ["C09D", "angiotensin", "sartan", "at1-rezeptor", "at1-antagonist"],
        ["C07", "beta-blocker", "betablocker", "\u{03b2}-blocker", "betarezeptorenblocker", "beta-adrenozeptor"],
        ["C08", "calciumantagonist", "calciumkanalblocker", "kalziumantagonist",
         "kalziumkanalblocker", "calcium-antagonist"],
        ["C03", "diuretik", "thiazid", "schleifendiuretik", "kaliumsparend"],
        ["C03C", "schleifendiuretik", "furosemid", "torasemid"],
        ["C03A", "thiazid", "hydrochlorothiazid"],
        ["C01A", "herzglykosid", "digoxin", "digitalis", "digitoxin"],
        ["C01B", "antiarrhythmi", "amiodaron"],
        ["C10A", "statin", "hmg-coa", "lipidsenk", "cholesterinsenk"],
        ["N06AB", "ssri", "serotonin-wiederaufnahme", "serotonin reuptake",
         "selektive serotonin", "serotonerg"],
        ["N06A", "antidepressiv", "trizyklisch", "serotonin", "snri", "maoh",
         "mao-hemmer", "monoaminoxidase"],
        ["A10", "antidiabetik", "insulin", "blutzucker", "hypoglykämie", "orale antidiabetika",
         "sulfonylharnstoff", "metformin"],
        ["H02", "corticosteroid", "kortikosteroid", "glucocorticoid", "glukokortikoid",
         "kortison", "steroid"],
        ["L04", "immunsuppress", "ciclosporin", "tacrolimus", "mycophenolat", "azathioprin",
         "sirolimus"],
        ["L01", "antineoplast", "zytostatik", "methotrexat", "chemotherap"],
        ["N03", "antiepileptik", "antikonvulsiv", "krampflösend", "carbamazepin",
         "valproinsäure", "phenytoin", "enzymindukt"],
        ["N05A", "antipsychoti", "neuroleptik", "qt-verlänger", "qt-zeit"],
        ["N05B", "anxiolytik", "benzodiazepin"],
        ["N05C", "sedativ", "hypnotik", "schlafmittel", "zns-dämpfend", "zns-depression"],
        ["J01", "antibiotik", "antibakteriell"],
        ["J01FA", "makrolid", "erythromycin", "clarithromycin", "azithromycin"],
        ["J01MA", "fluorchinolon", "chinolon", "gyrasehemm"],
        ["J02A", "antimykotik", "azol-antimykotik", "triazol", "itraconazol",
         "fluconazol", "voriconazol", "cyp3a4-hemm"],
        ["J05A", "antiviral", "proteasehemm", "protease-inhibitor", "hiv"],
        ["A02BC", "protonenpumpeninhibitor", "protonenpumpenhemm", "ppi", "säureblocker"],
        ["A02B", "antazid", "h2-blocker", "h2-antagonist", "säurehemm"],
        ["G03A", "kontrazeptiv", "östrogen", "orale kontrazeptiva", "hormonelle verhütung"],
        ["N07", "dopaminerg", "cholinerg", "anticholinerg"],
        ["R03", "bronchodilatat", "theophyllin", "sympathomimetik", "beta-2"],
        ["M04", "urikosurik", "gichtmittel", "harnsäure", "allopurinol"],
        ["B03", "eisen", "eisenpräparat", "eisensupplementation"],
        ["L02BA", "toremifen", "tamoxifen", "antiöstrogen", "östrogen-rezeptor",
         "serm", "selektive östrogenrezeptor"],
        ["L02B", "hormonantagonist", "antihormon", "antiandrogen", "antiöstrogen"],
        ["V03AB", "sugammadex", "antidot", "antagonisierung", "neuromuskuläre blockade",
         "verdrängung"],
        ["M03A", "muskelrelax", "neuromuskulär", "rocuronium", "vecuronium",
         "succinylcholin", "curare"],
    ]

    private struct CypEntry {
        let enzyme: String
        let patterns: [String]
        let inhibAtc: [String]
        let inhibSubst: [String]
        let inducAtc: [String]
        let inducSubst: [String]
    }

    private static let cypMap: [CypEntry] = [
        CypEntry(enzyme: "CYP3A4", patterns: ["cyp3a4", "cyp3a"],
                 inhibAtc: ["J05AE", "J02A", "J01FA"],
                 inhibSubst: ["ritonavir", "cobicistat", "itraconazol", "ketoconazol",
                              "voriconazol", "posaconazol", "fluconazol", "clarithromycin",
                              "erythromycin", "diltiazem", "verapamil", "grapefruit"],
                 inducAtc: ["J04AB", "N03AF", "N03AB"],
                 inducSubst: ["rifampicin", "rifabutin", "carbamazepin", "phenytoin",
                              "phenobarbital", "johanniskraut", "efavirenz", "nevirapin"]),
        CypEntry(enzyme: "CYP2D6", patterns: ["cyp2d6"],
                 inhibAtc: [],
                 inhibSubst: ["fluoxetin", "paroxetin", "bupropion", "chinidin",
                              "terbinafin", "duloxetin", "ritonavir", "cobicistat"],
                 inducAtc: [],
                 inducSubst: ["rifampicin"]),
        CypEntry(enzyme: "CYP2C9", patterns: ["cyp2c9"],
                 inhibAtc: [],
                 inhibSubst: ["fluconazol", "amiodaron", "miconazol", "voriconazol", "fluvoxamin"],
                 inducAtc: [],
                 inducSubst: ["rifampicin", "carbamazepin", "phenytoin"]),
        CypEntry(enzyme: "CYP2C19", patterns: ["cyp2c19"],
                 inhibAtc: [],
                 inhibSubst: ["omeprazol", "esomeprazol", "fluvoxamin", "fluconazol",
                              "voriconazol", "ticlopidin"],
                 inducAtc: [],
                 inducSubst: ["rifampicin", "carbamazepin", "phenytoin", "johanniskraut"]),
        CypEntry(enzyme: "CYP1A2", patterns: ["cyp1a2"],
                 inhibAtc: ["J01MA"],
                 inhibSubst: ["ciprofloxacin", "fluvoxamin", "enoxacin"],
                 inducAtc: [],
                 inducSubst: ["rifampicin", "carbamazepin", "phenytoin", "johanniskraut"]),
        CypEntry(enzyme: "CYP2C8", patterns: ["cyp2c8"],
                 inhibAtc: [],
                 inhibSubst: ["gemfibrozil", "clopidogrel", "trimethoprim"],
                 inducAtc: [],
                 inducSubst: ["rifampicin"]),
        CypEntry(enzyme: "CYP2B6", patterns: ["cyp2b6"],
                 inhibAtc: [],
                 inhibSubst: ["ticlopidin", "clopidogrel"],
                 inducAtc: [],
                 inducSubst: ["rifampicin", "efavirenz"]),
    ]

    private static let atcClassDescriptions: [String: String] = [
        "B01A": "Antikoagulantien",
        "B01AC": "Thrombozytenaggregationshemmer",
        "M01A": "NSAR (NSAIDs)",
        "N02B": "Analgetika / Antipyretika",
        "N02A": "Opioide",
        "C09A": "ACE-Hemmer",
        "C09B": "ACE-Hemmer (Kombination)",
        "C09C": "Sartane (AT1-Antagonisten)",
        "C09D": "Sartane (Kombination)",
        "C07": "Beta-Blocker",
        "C08": "Calciumkanalblocker",
        "C03": "Diuretika",
        "C03C": "Schleifendiuretika",
        "C03A": "Thiazide",
        "C01A": "Herzglykoside",
        "C01B": "Antiarrhythmika",
        "C10A": "Statine",
        "N06AB": "SSRIs",
        "N06A": "Antidepressiva",
        "A10": "Antidiabetika",
        "H02": "Corticosteroide",
        "L04": "Immunsuppressiva",
        "L01": "Antineoplastika",
        "N03": "Antiepileptika",
        "N05A": "Antipsychotika",
        "N05B": "Anxiolytika",
        "N05C": "Sedativa / Hypnotika",
        "J01": "Antibiotika",
        "J01FA": "Makrolide",
        "J01MA": "Fluorchinolone",
        "J02A": "Antimykotika",
        "J05A": "Antivirale",
        "A02BC": "PPI (Protonenpumpenhemmer)",
        "A02B": "Ulkusmittel",
        "G03A": "Hormonale Kontrazeptiva",
        "N07": "Nervensystem (andere)",
        "R03": "Bronchodilatatoren",
        "M04": "Gichtmittel",
        "B03": "Eisenpräparate",
        "L02BA": "SERMs (Tamoxifen)",
        "L02B": "Hormonantagonisten",
        "V03AB": "Antidota",
        "M03A": "Muskelrelaxantien",
    ]

    private static let atcPrefixOrder = [
        "B01AC", "B01A", "M01A", "N02B", "N02A", "C09A", "C09B", "C09C", "C09D",
        "C07", "C08", "C03C", "C03A", "C03", "C01A", "C01B", "C10A", "N06AB", "N06A",
        "A10", "H02", "L04", "L01", "N03", "N05A", "N05B", "N05C",
        "J01FA", "J01MA", "J01", "J02A", "J05A", "A02BC", "A02B", "G03A", "N07", "R03",
        "M04", "B03", "L02BA", "L02B", "V03AB", "M03A"
    ]
}
