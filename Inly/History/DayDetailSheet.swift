import SwiftData
import SwiftUI

/// One day: totals, the out periods, and a way to fix forgotten taps.
struct DayDetailSheet: View {
    let day: Date

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WearSession.start) private var allSessions: [WearSession]
    @State private var editing: EditTarget?

    private var interval: DateInterval { WearCalculator.dayInterval(containing: day, calendar: .current) }

    private var sessions: [WearSession] {
        allSessions.filter { $0.start < interval.end && ($0.end ?? .now) > interval.start }
    }

    var body: some View {
        let now = Date.now
        let spans = allSessions.map { SessionSpan(start: $0.start, end: $0.end) }
        let wear = WearCalculator.dayWear(on: day, sessions: spans, now: now, calendar: .current)
        let out = wear.elapsedSeconds - wear.wornSeconds

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.formatted(.dateTime.weekday(.wide)).uppercased())
                        .font(Theme.font(12, .semibold)).tracking(1).foregroundStyle(Theme.muted)
                    Text(day.formatted(.dateTime.month(.wide).day().year()))
                        .font(Theme.font(28, .heavy))
                }
                HStack(spacing: 12) {
                    stat("Worn", TimeFormat.hoursMinutes(wear.wornSeconds), Theme.inColor)
                    stat("Out", TimeFormat.hoursMinutes(out), Theme.outColor)
                }

                Text("Out periods").font(Theme.font(17, .heavy))
                if sessions.isEmpty {
                    Text("No breaks recorded this day.")
                        .font(Theme.font(15, .semibold)).foregroundStyle(Theme.muted)
                } else {
                    VStack(spacing: 8) {
                        ForEach(sessions) { s in
                            Button { editing = EditTarget(session: s) } label: { row(s, now: now) }
                                .buttonStyle(.plain)
                        }
                    }
                }

                Button { editing = EditTarget(session: nil) } label: {
                    Label("Add a missed break", systemImage: "plus")
                        .font(Theme.font(16, .heavy))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.raised, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .presentationDetents([.fraction(0.7), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
        .sheet(item: $editing) { target in
            SessionEditSheet(session: target.session, day: day)
        }
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(Theme.font(11, .heavy)).tracking(1).foregroundStyle(color)
            Text(value).font(Theme.font(22, .heavy).monospacedDigit())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func row(_ s: WearSession, now: Date) -> some View {
        let end = s.end ?? now
        let time = "\(s.start.formatted(date: .omitted, time: .shortened)) – \(s.end == nil ? "now" : end.formatted(date: .omitted, time: .shortened))"
        return HStack(spacing: 12) {
            Image(systemName: s.reason.symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.outColor)
                .frame(width: 40, height: 40)
                .background(Theme.outColor.opacity(0.16), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(s.reason.title).font(Theme.font(16, .heavy))
                Text(time).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
            }
            Spacer()
            Text(TimeFormat.hoursMinutes(end.timeIntervalSince(s.start)))
                .font(Theme.font(15, .heavy).monospacedDigit())
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.muted)
        }
        .padding(12)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit this break")
    }
}

struct EditTarget: Identifiable {
    let id = UUID()
    let session: WearSession?
}

/// Add a missed break or edit an existing one.
struct SessionEditSheet: View {
    let session: WearSession?
    let day: Date

    @Environment(\.dismiss) private var dismiss
    @Query private var allSessions: [WearSession]

    @State private var start: Date
    @State private var end: Date
    @State private var reason: OutReason
    @State private var error: String?
    @State private var confirmDelete = false

    private var isOpen: Bool { session != nil && session?.end == nil }

    init(session: WearSession?, day: Date) {
        self.session = session
        self.day = day
        let cal = Calendar.current
        if let session {
            _start = State(initialValue: session.start)
            _end = State(initialValue: session.end ?? .now)
            _reason = State(initialValue: session.reason)
        } else {
            let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
            let s = min(noon, Date.now.addingTimeInterval(-30 * 60))
            _start = State(initialValue: s)
            _end = State(initialValue: s.addingTimeInterval(30 * 60))
            _reason = State(initialValue: .meal)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(session == nil ? "Add a missed break" : "Edit break")
                .font(Theme.font(28, .heavy))

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(OutReason.allCases, id: \.self) { r in
                        Button { reason = r } label: { Label(r.title, systemImage: r.symbol) }
                            .buttonStyle(ChipStyle(selected: reason == r, color: Theme.outColor))
                    }
                }
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 0) {
                DatePicker("Out at", selection: $start, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                    .padding(.vertical, 8)
                Divider().overlay(Theme.surface)
                if isOpen {
                    Text("Still out. Put your aligners back in from Today to finish this break.")
                        .font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                        .padding(.vertical, 10)
                } else {
                    DatePicker("Back in at", selection: $end, in: start...Date.now, displayedComponents: [.date, .hourAndMinute])
                        .padding(.vertical, 8)
                }
            }
            .font(Theme.font(16, .semibold))
            .padding(.horizontal, 16)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            if let error {
                Text(error).font(Theme.font(14, .heavy)).foregroundStyle(Theme.overColor)
            }

            VStack(spacing: 6) {
                Button("Save") { save() }
                    .buttonStyle(PillButtonStyle(color: Theme.inColor))
                if session != nil {
                    Button("Delete this break", role: .destructive) { confirmDelete = true }
                        .font(Theme.font(16, .heavy))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                Button("Cancel") { dismiss() }
                    .font(Theme.font(16, .heavy))
                    .foregroundStyle(Color(hex: 0xC9C9D2))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
        .confirmationDialog("Delete this break?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let session { SessionService.shared.delete(session) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func save() {
        let now = Date.now
        let others = allSessions
            .filter { $0.persistentModelID != session?.persistentModelID }
            .map { SessionSpan(start: $0.start, end: $0.end) }

        if isOpen {
            if WearCalculator.hasOverlap(start: start, end: now, others: others, now: now) {
                error = "That overlaps another break."
                return
            }
            session?.start = start
            session?.reason = reason
            SessionService.shared.commit()
            dismiss()
            return
        }

        guard end > start else { error = "\"Back in\" has to be after \"out\"."; return }
        guard end <= now else { error = "You can't log a break in the future."; return }
        if WearCalculator.hasOverlap(start: start, end: end, others: others, now: now) {
            error = "That overlaps another break."
            return
        }
        if let session {
            session.start = start
            session.end = end
            session.reason = reason
            SessionService.shared.commit()
        } else {
            SessionService.shared.addSession(start: start, end: end, reason: reason)
        }
        dismiss()
    }
}
