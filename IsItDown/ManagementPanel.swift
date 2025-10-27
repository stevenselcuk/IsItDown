import ServiceManagement
import SwiftUI
import Charts
import CoreData

let storage = UserDefaults.standard

extension String {
    var isValidURL: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.contains(" ") {
            return false
        }
        
        if let urlComponents = URLComponents(string: trimmed),
           let scheme = urlComponents.scheme,
           let host = urlComponents.host, !host.isEmpty,
           (scheme == "http" || scheme == "https") {
            return true
        }
        
        if let urlComponents = URLComponents(string: "http://\(trimmed)"),
           let host = urlComponents.host, !host.isEmpty {
            return true
        }
        
        return false
    }
}

struct ManagementPanel: View {
    var data = PersistenceProvider.default
    @State private var observer1: Any? = nil
    @State private var observer2: Any? = nil
    @ObservedObject var manager = Manager.share
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt)], predicate: nil)
    var assets: FetchedResults<Asset>

    @State private var addNewAsset: Bool = false
    @State private var showingSettings: Bool = false
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var groupName: String = ""
    @State private var showInMenubar: Bool = true
    
    @State private var alertInfo: Asset?
    @State private var selectedAssetForPopover: Asset?

    private var groupedAssets: [String: [Asset]] {
        Dictionary(grouping: assets, by: { $0.groupName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? $0.groupName! : "Ungrouped" })
    }
    
    private var sortedGroupKeys: [String] {
        groupedAssets.keys.sorted()
    }

    private func addAsset() {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !trimmedURL.isEmpty, trimmedURL.isValidURL else { return }
        
        let finalURL: String
        if trimmedURL.lowercased().hasPrefix("http://") || trimmedURL.lowercased().hasPrefix("https://") {
            finalURL = trimmedURL
        } else {
            finalURL = "http://\(trimmedURL)"
        }
        
        let asset = Asset(context: data.context)
        asset.id = UUID()
        asset.name = name
        asset.url = finalURL
        asset.groupName = groupName.isEmpty ? nil : groupName
        asset.createdAt = Date()
        asset.lastUpdate = Date()
        asset.addMenubar = showInMenubar
        asset.status = "Checking"
        try? data.context.save()
        Task { await manager.checkAllAssets() }
        name = ""; url = ""; groupName = ""; showInMenubar = true; addNewAsset = false
    }
    
    private func clearAllHistoryLogs() {
        let context = data.context
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "StatusLog")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            context.refreshAllObjects()
            print("Successfully cleared all history logs.")
        } catch {
            print("Error clearing history logs: \(error)")
        }
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 0) {
                Text("🤨 Is it down?")
                    .fontRegular(size: 14)
                    .padding()
                Spacer()
                Image(systemName: "arrow.clockwise")
                    .resizable().frame(width: 12, height: 12).padding().onTapGesture { Task { await manager.checkAllAssets() } }
                Image(systemName: "plus")
                    .resizable().frame(width: 12, height: 12).padding().onTapGesture { addNewAsset = true }
                    .popover(isPresented: $addNewAsset) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TextField("Name e.g. My Website", text: $name).textFieldStyle(PlainTextFieldStyle()).fontRegular(size: 12)
                                Spacer()
                                Toggle("Add menubar", isOn: $showInMenubar).fontRegular(size: 12)
                            }
                            Divider()
                            TextField("URL e.g. mywebsite.com", text: $url).textFieldStyle(PlainTextFieldStyle()).fontRegular(size: 12).onSubmit(addAsset)
                            Divider()
                            TextField("Group (Optional)", text: $groupName).textFieldStyle(PlainTextFieldStyle()).fontRegular(size: 12).onSubmit(addAsset)
                            Button("Add Site", action: addAsset).disabled(name.isEmpty || url.isEmpty || !url.isValidURL)
                        }
                        .padding(10).frame(minWidth: 320)
                    }
            }

            ScrollView {
                ForEach(sortedGroupKeys, id: \.self) { groupKey in
                    Section(header: Text(groupKey).fontBold(size: 10).padding(.horizontal, 12).padding(.top, 8)) {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(groupedAssets[groupKey]!, id: \.self) { asset in
                                AssetRowView(asset: asset, alertInfo: $alertInfo)
                                .onTapGesture { self.selectedAssetForPopover = asset }
                            }
                        }.padding(.horizontal, 8)
                    }
                }
            }
            .alert(item: $alertInfo) { asset in
                Alert(title: Text(asset.name ?? "Error Details"), message: Text(asset.errorDescription ?? "No details available."), dismissButton: .default(Text("OK")))
            }
            .popover(item: $selectedAssetForPopover) { asset in
                AssetDetailView(asset: asset)
            }
            
            HStack {
                Text("Settings").fontBold(size: 12).padding().onTapGesture { showingSettings = true }
                    .popover(isPresented: $showingSettings) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Consolidated Menubar").fontRegular(size: 12)
                                Spacer()
                                Toggle("", isOn: $manager.consolidatedMode)
                                    .onChange(of: manager.consolidatedMode) { storage.set($0, forKey: "consolidatedMode") }
                            }
                            HStack {
                                Text("Check Interval").fontRegular(size: 12)
                                Spacer()
                                Stepper("\(String(format: "%.0f", manager.checkInterval / 60)) min.") {
                                    manager.checkInterval += 60
                                    storage.set(manager.checkInterval, forKey: "checkInterval")
                                } onDecrement: {
                                    if manager.checkInterval > 60 { manager.checkInterval -= 60; storage.set(manager.checkInterval, forKey: "checkInterval") }
                                }
                            }
                            HStack {
                                Text("Launch at login").fontRegular(size: 12)
                                Spacer()
                                Toggle("", isOn: $manager.launchAtLogin)
                                    .onChange(of: manager.launchAtLogin) { value in
                                        do {
                                            if value { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                                            storage.set(value, forKey: "launchAtLogin")
                                        } catch { print("Login item error: \(error.localizedDescription)") }
                                    }
                            }
                            HStack {
                                Text("Send notifications").fontRegular(size: 12)
                                Spacer()
                                Toggle("", isOn: $manager.notificationStatus)
                                    .onChange(of: manager.notificationStatus) { value in
                                        if value { Manager.askPermission() }
                                        storage.set(value, forKey: "notificationStatus")
                                    }
                            }
                            Divider()
                            Button(role: .destructive) {
                                clearAllHistoryLogs()
                                showingSettings = false
                            } label: {
                                Text("Clear All History Logs").fontRegular(size: 12)
                            }

                        }.padding(10).frame(minWidth: 220)
                    }
                Spacer()
                Text("Quit").fontBold(size: 12).padding().onTapGesture { Manager.quitApp() }
            }.border(width: 1, edges: [.top], color: Color.gray.opacity(0.1))
            FocusView().frame(width: 0, height: 0)
        }
        .frame(width: 280, height: 420, alignment: .center)
        .onAppear {
            observer1 = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { _ in (NSApp.delegate as? AppDelegate)?.closeManagementPanelWindow() }
            observer2 = NotificationCenter.default.addObserver(forName: NSWindow.didResignMainNotification, object: nil, queue: .main) { _ in (NSApp.delegate as? AppDelegate)?.closeManagementPanelWindow() }
        }
        .onDisappear {
            if let obs1 = observer1 { NotificationCenter.default.removeObserver(obs1) }
            if let obs2 = observer2 { NotificationCenter.default.removeObserver(obs2) }
        }
    }
}

