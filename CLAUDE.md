# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Generika.cc is a Swiss pharmacy iOS app (Objective-C + Swift) for medication barcode scanning, e-prescription management, drug interactions checking, drug price comparison, and receipt handling. Licensed GPL-3.0.

## Build & Test Commands

```zsh
# Build (always use workspace, not xcodeproj)
xcodebuild -workspace Generika.xcworkspace -scheme Generika
make build

# Run all tests
make test
OS_VERSION="latest" ./bin/test-runner All

# Run a single test case
OS_VERSION="latest" ./bin/test-runner ProductTests/testInit

# Clean
make clean              # clean build artifacts
make erase              # full cleanup: simulators, DerivedData, build artifacts

# Install dependencies
pod install
```

## Setup Requirements

- Open `Generika.xcworkspace` (NOT `Generika.xcodeproj`)
- ZurRose certificate at `Generika/ZurRose/client.p12`
- Copy `ZurRoseCredential.h.sample` to `ZurRoseCredential.h` and set password
- Optional: `Generika/Databases/amiko_db_full_idx_pinfo_de.db` (generated via cpp2sqlite)
- `Generika/Databases/interactions.db` — drug interactions database (updatable in-app from `http://pillbox.oddb.org/interactions.db`)

## Architecture

**Pattern:** MVC with Singleton Managers

### Data Flow
- **ScannerViewController** captures barcodes (EAN-13) and QR codes (CHMED16A1 e-prescriptions)
- **MasterViewController** is the central hub — manages product/receipt lists with segmented control tabs, orchestrates navigation to all other view controllers
- **ProductManager** / **ReceiptManager** are singleton UIDocument subclasses handling persistence (iCloud-capable)
- **AmikoDBManager** queries the local SQLite drug database by GTIN, REG number, or ATC code
- **InteractionsManager** (Swift) checks drug interactions locally via `interactions.db` using 3 strategies: substance-level, ATC class-level, and CYP enzyme-mediated
- **InteractionsViewController** (Swift) displays interaction results in a WKWebView with color-coded severity; presented full-screen on iPad via `UIModalPresentationFullScreen`
- **KostengutspracheViewController** (Swift) — Kostengutsprache KVV 71 form for IBD Gastroenterology; generates PDF, sends via share sheet; pre-fills from Receipt data and prescription scan; resolves medication names via GTIN lookup in AmiKo DB or OCR for pharmacodes; saves all form data back to Receipt on close (patient address, AHV, insurer name, physician hospital/department); includes IBD diagnosis selector (M. Crohn / Colitis ulcerosa)
- **PrescriptionScannerViewController** (Swift) — Two-stage prescription scanner: live QR detection (CHMED16A) + photo capture with full-page OCR (VNRecognizeTextRequest); extracts medications, dosages, AHV number, ZSR, physician name/title, hospital, department, patient address from prescription documents; pattern-based medication detection (dosage forms: Filmtabl, Tabl, Kaps etc.); merges QR + OCR data for KKV form filling; pharmacode-aware (uses OCR names when idType=3)
- **InsuranceCardScannerViewController** (Swift) — OCR scanner for Swiss health insurance cards using Vision framework; extracts patient name, card number, BAG number, AHV number, birth date, gender; maps BAG to insurer name/GLN via JSON lookup tables

### Key Models
- **Product** — scanned medication (EAN, REG, name, price, expiry); supports NSCoding
- **Receipt** — imported prescription from `.amk` files; contains Operator, Patient (with healthCardNumber, insurerName, ahvNumber), and Products
- **EPrescription** — parsed from CHMED16A1 QR codes; converts to ZurRosePrescription objects

### ZurRose Integration (`Generika/ZurRose/`)
17 files handling prescription submission to the ZurRose pharmacy system with client certificate auth. Key classes: ZurRosePrescription, ZurRoseProduct, ZurRosePosology.

### Managers
- **ProductManager** / **ReceiptManager** — CRUD + file persistence via UIDocument
- **SettingsManager** — Keychain-based credential storage (ZSR number, ZurRose customer number)
- **SessionManager** — Authentication token handling
- **InteractionsManager** (Swift) — local drug interaction search engine + DB update from pillbox.oddb.org

### Networking
- **AFNetworking 4.x** for HTTP requests
- **Reachability** for network status monitoring
- API endpoints configured in `Constant.h` (ODDB base URL, user agents)

## Dependencies

No external dependencies. All previously used CocoaPods have been replaced with built-in iOS APIs.

## Test Files

Located in `GenerikaTests/`: ProductTests, ProductManagerTests, BarcodeExtractorTests, GenerikaTests.

## Important Notes

- "Build Active Architecture Only" must match between Generika and Pods targets
- Platform minimum: iOS 15.0
- Swift/ObjC bridging header: `Generika/Generika-Bridging-Header.h`; auto-generated header is `generika-Swift.h` (PRODUCT_NAME is lowercase `generika`)
- UI is mix of programmatic and XIB (PatinfoViewController, PriceComparisonViewController)
