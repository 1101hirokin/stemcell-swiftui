import SwiftUI
import StemcellTokens

/// 行内の交差軸の揃え（契約の `align`）。`Stack` と違って `stretch` を持たない。
public enum ClusterAlign: String, Sendable, CaseIterable {
    case start, center, end

    var vertical: VerticalAlignment {
        switch self {
        case .start: return .top
        case .center: return .center
        case .end: return .bottom
        }
    }
}

/// 折り返す横並び（契約の `Cluster`）。行に収まらなければ次の行へ流れる。
///
/// SwiftUI に折り返す並びの型が無いので、契約の名前で型を出す（DESIGN.md §2 の 70 個の側）。
/// 土台は `Layout` に置く。`LazyVGrid` では列の数を先に決める要があり、それは
/// 「行に収まらなければ次へ流れる」ではなく「決めた数で割る」になる。`ViewThatFits` は
/// 候補を並べる形で、任意の個数には向かない。
public struct Cluster<Content: View>: View {
    private let gap: String
    private let align: ClusterAlign
    private let content: Content

    public init(
        gap: String = "md",
        align: ClusterAlign = .start,
        @ViewBuilder content: () -> Content
    ) {
        self.gap = gap
        self.align = align
        self.content = content()
    }

    public var body: some View {
        // 段は gap の意味層を引く（契約の gap description）。両軸に同じ値を置く。
        let spacing = resolveSpacing(gap, scale: .gap) ?? StemcellTokens.Spacing.Gap.md
        WrapLayout(spacing: spacing, align: align) { content }
    }
}

/// 折り返しの配置。行へ詰めて、入らなくなったら次の行へ送る。
///
/// 交差軸の揃えは行ごとに解く。CSS の `flex-wrap` が行を単位に `align-items` を効かせるのと
/// 同じで、全体の最も高い子ではなく、その行の最も高い子に対して揃える。
struct WrapLayout: Layout {
    let spacing: CGFloat
    let align: ClusterAlign

    struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// 与えられた幅へ詰めた結果の行。寸法を測るときと置くときで同じ答えが要るので、一箇所に置く。
    private func lines(_ sizes: [CGSize], width: CGFloat) -> [Line] {
        var out: [Line] = []
        var line = Line()
        for (i, s) in sizes.enumerated() {
            let add = line.indices.isEmpty ? s.width : line.width + spacing + s.width
            if !line.indices.isEmpty && add > width {
                out.append(line)
                line = Line()
                line.indices = [i]
                line.width = s.width
                line.height = s.height
            } else {
                line.indices.append(i)
                line.width = add
                line.height = max(line.height, s.height)
            }
        }
        if !line.indices.isEmpty { out.append(line) }
        return out
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        // 幅が来ないときは一行に並べたときの幅を返す。折り返す相手が決まらないためである。
        let width = proposal.width ?? sizes.reduce(0) { $0 + $1.width } + spacing * CGFloat(max(0, sizes.count - 1))
        let ls = lines(sizes, width: width)
        let height = ls.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, ls.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var y = bounds.minY
        for line in lines(sizes, width: bounds.width) {
            var x = bounds.minX
            for i in line.indices {
                let s = sizes[i]
                let dy: CGFloat
                switch align {
                case .start: dy = 0
                case .center: dy = (line.height - s.height) / 2
                case .end: dy = line.height - s.height
                }
                subviews[i].place(
                    at: CGPoint(x: x, y: y + dy),
                    proposal: ProposedViewSize(s)
                )
                x += s.width + spacing
            }
            y += line.height + spacing
        }
    }
}
