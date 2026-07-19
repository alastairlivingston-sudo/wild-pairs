import SwiftUI
import WildPairsCore

// The physical table surface behind gameplay. It remains dark-first and re-tints to the
// current element, but the layers are deliberately restrained so cards stay dominant:
// a broad centre atmosphere, a colour-blind-safe element pattern, fine material variation,
// sparse edge-biased motes, and a protective vignette. No layer carries game state by itself.
struct TableBackground: View {
    var element: CardColour? = nil

    @Environment(\.reducedVisualEffects) private var reducedVisualEffects
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: Theme.Element.ScenePalette { Theme.Element.scene(for: element) }

    var body: some View {
        GeometryReader { geo in
            let radius = max(geo.size.width, geo.size.height)

            ZStack {
                Rectangle().fill(reducedVisualEffects ? Theme.Element.neutral.base : palette.base)

                if reducedVisualEffects {
                    // Static, opaque fallback: no blur, transparency animation, or motes.
                    Rectangle().fill(
                        RadialGradient(
                            colors: [Theme.Felt.baseDarkHighlight.opacity(0.78), Theme.Element.neutral.base],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius * 0.78
                        )
                    )
                } else {
                    if reduceMotion {
                        atmosphere(radius: radius)
                    } else {
                        // A slow three-dimensional drift, capped at 12 fps. The movement is
                        // intentionally below the salience of card and turn animations.
                        TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            atmosphere(radius: radius)
                                .offset(
                                    x: sin(t / 17) * radius * 0.018,
                                    y: cos(t / 23) * radius * 0.014
                                )
                                .scaleEffect(1 + 0.018 * sin(t / 29))
                        }
                    }

                    ElementSurfacePattern(element: element)
                        .opacity(0.038)

                    // Sparse motes provide depth at the edges only. They disappear entirely
                    // under Reduce Motion rather than freezing in arbitrary positions.
                    if !reduceMotion {
                        ElementalMotes(colour: palette.glow)
                    }
                }

                // The centre stays readable while the outer thumb and status zones recede.
                Rectangle().fill(
                    RadialGradient(
                        colors: [.clear, Theme.Felt.vignette.opacity(0.88)],
                        center: .center,
                        startRadius: radius * 0.42,
                        endRadius: radius * 0.94
                    )
                )
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.55), value: element)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One broad centre wash plus two peripheral blooms. The centre wash visually binds the
    /// partner rail, opponent seats, direction orbit and piles into one table object.
    private func atmosphere(radius: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(
                RadialGradient(
                    colors: [palette.glow.opacity(0.13), .clear],
                    center: UnitPoint(x: 0.5, y: 0.48),
                    startRadius: 0,
                    endRadius: radius * 0.46
                )
            )
            Rectangle().fill(
                RadialGradient(
                    colors: [palette.auroraA.opacity(0.15), .clear],
                    center: UnitPoint(x: 0.12, y: 0.72),
                    startRadius: 0,
                    endRadius: radius * 0.52
                )
            )
            Rectangle().fill(
                RadialGradient(
                    colors: [palette.auroraB.opacity(0.11), .clear],
                    center: UnitPoint(x: 0.9, y: 0.38),
                    startRadius: 0,
                    endRadius: radius * 0.48
                )
            )
            Rectangle().fill(
                LinearGradient(
                    colors: [.white.opacity(0.018), .clear, .black.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

/// The active element is reinforced by pattern as well as colour. These are the same four
/// pattern families used on cards, but at table-surface contrast rather than card-face contrast:
/// Lava = diagonal hatch, Sky = horizontal lines, Grass = vertical lines, Sun = dot grid.
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

/// Five small, edge-biased motes rising on long, offset loops. Their job is material depth,
/// not celebration; opacity and frame rate are intentionally modest for battery and hierarchy.
private struct ElementalMotes: View {
    let colour: Color

    private static let lanes: [CGFloat] = [0.10, 0.24, 0.76, 0.90, 0.84]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                context.addFilter(.shadow(color: colour.opacity(0.45), radius: 3))

                for (index, lane) in Self.lanes.enumerated() {
                    let seed = Double(index)
                    let duration = 12.0 + seed * 1.9
                    let phase = ((t / duration) + seed * 0.31)
                        .truncatingRemainder(dividingBy: 1.0)
                    let drift = sin(t / (8.0 + seed) + seed) * 7
                    let x = size.width * lane + drift
                    let y = size.height * (1.05 - phase * 1.16)
                    let fade = min(phase / 0.16, (1.0 - phase) / 0.28, 1.0)
                    let side: CGFloat = 3.5 + CGFloat(index % 2)
                    var mote = Path(
                        roundedRect: CGRect(x: -side / 2, y: -side / 2, width: side, height: side),
                        cornerRadius: side * 0.28
                    )
                    mote = mote.applying(
                        CGAffineTransform(rotationAngle: .pi / 4 + phase * .pi * 0.5)
                            .concatenating(CGAffineTransform(translationX: x, y: y))
                    )
                    context.opacity = max(0, fade) * 0.42
                    context.fill(mote, with: .color(colour))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
