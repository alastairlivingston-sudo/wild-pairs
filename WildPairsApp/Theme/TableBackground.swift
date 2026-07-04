import SwiftUI
import WildPairsCore

// Elemental Live scene (Phase 12, design-plan.md §2/§3.1): a deep elemental base, two aurora
// blobs plus a floor glow, a faint fabric weave, drifting motes in the element's glow colour,
// and an edge vignette. The game table passes the active colour so the whole scene re-tints
// as play changes colour; menus pass nothing and get the neutral indigo/teal scene.
// Reduced Visual Effects renders one static neutral gradient; Reduce Motion keeps the tint
// crossfade off and drops the motes.
struct TableBackground: View {
    var element: CardColour? = nil

    @Environment(\.reducedVisualEffects) private var reducedVisualEffects
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: Theme.Element.ScenePalette { Theme.Element.scene(for: element) }

    var body: some View {
        GeometryReader { geo in
            let radius = max(geo.size.width, geo.size.height)
            ZStack {
                if reducedVisualEffects {
                    Rectangle().fill(Theme.Element.neutral.base)
                    Rectangle().fill(
                        RadialGradient(colors: [Theme.Felt.baseDarkHighlight, Theme.Element.neutral.base],
                                       center: .center, startRadius: 0, endRadius: radius * 0.75))
                } else {
                    Rectangle().fill(palette.base)
                    if reduceMotion {
                        aurora(radius: radius)
                    } else {
                        // Slow breathing drift so the environment reads as alive without
                        // competing with the cards ("subtle, not needy").
                        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            aurora(radius: radius)
                                .offset(x: sin(t / 13) * radius * 0.03,
                                        y: cos(t / 17) * radius * 0.025)
                                .scaleEffect(1 + 0.04 * sin(t / 21))
                        }
                    }
                    FeltWeave().opacity(0.04)
                    if !reduceMotion {
                        ElementalMotes(colour: palette.glow)
                    }
                }
                Rectangle().fill(
                    RadialGradient(colors: [.clear, Theme.Felt.vignette],
                                   center: .center, startRadius: radius * 0.45, endRadius: radius * 0.85))
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: element)
        }
        .ignoresSafeArea()
    }

    /// Two off-centre aurora blobs plus a floor glow, per prototype 04. Gradient stop counts
    /// are identical across palettes so the colour-change crossfade interpolates smoothly.
    private func aurora(radius: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(
                RadialGradient(colors: [palette.auroraA.opacity(0.22), .clear],
                               center: UnitPoint(x: 0.18, y: 0.72), startRadius: 0, endRadius: radius * 0.55))
            Rectangle().fill(
                RadialGradient(colors: [palette.auroraB.opacity(0.16), .clear],
                               center: UnitPoint(x: 0.85, y: 0.5), startRadius: 0, endRadius: radius * 0.5))
            Rectangle().fill(
                RadialGradient(colors: [palette.auroraA.opacity(0.2), .clear],
                               center: UnitPoint(x: 0.5, y: 1.12), startRadius: 0, endRadius: radius * 0.6))
        }
    }
}

/// A faint repeating diagonal weave to break up the flat gradient without affecting contrast.
private struct FeltWeave: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 18
            var offset: CGFloat = -size.height
            while offset < size.width {
                var path = Path()
                path.move(to: CGPoint(x: offset, y: size.height))
                path.addLine(to: CGPoint(x: offset + size.height, y: 0))
                context.stroke(path, with: .color(.white), lineWidth: 1)
                offset += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

/// Drifting elemental sparks (design-plan.md §2.3): seven rotated squares rising bottom→top
/// on staggered 8–13s loops. Stateless — every position derives from the timeline clock, so
/// each frame is a single seven-rect Canvas pass.
private struct ElementalMotes: View {
    let colour: Color

    private static let lanes: [CGFloat] = [0.14, 0.32, 0.58, 0.74, 0.88, 0.46, 0.22]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                context.addFilter(.shadow(color: colour.opacity(0.8), radius: 5))
                for (i, lane) in Self.lanes.enumerated() {
                    let seed = Double(i)
                    let duration = 8.0 + (seed * 1.7).truncatingRemainder(dividingBy: 5.0)
                    let phase = ((t / duration) + seed * 0.37).truncatingRemainder(dividingBy: 1.0)
                    let x = size.width * lane
                    let y = size.height * (1.02 - phase * 1.1)
                    let fade = min(phase / 0.12, (1.0 - phase) / 0.25, 1.0)
                    let side: CGFloat = 5 + CGFloat(i % 2)
                    var mote = Path(roundedRect: CGRect(x: -side / 2, y: -side / 2, width: side, height: side),
                                    cornerRadius: side * 0.3)
                    mote = mote.applying(
                        CGAffineTransform(rotationAngle: .pi / 4 + phase * .pi)
                            .concatenating(CGAffineTransform(translationX: x, y: y)))
                    context.opacity = max(0, fade) * 0.75
                    context.fill(mote, with: .color(colour))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
