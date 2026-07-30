import SwiftUI
import StemcellTokens

// 間隔の語彙を解く（spacing.md §6、layout.md §6）。契約は string で受ける。段（sm / md / lg）か、
// 大域の原始（8〜24 の整数の文字列）である。小域の原始（0〜7）と生の数は受けない。
// 混合型なので、値が語彙に合うかを見るのは実装の仕事だと契約が書いている。

enum SpacingScale {
    case inset, stack, inline, gap

    func step(_ name: String) -> CGFloat? {
        switch (self, name) {
        case (.inset, "sm"): return StemcellTokens.Spacing.Inset.sm
        case (.inset, "md"): return StemcellTokens.Spacing.Inset.md
        case (.inset, "lg"): return StemcellTokens.Spacing.Inset.lg
        case (.stack, "sm"): return StemcellTokens.Spacing.Stack.sm
        case (.stack, "md"): return StemcellTokens.Spacing.Stack.md
        case (.stack, "lg"): return StemcellTokens.Spacing.Stack.lg
        case (.inline, "sm"): return StemcellTokens.Spacing.Inline.sm
        case (.inline, "md"): return StemcellTokens.Spacing.Inline.md
        case (.inline, "lg"): return StemcellTokens.Spacing.Inline.lg
        // 折り返す並びは両軸に同じ間隔を置くので、独立した意味層を持つ（spacing.md §4）。
        case (.gap, "sm"): return StemcellTokens.Spacing.Gap.sm
        case (.gap, "md"): return StemcellTokens.Spacing.Gap.md
        case (.gap, "lg"): return StemcellTokens.Spacing.Gap.lg
        default: return nil
        }
    }
}

/// 大域の原始。8 から 24 までで、それより小さい段は意味層でしか使わせない。
private let globalPrimitives: [String: CGFloat] = [
    "8": StemcellTokens.Spacing.s8, "9": StemcellTokens.Spacing.s9,
    "10": StemcellTokens.Spacing.s10, "11": StemcellTokens.Spacing.s11,
    "12": StemcellTokens.Spacing.s12, "13": StemcellTokens.Spacing.s13,
    "14": StemcellTokens.Spacing.s14, "15": StemcellTokens.Spacing.s15,
    "16": StemcellTokens.Spacing.s16, "17": StemcellTokens.Spacing.s17,
    "18": StemcellTokens.Spacing.s18, "19": StemcellTokens.Spacing.s19,
    "20": StemcellTokens.Spacing.s20, "21": StemcellTokens.Spacing.s21,
    "22": StemcellTokens.Spacing.s22, "23": StemcellTokens.Spacing.s23,
    "24": StemcellTokens.Spacing.s24,
]

func resolveSpacing(_ raw: String, scale: SpacingScale) -> CGFloat? {
    scale.step(raw) ?? globalPrimitives[raw]
}

/// 内側余白。1 値なら全周、2 値「block inline」なら軸別（layout.md §6）。
/// 片方でも語彙から外れたら部分適用せず余白なしへ退避する、と契約が定めている。
func resolveInset(_ raw: String) -> EdgeInsets? {
    let parts = raw.split(separator: " ").map(String.init)
    switch parts.count {
    case 1:
        guard let v = resolveSpacing(parts[0], scale: .inset) else { return nil }
        return EdgeInsets(top: v, leading: v, bottom: v, trailing: v)
    case 2:
        guard let block = resolveSpacing(parts[0], scale: .inset),
              let inline = resolveSpacing(parts[1], scale: .inset) else { return nil }
        return EdgeInsets(top: block, leading: inline, bottom: block, trailing: inline)
    default:
        return nil
    }
}
