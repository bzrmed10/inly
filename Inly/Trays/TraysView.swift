import SwiftData
import SwiftUI

private struct ToastData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let undo: () -> Void
}

struct TraysView: View {
    @Query(sort: \Tray.number, order: .reverse) private var trays: [Tray]
    @Query private var sessions: [WearSession]

    @State private var settings = WearSettings.load()
    @State private var showStart = false
    @State private var showExtend = false
    @State private var showAppointment = false
    @State private var showCompare = false
    @State private var detailTray: Tray?
    @State private var toast: ToastData?
    @State private var toastTask: Task<Void, Never>?

    private var current: Tray? { trays.first(where: { $0.endDate == nil }) }
    private var finished: [Tray] { trays.filter { $0.endDate != nil } }
    private var spans: [SessionSpan] { sessions.map { SessionSpan(start: $0.start, end: $0.end) } }
    private var trackingMoment: Date? { settings.resolvedTrackingStart(firstSession: sessions.map(\.start).min()) }
    private func from(_ tray: Tray) -> Date { max(tray.startDate, trackingMoment ?? tray.startDate) }
    private var forecast: Insights.Forecast? {
        guard let current else { return nil }
        return Insights.forecast(
            currentStart: current.startDate, plannedDays: current.plannedDays, currentNumber: current.number,
            totalTrays: max(settings.totalTrays, current.number), defaultDays: settings.defaultTrayDays, now: .now, calendar: .current
        )
    }
    private var nextNumber: Int { (trays.first?.number ?? 0) + 1 }
    private let insets = EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20)

    var body: some View {
        ZStack(alignment: .top) {
            List {
                header.row(insets)
                progress.row(insets)
                appointmentCard.row(insets)
                if trays.filter({ $0.photoData != nil }).count >= 2 {
                    compareButton.row(insets)
                }
                if let current {
                    currentCard(current).row(insets)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { delete(current) } label: { Label(L10n.t("Delete"), systemImage: "trash") }
                        }
                } else {
                    emptyCard.row(insets)
                }
                if !finished.isEmpty {
                    historyHeader.row(EdgeInsets(top: 12, leading: 20, bottom: 4, trailing: 20))
                    ForEach(finished) { tray in
                        historyRow(tray).row(insets)
                            .contentShape(Rectangle())
                            .onTapGesture { detailTray = tray }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { delete(tray) } label: { Label(L10n.t("Delete"), systemImage: "trash") }
                            }
                    }
                }
                Color.clear.frame(height: 90).row(insets)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)

            if let toast {
                ToastBanner(title: toast.title, subtitle: toast.subtitle) {
                    toast.undo()
                    withAnimation(.smooth) { self.toast = nil }
                }
                .padding(.top, 6)
            }
        }
        .background(Theme.night.ignoresSafeArea())
        .onAppear { settings = WearSettings.load() }
        .sheet(isPresented: $showStart) {
            StartTraySheet(current: current, nextNumber: nextNumber, defaultDays: settings.defaultTrayDays) { date, days in
                TrayNotifications.requestPermission()
                let undo = SessionService.shared.startNextTray(on: date, plannedDays: days)
                let started = nextNumber - 1
                let due = TrayLogic.switchDate(start: date, plannedDays: days, calendar: .current)
                let dueText = L10n.date(due, .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                show(ToastData(title: L10n.t("Tray %d started", started), subtitle: L10n.t("Switch reminder %@", dueText)) {
                    SessionService.shared.undoStartTray(undo)
                })
            }
        }
        .sheet(isPresented: $showExtend) {
            if let current {
                ExtendTraySheet(tray: current) { days in
                    SessionService.shared.extendCurrentTray(by: days)
                }
            }
        }
        .sheet(isPresented: $showCompare) { CompareSheet() }
        .sheet(item: $detailTray) { tray in TrayDetailSheet(tray: tray, onClose: { detailTray = nil }) }
        .sheet(isPresented: $showAppointment) {
            AppointmentSheet(initial: settings.nextAppointment) { date in
                if date != nil { TrayNotifications.requestPermission() }
                settings.nextAppointment = date
                settings.save()
                AppointmentReminders.schedule(date)
            }
        }
        .sensoryFeedback(.success, trigger: toast?.id)
    }

    // MARK: Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("Treatment · %@", L10n.trays(max(settings.totalTrays, trays.first?.number ?? 0))))
                .font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)
            Text(L10n.t("Trays")).font(Theme.font(36, .heavy))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var progress: some View {
        let total = max(settings.totalTrays, trays.first?.number ?? 0, 1)
        let cur = current?.number ?? nextNumber
        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: min(24, total))
        return VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.t("Tray %d of %d", min(cur, total), total)).font(Theme.font(15, .heavy))
                Spacer()
                Text(L10n.t("%@ to go", L10n.trays(max(0, total - cur)))).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
            }
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(1...total, id: \.self) { i in
                    Capsule()
                        .fill(i < cur ? Theme.trayColor : (i == cur ? Color.white : Color(hex: 0x2A2A33)))
                        .frame(height: 8)
                }
            }
            if let f = forecast {
                HStack {
                    Image(systemName: "flag.checkered").foregroundStyle(Theme.trayColor)
                    Text(L10n.t("Estimated finish %@", L10n.shortDate(f.finishDate, year: true)))
                        .font(Theme.font(14, .heavy))
                    Spacer()
                    Text(f.daysLeft == 0 ? L10n.t("today") : L10n.t("in %@", L10n.days(f.daysLeft)))
                        .font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                }
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var compareButton: some View {
        Button { showCompare = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.split.2x1")
                    .font(.title3).foregroundStyle(Theme.trayColor)
                    .frame(width: 40, height: 40).background(Theme.raised, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("Compare photos")).font(Theme.font(15, .heavy))
                    Text(L10n.t("See how your smile has moved")).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var appointmentCard: some View {
        let appt = settings.nextAppointment.flatMap { $0 > .now ? $0 : nil }
        return Button { showAppointment = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3).foregroundStyle(Theme.inColor)
                    .frame(width: 40, height: 40).background(Theme.raised, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("Orthodontist visit")).font(Theme.font(15, .heavy))
                    if let appt {
                        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: appt)).day ?? 0
                        Text("\(L10n.date(appt, .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())) · \(days == 0 ? L10n.t("today") : (days == 1 ? L10n.t("tomorrow") : L10n.t("in %@", L10n.days(days))))")
                            .font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                    } else {
                        Text(L10n.t("Add your next appointment")).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appt == nil ? L10n.t("Add orthodontist visit") : L10n.t("Edit orthodontist visit"))
    }

    private func currentCard(_ tray: Tray) -> some View {
        let cal = Calendar.current
        let elapsed = TrayLogic.daysElapsed(start: tray.startDate, now: .now, calendar: cal)
        let dayN = elapsed + 1
        let over = TrayLogic.overage(start: tray.startDate, plannedDays: tray.plannedDays, now: .now, calendar: cal)
        let tint = over > 0 ? Theme.outColor : Theme.trayColor
        let due = TrayLogic.switchDate(start: tray.startDate, plannedDays: tray.plannedDays, calendar: cal)
        let avg = WearCalculator.averageWornHours(from: from(tray), to: .now, sessions: spans, now: .now, calendar: cal)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.t("Current tray")).font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)
                Spacer()
                Text(L10n.t("Day %d of %d", dayN, tray.plannedDays))
                    .font(Theme.font(13, .heavy)).foregroundStyle(tint)
                    .padding(.horizontal, 12).frame(height: 28)
                    .background(tint.opacity(0.16), in: Capsule())
            }
            Text(L10n.t("Tray %d", tray.number))
                .font(Theme.font(38, .heavy)).minimumScaleFactor(0.7).lineLimit(1)
            if over > 0 {
                Text(L10n.t("+%@ over the plan", L10n.days(over)))
                    .font(Theme.font(15, .heavy)).foregroundStyle(Theme.outColor)
            }
            ProgressView(value: min(1, Double(dayN) / Double(max(1, tray.plannedDays))))
                .tint(tint)
            HStack(alignment: .top) {
                info(L10n.t("Started"), L10n.shortDate(tray.startDate))
                info(L10n.t("Switch on"), L10n.date(due, .dateTime.weekday(.abbreviated).month(.abbreviated).day()).replacingOccurrences(of: ",", with: ""))
                info(L10n.t("Avg wear"), TimeFormat.hoursMinutes(avg * 3600))
            }
            Button { showStart = true } label: {
                Label(L10n.t("Start tray %d", tray.number + 1), systemImage: "plus")
            }
            .buttonStyle(PillButtonStyle(color: .white, height: 54))
            Button { detailTray = tray } label: {
                Label(tray.photoData == nil ? L10n.t("Photo & notes") : L10n.t("Photo & notes ✓"), systemImage: "camera")
            }
            .font(Theme.font(15, .heavy))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Theme.raised, in: Capsule())
            .buttonStyle(.plain)
            Button { showExtend = true } label: { Text(L10n.t("Extend plan")) }
                .font(Theme.font(15, .heavy))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.raised, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(18)
        .background(alignment: .topTrailing) {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.35), tint.opacity(0)], center: .center, startRadius: 0, endRadius: 120))
                .frame(width: 240, height: 240)
                .offset(x: 70, y: -90)
                .blur(radius: 10)
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("No tray yet")).font(Theme.font(24, .heavy))
            Text(L10n.t("Start a tray to track how many days you stay on it."))
                .font(Theme.font(15, .semibold)).foregroundStyle(Theme.muted)
            Button { showStart = true } label: { Label(L10n.t("Start tray %d", nextNumber), systemImage: "plus") }
                .buttonStyle(PillButtonStyle(color: .white, height: 54))
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func info(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(Theme.font(12, .bold)).foregroundStyle(Theme.muted)
            Text(value).font(Theme.font(15, .heavy)).minimumScaleFactor(0.7).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var historyHeader: some View {
        let days = finished.map { TrayLogic.daysSpent(start: $0.startDate, end: $0.endDate, now: .now, calendar: .current) }
        let avg = days.isEmpty ? 0 : Double(days.reduce(0, +)) / Double(days.count)
        return HStack(alignment: .firstTextBaseline) {
            Text(L10n.t("Tray history")).font(Theme.font(20, .heavy))
            Spacer()
            Text(L10n.t("%d done · avg %@ days", finished.count, String(format: "%.1f", avg)))
                .font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
        }
    }

    private func historyRow(_ tray: Tray) -> some View {
        let cal = Calendar.current
        let days = TrayLogic.daysSpent(start: tray.startDate, end: tray.endDate, now: .now, calendar: cal)
        let delta = days - tray.plannedDays
        let barColor: Color = delta > 0 ? Theme.outColor : (delta < 0 ? Theme.inColor : Theme.trayColor)
        let noteColor: Color = delta > 0 ? Theme.outColor : (delta < 0 ? Color(hex: 0x8DBBFF) : Theme.muted)
        let note = delta == 0 ? L10n.t("on plan") : (delta > 0 ? "+" + L10n.days(delta) : "−" + L10n.days(-delta))
        let avg = WearCalculator.averageWornHours(from: from(tray), to: tray.endDate ?? .now, sessions: spans, now: .now, calendar: cal)
        let md: (Date) -> String = { L10n.shortDate($0) }

        return HStack(spacing: 12) {
            Text("\(tray.number)")
                .font(Theme.font(16, .heavy))
                .frame(width: 40, height: 40)
                .background(Theme.raised, in: Circle())
            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.t("Tray %d · %@ – %@", tray.number, md(tray.startDate), md(tray.endDate ?? .now)) + (tray.photoData == nil ? "" : "  📷"))
                        .font(Theme.font(15, .heavy)).lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength: 6)
                    Text(L10n.days(days)).font(Theme.font(15, .heavy))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.raised)
                        Capsule().fill(barColor).frame(width: geo.size.width * min(1, Double(days) / 16))
                    }
                }
                .frame(height: 6)
                HStack {
                    Text(L10n.t("avg wear %@", TimeFormat.hoursMinutes(avg * 3600)))
                    Spacer()
                    Text(note).foregroundStyle(noteColor)
                }
                .font(Theme.font(12, .bold)).foregroundStyle(Theme.muted)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Actions

    private func delete(_ tray: Tray) {
        let number = tray.number
        let undo = SessionService.shared.deleteTray(tray)
        show(ToastData(title: L10n.t("Tray %d deleted", number), subtitle: nil) {
            SessionService.shared.undoDelete(undo)
        })
    }

    private func show(_ data: ToastData) {
        withAnimation(.smooth) { toast = data }
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(7))
            if !Task.isCancelled { withAnimation(.smooth) { toast = nil } }
        }
    }
}

private extension View {
    /// Plain list row: no separator or background, custom insets.
    func row(_ insets: EdgeInsets) -> some View {
        self.listRowInsets(insets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
