import Foundation
import Observation
import StoreKit
import UserNotifications
import WidgetKit

/// Why the paywall was opened: the matching benefit is shown first.
enum PaywallReason: String, Identifiable, CaseIterable {
    case general, watch, widgets, sync, retainer, history, photos, export
    var id: String { rawValue }
}

/// Inly+ purchases (StoreKit 2, no server). One lifetime purchase, plus a free 7-day trial item.
@MainActor
@Observable
final class Store {
    static let shared = Store()

    static let lifetimeID = "com.bzrmed.inly.plus"
    static let trialID = "com.bzrmed.inly.plus.trial"
    static let trialDays = 7

    private(set) var lifetime: Product?
    private(set) var trialProduct: Product?
    private(set) var productsFailed = false
    private(set) var ownsLifetime = false
    private(set) var isFamilyShared = false
    private(set) var trialStart: Date?
    private(set) var busy = false

    /// Set to open the paywall from anywhere (RootView presents it).
    var paywall: PaywallReason?

    private let demo = ProcessInfo.processInfo.arguments.contains("-demoData") || ProcessInfo.processInfo.arguments.contains("-plusUnlocked")
    private var updates: Task<Void, Never>?

    private init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refresh()
            }
        }
    }

    // MARK: State

    var trialEnd: Date? { trialStart.map { $0.addingTimeInterval(Double(Self.trialDays) * 86_400) } }
    var trialActive: Bool { trialEnd.map { Date.now < $0 } ?? false }
    var trialUsed: Bool { trialStart != nil }
    var isPlus: Bool { demo || ownsLifetime || trialActive }

    /// Runs `action` when Inly+ is unlocked, otherwise opens the paywall for `reason`.
    func require(_ reason: PaywallReason, _ action: () -> Void) {
        if isPlus { action() } else { paywall = reason }
    }

    // MARK: StoreKit

    func start() async {
        await loadProducts()
        await refresh()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.lifetimeID, Self.trialID])
            lifetime = products.first { $0.id == Self.lifetimeID }
            trialProduct = products.first { $0.id == Self.trialID }
            productsFailed = lifetime == nil
        } catch {
            productsFailed = true
        }
    }

    /// Reads what this Apple ID owns and shares the result with the widgets and the watch.
    func refresh() async {
        var owns = false, family = false
        var trial: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result, t.revocationDate == nil else { continue }
            switch t.productID {
            case Self.lifetimeID:
                owns = true
                family = t.ownershipType == .familyShared
            case Self.trialID:
                trial = t.purchaseDate
            default: break
            }
        }
        ownsLifetime = owns
        isFamilyShared = family
        trialStart = trial
        publish()
    }

    @discardableResult
    func buy(_ product: Product?) async -> Bool {
        guard let product, !busy else { return false }
        busy = true
        defer { busy = false }
        do {
            let result = try await product.purchase()
            guard case .success(let verification) = result, case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await refresh()
            if transaction.productID == Self.trialID { scheduleTrialReminder() }
            if isPlus { CloudSync.shared.plusDidUnlock() }
            return isPlus
        } catch {
            return false
        }
    }

    func restore() async {
        busy = true
        defer { busy = false }
        try? await AppStore.sync()
        await refresh()
    }

    private func publish() {
        let active = isPlus
        let changed = PlusStatus.isActive != active
        PlusStatus.set(active)
        if changed {
            WidgetCenter.shared.reloadAllTimelines()
            SessionService.shared.writeWidgetSnapshot()
        }
    }

    /// One reminder the day before the free trial ends. No automatic charge ever happens.
    private func scheduleTrialReminder() {
        guard let end = trialEnd else { return }
        let fire = end.addingTimeInterval(-86_400)
        guard fire > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = L10n.t("Your Inly+ trial ends tomorrow")
        content.body = L10n.t("Keep Apple Watch, widgets, sync and reports with a one-time purchase.")
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let request = UNNotificationRequest(identifier: "inlyPlusTrialEnds", content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}
