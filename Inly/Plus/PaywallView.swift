import StoreKit
import SwiftUI

/// The Inly+ screen: one lifetime purchase, a free 7-day trial, no subscription.
struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var store = Store.shared
    @State private var redeeming = false
    @State private var unlocked = false
    @State private var appeared = false

    private struct Benefit: Identifiable {
        let id: PaywallReason
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }

    private var benefits: [Benefit] {
        let all = [
            Benefit(id: .watch, icon: "applewatch", color: Theme.phaseColor(2), title: L10n.t("Apple Watch & complications"), detail: L10n.t("Log from your wrist. Your day on the watch face.")),
            Benefit(id: .widgets, icon: "square.grid.2x2.fill", color: Theme.inColor, title: L10n.t("Home & Lock Screen widgets"), detail: L10n.t("Your ring and out timer at a glance.")),
            Benefit(id: .sync, icon: "icloud.fill", color: Theme.inColor, title: L10n.t("iCloud sync & auto backup"), detail: L10n.t("Your history follows you to a new iPhone.")),
            Benefit(id: .retainer, icon: "moon.stars.fill", color: Theme.retainerColor, title: L10n.t("Retainer mode"), detail: L10n.t("Nights or full time, for years after treatment.")),
            Benefit(id: .history, icon: "calendar", color: Theme.phaseColor(1), title: L10n.t("Full history & weekly score"), detail: L10n.t("Every day, every tray, your streaks.")),
            Benefit(id: .photos, icon: "photo.stack.fill", color: Theme.trayColor, title: L10n.t("Unlimited progress photos"), detail: L10n.t("Compare any two trays side by side.")),
            Benefit(id: .export, icon: "doc.richtext.fill", color: Theme.outColor, title: L10n.t("Reports for your orthodontist"), detail: L10n.t("A clean PDF or CSV before each visit.")),
        ]
        guard let first = all.firstIndex(where: { $0.id == reason }) else { return all }
        var sorted = all
        sorted.insert(sorted.remove(at: first), at: 0)
        return sorted
    }

    private var headline: String {
        switch reason {
        case .general: L10n.t("Everything Inly can do.")
        case .watch: L10n.t("Inly on your wrist.")
        case .widgets: L10n.t("Your day, on every screen.")
        case .sync: L10n.t("Never lose your history.")
        case .retainer: L10n.t("Your retainer years, covered.")
        case .history: L10n.t("Your whole story, not just two weeks.")
        case .photos: L10n.t("Keep every step of your smile.")
        case .export: L10n.t("Bring a report to your orthodontist.")
        }
    }

    private var canTrial: Bool { store.canStartTrial }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    benefitList
                    planCard
                    actions
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)

            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.text)
                    .frame(width: 38, height: 38)
            }
            .glassEffect(.regular.interactive(), in: Circle())
            .padding(16)
            .accessibilityLabel(L10n.t("Close"))
        }
        .background(background.ignoresSafeArea())
        .overlay { if unlocked { successOverlay } }
        .offerCodeRedemption(isPresented: $redeeming) { _ in Task { await store.refresh(); if store.isPlus { celebrate() } } }
        .task { if store.lifetime == nil && !store.paywallShot { await store.loadProducts() } }
        .onAppear { withAnimation(.spring(duration: 0.9, bounce: 0.25)) { appeared = true } }
    }

    // MARK: Pieces

    private var background: some View {
        ZStack {
            Theme.night
            RadialGradient(colors: [Theme.inColor.opacity(0.28), .clear], center: .top, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Theme.phaseColor(1).opacity(0.14), .clear], center: .topTrailing, startRadius: 0, endRadius: 360)
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(Theme.track, lineWidth: 12).frame(width: 108, height: 108)
                Circle()
                    .trim(from: 0, to: appeared ? 0.92 : 0.05)
                    .stroke(AngularGradient(colors: [Theme.inColor, Theme.phaseColor(1), Theme.retainerColor, Theme.inColor], center: .center),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 108, height: 108)
                    .shadow(color: Theme.inColor.opacity(0.55), radius: 18)
                Text("+").font(Theme.font(44, .heavy)).foregroundStyle(Theme.text)
            }
            .padding(.top, 6)
            HStack(spacing: 0) {
                Text("Inly").foregroundStyle(Theme.text)
                Text("+").foregroundStyle(Theme.inColor)
            }
            .font(Theme.font(40, .heavy))
            Text(headline)
                .font(Theme.font(20, .heavy)).multilineTextAlignment(.center)
            Text(L10n.t("Pay once. Yours for your whole treatment and your retainer years."))
                .font(Theme.font(15, .semibold)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private var benefitList: some View {
        VStack(spacing: 0) {
            ForEach(Array(benefits.enumerated()), id: \.element.id) { index, b in
                HStack(spacing: 14) {
                    Image(systemName: b.icon)
                        .font(.system(size: 17, weight: .bold)).foregroundStyle(b.color)
                        .frame(width: 40, height: 40)
                        .background(b.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.title).font(Theme.font(16, .heavy))
                        Text(b.detail).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                    }
                    Spacer(minLength: 0)
                    if b.id == reason && reason != .general {
                        Image(systemName: "sparkle").font(.system(size: 13, weight: .heavy)).foregroundStyle(b.color)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 18)
                .animation(.spring(duration: 0.6).delay(0.05 * Double(index) + 0.15), value: appeared)
                if index < benefits.count - 1 { Divider().overlay(Theme.raised).padding(.leading, 70) }
            }
        }
        .padding(.vertical, 4)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var planCard: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Inly+ Lifetime")).font(Theme.font(18, .heavy))
                Text(L10n.t("One-time purchase · No subscription")).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                Label(L10n.t("Family Sharing included"), systemImage: "person.2.fill")
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.trayColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Theme.trayColor.opacity(0.14), in: Capsule())
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
            Group {
                if let price = store.lifetimePrice {
                    Text(price)
                } else if store.productsFailed {
                    Image(systemName: "wifi.exclamationmark")
                } else {
                    ProgressView()
                }
            }
            .font(Theme.font(26, .heavy))
            .foregroundStyle(Theme.text)
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.inColor.opacity(0.6), lineWidth: 1.5))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if store.productsFailed && store.lifetimePrice == nil {
                Text(L10n.t("Couldn't reach the App Store. Check your connection."))
                    .font(Theme.font(14, .semibold)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                Button(L10n.t("Try again")) { Task { await store.loadProducts() } }
                    .buttonStyle(PillButtonStyle(color: Theme.text, foreground: Theme.night))
            } else if canTrial {
                Button { purchase(store.trialProduct) } label: { buttonLabel(L10n.t("Try free for %d days", Store.trialDays)) }
                    .buttonStyle(PillButtonStyle(color: Theme.inColor, foreground: Theme.night))
                Text(L10n.t("Free for 7 days. No automatic charge, nothing to cancel."))
                    .font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                Button { purchase(store.lifetime) } label: {
                    Text(store.lifetimePrice.map { L10n.t("Or unlock now for %@", $0) } ?? L10n.t("Unlock Inly+"))
                        .font(Theme.font(16, .heavy)).foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Button { purchase(store.lifetime) } label: {
                    buttonLabel(store.lifetimePrice.map { L10n.t("Unlock Inly+ · %@", $0) } ?? L10n.t("Unlock Inly+"))
                }
                .buttonStyle(PillButtonStyle(color: Theme.inColor, foreground: Theme.night))
                if store.trialUsed && !store.trialActive {
                    Text(L10n.t("Your free trial has ended. Your data is safe and waiting."))
                        .font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                }
            }
        }
        .disabled(store.busy)
    }

    private func buttonLabel(_ title: String) -> some View {
        HStack(spacing: 8) {
            if store.busy { ProgressView().tint(Theme.night) }
            Text(title)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack(spacing: 18) {
                Button(L10n.t("Restore purchases")) { Task { await store.restore(); if store.isPlus { celebrate() } } }
                Button(L10n.t("Redeem code")) { redeeming = true }
            }
            .font(Theme.font(14, .heavy))
            .foregroundStyle(Theme.text)
            HStack(spacing: 18) {
                Button(L10n.t("Terms of Use")) { openURL(LegalLinks.terms) }
                Button(L10n.t("Privacy Policy")) { openURL(LegalLinks.privacy) }
            }
            .font(Theme.font(12, .semibold))
            .foregroundStyle(Theme.muted)
            Text(L10n.t("Your tracking, reminders and Live Activity stay free forever."))
                .font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
    }

    private var successOverlay: some View {
        ZStack {
            Theme.night.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72, weight: .bold)).foregroundStyle(Theme.trayColor)
                    .symbolEffect(.bounce, value: unlocked)
                Text(L10n.t("Inly+ is unlocked")).font(Theme.font(26, .heavy))
                Text(store.trialActive && !store.ownsLifetime ? L10n.t("Enjoy everything free for %d days.", Store.trialDays) : L10n.t("Thank you for supporting Inly."))
                    .font(Theme.font(15, .semibold)).foregroundStyle(Theme.muted)
            }
        }
        .transition(.opacity)
    }

    // MARK: Actions

    private func purchase(_ product: Product?) {
        Task {
            // Cancelled or failed: nothing was charged, the screen simply stays.
            if await store.buy(product) { celebrate() }
        }
    }

    private func celebrate() {
        withAnimation(.smooth) { unlocked = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            dismiss()
        }
    }
}

enum LegalLinks {
    static let site = URL(string: "https://inly-app.netlify.app/")!
    static let terms = URL(string: "https://inly-app.netlify.app/terms")!
    static let privacy = URL(string: "https://inly-app.netlify.app/privacy")!
    static let support = URL(string: "https://inly-app.netlify.app/support")!
    static let supportEmail = "support@healus-ai.com"
}
