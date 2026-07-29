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
            VStack(alignment: horizontal, spacing: spacing) { content }
                .frame(maxWidth: align == .stretch ? .infinity : nil, alignment: stretchAlignment)
        case .inline:
            HStack(alignment: vertical, spacing: spacing) { content }
                .frame(maxHeight: align == .stretch ? .infinity : nil, alignment: stretchAlignment)
        }
    }

    /// 交差軸の揃え。stretch は SwiftUI の alignment に無いので、枠を広げる側で表す。
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

    private var stretchAlignment: Alignment {
        direction == .stack ? .topLeading : .topLeading
    }
}
