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
                    Row("ボタンの強調度") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(StemcellVariant.allCases, id: \.self) { variant in
                                Button(variant.rawValue) { }
                                    .buttonStyle(.stemcell(variant))
                            }
                        }
                    }

                    Row("色の役") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(StemcellIntent.allCases, id: \.self) { intent in
                                Button(intent.rawValue) { }
                                    .buttonStyle(.stemcell(.filled, color: intent))
                            }
                        }
                    }

                    Row("段") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(StemcellSize.allCases, id: \.self) { size in
                                Button(size.rawValue) { }
                                    .buttonStyle(.stemcell(.soft, size: size))
                            }
                        }
                    }

                    Row("親いっぱい") {
                        Button("fullWidth") { }
                            .buttonStyle(.stemcell(.filled, fullWidth: true))
                    }

                    Row("無効") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            Button("押せる") { }.buttonStyle(.stemcell())
                            Button("押せない") { }.buttonStyle(.stemcell()).disabled(true)
                        }
                    }

                    Row("絵だけのボタン") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            ForEach(IconButtonShape.allCases, id: \.self) { shape in
                                Button { } label: { Image(systemName: "xmark") }
                                    .buttonStyle(.stemcellIcon(.soft, shape: shape))
                                    .accessibilityLabel("閉じる")
                            }
                        }
                    }

                    Row("欄と値") {
                        Stack(gap: "sm") {
                            Field("メール", description: "会社のものを入れる", required: true) {
                                TextField("", text: .constant(""))
                                    .fieldStyle()
                            }
                            Field("不正な値", error: "形式が違う") {
                                TextField("", text: .constant("x"))
                                    .fieldStyle(invalid: true)
                            }
                            Field("読むだけ") {
                                TextField("", text: .constant("変えられない"))
                                    .fieldStyle(readOnly: true)
                            }
                            Toggle("入り切り", isOn: .constant(true))
                                .toggleStyle(.stemcellSwitch)
                            Toggle("四角い印", isOn: .constant(true))
                                .toggleStyle(.stemcellCheckbox)
                            Toggle("第三の値", isOn: .constant(false))
                                .toggleStyle(.stemcellCheckbox(indeterminate: true, mixedValueLabel: "どちらでもない"))
                        }
                    }

                    // 交差軸の揃えは、提案を受ける子と受けない子で見え方が割れる。両方を並べる。
                    // 橙は提案をそのまま受ける子（Color）、緑は自分の理想で止まる子（Text）である。
                    // 背の高い子を混ぜて、行の交差軸をそこで決めさせている。
                    Row("交差軸の揃え（inline）") {
                        Stack(gap: "sm") {
                            ForEach(StackAlign.allCases, id: \.self) { a in
                                Stack(direction: .inline, gap: "sm", align: a) {
                                    Text(a.rawValue).frame(width: 64, alignment: .leading)
                                    Color.orange.opacity(0.35).frame(width: 40)
                                    Text("受けない子").background(Color.green.opacity(0.2))
                                    Text("背の高い子\n二行ある")
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
}

/// 見出しと中身の組。見本の中でだけ使う。
struct Row<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Stack(gap: "sm", align: .start) {
            Text(title).textStyle(.titleSm)
            content
        }
    }
}
