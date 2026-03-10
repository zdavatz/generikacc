# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Generika.cc is a Swiss pharmacy iOS app (Objective-C) for medication barcode scanning, e-prescription management, drug price comparison, and receipt handling. Licensed GPL-3.0.

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

## Architecture

**Pattern:** MVC with Singleton Managers

### Data Flow
- **ScannerViewController** captures barcodes (EAN-13) and QR codes (CHMED16A1 e-prescriptions)
- **MasterViewController** is the central hub — manages product/receipt lists with segmented control tabs, orchestrates navigation to all other view controllers
- **ProductManager** / **ReceiptManager** are singleton UIDocument subclasses handling persistence (iCloud-capable)
- **AmikoDBManager** queries the local SQLite drug database by GTIN, REG number, or ATC code

### Key Models
- **Product** — scanned medication (EAN, REG, name, price, expiry); supports NSCoding
- **Receipt** — imported prescription from `.amk` files; contains Operator, Patient, and Products
- **EPrescription** — parsed from CHMED16A1 QR codes; converts to ZurRosePrescription objects

### ZurRose Integration (`Generika/ZurRose/`)
17 files handling prescription submission to the ZurRose pharmacy system with client certificate auth. Key classes: ZurRosePrescription, ZurRoseProduct, ZurRosePosology.

### Managers
- **ProductManager** / **ReceiptManager** — CRUD + file persistence via UIDocument
- **SettingsManager** — Keychain-based credential storage (ZSR number, ZurRose customer number)
- **SessionManager** — Authentication token handling

### Networking
- **AFNetworking 3.x** for HTTP requests
- **Reachability** for network status monitoring
- API endpoints configured in `Constant.h` (ODDB base URL, user agents)

## Dependencies (CocoaPods)

AFNetworking, NTMonthYearPicker, GZIP, KissXML, SSZipArchive. Test-only: OCMock.

## Test Files

Located in `GenerikaTests/`: ProductTests, ProductManagerTests, BarcodeExtractorTests, GenerikaTests.

## Important Notes

- "Build Active Architecture Only" must match between Generika and Pods targets
- Platform minimum: iOS 9.0
- UI is mix of programmatic and XIB (PatinfoViewController, PriceComparisonViewController)
