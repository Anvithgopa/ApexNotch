import Foundation
import AVFoundation
import AppKit

@MainActor
public final class CameraManager: NSObject, ObservableObject {
    public static let shared = CameraManager()
    
    @Published public private(set) var isSessionRunning: Bool = false
    @Published public private(set) var availableDevices: [AVCaptureDevice] = []
    @Published public var selectedDevice: AVCaptureDevice?
    
    public let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.apexnotch.camera.session")
    private var currentInput: AVCaptureDeviceInput?
    
    override private init() {
        super.init()
        discoverDevices()
    }
    
    public func discoverDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        self.availableDevices = discovery.devices
        if selectedDevice == nil {
            self.selectedDevice = discovery.devices.first
        }
    }
    
    public func startCapture() {
        guard PermissionManager.shared.cameraStatus == .authorized else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.captureSession.isRunning else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high
            
            if let input = self.currentInput {
                self.captureSession.removeInput(input)
            }
            
            if let device = self.selectedDevice,
               let input = try? AVCaptureDeviceInput(device: device),
               self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.currentInput = input
            }
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            
            Task { @MainActor [weak self] in
                self?.isSessionRunning = true
            }
        }
    }
    
    public func stopCapture() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            Task { @MainActor [weak self] in
                self?.isSessionRunning = false
            }
        }
    }
    
    public func switchDevice(to device: AVCaptureDevice) {
        self.selectedDevice = device
        if isSessionRunning {
            stopCapture()
            startCapture()
        }
    }
}
