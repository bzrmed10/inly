import SwiftData
import SwiftUI

struct TodayView: View {
    var onOpenTrays: () -> Void = {}

    @Query(sort: \WearSession.start) private var sessions: [WearSession]
    @Query(filter: #Predicate<Tray> { $0.endDate == nil }, sort: \Tray.startDate, order: .reverse)
    private var currentTrays: [Tray]

    @State private var settings = WearSettings.load()
    @State private var toggles = 0
    @State private var toast: String?
    @State private var toastIsOut = false
    @State private var toastTask: Task<Void, Never>?
    @AppStorage("plusTrialCardDismissed") private var trialCardDismissed = false

    private var openSession: WearSession? { sessions.last(where: { $0.end == nil }) }

    var body: some View {
        ZStack(alignment: .top) {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                content(now: timeline.date)
            }
            if let toast {
                ToastBanner(title: toast, color: toastIsOut ? Theme.outColor : Theme.inColor) {
                    SessionService.shared.undoLastToggle()
                    withAnimation(.smooth) { self.toast = nil }
                }
                .padding(.top, 6)
            }
        }
        .background(Theme.night.ignoresSafeArea())
        .onAppear { settings = WearSettings.load() }
        .sensoryFeedback(.impact(weight: .medium), trigger: toggles)
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let spans = sessions.map { SessionSpan(start: $0.start, end: $0.end) }
        let snap = WearCalculator.snapshot(
            sessions: spans, now: now, budgetSeconds: settings.budgetSeconds, calendar: .current,
            trackingStart: settings.resolvedTrackingStart(firstSession: sessions.first?.start)
        )
        let color = ringColor(snap)

        ScrollView {
            VStack(spacing: 18) {
                header(now: now)
                trayCard(now: now)
                if snap.isOut { reasonChips }
                hero(snap: snap, color: color, now: now)
                statusPill(snap: snap, color: color)
                timelineCard(now: now)
                stats(snap: snap)
                plusCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            actionButton(snap: snap)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    /// A quiet invitation below the stats: the free trial from the second day, or retainer mode after the trial.
    @ViewBuilder
    private var plusCard: some View {
        let store = Store.shared
        if !store.isPlus && settings.retainerMode {
            plusInvite(icon: "moon.stars.fill", color: Theme.retainerColor,
                       title: L10n.t("Retainer mode is part of Inly+"),
                       detail: L10n.t("Your timer keeps working. Unlock nightly schedules and bedtime reminders."),
                       button: L10n.t("Unlock"), reason: .retainer, dismissible: false)
        } else if !store.isPlus && !store.trialUsed && !trialCardDismissed && ReviewPrompter.shared.daysSinceFirstLaunch >= 1 {
            plusInvite(icon: "sparkles", color: Theme.inColor,
                       title: L10n.t("Try Inly+ free for 7 days"),
                       detail: L10n.t("Apple Watch, widgets, iCloud sync, full history and reports. No automatic charge."),
                       button: L10n.t("Try free"), reason: .general, dismissible: true)
        }
    }

    private func plusInvite(icon: String, color: Color, title: String, detail: String, button: String, reason: PaywallReason, dismissible: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(color)
                .frame(width: 40, height: 40).background(color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.font(16, .heavy))
                Text(detail).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                Button(button) { Store.shared.paywall = reason }
                    .font(Theme.font(14, .heavy)).foregroundStyle(Theme.night)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(color, in: Capsule())
                    .buttonStyle(.plain)
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
            if dismissible {
                Button { withAnimation(.smooth) { trialCardDismissed = true } } label: {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.muted)
                        .frame(width: 28, height: 28).background(Theme.raised, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.t("Close"))
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func ringColor(_ snap: WearSnapshot) -> Color {
        if snap.isOut { return snap.isOverBudget ? Theme.overColor : Theme.outColor }
        return Theme.inColor
    }

    // MARK: Header

    private func header(now: Date) -> some View {
        let name = settings.userName.trimmingCharacters(in: .whitespaces)
        let phrase = Greeting.phrase(for: now)
        let light = Font.system(size: 30, weight: .light, design: .rounded)
        let bold = Font.system(size: 30, weight: .heavy, design: .rounded)
        return VStack(alignment: .leading, spacing: 2) {
            Text(L10n.date(now, .dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(Theme.font(12, .semibold)).tracking(1).foregroundStyle(Theme.muted)
            Group {
                if name.isEmpty {
                    Text(phrase + L10n.t("!")).font(light)
                } else {
                    Text("\(Text(phrase + L10n.t(", ")).font(light))\(Text(name).font(bold))\(Text(L10n.t("!")).font(light))")
                }
            }
            .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Tray card

    @ViewBuilder
    private func trayCard(now: Date) -> some View {
        if settings.retainerMode {
            retainerCard
        } else if let tray = currentTrays.first {
            let cal = Calendar.current
            let elapsed = TrayLogic.daysElapsed(start: tray.startDate, now: now, calendar: cal)
            let dayN = elapsed + 1
            let over = TrayLogic.overage(start: tray.startDate, plannedDays: tray.plannedDays, now: now, calendar: cal)
            let left = TrayLogic.daysUntilSwitch(start: tray.startDate, plannedDays: tray.plannedDays, now: now, calendar: cal)
            let tint = over > 0 ? Theme.outColor : Theme.phaseColor(tray.phase)
            let subtitle: String = {
                if over > 0 { return L10n.t("+%@ over the plan", L10n.days(over)) }
                if left == 0 { return L10n.t("Switch to tray %d today", tray.displayNumber + 1) }
                return L10n.t("Day %d of %d · switch in %@", dayN, tray.plannedDays, L10n.days(left))
            }()
            Button(action: onOpenTrays) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().stroke(Theme.raised, lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: max(0.02, min(1, Double(dayN) / Double(max(1, tray.plannedDays)))))
                            .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(tray.displayNumber)").font(Theme.font(17, .heavy))
                    }
                    .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(trayTitle(tray))
                            .font(Theme.font(17, .heavy))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(subtitle)
                            .font(Theme.font(14, .semibold)).foregroundStyle(over > 0 ? Theme.outText : Theme.muted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.muted)
                }
                .padding(14)
                .background(alignment: .leading) {
                    Circle().fill(tint.opacity(0.22)).frame(width: 120, height: 120).blur(radius: 30).offset(x: -30)
                }
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint(L10n.t("Opens your trays"))
        } else {
            Button(action: onOpenTrays) {
                Card {
                    Text(L10n.t("Set up your tray")).font(Theme.font(17, .heavy))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func trayTitle(_ tray: Tray) -> String {
        let of = max(settings.totalTrays, tray.displayNumber)
        return tray.phase > 0
            ? L10n.t("Refinement %d · Tray %d of %d", tray.phase, tray.displayNumber, of)
            : L10n.t("Tray %d of %d", tray.displayNumber, of)
    }

    private var retainerCard: some View {
        let subtitle: String = {
            switch settings.retainerSchedule {
            case .fullTime: return L10n.t("Full-time · %d hours a day", settings.goalHours)
            case .nightly: return L10n.t("Nightly · %d hours", settings.retainerHours)
            case .fewNights: return L10n.t("%d nights a week · %d hours", settings.retainerNights, settings.retainerHours)
            }
        }()
        return Button(action: onOpenTrays) {
            HStack(spacing: 14) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.retainerColor)
                    .frame(width: 52, height: 52).background(Theme.raised, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(TreatmentPhase.retainerName).font(Theme.font(17, .heavy))
                    Text(subtitle).font(Theme.font(14, .semibold)).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.muted)
            }
            .padding(14)
            .background(alignment: .leading) {
                Circle().fill(Theme.retainerColor.opacity(0.22)).frame(width: 120, height: 120).blur(radius: 30).offset(x: -30)
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Reason chips

    private var reasonChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(OutReason.allCases, id: \.self) { reason in
                    Button {
                        SessionService.shared.setReason(reason)
                    } label: {
                        Label(reason.title, systemImage: reason.symbol)
                    }
                    .buttonStyle(ChipStyle(selected: openSession?.reason == reason, color: Theme.outColor))
                }
            }
        }
        .scrollIndicators(.hidden)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Hero

    private func hero(snap: WearSnapshot, color: Color, now: Date) -> some View {
        let seconds: TimeInterval = {
            if snap.isOut, let s = openSession { return now.timeIntervalSince(s.start) }
            return snap.wornSeconds
        }()
        return ZStack {
            GlowRing(progress: snap.isOut ? snap.budgetUsed : snap.goalProgress, color: color)
            VStack(spacing: 4) {
                Text(snap.isOut ? L10n.t("OUT FOR") : L10n.t("WORN TODAY"))
                    .font(Theme.font(13, .heavy))
                    .tracking(1.4)
                    .foregroundStyle(color)
                Text(TimeFormat.clock(seconds))
                    .font(Theme.timerFont(40))
                    .contentTransition(.numericText(countsDown: false))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .frame(width: 230, height: 230)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snap.isOut ? L10n.t("Aligners out") : L10n.t("Worn today"))
        .accessibilityValue(TimeFormat.hoursMinutes(seconds))
    }

    private func statusPill(snap: WearSnapshot, color: Color) -> some View {
        let text: String = {
            if snap.isOverBudget { return L10n.t("Over today's budget") }
            if snap.isOut { return L10n.t("%@ of out-time left", TimeFormat.hoursMinutes(snap.leftSeconds)) }
            return L10n.t("Aligners in · %@ out-time left", TimeFormat.hoursMinutes(snap.leftSeconds))
        }()
        return Text(text)
            .font(Theme.font(15, .semibold))
            .foregroundStyle(snap.isOut && !snap.isOverBudget ? Theme.outText : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(snap.isOut && !snap.isOverBudget ? Theme.outSoft : color.opacity(0.14), in: Capsule())
            .animation(.smooth, value: text)
    }

    // MARK: Day timeline

    private func timelineCard(now: Date) -> some View {
        let cal = Calendar.current
        let day = WearCalculator.dayInterval(containing: now, calendar: cal)
        let todays = sessions.filter { $0.start < day.end && ($0.end ?? now) > day.start }
        let outTotal = WearCalculator.outSeconds(
            in: day, sessions: todays.map { SessionSpan(start: $0.start, end: $0.end) }, now: now
        )
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.t("Today's timeline")).font(Theme.font(17, .heavy))
                    Spacer()
                    Text(todays.isEmpty ? L10n.t("No breaks yet") : L10n.t("%@ · %@ out", L10n.breaks(todays.count), TimeFormat.hoursMinutes(outTotal)))
                        .font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                }
                GeometryReader { geo in
                    let w = geo.size.width
                    let x: (Date) -> CGFloat = { d in
                        w * CGFloat(max(0, min(1, d.timeIntervalSince(day.start) / 86_400)))
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.inColor.opacity(0.35))
                        ForEach(todays) { s in
                            let a = x(max(s.start, day.start))
                            let b = x(min(s.end ?? now, day.end))
                            Capsule().fill(Theme.outColor)
                                .frame(width: max(5, b - a), height: 14)
                                .offset(x: a)
                        }
                        Capsule().fill(Theme.text)
                            .frame(width: 3, height: 22)
                            .offset(x: x(now) - 1.5)
                    }
                    .frame(height: 22)
                }
                .frame(height: 22)
                HStack {
                    ForEach(["0", "6", "12", "18", "24"], id: \.self) { h in
                        Text(h).font(Theme.font(11, .bold)).foregroundStyle(Theme.muted)
                        if h != "24" { Spacer() }
                    }
                }
                HStack(spacing: 14) {
                    legend(Theme.inColor.opacity(0.6), L10n.t("In"))
                    legend(Theme.outColor, L10n.t("Out"))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted)
        }
    }

    // MARK: Stats + action

    private func stats(snap: WearSnapshot) -> some View {
        HStack(spacing: 12) {
            statCard(L10n.t("Worn"), TimeFormat.hoursMinutes(snap.wornSeconds), Theme.inColor)
            statCard(L10n.t("Out"), TimeFormat.hoursMinutes(snap.outSeconds), Theme.outColor)
            statCard(L10n.t("Left"), TimeFormat.hoursMinutes(snap.leftSeconds), snap.isOverBudget ? Theme.overColor : Theme.trayColor)
        }
    }

    private func statCard(_ title: String, _ value: String, _ color: Color) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(Theme.font(11, .heavy))
                    .tracking(1)
                    .foregroundStyle(color)
                Text(value)
                    .font(Theme.font(20, .heavy).monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }

    private func actionButton(snap: WearSnapshot) -> some View {
        Button {
            let wasOut = snap.isOut
            withAnimation(.smooth) {
                if wasOut {
                    SessionService.shared.putBackIn()
                } else {
                    TrayNotifications.requestPermission()
                    SessionService.shared.takeOut()
                }
            }
            toggles += 1
            showToast(wasOut ? L10n.t("Aligners back in") : L10n.t("Aligners out"), isOut: !wasOut)
        } label: {
            Text(snap.isOut ? L10n.t("Put back in") : L10n.t("Take out"))
        }
        .buttonStyle(PillButtonStyle(color: snap.isOut ? Theme.outColor : Theme.inColor))
        .accessibilityHint(snap.isOut ? L10n.t("Records that your aligners are back in") : L10n.t("Starts timing how long your aligners are out"))
    }

    private func showToast(_ text: String, isOut: Bool) {
        toastIsOut = isOut
        withAnimation(.smooth) { toast = text }
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { withAnimation(.smooth) { toast = nil } }
        }
    }
}
