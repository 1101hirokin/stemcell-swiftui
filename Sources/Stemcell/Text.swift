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

    /// 与えられた大きさで組む。大きさは呼ぶ側が決める（Dynamic Type で伸びた後の値が来る）。
    ///
    /// `Font.system(size:)` は固定の大きさであって、Dynamic Type では伸びない。
    /// 前の版はここに `metrics.size` を直に渡していて、字が伸びなかった。iPad Pro 13 で
    /// 標準と accessibility-extra-extra-extra-large を撮り比べ、見出しの墨の外接箱が
    /// どちらも 90.5 x 12.5pt で同じであることを測って分かった。
    ///
    /// 書体そのもの（CSS の font stack）はトークンから写せないので、その土地の既定に委ねる。
    func font(size: CGFloat) -> Font {
        Font.system(
            size: size,
            weight: Font.Weight(stemcellWeight: metrics.weight),
            design: isMonospaced ? .monospaced : .default
        )
    }

    /// 行の高さは比で持つが、SwiftUI の lineSpacing は行と行の「あいだ」である。差し引いて渡す。
    /// 大きさが伸びれば、あいだも同じ比で伸びる要がある。
    func lineSpacing(size: CGFloat) -> CGFloat {
        size * (metrics.lineHeight - 1)
    }

    /// Dynamic Type の伸び方をどの native の役に合わせるか。
    ///
    /// `@ScaledMetric` は基準の値をこの役の伸び率で掛ける。基準はトークンのままなので、
    /// ここが決めるのは大きさではなく伸びの速さだけである。native の役は大きいものほど
    /// 緩く伸びる。実測で `largeTitle` に合わせた役が 1.68 倍、`caption2` に合わせた役が
    /// 3.63 倍だった（iPad Pro 13、標準から accessibility-extra-extra-extra-large）。
    ///
    /// 選び方は、トークンの大きさに一番近い native の役へ合わせる、という一つの規則で通す。
    /// 前の版は役の意図（display / headline / title …）で選んでいたが、それだとトークンで
    /// 大きさが同じ役に別の伸び率が付く。`headlineMd` と `titleLg` はどちらも 21pt なのに
    /// 最大設定で 2.33 倍と 2.04 倍に割れていた。トークンに無い階層を Dynamic Type が
    /// 作り出していたことになる。大きさが同じなら伸び方も同じにする。
    ///
    /// 同じ距離に二つ並ぶとき（14pt に対する `footnote` 13pt と `subheadline` 15pt）は
    /// 大きいほうを採る。緩く伸びるほうで、版面が壊れにくい。
    var scaleAnchor: Font.TextStyle {
        switch metrics.size {
        case 42: return .largeTitle   // native 34
        case 28: return .title        // native 28
        case 21: return .title2       // native 22
        case 16.8: return .body       // native 17
        case 14: return .subheadline  // native 15
        case 12: return .caption      // native 12
        default: return .caption2     // 10.5 に対する native 11
        }
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
    /// 字の役を当てる。契約の `Text.variant` はここへ写る。
    ///
    /// 名前に接頭辞を付けないのは、姿を当てる修飾子だからである。消費者が絶えず書くものは
    /// native の形に寄せ、文脈を配るもの（`.stemcellTheme` / `.stemcellDensity`）だけが
    /// 接頭辞を持つ（DESIGN.md §12）。
    ///
    /// 契約の `truncate` と `muted` は引数にしない。SwiftUI に口があるからである
    /// （`.lineLimit(1)` と `.foregroundStyle(...)`）。二つの道を作ると真実が二つになる。
    /// `Button` の `disabled` を `.disabled()` へ委ねたのと同じ判断である。
    public func textStyle(_ role: StemcellTextRole = .bodyMd) -> some View {
        modifier(StemcellTextModifier(role: role))
    }
}

struct StemcellTextModifier: ViewModifier {
    let role: StemcellTextRole
    /// トークンの大きさを、利用者が選んだ本文の大きさで伸ばした値。
    @ScaledMetric private var size: CGFloat

    init(role: StemcellTextRole) {
        self.role = role
        _size = ScaledMetric(wrappedValue: role.metrics.size, relativeTo: role.scaleAnchor)
    }

    func body(content: Content) -> some View {
        content
            .font(role.font(size: size))
            .lineSpacing(role.lineSpacing(size: size))
    }
}

extension ShapeStyle where Self == Color {
    /// 副次の文字色（契約の `muted`）。`.foregroundStyle(.stemcellMuted)` で当てる。
    public static var stemcellMuted: Color {
        DynamicColor(
            light: StemcellThemeStandardLight.Color.App.fgMuted,
            dark: StemcellThemeStandardDark.Color.App.fgMuted
        ).resolved
    }
}
