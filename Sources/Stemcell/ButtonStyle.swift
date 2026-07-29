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
            .padding(.vertical, size.inset)
            .padding(.horizontal, size.inset * 2)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            // iOS の当たり判定の床は 44pt（size.md §4）。トークンが存在しないので数を直に書く。
            // size.md §7 が「最低基準の値は foundations にも @stemcell/tokens にも無い」と
            // 未確定にしているところで、HOLES #4 に記録した。
            .frame(minWidth: 44, minHeight: 44)
            .foregroundStyle(foreground(c).resolved)
            .background(background(c, pressed: pressed))
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay {
                if variant == .outlined {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(c.border.resolved, lineWidth: StemcellTokens.Shape.borderWidth)
                }
            }
            .opacity(isEnabled ? 1 : 0.5)
    }

    private func foreground(_ c: IntentColors) -> DynamicColor {
        variant == .filled ? c.fg : c.softFg
    }

    @ViewBuilder
    private func background(_ c: IntentColors, pressed: Bool) -> some View {
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
            fullWidth: fullWidth, corner: StemcellTokens.Shape.Semantic.control
        )
    }

    /// 絵だけのボタン（IconButton）。名前は `.accessibilityLabel` で渡す。
    /// 契約は `label` を必須にしているが、SwiftUI では到達性の修飾子がその口である。
    public static func stemcellIcon(
        _ variant: StemcellVariant = .text,
        color intent: StemcellIntent = .plain,
        size: StemcellSize = .md,
        shape: StemcellIconButtonShape = .control
    ) -> StemcellButtonStyle {
        StemcellButtonStyle(
            variant: variant, intent: intent, size: size,
            fullWidth: false, corner: shape.corner
        )
    }
}

/// 絵だけのボタンの角（IconButton の `shape`）。
public enum StemcellIconButtonShape: String, Sendable, CaseIterable {
    case control, pill

    var corner: CGFloat {
        switch self {
        case .control: return StemcellTokens.Shape.Semantic.control
        case .pill: return StemcellTokens.Shape.Semantic.pill
        }
    }
}
