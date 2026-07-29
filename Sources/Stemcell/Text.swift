import SwiftUI
import StemcellTokens
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

    /// 契約が定める行 box の高さ。
    var lineBox: CGFloat {
        metrics.size * metrics.lineHeight
    }

    /// その土地が字に与える自然な行高。ここは契約が持たず、書体が持つ。
    var naturalLineHeight: CGFloat {
        let w = Font.Weight(stemcellWeight: metrics.weight)
        #if canImport(UIKit)
        let f = isMonospaced
            ? UIFont.monospacedSystemFont(ofSize: metrics.size, weight: w.uiKit)
            : UIFont.systemFont(ofSize: metrics.size, weight: w.uiKit)
        return f.lineHeight
        #elseif canImport(AppKit)
        let f = isMonospaced
            ? NSFont.monospacedSystemFont(ofSize: metrics.size, weight: w.appKit)
            : NSFont.systemFont(ofSize: metrics.size, weight: w.appKit)
        return NSLayoutManager().defaultLineHeight(for: f)
        #else
        return metrics.size * 1.2
        #endif
    }
}

extension Font.Weight {
    #if canImport(UIKit)
    var uiKit: UIFont.Weight {
        switch self {
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        default: return .regular
        }
    }
    #elseif canImport(AppKit)
    var appKit: NSFont.Weight {
        switch self {
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        default: return .regular
        }
    }
    #endif

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

    func body(content: Content) -> some View {
        // 契約の行の高さは行 box の高さである（typography.md §3.2 の固定比 1.334）。
        // CSS の line-height は一行でも行 box を決めるが、SwiftUI の lineSpacing は
        // 行と行のあいだにしか効かない。一行の Text はその土地の自然な行高のままになる。
        //
        // Web と並べて見つけた。md のボタンで、字の箱が 16.0pt しか無く
        // 14 × 1.334 = 18.68 になっていなかった。
        //
        // 足りないぶんを、行のあいだと上下の余白へ分けて配る。あいだへ入れると
        // 二行目以降が、余白へ入れると一行目と最終行が、それぞれ正しい高さになる。
        let extra = max(0, role.lineBox - role.naturalLineHeight)
        content
            .font(role.font)
            .lineSpacing(extra)
            .padding(.vertical, extra / 2)
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
