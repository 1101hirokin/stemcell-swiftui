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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    public func body(content: Content) -> some View {
        HStack(spacing: StemcellTokens.Spacing.Inline.md) {
            start
            content
                // 値の場所を先に譲らない。前後のものは装飾で、中身は値である。
                // 優先の指定が無いと、狭いときに潰れるべきでない中身が先に消え、
                // 固定寸法のアイコンが満寸のまま親をはみ出した（実測で 14pt）。
                .layoutPriority(1)
                .textFieldStyle(.plain)
                // 読むだけは打てない。ARIA は readonly を「編集はできないが、それ以外は
                // 操作できる」と定め、Web は HTML の readonly 属性がそのまま持っている。
                // SwiftUI の TextField にその状態が無いので、中身だけを無効にして打てなく
                // する。焦点を受けられなくなるぶん「それ以外は操作できる」を満たせない。
                // HOLES #8 に記録した。
                //
                // 無効にするのは content だけである。囲いは無効にしない。面と枠の色は
                // 上の isEnabled から引いており、読むだけと使えないことは別のままにする
                // （state.md §6）。
                .disabled(readOnly)
                // .disabled() は字も灰へ落とす。それだと読むだけが使えないものと同じ姿に
                // なり、§6 が別だと定めているものが見分けられなくなる。実際に一度そうなった。
                // 打てないことだけを借りて、字の色は地の字色へ戻す。
                .foregroundStyle(contentForeground)
            end
        }
            .padding(size.inset)
            // 床は幅にも要る。Button は minWidth も持っているのに、ここは高さだけだった。
            .frame(minWidth: 44, minHeight: 44) // size.md §4。トークンが無い。HOLES #4
            .background(surface)
            .clipShape(SuperellipseRoundedRectangle(cornerRadius: StemcellTokens.Shape.Continuous.Semantic.control))
            .overlay {
                SuperellipseRoundedRectangle(cornerRadius: StemcellTokens.Shape.Continuous.Semantic.control)
                    .strokeBorder(borderColor, lineWidth: StemcellTokens.Shape.borderWidth)
            }
            // 使えないものは相互作用の状態を出さない（state.md §3.2）。
            .onHover { hovering = isEnabled && $0 }
            .animation(transition, value: hovering)
    }

    /// 読むだけの字色。打てないことだけを .disabled() から借り、灰へ落ちるのを打ち消す。
    /// 使えないときは灰のままでよい。そちらは本当に無効だからである。
    private var contentForeground: Color {
        isEnabled ? theme.colors.foreground.resolved : DisabledColors.fg.resolved
    }

    private var transition: Animation? { StemcellMotion.feedback(reduceMotion) }


    /// 不正は intent を danger へ差し替える（state.md §7）。判定はアプリが持つ。
    /// 読むだけは無効ではない。枠は残し、面だけを地へ寄せて「打てない」と見せる。
    private var surface: Color {
        if !isEnabled { return DisabledColors.softBg.resolved }
        if readOnly { return theme.colors.background.resolved }
        // 面のチャンネル。読むだけの欄はホバーに応えない。打てないものに反応を返さない。
        if hovering && !readOnly { return StemcellIntent.plain.colors.softBgHover.resolved }
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
