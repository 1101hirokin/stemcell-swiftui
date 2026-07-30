import Testing
import SwiftUI
import StemcellTokens
@testable import Stemcell

// 試験の名前に空白は使えない。Swift の識別子は Unicode を許すが、空白は区切りである。
// 日本語と英字を混ぜるときは詰めて書く。

@Test func 既定のテーマは明暗で地の面が違う() {
    let background = StemcellTheme.standard.colors.background
    #expect(background.light != background.dark)
}

@Test func 密度の既定はcomfortableである() {
    #expect(EnvironmentValues().stemcellDensity == .comfortable)
}

@Test func テーマは差し替えられる() {
    var theme = StemcellTheme.standard
    let before = theme.colors.primaryBackground
    theme.colors.primaryBackground = DynamicColor(light: Color.red, dark: Color.red)
    #expect(theme.colors.primaryBackground != before)
}
