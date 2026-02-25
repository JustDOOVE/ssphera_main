import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var windowController: NSWindowController?

    var appViewModel = AppViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Скрываем из Dock
        NSApp.setActivationPolicy(.accessory)

        // Menu bar button
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "СФЕРА"
        }

        // Menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Открыть окно", action: #selector(openWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Выйти из профиля", action: #selector(logout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Выйти", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func openWindow() {
        if windowController == nil {
            let contentView = RootView().environmentObject(appViewModel)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.contentView = NSHostingView(rootView: contentView)
            window.makeKeyAndOrderFront(nil)

            // Уровень окна стандартный или плавающий
            window.level = .normal   // или .floating, если нужно поверх всех окон

            windowController = NSWindowController(window: window)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowClosed(_:)),
                name: NSWindow.willCloseNotification,
                object: window
            )
        }

        // Показываем в Dock и активируем приложение
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func windowClosed(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow, closedWindow == windowController?.window else {
            return
        }

        // Скрыть из Dock
        NSApp.setActivationPolicy(.accessory)

        // Убираем контроллер и observer
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: closedWindow)
        windowController = nil
    }

    @objc func logout() {
        appViewModel.logout()
        openWindow()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
