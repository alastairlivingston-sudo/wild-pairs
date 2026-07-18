import SwiftUI
import WildPairsCore

// The physical table surface behind gameplay. It remains dark-first and re-tints to the
// current element, but the layers are deliberately restrained so cards stay dominant:
// a broad centre atmosphere, a colour-blind-safe element pattern, fine material variation,
// and a protective vignette. No layer carries game state by itself.
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
                    // Static, opaque fallback: no blur, transparency animation, or particles.
                    Rectangle().fill(
                        RadialGradient(
                            colors: [Theme.Felt.baseDarkHighlight.opacity(0.78), Theme.Element.neutral.base],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius * 0.78
                        )
                    )
                } else {
                    // The table itself stays still. Gameplay motion belongs to cards, turns, and
                    // scoring; a moving background competed with those events in real play.
                    atmosphere(radius: radius)

                    ElementSurfacePattern(element: element)
                        .opacity(0.030)
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
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: element)
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
                    colors: [palette.glow.opacity(0.12), .clear],
                    center: UnitPoint(x: 0.5, y: 0.46),
                    startRadius: 0,
                    endRadius: radius * 0.50
                )
            )
            Rectangle().fill(
                LinearGradient(
                    colors: [.white.opacity(0.014), .clear, .black.opacity(0.09)],
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
