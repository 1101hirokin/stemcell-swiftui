import SwiftUI

/// 一方向に並べる（Stack.md）。
/// 並べる向き。
///
/// Stack の中の入れ子にしない。Stack が生成型なので、入れ子にすると外から呼ぶときに
/// `Stack<EmptyView>.Align` と書くことになり、型推論も壊れる（実際に壊した）。
public enum StackDirection: String, Sendable, CaseIterable {
    /// 積む向き。読みの流れに沿って縦に並ぶ。
    case stack
    /// 並ぶ向き。行の中に横に並ぶ。
    case inline
}

/// 交差軸の揃え。
public enum StackAlign: String, Sendable, CaseIterable {
    case stretch, start, center, end
}

public struct Stack<Content: View>: View {
    private let direction: StackDirection
    private let gap: String
    private let align: StackAlign
    private let content: Content

    public init(
        direction: StackDirection = .stack,
        gap: String = "md",
        align: StackAlign = .stretch,
        @ViewBuilder content: () -> Content
    ) {
        self.direction = direction
        self.gap = gap
        self.align = align
        self.content = content()
    }

    public var body: some View {
        // 段は direction に応じて別の意味層を引く（契約）。縦に積むときと横に並べるときで
        // 要る間隔が違うからで、同じ md でも値が違う。
        let spacing = resolveSpacing(gap, scale: direction == .stack ? .stack : .inline)

        switch direction {
        case .stack:
            // 積みの箱は横いっぱいを取る。Web の Stack が block である（内容幅で止まらない）
            // ことに対応する。中の揃えは alignment が持つ。
            VStack(alignment: horizontal, spacing: spacing) { content }
                .frame(maxWidth: align == .stretch ? .infinity : nil, alignment: .topLeading)
        case .inline:
            // 交差軸（ここでは高さ）に枠を当てない。前の版は stretch のとき
            // `.frame(maxHeight: .infinity)` を当てていたが、高さの決まらない場所
            // （ScrollView の中）では行が無限を要求し、行同士が重なった。実機で見た。
            HStack(alignment: vertical, spacing: spacing) { content }
        }
    }

    /// 交差軸の揃え。
    ///
    /// SwiftUI の Stack は、揃えが何であれ交差軸の寸法を子へ提案する。提案を受ける子
    /// （`Color` や `TextField`）はそれで広がり、自分の理想で止まる子（`Text`）は止まる。
    /// つまり stretch は「広げてよい」という提案でしかなく、Web の
    /// `align-items: stretch`（子の箱そのものを広げる）とは効き方が違う。
    /// start / center / end は、止まった子を置く位置としてだけ効く。HOLES #2 に記録した。
    private var horizontal: HorizontalAlignment {
        switch align {
        case .start: return .leading
        case .center: return .center
        case .end: return .trailing
        case .stretch: return .leading
        }
    }

    private var vertical: VerticalAlignment {
        switch align {
        case .start: return .top
        case .center: return .center
        case .end: return .bottom
        case .stretch: return .top
        }
    }
}
