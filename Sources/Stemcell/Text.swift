import SwiftUI
import StemcellTokens

/// 字の役（typography.md §4）。契約の `Text.variant` がこれを選ぶ。
///
/// SwiftUI の `Text` とは名前が衝突するので、型ではなく修飾子で出す（DESIGN.md §2）。
/// `Font` の拡張だけでは足りない。役は大きさと太さのほかに行の高さを持ち、SwiftUI では
/// 行の高さが `Font` ではなく View 側（`lineSpacing`）にあるからである。
public enum StemcellTextRole: String, Sendable, CaseIterable {
    case displayLg = "display-lg"
    case displayMd = "display-md"
    case headlineLg = "headline-lg"
    case headlineMd = "headline-md"
    case headlineSm = "headline-sm"
    case titleLg = "title-lg"
    case titleMd = "title-md"
    case titleSm = "title-sm"
    case bodyLg = "body-lg"
    case bodyMd = "body-md"
    case bodySm = "body-sm"
    case labelLg = "label-lg"
    case labelMd = "label-md"
    case labelSm = "label-sm"
    case monoMd = "mono-md"
    case monoSm = "mono-sm"

    /// 等幅で組む役。コードの断片に使う。
    public var isMonospaced: Bool {
        self == .monoMd || self == .monoSm
    }

    var metrics: (size: CGFloat, weight: CGFloat, lineHeight: CGFloat) {
        typealias T = StemcellTokens.Typography
        switch self {
        case .displayLg:
            return (T.DisplayLg.fontSize, T.DisplayLg.fontWeight, T.DisplayLg.lineHeight)
        case .displayMd:
            return (T.DisplayMd.fontSize, T.DisplayMd.fontWeight, T.DisplayMd.lineHeight)
        case .headlineLg:
            return (T.HeadlineLg.fontSize, T.HeadlineLg.fontWeight, T.HeadlineLg.lineHeight)
        case .headlineMd:
            return (T.HeadlineMd.fontSize, T.HeadlineMd.fontWeight, T.HeadlineMd.lineHeight)
        case .headlineSm:
            return (T.HeadlineSm.fontSize, T.HeadlineSm.fontWeight, T.HeadlineSm.lineHeight)
        case .titleLg:
            return (T.TitleLg.fontSize, T.TitleLg.fontWeight, T.TitleLg.lineHeight)
        case .titleMd:
            return (T.TitleMd.fontSize, T.TitleMd.fontWeight, T.TitleMd.lineHeight)
        case .titleSm:
            return (T.TitleSm.fontSize, T.TitleSm.fontWeight, T.TitleSm.lineHeight)
        case .bodyLg:
            return (T.BodyLg.fontSize, T.BodyLg.fontWeight, T.BodyLg.lineHeight)
        case .bodyMd:
            return (T.BodyMd.fontSize, T.BodyMd.fontWeight, T.BodyMd.lineHeight)
        case .bodySm:
            return (T.BodySm.fontSize, T.BodySm.fontWeight, T.BodySm.lineHeight)
        case .labelLg:
            return (T.LabelLg.fontSize, T.LabelLg.fontWeight, T.LabelLg.lineHeight)
        case .labelMd:
            return (T.LabelMd.fontSize, T.LabelMd.fontWeight, T.LabelMd.lineHeight)
        case .labelSm:
            return (T.LabelSm.fontSize, T.LabelSm.fontWeight, T.LabelSm.lineHeight)
        case .monoMd:
            return (T.MonoMd.fontSize, T.MonoMd.fontWeight, T.MonoMd.lineHeight)
        case .monoSm:
            return (T.MonoSm.fontSize, T.MonoSm.fontWeight, T.MonoSm.lineHeight)
        }
    }

    var font: Font {
        // Font.system(size:) は Dynamic Type で伸びる。字を固定しないのは第1条である。
        // 書体そのもの（CSS の font stack）はトークンから写せないので、その土地の既定に委ねる。
        Font.system(
            size: metrics.size,
            weight: Font.Weight(stemcellWeight: metrics.weight),
            design: isMonospaced ? .monospaced : .default
        )
    }

    /// 行の高さは比で持つが、SwiftUI の lineSpacing は行と行の「あいだ」である。差し引いて渡す。
    var lineSpacing: CGFloat {
        metrics.size * (metrics.lineHeight - 1)
    }
}

extension Font.Weight {
    init(stemcellWeight raw: CGFloat) {
        switch raw {
        case ..<450: self = .regular
        case ..<550: self = .medium
        case ..<650: self = .semibold
        default: self = .bold
        }
    }
}

extension View {
    /// 字の役を当てる。契約の Text はここへ写る。
    public func stemcellText(
        _ role: StemcellTextRole = .bodyMd,
        muted: Bool = false,
        truncate: Bool = false
    ) -> some View {
        modifier(StemcellTextModifier(role: role, muted: muted, truncate: truncate))
    }
}

struct StemcellTextModifier: ViewModifier {
    let role: StemcellTextRole
    let muted: Bool
    let truncate: Bool

    @Environment(\.stemcellTheme) private var theme

    func body(content: Content) -> some View {
        content
            .font(role.font)
            .lineSpacing(role.lineSpacing)
            .lineLimit(truncate ? 1 : nil)
            .truncationMode(.tail)
            // 既定は色を宣言せず周りを継ぐ（契約: muted の既定 false は色を宣言しない）。
            .foregroundStyle(muted ? AnyShapeStyle(theme.colors.fgMuted.resolved) : AnyShapeStyle(.foreground))
    }
}
