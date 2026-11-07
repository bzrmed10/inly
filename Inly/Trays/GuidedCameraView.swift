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

/// Outline of a smile plus a centre line, to line the teeth up the same way every time.
private struct SmileGuide: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let mouth = CGRect(x: w * 0.09, y: h * 0.36, width: w * 0.82, height: h * 0.2)
            ZStack {
                RoundedRectangle(cornerRadius: mouth.height / 2, style: .continuous)
                    .path(in: mouth)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                Path { p in
                    p.move(to: CGPoint(x: w / 2, y: mouth.minY - 24))
                    p.addLine(to: CGPoint(x: w / 2, y: mouth.maxY + 24))
                }
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                Path { p in
                    p.move(to: CGPoint(x: mouth.minX, y: mouth.midY))
                    p.addLine(to: CGPoint(x: mouth.maxX, y: mouth.midY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 8]))
            }
            .foregroundStyle(.white.opacity(0.75))
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

    // MARK: Live

    private var liveView: some View {
        ZStack {
            CameraPreview(session: controller.session).ignoresSafeArea()
            if showGhost, let ghost {
                Image(uiImage: ghost)
                    .resizable().scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.35)
                    .allowsHitTesting(false)
            }
            SmileGuide().padding(.vertical, 60)

            if let countdown {
                Text("\(countdown)")
                    .font(Theme.font(120, .heavy)).foregroundStyle(.white)
                    .shadow(radius: 12)
                    .allowsHitTesting(false)
            }

            VStack {
                HStack {
                    circleButton("xmark", label: "Close") { onClose() }
                    Spacer()
                    if ghost != nil {
                        pill(showGhost ? "Last photo: on" : "Last photo: off", icon: "square.on.square") { showGhost.toggle() }
                    }
                }
                Text("Smile and line your teeth up with the guide")
                    .font(Theme.font(14, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.black.opacity(0.45), in: Capsule())
                    .padding(.top, 6)
                Spacer()
                HStack {
                    circleButton(useTimer ? "timer" : "timer.slash", label: useTimer ? "Timer on" : "Timer off") { useTimer.toggle() }
                    Spacer()
                    Button(action: shutter) {
                        ZStack {
                            Circle().stroke(.white, lineWidth: 4).frame(width: 78, height: 78)
                            Circle().fill(.white).frame(width: 62, height: 62)
                        }
                    }
                    .accessibilityLabel("Take photo")
                    Spacer()
                    circleButton("arrow.triangle.2.circlepath.camera", label: "Switch camera") { flip() }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
    }

    // MARK: Review

    private func reviewView(_ image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image).resizable().scaledToFill().ignoresSafeArea().allowsHitTesting(false)
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button { captured = nil } label: {
                        Text("Retake").font(Theme.font(17, .heavy)).frame(maxWidth: .infinity, minHeight: 54)
                            .background(.black.opacity(0.55), in: Capsule())
                    }
                    Button { onUse(image); onClose() } label: {
                        Text("Use photo").font(Theme.font(17, .heavy)).foregroundStyle(Theme.night)
                            .frame(maxWidth: .infinity, minHeight: 54).background(Theme.inColor, in: Capsule())
                    }
                }
                .buttonStyle(.plain).foregroundStyle(.white)
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
    }

    private var deniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill").font(.system(size: 36)).foregroundStyle(Theme.muted)
            Text("Camera access is off").font(Theme.font(20, .heavy))
            Text("Turn it on in Settings to take progress photos.")
                .font(Theme.font(15, .medium)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .font(Theme.font(16, .heavy))
            Button("Close") { onClose() }.font(Theme.font(16, .semibold)).foregroundStyle(Theme.muted)
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

    private func takePhoto() {
        controller.capture { data in
            Task { @MainActor in
                if let data, let image = UIImage(data: data) { captured = image }
            }
        }
    }
}
