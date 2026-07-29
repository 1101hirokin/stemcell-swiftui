import SwiftUI
import StemcellTokens

/// 色の役（color.md §5 の intent）。契約の `color` prop がこれを選ぶ。
public enum StemcellIntent: String, Sendable, CaseIterable {
    case primary, danger, warning, plain
}

/// 使えないときの差し替え先（state.md §7）。
///
/// disabled は intent の差し替えであって減衰ではない。薄めるだけだと danger の赤が
/// 薄い赤のまま残り、「使えない」ではなく「危ないが薄い」に読める。hover と pressed を
/// 持たないのは、使えないものが押されたときの姿を持たないためである。
enum DisabledColors {
    static let bg = DynamicColor(
        light: StemcellThemeStandardLight.Color.Semantic.Disabled.bg,
        dark: StemcellThemeStandardDark.Color.Semantic.Disabled.bg)
    static let fg = DynamicColor(
        light: StemcellThemeStandardLight.Color.Semantic.Disabled.fg,
        dark: StemcellThemeStandardDark.Color.Semantic.Disabled.fg)
    static let border = DynamicColor(
        light: StemcellThemeStandardLight.Color.Semantic.Disabled.border,
        dark: StemcellThemeStandardDark.Color.Semantic.Disabled.border)
    static let softBg = DynamicColor(
        light: StemcellThemeStandardLight.Color.Semantic.Disabled.softBg,
        dark: StemcellThemeStandardDark.Color.Semantic.Disabled.softBg)
    static let softFg = DynamicColor(
        light: StemcellThemeStandardLight.Color.Semantic.Disabled.softFg,
        dark: StemcellThemeStandardDark.Color.Semantic.Disabled.softFg)
}

/// 一つの intent が持つ役割一式。明暗の対で持つ。
struct IntentColors {
    let bg, fg, border: DynamicColor
    let bgHover, bgPressed: DynamicColor
    let softBg, softFg, softBgHover, softBgPressed: DynamicColor
}

extension StemcellIntent {
    var colors: IntentColors {
        typealias L = StemcellThemeStandardLight.Color.Semantic
        typealias D = StemcellThemeStandardDark.Color.Semantic
        switch self {
        case .primary:
            return IntentColors(
                bg: .init(light: L.Primary.bg, dark: D.Primary.bg),
                fg: .init(light: L.Primary.fg, dark: D.Primary.fg),
                border: .init(light: L.Primary.border, dark: D.Primary.border),
                bgHover: .init(light: L.Primary.bgHover, dark: D.Primary.bgHover),
                bgPressed: .init(light: L.Primary.bgPressed, dark: D.Primary.bgPressed),
                softBg: .init(light: L.Primary.softBg, dark: D.Primary.softBg),
                softFg: .init(light: L.Primary.softFg, dark: D.Primary.softFg),
                softBgHover: .init(light: L.Primary.softBgHover, dark: D.Primary.softBgHover),
                softBgPressed: .init(light: L.Primary.softBgPressed, dark: D.Primary.softBgPressed)
            )
        case .danger:
            return IntentColors(
                bg: .init(light: L.Danger.bg, dark: D.Danger.bg),
                fg: .init(light: L.Danger.fg, dark: D.Danger.fg),
                border: .init(light: L.Danger.border, dark: D.Danger.border),
                bgHover: .init(light: L.Danger.bgHover, dark: D.Danger.bgHover),
                bgPressed: .init(light: L.Danger.bgPressed, dark: D.Danger.bgPressed),
                softBg: .init(light: L.Danger.softBg, dark: D.Danger.softBg),
                softFg: .init(light: L.Danger.softFg, dark: D.Danger.softFg),
                softBgHover: .init(light: L.Danger.softBgHover, dark: D.Danger.softBgHover),
                softBgPressed: .init(light: L.Danger.softBgPressed, dark: D.Danger.softBgPressed)
            )
        case .warning:
            return IntentColors(
                bg: .init(light: L.Warning.bg, dark: D.Warning.bg),
                fg: .init(light: L.Warning.fg, dark: D.Warning.fg),
                border: .init(light: L.Warning.border, dark: D.Warning.border),
                bgHover: .init(light: L.Warning.bgHover, dark: D.Warning.bgHover),
                bgPressed: .init(light: L.Warning.bgPressed, dark: D.Warning.bgPressed),
                softBg: .init(light: L.Warning.softBg, dark: D.Warning.softBg),
                softFg: .init(light: L.Warning.softFg, dark: D.Warning.softFg),
                softBgHover: .init(light: L.Warning.softBgHover, dark: D.Warning.softBgHover),
                softBgPressed: .init(light: L.Warning.softBgPressed, dark: D.Warning.softBgPressed)
            )
        case .plain:
            return IntentColors(
                bg: .init(light: L.Plain.bg, dark: D.Plain.bg),
                fg: .init(light: L.Plain.fg, dark: D.Plain.fg),
                border: .init(light: L.Plain.border, dark: D.Plain.border),
                bgHover: .init(light: L.Plain.bgHover, dark: D.Plain.bgHover),
                bgPressed: .init(light: L.Plain.bgPressed, dark: D.Plain.bgPressed),
                softBg: .init(light: L.Plain.softBg, dark: D.Plain.softBg),
                softFg: .init(light: L.Plain.softFg, dark: D.Plain.softFg),
                softBgHover: .init(light: L.Plain.softBgHover, dark: D.Plain.softBgHover),
                softBgPressed: .init(light: L.Plain.softBgPressed, dark: D.Plain.softBgPressed)
            )
        }
    }
}

/// 強調度（emphasis.md §3 の4段）。
public enum StemcellVariant: String, Sendable, CaseIterable {
    case filled, soft, outlined, text
}

/// 段（size.md §2）。段が引くのは内側余白と当たり判定の下限だけで、文字は引かない。
public enum StemcellSize: String, Sendable, CaseIterable {
    case sm, md, lg

    var inset: CGFloat {
        switch self {
        case .sm: return StemcellTokens.Spacing.Inset.sm
        case .md: return StemcellTokens.Spacing.Inset.md
        case .lg: return StemcellTokens.Spacing.Inset.lg
        }
    }
}
