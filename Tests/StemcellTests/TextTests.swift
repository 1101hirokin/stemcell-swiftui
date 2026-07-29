import Testing
import SwiftUI
@testable import Stemcell

@Test func 字の役は十六ある() {
    #expect(StemcellTextRole.allCases.count == 16)
}

@Test func 段が上がるほど字が大きい() {
    #expect(StemcellTextRole.bodySm.metrics.size < StemcellTextRole.bodyMd.metrics.size)
    #expect(StemcellTextRole.bodyMd.metrics.size < StemcellTextRole.bodyLg.metrics.size)
}

@Test func 等幅の役は二つだけ() {
    #expect(StemcellTextRole.allCases.filter(\.isMonospaced).count == 2)
}

@Test func 行のあいだは行の高さから字の大きさを引いた分() {
    let role = StemcellTextRole.bodyMd
    #expect(role.lineSpacing(size: role.metrics.size) == role.metrics.size * (role.metrics.lineHeight - 1))
    #expect(role.lineSpacing(size: role.metrics.size) > 0)
}

@Test func 字が伸びれば行のあいだも同じ比で伸びる() {
    let role = StemcellTextRole.bodyMd
    let base = role.lineSpacing(size: role.metrics.size)
    let doubled = role.lineSpacing(size: role.metrics.size * 2)
    #expect(doubled == base * 2)
}

@Test func 伸びの速さは役ごとに違う相手へ合わせる() {
    // 大きい役ほど緩く伸ばす。全部を body に合わせると階層が壊れる。
    #expect(StemcellTextRole.displayLg.scaleAnchor == .largeTitle)
    #expect(StemcellTextRole.bodyMd.scaleAnchor == .body)
    #expect(StemcellTextRole.labelSm.scaleAnchor == .caption2)
}

@Test func 太さは数から段へ写る() {
    #expect(Font.Weight(stemcellWeight: 400) == .regular)
    #expect(Font.Weight(stemcellWeight: 600) == .semibold)
}
