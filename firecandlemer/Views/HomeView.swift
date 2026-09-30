import SwiftUI
import UIKit

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @Namespace private var ns

    // Single-column layout with horizontally oriented, wide cards
    private let columns = [GridItem(.flexible(), spacing: AppSpacing.m)]

    // Top bar + side menu state
    @State private var showMenu: Bool = false
    @State private var showShare: Bool = false

    private var menuWidth: CGFloat { UIScreen.main.bounds.width * 0.8 }


    @State private var showingPaidView = false
    @State private var showingPaidViewFront = false
    @EnvironmentObject var revenueCatModel: RevenueCatModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .leading) {
                AppColors.background.ignoresSafeArea()

                // Main content with custom top bar
                VStack(spacing: 0) {
                    topBar
                    content
                }

                // Dim overlay when menu is open
                if showMenu {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { toggleMenu(false) }
                        .transition(.opacity)
                }

                // Side Menu
                sideMenu
            }
            .navigationBarHidden(true)
            .onAppear { if vm.categories.isEmpty { vm.load() } }
            .sheet(isPresented: $showShare) {
                ActivityView(activityItems: [URL(string: PaidValue.Setting.appLink)!])
            }
            .applyPaidViewModifiers(
                hasSeenOnboarding: $hasSeenOnboarding,
                showingPaidView: $showingPaidView,
                revenueCatModel: revenueCatModel
            )
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Fullscreen layout for iPad
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Button(action: { toggleMenu(true) }) {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(AppSpacing.s)
                    .background(AppColors.cardBackground, in: Circle())
            }
            Spacer()
            Text("Video Scenes")
                .font(AppTypography.subtitle)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: { showShare = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(AppSpacing.s)
                    .background(AppColors.cardBackground, in: Circle())
            }
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.bottom, AppSpacing.m)
        .background(AppColors.background.opacity(0.95))
    }

    private var content: some View {
        Group {
            if vm.isLoading {
                VStack { Spacer(); ProgressView().progressViewStyle(.circular); Spacer() }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: AppSpacing.m) {
                        ForEach(vm.categories) { category in
                            NavigationLink(destination: CategoryView(category: category, ns: ns)) {
                                CategoryCard(category: category, ns: ns)
                                    .contentShape(Rectangle())
                            }
                            .contentShape(Rectangle())
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.all, AppSpacing.m)
                }
            }
        }
    }

    private var sideMenu: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                // Header
                HStack {
                    Text("Menu")
                        .font(AppTypography.subtitle)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button(action: { toggleMenu(false) }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.s)
                    }
                }
                .padding(.bottom, AppSpacing.s)

                menuButton(title: "Go PRO", systemImage: "star.fill") {
                    // Close menu and present paywall
                    toggleMenu(false)
                    showingPaidView = true
                }
                menuButton(title: "Rate App", systemImage: "hand.thumbsup.fill") {
                    open(urlString: PaidValue.Setting.appLink)
                    toggleMenu(false)
                }
                menuButton(title: "Share App", systemImage: "square.and.arrow.up") {
                    showShare = true
                    toggleMenu(false)
                }
                menuButton(title: "Privacy Policy", systemImage: "lock.fill") {
                    open(urlString: PaidValue.Setting.privacyLink)
                    toggleMenu(false)
                }
                menuButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                    open(urlString: PaidValue.Setting.termsLink)
                    toggleMenu(false)
                }

                Spacer()
            }
            .padding(AppSpacing.m)
            .frame(width: menuWidth)
            .frame(maxHeight: .infinity)
            .background(Color.black)
            .offset(x: showMenu ? 0 : -menuWidth)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: showMenu)
        }
    }

    private func menuButton(title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: systemImage)
                    .foregroundColor(AppColors.primary)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 22)
                Text(title)
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
                Spacer()
            }
            .padding(.vertical, AppSpacing.s)
            .padding(.horizontal, AppSpacing.s)
            .background(AppColors.background.opacity(0.6))
            .cornerRadius(AppRadii.m)
        }
    }

    private func toggleMenu(_ open: Bool) {
        withAnimation(.spring()) { showMenu = open }
    }

    private func open(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

private struct CategoryCard: View {
    let category: Category
    let ns: Namespace.ID

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Prefer video as base if available; fallback to image
            if let videoName = category.backgroundVideoName {
                LoopingBackgroundVideoView(name: videoName, placeholderImageName: category.backgroundImageName)
                    .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 180)
                    .clipped()
            } else if let ui = UIImage(named: category.backgroundImageName), !category.backgroundImageName.isEmpty {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 180)
                    .clipped()
            } else {
                AppColors.cardBackground
                    .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 180)
            }
            // Common black dim overlay
            Color.black.opacity(0.1)
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 180)
                .allowsHitTesting(false)
            Text(NSLocalizedString(category.title, comment: "").uppercased())
                .font(.system(size: 24, weight: .thin, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .padding(AppSpacing.m)
        }
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadii.l)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.l)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: category.id)
        .contentShape(Rectangle())
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(RevenueCatModel())
    }
}

// MARK: - Share Sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            vc.popoverPresentationController?.sourceView = windowScene.windows.first
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
