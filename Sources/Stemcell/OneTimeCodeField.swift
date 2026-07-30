import SwiftUI
import StemcellTokens

/// 打てる文字の集合（契約の `charset`）。正規表現は受け取らない。
///
/// 打てる文字は入力様式そのものを決めるので、列挙でなければ鍵盤を導けない。
/// 正規表現の方言は土地ごとに違い、そして DS は検証しない（契約の裁定 2026-07-28）。
public enum OneTimeCodeCharset: String, Sendable, CaseIterable {
    case numeric, alphanumeric

    func accepts(_ c: Character) -> Bool {
        switch self {
        case .numeric: return c.isNumber
        case .alphanumeric: return c.isNumber || c.isLetter
        }
    }

    #if os(iOS)
    var keyboard: UIKeyboardType {
        switch self {
        case .numeric: return .numberPad
        case .alphanumeric: return .asciiCapable
        }
    }
    #endif
}

/// 打った文字を伏せる指定。見せ直す操作の名前を同梱する。
///
/// 契約は「伏せたときは見せ直す手段を部品が必ず持つ」と定め、i18n.md §1 は「DS は文言を
/// 持たない」と定める。二つを別々の引数にすると、名前の無いボタンが既定値のまま黙って出せて
/// しまう。伏せる指定そのものに文言を持たせて、名前無しで伏せられない形にする。
public struct OneTimeCodeMask: Sendable, Equatable {
    let showLabel: String
    let hideLabel: String

    /// - Parameters:
    ///   - showLabel: コードを見せる操作の名前。
    ///   - hideLabel: コードを伏せる操作の名前。
    public init(showLabel: String, hideLabel: String) {
        self.showLabel = showLabel
        self.hideLabel = hideLabel
    }
}

/// 確認コードを打つ欄（契約の `OneTimeCodeField`）。
///
/// 見えている枠は桁の数だけ並ぶが、打てる欄は一つである。契約の裁定で、桁ごとに欄を分けると
/// 貼り付けが一桁目にしか入らず、SMS からの自動入力も効かず、読み上げが「6 個の欄のうち
/// 1 個目」と読んで一つの値に聞こえない。
///
/// SwiftUI に相当する部品が無いので型で出す（DESIGN.md §2）。
///
/// 自動入力は native が持っている。`textContentType(.oneTimeCode)` を渡すだけで、SMS から
/// 拾って一度に埋まる。契約の a11y notes が「自動入力の機構は一つの欄に紐づく」と書いていて、
/// 一つの欄にした判断がそのまま効く。BACKLOG の「鍵盤の指定の対応物」はここで埋まる。
public struct OneTimeCodeField: View {
    @Binding private var value: String
    private let length: Int
    private let charset: OneTimeCodeCharset
    private let mask: OneTimeCodeMask?
    private let invalid: Bool
    private let onComplete: (String) -> Void

    /// - Parameters:
    ///   - value: 打たれた文字。桁が揃う前の途中の値も流れる。値はアプリが持つ。
    ///   - length: 桁の数。発行する側の政策なので消費者が渡す。
    ///   - charset: 打てる文字。鍵盤の指定はここから導く。
    ///   - mask: 打った文字を伏せる。渡すと見せ直す手段が並ぶ。伏せないなら nil。
    ///   - invalid: 不正。intent を danger へ差し替える（state.md §7）。
    ///   - onComplete: 桁が揃った。値の変化とは別の通知である（契約の裁定）。
    public init(
        value: Binding<String>,
        length: Int = 6,
        charset: OneTimeCodeCharset = .numeric,
        mask: OneTimeCodeMask? = nil,
        invalid: Bool = false,
        onComplete: @escaping (String) -> Void = { _ in }
    ) {
        self._value = value
        self.length = length
        self.charset = charset
        self.mask = mask
        self.invalid = invalid
        self.onComplete = onComplete
    }

