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
    // 束縛は値を持たせる。.constant() だと書いても入り切りしても戻ってしまい、
    // 欄もつまみも触れないものになる（実機で気づいた）。
    @State private var mail = ""
    @State private var invalid = "x"
    @State private var readOnly = "変えられない"
    @State private var on = true
    @State private var checked = true
    @State private var mixed = false
    @State private var lightOpen = false
    @State private var explicitOpen = false
    @State private var popDown = false
    @State private var popUp = false
    @State private var popOverDialog = false
    @State private var code = ""
    @State private var codeDone = ""
    @State private var picked: [URL] = []
    @State private var inbox: [URL] = []
    @State private var dropped: [String] = []
    @State private var refused: [String] = []

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

                    // 字の役と行間。Dynamic Type を動かして、字と行のあいだが同じ比で
                    // 伸びるかを見る場所である。一行では行間が見えないので折り返させる。
                    Row("字の役") {
                        Stack(gap: "sm", align: .start) {
                            ForEach(StemcellTextRole.allCases, id: \.self) { role in
                                Text("\(role.rawValue) 行のあいだを見るために折り返させる長さの文をここに置いている")
                                    .textStyle(role)
                            }
                        }
                    }

                    Row("欄と値") {
                        Stack(gap: "sm") {
                            Field("メール", description: "会社のものを入れる", required: true) {
                                TextField("", text: $mail)
                                    .fieldStyle()
                            }
                            Field("不正な値", error: "形式が違う") {
                                TextField("", text: $invalid)
                                    .fieldStyle(invalid: true)
                            }
                            Field("読むだけ") {
                                TextField("", text: $readOnly)
                                    .fieldStyle(readOnly: true)
                            }
                            Toggle("入り切り", isOn: $on)
                                .toggleStyle(.stemcellSwitch)
                            Toggle("四角い印", isOn: $checked)
                                .toggleStyle(.stemcellCheckbox)
                            Toggle("第三の値", isOn: $mixed)
                                .toggleStyle(.stemcellCheckbox(indeterminate: true, mixedValueLabel: "どちらでもない"))
                        }
                    }

                    // 確認コード。枠は桁の数だけ並ぶが、打てる欄は一つである。
                    // 自動入力も貼り付けも、その一つに紐づく（契約の裁定）。
                    Row("確認コード") {
                        Stack(gap: "sm", align: .start) {
                            Field("コード", description: codeDone.isEmpty ? "六桁を打つ" : "揃った: \(codeDone)") {
                                OneTimeCodeField(value: $code,
                                                 mask: .init(showValueLabel: "コードを表示する",
                                                             hideValueLabel: "コードを隠す",
                                                             revealedMessage: "コードを表示しました",
                                                             hiddenMessage: "コードを隠しました")) { done in
                                    codeDone = done
                                }
                            }
                        }
                    }

                    // 落とせる面。落ちてくる最中の姿は、実際に何かを引いてこないと出ない。
                    // 押して選べる手段を中へ置くのは Normative である（WCAG 2.2 SC 2.5.7）。
                    Row("落とす面") {
                        Stack(gap: "sm", align: .start) {
                            // 面へは accept を渡さない。面が先に弾くと告知が二度に分かれ、
                            // 後が前を上書きする（patterns/file-upload.md §4）。面はそのまま
                            // 渡し、絞り込みも告知も値を持つ欄がまとめて行う。
                            DropArea(label: "画像を落とす") { urls in
                                dropped = urls.map(\.lastPathComponent)
                                inbox = urls
                            } content: {
                                Stack(gap: "sm", align: .center) {
                                    Text("画像をここへ引いてきて放す").textStyle(.bodyMd)
                                    Button("ファイルを選ぶ") { }
                                        .buttonStyle(.stemcell(.outlined, size: .sm))
                                }
                            }
                            if !dropped.isEmpty {
                                Text("受け取った: \(dropped.joined(separator: ", "))").textStyle(.bodySm)
                            }
                            if !refused.isEmpty {
                                Text("弾いた: \(refused.joined(separator: ", "))")
                                    .textStyle(.bodySm)
                                    .foregroundStyle(.stemcellMuted)
                            }
                        }
                    }

                    // ファイルを選ぶ欄。選ばせるのは環境の選択画面で、貼り付けは
                    // PasteButton が受ける。姿は環境が持つ（HOLES #29）。
                    Row("ファイルを選ぶ") {
                        Stack(gap: "sm", align: .start) {
                            Field("添付", description: picked.isEmpty
                                  ? "画像を選ぶ"
                                  : picked.map(\.lastPathComponent).joined(separator: ", ")) {
                                FileField(value: $picked, accept: ["image/*"], multiple: true,
                                          triggerLabel: "ファイルを選ぶ",
                                          pasteLabel: "貼り付ける",
                                          receivedLabel: "{n} 件を受け取りました",
                                          rejectedLabel: "{n} 件を弾きました",
                                          incoming: $inbox) { _ in
                                } onReject: { urls in
                                    refused = urls.map(\.lastPathComponent)
                                }
                            }
                        }
                    }

                    // 中央に開く modal。焦点が中へ入るか、閉じたら元へ戻るかを見る場所である。
                    Row("覆い") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            Button("light で開く") { lightOpen = true }
                                .buttonStyle(.stemcell())
                            Button("explicit で開く") { explicitOpen = true }
                                .buttonStyle(.stemcell(.outlined))
                        }
                    }

                    // 折り返す横並び。窓を縮めると行が増える。揃えの三つは行ごとに解ける。
                    Row("折り返す並び") {
                        Stack(gap: "sm") {
                            ForEach(ClusterAlign.allCases, id: \.self) { a in
                                Cluster(gap: "sm", align: a) {
                                    Text(a.rawValue).textStyle(.labelMd)
                                    ForEach(["東京", "神奈川", "埼玉", "千葉", "茨城", "栃木", "群馬", "山梨"], id: \.self) { name in
                                        Button(name) { }.buttonStyle(.stemcell(.soft, size: .sm))
                                    }
                                    Text("背の高い子\n二行ある").textStyle(.bodySm)
                                }
                            }
                        }
                    }

                    // 地の上の面。影の面と枠の面の二つ。暗いテーマで面が消えないかを見る場所である。
                    Row("面") {
                        Stack(direction: .inline, gap: "md", align: .start) {
                            Card {
                                Stack(gap: "sm", align: .start) {
                                    Text("影の面").textStyle(.titleSm)
                                    Text("既定。二層の影で地から浮く。").textStyle(.bodySm)
                                }
                            }
                            Card(outlined: true) {
                                Stack(gap: "sm", align: .start) {
                                    Text("枠の面").textStyle(.titleSm)
                                    Text("影を持たず、縁で地から分ける。").textStyle(.bodySm)
                                }
                            }
                            // 入れ子は段が上がらない（HOLES #21）。内側を枠にすると境界が出る。
                            Card {
                                Card(outlined: true) {
                                    Text("入れ子は枠で分ける").textStyle(.bodySm)
                                }
                            }
                        }
                    }

                    // アンカーに従う一時の面。開き方向の二つと、覆いの上に出したときを見る。
                    Row("アンカーに従う面") {
                        Stack(direction: .inline, gap: "sm", align: .center) {
                            Button("下へ開く") { popDown = true }
                                .buttonStyle(.stemcell(.soft))
                                .stemcellPopover(isPresented: $popDown) {
                                    Stack(gap: "sm", align: .start) {
                                        Text("下へ開いた面").textStyle(.titleSm)
                                        Text("外側を押すか Escape で閉じる。").textStyle(.bodySm)
                                    }
                                }
                            Button("上へ開く") { popUp = true }
                                .buttonStyle(.stemcell(.soft))
                                .stemcellPopover(isPresented: $popUp, placement: .blockStart) {
                                    Text("上へ開いた面").textStyle(.bodyMd)
                                }
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

                    // stack 方向も同じ形で見る。こちらの交差軸は横で、第3条が名指す
                    // 「横いっぱいに広がろうとする」の直接の相手である。
                    Row("交差軸の揃え（stack）") {
                        Stack(gap: "sm") {
                            ForEach(StackAlign.allCases, id: \.self) { a in
                                Stack(gap: "sm", align: a) {
                                    Color.orange.opacity(0.35).frame(height: 14)
                                    Text("\(a.rawValue) / 受けない子")
                                        .background(Color.green.opacity(0.2))
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(theme.colors.background.resolved)
        .stemcellDensity(density)
        .stemcellDialog(isPresented: $lightOpen) {
            Text("下書きを捨てる")
        } content: {
            Text("この画面で書いたものは残りません。背後を押すか Escape でも閉じられます。")
        } actions: {
            Stack(direction: .inline, gap: "sm", align: .center) {
                Button("面を重ねる") { popOverDialog = true }
                    .buttonStyle(.stemcell(.soft))
                    .stemcellPopover(isPresented: $popOverDialog) {
                        Text("覆いの上に出した面").textStyle(.bodySm)
                    }
                Button("閉じる") { lightOpen = false }.buttonStyle(.stemcell(.text))
            }
        }
        .stemcellDialog(isPresented: $explicitOpen, dismiss: .explicit) {
            Text("本当に消しますか")
        } content: {
            Text("消したものは戻せません。背後を押しても Escape を押しても閉じません。")
        } actions: {
            Button("やめる") { explicitOpen = false }.buttonStyle(.stemcell(.text))
            Button("消す") { explicitOpen = false }.buttonStyle(.stemcell(.filled, color: .danger))
        }
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
