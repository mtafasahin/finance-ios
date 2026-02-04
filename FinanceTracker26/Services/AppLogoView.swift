import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            // Background circle with subtle gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Symbol: stylized line chart inside
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let path = Path { p in
                    // Create a simple rising chart line with two peaks
                    p.move(to: CGPoint(x: 0.15 * w, y: 0.70 * h))
                    p.addLine(to: CGPoint(x: 0.35 * w, y: 0.45 * h))
                    p.addLine(to: CGPoint(x: 0.52 * w, y: 0.60 * h))
                    p.addLine(to: CGPoint(x: 0.72 * w, y: 0.30 * h))
                    p.addLine(to: CGPoint(x: 0.88 * w, y: 0.40 * h))
                }

                path
                    .stroke(Color.white, style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round, lineJoin: .round))
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                // Small end-point dot to accent the chart
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.14, height: w * 0.14)
                    .position(x: 0.88 * w, y: 0.40 * h)
            }
            .padding(size * 0.18)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: size * 0.08, x: 0, y: size * 0.04)
        .accessibilityLabel("App Logo")
    }
}

#Preview("App Logo") {
    VStack(spacing: 24) {
        AppLogoView(size: 60)
        AppLogoView(size: 120)
        AppLogoView(size: 180)
    }
    .padding()
    .background(Color(.systemBackground))
}
