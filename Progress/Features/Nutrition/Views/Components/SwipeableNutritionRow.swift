//
//  SwipeableNutritionRow.swift
//  Progress
//

import SwiftUI
import UIKit

// MARK: - Swipeable Nutrition Row Component

struct SwipeableNutritionRow: View {
    let entry: NutritionEntry
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showingDetail = false

    private let revealWidth: CGFloat = 88
    private let cardCornerRadius: CGFloat = 20

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { settle(to: 0) }
            }

            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color.red)
                .opacity(offset < 0 ? 1 : 0)
                .allowsHitTesting(false)

            deleteButton
                .frame(width: revealWidth)
                .frame(maxHeight: .infinity)
                .opacity(offset < 0 ? 1 : 0)
                .allowsHitTesting(offset < 0)

            SimpleFoodEntryRow(entry: entry)
                .overlay {
                    FoodRowSwipeLayer(
                        offset: $offset,
                        revealWidth: revealWidth,
                        onTap: handleTap
                    )
                }
                .offset(x: offset)
                .allowsHitTesting(offset == 0)
        }
        // Height comes from the card, so the delete control can't grow past it.
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAction(.default) { showingDetail = true }
        .accessibilityAction(named: Text("Delete"), onDelete)
        .sheet(isPresented: $showingDetail) {
            FoodDetailView(entry: entry)
        }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            VStack(spacing: 4) {
                Image(systemName: "trash")
                Text("Delete")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete")
    }

    private func handleTap() {
        if offset != 0 {
            settle(to: 0)
        } else {
            showingDetail = true
        }
    }

    private func settle(to target: CGFloat) {
        withAnimation(.smooth(duration: 0.2)) {
            offset = target
        }
    }
}

/// Horizontal reveal that leaves vertical drags to the parent scroll view.
private struct FoodRowSwipeLayer: UIViewRepresentable {
    @Binding var offset: CGFloat
    var revealWidth: CGFloat
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $offset, revealWidth: revealWidth, onTap: onTap)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        pan.cancelsTouchesInView = true
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.offset = $offset
        context.coordinator.revealWidth = revealWidth
        context.coordinator.onTap = onTap
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var offset: Binding<CGFloat>
        var revealWidth: CGFloat
        var onTap: () -> Void
        private var dragStart: CGFloat = 0

        init(offset: Binding<CGFloat>, revealWidth: CGFloat, onTap: @escaping () -> Void) {
            self.offset = offset
            self.revealWidth = revealWidth
            self.onTap = onTap
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            let translation = pan.translation(in: pan.view)
            switch pan.state {
            case .began:
                dragStart = offset.wrappedValue
            case .changed:
                let next = dragStart + translation.x
                offset.wrappedValue = min(max(next, -revealWidth), 0)
            case .ended, .cancelled, .failed:
                let next = dragStart + translation.x
                let target: CGFloat = next < -revealWidth * 0.45 ? -revealWidth : 0
                withAnimation(.smooth(duration: 0.2)) {
                    offset.wrappedValue = target
                }
            default:
                break
            }
        }

        @objc func handleTap(_ tap: UITapGestureRecognizer) {
            guard tap.state == .ended else { return }
            onTap()
        }
    }
}
