//
//  Theme.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

// MARK: - Color System

extension Color {
    // Primary Background
    static let momentumBackground = Color.white
    static let momentumBackgroundSecondary = Color(hex: "F8FAFC")

    // Primary Accent - Electric Blue
    static let momentumBlue = Color(hex: "2563EB")
    static let momentumBlueLight = Color(hex: "3B82F6")
    static let momentumBlueDark = Color(hex: "1D4ED8")

    // Text Colors
    static let momentumTextPrimary = Color(hex: "0F172A")
    static let momentumTextSecondary = Color(hex: "64748B")
    static let momentumTextTertiary = Color(hex: "94A3B8")

    // Difficulty Colors
    static let momentumEasy = Color(hex: "10B981")      // Emerald - 1 point
    static let momentumMedium = Color(hex: "F59E0B")    // Amber - 2 points
    static let momentumHard = Color(hex: "EF4444")      // Red - 3 points

    // Status Colors
    static let momentumSuccess = Color(hex: "10B981")
    static let momentumWarning = Color(hex: "F59E0B")
    static let momentumDanger = Color(hex: "EF4444")

    // Card Colors
    static let momentumCardBackground = Color.white
    static let momentumCardBorder = Color(hex: "E2E8F0")

    // Legacy colors (kept for compatibility)
    static let momentumDeepBlue = Color(hex: "1E3A8A")
    static let momentumViolet = Color(hex: "7C3AED")
    static let momentumCoral = Color(hex: "FF6B4A")
    static let momentumGreenStart = Color(hex: "10B981")
    static let momentumGreenEnd = Color(hex: "34D399")
    static let momentumLightBackground = Color(hex: "F9FAFB")
    static let momentumDarkBackground = Color(hex: "0F172A")
    static let momentumSurfacePrimary = Color(hex: "0E0F12")
    static let momentumSurfaceSecondary = Color(hex: "15171C")
    static let momentumSurfaceDivider = Color(hex: "1F2228")
    static let momentumPrimaryText = Color.white
    static let momentumSecondaryText = Color(hex: "94A3B8")
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

// MARK: - Typography

struct MomentumFont {
    // Using SF Pro Rounded as fallback until Plus Jakarta Sans is added
    // To use Plus Jakarta Sans:
    // 1. Download from Google Fonts
    // 2. Add .ttf files to project
    // 3. Add to Info.plist under "Fonts provided by application"
    // 4. Change .rounded to .default and use .custom("PlusJakartaSans-Regular", size:)

    static func display(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headingLarge(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func headingMedium(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func bodyMedium(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func label(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    // Legacy methods
    static func heading(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func stats(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

// MARK: - Spacing

struct MomentumSpacing {
    static let micro: CGFloat = 4
    static let tight: CGFloat = 8
    static let compact: CGFloat = 12
    static let standard: CGFloat = 16
    static let comfortable: CGFloat = 20
    static let section: CGFloat = 24
    static let large: CGFloat = 32
}

// MARK: - Corner Radii

struct MomentumRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

// MARK: - Gradients

struct MomentumGradients {
    static let primary = LinearGradient(
        colors: [.momentumBlue, .momentumBlueLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let success = LinearGradient(
        colors: [.momentumSuccess, Color(hex: "34D399")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let celebration = LinearGradient(
        colors: [.momentumBlue, Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Legacy
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

// MARK: - View Modifiers

struct MomentumCardModifier: ViewModifier {
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(Color.momentumCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .strokeBorder(
                        isHighlighted ? Color.momentumBlue : Color.momentumCardBorder.opacity(0.5),
                        lineWidth: isHighlighted ? 2 : 1
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
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .fill(Color.momentumBlue)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MomentumFont.bodyMedium(17))
            .foregroundColor(.momentumBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: MomentumRadius.small)
                    .fill(Color.momentumBlue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.small)
                    .strokeBorder(Color.momentumBlue.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func momentumCard(highlighted: Bool = false) -> some View {
        modifier(MomentumCardModifier(isHighlighted: highlighted))
    }

    // Legacy modifiers
    func opaqueSurface(level: OpaqueSurfaceModifier.SurfaceLevel = .secondary, cornerRadius: CGFloat = 12) -> some View {
        modifier(OpaqueSurfaceModifier(level: level, cornerRadius: cornerRadius))
    }

    func frostedGlass() -> some View {
        modifier(FrostedGlassModifier())
    }

    func cardStyle(highlighted: Bool = false) -> some View {
        modifier(CardModifier(isHighlighted: highlighted))
    }
}

// MARK: - Legacy Modifiers (kept for compatibility)

struct OpaqueSurfaceModifier: ViewModifier {
    var level: SurfaceLevel = .primary
    var cornerRadius: CGFloat = 12

    enum SurfaceLevel {
        case primary
        case secondary
        case elevated
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
