import SwiftUI
import UserNotifications

struct MenubarView: View {
    @ObservedObject var manager = Manager.share
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt)], predicate: NSPredicate(format: "addMenubar == %@", NSNumber(value: true)))
    var assets: FetchedResults<Asset>

    @State var isConnected: Bool = true
    
    private var downAssetsCount: Int {
        assets.filter { $0.status == "Down" }.count
    }
    
    private func formattedResponseTime(for time: Double) -> String {
        if time == 0 { return "- ms" }
        let ms = time * 1000
        return String(format: "%.0f ms", ms)
    }
    
    var body: some View {
        if assets.isEmpty {
            EmptyView()
        } else if manager.consolidatedMode {
            ConsolidatedView(totalCount: assets.count, downCount: downAssetsCount)
        } else {
            ExpandedView(assets: assets)
        }
    }
    
    @ViewBuilder
    private func EmptyView() -> some View {
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
    }
    
    @ViewBuilder
    private func ConsolidatedView(totalCount: Int, downCount: Int) -> some View {
        let isEverythingUp = downCount == 0
        HStack(spacing: 4) {
            Circle()
                .fill(isEverythingUp ? .green : .red)
                .frame(width: 8, height: 8)
            if !isEverythingUp {
                Text("\(downCount)/\(totalCount) Down")
                    .fontMonoMedium(color: .white, size: 12)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }
    
    @ViewBuilder
    private func ExpandedView(assets: FetchedResults<Asset>) -> some View {
        LazyHStack(alignment: .center, spacing: 0) {
            ForEach(assets, id: \.self) { asset in
                HStack(alignment: .center, spacing: 6) {
                    HStack(alignment: .center, spacing: 3) {
                        Circle()
                            .fill(asset.status == "Up" ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(formattedResponseTime(for: asset.responseTime))
                            .fontMonoMedium(color: .white, size: 12)
                    }
                    .padding(.all, 3)
                    .background(Color.gray.opacity(0.4))
                    .cornerRadius(3)
                    .padding(.vertical, 3)
                    
                    Text(asset.name ?? "")
                        .fontMonoMedium(color: .white, size: 10)
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: false)
                }
                .padding(.horizontal, 5)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}