    @Environment(\.stemcellTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var focused: Bool
    @State private var revealed = false

    public var body: some View {
        HStack(spacing: StemcellTokens.Spacing.Inline.md) {
            boxes
            if let mask { revealToggle(mask) }
        }
    }

    /// 桁の枠。見た目であって欄ではない。押しても焦点は一つの欄へ行く。
    private var boxes: some View {
        HStack(spacing: StemcellTokens.Spacing.Inline.md) {
            ForEach(0..<length, id: \.self) { i in box(at: i) }
        }
        // 枠は見た目なので、押す先も読み上げも欄へ渡す。
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // 本物の欄は背景へ敷く。ZStack だと欄と枠が対等に大きさを出し合うので、見えない欄の
        // 理想幅が組の幅に混ざりうる。背景は本体の大きさに従うだけなので、大きさを決めるのは
        // 枠のほうだと構造で決まる。
        .background { hiddenField }
        // 親の幅いっぱいへ均等に割る（契約の Normative）。
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
    }

    /// 本物の欄。透かして敷き、焦点も読み上げも貼り付けも自動入力もこちらが受ける
    /// （契約の a11y notes）。
    private var hiddenField: some View {
        TextField("", text: $value)
            .textFieldStyle(.plain)
            .focused($focused)
            .textContentType(.oneTimeCode)
            #if os(iOS)
            .keyboardType(charset.keyboard)
            #endif
            .foregroundStyle(Color.clear)
            .accentColor(.clear)
            .onChange(of: value) { _, new in
                // 打てる文字だけを残し、桁で切る。大文字小文字は変えない（正規化はアプリ）。
                let cleaned = String(new.filter(charset.accepts).prefix(length))
                if cleaned != new { value = cleaned }
                // 揃うたびに知らせる。貼り付けや自動入力で一度に埋まったときも出る。
                if cleaned.count == length { onComplete(cleaned) }
            }
    }

    private func box(at i: Int) -> some View {
        let chars = Array(value)
        let filled = i < chars.count
        // いま打っている桁。焦点があるときだけ強調する。
        let current = focused && i == chars.count
        let hidden = mask != nil && !revealed
        return Text(filled ? (hidden ? "•" : String(chars[i])) : " ")
            .textStyle(.bodyMd)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(minWidth: 44, minHeight: 44)
            .background(surface)
            .clipShape(shape)
            .overlay { shape.strokeBorder(borderColor(current: current), lineWidth: StemcellTokens.Shape.borderWidth) }
    }

    private var shape: SuperellipseRoundedRectangle {
        SuperellipseRoundedRectangle(cornerRadius: StemcellTokens.Shape.Continuous.Semantic.control)
    }

    private var surface: Color {
        isEnabled ? theme.colors.surface.resolved : DisabledColors.softBg.resolved
    }

    /// 使えないときは字も落とす。地と縁だけ落として字を濃いまま残すと、押せそうに見える
    /// （state.md §3。使えないほうが強い）。撮って気づいた。
    private var foreground: Color {
        isEnabled ? theme.colors.foreground.resolved : DisabledColors.fg.resolved
    }

    private func borderColor(current: Bool) -> Color {
        // 使えないほうが強い（state.md §3）。不正は intent を danger へ差し替える（§7）。
        if !isEnabled { return DisabledColors.border.resolved }
        if invalid { return StemcellIntent.danger.colors.border.resolved }
        if current { return StemcellIntent.primary.colors.border.resolved }
        return theme.colors.border.resolved
    }

    /// 伏せたときに見せ直す手段。契約が「必ず持つ」と定めている。打ち間違いを直す手段が
    /// 全部消して打ち直すことしか無くなるためである（PasswordField と同じ判断）。
    ///
    /// 欄の中の付属なので正方形で、角を丸めない（field.md §6-1-b）。
    private func revealToggle(_ mask: OneTimeCodeMask) -> some View {
        Button {
            revealed.toggle()
        } label: {
            Image(systemName: revealed ? "eye.slash" : "eye")
        }
        .buttonStyle(.stemcellIcon(.text))
        .accessibilityLabel(revealed ? mask.hideLabel : mask.showLabel)
    }
}
