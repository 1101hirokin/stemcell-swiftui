import Testing
import SwiftUI
@testable import Stemcell

@Test func 強調度は四段ある() {
    #expect(StemcellVariant.allCases.count == 4)
}

@Test func 色の役は四つで成功と情報を持たない() {
    // 行動の色に success は無い（color.md §5: 行動はまだ成功していない）。
    let names = StemcellIntent.allCases.map(\.rawValue)
    #expect(names == ["primary", "danger", "warning", "plain"])
}

@Test func 段は内側余白だけを引く() {
    #expect(StemcellSize.sm.inset < StemcellSize.md.inset)
    #expect(StemcellSize.md.inset < StemcellSize.lg.inset)
}

@Test func 絵だけのボタンの角は二つから選ぶ() {
    #expect(StemcellIconButtonShape.control.corner != StemcellIconButtonShape.pill.corner)
}

@Test func intentごとに面と文字の色が違う() {
    #expect(StemcellIntent.primary.colors.bg != StemcellIntent.danger.colors.bg)
}
