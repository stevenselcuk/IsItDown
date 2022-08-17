//
//  main.swift
//  IsItDownAutoLauncher
//
//  Created by Steven J. Selcuk on 17.08.2022.
//


import AppKit

// TODO: When targeting macOS 11, convert this to use `App` protocol and remove `NSPrincipalClass` in Info.plist.

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let mainBundleIdentifier = "org.tabbycatllc.isitdown"

        // Ensures the app is not already running.
        guard NSRunningApplication.runningApplications(withBundleIdentifier: mainBundleIdentifier).isEmpty else {
            NSApp.terminate(nil)
            return
        }

        let pathComponents = (Bundle.main.bundlePath as NSString).pathComponents
        let mainPath = NSString.path(withComponents: Array(pathComponents[0...(pathComponents.count - 5)]))
        NSWorkspace.shared.launchApplication(mainPath)
        NSApp.terminate(nil)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()


