import AppKit
import Vision
import SwiftUI

@MainActor
public final class ScreenOCRService: ObservableObject {
    public static let shared = ScreenOCRService()
    
    @Published public private(set) var isCapturing = false
    @Published public private(set) var lastExtractedText: String = ""
    
    private init() {}
    
    public func captureAndExtractText() {
        guard !isCapturing else { return }
        isCapturing = true
        
        // Hide panel briefly so user can select area cleanly
        let wasExpanded = AppState.shared.isExpanded
        if wasExpanded {
            AppState.shared.collapse()
        }
        
        let tempPath = "/tmp/apex_ocr_\(UUID().uuidString).png"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            task.arguments = ["-i", "-s", tempPath]
            
            try? task.run()
            task.waitUntilExit()
            
            guard FileManager.default.fileExists(atPath: tempPath),
                  let img = NSImage(contentsOfFile: tempPath),
                  let cgImg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                Task { @MainActor in
                    self.isCapturing = false
                    if wasExpanded { AppState.shared.setExpanded(true) }
                }
                return
            }
            
            // Clean up temporary image file
            try? FileManager.default.removeItem(atPath: tempPath)
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImg, options: [:])
            try? handler.perform([request])
            
            let recognizedStrings = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            let extracted = recognizedStrings.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            
            Task { @MainActor in
                self.isCapturing = false
                if wasExpanded { AppState.shared.setExpanded(true) }
                
                if !extracted.isEmpty {
                    self.lastExtractedText = extracted
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(extracted, forType: .string)
                    
                    let words = extracted.split(separator: " ").count
                    AppState.shared.showToast("Extracted \(words) words to clipboard!")
                } else {
                    AppState.shared.showToast("No text recognized in selection")
                }
            }
        }
    }
}
