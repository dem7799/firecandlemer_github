import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - PaidValue
struct PaidValue {
    
    // MARK: - Settings
    struct Setting {

        static let isPremiumPROD = false // Set to true for Production App Store release, false for local testing

        static let appLink = "https://apps.apple.com/app/idYOUR_APPLE_APP_ID"
        static let privacyLink = "https://yourdomain.com/privacy"
        static let termsLink = "https://yourdomain.com/terms"
    }

    // MARK: - Session Flags (per app launch)
    struct Session {
        static var didAutoShowPaywall = false
    }
}

// MARK: - View Modifiers
extension View {
    func applyPaidViewModifiers(
        hasSeenOnboarding: Binding<Bool>,
        showingPaidView: Binding<Bool>,
        revenueCatModel: RevenueCatModel
    ) -> some View {
        self
            .navigationViewStyle(StackNavigationViewStyle()) // Fullscreen layout for iPad
            .fullScreenCover(isPresented: Binding(
                get: { !hasSeenOnboarding.wrappedValue },
                set: { _ in hasSeenOnboarding.wrappedValue = true }
            ), content: {
                OnboardingView(isPresented: Binding(
                    get: { !hasSeenOnboarding.wrappedValue },
                    set: { _ in hasSeenOnboarding.wrappedValue = true }
                ))
                .environmentObject(revenueCatModel)
            })
            .fullScreenCover(isPresented: showingPaidView) {
                revenueCatModel.paywallView(
                    onPurchaseCompleted: { customerInfo in
                        print("Purchase completed: \(customerInfo.entitlements)")
                        showingPaidView.wrappedValue = false
                    },
                    onRestoreCompleted: { customerInfo in
                        print("Restore completed: \(customerInfo.entitlements)")
                        showingPaidView.wrappedValue = false
                    }
                )
            }
            .onAppear {
                // Auto-present paywall once per app session to avoid repeated popups
                guard !PaidValue.Session.didAutoShowPaywall else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if hasSeenOnboarding.wrappedValue && !revenueCatModel.isPremium {
                        Purchases.shared.getOfferings { _, _ in
                            showingPaidView.wrappedValue = true
                            PaidValue.Session.didAutoShowPaywall = true
                        }
                    }
                }
            }
    }
}

/*
@State private var showingPaidView = false
@State private var showingPaidViewFront = false
@EnvironmentObject var revenueCatModel: RevenueCatModel
@AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
*/

/*
.applyPaidViewModifiers(
    hasSeenOnboarding: $hasSeenOnboarding,
    showingPaidView: $showingPaidView,
    revenueCatModel: revenueCatModel
)
*/
