import Testing
import SwiftUI
import StemcellTokens
@testable import Stemcell

@Test func 段の名前が間隔へ解ける() {
    #expect(resolveSpacing("md", scale: .inset) != nil)
    #expect(resolveSpacing("md", scale: .stack) != nil)
}

@Test func 積むときと並べるときで段の値が違う() {
    #expect(resolveSpacing("md", scale: .stack) != resolveSpacing("md", scale: .inline))
}

@Test func 大域の原始は受けるが小域は受けない() {
    #expect(resolveSpacing("8", scale: .inset) != nil)
    #expect(resolveSpacing("4", scale: .inset) == nil)
    #expect(resolveSpacing("0", scale: .inset) == nil)
}

@Test func 生の数と語彙外は受けない() {
    #expect(resolveSpacing("16px", scale: .inset) == nil)
    #expect(resolveSpacing("xl", scale: .inset) == nil)
}

@Test func 余白は一値で全周に効く() {
    let insets = resolveInset("md")
    #expect(insets?.top == insets?.leading)
    #expect(insets?.top == insets?.bottom)
}

@Test func 余白は二値で軸別に効く() {
    let insets = resolveInset("lg sm")
    #expect(insets?.top != insets?.leading)
    #expect(insets?.top == insets?.bottom)
    #expect(insets?.leading == insets?.trailing)
}

@Test func 片方が語彙外なら部分適用せず余白なしへ退避する() {
    #expect(resolveInset("lg 4") == nil)
    #expect(resolveInset("md md md") == nil)
}

@Test func 折り返す並びは間隔の意味層を引く() {
    // 契約の gap description が「段は spacing.gap の意味層を引く」と定める。
    // 段と並びの意味層とは別の値である。
    #expect(resolveSpacing("sm", scale: .gap) == StemcellTokens.Spacing.Gap.sm)
    #expect(resolveSpacing("md", scale: .gap) == StemcellTokens.Spacing.Gap.md)
    #expect(resolveSpacing("lg", scale: .gap) == StemcellTokens.Spacing.Gap.lg)
}

@Test func 折り返す並びの揃えは三つで伸びを持たない() {
    // Stack は四つ持つが、Cluster の契約は start / center / end だけである。
    #expect(ClusterAlign.allCases.count == 3)
    #expect(!ClusterAlign.allCases.map(\.rawValue).contains("stretch"))
}
