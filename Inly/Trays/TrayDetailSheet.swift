import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// One tray: progress photo and notes ("sore teeth", "attachment came off").
struct TrayDetailSheet: View {
    let tray: Tray
    /// Closes the sheet from the parent (the environment's dismiss stops working after a picker was used).
    var onClose: () -> Void = {}
    @Query private var notes: [TrayNote]
    @Query(sort: \Tray.number, order: .reverse) private var allTrays: [Tray]
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var draft = ""
    @FocusState private var focused: Bool

    private let quickKeys = ["Sore teeth", "Pressure", "Tight fit", "Attachment loose", "Lisp", "All good"]
    private var quick: [String] { quickKeys.map { L10n.t($0) } }

    init(tray: Tray, onClose: @escaping () -> Void = {}) {
        self.tray = tray
        self.onClose = onClose
        let number = tray.number
        _notes = Query(filter: #Predicate<TrayNote> { $0.trayNumber == number }, sort: \.date, order: .reverse)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tray.fullLabel).font(Theme.font(32, .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                        Text(L10n.date(tray.startDate, .dateTime.month(.wide).day()))
                            .font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Button(L10n.t("Done")) { onClose(); dismiss() }.font(Theme.font(16, .heavy))
                }

                photoSection
                notesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
        .fullScreenCover(isPresented: $showCamera) {
            GuidedCameraView(
                ghost: previousPhoto,
                onUse: { image in savePhoto(Self.downsized(image)) },
                onClose: { showCamera = false }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
    }

    // MARK: Photo

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("Progress photo")).font(Theme.font(17, .heavy))
            if let data = tray.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 240)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .allowsHitTesting(false)
                    .accessibilityLabel(L10n.t("Progress photo for tray %d", tray.displayNumber))
                photoButtons(hasPhoto: true)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill").font(.title).foregroundStyle(Theme.muted)
                    Text(L10n.t("Add a photo of your teeth in this tray"))
                        .font(Theme.font(15, .bold)).foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity).frame(height: 120)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                photoButtons(hasPhoto: false)
            }
        }
    }

    private func photoButtons(hasPhoto: Bool) -> some View {
        HStack(spacing: 10) {
            if CameraPicker.isAvailable {
                Button { showCamera = true } label: {
                    Label(L10n.t("Camera"), systemImage: "camera").frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.plain)
                .background(Theme.inColor, in: Capsule())
                .foregroundStyle(Theme.night)
            }
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(L10n.t("Library"), systemImage: "photo").frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.plain)
            .background(CameraPicker.isAvailable ? Theme.raised : Theme.inColor, in: Capsule())
            .foregroundStyle(CameraPicker.isAvailable ? Color.white : Theme.night)
            if hasPhoto {
                Button(role: .destructive) { SessionService.shared.setPhoto(nil, for: tray); pickerItem = nil } label: {
                    Image(systemName: "trash").frame(width: 46, height: 46)
                }
                .buttonStyle(.plain)
                .background(Theme.raised, in: Circle())
                .accessibilityLabel(L10n.t("Remove photo"))
            }
        }
        .font(Theme.font(15, .heavy))
    }

    /// Photo from the closest earlier tray, used as the faint guide in the camera.
    private var previousPhoto: UIImage? {
        allTrays.first { $0.number < tray.number && $0.photoData != nil }
            .flatMap { $0.photoData }
            .flatMap { UIImage(data: $0) }
    }

    private func savePhoto(_ data: Data?) {
        guard let data else { return }
        SessionService.shared.setPhoto(data, for: tray)
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let raw = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: raw) else { return }
        savePhoto(Self.downsized(image))
    }

    /// Keeps photos small (max 1600 px, JPEG) so the database stays light.
    static func downsized(_ image: UIImage, maxSide: CGFloat = 1600) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / max(1, longest))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.jpegData(compressionQuality: 0.8)
    }

    // MARK: Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("Notes")).font(Theme.font(17, .heavy))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quick, id: \.self) { text in
                        Button { SessionService.shared.addNote(trayNumber: tray.number, text: text) } label: {
                            Text(text).font(Theme.font(14, .heavy))
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(Theme.raised, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 10) {
                TextField(L10n.t("Write a note"), text: $draft, axis: .vertical)
                    .focused($focused)
                    .font(Theme.font(16, .semibold))
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                Button { addDraft() } label: {
                    Image(systemName: "arrow.up").font(.headline.weight(.heavy))
                        .frame(width: 44, height: 44)
                        .background(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.raised : Theme.inColor, in: Circle())
                        .foregroundStyle(Theme.night)
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel(L10n.t("Add note"))
            }

            if notes.isEmpty {
                Text(L10n.t("No notes yet. Tap a suggestion above or write your own."))
                    .font(Theme.font(14, .medium)).foregroundStyle(Theme.muted)
            } else {
                VStack(spacing: 8) {
                    ForEach(notes) { note in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(note.text).font(Theme.font(16, .bold))
                                Text(L10n.date(note.date, .dateTime.month(.abbreviated).day().hour().minute()))
                                    .font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted)
                            }
                            Spacer(minLength: 8)
                            Button { SessionService.shared.deleteNote(note) } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted).font(.title3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.t("Delete note"))
                        }
                        .padding(14)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
    }

    private func addDraft() {
        SessionService.shared.addNote(trayNumber: tray.number, text: draft)
        draft = ""
        focused = false
    }
}
