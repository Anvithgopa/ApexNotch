import SwiftUI
import Combine

@MainActor
public final class NotchPetManager: ObservableObject {
    public static let shared = NotchPetManager()
    
    @Published public private(set) var currentState: PetState = .sleeping
    @Published public private(set) var animationStep: Int = 0
    @Published public private(set) var currentBounce: CGFloat = 0.0
    @Published public private(set) var isExcited: Bool = false
    @Published public private(set) var speedFactor: Double = 1.0
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
        startAnimationLoop()
    }
    
    private func setupSubscriptions() {
        SystemStatsService.shared.$stats
            .receive(on: RunLoop.main)
            .sink { [weak self] stats in
                self?.updateState(cpuPercent: stats.cpuUsagePercent)
            }
            .store(in: &cancellables)
    }
    
    public func updateState(cpuPercent: Double) {
        let newState: PetState
        let factor: Double
        
        if cpuPercent < 15.0 {
            newState = .sleeping
            factor = 0.5
        } else if cpuPercent < 35.0 {
            newState = .walking
            factor = 1.0
        } else if cpuPercent < 65.0 {
            newState = .trotting
            factor = 2.0
        } else {
            newState = .sprinting
            factor = 3.8
        }
        
        if self.currentState != newState || abs(self.speedFactor - factor) > 0.1 {
            self.currentState = newState
            self.speedFactor = factor
            restartTimer()
        }
    }
    
    private func startAnimationLoop() {
        restartTimer()
    }
    
    private func restartTimer() {
        timer?.invalidate()
        let interval: Double
        switch currentState {
        case .sleeping:
            interval = 0.80
        case .walking:
            interval = 0.32
        case .trotting:
            interval = 0.18
        case .sprinting:
            interval = 0.09
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.animationStep = (self.animationStep + 1) % 4
                
                withAnimation(.easeInOut(duration: interval * 0.8)) {
                    switch self.currentState {
                    case .sleeping:
                        self.currentBounce = self.animationStep % 2 == 0 ? 0 : -1.5
                    case .walking:
                        self.currentBounce = self.animationStep % 2 == 0 ? 0 : -3.0
                    case .trotting:
                        self.currentBounce = self.animationStep % 2 == 0 ? 0 : -5.0
                    case .sprinting:
                        self.currentBounce = self.animationStep % 2 == 0 ? -1.0 : -7.0
                    }
                }
            }
        }
    }
    
    public func petTapped() {
        isExcited = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            currentBounce = -10.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.isExcited = false
        }
    }
}
