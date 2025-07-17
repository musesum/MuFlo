import SwiftUI
import Combine

@MainActor
struct MultiTapButton<Label>: View where Label: View {

    let label: Label
    let tapOnce: () -> Void
    let tapTwice: () -> Void
    let longPress: () -> Void
    let duration: Double = 0.25 // Duration for single tap or long press
    let threshold: CGFloat = 20 // Threshold for passing gesture to superview

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
    @State private var lastTapTime = TimeInterval(0)
    @State private var longPressWorkItem: DispatchWorkItem?
    @State private var singleTapWorkItem: DispatchWorkItem?
    @State private var touchStartTime = TimeInterval(0)

    var body: some View {
        label
            .contentShape(Rectangle()) // Expands tappable area to full view
            .simultaneousGesture(

                DragGesture(minimumDistance: 0)

                    .onChanged { value in // start drag
                        if isTriggered || isScrolling {
                            return
                        }

                        // Record touch start time for long press detection
                        if touchStartTime == 0 {
                            touchStartTime = Date().timeIntervalSince1970
                            startLongPressTimer()
                        }

                        dragOffset = value.translation
                        // Check if threshold has been exceeded
                        if abs(value.translation.height) > threshold || abs(value.translation.width) > threshold {
                            isScrolling = true
                            cancelTimers()
                        }
                    }
                    .onEnded { _ in // end drag
                        cancelLongPressTimer()

                        if isTriggered || isScrolling {
                            resetState()
                            return
                        }

                        let timeNow = Date().timeIntervalSince1970
                        let timeSinceLastTap = timeNow - lastTapTime

                        // Check for double tap
                        if timeSinceLastTap < duration {
                            cancelSingleTapTimer()
                            tapTwice()
                            isTriggered = true
                            resetState()
                        } else {
                            // Schedule single tap with delay to wait for potential double tap
                            lastTapTime = timeNow
                            startSingleTapTimer()
                        }

                        touchStartTime = 0
                    }
            )
            .onDisappear {
                resetState()
            }
    }

    private func startLongPressTimer() {
        let workItem = DispatchWorkItem {
            if !isScrolling && !isTriggered {
                isTriggered = true
                longPress()
                cancelSingleTapTimer()
            }
        }
        longPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func startSingleTapTimer() {
        let workItem = DispatchWorkItem {
            if !isScrolling && !isTriggered {
                isTriggered = true
                tapOnce()
            }
        }
        singleTapWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
    
    private func cancelLongPressTimer() {
        longPressWorkItem?.cancel()
        longPressWorkItem = nil
    }

    private func cancelSingleTapTimer() {
        singleTapWorkItem?.cancel()
        singleTapWorkItem = nil
    }

    private func cancelTimers() {
        cancelLongPressTimer()
        cancelSingleTapTimer()
    }

    // Reset state for the next gesture interaction
    private func resetState() {
        cancelTimers()
        lastTapTime = 0
        touchStartTime = 0
        dragOffset = .zero
        isScrolling = false
        isTriggered = false
    }
}
