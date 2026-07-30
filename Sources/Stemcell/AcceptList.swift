import Foundation
import UniformTypeIdentifiers

/// 受け入れる種類の判定（FileField.md §2）。svelte の `internal/files.ts` と同じ語彙で解く。
///
/// 語彙は MIME 型の列である。総称（`image/*`）と、Web の方言である拡張子（`.csv`）も解く。
/// 語彙を土地ごとに変えない。同じ `accept` を渡した二つの画面が別のものを受け取ったら、
/// 契約が共通言語である意味が無くなる。
///
/// 中身が本当にその型かは確かめない。拡張子を変えただけのファイルは通る。それはアプリの
/// 仕事である（svelte も同じ線を引いている）。
enum AcceptList {
    /// 落とされたものの MIME 型。UTType から引く。
    ///
    /// Web の `File.type` にあたるものが Apple には無い。あちらは拡張子と magic number から
    /// ブラウザが決めた文字列を持っているが、こちらは `UTType` という別の体系がある。
    /// 型そのものを比べると語彙が土地ごとに割れるので、`UTType` を MIME 型へ戻してから
    /// 同じ規則を当てる。
    static func mimeType(of url: URL) -> String {
        let t = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
            ?? UTType(filenameExtension: url.pathExtension)
        return t?.preferredMIMEType?.lowercased() ?? ""
    }

    private static func matches(_ url: URL, rule: String) -> Bool {
        let r = rule.trimmingCharacters(in: .whitespaces).lowercased()
        if r.isEmpty { return false }
        if r == "*/*" || r == "*" { return true }
        // Web の方言。拡張子で言う。
        if r.hasPrefix(".") { return url.lastPathComponent.lowercased().hasSuffix(r) }
        let type = mimeType(of: url)
        if r.hasSuffix("/*") { return type.hasPrefix(String(r.dropLast())) }
        return type == r
    }

    /// accept が空なら何でも通す。
    static func accepts(_ url: URL, _ accept: [String]?) -> Bool {
        guard let accept, !accept.isEmpty else { return true }
        return accept.contains { matches(url, rule: $0) }
    }

    /// 受け取るものと弾くものへ分ける。
    static func split(_ urls: [URL], accept: [String]?) -> (accepted: [URL], rejected: [URL]) {
        var accepted: [URL] = []
        var rejected: [URL] = []
        for u in urls {
            if accepts(u, accept) { accepted.append(u) } else { rejected.append(u) }
        }
        return (accepted, rejected)
    }
}
