import SwiftUI

/// The WorkoutTracker logo, "Climbing W": a W whose last stroke stands free and climbs higher,
/// the next rep, the next session.
///
/// Drawn from the same geometry as `Branding/workouttracker-logo` (source-kit.py), so it is sharp
/// at any size and needs no image asset.
struct WorkoutMark: View {
    /// Colour of the W. The climbing stroke is always green unless `climb` is set.
    var w: Color = .primary
    var climb: Color = WorkoutMarkGeometry.green

    var body: some View {
        Canvas { context, size in
            let mark = WorkoutMarkGeometry(in: CGRect(origin: .zero, size: size))
            let style = StrokeStyle(lineWidth: mark.strokeWidth, lineCap: .round, lineJoin: .round)
            context.stroke(mark.w, with: .color(w), style: style)
            context.stroke(mark.climb, with: .color(climb), style: style)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// The logo's construction on a 256-unit canvas, fitted as a centred square into a frame.
struct WorkoutMarkGeometry {
    static let navy = Color(red: 0.039, green: 0.157, blue: 0.314)   // #0A2850
    static let green = Color(red: 0.196, green: 0.831, blue: 0.420)  // #32D46B

    private static let canvas: CGFloat = 256
    private static let unitStroke: CGFloat = 36
    /// The W, already optically centred on the canvas.
    private static let wPoints: [CGPoint] = [
        CGPoint(x: 39, y: 96), CGPoint(x: 81, y: 208), CGPoint(x: 123, y: 124), CGPoint(x: 165, y: 208),
    ]
    /// The climbing stroke leaves the W's last foot at 75° and starts this far along it.
    private static let climbAngle: CGFloat = 75
    private static let climbGap: CGFloat = 84
    private static let climbTopY: CGFloat = 44

    let w: Path
    let climb: Path
    let climbStart: CGPoint
    let climbEnd: CGPoint
    let strokeWidth: CGFloat

    init(in rect: CGRect) {
        let side = min(rect.width, rect.height)
        let scale = side / Self.canvas
        let transform = CGAffineTransform(translationX: rect.midX - side / 2, y: rect.midY - side / 2)
            .scaledBy(x: scale, y: scale)

        let foot = Self.wPoints[3]
        let radians = Self.climbAngle * .pi / 180
        let end = CGPoint(x: foot.x + (foot.y - Self.climbTopY) / tan(radians), y: Self.climbTopY)
        let start = CGPoint(x: foot.x + Self.climbGap * cos(radians), y: foot.y - Self.climbGap * sin(radians))

        var w = Path()
        w.addLines(Self.wPoints)
        var climb = Path()
        climb.move(to: start)
        climb.addLine(to: end)

        self.w = w.applying(transform)
        self.climb = climb.applying(transform)
        climbStart = start.applying(transform)
        climbEnd = end.applying(transform)
        strokeWidth = Self.unitStroke * scale
    }
}

/// An app icon as it looks on the Home Screen, for the icon picker in Settings.
struct AppIconTile: View {
    let choice: AppIconChoice

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        ZStack {
            switch choice {
            case .automatic:
                navy
                black.clipShape(LowerRightHalf())
            case .navy:
                navy
            case .black:
                black
            case .tinted:
                Color.black.overlay(WorkoutMark(w: Color(white: 0.85), climb: Color(white: 0.85)).padding(10))
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.separator, lineWidth: 0.5))
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var navy: some View {
        LinearGradient(colors: [Color(red: 0.055, green: 0.227, blue: 0.447), Color(red: 0.027, green: 0.102, blue: 0.212)],
                       startPoint: .top, endPoint: .bottom)
            .overlay(WorkoutMark(w: .white).padding(10))
    }

    private var black: some View {
        Color.black.overlay(WorkoutMark(w: .white).padding(10))
    }
}

/// The lower-right half of a square, split along the diagonal.
private struct LowerRightHalf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

#Preview("Climbing W") {
    VStack(spacing: 24) {
        WorkoutMark().frame(width: 160)
        HStack(spacing: 16) {
            WorkoutMark().frame(width: 32)
            WorkoutMark().frame(width: 22)
        }
        HStack(spacing: 12) {
            ForEach(AppIconChoice.allCases) { AppIconTile(choice: $0).frame(width: 60) }
        }
    }
    .padding(40)
}
