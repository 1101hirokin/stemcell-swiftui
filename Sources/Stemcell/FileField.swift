import SwiftUI
import StemcellTokens
import UniformTypeIdentifiers

/// ファイルを選ぶ欄（契約の `FileField`）。選ばせることと、選ばれたものを値として持つことだけを
/// 担う。落とせる面は `DropArea`、選ばれたものの見せ方は別の部品で、一体の姿は合成である。
///
/// SwiftUI に相当する部品が無いので型で出す（DESIGN.md §2）。
///
/// 土台は環境のファイル選択である。`.fileImporter` がそれで、受け入れる種類の絞り込みも、
/// 複数選択も、フォルダも無償で持っている（第2条）。選ばせる仕組みを自前で作らない。
/// Web は「入力を透明で重ねる」形で焦点を native に残しているが、SwiftUI は修飾子なので
/// その工夫が要らない。`Button` はそのまま `Button` である。
///
/// 貼り付けは `PasteButton` が受ける。契約の a11y notes が「iOS は貼り付けボタン
/// （`UIPasteControl`）を置く」と書いていて、`PasteButton` の実体がそれである。押した
/// ときだけ貼り付け先へ触れるので、環境が貼り付けの確認を出さない。Web のように文書へ
/// `paste` を張って焦点のあいだだけ受ける、という工夫は要らない。契約が「画面のどこに
/// 貼っても受ける形は採らない（他の欄への貼り付けを奪う）」と定めているのを、native の
/// 機構がそのまま満たしている。
///
/// 契約の prop のうち、ここが受けないものが四つある。
///
/// `label` `description` `error` `required` `labelHidden` は `Field` が持つ。他の欄と
/// 同じ解剖である（契約の a11y notes）。
///
/// `disabled` は `.disabled()` へ委ねる。
///
/// `name` は受けない。SwiftUI に HTML の form が無い（field.md §5）。
///
/// `capture` は受けない。`.fileImporter` に写真機を直接開く口が無い。契約は capture を
/// 「要求であって命令ではない。持たない環境では通常の選択画面が開く」と書いているので、
/// 常に通常の選択画面が開く形が、その退避そのものにあたる（第7条）。口を作って何も
/// しないより、受けないほうが正直である。
public struct FileField: View {
    @Binding private var value: [URL]
    private let accept: [String]?
    private let multiple: Bool
    private let directory: Bool
    private let invalid: Bool
    private let size: StemcellSize
    private let triggerLabel: String
    private let pasteLabel: String?
    private let receivedLabel: String?
    private let rejectedLabel: String?
    private let onChange: ([URL]) -> Void
    private let onReject: ([URL]) -> Void

    /// - Parameters:
    ///   - value: 選ばれたファイル。値はアプリが持つ。
    ///   - accept: 受け入れる種類（MIME 型の列）。選択画面の絞り込みにも、貼り付けの
    ///     絞り込みにも使う。
    ///   - multiple: 複数選べる。
    ///   - directory: フォルダごと選ぶ。
    ///   - invalid: 不正。判定はアプリがする。
    ///   - size: 大きさの段。
    ///   - triggerLabel: 選ぶ操作の名前。DS は文言を持たない（i18n.md §1）。
    ///   - pasteLabel: 貼り付けの操作の名前。渡さなければ貼り付けの口を出さない。
    ///   - receivedLabel: 貼る経路で受け取ったことを知らせる文のひな型（`{n}` を件数で置き換える）。
    ///   - rejectedLabel: 弾いたことを知らせる文のひな型（`{n}` を件数で置き換える）。
    ///   - onChange: 値が変わった。
    ///   - onReject: `accept` に合わないものを弾いた。何をするかはアプリが決める。
    public init(
        value: Binding<[URL]>,
        accept: [String]? = nil,
        multiple: Bool = false,
        directory: Bool = false,
        invalid: Bool = false,
        size: StemcellSize = .md,
        triggerLabel: String,
        pasteLabel: String? = nil,
        receivedLabel: String? = nil,
        rejectedLabel: String? = nil,
        onChange: @escaping ([URL]) -> Void = { _ in },
        onReject: @escaping ([URL]) -> Void = { _ in }
    ) {
        self._value = value
        self.accept = accept
        self.multiple = multiple
        self.directory = directory
        self.invalid = invalid
        self.size = size
        self.triggerLabel = triggerLabel
        self.pasteLabel = pasteLabel
        self.receivedLabel = receivedLabel
        self.rejectedLabel = rejectedLabel
        self.onChange = onChange
        self.onReject = onReject
    }

    @Environment(\.isEnabled) private var isEnabled
    @State private var picking = false
    @State private var announcement = ""

