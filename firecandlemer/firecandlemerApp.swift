//
//  firecandlemerApp.swift
//  firecandlemer
//
//  Created by Dmitriy on 04.09.2025.
//

import SwiftUI
import StoreKit
import AppTrackingTransparency
import AdSupport
import RevenueCat
import AppsFlyerLib
import OneSignalFramework

@main
struct firecandlemerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var revenueCatModel = RevenueCatModel()

    init() {
        configureNavigationBarAppearance()

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")

        AppsFlyerLib.shared().appsFlyerDevKey = "YOUR_APPSFLYER_DEV_KEY"
        AppsFlyerLib.shared().appleAppID = "YOUR_APPLE_APP_ID"
        AppsFlyerLib.shared().start()

        OneSignal.initialize("YOUR_ONESIGNAL_APP_ID")

        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            OneSignal.Notifications.requestPermission({ accepted in
                print("User accepted notifications: \(accepted)")
            }, fallbackToSettings: true)
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(revenueCatModel)
                .task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds delay before ATT prompt
                    await requestTrackingAuthorization()
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive {
                UIApplication.shared.isIdleTimerDisabled = false
                print("[Idle] forced FALSE on scenePhase=\(String(describing: phase))")
            }
        }
    }

    @MainActor
    func requestTrackingAuthorization() {
        guard #available(iOS 14, *) else { return }
        
        Task {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            switch status {
            case .authorized:
                print("Tracking authorized")
            case .denied:
                print("Tracking denied")
            case .notDetermined:
                print("Tracking not determined")
            case .restricted:
                print("Tracking restricted")
            @unknown default:
                print("Tracking unknown status")
            }
        }
    }
}

private func configureNavigationBarAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
    appearance.backgroundColor = UIColor.black.withAlphaComponent(0.45)
    appearance.titleTextAttributes = [
        .foregroundColor: UIColor.white
    ]
    appearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor.white
    ]
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().tintColor = .white
}
