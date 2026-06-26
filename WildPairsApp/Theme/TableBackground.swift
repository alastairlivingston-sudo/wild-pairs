import SwiftUI

// Premium dark felt table surface (Phase 9 A2): deep teal/green base, a soft radial highlight
// toward the centre for depth, a subtle vignette at the edges, and a faint fabric-weave
// texture. Used behind every screen so nothing reads as a raw system-white background.
struct TableBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.Felt.base(scheme)
                RadialGradient(
                    colors: [Theme.Felt.highlight(scheme), Theme.Felt.base(scheme)],
                    center: .center, startRadius: 0, endRadius: max(geo.size.width, geo.size.height) * 0.75
                )
                FeltWeave()
                    .opacity(0.05)
                RadialGradient(
                    colors: [.clear, Theme.Felt.vignette],
                    center: .center, startRadius: max(geo.size.width, geo.size.height) * 0.45,
                    endRadius: max(geo.size.width, geo.size.height) * 0.85
                )
            }
        }
        .ignoresSafeArea()
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
