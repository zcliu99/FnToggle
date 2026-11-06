# FnToggle

A tiny macOS menu bar app that toggles **"Use F1, F2, etc. keys as standard function keys"** with one click.

- **On** → solid, filled "fn" key icon
- **Off** → faint, outlined "fn" key icon
- Left-click toggles. Right-click (or ctrl-click) shows a menu with the current state, Toggle and Quit.
- No Dock icon; it lives only in the menu bar.

## Compatibility

| | |
|---|---|
| Built on | macOS 15.8.2 (Sequoia), Apple Silicon (arm64) |
| Toolchain | Apple Swift 6.2.4 (Xcode command line tools), SDK 26.2 |
| Minimum macOS (as built) | **15.0 (Sequoia)** |
| Architecture (as built) | **arm64 only** (Apple Silicon Macs) |

The prebuilt `FnToggle.app` will not run on macOS older than 15.0 or on Intel Macs. The source uses `kIOMainPortDefault`, which needs macOS 12 or later, so you can rebuild for older systems, for example:

```bash
swiftc -O -target arm64-apple-macos12.0 main.swift -o FnToggle -framework Cocoa -framework IOKit
```

(Adjust `build.sh` accordingly, and use `x86_64` or build both and combine them with `lipo` for Intel.) Older versions are untested.

## Build and run

Requires Xcode or the command line tools (`xcode-select --install`).

```bash
cd FnToggle
./build.sh
open FnToggle.app
```

To start at login, copy `FnToggle.app` to `/Applications` and add it under System Settings → General → Login Items.

## How it works

- Reads and writes the `com.apple.keyboard.fnState` global preference (the setting System Settings uses), so the two stay in sync.
- Also sets the HID system's `HIDFKeyMode` parameter through IOKit so the change applies immediately, without logging out. This is an undocumented interface and may change in future macOS releases. If a click updates the setting but your keys don't change behaviour, that call is the likely cause.
- The icon re-reads the setting every 3 seconds.

## Alternatives

- [jkbrzt/macos-fn-toggle](https://github.com/jkbrzt/macos-fn-toggle)

## Notes

- The app is ad-hoc signed (`codesign --sign -`), not notarized. If you copy it to another Mac, macOS Gatekeeper may block it; right-click → Open the first time.
- Files: `main.swift` (the whole app) and `build.sh` (compiles, creates the `.app` bundle, signs it).
