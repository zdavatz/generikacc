# Generika.cc

[![Build Status](
https://travis-ci.org/zdavatz/generikacc.svg?branch=master)](
https://travis-ci.org/zdavatz/generikacc)

## Features

* iPhone/iPad Support
* EAN-13 Barcode Scan
* CHMED16A1 e-Prescription QR Code Scan
* Kostengutsprache (KVV 71) form for IBD Gastroenterology with PDF/Email export and full data persistence
* Indikationscode (IndC) selector inside the Kostengutsprache form: pick the BAG XXXXX.NN code, see the matching limitations text live, KoGu warning when text triggers it, KVV 71b/c off-label fallback when no IndC; selection embedded in the PDF (issue #102)
* Two-stage prescription scanner: QR code (CHMED16A) + full-page OCR to auto-fill KKV forms (medications, AHV, physician, hospital, patient address, insurer name)
* Pharmacode support: OCR medication name extraction when no GTIN available
* Insurance card OCR scanner (Swiss Versichertenkarte) with BAG-to-insurer lookup
* Drug Price Comparison Viewer
* Fachinformation/Patienteninformation Viewer
* Drug Interactions Checker (local SDIF database, full-screen on iPad)
* Side effects Viewer
* Expiry date Saving
* ZurRose pharmacy prescription submission


## Repository

https://github.com/zdavatz/generikacc


## Setup

### Requirements

* Xcode 16+ (iOS 15.0+ deployment target)
* XCTest (for testing)

### Dependencies

No external dependencies. All previously used CocoaPods (AFNetworking, NTMonthYearPicker, GZIP, KissXML, SSZipArchive, OCMock) have been replaced with built-in iOS APIs and lightweight custom implementations:

* `UIDatePicker` (replaces NTMonthYearPicker)
* `zlib` (replaces GZIP and SSZipArchive)
* `XMLBuilder` (replaces KissXML/DDXML)

### Build

```zsh
% cd /path/to/generikacc
% open Generika.xcworkspace
```

Build with Xcode or from command line:

```zsh
% xcodebuild -workspace Generika.xcworkspace -scheme Generika
```

### Set ZurRose certificate and password

- Copy the ZurRose certificate to `Generika/ZurRose/client.p12`.
- Rename `Generika/ZurRose/ZurRoseCredential.h.sample` to `Generika/ZurRose/ZurRoseCredential.h`, and set the password in the file.
- Open `Generika.xcworkspace` and build it.

### Add local databases

- Generate `amiko_db_full_idx_pinfo_de.db` with cpp2sqlite
  - `./cpp2sqlite --lang=de  --pinfo`
- Put it in Generika/Databases/
- `interactions.db` is also in Generika/Databases/ and can be updated in-app via Settings or downloaded from `http://pillbox.oddb.org/interactions.db`

### Debug

You may want to clean before rebuild, if you face something weird problem...

```zsh
# remove cache and compiled objects, log etc.
% rm -fr ~/Library/Developer/Xcode/DerivedData
```

And then click `Product` > `Clean` from menu (Shift + Command + K)

## Test

Run [XCTest](https://developer.apple.com/documentation/xctest?language=objc).

`test-runner` script supports multiple versions of _iphonesimulator_.

```zsh
# same as OS_VERSION="latest" ./bin/test-runner All, see `test-runner` script
% make test
% OS_VERSION="10.3.1" make test

# run single test case
% OS_VERSION="latest" ./bin/test-runner ProductTests/testInit
% OS_VERSION="10.3.1" ./bin/test-runner ProductTests/testInit
```

About target versions, see also _matrix_ in `.travis.yml`.


## Licence

`GPL-3.0`

```txt
Generika.cc
Copyright (c) 2012-2026 ywesee GmbH
```

See [LICENSE.txt](LICENCE).
