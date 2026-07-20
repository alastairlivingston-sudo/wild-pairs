import Foundation
import SwiftUI
import WildPairsCore

// The table surface keeps cards dominant while reinforcing the active element through a dark
// base, a broad colour field, and the same colour-blind pattern family used on card faces.
struct TableBackground: View {
    var element: CardColour? = nil
    var turnDirection: TurnDirection? = nil
    var directionAnimationDisabled = false
    var style: TableBackgroundStyle? = nil
    /// Table position of the acting seat (0 bottom, 1 left, 2 top, 3 right), so the ambient
    /// rings can say *whose* turn it is as well as which way play travels.
    var activeTablePosition: Int? = nil

    @Environment(\.reducedVisualEffects) private var reducedVisualEffects
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: Theme.Element.ScenePalette { Theme.Element.scene(for: element) }
    private var resolvedStyle: TableBackgroundStyle { style ?? .felt }
    private var motionDisabled: Bool {
        directionAnimationDisabled || reducedVisualEffects || reduceMotion
    }

    var body: some View {
        GeometryReader { geo in
            let radius = max(geo.size.width, geo.size.height)

            ZStack {
                Rectangle().fill(palette.base)

                styleTexture(radius: radius)
                elementField(radius: radius)

                ElementSurfacePattern(element: element)
                    .opacity(patternOpacity)

                if let turnDirection {
                    DirectionalTablePulse(
                        direction: turnDirection,
                        accent: palette.glow,
                        motionDisabled: motionDisabled,
                        activeTablePosition: activeTablePosition
                    )
                }

                Rectangle().fill(
                    RadialGradient(
                        colors: [.clear, Theme.Felt.vignette.opacity(0.82)],
                        center: .center,
                        startRadius: radius * 0.44,
                        endRadius: radius * 0.96
                    )
                )
            }
            .animation(motionDisabled ? nil : .easeInOut(duration: 0.45), value: element)
            .animation(motionDisabled ? nil : .easeInOut(duration: 0.25), value: resolvedStyle)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var patternOpacity: Double {
        guard element != nil else { return 0.025 }
        return reducedVisualEffects ? 0.052 : 0.072
    }

    @ViewBuilder private func styleTexture(radius: CGFloat) -> some View {
        switch resolvedStyle {
        case .felt:
            Rectangle().fill(
                LinearGradient(
                    colors: [
                        .white.opacity(reducedVisualEffects ? 0.008 : 0.018),
                        .clear,
                        .black.opacity(0.11)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .aurora:
            ZStack {
                Rectangle().fill(
                    RadialGradient(
                        colors: [palette.auroraA.opacity(reducedVisualEffects ? 0.10 : 0.23), .clear],
                        center: UnitPoint(x: 0.10, y: 0.04),
                        startRadius: 0,
                        endRadius: radius * 0.72
                    )
                )
                Rectangle().fill(
                    RadialGradient(
                        colors: [palette.auroraB.opacity(reducedVisualEffects ? 0.08 : 0.18), .clear],
                        center: UnitPoint(x: 0.92, y: 0.90),
                        startRadius: 0,
                        endRadius: radius * 0.68
                    )
                )
            }
        case .contours:
            ContourSurfacePattern()
                .opacity(reducedVisualEffects ? 0.040 : 0.070)
        }
    }

    private func elementField(radius: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(
                RadialGradient(
                    colors: [
                        palette.glow.opacity(reducedVisualEffects ? 0.14 : 0.23),
                        palette.auroraA.opacity(reducedVisualEffects ? 0.04 : 0.09),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.46),
                    startRadius: 0,
                    endRadius: radius * 0.62
                )
            )
            Rectangle().fill(
                LinearGradient(
                    colors: [
                        palette.auroraA.opacity(reducedVisualEffects ? 0.035 : 0.075),
                        .clear,
                        palette.auroraB.opacity(reducedVisualEffects ? 0.030 : 0.065)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

private struct DirectionalTablePulse: View {
    let direction: TurnDirection
    let accent: Color
    let motionDisabled: Bool
    var activeTablePosition: Int? = nil

    /// Concentric ring scales. Depth comes from tone, not from stroke weight or count.
    private static let ringScales: [CGFloat] = [1.0, 0.87, 0.74, 0.61]

    /// Degrees clockwise from 12 o'clock for each table position.
    private func seatAngle(_ position: Int) -> Double {
        switch position {
        case 0: return 180   // bottom — the local player
        case 1: return 270   // left
        case 2: return 0     // top — partner
        case 3: return 90    // right
        default: return 0
        }
    }

    /// `pulseArc` is trimmed 0.02-0.23, so its midpoint already sits ~45 degrees round.
    private var anchorRotation: Double? {
        activeTablePosition.map { seatAngle($0) - 45 }
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let width = geo.size.width * (isLandscape ? 0.94 : 1.08)
            let height = geo.size.height * (isLandscape ? 0.72 : 0.62)
            let lineWidth = max(2, min(4, min(geo.size.width, geo.size.height) * 0.006))

            ZStack {
                ForEach(Array(Self.ringScales.enumerated()), id: \.offset) { index, scale in
                    Ellipse()
                        .stroke(
                            accent.opacity(0.055 - Double(index) * 0.010),
                            style: StrokeStyle(lineWidth: 1, dash: [2, 13])
                        )
                        .scaleEffect(scale)
                }

                if motionDisabled {
                    // Still frame must keep BOTH cues: the arc sits on the acting seat, and the
                    // lean shows which way play is travelling.
                    pulseArc(lineWidth: lineWidth)
                        .rotationEffect(.degrees(
                            (anchorRotation ?? 0) + (direction == .clockwise ? 18 : -18)
                        ))
                        .opacity(0.13)
                } else {
                    TimelineView(.periodic(from: .now, by: 1.0 / 15.0)) { context in
                        let elapsed = context.date.timeIntervalSinceReferenceDate
                        let orbit = elapsed.truncatingRemainder(dividingBy: 14) / 14
                        let sign = direction == .clockwise ? 1.0 : -1.0
                        let pulse = (sin(elapsed * .pi / 2) + 1) / 2

                        // With a known seat the arc rests on it and drifts the way play moves;
                        // without one it falls back to a free orbit.
                        let rotation = anchorRotation.map { $0 + sign * (orbit * 2 - 1) * 22 }
                            ?? (orbit * 360 * sign)

                        pulseArc(lineWidth: lineWidth)
                            .rotationEffect(.degrees(rotation))
                            .opacity(0.10 + pulse * 0.08)
                    }
                    .animation(.easeInOut(duration: 0.6), value: activeTablePosition)
                }
            }
            .frame(width: width, height: height)
            .position(x: geo.size.width / 2, y: geo.size.height * 0.50)
        }
    }

    private func pulseArc(lineWidth: CGFloat) -> some View {
        Ellipse()
            .trim(from: 0.02, to: 0.23)
            .stroke(
                accent,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
    }
}

private struct ContourSurfacePattern: View {
    var body: some View {
        Canvas { context, size in
            let step = min(size.width, size.height) * 0.052

            for index in 0..<11 {
                let inset = CGFloat(index) * step
                let rect = CGRect(
                    x: size.width * 0.06 + inset * 0.34,
                    y: size.height * 0.04 + inset,
                    width: size.width * 0.88 - inset * 0.68,
                    height: size.height * 0.92 - inset * 2
                )
                guard rect.width > 10, rect.height > 10 else { break }
                let path = Path(
                    roundedRect: rect,
                    cornerRadius: min(rect.width, rect.height) * 0.34
                )
                context.stroke(path, with: .color(.white), lineWidth: 0.8)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// The active element is reinforced by pattern as well as colour:
// Lava = diagonal hatch, Sky = horizontal lines, Grass = vertical lines, Sun = dot grid.
private struct ElementSurfacePattern: View {
    let element: CardColour?

    var body: some View {
        Canvas { context, size in
            switch element {
            case .crimson:
                drawDiagonal(context: context, size: size)
            case .cobalt:
                drawHorizontal(context: context, size: size)
            case .jade:
                drawVertical(context: context, size: size)
            case .amber:
                drawDots(context: context, size: size)
            case nil:
                drawNeutralWeave(context: context, size: size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawDiagonal(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 22
        var offset: CGFloat = -size.height
        while offset < size.width {
            var path = Path()
            path.move(to: CGPoint(x: offset, y: size.height))
            path.addLine(to: CGPoint(x: offset + size.height, y: 0))
            context.stroke(path, with: .color(.white), lineWidth: 1)
            offset += spacing
        }
    }

    private func drawHorizontal(context: GraphicsContext, size: CGSize) {
        var y: CGFloat = 9
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.white), lineWidth: 1)
            y += 20
        }
    }

    private func drawVertical(context: GraphicsContext, size: CGSize) {
        var x: CGFloat = 10
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(.white), lineWidth: 1)
            x += 20
        }
    }

    private func drawDots(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 22
        var y: CGFloat = spacing * 0.5
        while y < size.height {
            var x: CGFloat = spacing * 0.5
            while x < size.width {
                context.fill(
                    Path(ellipseIn: CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4)),
                    with: .color(.white)
                )
                x += spacing
            }
            y += spacing
        }
    }

    private func drawNeutralWeave(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 28
        var offset: CGFloat = -size.height
        while offset < size.width {
            var path = Path()
            path.move(to: CGPoint(x: offset, y: size.height))
            path.addLine(to: CGPoint(x: offset + size.height, y: 0))
            context.stroke(path, with: .color(.white), lineWidth: 0.8)
            offset += spacing
        }
    }
}

extension TableBackgroundStyle {
    var displayName: String {
        switch self {
        case .felt: return "Felt"
        case .aurora: return "Aurora"
        case .contours: return "Contours"
        }
    }

    var detail: String {
        switch self {
        case .felt: return "A restrained material surface with a focused centre glow."
        case .aurora: return "Layered edge light that carries more of the active element colour."
        case .contours: return "Quiet contour lines that keep the table structured and low-noise."
        }
    }
}

extension AITurnPace {
    var displayName: String {
        switch self {
        case .brisk: return "Brisk"
        case .steady: return "Steady"
        case .relaxed: return "Relaxed"
        case .slow: return "Slow"
        }
    }

    /// Range across Easy…Master, so the pace reads as real time rather than a vague label.
    var detail: String {
        switch self {
        case .brisk: return "About 0.6–1.1 seconds per AI turn."
        case .steady: return "About 1.1–2.0 seconds per AI turn."
        case .relaxed: return "About 1.9–3.4 seconds per AI turn."
        case .slow: return "About 2.9–5.2 seconds per AI turn — most time to read each card."
        }
    }
}
