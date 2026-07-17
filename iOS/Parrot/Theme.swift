import SwiftUI
import UIKit

// Sunny classroom by day, dusk classroom by night.
// Sky-blue base with two tropical accents used sparingly: coral and leaf green.

enum Theme {
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let sky = dynamic(light: UIColor(red: 0.22, green: 0.62, blue: 0.86, alpha: 1),
                             dark: UIColor(red: 0.42, green: 0.71, blue: 0.89, alpha: 1))
    static let coral = dynamic(light: UIColor(red: 1.00, green: 0.42, blue: 0.37, alpha: 1),
                               dark: UIColor(red: 0.91, green: 0.51, blue: 0.47, alpha: 1))
    static let leaf = dynamic(light: UIColor(red: 0.22, green: 0.65, blue: 0.42, alpha: 1),
                              dark: UIColor(red: 0.40, green: 0.72, blue: 0.53, alpha: 1))
    static let amber = dynamic(light: UIColor(red: 0.95, green: 0.66, blue: 0.20, alpha: 1),
                               dark: UIColor(red: 0.88, green: 0.67, blue: 0.34, alpha: 1))
    static let ink = dynamic(light: UIColor(red: 0.07, green: 0.20, blue: 0.29, alpha: 1),
                             dark: UIColor(red: 0.90, green: 0.95, blue: 0.98, alpha: 1))
    static let inkSoft = dynamic(light: UIColor(red: 0.07, green: 0.20, blue: 0.29, alpha: 0.6),
                                 dark: UIColor(red: 0.90, green: 0.95, blue: 0.98, alpha: 0.6))
    static let shadow = dynamic(light: UIColor(red: 0.10, green: 0.35, blue: 0.55, alpha: 0.16),
                                dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.45))

    static let skyTop = dynamic(light: UIColor(red: 0.69, green: 0.88, blue: 0.98, alpha: 1),
                                dark: UIColor(red: 0.06, green: 0.11, blue: 0.18, alpha: 1))
    static let skyBottom = dynamic(light: UIColor(red: 0.90, green: 0.97, blue: 1.00, alpha: 1),
                                   dark: UIColor(red: 0.10, green: 0.17, blue: 0.25, alpha: 1))

    // Springs
    static let springFast = Animation.spring(response: 0.2, dampingFraction: 0.75)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.78)
    static let springSoft = Animation.spring(response: 0.35, dampingFraction: 0.82)
}

// MARK: - Classroom background

struct ClassroomBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.skyTop, Theme.skyBottom],
                           startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Theme.coral.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -150, y: -260)
            Circle()
                .fill(Theme.leaf.opacity(0.12))
                .frame(width: 360, height: 360)
                .blur(radius: 70)
                .offset(x: 170, y: 300)
            Circle()
                .fill(Theme.sky.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 150, y: -120)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass card

struct GlassCard: ViewModifier {
    var corner: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.06)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Theme.shadow, radius: 16, x: 0, y: 8)
            )
    }
}

extension View {
    func glassCard(corner: CGFloat = 28) -> some View {
        modifier(GlassCard(corner: corner))
    }
}

// MARK: - Keyboard dismissal

extension View {
    /// Every text-input screen gets this: interactive scroll dismissal plus
    /// a background tap anywhere outside the field resigns first responder.
    func dismissKeyboardOnTap() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
            }
    }
}

// MARK: - Shared small views

struct AccuracyDial: View {
    let accuracy: Double
    var size: CGFloat = 64
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ink.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, accuracy))
                .stroke(
                    accuracy >= Mastery.threshold ? Theme.leaf : Theme.sky,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.springSoft, value: accuracy)
            Text(accuracy.percentText)
                .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .animation(Theme.springFast, value: accuracy)
        }
        .frame(width: size, height: size)
    }
}

struct PositionChip: View {
    let position: WordPosition

    var body: some View {
        Text(position.label)
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.inkSoft)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Theme.ink.opacity(0.07)))
    }
}
