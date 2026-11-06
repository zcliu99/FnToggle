import Cocoa
import IOKit
import IOKit.hidsystem

// MARK: - Fn key state

enum FnState {
    static let key = "com.apple.keyboard.fnState" as CFString

    /// true  = F1, F2… act as standard function keys
    static var standard: Bool {
        get {
            CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
            return CFPreferencesCopyValue(key, kCFPreferencesAnyApplication,
                                          kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? Bool ?? false
        }
        set {
            // 1. Persist, so System Settings shows the same value and it survives reboot.
            CFPreferencesSetValue(key, newValue as CFBoolean, kCFPreferencesAnyApplication,
                                  kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            CFPreferencesSynchronize(kCFPreferencesAnyApplication,
                                     kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            // 2. Apply live to the HID system, so no logout is needed.
            applyToHID(newValue)
        }
    }

    private static func applyToHID(_ standard: Bool) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }
        var connect: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect) == KERN_SUCCESS else { return }
        defer { IOServiceClose(connect) }
        _ = IOHIDSetCFTypeParameter(connect, "HIDFKeyMode" as CFString, NSNumber(value: standard ? 1 : 0))
    }
}

// MARK: - Icon

func fnIcon(on: Bool) -> NSImage {
    let size = NSSize(width: 26, height: 18)
    let img = NSImage(size: size, flipped: false) { rect in
        let box = rect.insetBy(dx: 1.5, dy: 1.5)
        let path = NSBezierPath(roundedRect: box, xRadius: 4, yRadius: 4)
        let font = NSFont.systemFont(ofSize: 11, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
        let text = NSAttributedString(string: "fn", attributes: attrs)
        let ts = text.size()
        let origin = NSPoint(x: rect.midX - ts.width / 2, y: rect.midY - ts.height / 2)

        if on {
            // Solid: filled key with "fn" knocked out.
            NSColor.black.setFill()
            path.fill()
            NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
            text.draw(at: origin)
        } else {
            // Faint: thin outline + dim text.
            NSGraphicsContext.current?.cgContext.setAlpha(0.35)
            NSColor.black.setStroke()
            path.lineWidth = 1.2
            path.stroke()
            text.draw(at: origin)
        }
        return true
    }
    img.isTemplate = true
    return img
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let toggleItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "")

    func applicationDidFinishLaunching(_ n: Notification) {
        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(clicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        refresh()
        // Keep in sync if changed from System Settings.
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(refresh), name: NSNotification.Name("com.apple.keyboard.fnStateDidChange"), object: nil)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refresh() }
    }

    @objc func refresh() {
        let on = FnState.standard
        item.button?.image = fnIcon(on: on)
        item.button?.toolTip = on ? "F1–F12 are standard function keys (click to turn off)"
                                  : "F1–F12 use media/special features (click to turn on)"
    }

    @objc func clicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            let menu = NSMenu()
            let on = FnState.standard
            menu.addItem(withTitle: on ? "Standard function keys: On" : "Standard function keys: Off",
                         action: nil, keyEquivalent: "").isEnabled = false
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Toggle", action: #selector(toggle), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
            menu.items.forEach { $0.target = self }
            item.menu = menu
            item.button?.performClick(nil)
            item.menu = nil
        } else {
            toggle()
        }
    }

    @objc func toggle() {
        FnState.standard.toggle()
        refresh()
    }

    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
