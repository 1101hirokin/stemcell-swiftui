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
    /// `layer.popover.z` は引いていない。native の提示は OS が層を持つので、z を差し込む
    /// 場所が構造として無い（overlay.md §7）。`Dialog` と同じ理由で、漏れではなく対象外である。
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Box(inset: "md") {
            content()
        }
        // 中身の高さを内容で止める。これが無いと、複数行の中身を渡したときに面が伸びて
        // 画面の端で切られ、角丸も縁も見えないまま本文がちぎれる。錨が下寄りにあるほど
        // 起きやすい。一行の中身では起きないので、気づきにくい。実機で見つかった。
        //
        // native は本来、余裕のある側へ向きを反転して収める。素の .popover ではそう動く。
        // 伸びた面がどちら向きでも画面を超えるので、その働きを潰していた。
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(theme.colors.foreground.resolved)
        // 面は surface-raised の段である（elevation.md §5 の表）。
        .background(theme.colors.surfaceRaised.resolved)
        .clipShape(SuperellipseRoundedRectangle(
            cornerRadius: StemcellTokens.Shape.Continuous.Semantic.popover
        ))
        // 浮かぶ面は縁を持つ。影だけで地から浮かせると、強制配色で影が落ちたときに境界が
        // 消えて面と地が同じ色で溶ける（契約の a11y notes、elevation.md §3）。
        // 相互作用する部品の境界ではないので 3:1 は要らず、地との差が分かる最も薄い線でよい。
        //
        // 切り取りの後ろへ置いている。前へ置いた版でも線を拾えなかったので移したが、
        // 順序が効いたのかは切り分けていない。実測では上端で EAEAEA を拾う。
        // トークンの E6E8EC を 1pt で白へ重ねた見え方と合う。影との区別は付きにくい。
        .overlay {
            SuperellipseRoundedRectangle(
                cornerRadius: StemcellTokens.Shape.Continuous.Semantic.popover
            )
            .strokeBorder(theme.colors.divider.resolved, lineWidth: StemcellTokens.Shape.borderWidth)
        }
        // 影は二層である（elevation.md §4）。modal より一段浅い。
        .stemcellShadow(level: StemcellTokens.Elevation.Popover.level, colors: theme.colors)
        // 面の地を透かして自分で描く。native の地には縁を当てられない。
        // ここで iOS 26 の既定であるガラスを手放している。`Dialog` と同じ判断で、
        // 理由も同じである（HOLES #15）。DESIGN.md §4 が挙げていた「ガラスの上のガラス」は、
        // 両方がガラスを捨てたので前提ごと無くなった。HOLES #18。
        .presentationBackground(.clear)
        // 出入りの時間を引く（契約の tokensRequired）。ただし native の提示が自分の
        // 出入りを持っていて、ここで書いた値がどこまで効くかは確かめていない。
        .transition(.opacity)
        .animation(transition, value: true)
    }

    /// 動きを減らす設定のときは時間を持たない。
    private var transition: Animation? {
        let d = reduceMotion
            ? StemcellTokens.Motion.None.duration
            : StemcellTokens.Motion.Entrance.duration
        return d == 0 ? nil : .easeOut(duration: d)
    }
}
