import SwiftUI
import StemcellTokens

/// 退出の仕方（Dialog.md、overlay.md §8 の裁定）。
public enum DialogDismiss: String, Sendable, CaseIterable {
    /// Escape と背後で閉じる。閲覧系の既定。
    case light
    /// ボタンでのみ閉じる。確認と破壊と未保存の欄で使う。
    case explicit
}

extension View {
    /// 中央に開く modal（契約の `Dialog`）。
    ///
    /// SwiftUI に `Dialog` の型が無いので修飾子で出す（DESIGN.md §2 の表）。
    /// 名前に接頭辞を付けたのは、これが姿を当てる修飾子ではないからである。§12 は
    /// 「姿を当てる修飾子は native の形に寄せる」と定めるが、ここは姿ではなく提示を足す。
    /// `.dialog` という一般名を stemcell が占めるのは行き過ぎだと自分は考えた。
    ///
    /// 土台は native の提示に置く。焦点を中へ移すこと、中に捕まえること、閉じたら元へ戻すこと、
    /// 背後を操作できなくすることは、どれも提示の機構が持っている（overlay.md §4 が
    /// 「捕捉の実現は表現である」と書いているところ）。自前の trap は持たない。
    /// ただし実機の VoiceOver で確かめてはいない。HOLES #14。
    ///
    /// 契約の `openchange` は別に持たない。`isPresented` の束縛一本へ畳んでいる。
    /// SwiftUI の `.sheet(isPresented:)` がその合成そのもので、幕を押しても Escape でも
    /// 同じ束縛が更新される。二つの口を作ると真実が二つになる（第2条）。
    ///
    /// `layer.modal.z` は引いていない。native の提示は OS が層を持つので、z を差し込む
    /// 場所が構造として無い（overlay.md §7 の表が「rank の外」と書いている）。
    /// 漏れではなく対象外である。
    ///
    /// - Parameters:
    ///   - isPresented: 開いているか。アプリが所有する値である（overlay.md §6）。
    ///   - dismiss: 退出の仕方。既定は `light`。
    ///   - title: 見出し。modal の名前になる。無名の modal は許さない（契約の slots）。
    ///   - content: 本体。
    ///   - actions: 脚の操作。`explicit` のときは閉じる手段をここに必ず置く。
    public func stemcellDialog<T: View, C: View, A: View>(
        isPresented: Binding<Bool>,
        dismiss: DialogDismiss = .light,
        @ViewBuilder title: @escaping () -> T,
        @ViewBuilder content: @escaping () -> C,
        @ViewBuilder actions: @escaping () -> A = { EmptyView() }
    ) -> some View {
        modifier(StemcellDialogModifier(
            isPresented: isPresented, dismiss: dismiss,
            title: title, content: content, actions: actions
        ))
    }
}

struct StemcellDialogModifier<T: View, C: View, A: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dismiss: DialogDismiss
    @ViewBuilder let title: () -> T
    @ViewBuilder let content: () -> C
    @ViewBuilder let actions: () -> A

    func body(content base: Content) -> some View {
        #if os(iOS)
        base.fullScreenCover(isPresented: $isPresented) {
            DialogSurface(dismiss: dismiss, isPresented: $isPresented,
                          title: title, content: self.content, actions: actions)
                // 覆いの地を透かして、幕と札を自分で描く。契約は幕を要求しており
                // （tokensRequired の scrim）、覆いの既定の地では色が指定できない。
                .presentationBackground(.clear)
        }
        // 退出を止めるのは native の口がある。ただし iOS の fullScreenCover は下へ引く
        // 仕草をそもそも持たないので、ここは効いていない見込みが高い。macOS の sheet では
        // 効く。無害なので両方に置いてあるが、iOS で意味を持つかは確かめていない。
        .interactiveDismissDisabled(dismiss == .explicit)
        #else
        base.sheet(isPresented: $isPresented) {
            DialogSurface(dismiss: dismiss, isPresented: $isPresented,
                          title: title, content: self.content, actions: actions)
                .presentationBackground(.clear)
        }
        .interactiveDismissDisabled(dismiss == .explicit)
        #endif
    }
}

