import Testing
import StoreKitTest
@testable import QSelf

/// `xcodebuild test` from the command line does not honor the scheme's
/// StoreKitConfigurationFileReference the way Xcode's own Test/Run action
/// does (that wiring is IDE-integration-only) — so tests load the config
/// directly via SKTestSession instead, which works from any test runner.
struct PurchaseServiceTests {

    private func makeTestSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "Configuration")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    @Test @MainActor func loadProductFindsTheConfiguredProLifetimeProduct() async throws {
        _ = try makeTestSession()

        let service = PurchaseService()
        await service.loadProduct()

        #expect(service.product?.id == PurchaseService.productID)
        #expect(service.errorMessage == nil)
    }

    @Test @MainActor func purchaseUnlocksProAndPersistsTheFlag() async throws {
        let session = try makeTestSession()
        UserDefaults.standard.set(false, forKey: "isPro")

        let service = PurchaseService()
        await service.loadProduct()
        await service.purchase()

        #expect(UserDefaults.standard.bool(forKey: "isPro") == true)
        #expect(session.allTransactions().count == 1)

        UserDefaults.standard.set(false, forKey: "isPro")
    }

    @Test @MainActor func restorePurchasesFindsAnExistingTransaction() async throws {
        let session = try makeTestSession()
        UserDefaults.standard.set(false, forKey: "isPro")

        let service = PurchaseService()
        await service.loadProduct()
        await service.purchase()
        UserDefaults.standard.set(false, forKey: "isPro")

        await service.restorePurchases()

        #expect(UserDefaults.standard.bool(forKey: "isPro") == true)
        #expect(session.allTransactions().count == 1)

        UserDefaults.standard.set(false, forKey: "isPro")
    }
}
