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

@Test func 行の箱は契約の比で決まる() {
    let role = StemcellTextRole.bodyMd
    #expect(role.lineBox == role.metrics.size * role.metrics.lineHeight)
}

@Test func 自然な行高は契約の箱より低い() {
    // CSS の line-height は一行でも行 box を決めるが、SwiftUI の lineSpacing は
    // 行と行のあいだにしか効かない。差を埋める要があることを、ここで固定する。
    for role in StemcellTextRole.allCases {
        #expect(role.naturalLineHeight < role.lineBox, "\(role.rawValue)")
    }
}

@Test func 太さは数から段へ写る() {
    #expect(Font.Weight(stemcellWeight: 400) == .regular)
    #expect(Font.Weight(stemcellWeight: 600) == .semibold)
}
