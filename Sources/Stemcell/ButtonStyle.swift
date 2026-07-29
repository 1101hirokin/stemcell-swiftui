import SwiftUI
import StemcellTokens

/// 契約の `Button` は SwiftUI では型ではなく様式で出す（DESIGN.md §2）。
///
/// SwiftUI の `Button` は Liquid Glass も鍵盤とスイッチコントロールの操作も Dynamic Type も
/// VoiceOver の traits も無償で持っている。自前で描けばそれを捨てて書き直すことになる
/// （第2条 / RFC 0010）。だから姿だけを差し替える。
public struct StemcellButtonStyle: ButtonStyle {
    var variant: StemcellVariant
    var intent: StemcellIntent
    var size: StemcellSize
    var fullWidth: Bool
    /// 角の形。IconButton の `shape` がここへ来る。
    var corner: CGFloat

    // 無効は契約の prop ではなく環境から来る。SwiftUI の .disabled() が正であり、
    // 部品が別の道を作ると二つの真実ができる（第2条: native の機構で満たす）。
    @Environment(\.isEnabled) private var isEnabled

    public func makeBody(configuration: Configuration) -> some View {
        let c = intent.colors
        let pressed = configuration.isPressed

        configuration.label
            // 字の役は label-lg である（contracts/Button/contract.json の tokensRequired が
            // typography.label-lg を挙げている）。段では変えない。Web も全段で当てている。
            // 前の版は役を一つも当てておらず、周囲の既定（.body の 17pt）で組んでいた。
            .textStyle(.labelLg)
            // 折り返さない。入りきらないときは省略記号で切る。
            //
            // 主要 DS を一次資料で当たると、一行に保つ側が多数である（Material 3 の実装、
            // UIKit の古典、shadcn/ui、Primer、Ant Design、Atlaskit）。そのうち省略を選ぶのが
            // Material 3 と UIKit の古典と Atlaskit で、はみ出す側の三つは意図して選んだと
            // いうより対策していないだけに見える。
            //
            // SwiftUI の既定は lineLimit が nil で折り返すが、それは Apple の作法ではない。
            // UILabel の既定は numberOfLines 1 の byTruncatingTail で、Apple の中でも割れている。
            //
            // 折り返しを許さないのは、どこで折るかが言語依存になり、CJK と欧文で意味が変わる
            // からである。三つの土地で一意に実装できなくなる。
            //
            // 実害も見た。横の余白が md で左右 48pt を無条件に食うので、親がそれを下回ると
            // 字の有効幅が 0 になり、文字が一つも描かれないまま高さだけが 153.5pt まで伸びた。
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.vertical, size.inset)
            .padding(.horizontal, size.inset * 2)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .foregroundStyle(foreground(c).resolved)
            .background(background(c, pressed: pressed))
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay {
                if variant == .outlined {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: StemcellTokens.Shape.borderWidth)
                }
            }
            // ここから下は当たり判定の話で、姿の話ではない。
            //
            // size.rules.json は minimumTargetSize を appliesTo: hit-region と定め、
            // 「見た目の大きさではなく押せる範囲。したがって段と密度は見た目を詰めてよい」と
            // 註釈している。だから枠は面より外に置く。前の版は面より前に置いていて、
            // sm の段が 36.5pt から 44.0pt へ膨らみ、段を一つ潰していた。
            //
            // contentShape が要るのは、面を持たない強調度（outlined と text）が透明な地を
            // 持つからである。SwiftUI は透明な画素を押せる範囲に数えないので、字の上でしか
            // 反応しなかった。実機で見つかった。
            //
            // 床の値をトークンから引けないのは size.md §7 が未確定にしているためで、HOLES #4。
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }

    private func foreground(_ c: IntentColors) -> DynamicColor {
        // 使えないときは intent ごと差し替える（state.md §7）。薄めない。
        guard isEnabled else { return variant == .filled ? DisabledColors.fg : DisabledColors.softFg }
        return variant == .filled ? c.fg : c.softFg
    }

    private var borderColor: Color {
        isEnabled ? intent.colors.border.resolved : DisabledColors.border.resolved
    }

    @ViewBuilder
    private func background(_ c: IntentColors, pressed: Bool) -> some View {
        if !isEnabled {
            // 押された姿は持たない。使えないものは押せない。
            switch variant {
            case .filled: DisabledColors.bg.resolved
            case .soft: DisabledColors.softBg.resolved
            case .outlined, .text: Color.clear
            }
        } else {
            switch variant {
            case .filled:
                (pressed ? c.bgPressed : c.bg).resolved
            case .soft:
                (pressed ? c.softBgPressed : c.softBg).resolved
            case .outlined, .text:
                // 面を持たない強調度は、押したときだけ面を得る（emphasis.md §4）。
                pressed ? c.softBgPressed.resolved : Color.clear
            }
        }
    }
}

extension ButtonStyle where Self == StemcellButtonStyle {
    /// stemcell の姿。
    public static var stemcell: StemcellButtonStyle { .stemcell() }

    public static func stemcell(
        _ variant: StemcellVariant = .filled,
        color intent: StemcellIntent = .primary,
        size: StemcellSize = .md,
        fullWidth: Bool = false
    ) -> StemcellButtonStyle {
        StemcellButtonStyle(
            variant: variant, intent: intent, size: size,
            fullWidth: fullWidth, corner: StemcellTokens.Shape.Continuous.Semantic.control
        )
    }

    /// 絵だけのボタン（IconButton）。名前は `.accessibilityLabel` で渡す。
    /// 契約は `label` を必須にしているが、SwiftUI では到達性の修飾子がその口である。
    public static func stemcellIcon(
        _ variant: StemcellVariant = .text,
        color intent: StemcellIntent = .plain,
        size: StemcellSize = .md,
        shape: IconButtonShape = .control
    ) -> StemcellButtonStyle {
        StemcellButtonStyle(
            variant: variant, intent: intent, size: size,
            fullWidth: false, corner: shape.corner
        )
    }
}

/// 絵だけのボタンの角（IconButton の `shape`）。
public enum IconButtonShape: String, Sendable, CaseIterable {
    case control, pill

    var corner: CGFloat {
        switch self {
        case .control: return StemcellTokens.Shape.Continuous.Semantic.control
        case .pill: return StemcellTokens.Shape.Semantic.pill
        }
    }
}
