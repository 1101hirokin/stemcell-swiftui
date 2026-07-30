import SwiftUI
import AppKit
import Stemcell

// 画面を出さずに姿を焼く（DESIGN.md §7）。
//
// screencapture は画面収録の許可が要り、画面が消灯していると真っ黒を返し、窓を掴みそこねると
// 何も撮れない。実際そこで何度も止まった。窓を画面の外へ置いて cacheDisplay でビットマップへ
// 落とせば、そのどれも要らない。sheet は別の窓として出るので attachedSheet から辿る。
//
// 撮れないものが一つある。押した結果は撮れない。触った後にどうなるかは XCUITest を組むか
// 人が押すことになる。
//
// 使い方:
//   swift run Shots <題目> <出力.png>
//
// 題目は下の `subjects` に足す。

@MainActor
enum Subjects {
    static func view(_ name: String) -> AnyView? {
        switch name {
        case "one-time-code": return AnyView(OneTimeCodeProbe())
        case "one-time-code-states": return AnyView(OneTimeCodeStatesProbe())
        case "drop-area": return AnyView(DropAreaProbe())
        default: return nil
        }
    }

    static var names: [String] { ["one-time-code", "one-time-code-states", "drop-area"] }
}

struct OneTimeCodeProbe: View {
    @State private var partial = "123"
    @State private var hidden = "4567"
    @State private var empty = ""

    var body: some View {
        Stack(gap: "lg", align: .start) {
            Text("途中まで打った").textStyle(.labelMd)
            OneTimeCodeField(value: $partial)
            Text("伏せた。見せ直す手段を部品が持つ").textStyle(.labelMd)
            OneTimeCodeField(value: $hidden,
                             mask: .init(showValueLabel: "コードを表示する",
                                         hideValueLabel: "コードを隠す",
                                         revealedMessage: "コードを表示しました",
                                         hiddenMessage: "コードを隠しました"))
            Text("不正").textStyle(.labelMd)
            OneTimeCodeField(value: $empty, invalid: true)
        }
        .padding(24)
        .frame(width: 520, alignment: .leading)
        .stemcellTheme(.standard)
    }
}

/// 使えない状態と、桁数と打てる文字の別。暗いテーマは `.preferredColorScheme` で被せる。
struct OneTimeCodeStatesProbe: View {
    @State private var off = "12"
    @State private var four = "9"
    @State private var alnum = "A7b"

    var body: some View {
        Stack(gap: "lg", align: .start) {
            Text("使えない").textStyle(.labelMd)
            OneTimeCodeField(value: $off).disabled(true)
            Text("四桁").textStyle(.labelMd)
            OneTimeCodeField(value: $four, length: 4)
            Text("英数字").textStyle(.labelMd)
            OneTimeCodeField(value: $alnum, charset: .alphanumeric)
            Text("読むだけ / 段 sm と lg").textStyle(.labelMd)
            OneTimeCodeField(value: $four, length: 4, readOnly: true)
            OneTimeCodeField(value: $alnum, charset: .alphanumeric, size: .sm)
        }
        .padding(24)
        .frame(width: 520, alignment: .leading)
        .stemcellTheme(.standard)
    }
}

struct DropAreaProbe: View {
    var body: some View {
        Stack(gap: "lg", align: .start) {
            Text("常のとき").textStyle(.labelMd)
            DropArea(label: "ファイルを落とす") { _ in } content: {
                Stack(gap: "sm", align: .center) {
                    Text("ここへ引いてきて放す").textStyle(.bodyMd)
                    Button("ファイルを選ぶ") { }.buttonStyle(.stemcell(.outlined, size: .sm))
                }
            }
            Text("使えない").textStyle(.labelMd)
            DropArea(label: "ファイルを落とす") { _ in } content: {
                Text("受け取れない").textStyle(.bodyMd)
            }
            .disabled(true)
        }
        .padding(24)
        .frame(width: 520, alignment: .leading)
        .stemcellTheme(.standard)
    }
}

@MainActor
func shoot() {
    let args = CommandLine.arguments
    guard args.count >= 3, let subject = Subjects.view(args[1]) else {
        FileHandle.standardError.write(Data(
            "使い方: swift run Shots <題目> <出力.png>\n題目: \(Subjects.names.joined(separator: ", "))\n".utf8))
        exit(2)
    }
    let out = args[2]
    let wait = args.count > 3 ? (Double(args[3]) ?? 1.0) : 1.0

    // 暗いテーマは第4引数で切り替える。地は theme から取る（白を敷くと暗いほうが見えない）。
    let dark = args.count > 4 && args[4] == "dark"
    let root = subject
        .preferredColorScheme(dark ? .dark : .light)
        .background(StemcellTheme.standard.colors.background.resolved)
    let host = NSHostingView(rootView: root)
    host.frame = NSRect(x: 0, y: 0, width: 520, height: 620)
    let win = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
    win.contentView = host
    // 画面の外へ置き、前面へは出さない。
    win.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
    win.orderBack(nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
        // sheet が出ていればそちらを焼く。付いていなければ本体を焼く。
        let target = win.attachedSheet ?? win
        guard let v = target.contentView,
              let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else {
            FileHandle.standardError.write(Data("焼けなかった\n".utf8))
            exit(1)
        }
        v.cacheDisplay(in: v.bounds, to: rep)
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
        print("\(rep.pixelsWide)x\(rep.pixelsHigh) を \(out) へ書いた（sheet: \(win.attachedSheet != nil ? "あり" : "なし")）")
        exit(0)
    }
    NSApplication.shared.run()
}

MainActor.assumeIsolated { shoot() }
