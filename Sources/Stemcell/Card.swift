import SwiftUI
import StemcellTokens

/// 地の上の面（契約の `Card`）。内容をまとめて一枚に見せる。それ自体は何もしない。
///
/// SwiftUI に `Card` の型が無いので、契約の名前で型を出す（DESIGN.md §2 の 70 個の側）。
///
/// 押せる `Card` は作らない。契約の裁定である。全面が押せると、操作が二つ以上あるときに
/// 「全面」がどの操作なのかを視覚から読めない。押す責任は中の要素が持つ。
/// だから `Button` で包む口も、押されたことを受ける引数も置いていない。押せないことは
/// 引数を持たせないことで型が保証するので、試験で言い直していない。
public struct Card<Content: View>: View {
    /// 枠の面にするか。既定は影の面である。
    ///
    /// `variant` と呼ばないのは、あの名前が強調度の四段に予約されているからだけではない。
    /// 強調度の配線は `color.semantic.{intent}.*` を前提にしていて、intent を持たない
    /// `Card` には仕組みごと当てられない（契約の設計意図）。
    private let outlined: Bool
    private let content: Content

    public init(outlined: Bool = false, @ViewBuilder content: () -> Content) {
        self.outlined = outlined
        self.content = content()
    }

    @Environment(\.stemcellTheme) private var theme

    public var body: some View {
        content
            .padding(StemcellTokens.Spacing.Inset.md)
            // 面は surface の段である（elevation.md §5 の表）。
            .background(theme.colors.surface.resolved)
            .clipShape(shape)
            .overlay {
                if outlined {
                    // 枠の面は影を持たず、縁で地から分ける。
                    shape.strokeBorder(
                        theme.colors.border.resolved,
                        lineWidth: StemcellTokens.Shape.borderWidth
                    )
                }
            }
            // 影の面は二層で浮かせる（elevation.md §4）。枠の面は影を持たない。
            .stemcellShadow(level: outlined ? 0 : StemcellTokens.Elevation.Surface.level,
                            colors: theme.colors)
    }

    private var shape: SuperellipseRoundedRectangle {
        SuperellipseRoundedRectangle(
            cornerRadius: StemcellTokens.Shape.Continuous.Semantic.card
        )
    }
}
