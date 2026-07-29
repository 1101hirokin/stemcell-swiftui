import SwiftUI
import StemcellTokens

/// 欄の解剖（field.md §2）。名前と説明とエラーを欄の周りに立て、支援技術へ配線する。
///
/// SwiftUI に相当する部品が無いので型で出す（DESIGN.md §2）。`LabeledContent` は
/// 名前と値を横に並べるためのもので、説明とエラーを持たない。
///
/// 名前は必須である。契約が「無名の欄を許さない」と定めていて、`TextField` の第一引数は
/// 下敷き（placeholder）を兼ねる。入力した瞬間に消える名前は名前ではない（field.md §2）。
public struct Field<Content: View>: View {
    private let label: String
    private let description: String?
    private let error: String?
    private let required: Bool
    private let content: Content

    /// - Parameters:
    ///   - label: 欄の名前。必須。
    ///   - description: 入力の条件など。エラーが出ても消さず並べる（field.md §3 の裁定）。
    ///   - error: 不正のときの言葉。アプリが判定して渡す（state.md §2）。
    ///   - required: 入力が要ることを支援技術と視覚の両方へ出す（field.md §4）。
    public init(
        _ label: String,
        description: String? = nil,
        error: String? = nil,
        required: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.description = description
        self.error = error
        self.required = required
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: StemcellTokens.Spacing.Stack.sm) {
            // 視覚の標示は部品が出す（field.md §4 の裁定。多数派の側）。
            // 記号そのものは seed であって規範ではない。
            // 連結は Text 同士でしかできないので、役を当てるのは連ねたあとである。
            (Text(label) + Text(required ? " *" : "").foregroundColor(StemcellIntent.danger.colors.bg.resolved))
                .textStyle(.labelMd)

            content

            // 説明とエラーは並べる。置換にしないのは、直している最中に入力の条件を
            // 読めなくなるからである（field.md §3。並置の裁定）。
            if let description {
                Text(description)
                    .textStyle(.bodySm)
                    .foregroundStyle(.stemcellMuted)
            }
            if let error {
                Text(error)
                    .textStyle(.bodySm)
                    .foregroundStyle(StemcellIntent.danger.colors.softFg.resolved)
            }
        }
        // 名前も説明もエラーも、一つの到達物として届ける。Web の aria-describedby にあたる
        // 配線は、SwiftUI では要素をまとめて名前と補足を与える形になる
        // （guidelines/accessibility.md: 役割に相手が居ないときは名前と値と状態で伝える）。
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(required ? [] : [])
    }

    private var hint: String {
        [description, error].compactMap { $0 }.joined(separator: "。")
    }
}
