import SwiftUI

// MARK: - Apex Design System semantic tokens
// Dark-first palette: Arc (indigo, UI chrome), Pulse (emerald, positive signal),
// Ignite (orange, high effort/attention), Graphite (cool-violet neutral surfaces/text).
// Always use these tokens in views — never raw hex or system colors.

extension Color {

    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    // Surfaces
    static let apexCanvas = Color(hex: 0x0A0A10)
    static let apexCard = Color(hex: 0x12121A)
    static let apexSurfaceElevated = Color(hex: 0x1A1A24)
    static let apexBorder = Color(hex: 0x26262E)

    // Text hierarchy
    static let apexTextPrimary = Color(hex: 0xF4F4F6)
    static let apexTextSecondary = Color(hex: 0x9797A6)
    static let apexTextTertiary = Color(hex: 0x6B6B78)

    // Palette accents
    static let apexArc = Color(hex: 0x818CF8)      // UI chrome only
    static let apexPulse = Color(hex: 0x34D399)    // positive bio-signal
    static let apexIgnite = Color(hex: 0xFB923C)   // attention / max effort

    // Status tiers (Low/Moderate/High, mirrors recovery/readiness scale)
    static let apexStatusGood = apexPulse
    static let apexStatusModerate = apexIgnite
    static let apexStatusPoor = Color(hex: 0xEF4444)
}
