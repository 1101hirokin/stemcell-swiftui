// 画面へ出さずに macOS の姿を焼く。
//
// screencapture は画面収録の許可が要り、画面が消灯していると真っ黒を返し、窓を掴み
// そこねると何も撮れない。実際そこで何度も止まった。窓を画面の外へ置いて cacheDisplay で
// ビットマップへ落とせば、そのどれも要らない。
//
// sheet は別の窓として出るので、attachedSheet から辿る。
//
// 撮れないものが一つある。押した結果は撮れない。触った後にどうなるかは XCUITest を組むか
// 人が押すことになる。
//
// 使い方:
//   swift Tools/shoot-macos.swift <出力.png> [待つ秒数]
//
// 焼く中身はこのファイルの `subject` を書き替えて指定する。見本を丸ごと焼くなら
// Example を import できないので、確かめたい View をここへ写す。
import SwiftUI
import AppKit

@MainActor
private var subject: some View {
    // ここを書き替える。
    VStack(spacing: 12) {
        Text("焼く中身をここへ").font(.title)
    }
    .padding(24)
    .frame(width: 420, height: 240)
    .background(Color.white)
}

@MainActor func run() {
    let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "shot.png"
    let wait = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2]) ?? 1.5 : 1.5

    let host = NSHostingView(rootView: subject)
    host.frame = NSRect(x: 0, y: 0, width: 420, height: 240)
    let win = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
    win.contentView = host
    // 画面の外へ置く。前面へは出さない。
    win.setFrameOrigin(NSPoint(x: -10000, y: -10000))
    win.orderBack(nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
        // sheet が出ていればそちらを焼く。付いていなければ本体を焼く。
        let target = win.attachedSheet ?? win
        guard let v = target.contentView,
              let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else {
            FileHandle.standardError.write(Data("焼けなかった\n".utf8)); exit(1)
        }
        v.cacheDisplay(in: v.bounds, to: rep)
        try! rep.representation(using: .png, properties: [:])!
            .write(to: URL(fileURLWithPath: out))
        print("\(rep.pixelsWide)x\(rep.pixelsHigh) を \(out) へ書いた（sheet: \(win.attachedSheet != nil ? "あり" : "なし")）")
        exit(0)
    }
    NSApplication.shared.run()
}
MainActor.assumeIsolated { run() }