/// 幕と札。覆いの中身として描く。
struct DialogSurface<T: View, C: View, A: View>: View {
    let dismiss: DialogDismiss
    @Binding var isPresented: Bool
    @ViewBuilder let title: () -> T
    @ViewBuilder let content: () -> C
    @ViewBuilder let actions: () -> A

    @Environment(\.stemcellTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // 幕。色は elevation.md §6 が定める単一のもので、多重に重ねない。
            theme.colors.scrim.resolved
                .ignoresSafeArea()
                .onTapGesture {
                    // light だけが背後で閉じる。explicit は無視する（契約の dismiss）。
                    if dismiss == .light { isPresented = false }
                }
                // 幕そのものは読み上げに要らない。閉じる手段は札の中に置く。
                .accessibilityHidden(true)

            Box(inset: "lg") {
                Stack(gap: "md", align: .start) {
                    title().textStyle(.titleMd)
                    content().textStyle(.bodyMd)
                    // 脚は空でも行として置く。前は `A.self != EmptyView.self` で判定していたが、
                    // あれは既定値を渡したときにしか当たらない。消費者が `if` を一つ書くと
                    // ViewBuilder が `EmptyView` ではない型を作るので、中身が無くても真になり、
                    // Spacer だけの行が残る。空の行は高さを持たないので、判定をやめた。
                    Stack(direction: .inline, gap: "md", align: .center) {
                        Spacer(minLength: 0)
                        actions()
                    }
                }
                // 字の色はテーマから引く。`.textStyle()` は大きさと太さと行の箱だけを持ち、
                // 色は持たない。当てないと SwiftUI の既定（純黒）になり、消費者がテーマを
                // 差し替えても追随しない。
                .foregroundStyle(theme.colors.foreground.resolved)
            }
            // 面は overlay の段である（elevation.md §5 の表。modal と notification が共有する）。
            // surface は navigation と共有する別の段で、明るいテーマでは同値になるが
            // 暗いテーマでは別の色になる。最初 surface を引いていて、暗いほうで間違えていた。
            .background(theme.colors.overlay.resolved)
            .clipShape(SuperellipseRoundedRectangle(
                cornerRadius: StemcellTokens.Shape.Continuous.Semantic.dialog
            ))
            // 影は二層である（elevation.md §4）。色と不透明度はトークンが持つ。
            // 幕の色を薄めて代用していたが、幕は既に 0.4 を持つので実効が 0.07 まで落ちて
            // 影として立っていなかった。レベルから半径と下げ幅を導くのは §7 のとおり。
            .stemcellShadow(level: StemcellTokens.Elevation.Modal.level, colors: theme.colors)
            // 読みやすい上限で止める。伸びるのは縦だけである（契約の expressive）。
            .frame(maxWidth: 420)
            .padding(StemcellTokens.Spacing.Inset.lg)
            // 見出しと中身と脚を一つの塊として読み上げへ届ける。
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
        .animation(isPresented ? entrance : exit, value: isPresented)
    }

    /// 入りと出で段が違う（契約の tokensRequired が motion.entrance と motion.exit を
    /// 別に挙げている）。出るほうが速い。
    ///
    /// ただし覆いそのものの出入りは native の提示が握っていて、ここで書いた時間が
    /// どこまで効くかは確かめていない。幕と札の不透明度には効く。
    private var entrance: Animation? { animation(StemcellTokens.Motion.Entrance.duration) }
    private var exit: Animation? { animation(StemcellTokens.Motion.Exit.duration) }

    /// 動きを減らす設定のときは時間を持たない。
    private func animation(_ seconds: TimeInterval) -> Animation? {
        let d = reduceMotion ? StemcellTokens.Motion.None.duration : seconds
        return d == 0 ? nil : .easeOut(duration: d)
    }
}
