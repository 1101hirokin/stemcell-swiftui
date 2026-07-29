import SwiftUI

/// 余白を持つだけの箱（Box.md）。
///
/// 契約の `as`（意味を持つ要素の選択）は写していない。あれは HTML の要素を選ぶための prop で、
/// SwiftUI に要素の語彙が無い。意味は要素ではなく到達性の修飾子で届く
/// （guidelines/accessibility.md）。必要なら消費者が `.accessibilityElement` を重ねる。
public struct Box<Content: View>: View {
    private let inset: String?
    private let content: Content

    public init(inset: String? = nil, @ViewBuilder content: () -> Content) {
        self.inset = inset
        self.content = content()
    }

    public var body: some View {
        let insets = inset.flatMap(resolveInset)
        content.padding(insets ?? EdgeInsets())
    }
}
