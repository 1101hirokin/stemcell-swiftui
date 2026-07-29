import SwiftUI
import StemcellTokens

/// 契約の `TextField` の姿（field.md §2 の解剖）。
///
/// SwiftUI の `TextFieldStyle` には手が出せない。protocol の要求が underscore 付きで、
/// 外から実装できないためである。`.buttonStyle` や `.toggleStyle` のようには乗れないので、
/// 修飾子で出す。名前は姿を当てる側なので native の形に寄せる（DESIGN.md §12）。
public struct StemcellFieldStyle<Start: View, End: View>: ViewModifier {
    var size: StemcellSize
    var invalid: Bool
    /// 読むだけ。使えないこととは違う（state.md §6）。焦点は受け、文字は選べる。
    var readOnly: Bool
    var start: Start
    var end: End

    @Environment(\.stemcellTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public func body(content: Content) -> some View {
        HStack(spacing: StemcellTokens.Spacing.Inline.md) {
            start
            content.textFieldStyle(.plain)
            end
        }
            .padding(size.inset)
            .frame(minHeight: 44) // 当たり判定の床（size.md §4）。トークンが無い。HOLES #4
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: StemcellTokens.Shape.Semantic.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: StemcellTokens.Shape.Semantic.control, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: StemcellTokens.Shape.borderWidth)
            }
    }

    /// 不正は intent を danger へ差し替える（state.md §7）。判定はアプリが持つ。
    /// 読むだけは無効ではない。枠は残し、面だけを地へ寄せて「打てない」と見せる。
    private var surface: Color {
        if !isEnabled { return DisabledColors.softBg.resolved }
        if readOnly { return theme.colors.background.resolved }
        return theme.colors.surface.resolved
    }

    private var borderColor: Color {
        // 使えないほうが強い。同じ面を争うので優先順位が要る（state.md §3）。
        if !isEnabled { return DisabledColors.border.resolved }
        // 読むだけは無効ではない。枠は残し、面だけを地に寄せる（state.md §6）。
        return invalid
            ? StemcellIntent.danger.colors.border.resolved
            : theme.colors.border.resolved
    }
}

extension View {
    /// 欄の姿を当てる。契約の `TextField` はここへ写る。
    ///
    /// 契約の `disabled` は `.disabled()`、`value` は SwiftUI の束縛、`placeholder` は
    /// `TextField` の第一引数、`keyboard` は `.keyboardType()`、`autocomplete` は
    /// `.textContentType()` が持つ。どれも native に口があるので引数にしない。
    public func fieldStyle(
        size: StemcellSize = .md,
        invalid: Bool = false,
        readOnly: Bool = false
    ) -> some View {
        modifier(StemcellFieldStyle(
            size: size, invalid: invalid, readOnly: readOnly,
            start: EmptyView(), end: EmptyView()
        ))
    }

    /// 欄の前後にものを置く（契約の `start` / `end` スロット）。あいだの間隔は部品が持つ。
    public func fieldStyle<S: View, E: View>(
        size: StemcellSize = .md,
        invalid: Bool = false,
        readOnly: Bool = false,
        @ViewBuilder start: () -> S,
        @ViewBuilder end: () -> E = { EmptyView() }
    ) -> some View {
        modifier(StemcellFieldStyle(
            size: size, invalid: invalid, readOnly: readOnly,
            start: start(), end: end()
        ))
    }
}
