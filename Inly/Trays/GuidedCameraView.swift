import SwiftUI
@preconcurrency import AVFoundation
import UIKit

/// Wraps an AVCaptureSession. All session work happens on one private queue.
final class CameraController: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "com.bzrmed.inly.camera")
    private var position: AVCaptureDevice.Position = .front
    private var completion: (@Sendable (Data?) -> Void)?

    func configure(position: AVCaptureDevice.Position) {
        queue.async { [self] in
            self.position = position
            session.beginConfiguration()
            session.sessionPreset = .photo
            for input in session.inputs { session.removeInput(input) }
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
               let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
                session.addInput(input)
            }
            if !session.outputs.contains(output), session.canAddOutput(output) { session.addOutput(output) }
            session.commitConfiguration()
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        queue.async { [self] in if session.isRunning { session.stopRunning() } }
    }

    func capture(_ done: @escaping @Sendable (Data?) -> Void) {
        queue.async { [self] in
            completion = done
            if let connection = output.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    // Save the photo the way the preview shows it, so it lines up with the ghost of the last photo.
                    connection.isVideoMirrored = (position == .front)
                }
            }
            output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        queue.async { [self] in
            let done = completion
            completion = nil
            done?(data)
        }
    }
}

private final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Mouth outline, centre line and bite line, drawn inside the photo frame.
private struct SmileGuide: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let mouth = CGRect(x: w * 0.1, y: h * 0.27, width: w * 0.8, height: h * 0.46)
            ZStack {
                RoundedRectangle(cornerRadius: mouth.height / 2, style: .continuous)
                    .path(in: mouth)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                Path { p in
                    p.move(to: CGPoint(x: w / 2, y: h * 0.12))
                    p.addLine(to: CGPoint(x: w / 2, y: h * 0.88))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                Path { p in
                    p.move(to: CGPoint(x: mouth.minX, y: mouth.midY))
                    p.addLine(to: CGPoint(x: mouth.maxX, y: mouth.midY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 8]))
            }
            .foregroundStyle(.white.opacity(0.8))
        }
        .allowsHitTesting(false)
    }
}

/// Camera for progress photos: a guide to frame your teeth, a faint ghost of your last photo, and a self-timer.
struct GuidedCameraView: View {
    /// The previous tray's photo, shown faintly so the new one lines up with it.
    var ghost: UIImage?
    var onUse: (UIImage) -> Void
    var onClose: () -> Void

