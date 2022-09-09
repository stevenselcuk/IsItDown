//
//  AppDelegate.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var managementWindow: NSWindow!
    @ObservedObject var manager = Manager.share
    let data = PersistenceProvider.default

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
       
        let menubarView = (statusBarItem.value(forKey: "window") as? NSWindow)?.contentView

        let hostingView = NSHostingView(rootView: MenubarView().environment(\.managedObjectContext, PersistenceProvider.default.context))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        menubarView?.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: menubarView!.topAnchor),
            hostingView.rightAnchor.constraint(equalTo: menubarView!.rightAnchor),
            hostingView.bottomAnchor.constraint(equalTo: menubarView!.bottomAnchor),
            hostingView.leftAnchor.constraint(equalTo: menubarView!.leftAnchor),
        ])

        if let button = statusBarItem.button {
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    @objc func togglePopover(_ sender: AnyObject?) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.leftMouseUp {
            if manager.managementPanelOpen == false {
                openManagementPanelWindow()
            } else {
                closeManagementPanelWindow()
            }
        } else if event.type == NSEvent.EventType.rightMouseUp {
        }
    }

    func openManagementPanelWindow() {
        managementWindow = NSWindow(
            contentRect: NSRect(x: -((NSScreen.main?.frame.height)! / 2), y: -((NSScreen.main?.frame.width)! / 2), width: 240, height: 380),
            styleMask: [.titled, .borderless],
            backing: .buffered, defer: false)

        managementWindow.level = NSWindow.Level.normal + 1
        managementWindow.isReleasedWhenClosed = false
        managementWindow.positionCenter()
        managementWindow.titlebarAppearsTransparent = true
        managementWindow.titleVisibility = .hidden
        managementWindow.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)

        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .popover
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        //  visualEffect.layer?.cornerRadius = 16.0

        managementWindow.titleVisibility = .hidden
        managementWindow.backgroundColor = .clear
        managementWindow.isMovableByWindowBackground = true

        managementWindow.contentView?.addSubview(visualEffect)
        let v = NSHostingView(rootView: ManagementPanel().environment(\.managedObjectContext, PersistenceProvider.default.context))
        v.translatesAutoresizingMaskIntoConstraints = false
        managementWindow.contentView?.addSubview(v)
        guard let constraints = managementWindow.contentView else {
            return
        }

        v.leadingAnchor.constraint(equalTo: constraints.leadingAnchor).isActive = true
        v.trailingAnchor.constraint(equalTo: constraints.trailingAnchor).isActive = true
        v.topAnchor.constraint(equalTo: constraints.topAnchor).isActive = true
        v.bottomAnchor.constraint(equalTo: constraints.bottomAnchor).isActive = true

        visualEffect.leadingAnchor.constraint(equalTo: constraints.leadingAnchor).isActive = true
        visualEffect.trailingAnchor.constraint(equalTo: constraints.trailingAnchor).isActive = true
        visualEffect.topAnchor.constraint(equalTo: constraints.topAnchor).isActive = true
        visualEffect.bottomAnchor.constraint(equalTo: constraints.bottomAnchor).isActive = true
        managementWindow.makeKeyAndOrderFront(nil)
        manager.managementPanelOpen = true
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
     
    func closeManagementPanelWindow() {
            if managementWindow == nil {return}
            if manager.managementPanelOpen == true {
                managementWindow.close()
                manager.managementPanelOpen = false
            }
    }
}

