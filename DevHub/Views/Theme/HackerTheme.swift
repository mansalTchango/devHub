import SwiftUI

// MARK: - Hacker Color Palette

enum HackerColors {
    static let background = Color(hex: 0x0D1117)
    static let cardBackground = Color(hex: 0x161B22)
    static let border = Color(hex: 0x30363D)
    static let text = Color(hex: 0xC9D1D9)
    static let textSecondary = Color(hex: 0x8B949E)
    static let accent = Color(hex: 0x00FF41)       // vert matrix
    static let accentBlue = Color(hex: 0x58A6FF)
    static let accentOrange = Color(hex: 0xF0883E)
    static let accentRed = Color(hex: 0xF85149)
    static let accentPurple = Color(hex: 0xBC8CFF)
}

// MARK: - Color hex init

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Hacker Card Modifier

struct HackerCardModifier: ViewModifier {
    var borderColor: Color = HackerColors.border
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(HackerColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func hackerCard(borderColor: Color = HackerColors.border, padding: CGFloat = 16) -> some View {
        modifier(HackerCardModifier(borderColor: borderColor, padding: padding))
    }
}

// MARK: - Terminal Header Modifier

struct TerminalHeaderModifier: ViewModifier {
    let title: String
    var prompt: String = "$"
    var showCursor: Bool = true

    func body(content: Content) -> some View {
        HStack(spacing: 6) {
            Text(prompt)
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(HackerColors.accent)

            Text(title)
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(HackerColors.text)

            if showCursor {
                BlinkingCursor()
            }

            content
        }
    }
}

// MARK: - Blinking Cursor

struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Text("\u{2588}")
            .font(.system(.title, design: .monospaced, weight: .bold))
            .foregroundStyle(HackerColors.accent)
            .opacity(visible ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: visible)
            .onAppear { visible = false }
    }
}

// MARK: - Terminal Separator

struct TerminalSeparator: View {
    var body: some View {
        Text(String(repeating: "\u{2500}", count: 60))
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(HackerColors.border)
            .lineLimit(1)
    }
}

// MARK: - Hacker Button Style

struct HackerButtonStyle: ButtonStyle {
    var color: Color = HackerColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .monospaced, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.2 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.6), lineWidth: 1)
            )
    }
}

extension View {
    func hackerButton(color: Color = HackerColors.accent) -> some View {
        buttonStyle(HackerButtonStyle(color: color))
    }
}

// MARK: - ASCII Progress Bar

struct ASCIIProgressBar: View {
    let value: Double // 0-100
    var width: Int = 20
    var filledChar: String = "\u{2588}"
    var emptyChar: String = "\u{2591}"

    var body: some View {
        let filled = Int(max(0, min(100, value)) / 100 * Double(width))
        let empty = width - filled
        let bar = String(repeating: filledChar, count: filled) + String(repeating: emptyChar, count: empty)

        Text("[\(bar)] \(Int(value))%")
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(colorForValue)
    }

    private var colorForValue: Color {
        if value > 80 { return HackerColors.accentRed }
        if value > 60 { return HackerColors.accentOrange }
        return HackerColors.accent
    }
}

// MARK: - Hacker Text Field Style

struct HackerTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(HackerColors.text)
            .padding(8)
            .background(HackerColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(HackerColors.border, lineWidth: 1)
            )
    }
}

// MARK: - Hacker Scroll Background

extension View {
    func hackerBackground() -> some View {
        self
            .background(HackerColors.background)
            .foregroundStyle(HackerColors.text)
    }
}
