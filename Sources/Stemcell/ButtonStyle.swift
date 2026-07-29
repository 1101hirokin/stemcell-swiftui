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

    public func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration, style: self)
    }
}

extension StemcellButtonStyle {
    /// 状態を持つので View に分ける。`ButtonStyle` は struct なので `@State` を置けない。
    fileprivate struct Surface: View {
        let configuration: Configuration
        let style: StemcellButtonStyle

        // 無効は契約の prop ではなく環境から来る。SwiftUI の .disabled() が正であり、
        // 部品が別の道を作ると二つの真実ができる（第2条: native の機構で満たす）。
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var hovering = false

        var body: some View {
            let variant = style.variant
            let size = style.size
            let corner = style.corner
            let c = style.intent.colors
            let pressed = configuration.isPressed

            configuration.label
                // 字の役は label-lg である（contracts/Button/contract.json の
                // tokensRequired が typography.label-lg を挙げている）。段では変えない。
                // Web も全段で label-lg を当てている。
                //
                // 前の版は役を一つも当てておらず、周囲の既定（.body の 17pt）で組んでいた。
                // Web と並べて高さが違うことから見つかった。lg で 52.5pt と 50.68px に割れる。
                .textStyle(.labelLg)
                // 折り返さない。入りきらないときは省略記号で切る。
                // 主要 DS を一次資料で当たると、一行に保つ側が多数で、そのうち省略を選ぶのが
                // Material 3 の実装と UIKit の古典と Atlaskit である。SwiftUI の既定は
                // lineLimit が nil で折り返すが、それは Apple の作法ではない。UILabel の既定は
                // numberOfLines 1 の byTruncatingTail で、Apple の中でも割れている。
                //
                // 折り返しを許さないのは、どこで折るかが言語依存になり、CJK と欧文で意味が
                // 変わるからである。三つの土地で一意に実装できなくなる。
                //
                // 実害も見た。横の余白が md で左右 48pt を無条件に食うので、親がそれを下回ると
                // 字の有効幅が 0 になり、文字が一つも描かれないまま高さだけが伸びていた。
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.vertical, size.inset)
                .padding(.horizontal, size.inset * 2)
                // 枠の太さぶんを箱へ足す。Web は border: 1px solid transparent を全段に
                // 置いていて、outlined と filled で箱が揃うようにしている。SwiftUI の
                // strokeBorder は重ねなので箱を増やさず、そのぶん低くなっていた（実測 2pt）。
                .padding(StemcellTokens.Shape.borderWidth)
                .frame(maxWidth: style.fullWidth ? .infinity : nil)
                .foregroundStyle(foreground(c, variant: variant).resolved)
                .background(surface(c, variant: variant, pressed: pressed))
                .clipShape(SuperellipseRoundedRectangle(cornerRadius: corner))
                .overlay {
                    if variant == .outlined {
                        SuperellipseRoundedRectangle(cornerRadius: corner)
                            .strokeBorder(borderColor, lineWidth: StemcellTokens.Shape.borderWidth)
                    }
                }
                // 使えないものは相互作用の状態を出さない（state.md §3.2）。
                // ここは論理的必然ではなく規範で、実装が明示的に満たす要がある。
                .onHover { hovering = isEnabled && $0 }
                .animation(transition, value: hovering)
                .animation(transition, value: pressed)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }

        /// 状態の移りは速い側の段を引く。動きを減らす設定のときは時間を持たない
        /// （トークンが Motion.None を秒で出している）。
        private var transition: Animation? {
            let d = reduceMotion
                ? StemcellTokens.Motion.None.duration
                : StemcellTokens.Motion.Duration.fast02
            return d == 0 ? nil : .easeOut(duration: d)
        }

        private func foreground(_ c: IntentColors, variant: StemcellVariant) -> DynamicColor {
            // 使えないときは intent ごと差し替える（state.md §7）。薄めない。
            guard isEnabled else { return variant == .filled ? DisabledColors.fg : DisabledColors.softFg }
            return variant == .filled ? c.fg : c.softFg
        }

        private var borderColor: Color {
            isEnabled ? style.intent.colors.border.resolved : DisabledColors.border.resolved
        }

        /// 面のチャンネル。pressed が hover に勝つ（state.md §3.3）。
        /// 連続ホバーを持つ入力では押下が必ずホバーを含むので、より限定的なほうを採る。
        @ViewBuilder
        private func surface(_ c: IntentColors, variant: StemcellVariant, pressed: Bool) -> some View {
            if !isEnabled {
                // 押された姿も、ホバーの姿も持たない。使えないものは操作できない。
                switch variant {
                case .filled: DisabledColors.bg.resolved
                case .soft: DisabledColors.softBg.resolved
                case .outlined, .text: Color.clear
                }
            } else {
                switch variant {
                case .filled:
                    (pressed ? c.bgPressed : hovering ? c.bgHover : c.bg).resolved
                case .soft:
                    (pressed ? c.softBgPressed : hovering ? c.softBgHover : c.softBg).resolved
                case .outlined, .text:
                    // 面を持たない強調度は、触れたときだけ面を得る（emphasis.md §4）。
                    if pressed {
                        c.softBgPressed.resolved
                    } else if hovering {
                        c.softBgHover.resolved
                    } else {
                        Color.clear
                    }
                }
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
