import Testing
import Foundation

// トークンを引けているかの検査（DESIGN.md §8）。
//
// §8 は「見た目は測らない。色や間隔が正しいかは、トークンを引いているかどうかで見る」と
// 書いていたが、その検査が実在しなかった。実機で見つかった不具合の多くは、契約が答えを
// 持っているのに実装が読み落としたものである。書き足しても読み落としは閉じない。機械が
// 捕まえる形にする。
//
// ここが見るのは二種類だけである。退避側のトークンを引いていないか。トークンが出している
// 役を一度も引いていないものが無いか。どちらも今日の実機で実際に踏んだ穴に対応する。

/// Sources 配下の Swift を読む。試験の実行位置ではなく、この試験自身の位置から辿る。
private func sourceFiles() throws -> [(name: String, text: String)] {
    let here = URL(fileURLWithPath: #filePath)
    let root = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let dir = root.appendingPathComponent("Sources/Stemcell")
    let names = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasSuffix(".swift") }
    return try names.sorted().map { ($0, try String(contentsOf: dir.appendingPathComponent($0), encoding: .utf8)) }
}

@Test func 角は退避側の段を引かない() throws {
    // shape.md §3 は値を二段で持ち、§5 は「連続曲率を一級で持つ native（SwiftUI の
    // .continuous）は常に連続曲率側にいる」と定める。退避側は corner-shape 未対応の
    // ブラウザのためのものである。実装は一度ここを取り違え、角が意図の半分以下になっていた。
    //
    // pill だけは例外である。全円は両段で同値なので Continuous の側に無い。
    for (name, text) in try sourceFiles() {
        for line in text.split(separator: "\n") where line.contains("Shape.Semantic.") {
            #expect(
                line.contains("Shape.Semantic.pill"),
                "\(name) が退避側の角を引いている。Shape.Continuous.Semantic へ替える: \(line.trimmingCharacters(in: .whitespaces))"
            )
        }
    }
}

@Test func トークンが出している役を実装が引いている() throws {
    // 引いていない役は、契約のその状態を実装が持っていないということである。
    // hover と焦点の輪はここで落ちた。state.md §3.3 は hover と pressed を面のチャンネルで、
    // focus を輪のチャンネルで解決すると定めていて、focus-ring.md は自らを
    // 「ほぼ全て Normative であり、a11y の最低基準にあたる」と書いている。
    // Intent.swift はトークンを役へ橋渡しする場所であって、消費する側ではない。
    // ここを数に入れると、宣言しただけの役が「引いている」ことになる（実際になった）。
    let text = try sourceFiles()
        .filter { $0.name != "Intent.swift" }
        .map(\.text)
        .joined(separator: "\n")

    // まだ引けていないものは、ここへ理由と行き先を書いて通す。数が減る方向にしか動かさない。
    // hover はここに居たが、実装して外した。この検査が「外せ」と言って落ちた。
    let 未実装: [String: String] = [
        // 譲ったものは実装されない。理由が要るので、未実装と同じ場所に書く。
        "focusRing": "HOLES #11。焦点の輪は platform へ譲った。ButtonStyle の中から焦点を知る道が無い",
    ]

    let 引くべき役 = [
        "bg", "fg", "border", "bgHover", "bgPressed",
        "softBg", "softFg", "softBgHover", "softBgPressed",
        "focusRing",
    ]

    for 役 in 引くべき役 {
        let 引いている = text.contains(".\(役)")

        if let 理由 = 未実装[役] {
            #expect(!引いている, "\(役) を引けるようになった。未実装の一覧から外す（\(理由)）")
        } else {
            #expect(引いている, "\(役) をどの部品も引いていない。契約のその状態を実装が持っていない")
        }
    }
}
