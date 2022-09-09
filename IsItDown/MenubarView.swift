//
//  MenubarView.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import SwiftUI
import UserNotifications

struct MenubarView: View {
    @ObservedObject var manager = Manager.share
    let timer = Timer.publish(every: TimeInterval(Manager.share.checkInterval), on: .main, in: .common).autoconnect()
    var data = PersistenceProvider.default

    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt)], predicate: NSPredicate(format: "addMenubar == %@", NSNumber(value: true)))
    var assets: FetchedResults<Asset>

    @State var isConnected: Bool = true
    @State var notificationStatus: Bool = storage.bool(forKey: "notificationStatus")
    var body: some View {
        if assets.count < 1 {
            LazyHStack(alignment: .center, spacing: 0) {
                Text("🤨")
                    .fontMonoMedium(color: .white, size: 12)
                    .padding(.all, 3)
                    .background(Color.gray.opacity(0.4))
                    .cornerRadius(3)
                    .padding(.vertical, 3)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
        } else if isConnected == true {
            LazyHStack(alignment: .center, spacing: 0) {
                ForEach(Array(assets.enumerated()), id: \.element) { _, asset in
                    HStack(alignment: .center, spacing: 6) {
                        HStack(alignment: .center, spacing: 3) {
                            Circle()
                                .fill(asset.status == "Up" ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text("\(asset.code)")
                                .fontMonoMedium(color: .white, size: 12)

                        }.padding(.all, 3)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(3)
                            .padding(.vertical, 3)
                        Text(asset.name ?? "")
                            .fontMonoMedium(color: .white, size: 10)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: false)
                    }.padding(.horizontal, 5)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .onReceive(timer) { _ in
                isConnected = Reachability.isConnectedToNetwork()
                for asset in assets {
                    Checker.default.check(url: asset.url ?? "https://google.com", completion: { result in
                        asset.code = Int16(result.statusCode)
                        if notificationStatus == true && asset.lastUpdate!.addingTimeInterval(TimeInterval(60 * 60 * 1)) < Date() && asset.code > 204 {
                            let content = UNMutableNotificationContent()
                            content.title = "\(asset.name ?? "Something") in trouble!"
                            content.subtitle = "Status Code: \(Int16(result.statusCode))"
                            content.sound = UNNotificationSound.defaultCritical
                            content.interruptionLevel = .critical
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                            UNUserNotificationCenter.current().add(request)
                        }

                        if result.isDown == true || result.noInternet == true || result.urlError == true {
                            asset.status = "Down"
                        } else {
                            asset.status = "Up"
                        }
                        asset.lastUpdate = Date()
                        try? data.context.save()
                    })
                }
            }
        } else {
            Text("🔌 No connection")
                .fontMonoMedium(color: .white, size: 10)
                .frame(width: 120, height: 20, alignment: .leading)
        }
    }
}
