import Foundation
import RevenueCat
import SwiftUI

final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscribed = false
    @Published var customerInfo: CustomerInfo?
    @Published var credits: Int = 0
    @Published var showOnboarding = false
    @Published var availablePackages: [Package] = []

    private init() {}

    func loadConfig() {
        checkSubscriptionStatus()
        fetchAvailablePackages()
    }

    func fetchAvailablePackages() {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error = error {
                print("Error fetching offerings: \(error)")
                return
            }

            if let packages = offerings?.offering(identifier: "credits-shop")?.availablePackages {
                DispatchQueue.main.async {
                    self?.availablePackages = packages
                }
            }
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        showOnboarding = false

        Task {
            await registerUser(credits: 0)
        }
    }

    private func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            DispatchQueue.main.async {
                let isActive = customerInfo?.entitlements.all["Pro"]?.isActive == true
                self.isSubscribed = isActive
            }
        }
        self.showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingCompleted")
    }

    func restorePurchases(completion: @escaping (Bool) -> Void) {
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            if let error = error {
                print("Error restoring purchases: \(error)")
                completion(false)
                return
            }

            DispatchQueue.main.async {
                self?.customerInfo = customerInfo
                let isActive = customerInfo?.entitlements.all["Pro"]?.isActive == true
                self?.isSubscribed = isActive
                completion(self?.isSubscribed ?? false)
            }
        }
    }

    func useCredits(_ amount: Int) {
        Task {
            do {
                let response = try await UserService.shared.useCredits(amount)
                DispatchQueue.main.async {
                    self.credits = response.remaining_credits
                }
                print("Credits used successfully. Remaining: \(response.remaining_credits)")
            } catch {
                print("Error using credits: \(error)")
            }
        }
    }

    func hasCredits(_ amount: Int) -> Bool {
        return credits >= amount
    }

    func addCredits(_ amount: Int) {
        credits += amount
    }

    func registerUser(credits: Int) async {
        print("Registering user like...")
        do {
            let response = try await UserService.shared.registerUser(initialCredits: credits)
            print("User registered successfully.")
            print(response.credits)
        } catch {
            print("Error registering user: \(error)")
        }
    }

    func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        let isActive = customerInfo.entitlements.all["Pro"]?.isActive == true
        isSubscribed = isActive
        self.customerInfo = customerInfo

        if isActive {
            if let activeSubscription = customerInfo.activeSubscriptions.first {
                let creditsToAdd = getCreditsForProduct(activeSubscription)
                addCredits(creditsToAdd)

                Task {
                    do {
                        _ = try await UserService.shared.addCredits(creditsToAdd)
                        print("Credits added successfully")
                    } catch {
                        print("Error adding credits: \(error)")
                    }
                }
            } else if let recentPurchase = customerInfo.allPurchasedProductIdentifiers.first {
                let creditsToAdd = getCreditsForProduct(recentPurchase)
                addCredits(creditsToAdd)

                Task {
                    do {
                        let response = try await UserService.shared.addCredits(creditsToAdd)
                        DispatchQueue.main.async {
                            self.credits = response.total_credits
                        }
                        print("Credits added successfully: \(response.message)")
                    } catch {
                        print("Error adding credits: \(error)")
                    }
                }
            }
        }
    }

    private func getCreditsForProduct(_ productId: String) -> Int {
        switch productId {
        case "com.vemix.credits10":
            return 10
        case "com.vemix.credits20":
            return 20
        case "com.vemix.credits30":
            return 30
        case "com.vemix.credits60":
            return 60
        case "com.vemix.weekly":
            return 10
        case "com.vemix.yearly":
            return 60
        default:
            return 0
        }
    }

    func purchaseCredits(productId: String, completion: @escaping (Bool, Error?) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                completion(false, error)
                return
            }

            guard let creditsOffering = offerings?.offering(identifier: "credits-shop") else {
                completion(false, NSError(domain: "SubscriptionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Credits offering not found"]))
                return
            }

            guard let product = creditsOffering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productId })?.storeProduct else {
                completion(false, NSError(domain: "SubscriptionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Product not found"]))
                return
            }

            Purchases.shared.purchase(product: product) { [weak self] transaction, customerInfo, error, userCancelled in
                if let error = error {
                    completion(false, error)
                    return
                }

                if userCancelled {
                    completion(false, NSError(domain: "SubscriptionManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled"]))
                    return
                }

                if let customerInfo = customerInfo {
                    let creditsToAdd = self?.getCreditsForProduct(productId) ?? 0

                    Task {
                        do {
                            let response = try await UserService.shared.addCredits(creditsToAdd)
                            DispatchQueue.main.async {
                                self?.credits = response.total_credits
                                completion(true, nil)
                            }
                            print("Credits added successfully: \(response.message)")
                        } catch {
                            print("Error adding credits: \(error)")
                            DispatchQueue.main.async {
                                completion(false, error)
                            }
                        }
                    }
                } else {
                    completion(false, nil)
                }
            }
        }
    }
}
