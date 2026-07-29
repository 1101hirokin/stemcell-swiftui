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
        Toggle(isOn: configuration.$isOn) { configuration.label }
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

    @Environment(\.stemcellTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: StemcellTokens.Spacing.Inline.sm) {
                mark(on: configuration.isOn)
                configuration.label
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        // 値が届くのは Normative。三値なので aria-checked の mixed にあたるものを持つ。
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
        .accessibilityValue(indeterminate ? "混在" : (configuration.isOn ? "オン" : "オフ"))
    }

    @ViewBuilder
    private func mark(on: Bool) -> some View {
        let filled = on || indeterminate
        RoundedRectangle(cornerRadius: StemcellTokens.Shape.Semantic.selection, style: .continuous)
            .fill(filled ? theme.colors.primaryBackground.resolved : Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: StemcellTokens.Shape.Semantic.selection, style: .continuous)
                    .strokeBorder(
                        filled ? theme.colors.primaryBackground.resolved : theme.colors.border.resolved,
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

    /// 第三の値を持つ印。
    public static func stemcellCheckbox(indeterminate: Bool) -> StemcellCheckboxToggleStyle {
        .init(indeterminate: indeterminate)
    }
}
