import SwiftUI

struct CategoryView: View {
    @StateObject private var vm: CategoryViewModel
    let ns: Namespace.ID
    @Environment(\.dismiss) private var dismiss
    @State private var showSleepingOverlay: Bool = false
    @State private var showingPaidView: Bool = false
    @EnvironmentObject var revenueCatModel: RevenueCatModel

    private let columns = [GridItem(.flexible(), spacing: AppSpacing.m), GridItem(.flexible(), spacing: AppSpacing.m)]

    init(category: Category, ns: Namespace.ID) {
        _vm = StateObject(wrappedValue: CategoryViewModel(category: category))
        self.ns = ns
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.m) {
                    ForEach(vm.videos) { video in
                        if revenueCatModel.isPremium || video.isFree {
                            NavigationLink(destination: PlayerView(item: video, ns: ns)) {
                                VideoCell(item: video, ns: ns)
                                    .contentShape(Rectangle())
                            }
                            .contentShape(Rectangle())
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: { showingPaidView = true }) {
                                VideoCell(item: video, ns: ns)
                                    .contentShape(Rectangle())
                            }
                            .contentShape(Rectangle())
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.all, AppSpacing.m)
            }
        }
        .overlay(
            Group {
                if showSleepingOverlay {
                    ZStack {
                        Color.black.opacity(0.9).ignoresSafeArea()
                        Text("Sleeping")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color(white: 0.6))
                    }
                    .onTapGesture { withAnimation { showSleepingOverlay = false } }
                }
            }
        )
        .navigationTitle(vm.category.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.gray)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(LocalizedStringKey(vm.category.title))
                    .font(AppTypography.subtitle)
                    .foregroundColor(Color(white: 0.6))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sleepTimerDidEnd)) { _ in
            withAnimation { showSleepingOverlay = true }
        }
        .fullScreenCover(isPresented: $showingPaidView) {
            revenueCatModel.paywallView(
                onPurchaseCompleted: { _ in showingPaidView = false },
                onRestoreCompleted: { _ in showingPaidView = false }
            )
        }
    }
}

private struct VideoCell: View {
    let item: VideoItem
    let ns: Namespace.ID
    @EnvironmentObject var revenueCatModel: RevenueCatModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(item.previewImageName)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
                .clipped()
                .cornerRadius(AppRadii.m)
                .matchedGeometryEffect(id: "preview-\(item.id)", in: ns)
            LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.35)]), startPoint: .center, endPoint: .bottom)
                .cornerRadius(AppRadii.m)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.m)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .overlay(
            Group {
                if item.isFree && !revenueCatModel.isPremium {
                    Text("Free")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(AppColors.primary.opacity(0.95))
                        .clipShape(Capsule())
                        .padding(8)
                }
            }, alignment: .topTrailing
        )
        .contentShape(Rectangle())
    }
}

struct CategoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoryView(category: Category(id: "cat_fire", title: "Fire", backgroundImageName: "cat_fire_bg", videos: []), ns: Namespace().wrappedValue)
        }
        .environmentObject(RevenueCatModel())
    }
}
