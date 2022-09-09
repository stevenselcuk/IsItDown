//
//  Manager.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import Foundation
import Cocoa
import UserNotifications

class Manager: ObservableObject {
    static var share = Manager()
 
    @Published var id: UUID = UUID()
    @Published var managementPanelOpen: Bool = false
    @Published var checkInterval: Float = storage.optionalFloat(forKey: "checkInterval") ?? 1 * 60
    @Published var launchAtLogin: Bool = storage.optionalBool(forKey: "launchAtLogin") ?? false
    @Published var notificationStatus: Bool = storage.optionalBool(forKey: "notificationStatus") ?? false
    static public func quitApp() {
      NSApp.terminate(self)
    }
    
    static public func openAbout() {
       // (NSApp.delegate as! AppDelegate).openAboutWindow()
    }
    
    static public func closeAbout() {
       // (NSApp.delegate as! AppDelegate).closeAboutWindow()
    }
    
    static public func askPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                storage.set(true, forKey: "notificationStatus")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}
