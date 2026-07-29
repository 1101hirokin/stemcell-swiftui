import Testing
import SwiftUI
@testable import Stemcell

@Test func 既定のテーマは明暗で地の面が違う() {
    let background = StemcellTheme.standard.colors.background
    #expect(background.light != background.dark)
}

@Test func 密度の既定は comfortable である() {
    #expect(EnvironmentValues().stemcellDensity == .comfortable)
}

@Test func テーマは差し替えられる() {
    var theme = StemcellTheme.standard
    let before = theme.colors.primaryBackground
    theme.colors.primaryBackground = DynamicColor(light: .red, dark: .red)
    #expect(theme.colors.primaryBackground != before)
}
