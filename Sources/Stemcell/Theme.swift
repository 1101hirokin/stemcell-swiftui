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
    /// modal の背後に敷く veil（elevation.md §6）。半透明で持つ。
    public var scrim: DynamicColor

    public init(
        background: DynamicColor,
        foreground: DynamicColor,
        surface: DynamicColor,
        border: DynamicColor,
        fgMuted: DynamicColor,
        primaryBackground: DynamicColor,
        primaryForeground: DynamicColor,
        scrim: DynamicColor
    ) {
        self.background = background
        self.foreground = foreground
        self.surface = surface
        self.border = border
        self.fgMuted = fgMuted
        self.primaryBackground = primaryBackground
        self.primaryForeground = primaryForeground
        self.scrim = scrim
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
            ),
            // トークンの `scrim` は veil で、本来 0.4 の不透明度を持つ。いま引いている
            // 0.0.0-alpha.16 の Swift 出力はそれを落としていて不透明のまま出る。
            // 直しは stemcell-tokens の PR #24 にあるが、版がまだ切られていない。
            // それまでは値を自前で当てる。elevation.md §6 が「基底色を自前で透過させ直さない」
            // と定めているところなので、版が上がったら消す。HOLES #13。
            scrim: .init(
                light: StemcellThemeStandardLight.scrim.opacity(0.4),
                dark: StemcellThemeStandardDark.scrim.opacity(0.4)
            )
        )
    )
}
