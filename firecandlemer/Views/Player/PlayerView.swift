import SwiftUI
import AVFoundation
import UIKit

struct PlayerView: View {
    @StateObject private var vm: PlayerViewModel
    let ns: Namespace.ID

    @State private var showSleepSheet = false
    @Environment(\.dismiss) private var dismiss

    init(item: VideoItem, ns: Namespace.ID) {
        _vm = StateObject(wrappedValue: PlayerViewModel(item: item))
        self.ns = ns
    }

    var body: some View {
        ZStack {
            AppColors.blackBG.ignoresSafeArea()

            content

            PlayerOverlayView(
                isMuted: $vm.isMuted,
                isVisible: $vm.overlayVisible,
                remainingText: vm.remainingTimeText,
                onSleepTapped: { showSleepSheet = true },
                onBack: { dismiss() }
            )
            .padding(.bottom, AppSpacing.l)
        }
        .onTapGesture { vm.toggleOverlayAutoHide() }
        .onAppear { vm.onAppear() }
        .onDisappear {
            vm.onDisappear()
            // Ensure system auto-lock is enabled when leaving the player
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .sheet(isPresented: $showSleepSheet) {
            SleepTimerSheet(selection: $vm.sleepTimerSelection, fadeoutEnabled: $vm.fadeoutEnabled) { interval in
                vm.scheduleSleep(after: interval)
                showSleepSheet = false
            }
            .applyDetentsIfAvailable()
        }
        .onChange(of: vm.shouldDismissOnSleep) { newValue in
            if newValue { dismiss() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle, .downloading:
            LoaderView(progressText: vm.progressText, previewName: vm.item.previewImageName)
        case .error(let message):
            VStack(spacing: AppSpacing.m) {
                Text(NSLocalizedString("Download failed", comment: ""))
                    .font(AppTypography.subtitle)
                    .foregroundColor(.white)
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(.white.opacity(0.7))
                Button(NSLocalizedString("Retry", comment: "")) { vm.onAppear() }
                    .buttonStyle(.borderedProminent)
            }
        case .ready:
            if let player = vm.videoPlayer {
                GeometryReader { geo in
                    let isLandscape = geo.size.width > geo.size.height
                    VideoPlayerRepresentable(
                        player: player,
                        videoGravity: .resizeAspectFill
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                
            } else {
                Color.black
            }
        }
    }
}

// MARK: - Loader

private struct LoaderView: View {
    let progressText: String
    let previewName: String
    @State private var appear = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fullscreen preview image background
                Image(previewName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // Dark overlay over preview (stronger)
                Color.black.opacity(0.7).ignoresSafeArea()

                // Centered card
                VStack(spacing: AppSpacing.m) {
                    LottieOrRing()
                        .frame(width: 120, height: 120)

                    Text(NSLocalizedString("Downloading...", comment: ""))
                        .font(AppTypography.subtitle)
                        .foregroundColor(AppColors.textPrimary)

                    Text(progressText)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    Text(NSLocalizedString("Please wait", comment: ""))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.vertical, AppSpacing.l)
                .padding(.horizontal, AppSpacing.xl)
                .frame(width: min(geo.size.width - 48, 360))
                .background(
                    Group {
                        if #available(iOS 15.0, *) {
                            Color.clear.background(.ultraThinMaterial)
                        } else {
                            AppColors.cardBackground
                        }
                    }
                )
                .cornerRadius(AppRadii.l)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadii.l)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
                .scaleEffect(appear ? 1.0 : 0.9)
                .opacity(appear ? 1.0 : 0.0)
                .position(x: geo.size.width/2, y: geo.size.height/2)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { appear = true }
                }
            }
            .ignoresSafeArea()
        }
    }
}

private struct LottieOrRing: View {
    var body: some View {
        #if canImport(Lottie)
        LottieLoader()
            .frame(width: 120, height: 120)
        #else
        ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .scaleEffect(1.5)
        #endif
    }
}

#if canImport(Lottie)
import Lottie
private struct LottieLoader: UIViewRepresentable {
    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: "loader")
        view.loopMode = .loop
        view.play()
        return view
    }
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
#endif

// MARK: - Sleep Timer Sheet

private struct SleepTimerSheet: View {
    @Binding var selection: TimeInterval?
    @Binding var fadeoutEnabled: Bool
    let choose: (TimeInterval?) -> Void

    @State private var customMinutes: Int = 30

    private let options: [(String, TimeInterval?)] = []

    var body: some View {
        ZStack {
            AppColors.blackBG.ignoresSafeArea()
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                Text("Sleep Timer")
                    .font(AppTypography.subtitle)
                    .foregroundColor(Color(white: 0.6))

                // Off option
                Button(action: { choose(nil) }) {
                    HStack {
                        Text("Off").foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if selection == nil { Image(systemName: "checkmark").foregroundColor(AppColors.primary) }
                    }
                }
                .padding(.vertical, AppSpacing.s)

                // Fadeout toggle
                HStack {
                    Toggle(isOn: $fadeoutEnabled) {
                        Text("Fadeout").foregroundColor(AppColors.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                }

                // Custom controls (time, -/+, Start all in one row)
                HStack(spacing: AppSpacing.m) {
                    Text(String.localizedStringWithFormat(NSLocalizedString("%lld min", comment: ""), customMinutes))
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(minWidth: 90, alignment: .leading)

                    Spacer(minLength: AppSpacing.s)

                    Button(action: { customMinutes = max(1, customMinutes - 5) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.18), in: Circle())
                    }

                    Button(action: { customMinutes = min(240, customMinutes + 5) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.18), in: Circle())
                    }

                    Button(NSLocalizedString("Start", comment: "")) {
                        choose(TimeInterval(customMinutes * 60))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(minWidth: 120)
                }

                // Removed explicit "Turn Off Timer" button; use "Off" option above
            }
            .padding()
        }
    }
}

private extension View {
    @ViewBuilder
    func applyDetentsIfAvailable() -> some View {
        if #available(iOS 16, *) {
            #if os(iOS)
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            self
                .presentationDetents([.fraction(isPad ? 0.5 : 0.35)])
                .presentationDragIndicator(.visible)
            #else
            self
            #endif
        } else {
            self
        }
    }
}

private extension AppColors {
    static let blackBG = Color.black
}
