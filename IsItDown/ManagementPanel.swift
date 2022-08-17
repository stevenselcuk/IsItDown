//
//  ManagementPanel.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import ServiceManagement
import SwiftUI

let storage = UserDefaults.standard

struct ManagementPanel: View {
    var data = PersistenceProvider.default
    @State private var observer1: Any? = nil
    @State private var observer2: Any? = nil
    @ObservedObject var manager = Manager.share
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt)], predicate: nil)
    var assets: FetchedResults<Asset>

    @State var addNewAsset: Bool = false
    @State var showingSettings: Bool = false
    @State var name: String = ""
    @State var url: String = ""
    @State var showInMenubar: Bool = true
    @State var launchAtLogin: Bool = storage.bool(forKey: "launchAtLogin")
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 0) {
                Text("🤨 Is it down?")
                    .fontRegular(size: 14)
                    .padding()
                Spacer()
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 12, height: 12, alignment: .center)
                    .padding()
                    .onTapGesture {
                        addNewAsset = true
                    }
                    .popover(isPresented: $addNewAsset) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TextField(text: $name, label: { Text("Name e.g. My Website") })
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .background(.clear)
                                    .multilineTextAlignment(.leading)
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .fontRegular(size: 12)
                                    .onChange(of: name, perform: { newVal in
                                        if newVal.count > 20 {
                                            let trimmed = newVal.dropLast()
                                            name = String(trimmed)
                                        }
                                    })

                                Spacer()
                                Toggle("Add menubar", isOn: $showInMenubar)
                                    .fontRegular(size: 12)
                            }

                            Divider()
                            TextField(text: $url, label: { Text("URL e.g. https://tabbythecat.com") })
                                .textFieldStyle(PlainTextFieldStyle())
                                .background(.clear)
                                .multilineTextAlignment(.leading)
                                .truncationMode(.middle)
                                .lineLimit(1)
                                .fixedSize(horizontal: false, vertical: true)
                                .fontRegular(size: 12)
                                .onSubmit {
                                    if url.isEmpty || name.isEmpty { return }
                                    let asset = Asset(context: data.context)
                                    asset.id = UUID()
                                    asset.name = name
                                    asset.url = url
                                    asset.createdAt = Date()
                                    asset.addMenubar = showInMenubar
                                    try? data.context.save()
                                    name = ""
                                    url = ""
                                    showInMenubar = true

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                        for asset in assets {
                                            Checker.default.check(url: asset.url ?? "https://google.com", completion: { result in
                                                asset.code = Int16(result.statusCode)
                                                asset.lastUpdate = Date()
                                                print(Date())
                                                if result.isDown == true || result.noInternet == true || result.urlError == true {
                                                    asset.status = "Down"
                                                } else {
                                                    asset.status = "Up"
                                                }
                                                try? data.context.save()
                                            })
                                        }
                                    })
                                }
                        }
                        .padding(.all, 10)
                        .frame(minWidth: 320, maxWidth: .infinity, minHeight: 90, maxHeight: .infinity, alignment: .topLeading)
                    }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(assets.enumerated()), id: \.element) { _, asset in
                        HStack(alignment: .center) {
                            HStack {
                                Circle()
                                    .fill(asset.status == "Up" ? .green : .red)
                                    .frame(width: 8, height: 8)
                                Text("\(asset.code)")
                                    .fontMonoMedium(color: .white, size: 12)
                            }
                            .padding(.all, 3)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(3)
                            .padding(.vertical, 3)

                            Text(asset.name ?? "")
                                .fontMonoMedium(color: .white, size: 12)

                        }.padding(.horizontal, 12)
                            .contextMenu {
                                Button {
                                    data.context.delete(asset)
                                    try? data.context.save()
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            HStack {
                Image(systemName: "gear")
                    .padding()
                    .onTapGesture {
                        showingSettings = true
                    }
                    .popover(isPresented: $showingSettings) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .center, spacing: 0) {
                                Text("Check Interval")
                                    .fontRegular(size: 12)
                                Spacer()
                                Stepper {
                                    Text("\(String(format: "%.0f", manager.checkInterval / 60)) min. ")
                                } onIncrement: {
                                    manager.checkInterval += 60
                                    storage.set(manager.checkInterval, forKey: "checkInterval")
                                } onDecrement: {
                                    if manager.checkInterval > 120 {
                                        manager.checkInterval -= 60
                                        storage.set(manager.checkInterval, forKey: "checkInterval")
                                    }
                                }
                                .fontRegular(size: 12)
                            }

                            HStack(alignment: .center, spacing: 0) {
                                Text("Launch at login")
                                    .fontRegular(size: 12)
                                Spacer()
                                Toggle("", isOn: $launchAtLogin)
                                    .onChange(of: launchAtLogin) { newValue in
                                        SMLoginItemSetEnabled(Constants.helperBundleID as CFString,
                                                              launchAtLogin)
                                        print(newValue.description)
                                        print(launchAtLogin)
                                        storage.set(newValue.description, forKey: "launchAtLogin")
                                    }
                                    .fontRegular(size: 12)
                            }

                            HStack {
                                Text("Bug or feature?")
                                    .fontRegular(size: 12)
                                Spacer()
                                Button(action: {
                                    let uri = "https://twitter.com/hevalandsteven"
                                    if let url = URL(string: uri) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }, label: {
                                    Text("Tell me")
                                        .fontRegular(size: 12)
                                })
                            }
                        }.padding(.all, 10)
                            .frame(minWidth: 160, maxWidth: .infinity, minHeight: 90, maxHeight: .infinity, alignment: .topLeading)
                    }
                Spacer()
                Text("")
                    .fontMonoMedium(size: 12)
                    .padding()

                Spacer()
                Image(systemName: "power")
                    .fontBold(size: 12)
                    .onTapGesture {
                        Manager.quitApp()
                    }
                    .padding()
            }.border(width: 1, edges: [.top], color: Color.gray.opacity(0.1))

            FocusView()
                .frame(width: 0, height: 0, alignment: .leading)
                .touchBar {
                    Text("Hello")
                        .fontMonoMedium(color: .white, size: 18)
                        .padding(.all, 6)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(4)
                }
        }

        .frame(width: 240, height: 380, alignment: .center)
        .onAppear(perform: {
            observer1 = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: OperationQueue.main) { _ in
                (NSApp.delegate as! AppDelegate).closeManagementPanelWindow()
            }

            observer2 = NotificationCenter.default.addObserver(forName: NSWindow.didResignMainNotification, object: nil, queue: OperationQueue.main) { _ in
                (NSApp.delegate as! AppDelegate).closeManagementPanelWindow()
            }
        })
        .onDisappear(perform: {
            NotificationCenter.default.removeObserver(observer1 as Any)
            NotificationCenter.default.removeObserver(observer2 as Any)
        })
    }
}
