import SwiftUI
import AVFoundation
import AppKit

public struct CameraVideoPreviewRepresentable: NSViewRepresentable {
    public let session: AVCaptureSession
    public let isMirrored: Bool
    
    public init(session: AVCaptureSession, isMirrored: Bool) {
        self.session = session
        self.isMirrored = isMirrored
    }
    
    public func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView(session: session)
        view.setMirrored(isMirrored)
        return view
    }
    
    public func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.setMirrored(isMirrored)
    }
}

public final class CameraPreviewNSView: NSView {
    private let previewLayer: AVCaptureVideoPreviewLayer
    
    public init(session: AVCaptureSession) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer = previewLayer
        previewLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layout() {
        super.layout()
        previewLayer.frame = bounds
    }
    
    public func setMirrored(_ mirrored: Bool) {
        if mirrored {
            previewLayer.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0)
        } else {
            previewLayer.transform = CATransform3DIdentity
        }
    }
}

public struct CameraMirrorView: View {
    @ObservedObject private var camera = CameraManager.shared
    @ObservedObject private var perms = PermissionManager.shared
    @ObservedObject private var prefs = UserPreferences.shared
    @EnvironmentObject private var appState: AppState
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Controls header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(camera.isSessionRunning ? NotchDesign.accentGreen : NotchDesign.textTertiary)
                        .frame(width: 8, height: 8)
                    Text(camera.isSessionRunning ? "CAMERA ACTIVE" : "Camera Mirror")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(camera.isSessionRunning ? NotchDesign.accentGreen : NotchDesign.textSecondary)
                }
                
                Spacer()
                
                if perms.cameraStatus == .authorized {
                    // Mirror toggle
                    Button(action: { prefs.cameraMirrorHorizontal.toggle() }) {
                        Label(prefs.cameraMirrorHorizontal ? "Mirrored" : "Normal", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    
                    // Aspect ratio picker
                    Picker("", selection: $prefs.cameraAspectRatio) {
                        ForEach(CameraAspectRatio.allCases) { ratio in
                            Text(ratio.rawValue).tag(ratio)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 110)
                }
            }
            
            // Video preview area
            if perms.cameraStatus != .authorized {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundColor(NotchDesign.textSecondary)
                    
                    Text("Camera Access Required")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("ApexNotch uses your camera only to provide a live quick mirror directly from the notch. Frames are never recorded or transmitted.")
                        .font(.system(size: 11))
                        .foregroundColor(NotchDesign.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                    
                    Button("Grant Camera Permission") {
                        Task {
                            _ = await perms.requestCameraAccess()
                            if perms.cameraStatus == .authorized {
                                camera.startCapture()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(NotchDesign.accentCyan)
                    .foregroundColor(.black)
                    .font(.system(size: 12, weight: .semibold))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
            } else {
                ZStack {
                    CameraVideoPreviewRepresentable(
                        session: camera.captureSession,
                        isMirrored: prefs.cameraMirrorHorizontal
                    )
                    .aspectRatio(prefs.cameraAspectRatio.ratio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    
                    if !camera.isSessionRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .frame(maxHeight: 250)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NotchDesign.surfaceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
        .onAppear {
            if perms.cameraStatus == .authorized {
                camera.startCapture()
            }
        }
        .onDisappear {
            camera.stopCapture()
        }
        .onChange(of: appState.isExpanded) { _, expanded in
            if !expanded {
                camera.stopCapture()
            } else if appState.activeTab == .camera && perms.cameraStatus == .authorized {
                camera.startCapture()
            }
        }
    }
}