    @State private var controller = CameraController()
    @State private var position: AVCaptureDevice.Position = .front
    @State private var denied = false
    @State private var showGhost = true
    @State private var useTimer = true
    @State private var countdown: Int?
    @State private var captured: UIImage?
    @State private var countdownTask: Task<Void, Never>?
    @State private var screen: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if denied {
                deniedView
            } else if let captured {
                reviewView(captured)
            } else {
                liveView
            }
        }
        .preferredColorScheme(.dark)
        .task { await start() }
        .onDisappear {
            countdownTask?.cancel()
            controller.stop()
        }
    }

    // MARK: Frame

    /// The photo frame in full-screen coordinates. Only what is inside it is saved.
    private func frame(in size: CGSize) -> CGRect {
        let w = max(1, size.width - 32)
        let h = w * 0.75
        return CGRect(x: 16, y: size.height * 0.40 - h / 2, width: w, height: h)
    }

    // MARK: Live

    private var liveView: some View {
        ZStack {
            // Visual layer: full screen, never takes touches.
            GeometryReader { geo in
                let cut = frame(in: geo.size)
                ZStack {
                    CameraPreview(session: controller.session)
                    Path { p in
                        p.addRect(CGRect(origin: .zero, size: geo.size))
                        p.addRoundedRect(in: cut, cornerSize: CGSize(width: 22, height: 22))
                    }
                    .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))
                    if showGhost, let ghost {
                        Image(uiImage: ghost).resizable().scaledToFill()
                            .frame(width: cut.width, height: cut.height).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .opacity(0.35)
                            .position(x: cut.midX, y: cut.midY)
                    }
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.9), lineWidth: 2)
                        .frame(width: cut.width, height: cut.height)
                        .position(x: cut.midX, y: cut.midY)
                    SmileGuide()
                        .frame(width: cut.width, height: cut.height)
                        .position(x: cut.midX, y: cut.midY)
                    if let countdown {
                        Text("\(countdown)")
                            .font(Theme.font(120, .heavy)).foregroundStyle(.white)
                            .shadow(radius: 12)
                            .position(x: cut.midX, y: cut.midY)
                    }
                }
                .onAppear { screen = geo.size }
                .onChange(of: geo.size) { _, new in screen = new }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Controls layer: respects the safe areas.
            VStack(spacing: 10) {
                HStack {
                    circleButton("xmark", label: L10n.t("Close")) { onClose() }
                    Spacer()
                    if ghost != nil {
                        pill(showGhost ? L10n.t("Last photo: on") : L10n.t("Last photo: off"), icon: "square.on.square") { showGhost.toggle() }
                    }
                }
                Text(L10n.t("Smile and line your teeth up with the guide"))
                    .font(Theme.font(14, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.black.opacity(0.45), in: Capsule())
                Spacer()
                HStack {
                    circleButton(useTimer ? "timer" : "timer.slash", label: useTimer ? L10n.t("Timer on") : L10n.t("Timer off")) { useTimer.toggle() }
                    Spacer()
                    Button(action: shutter) {
                        ZStack {
                            Circle().stroke(.white, lineWidth: 4).frame(width: 78, height: 78)
                            Circle().fill(.white).frame(width: 62, height: 62)
                        }
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.t("Take photo"))
                    Spacer()
                    circleButton("arrow.triangle.2.circlepath.camera", label: L10n.t("Switch camera") { flip() }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
    }

    // MARK: Review

    private func reviewView(_ image: UIImage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: max(1, screen.width - 32), height: max(1, screen.width - 32) * 0.75)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .allowsHitTesting(false)
            Spacer()
            HStack(spacing: 12) {
                Button { captured = nil } label: {
                    Text(L10n.t("Retake")).font(Theme.font(17, .heavy)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Theme.raised, in: Capsule())
                        .contentShape(Capsule())
                }
                Button { onUse(image); onClose() } label: {
                    Text(L10n.t("Use photo")).font(Theme.font(17, .heavy)).foregroundStyle(Theme.night)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Theme.inColor, in: Capsule())
                        .contentShape(Capsule())
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20).padding(.bottom, 12)
        }
    }

    private var deniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill").font(.system(size: 36)).foregroundStyle(Theme.muted)
            Text(L10n.t("Camera access is off")).font(Theme.font(20, .heavy))
            Text(L10n.t("Turn it on in Settings to take progress photos."))
                .font(Theme.font(15, .medium)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Button(L10n.t("Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .font(Theme.font(16, .heavy))
            Button(L10n.t("Close")) { onClose() }.font(Theme.font(16, .semibold)).foregroundStyle(Theme.muted)
        }
        .padding(30)
    }

    // MARK: Pieces

    private func circleButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18, weight: .bold))
                .frame(width: 48, height: 48).background(.black.opacity(0.45), in: Circle())
        }
        .buttonStyle(.plain).foregroundStyle(.white)
        .accessibilityLabel(label)
    }

    private func pill(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(Theme.font(13, .heavy))
                .padding(.horizontal, 14).frame(height: 40).background(.black.opacity(0.45), in: Capsule())
        }
        .buttonStyle(.plain).foregroundStyle(.white)
    }

    // MARK: Actions

    private func start() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        var allowed = status == .authorized
        if status == .notDetermined { allowed = await AVCaptureDevice.requestAccess(for: .video) }
        guard allowed else { denied = true; return }
        controller.configure(position: position)
    }

    private func flip() {
        position = position == .front ? .back : .front
        controller.configure(position: position)
    }

    private func shutter() {
        guard countdown == nil else { return }
        guard useTimer else { takePhoto(); return }
        countdownTask?.cancel()
        countdownTask = Task {
            for n in stride(from: 3, through: 1, by: -1) {
                countdown = n
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { countdown = nil; return }
            }
            countdown = nil
            takePhoto()
        }
    }

    /// Cuts out exactly what the frame showed. The preview fills the screen, so the same scale and offset map frame to photo pixels.
    static func crop(_ image: UIImage, to frame: CGRect, screen: CGSize) -> UIImage {
        guard screen.width > 0, screen.height > 0 else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let upright = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in image.draw(at: .zero) }
        guard let cg = upright.cgImage else { return image }
        let iw = CGFloat(cg.width), ih = CGFloat(cg.height)
        let scale = max(screen.width / iw, screen.height / ih)
        let offX = (screen.width - iw * scale) / 2
        let offY = (screen.height - ih * scale) / 2
        let rect = CGRect(
            x: (frame.minX - offX) / scale, y: (frame.minY - offY) / scale,
            width: frame.width / scale, height: frame.height / scale
        ).intersection(CGRect(x: 0, y: 0, width: iw, height: ih)).integral
        guard rect.width > 1, rect.height > 1, let cropped = cg.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped)
    }

    private func takePhoto() {
        let screen = self.screen
        controller.capture { data in
            Task { @MainActor in
                guard let data, let image = UIImage(data: data) else { return }
                captured = Self.crop(image, to: frame(in: screen), screen: screen)
            }
        }
    }
}
