import SwiftData
import SwiftUI

/// Create a PDF report or CSV file for the orthodontist and share it.
struct ExportSheet: View {
    @Query private var sessions: [WearSession]
    @Query(sort: \Tray.number) private var trays: [Tray]
    @Query(sort: \TrayNote.date) private var notes: [TrayNote]
    @Environment(\.dismiss) private var dismiss

    enum Period: String, CaseIterable, Identifiable {
        case week = "7 days", month = "30 days", all = "Everything"
        var id: String { rawValue }
        var title: String { L10n.t(rawValue) }
    }
    enum Format: String, CaseIterable, Identifiable {
        case pdf = "PDF report", daily = "CSV · per day"
        var id: String { rawValue }
        var title: String { L10n.t(rawValue) }
        var ext: String { self == .pdf ? "pdf" : "csv" }
    }

    @State private var range: Period = .month
    @State private var format: Format = .pdf
    @State private var fileURL: URL?
    @State private var settings = WearSettings.load()

    private var input: ReportBuilder.Input {
        let cal = Calendar.current
        let now = Date.now
        let tracking = settings.resolvedTrackingStart(firstSession: sessions.map(\.start).min())
        let from: Date = switch range {
        case .week: cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        case .month: cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: now)) ?? now
        case .all: tracking ?? sessions.map(\.start).min() ?? now
        }
        return ReportBuilder.Input(
            name: settings.userName, goalHours: settings.goalHours, from: from, now: now, trackingStart: tracking,
            spans: sessions.map { SessionSpan(start: $0.start, end: $0.end) },
            trays: trays.map { .init(number: $0.number, start: $0.startDate, end: $0.endDate, plannedDays: $0.plannedDays) },
            notes: notes.map { .init(trayNumber: $0.trayNumber, date: $0.date, text: $0.text) },
            appointment: settings.nextAppointment
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.t("Share with your orthodontist")).font(Theme.font(26, .heavy))
            Text(L10n.t("Wear time, trays and notes in one file you can send by email or message."))
                .font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)

            picker(L10n.t("Period"), selection: $range, options: Period.allCases) { $0.title }
            picker(L10n.t("Format"), selection: $format, options: Format.allCases) { $0.title }

            Spacer(minLength: 0)

            if let fileURL {
                ShareLink(item: fileURL) {
                    Label(L10n.t("Share %@", format.ext.uppercased()), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PillButtonStyle(color: Theme.inColor))
            } else {
                ProgressView().frame(maxWidth: .infinity, minHeight: 60)
            }
            Button(L10n.t("Done")) { dismiss() }
                .font(Theme.font(16, .heavy)).foregroundStyle(Color(hex: 0xC9C9D2))
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.fraction(0.62), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
        .onAppear { settings = WearSettings.load() }
        .task(id: "\(range.rawValue)-\(format.rawValue)-\(sessions.count)") { build() }
    }

    private func picker<T: Hashable & Identifiable>(
        _ title: String, selection: Binding<T>, options: [T], label: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
            HStack(spacing: 8) {
                ForEach(options) { option in
                    let selected = option == selection.wrappedValue
                    Button { selection.wrappedValue = option } label: {
                        Text(label(option))
                            .font(Theme.font(14, .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(selected ? Theme.night : .white)
                            .background(selected ? Color.white : Color(hex: 0x2A2A33), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private func build() {
        let data = input
        let name = "Inly-\(format == .pdf ? "report" : "daily")-\(Date.now.formatted(.iso8601.year().month().day())).\(format.ext)"
        let url = FileManager.default.temporaryDirectory.appending(path: name)
        let bytes: Data
        switch format {
        case .pdf: bytes = ReportBuilder.pdf(data)
        case .daily: bytes = Data(ReportBuilder.dailyCSV(data).utf8)
        }
        do {
            try bytes.write(to: url, options: .atomic)
            fileURL = url
        } catch {
            fileURL = nil
        }
    }
}
