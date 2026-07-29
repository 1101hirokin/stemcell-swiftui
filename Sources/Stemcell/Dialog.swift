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
        // 退出を止めるのは native の口がある。explicit は下へ引いても閉じない。
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
                    if A.self != EmptyView.self {
                        Stack(direction: .inline, gap: "md", align: .center) {
                            Spacer(minLength: 0)
                            actions()
                        }
                    }
                }
            }
            .background(theme.colors.surface.resolved)
            .clipShape(SuperellipseRoundedRectangle(
                cornerRadius: StemcellTokens.Shape.Continuous.Semantic.dialog
            ))
            .shadow(
                color: theme.colors.scrim.resolved.opacity(0.18),
                radius: StemcellTokens.Elevation.Modal.level * 4,
                y: StemcellTokens.Elevation.Modal.level
            )
            // 読みやすい上限で止める。伸びるのは縦だけである（契約の expressive）。
            .frame(maxWidth: 420)
            .padding(StemcellTokens.Spacing.Inset.lg)
            // 見出しと中身と脚を一つの塊として読み上げへ届ける。
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
        .animation(entrance, value: isPresented)
    }

    /// 入りは entrance の段を引く。動きを減らす設定のときは時間を持たない。
    private var entrance: Animation? {
        let d = reduceMotion
            ? StemcellTokens.Motion.None.duration
            : StemcellTokens.Motion.Entrance.duration
        return d == 0 ? nil : .easeOut(duration: d)
    }
}