struct AssetRowView: View {
    @ObservedObject var asset: Asset
    @Binding var alertInfo: Asset?
    
    private func formattedResponseTime(for time: Double) -> String {
        if time == 0 { return "- ms" }
        let ms = time * 1000
        return String(format: "%.0fms", ms)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Circle().fill(asset.status == "Up" ? .green : (asset.status == "Down" ? .red : .yellow)).frame(width: 8, height: 8)
                Text("\(asset.code) · \(formattedResponseTime(for: asset.responseTime))").fontMonoMedium(color: .white, size: 12)
            }
            .padding(.vertical, 3).padding(.horizontal, 5).background(Color.gray.opacity(0.4)).cornerRadius(3)
            Text(asset.name ?? "").fontMonoMedium(color: .white, size: 12)
            Spacer()
        }
        .padding(.vertical, 8).padding(.horizontal, 12).frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu {
            if asset.status == "Down", asset.errorDescription != nil {
                Button { alertInfo = asset } label: { Label("Show Error Details", systemImage: "exclamationmark.triangle") }
            }
            Button(role: .destructive) {
                PersistenceProvider.default.context.delete(asset)
                try? PersistenceProvider.default.context.save()
            } label: { Label("Remove", systemImage: "trash") }
        }
    }
}

struct AssetDetailView: View {
    @ObservedObject var asset: Asset

    private var validLogs: [StatusLog] {
        let set = asset.logs as? Set<StatusLog> ?? []
        return set.filter { $0.timestamp != nil }
    }
    
    private var logs: [StatusLog] {
        return validLogs.sorted { $0.timestamp! > $1.timestamp! }
    }
    
    private var chartLogs: [StatusLog] {
        return validLogs.sorted { $0.timestamp! < $1.timestamp! }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(asset.name ?? "Details").font(.title2).fontWeight(.bold)
            
            Text("24-Hour Response Time (ms)").font(.headline)
            
            if chartLogs.isEmpty {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor))
                    Text("No history data to display chart.").foregroundColor(.secondary)
                }
                .frame(height: 150)
            } else {
                Chart(chartLogs, id: \.self) { log in
                    BarMark(
                        x: .value("Time", log.timestamp!, unit: .minute),
                        y: .value("Response", log.responseTime * 1000)
                    )
                    .foregroundStyle(log.isUp ? .green.opacity(0.7) : .red.opacity(0.7))
                }
                .chartXAxis(.hidden)
                .frame(height: 150)
                .drawingGroup()
            }
            
            Text("Recent Events").font(.headline)
            List(logs, id: \.self) { log in
                HStack {
                    Image(systemName: log.isUp ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundColor(log.isUp ? .green : .red)
                    Text(log.isUp ? "Up" : "Down")
                    Spacer()
                    Text(log.timestamp!, style: .time)
                }
            }
            .listStyle(.plain)

        }
        .padding()
        .frame(width: 400, height: 450)
    }
}

