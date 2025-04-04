import SwiftUI
import Combine

@MainActor
struct MultiTapButton<Label>: View where Label: View {

    let label: Label
    let tapOnce: () -> Void
    let tapTwice: () -> Void
    let longPress: () -> Void
    let duration: Double = 0.5 // Duration for single tap or long press
    let threshold: CGFloat = 8 // Threshold for passing gesture to superview

    init(tapOnce: @escaping () -> Void,
         tapTwice: @escaping () -> Void,
         longPress: @escaping () -> Void,
         @ViewBuilder label: () -> Label) {

        self.label = label()
        self.tapOnce = tapOnce
        self.tapTwice = tapTwice
        self.longPress = longPress
    }

    @State private var dragOffset: CGSize = .zero
    @State private var isScrolling = false
    @State private var isTriggered = false
    @State private var tapTime = TimeInterval(0)
    @State private var timer: Timer?

    var body: some View {
        label
            .contentShape(Rectangle()) // Expands tappable area to full view
            .simultaneousGesture(

                DragGesture(minimumDistance: 0)

                    .onChanged { value in // start drag
                        if isTriggered || isScrolling {
                            return
                        }

                        startTimer() // Start the combined timer

                        dragOffset = value.translation
                        // Check if threshold has been exceeded
                        if abs(value.translation.height) > threshold || abs(value.translation.width) > threshold {
                            isScrolling = true
                            cancelTimer()
                        }
                    }
                    .onEnded { _ in // end drag
                        if isTriggered || isScrolling {
                            resetState()
                            return
                        }

                        let timeNow = Date().timeIntervalSince1970
                        let deltaTime = timeNow - tapTime

                        if deltaTime < duration {
                            tapTwice()
                            isTriggered = true
                            resetState()
                        } else {
                            tapTime = timeNow
                        }
                    }
            )
            .onDisappear {
                resetState()
            }
    }

    private func startTimer() {

        if timer != nil { return }
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false)  {_ in
            Task { @MainActor in
                cancelTimer()
                
                if isScrolling { return }
                isTriggered = true
                
                if tapTime > 0 {
                    tapOnce()
                } else {
                    longPress()
                }
            }
        }
    }

    // Cancel the single tap/long press timer
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Reset state for the next gesture interaction
    private func resetState() {

        cancelTimer()
        tapTime = 0
        dragOffset = .zero
        isScrolling = false
        isTriggered = false
    }
}
