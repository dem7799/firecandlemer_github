//
//  RevenueCatModel.swift

import Foundation
import SwiftUI
import RevenueCat
import RevenueCatUI

class RevenueCatModel: ObservableObject {
    @Published var isPremium = PaidValue.Setting.isPremiumPROD ? false : true
    @Published var customerInfo: CustomerInfo?

    init() {
        PaidValue.Setting.isPremiumPROD ? checkUserStatus() : nil
    }
    
    func checkUserStatus() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                await MainActor.run {
                    self.customerInfo = customerInfo
                    updatePremiumStatus(customerInfo: customerInfo)
                }
            } catch {
                print("Error fetching user customer info: \(error)")
            }
        }
    }

    func updatePremiumStatus(customerInfo: CustomerInfo) {
        let wasPermium = isPremium
        isPremium = customerInfo.entitlements["premium"]?.isActive == true
        
        if !wasPermium && isPremium {
            print("🎉 Premium content unlocked!")
        }
    }
}

// MARK: - Paywall Presentation https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls
extension RevenueCatModel {
    @ViewBuilder
    func paywallView(
        onPurchaseCompleted: ((CustomerInfo) -> Void)? = nil,
        onRestoreCompleted: ((CustomerInfo) -> Void)? = nil
    ) -> some View {
        PaywallView(displayCloseButton: true)
            .environmentObject(self)
            .onPurchaseCompleted { customerInfo in
                print("✅ Purchase completed successfully!")
                print("📱 Subscription status: \(customerInfo.entitlements["premium"]?.isActive == true ? "Active" : "Inactive")")
                print("ℹ️ Subscription entitlements: \(customerInfo.entitlements)")
                
                // Unlock premium content
                self.updatePremiumStatus(customerInfo: customerInfo)
                
                onPurchaseCompleted?(customerInfo)
            }
            .onRestoreCompleted { customerInfo in
                print("🔄 Purchases restoration completed!")
                print("📱 Subscription status: \(customerInfo.entitlements["premium"]?.isActive == true ? "Active" : "Inactive")")
                print("ℹ️ Subscription entitlements: \(customerInfo.entitlements)")
                
                // Unlock premium content if restoration succeeded
                self.updatePremiumStatus(customerInfo: customerInfo)
                
                onRestoreCompleted?(customerInfo)
            }
    }
}
