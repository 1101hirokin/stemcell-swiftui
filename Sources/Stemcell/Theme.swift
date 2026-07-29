import SwiftUI
import StemcellTokens

/// 明暗の対で持つ意味の色。
///
/// 消費者はここを差し替えてブランドを注入できる（憲法 第3条。StemcellProvider §7）。
/// 差し替えられる必要があるから、値は実行時のものであってアセットカタログではない。
public struct StemcellColors: Sendable, Hashable {
    public var background: DynamicColor
    public var foreground: DynamicColor
    public var surface: DynamicColor
    public var border: DynamicColor
    public var fgMuted: DynamicColor
    public var primaryBackground: DynamicColor
    public var primaryForeground: DynamicColor

    public init(
        background: DynamicColor,
        foreground: DynamicColor,
        surface: DynamicColor,
        border: DynamicColor,
        fgMuted: DynamicColor,
        primaryBackground: DynamicColor,
        primaryForeground: DynamicColor
    ) {
        self.background = background
        self.foreground = foreground
        self.surface = surface
        self.border = border
        self.fgMuted = fgMuted
        self.primaryBackground = primaryBackground
        self.primaryForeground = primaryForeground
    }
}

/// 密度。段の中身を差し替える（spacing.md §5）。
public enum StemcellDensity: String, Sendable, CaseIterable {
    case comfortable
    case compact
}

/// 文脈として配るもの。
public struct StemcellTheme: Sendable, Hashable {
    public var colors: StemcellColors

    public init(colors: StemcellColors) {
        self.colors = colors
    }
}

extension StemcellTheme {
    /// 既定のテーマ。値は @stemcell/tokens が生成したものを組み合わせる。
    public static let standard = StemcellTheme(
        colors: StemcellColors(
            background: .init(
                light: StemcellThemeStandardLight.Color.App.background,
                dark: StemcellThemeStandardDark.Color.App.background
            ),
            foreground: .init(
                light: StemcellThemeStandardLight.Color.App.foreground,
                dark: StemcellThemeStandardDark.Color.App.foreground
            ),
            surface: .init(
                light: StemcellThemeStandardLight.Color.App.surface,
                dark: StemcellThemeStandardDark.Color.App.surface
            ),
            border: .init(
                light: StemcellThemeStandardLight.Color.App.border,
                dark: StemcellThemeStandardDark.Color.App.border
            ),
            fgMuted: .init(
                light: StemcellThemeStandardLight.Color.App.fgMuted,
                dark: StemcellThemeStandardDark.Color.App.fgMuted
            ),
            primaryBackground: .init(
                light: StemcellThemeStandardLight.Color.Semantic.Primary.bg,
                dark: StemcellThemeStandardDark.Color.Semantic.Primary.bg
            ),
            primaryForeground: .init(
                light: StemcellThemeStandardLight.Color.Semantic.Primary.fg,
                dark: StemcellThemeStandardDark.Color.Semantic.Primary.fg
            )
        )
    )
}
