import SwiftUI
import StemcellTokens

/// 錨に対する開き方向（契約の `placement`。論理方向で持つ。layout.md §7）。
public enum PopoverPlacement: String, Sendable, CaseIterable {
    /// 下。既定。
    case blockEnd = "block-end"
    /// 上。
    case blockStart = "block-start"

    var arrowEdge: Edge {
        switch self {
        case .blockEnd: return .top
        case .blockStart: return .bottom
        }
    }
}

extension View {
    /// 錨に従属する一時の面（契約の `Popover`）。この修飾子を錨へ当てる。
    ///
    /// SwiftUI に `.popover` があるので、そこへ乗る。錨への位置決めも、外側を押したときの
    /// 退出も、Escape も、焦点を中へ入れて閉じたら錨へ戻すことも、native が持っている。
    /// 契約が Normative としているのはそこまでで（`overlay.md` §5 は衝突回避を Expressive、
    /// §7 は焦点の写像を rules に委ねる）、自前で書くのは面と角と縁だけである。
    ///
    /// 名前は `Dialog` と同じ理由で接頭辞を持つ。姿を当てる修飾子ではなく提示を足すもので、
    /// `.popover` という名は SwiftUI が既に使っている。
    ///
    /// 契約の `openchange` は `isPresented` の束縛一本へ畳む。SwiftUI の `.popover` が
    /// 外側を押したときも Escape のときも同じ束縛を落とすので、二つ目の口を作らない。
    ///
    /// - Parameters:
    ///   - isPresented: 開いているか。値であって状態ではない（overlay.md §6）。
    ///   - placement: 錨に対する優先の開き方向。既定は下。
    ///   - content: 浮かぶ面の中身。役は消費者が与える（契約の slots）。
    public func stemcellPopover<C: View>(
        isPresented: Binding<Bool>,
        placement: PopoverPlacement = .blockEnd,
        @ViewBuilder content: @escaping () -> C
    ) -> some View {
        modifier(StemcellPopoverModifier(
            isPresented: isPresented, placement: placement, popoverContent: content
        ))
    }
}

struct StemcellPopoverModifier<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    let placement: PopoverPlacement
    @ViewBuilder let popoverContent: () -> C

    func body(content: Content) -> some View {
        content.popover(
            isPresented: $isPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: placement.arrowEdge
        ) {
            PopoverSurface(content: popoverContent)
                // 狭い幅では SwiftUI が popover を sheet へ落とす。契約は錨への従属を
                // Normative としているので（slots.anchor が「Popover はこれに従属して位置を
                // 決める」）、落とさせない。
                .presentationCompactAdaptation(.popover)
        }
    }
}

/// 浮かぶ面。中身は消費者が与える。
struct PopoverSurface<C: View>: View {
    @ViewBuilder let content: () -> C

    @Environment(\.stemcellTheme) private var theme

    var body: some View {
        Box(inset: "md") {
            content()
        }
        .foregroundStyle(theme.colors.foreground.resolved)
        // 面は surface-raised の段である（elevation.md §5 の表）。
        .background(theme.colors.surfaceRaised.resolved)
        // 浮かぶ面は縁を持つ。影だけで浮かせると、強制配色で影が落ちたときに境界が消えて
        // 面と地が同じ色で溶ける（契約の a11y notes、elevation.md §3）。
        // 相互作用する部品の境界ではないので 3:1 は要らず、地との差が分かる最も薄い線でよい。
        .overlay {
            SuperellipseRoundedRectangle(
                cornerRadius: StemcellTokens.Shape.Continuous.Semantic.popover
            )
            .strokeBorder(theme.colors.divider.resolved, lineWidth: StemcellTokens.Shape.borderWidth)
        }
        .clipShape(SuperellipseRoundedRectangle(
            cornerRadius: StemcellTokens.Shape.Continuous.Semantic.popover
        ))
        // 影は二層である（elevation.md §4）。modal より一段浅い。
        .shadow(
            color: theme.colors.shadowPenumbra.resolved,
            radius: StemcellTokens.Elevation.Popover.level * 4,
            y: StemcellTokens.Elevation.Popover.level
        )
        .shadow(
            color: theme.colors.shadowUmbra.resolved,
            radius: StemcellTokens.Elevation.Popover.level,
            y: StemcellTokens.Elevation.Popover.level / 2
        )
        // 面の地を透かして自分で描く。native の地には縁を当てられない。
        .presentationBackground(.clear)
    }
}
