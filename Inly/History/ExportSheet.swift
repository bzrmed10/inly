import SwiftData
import PDFKit
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
    @State private var previewing = false

    /// First page of the PDF, for the preview card.
    static func thumbnail(_ url: URL) -> UIImage? {
        PDFDocument(url: url)?.page(at: 0)?.thumbnail(of: CGSize(width: 240, height: 320), for: .mediaBox)
    }
    @State private var settings = WearSettings.load()
    @State private var includePhotos = false

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
            trays: trays.map { .init(number: $0.number, start: $0.startDate, end: $0.endDate, plannedDays: $0.plannedDays, phase: $0.phase, shownNumber: $0.displayNumber, photo: includePhotos ? $0.photoData : nil) },
            notes: notes.map { n in .init(trayNumber: n.trayNumber, date: n.date, text: n.text, label: trays.first(where: { $0.number == n.trayNumber })?.fullLabel) },
            appointment: settings.nextAppointment,
            phaseTotals: settings.phaseTotals,
            retainerSince: settings.retainerMode ? settings.retainerStart : nil,
            includePhotos: includePhotos
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.t("Share with your orthodontist")).font(Theme.font(26, .heavy))
            Text(L10n.t("Wear time, trays and notes in one file you can send by email or message."))
                .font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)

            picker(L10n.t("Period"), selection: $range, options: Period.allCases) { $0.title }
            picker(L10n.t("Format"), selection: $format, options: Format.allCases) { $0.title }

            if format == .pdf, trays.contains(where: { $0.photoData != nil }) {
                Toggle(isOn: $includePhotos) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.t("Include progress photos")).font(Theme.font(16, .heavy))
                        Text(L10n.t("Makes the file larger."))
                            .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.trayColor)
                .padding(14)
                .background(Theme.track, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            if format == .pdf, let fileURL, let thumb = Self.thumbnail(fileURL) {
                Button { previewing = true } label: {
                    HStack(spacing: 14) {
                        Image(uiImage: thumb).resizable().scaledToFit().frame(height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 6)).shadow(radius: 4)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.t("Preview report")).font(Theme.font(16, .heavy)).foregroundStyle(Theme.text)
                            Text(L10n.t("See it before you send it.")).font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.forward").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted)
                    }
                    .padding(12)
                    .background(Theme.track, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reportPreview")
                .sheet(isPresented: $previewing) { PDFPreview(url: fileURL) }
            }

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
                .font(Theme.font(16, .heavy)).foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.sheet)
        .presentationCornerRadius(34)
        .onAppear { settings = WearSettings.load() }
        .task(id: "\(range.rawValue)-\(format.rawValue)-\(sessions.count)-\(includePhotos)") { build() }
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
                            .foregroundStyle(selected ? Theme.night : Theme.text)
                            .background(selected ? Theme.text : Theme.track, in: Capsule())
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

/// Full-screen view of the exported PDF.
private struct PDFPreview: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(L10n.t("Preview report"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.t("Done")) { dismiss() }
                    }
                }
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = .secondarySystemBackground
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}
