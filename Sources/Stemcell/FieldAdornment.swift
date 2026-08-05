import SwiftUI
import StemcellTokens

/// 欄に付く押せる付属（伏せる切り替え、消す、増減）の姿。svelte の `internal/field-button`
/// にあたる。公開しないのは、消費者が単体で置くものではないからである。付属を持つ部品が
/// 自分の中で使う。
///
/// 四角い正方形にするのは裁定（2026-07-28）である。押せる面が縦長だと欄の縁の飾りに見え、
/// 押す場所が読めない。角を丸めないのも同じ裁定で、欄の中の付属は部品の縁の内側に収まる
/// ので、自分で丸めると部品の曲がりとずれて隙間が出る。
///
/// `IconButton` は使えない。あちらの `shape` は契約が `control` と `pill` しか許して
/// いないので（発明不可）、角を持たない付属をあの型では表せない。
struct FieldAdornmentButtonStyle: ButtonStyle {
    /// 正方形の一辺。欄の行高である。持ち主が組み立てて渡す。
    let side: CGFloat

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled
                ? StemcellIntent.plain.colors.softFg.resolved
                : DisabledColors.fg.resolved)
            .frame(width: side, height: side)
            .background(background(pressed: configuration.isPressed))
            // 押せる範囲の床は見える正方形とは別に敷く（size.rules.json の
            // `appliesTo: hit-region`）。段が sm のとき一辺は 44 を下回るが、
            // 押せる範囲は下回らせない。
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .onHover { hovering = isEnabled && $0 }
            .animation(transition, value: hovering)
            .animation(transition, value: configuration.isPressed)
    }

    private func background(pressed: Bool) -> Color {
        guard isEnabled else { return .clear }
        let c = StemcellIntent.plain.colors
        if pressed { return c.softBgPressed.resolved }
        if hovering { return c.softBgHover.resolved }
        return .clear
    }

    private var transition: Animation? { StemcellMotion.feedback(reduceMotion) }
}
