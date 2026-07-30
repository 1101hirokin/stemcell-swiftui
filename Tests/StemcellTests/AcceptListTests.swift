import Testing
import Foundation
@testable import Stemcell

// 受け入れる種類の判定。svelte の `internal/files.test.ts` と同じ場面を並べる。
// 語彙が土地ごとに割れていないかを、同じ問いで確かめるためである。
//
// Web は `File` を組み立てて MIME 型を直に渡せるが、こちらは URL しか無く、型は
// `UTType` から引く。だから同じ問いでも、置く材料は名前だけになる。実在しない
// ファイルでも拡張子から型が解けることを利用している。

private func url(_ name: String) -> URL {
    URL(fileURLWithPath: "/tmp/stemcell-accept-test/\(name)")
}

@Test func acceptが無ければ何でも通す() {
    #expect(AcceptList.accepts(url("a.txt"), nil))
    #expect(AcceptList.accepts(url("a.txt"), []))
}

@Test func MIME型をそのまま照合する() {
    #expect(AcceptList.accepts(url("a.png"), ["image/png"]))
    #expect(!AcceptList.accepts(url("a.jpg"), ["image/png"]))
}

@Test func 総称を解く() {
    #expect(AcceptList.accepts(url("a.jpg"), ["image/*"]))
    #expect(!AcceptList.accepts(url("a.pdf"), ["image/*"]))
    #expect(AcceptList.accepts(url("a.pdf"), ["*/*"]))
}

@Test func 拡張子でも言える() {
    #expect(AcceptList.accepts(url("data.csv"), [".csv"]))
    #expect(!AcceptList.accepts(url("data.tsv"), [".csv"]))
}

@Test func 大文字と小文字を区別しない() {
    #expect(AcceptList.accepts(url("A.PNG"), [".png"]))
    #expect(AcceptList.accepts(url("a.png"), ["IMAGE/PNG"]))
}

@Test func 空の規則は何も通さない() {
    // 規則そのものが空白だけのとき、うっかり全部通さない。svelte も同じ線を引いている。
    #expect(!AcceptList.accepts(url("a.png"), ["  "]))
}

@Test func 受け取るものと弾くものへ分ける() {
    let (accepted, rejected) = AcceptList.split([url("a.png"), url("b.pdf")], accept: ["image/*"])
    #expect(accepted.map(\.lastPathComponent) == ["a.png"])
    #expect(rejected.map(\.lastPathComponent) == ["b.pdf"])
}

@Test func 型の解けないものはMIME型で照合できない() {
    // 未知の拡張子は `UTType` が解けないので MIME 型が空になる。総称にも当たらない。
    // 拡張子で言えば拾える。Web は `File.type` が空文字になる場面にあたる。
    #expect(!AcceptList.accepts(url("a.stemcell"), ["application/octet-stream"]))
    #expect(AcceptList.accepts(url("a.stemcell"), [".stemcell"]))
    // `*/*` は型を見ないので通る。
    #expect(AcceptList.accepts(url("a.stemcell"), ["*/*"]))
}

@Test func 拡張子の無いものは型で照合できない() {
    // `pathExtension` が空になり、型が解けない。総称にも当たらない。
    #expect(!AcceptList.accepts(url("README"), ["text/*"]))
    #expect(AcceptList.accepts(url("README"), ["*/*"]))
}

@Test func 点が複数あっても末尾で照合する() {
    // `pathExtension` は最後の一つしか返さないが、拡張子の規則は名前の末尾を見るので
    // 二段の拡張子でも当たる。
    #expect(AcceptList.accepts(url("archive.tar.gz"), [".tar.gz"]))
    #expect(!AcceptList.accepts(url("archive.tar.gz"), [".tar"]))
}

@Test func フォルダは型で弾かれる() {
    // フォルダの型は MIME 型を持たないので、MIME の規則には当たらない。弾く仕組みを
    // 別に持っているわけではなく、当たらないから通らないだけである。
    // 拡張子で言えば通ってしまう。そこは受け取った側が見る。
    #expect(!AcceptList.accepts(url("photos"), ["image/*"]))
    #expect(!AcceptList.accepts(url("Some.app"), ["application/octet-stream"]))
    #expect(AcceptList.accepts(url("Some.app"), [".app"]))
}
