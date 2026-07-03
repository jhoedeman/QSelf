# QSelf

A privacy-first iOS/macOS app for tracking supplements, peptides, injectables, and lifestyle
interventions against daily wellbeing metrics and bloodwork. All data lives in the user's own
iCloud private container — no backend, no server, no third-party analytics.

See [CLAUDE.md](CLAUDE.md) for the full project brief: data model, architecture, freemium
gating rules, and MVP build order.

## Stack

Swift + SwiftUI (iOS 17+ / macOS 14+, multiplatform, no Catalyst) · SwiftData + CloudKit ·
Swift Charts · StoreKit 2 · UserNotifications.

## Project setup

The Xcode project is generated from [`project.yml`](project.yml) via
[XcodeGen](https://github.com/yonaskolb/XcodeGen). `QSelf.xcodeproj/project.pbxproj` is
committed (so the project opens without extra tooling), but should be regenerated — not
hand-edited — whenever `project.yml` or the file layout changes:

```sh
xcodegen generate
open QSelf.xcodeproj
```