    public var body: some View {
        Stack(gap: "sm", align: .start) {
            Stack(direction: .inline, gap: "sm", align: .center) {
                trigger
                if let pasteLabel { pasteControl(pasteLabel) }
            }
            // 受け取った件数と弾いた件数を知らせる。常設の領域で、割り込ませない
            // （WCAG 2.2 SC 4.1.3）。
            //
            // svelte は `role="status"` の領域を視覚から隠しているが、SwiftUI に生きた
            // 領域にあたる機構が無い。`AccessibilityNotification.Announcement` は割り込む
            // ので契約と合わない。見える文にすると常設であることは満たすが、目で見る側にも
            // 出る。svelte と姿が割れる（HOLES #28）。
            if !announcement.isEmpty {
                Text(announcement)
                    .textStyle(.bodySm)
                    .foregroundStyle(.stemcellMuted)
            }
        }
        .fileImporter(
            isPresented: $picking,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: multiple
        ) { result in
            guard case .success(let picked) = result, !picked.isEmpty else { return }
            // 選択画面は accept で環境が絞っている。ここで絞り直さないのは svelte と同じで、
            // 素通しになるのは落とす経路と貼る経路だけである。
            publish(multiple ? value + picked : picked)
        }
    }

    /// 選ぶ操作。`Button` をそのまま使う（第2条）。
    private var trigger: some View {
        Button(triggerLabel) { picking = true }
            .buttonStyle(.stemcell(.outlined, color: invalid ? .danger : .plain, size: size))
    }

    /// 貼り付けの口。`PasteButton` は iOS では `UIPasteControl` で、押したときだけ
    /// 貼り付け先へ触れる。だから環境が貼り付けの確認を出さない。
    ///
    /// 置く場所は選ぶ操作の隣にした（契約 §4 が未確定にしていた件）。欄の中へ入れる形も
    /// 考えたが、この欄は入力の枠を持たず操作しか持たないので、入れる先が無い。
    ///
    /// 姿は譲る。`PasteButton` は `buttonStyle` を受け付けず、文言も自分で持つ。それが
    /// privacy の保証と引き換えだからである。渡せるのは `controlSize` と `tint` と
    /// `buttonBorderShape` だけで、渡した名前は読み上げにしか効かない（HOLES #29）。
    /// 文言を環境が持つのは i18n.md §1 とはむしろ揃う。DS は文言を持たない。
    private func pasteControl(_ label: String) -> some View {
        PasteButton(payloadType: URL.self) { urls in
            receive(urls)
        }
        .buttonBorderShape(.roundedRectangle)
        .controlSize(size.controlSize)
        .tint(StemcellIntent.plain.colors.border.resolved)
        .accessibilityLabel(label)
        .disabled(!isEnabled)
    }

    /// 貼る経路の受け取り。環境の選択画面は accept で勝手に絞るが、こちらは素通しなので
    /// 同じ絞り込みを当てる（契約 §2）。件数は部品が知っているので、部品が知らせる。
    private func receive(_ incoming: [URL]) {
        guard isEnabled, !incoming.isEmpty else { return }
        let (accepted, rejected) = AcceptList.split(incoming, accept: accept)
        let taken = multiple ? accepted : Array(accepted.prefix(1))
        if !taken.isEmpty { publish(multiple ? value + taken : taken) }
        if !rejected.isEmpty { onReject(rejected) }

        let said = [
            taken.isEmpty ? nil : receivedLabel?.replacingOccurrences(of: "{n}", with: "\(taken.count)"),
            rejected.isEmpty ? nil : rejectedLabel?.replacingOccurrences(of: "{n}", with: "\(rejected.count)"),
        ].compactMap { $0 }.joined(separator: " ")
        if !said.isEmpty { announcement = said }
    }

    private func publish(_ files: [URL]) {
        value = files
        onChange(files)
    }

    /// 受け入れる種類を環境の語彙へ写す。契約は MIME 型の列で言い、Apple は `UTType` で言う。
    ///
    /// 総称（`image/*`）は `UTType(mimeType:)` が解かないので、上位の型へ自分で寄せる。
    /// 解けなかった規則は落とす。落とすと絞りが緩むだけで、受け取ったあとの判定は
    /// `AcceptList` が同じ規則で当て直す（第7条）。
    private var allowedTypes: [UTType] {
        if directory { return [.folder] }
        guard let accept, !accept.isEmpty else { return [.item] }
        let types = accept.compactMap { rule -> UTType? in
            let r = rule.trimmingCharacters(in: .whitespaces).lowercased()
            if r == "*" || r == "*/*" { return .item }
            if r.hasPrefix(".") { return UTType(filenameExtension: String(r.dropFirst())) }
            if r.hasSuffix("/*") {
                switch String(r.dropLast(2)) {
                case "image": return .image
                case "video": return .movie
                case "audio": return .audio
                case "text": return .text
                default: return nil
                }
            }
            return UTType(mimeType: r)
        }
        return types.isEmpty ? [.item] : types
    }
}
