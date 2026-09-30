import SwiftUI
import StoreKit
import RevenueCat
import RevenueCatUI

// Import PaidViewFront
@_spi(PaidViewFront) import RevenueCatUI
@_spi(PaidView) import RevenueCatUI

// Onboarding color scheme
struct OnboardingColors {
    static let backgroundColor = Color.black
    static let titleTextColor = Color.white
    static let subtitleTextColor = Color.white.opacity(0.8)
    static let buttonBackgroundColor = Color.blue
    static let buttonTextColor = Color.white
}

struct OnboardingSlide: Codable, Identifiable {
    let id: Int
    let image: String
    let video: String?
    let title: String
    let subtitle: String
    let buttonText: String
    
    var color: Color {
        return OnboardingColors.backgroundColor
    }
    
    static let slides = [
        OnboardingSlide(
            id: 1,
            image: "board1",
            video: "cat_fire_bg",
            title: "Cozy Fireplace",
            subtitle: "Unwind, sleep, or work with a real fireplace ambience. Seamlessly looping videos and natural sound create instant coziness.",
            buttonText: "Continue"
        ),
        OnboardingSlide(
            id: 2,
            image: "board1",
            video: "cat_candle_bg",
            title: "Warm Candlelight",
            subtitle: "Soft flames help you relax, meditate, and read. A perfect backdrop for evenings and deep focus.",
            buttonText: "Continue"
        ),
        OnboardingSlide(
            id: 3,
            image: "board1",
            video: "cat_rain_bg",
            title: "Rain Outside",
            subtitle: "Gentle rain eases stress and improves focus. Soothing white noise for sleep and productivity.",
            buttonText: "Continue"
        ),
        OnboardingSlide(
            id: 4,
            image: "board1",
            video: "cat_aquarium_bg",
            title: "Relax Aquarium",
            subtitle: "Calming water and fish movement soothe and set the mood — great for rest and meditation.",
            buttonText: "Continue"
        ),
        OnboardingSlide(
            id: 5,
            image: "board1",
            video: "cat_nature_bg",
            title: "Nature Sounds",
            subtitle: "Forest, water, and wind — authentic sounds for relaxation and sleep. Works offline after download.",
            buttonText: "Continue"
        ),
        OnboardingSlide(
            id: 6,
            image: "board1",
            video: "cat_noise_bg",
            title: "White Noise",
            subtitle: "Steady white noise masks distractions for deeper sleep and focus — perfect for study, work, and bedtime.",
            buttonText: "Continue"
        )
    ]
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var slides: [OnboardingSlide] = []
    @EnvironmentObject var revenueCatModel: RevenueCatModel
    @State private var showingPaidView = false
    
    var body: some View {
        GeometryReader { geometry in
            mainContent(geometry: geometry)
        }
        .noAnimationFullScreenCover(isPresented: $showingPaidView) {
            paywallContent
        }
        .ignoresSafeArea()
        .onAppear(perform: loadSlides)
        .onChange(of: currentPage) { newPage in
            handlePageChange(newPage)
        }
        .preferredColorScheme(.light)
        .environment(\.colorScheme, .light)
    }
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        ZStack {
            if showingPaidView {
                // Empty ZStack branch - handled by fullScreenCover
                EmptyView()
            } else if let slide = slides[safe: currentPage] {
                slideContent(slide: slide, geometry: geometry)
            }
        }
    }
    
    private func slideContent(slide: OnboardingSlide, geometry: GeometryProxy) -> some View {
        ZStack {
            slide.color
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                tabViewContent(geometry: geometry)
            }
        }
        // Ensure the whole slide can extend under the status bar
        .ignoresSafeArea(edges: .top)
    }
    
    private func tabViewContent(geometry: GeometryProxy) -> some View {
        TabView(selection: $currentPage) {
            ForEach(slides) { slide in
                slideItemContent(slide: slide, geometry: geometry)
                    .tag(slide.id - 1)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        // Ensure pages can render under the status bar
        .ignoresSafeArea(edges: .top)
    }
    
    private func slideItemContent(slide: OnboardingSlide, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            imageSection(slide: slide, geometry: geometry)
            
            Spacer()
            
            textSection(slide: slide)
            
            buttonSection(slide: slide)
        }
    }
    
    private func imageSection(slide: OnboardingSlide, geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Group {
                if let videoName = slide.video, !videoName.isEmpty {
                    // Loop the onboarding video from Data/ like on the home screen
                    LoopingBackgroundVideoView(name: videoName, placeholderImageName: slide.image)
                } else {
                    Image(slide.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(maxWidth: .infinity)
            // Make the media container reach the very top by
            // extending its height with the top safe area.
            .frame(height: geometry.size.height * 0.6 + geometry.safeAreaInsets.top + 70, alignment: .top)
            .clipped()
            .ignoresSafeArea(edges: .top)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        OnboardingColors.backgroundColor.opacity(0),
                        OnboardingColors.backgroundColor.opacity(1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                // Cover bottom half of the media container
                .frame(height: (geometry.size.height * 0.6 + geometry.safeAreaInsets.top + 70) * 0.5),
                alignment: .bottom
            )
        }
        // Pull the media container under the status bar and lift it by extra 50pt
        .padding(.top, -(geometry.safeAreaInsets.top + 70))
        .ignoresSafeArea()
    }
    
    private func gradientOverlay(geometry: GeometryProxy) -> some View { EmptyView() }
    
    private func textSection(slide: OnboardingSlide) -> some View {
        VStack(spacing: 0) {
            Text(LocalizedStringKey(slide.title))
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(OnboardingColors.titleTextColor)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
            
            Text(LocalizedStringKey(slide.subtitle))
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .foregroundColor(OnboardingColors.subtitleTextColor)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(5)
        }
    }
    
    private func buttonSection(slide: OnboardingSlide) -> some View {
        Button(action: {
            handleButtonTap()
        }) {
            Text(LocalizedStringKey(slide.buttonText))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(OnboardingColors.buttonTextColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(OnboardingColors.buttonBackgroundColor)
                .cornerRadius(26)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 30)
        .padding(.bottom, 20)
    }
    
    private var paywallContent: some View {
        revenueCatModel.paywallView(
            onPurchaseCompleted: { customerInfo in
                print("Purchase completed: \(customerInfo.entitlements)")
                showingPaidView = false
                isPresented = false
            },
            onRestoreCompleted: { customerInfo in
                print("Restore completed: \(customerInfo.entitlements)")
                showingPaidView = false
                isPresented = false
            }
        )
        .onDisappear {
            // Immediately dismiss onboarding
            isPresented = false
            // Then dismiss paywall in next runloop cycle
            DispatchQueue.main.async {
                showingPaidView = false
            }
        }
    }
    
    private func handleButtonTap() {
        if currentPage < slides.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            if !revenueCatModel.isPremium {
                withAnimation(nil) {
                    showingPaidView = true
                }
            } else {
                isPresented = false
            }
        }
    }
    
    private func handlePageChange(_ newPage: Int) {
        if newPage == 4 {
            // DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            //     if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            //         SKStoreReviewController.requestReview(in: scene)
            //     }
            // }
        }
    }
    
    private func loadSlides() {
        slides = OnboardingSlide.slides
    }
}

struct OnboardingData: Codable {
    let slides: [OnboardingSlide]
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    let mockRevenueCatModel = RevenueCatModel()
    mockRevenueCatModel.isPremium = false // Set default state for preview
    
    return OnboardingView(isPresented: .constant(true))
        .environmentObject(mockRevenueCatModel)
} 
