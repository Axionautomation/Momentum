//
//  Theme.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

// MARK: - Color System
extension Color {
    // Primary Colors
    static let momentumDeepBlue = Color(hex: "1E3A8A")
    static let momentumViolet = Color(hex: "7C3AED")
    static let momentumCoral = Color(hex: "FF6B4A")

    // Success Gradient Colors
    static let momentumGreenStart = Color(hex: "10B981")
    static let momentumGreenEnd = Color(hex: "34D399")

    // Background Colors
    static let momentumLightBackground = Color(hex: "F9FAFB")
    static let momentumDarkBackground = Color(hex: "0F172A")

    // Opaque Surface Colors (Design Guide Compliant)
    static let momentumSurfacePrimary = Color(hex: "0E0F12")      // Near-black primary surface
    static let momentumSurfaceSecondary = Color(hex: "15171C")    // Slightly lighter surface
    static let momentumSurfaceDivider = Color(hex: "1F2228")      // Dividers and outlines

    // Text Colors
    static let momentumPrimaryText = Color.white
    static let momentumSecondaryText = Color(hex: "94A3B8")

    // Gold/Achievement Colors
    static let momentumGold = Color(hex: "F59E0B")
    static let momentumGoldLight = Color(hex: "FCD34D")

    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
struct MomentumGradients {
    static let primary = LinearGradient(
        colors: [.momentumDeepBlue, .momentumViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let success = LinearGradient(
        colors: [.momentumGreenStart, .momentumGreenEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let gold = LinearGradient(
        colors: [.momentumGold, .momentumGoldLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coral = LinearGradient(
        colors: [.momentumCoral, .momentumCoral.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = LinearGradient(
        colors: [.momentumDarkBackground, Color(hex: "1E293B")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography
struct MomentumFont {
    static func heading(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func bodyMedium(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func stats(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

// MARK: - View Modifiers

/// Opaque surface modifier (replaces FrostedGlassModifier)
/// Uses dark opaque colors instead of Apple's blur materials per design guide
struct OpaqueSurfaceModifier: ViewModifier {
    var level: SurfaceLevel = .primary
    var cornerRadius: CGFloat = 12

    enum SurfaceLevel {
        case primary      // Darkest (#0E0F12)
        case secondary    // Medium (#15171C)
        case elevated     // Same as secondary but with more shadow
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.momentumSurfaceDivider, lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(0.3),
                radius: level == .elevated ? 20 : 8,
                y: level == .elevated ? 10 : 4
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var backgroundColor: Color {
        switch level {
        case .primary:
            return .momentumSurfacePrimary
        case .secondary, .elevated:
            return .momentumSurfaceSecondary
        }
    }
}

/// Legacy FrostedGlassModifier (kept for backward compatibility, now uses opaque surfaces)
struct FrostedGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.momentumSurfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.momentumSurfaceDivider, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CardModifier: ViewModifier {
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isHighlighted ? Color.momentumViolet : Color.clear,
                        lineWidth: 2
                    )
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MomentumFont.bodyMedium(17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.momentumDeepBlue, .momentumViolet],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MomentumFont.bodyMedium(17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    /// Apply opaque surface styling (design guide compliant)
    func opaqueSurface(level: OpaqueSurfaceModifier.SurfaceLevel = .secondary, cornerRadius: CGFloat = 12) -> some View {
        modifier(OpaqueSurfaceModifier(level: level, cornerRadius: cornerRadius))
    }

    /// Legacy frosted glass method (now uses opaque surfaces)
    func frostedGlass() -> some View {
        modifier(FrostedGlassModifier())
    }

    func cardStyle(highlighted: Bool = false) -> some View {
        modifier(CardModifier(isHighlighted: highlighted))
    }
}
