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

@Test func 伸びの速さは大きさに近い相手へ合わせる() {
    #expect(StemcellTextRole.displayLg.scaleAnchor == .largeTitle)
    #expect(StemcellTextRole.bodyMd.scaleAnchor == .subheadline)
    #expect(StemcellTextRole.labelSm.scaleAnchor == .caption2)
}

@Test func 大きさが同じ役は伸び方も同じである() {
    // 役の意図で選ぶと、トークンで大きさが同じ役に別の伸び率が付き、
    // トークンに無い階層を Dynamic Type が作り出す。headlineMd と titleLg が
    // どちらも 21pt なのに最大設定で 2.33 倍と 2.04 倍に割れていた。
    for a in StemcellTextRole.allCases {
        for b in StemcellTextRole.allCases where a.metrics.size == b.metrics.size {
            #expect(a.scaleAnchor == b.scaleAnchor, "\(a.rawValue) と \(b.rawValue)")
        }
    }
}

@Test func 太さは数から段へ写る() {
    #expect(Font.Weight(stemcellWeight: 400) == .regular)
    #expect(Font.Weight(stemcellWeight: 600) == .semibold)
}
