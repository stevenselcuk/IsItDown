//
//  MenubarView.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import SwiftUI

struct MenubarView: View {
    @ObservedObject var manager = Manager.share
    let timer = Timer.publish(every: TimeInterval(Manager.share.checkInterval), on: .main, in: .common).autoconnect()
    var data = PersistenceProvider.default

    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt)], predicate: NSPredicate(format: "addMenubar == %@", NSNumber(value: true)))
    var assets: FetchedResults<Asset>

    @State var isConnected: Bool = true
    var body: some View {
        if assets.count < 1 {
            Text("🤨 Is it down?")
                .fontMonoMedium(color: .white, size: 12)
                .padding(.all, 3)
                .background(Color.gray.opacity(0.4))
                .cornerRadius(3)
                .padding(.vertical, 3)
                .frame(width: 115, height: 20, alignment: .center)
        } else if isConnected == true {
            LazyHStack(alignment: .center, spacing: 0) {
                ForEach(Array(assets.enumerated()), id: \.element) { index, asset in
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

                    /*  if index < assets.count - 1 {
                       Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 4, height: 4)
                        Text("")
                            .opacity(0.3)
                    }*/
                }
            }
            
            .frame(width: CGFloat(assets.reduce(0) { $0 + ($1.name?.count ?? 1) }) * 10 + CGFloat(assets.count) * 15, height: 20, alignment: .center)
                .onReceive(timer) { _ in
                    isConnected = Reachability.isConnectedToNetwork()
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
                }
        } else {
            Text("🔌 No connection")
                .fontMonoMedium(color: .white, size: 10)
                .frame(width: 120, height: 20, alignment: .leading)
        }
    }
}
