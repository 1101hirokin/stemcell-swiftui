import SwiftUI
import Stemcell

// 実機と Mac で姿を見るための見本。svelte の playground にあたる。
// 契約どおりに書けるかではなく、書いたものが読めるかを見る場所である。

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            Gallery()
                .stemcellTheme(.standard)
        }
        #if os(macOS)
        .defaultSize(width: 520, height: 720)
        #endif
    }
}

struct Gallery: View {
    @Environment(\.stemcellTheme) private var theme
    @State private var density: StemcellDensity = .comfortable

    var body: some View {
        ScrollView {
            Box(inset: "lg") {
                Stack(gap: "lg") {
                    Section("ボタンの強調度") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(StemcellVariant.allCases, id: \.self) { variant in
                                Button(variant.rawValue) { }
                                    .buttonStyle(.stemcell(variant))
                            }
                        }
                    }

                    Section("色の役") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(StemcellIntent.allCases, id: \.self) { intent in
                                Button(intent.rawValue) { }
                                    .buttonStyle(.stemcell(.filled, color: intent))
                            }
                        }
                    }

                    Section("段") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(StemcellSize.allCases, id: \.self) { size in
                                Button(size.rawValue) { }
                                    .buttonStyle(.stemcell(.soft, size: size))
                            }
                        }
                    }

                    Section("親いっぱい") {
                        Button("fullWidth") { }
                            .buttonStyle(.stemcell(.filled, fullWidth: true))
                    }

                    Section("無効") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            Button("押せる") { }.buttonStyle(.stemcell())
                            Button("押せない") { }.buttonStyle(.stemcell()).disabled(true)
                        }
                    }

                    Section("絵だけのボタン") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(StemcellIconButtonShape.allCases, id: \.self) { shape in
                                Button { } label: { Image(systemName: "xmark") }
                                    .buttonStyle(.stemcellIcon(.soft, shape: shape))
                                    .accessibilityLabel("閉じる")
                            }
                        }
                    }

                    Section("交差軸の揃え") {
                        Stack(gap: "sm") {
                            ForEach(["stretch", "start", "center", "end"], id: \.self) { name in
                                Stack(direction: .inline, gap: "sm", align: align(name)) {
                                    Text(name)
                                    Button("押す") { }.buttonStyle(.stemcell(.outlined, size: .sm))
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(theme.colors.background.resolved)
        .stemcellDensity(density)
    }

    private func align(_ name: String) -> Stack<EmptyView>.Align {
        Stack<EmptyView>.Align(rawValue: name) ?? .stretch
    }
}

/// 見出しと中身の組。見本の中でだけ使う。
struct Section<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Stack(gap: "sm", align: .start) {
            Text(title).font(.headline)
            content
        }
    }
}
