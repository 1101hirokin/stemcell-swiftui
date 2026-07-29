import SwiftUI

// 文脈は View ではなく修飾子で配る（DESIGN.md §3）。SwiftUI の慣習が .tint() と
// .environment() であり、木を一段包ませると NavigationStack や TabView の中のどこに
// 置くかで意味が変わる。契約の StemcellProvider はここに写る。

extension EnvironmentValues {
    /// いま効いているテーマ。
    @Entry public var stemcellTheme: StemcellTheme = .standard
    /// いま効いている密度。
    @Entry public var stemcellDensity: StemcellDensity = .comfortable
}

extension View {
    /// テーマを配る。ここから下の stemcell の部品がこれを引く。
    public func stemcellTheme(_ theme: StemcellTheme) -> some View {
        environment(\.stemcellTheme, theme)
    }

    /// 密度を配る。段の中身が差し替わる（spacing.md §5）。
    public func stemcellDensity(_ density: StemcellDensity) -> some View {
        environment(\.stemcellDensity, density)
    }
}
