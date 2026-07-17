import Foundation
import StoreKit
import SwiftUI

// Parrot Pro: monthly subscription unlocking unlimited target sounds and
// PDF reports. Free tier: two target sounds per kid, no PDF export.

@MainActor
@Observable
final class ProStore {
    static let productID = "parrot_pro_monthly"
    static let freeSoundLimit = 2

    private(set) var product: Product?
    private(set) var isPro = false
    private(set) var isWorking = false
    var lastMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        if CommandLine.arguments.contains("-uitest-pro") {
            isPro = true
        }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    var priceText: String {
        product?.displayPrice ?? "$1.99"
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            lastMessage = "Could not load the subscription right now."
        }
    }

    func refreshEntitlement() async {
        guard !CommandLine.arguments.contains("-uitest-pro") else { return }
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                entitled = true
            }
        }
        isPro = entitled
    }

    func purchase() async {
        guard let product else {
            await loadProduct()
            guard self.product != nil else { return }
            await purchase()
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlement()
                    lastMessage = nil
                } else {
                    lastMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                lastMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            lastMessage = "Purchase failed. Please try again."
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await refreshEntitlement()
        lastMessage = isPro ? "Parrot Pro restored." : "No previous purchase found."
    }

    func canAddSound(to kid: Kid) -> Bool {
        isPro || kid.sounds.count < Self.freeSoundLimit
    }
}
