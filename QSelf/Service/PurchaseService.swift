import StoreKit
import Foundation

/// One-time-purchase (non-consumable) Pro unlock. No server-side receipt
/// validation needed per CLAUDE.md — StoreKit 2's local transaction
/// verification is sufficient for a single-user, on-device app.
@MainActor
final class PurchaseService: ObservableObject {

    static let productID = "com.app.quantifiedself.pro.lifetime"

    @Published private(set) var product: Product?
    @Published var errorMessage: String?
    @Published private(set) var isPurchasing = false

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase() async {
        guard let product else {
            errorMessage = "Pro isn't available for purchase right now. Try again later."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    UserDefaults.standard.set(true, forKey: "isPro")
                    await transaction.finish()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        var restored = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == Self.productID {
                UserDefaults.standard.set(true, forKey: "isPro")
                restored = true
            }
        }
        if !restored {
            errorMessage = "No previous purchase found for this Apple ID."
        }
    }
}
