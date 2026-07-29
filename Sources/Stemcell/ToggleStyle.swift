import SwiftUI
import StemcellTokens

/// 契約の `Switch` は SwiftUI の `Toggle` へ写る（DESIGN.md §2）。
///
/// 自分で描かない。SwiftUI の `Toggle` は鍵盤とスイッチコントロールの操作も、VoiceOver の
/// 「オン、スイッチ、ダブルタップで切り替え」も、触覚も無償で持っている。既定の姿は
/// `.switch` のままで、色だけを stemcell の役へ寄せる。
public struct StemcellSwitchToggleStyle: ToggleStyle {
    @Environment(\.stemcellTheme) private var theme

    public func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            // native の版は狭いと札が一気に消える。折り返さず省略へ倒す。
            configuration.label
                .lineLimit(1)
                .truncationMode(.tail)
        }
            .toggleStyle(.switch)
            .tint(theme.colors.primaryBackground.resolved)
    }
}

/// 契約の `Checkbox`。SwiftUI に四角い印の様式が無いので、印だけを自前で描く。
///
/// `Toggle` に載せるのは、値の所有も鍵盤の操作も読み上げも native に任せるためである。
/// 描くのは印の姿だけで、押せることや状態が届くことは `Toggle` が持つ。
public struct StemcellCheckboxToggleStyle: ToggleStyle {
    /// 第三の値（`indeterminate`）。値であって状態ではない（state.md §6）。
    var indeterminate: Bool = false
    /// 第三の値を支援技術へ言うときの言葉。DS は文言を持たない（i18n.md §1）。
    var mixedValueLabel: String?

    @Environment(\.stemcellTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: StemcellTokens.Spacing.Inline.sm) {
                mark(on: configuration.isOn)
                // 札は折り返さない。狭いときに一文字ずつ縦へ伸びていた（実測で 12 行）。
                configuration.label
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            // 当たり判定の床は Button と同じ形で置く。ここにだけ無かった。
            // 印は 16pt しかないので、札が短いと押せる範囲が 24pt ほどしか無かった。
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // 使えないものは相互作用の状態を出さない（state.md §3.2）。
        .onHover { hovering = isEnabled && $0 }
        .animation(transition, value: hovering)
        .animation(transition, value: configuration.isOn)
        // 役は checkbox である（契約）。guidelines/accessibility.md の写像表は
        // checkbox を .isToggle へ写すと定めている。radio の処方（.isButton + .isSelected）を
        // 当てると VoiceOver が「ボタン、選択済み」と読み、役が違って届く。
        .accessibilityAddTraits(.isToggle)
        // 値の言い回しは DS が持たない（i18n.md §1）。三値のときだけ、native が言えない
        // 「どちらでもない」を消費者から受け取って添える。
        .accessibilityValue(indeterminate ? (mixedValueLabel.map(Text.init) ?? Text(verbatim: "")) : Text(verbatim: ""))
    }

    /// 使えないときは intent ごと差し替える（state.md §7）。
    private var markFill: Color {
        guard isEnabled else { return DisabledColors.bg.resolved }
        // 面のチャンネル。触れているあいだは濃くする（state.md §3.3）。
        return (hovering
            ? StemcellIntent.primary.colors.bgHover
            : theme.colors.primaryBackground).resolved
    }

    private var transition: Animation? {
        let d = reduceMotion
            ? StemcellTokens.Motion.None.duration
            : StemcellTokens.Motion.Duration.fast02
        return d == 0 ? nil : .easeOut(duration: d)
    }

    @ViewBuilder
    private func mark(on: Bool) -> some View {
        let filled = on || indeterminate
        SuperellipseRoundedRectangle(cornerRadius: StemcellTokens.Shape.Continuous.Semantic.selection)
            .fill(filled ? markFill : Color.clear)
            .overlay {
                SuperellipseRoundedRectangle(cornerRadius: StemcellTokens.Shape.Continuous.Semantic.selection)
                    .strokeBorder(
                        filled ? markFill : (isEnabled ? theme.colors.border : DisabledColors.border).resolved,
                        lineWidth: StemcellTokens.Shape.borderWidth
                    )
            }
            .overlay {
                Image(systemName: indeterminate ? "minus" : "checkmark")
                    .font(.system(size: StemcellTokens.Selection.markSize, weight: .bold))
                    .foregroundStyle(theme.colors.primaryForeground.resolved)
                    .opacity(filled ? 1 : 0)
            }
            .frame(width: StemcellTokens.Selection.size, height: StemcellTokens.Selection.size)
    }
}

extension ToggleStyle where Self == StemcellSwitchToggleStyle {
    /// 入り切りのつまみ（契約の `Switch`）。
    public static var stemcellSwitch: StemcellSwitchToggleStyle { .init() }
}

extension ToggleStyle where Self == StemcellCheckboxToggleStyle {
    /// 四角い印（契約の `Checkbox`）。
    public static var stemcellCheckbox: StemcellCheckboxToggleStyle { .init() }

    /// 第三の値を持つ印。言葉は消費者が渡す（i18n.md §1）。
    public static func stemcellCheckbox(
        indeterminate: Bool,
        mixedValueLabel: String? = nil
    ) -> StemcellCheckboxToggleStyle {
        .init(indeterminate: indeterminate, mixedValueLabel: mixedValueLabel)
    }
}
