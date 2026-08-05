import SwiftUI
import StemcellTokens

/// ファイルを落とせる面（契約の `DropArea`）。落ちたものを知らせるだけで、値は持たない。
///
/// 値を持たせると、同じ値が欄と面の二箇所に現れる。持つのは `FileField` かアプリである。
/// だから面を欄から離れた場所（画面全体、面の上、表の中）へ置ける。
///
/// SwiftUI に相当する部品が無いので型で出す（DESIGN.md §2）。
///
/// 落として入れる形だけでは、ポインタを引きずれない利用者に届かない。押して選べる手段を
/// 併置することが Normative である（WCAG 2.2 SC 2.5.7）。本部品はその手段を内側に持たない。
/// 面の中へ選べるものを置く形を契約が推奨している。持たない理由は、面と欄を分けた理由と
/// 同じで、合成の自由を残すためである。
///
/// 落ちてくる最中は状態である（RFC 0022）。何も持たずに通り過ぎたときと、持って止まった
/// ときとで次に起きることが違うので、`hover` とは別の語彙になっている。SwiftUI はこれを
/// 無償で持っている。`dropDestination` の `isTargeted` がそのまま `dragover` である。
///
/// Web は子の上で `dragleave` が飛ぶので出入りの深さを数えているが、こちらは数えていない。
/// ドロップ先はビューの枠へのヒットテストで決まるので同じ問題は起きない、というのが
/// 数えなかった理由である。ただし実際にドラッグして確かめてはいない。中へ別の
/// `dropDestination` を持つ子を置いたときの挙動も見ていない（HOLES #27）。
///
/// 落ちてきた URL がセキュリティスコープ付きかどうかも見ていない。`fileImporter` から
/// 得た URL は `startAccessingSecurityScopedResource` の対で囲むのが Apple の作法だが、
/// `dropDestination` から来た URL に同じ作法が要るかを確かめていない。要るなら、それは
/// 受け取った側の仕事になる。面は値を持たないので、開いて読むのは常にアプリである。
public struct DropArea<Content: View>: View {
    private let accept: [String]?
    private let label: String?
    private let onDrop: ([URL]) -> Void
    private let onReject: ([URL]) -> Void
    private let content: Content

    /// - Parameters:
    ///   - accept: 受け入れる種類（MIME 型の列）。語彙は `FileField` と同じ。渡さなければ
    ///     何でも受ける。
    ///   - label: 面の名前。中の文言を名前として使えないときに渡す。名前の無い面は許さない
    ///     （WCAG 2.2 SC 1.3.1 / 3.3.2）。
    ///   - onDrop: ファイルが落ちた。受け取った側が値へ足す。
    ///   - onReject: `accept` に合わないものが落ちた。件数を耳へ届けるのは値を持つ側の
    ///     仕事である。面は自分が何件受け取ったかしか知らない。
    ///   - content: 面の中身。押して選べる手段をここへ置く。
    public init(
        accept: [String]? = nil,
        label: String? = nil,
        onDrop: @escaping ([URL]) -> Void,
        onReject: @escaping ([URL]) -> Void = { _ in },
        @ViewBuilder content: () -> Content
    ) {
        self.accept = accept
        self.label = label
        self.onDrop = onDrop
        self.onReject = onReject
        self.content = content()
    }

    @Environment(\.stemcellTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var targeted = false

    /// 落ちてくる最中。使えないときは出さない（state.md §3.2。使えないものは相互作用の
    /// 状態を出さない）。
    private var dragover: Bool { targeted && isEnabled }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(StemcellTokens.Spacing.Inset.md)
            .background(surface)
            .clipShape(shape)
            .overlay { shape.strokeBorder(border, style: strokeStyle) }
            .animation(transition, value: dragover)
            // 使えないときにここを止めているが、`.disabled()` が native の側でドロップ
            // そのものを止めるなら、この番人は通らない。どちらかは確かめていない
            // （HOLES #27）。二重でも害は無いので置いてある。
            .dropDestination(for: URL.self) { urls, _ in
                guard isEnabled else { return false }
                let (accepted, rejected) = AcceptList.split(urls, accept: accept)
                if !accepted.isEmpty { onDrop(accepted) }
                if !rejected.isEmpty { onReject(rejected) }
                // 弾いたものも受け取ってはいる。false を返すと環境が「落とせなかった」
                // 動きを返すので、落ちた事実は知らせたうえで true を返す。
                return !urls.isEmpty
            } isTargeted: { targeted = $0 }
            // 面そのものは焦点を受けない（契約の a11y notes。`focusRing: false`）。
            // 焦点を受けるのは中に置かれた操作である。まとまりとして名前を持たせ、
            // 中身は読める形で残す。
            .accessibilityElement(children: .contain)
            // 名前は渡されたときだけ当てる。`label ?? ""` と書くと、渡されなかったときに
            // 「名前は空である」と積極的に言うことになる。契約は中の文言を名前として使う
            // 道を残しているので、黙っているほうが正しい。
            .accessibilityLabel(label.map(Text.init) ?? Text(verbatim: ""))
    }

    /// 常のときは薄い地、落ちてくる最中は primary の薄い地。造形は Expressive である。
    private var surface: Color {
        if !isEnabled { return DisabledColors.softBg.resolved }
        if dragover { return StemcellIntent.primary.colors.softBg.resolved }
        return StemcellIntent.plain.colors.softBg.resolved
    }

    private var border: Color {
        if !isEnabled { return DisabledColors.border.resolved }
        if dragover { return StemcellIntent.primary.colors.border.resolved }
        // 常のときは地の縁である。契約の `tokensRequired` が `color.app.border` を名指し、
        // svelte も `var(--color-app-border)` を引いている。`plain.border` はいま同じ値を
        // 持っているので見た目では区別が付かないが、値が同じことは名前が同じ理由にならない。
        return theme.colors.border.resolved
    }

    /// 常のときは点線、落ちてくる最中だけ実線にする。囲いであることと、いま受け取れることを
    /// 形でも言う（svelte と同じ表現を選んだ）。
    private var strokeStyle: StrokeStyle {
        let w = StemcellTokens.Shape.borderWidth
        // 点線の刻みはトークンが無い。CSS の `dotted` に相当するものが SwiftUI に無いので、
        // 丸い端で長さをほぼ 0 にし、空きを線幅の二倍に取って点を並べている。0 は使えないので
        // 0.01 を置く。造形は Expressive なので、契約が値を持っていないのは正しい。
        return dragover
            ? StrokeStyle(lineWidth: w)
            : StrokeStyle(lineWidth: w, lineCap: .round, dash: [0.01, w * 2])
    }

    private var shape: SuperellipseRoundedRectangle {
        SuperellipseRoundedRectangle(cornerRadius: StemcellTokens.Shape.Continuous.Semantic.control)
    }

    private var transition: Animation? { StemcellMotion.feedback(reduceMotion) }
}
