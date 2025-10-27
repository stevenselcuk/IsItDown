import Foundation
import Cocoa
import UserNotifications
import CoreData

class Manager: ObservableObject {
    static var share = Manager()
    var timer: Timer?
    var data = PersistenceProvider.default

    @Published var id: UUID = UUID()
    @Published var managementPanelOpen: Bool = false
    @Published var checkInterval: Float = storage.optionalFloat(forKey: "checkInterval") ?? 1 * 60 {
        didSet { startTimer() }
    }
    @Published var launchAtLogin: Bool = storage.optionalBool(forKey: "launchAtLogin") ?? false
    @Published var notificationStatus: Bool = storage.optionalBool(forKey: "notificationStatus") ?? false
    @Published var consolidatedMode: Bool = storage.optionalBool(forKey: "consolidatedMode") ?? false
    
    init() {
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(checkInterval), repeats: true) { _ in
            Task {
                await self.checkAllAssets()
            }
        }
        timer?.fire()
    }
    
    @MainActor
    func checkAllAssets() async {
        let fetchRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        guard let assetsToCheck = try? data.context.fetch(fetchRequest) else { return }

        for asset in assetsToCheck {
            guard let url = asset.url, !url.isEmpty else { continue }
            
            let previousStatus = asset.status
            let result = await Checker.default.check(url: url)

            asset.code = Int16(result.statusCode)
            asset.responseTime = result.responseTime
            asset.errorDescription = result.errorDescription
            
            let newStatusIsUp = !(result.isDown || result.urlError || result.noInternet)
            let newStatusString = newStatusIsUp ? "Up" : "Down"
            
            if notificationStatus, newStatusString == "Down", previousStatus == "Up" {
                 sendNotification(for: asset, with: result)
            }
            
            asset.status = newStatusString
            asset.lastUpdate = Date()
            
            createStatusLog(for: asset, responseTime: result.responseTime, isUp: newStatusIsUp)
        }

        if data.context.hasChanges {
            try? data.context.save()
            cleanupOldLogs()
        }
    }
    
    private func createStatusLog(for asset: Asset, responseTime: Double, isUp: Bool) {
        let newLog = StatusLog(context: data.context)
        newLog.timestamp = Date()
        newLog.responseTime = responseTime
        newLog.isUp = isUp
        asset.addToLogs(newLog)
    }
    
    private func cleanupOldLogs() {
        let context = data.context
        let fetchRequest: NSFetchRequest<StatusLog> = StatusLog.fetchRequest()
        
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", twentyFourHoursAgo as NSDate)
        
        do {
            let oldLogs = try context.fetch(fetchRequest)
            for log in oldLogs {
                context.delete(log)
            }
            try context.save()
        } catch {
            print("Error cleaning up old logs: \(error)")
        }
    }

    private func sendNotification(for asset: Asset, with result: Result) {
        let content = UNMutableNotificationContent()
        content.title = "\(asset.name ?? "A site") is in trouble!"
        content.subtitle = "Status Code: \(result.statusCode)"
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .critical
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static public func quitApp() {
      NSApp.terminate(self)
    }
    
    static public func askPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success { storage.set(true, forKey: "notificationStatus") }
            else if let error = error { print(error.localizedDescription) }
        }
    }
}
