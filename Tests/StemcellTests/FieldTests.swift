import Testing
import SwiftUI
import StemcellTokens
@testable import Stemcell

@Test func 印の大きさと中の印はトークンから来る() {
    #expect(StemcellTokens.Selection.markSize < StemcellTokens.Selection.size)
}

@Test func 不正のときは枠がdangerの役へ差し替わる() {
    let normal = StemcellFieldStyle(size: .md, invalid: false)
    let bad = StemcellFieldStyle(size: .md, invalid: true)
    #expect(normal.size == bad.size)
    #expect(bad.invalid)
}

@Test func 第三の値は様式が持つ() {
    let plain = StemcellCheckboxToggleStyle()
    let mixed = StemcellCheckboxToggleStyle(indeterminate: true)
    #expect(!plain.indeterminate)
    #expect(mixed.indeterminate)
}
