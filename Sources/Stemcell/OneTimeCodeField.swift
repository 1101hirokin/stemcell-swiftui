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

/// 打った文字を伏せる指定。契約の `masked` `showValueLabel` `hideValueLabel`
/// `revealedMessage` `hiddenMessage` を一つにまとめたものである。
///
/// 契約は「伏せたときは見せ直す手段を部品が必ず持つ」と定め、i18n.md §1 は「DS は文言を
/// 持たない」と定める。五つを平らな引数で並べると、名前も知らせる文も既定値の空のまま、
/// 黙って伏せられてしまう。四つは `masked` が真のときにだけ意味を持ち、偽のときは全部
/// 死ぬので、伏せる指定そのものへ束ねた。伏せないなら `nil` を渡す。
public struct OneTimeCodeMask: Sendable, Equatable {
    let showValueLabel: String
    let hideValueLabel: String
    let revealedMessage: String
    let hiddenMessage: String

    /// - Parameters:
    ///   - showValueLabel: コードを見せる操作の名前（「コードを表示する」）。
    ///   - hideValueLabel: コードを伏せる操作の名前（「コードを隠す」）。
    ///   - revealedMessage: 見せたときに支援技術へ届ける文。値そのものは流さない。
    ///   - hiddenMessage: 隠したときに支援技術へ届ける文。
    public init(
        showValueLabel: String,
        hideValueLabel: String,
        revealedMessage: String,
        hiddenMessage: String
    ) {
        self.showValueLabel = showValueLabel
        self.hideValueLabel = hideValueLabel
        self.revealedMessage = revealedMessage
        self.hiddenMessage = hiddenMessage
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
/// 一つの欄にした判断がそのまま効く。
///
/// 契約の prop のうち、ここが受けないものが三つある。
///
/// `label` `description` `error` `required` `labelHidden` は `Field` が持つ。契約の
/// a11y notes が「解剖と所有は他のフィールドと同じである」と書いていて、他の欄も
/// `Field` と `.fieldStyle()` に割っている。名前をここでも受けると真実が二つになる。
///
/// `disabled` は `.disabled()` へ委ねる。native に口があるものを引数にしない（`Button` と
/// 同じ判断）。
///
/// `name` は受けない。SwiftUI に HTML の form が無く、送信も reset も native の機構が無い
/// （field.md §5）。ここは退避ではなく、写す先が存在しない。
public struct OneTimeCodeField: View {
    @Binding private var value: String
    private let length: Int
    private let charset: OneTimeCodeCharset
    private let mask: OneTimeCodeMask?
    private let invalid: Bool
    private let readOnly: Bool
    private let size: StemcellSize
    private let onComplete: (String) -> Void

    /// - Parameters:
    ///   - value: 打たれた文字。桁が揃う前の途中の値も流れる。値はアプリが持つ。
    ///   - length: 桁の数。発行する側の政策なので消費者が渡す。
    ///   - charset: 打てる文字。鍵盤の指定はここから導く。
    ///   - mask: 打った文字を伏せる。渡すと見せ直す手段が並ぶ。伏せないなら nil。
    ///   - invalid: 不正。intent を danger へ差し替える（state.md §7）。
    ///   - readOnly: 読むだけ。invalid とは同時に成立しない（state.md §6）。
    ///   - size: 大きさの段。枠の内側の余白がここから決まる。
    ///   - onComplete: 桁が揃った。値の変化とは別の通知である（契約の裁定）。
    public init(
        value: Binding<String>,
        length: Int = 6,
        charset: OneTimeCodeCharset = .numeric,
        mask: OneTimeCodeMask? = nil,
        invalid: Bool = false,
        readOnly: Bool = false,
        size: StemcellSize = .md,
        onComplete: @escaping (String) -> Void = { _ in }
    ) {
        self._value = value
        // 桁の数は消費者が渡す数なので、語彙外の値が来る。落とさずに一桁へ退避する
        // （第7条。Stack が語彙外の段を既定へ寄せるのと同じ扱い）。
        self.length = max(1, length)
        self.charset = charset
        self.mask = mask
        // 読むだけと不正は同時に成立しない（state.md §6）。両方来たら不正を捨てる。
        // svelte も同じ扱いで、あちらは警告も出す。
        self.invalid = readOnly ? false : invalid
        self.readOnly = readOnly
        self.size = size
        self.onComplete = onComplete
    }

    @Environment(\.stemcellTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool
    @State private var revealed = false
    /// 打つ字の大きさ。利用者が本文を大きくすれば枠も伸びる。
    @ScaledMetric(relativeTo: .body) private var typedSize: CGFloat = StemcellTokens.Typography.BodyMd.fontSize

    /// 欄の行高。打つ字の一行分と、縦の inset 二つ分である（svelte の `--sc-field-side`
    /// と同じ組み立て）。枠の高さも、付属の正方形の一辺も、これ一つから出る。
    private var side: CGFloat {
        typedSize * StemcellTokens.Typography.BodyMd.lineHeight + size.inset * 2
    }

    public var body: some View {
        // 枠の並びと、伏せる切り替えのあいだ。Svelte の `.sc-otc-control` と同じ段を引く。
        HStack(spacing: StemcellTokens.Spacing.Inline.md) {
            boxes
            if let mask { revealToggle(mask) }
        }
    }

    /// 桁の枠。見た目であって欄ではない。押しても焦点は一つの欄へ行く。
    private var boxes: some View {
        // 値を桁へ割るのは一度でよい。枠ごとに `Array(value)` を作ると、一回の描き直しで
        // 桁の数だけ走る。
        let chars = Array(value)
        // 桁と桁のあいだ。並びと切り替えのあいだ（inline-md）より狭い段を引く。
        // 一つの値であることが、間隔の差でも読めるようにする（Svelte と同じ割り当て）。
        return HStack(spacing: StemcellTokens.Spacing.Inline.sm) {
            ForEach(0..<length, id: \.self) { i in box(at: i, chars: chars) }
        }
        // 枠は見た目なので、押す先も読み上げも欄へ渡す。
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // 本物の欄は背景へ敷く。ZStack だと欄と枠が対等に大きさを出し合うので、見えない欄の
        // 理想幅が組の幅に混ざりうる。背景は本体の大きさに従うだけなので、大きさを決めるのは
        // 枠のほうだと構造で決まる。
        //
        // 順序が意味を持つ。`.accessibilityHidden(true)` は、それを書いた時点までの枠だけに
        // かかる。あとから背景で足す欄には及ばない。入れ替えると欄ごと支援技術から消える。
        .background { hiddenField }
        // 親の幅いっぱいへ均等に割る（契約の Normative）。
        .frame(maxWidth: .infinity)
        // 押せる範囲はここである。枠は `allowsHitTesting(false)` を持つので、押す先は
        // この一枚しか無い。当たり判定の床はその押す先へ敷く（size.rules.json の
        // `appliesTo: hit-region`）。枠の一つ一つへ敷くと、床が見た目の寸法になって
        // 段が効かなくなる。HOLES #4 と同じ取り違えである。
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture { if !readOnly { focused = true } }
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
            // 読むだけは打てないことだけを借りる（FieldStyle と同じ判断）。字の色は
            // ここでは透明なので、灰へ落ちても見た目に出ない。
            .disabled(readOnly)
            // 初めて出たときにも桁で切る。`onChange` は最初の値では鳴らないので、
            // 桁を超えた値を渡されるとそのまま残り、揃っているのに完了も出なかった。
            .onAppear { normalize(value) }
            .onChange(of: value) { _, new in normalize(new) }
    }

    /// 打てる文字だけを残し、桁で切る。大文字小文字は変えない（正規化はアプリ）。
    private func normalize(_ new: String) {
        let cleaned = String(new.filter(charset.accepts).prefix(length))
        if cleaned != new { value = cleaned }
        // 揃うたびに知らせる。貼り付けや自動入力で一度に埋まったときも出る。
        if cleaned.count == length { onComplete(cleaned) }
    }

    private func box(at i: Int, chars: [Character]) -> some View {
        let filled = i < chars.count
        // いま打っている桁。焦点があるときだけ強調する。揃ったあとは最後の桁を指す。
        // `i == chars.count` だけだと、揃った瞬間にどこも指さなくなる。
        let current = focused && i == min(chars.count, length - 1) && !readOnly
        let hidden = mask != nil && !revealed
        return Text(filled ? (hidden ? "•" : String(chars[i])) : " ")
            .textStyle(.bodyMd)
            // 数字は桁で揃える（typography.md §5）。幅の違う字が混ざると桁がずれて見える。
            .monospacedDigit()
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            // 枠の高さは中身の有無で変わらない（契約の裁定 2026-07-28）。素朴に組むと
            // 空の枠に行の箱が立たず、打つほど枠が伸びる。行高で固定する。床の 44 を
            // ここへ敷くと、段を変えても高さが動かなくなるので敷かない。
            .frame(height: side)
            .background(surface)
            .clipShape(shape)
            .overlay { shape.strokeBorder(borderColor(current: current), lineWidth: StemcellTokens.Shape.borderWidth) }
            // いま打っている桁に輪を出す。枠の並び全体ではない。次に何が起きるかが読める
            // ようにするためで、契約が `focus-ring` のトークンを名指している。
            .overlay { focusRing(current: current) }
            .animation(transition, value: current)
    }

    /// いま打っている桁の輪。native が描く輪は隠した欄の一つぶん、つまり並び全体を囲む。
    /// 契約が求めているのは桁ごとなので、ここは譲らずに描く（HOLES #11 とは事情が違う）。
    @ViewBuilder
    private func focusRing(current: Bool) -> some View {
        if current {
            shape
                .strokeBorder(ringColor, lineWidth: StemcellTokens.FocusRing.width)
                .padding(-(StemcellTokens.FocusRing.offset + StemcellTokens.FocusRing.width))
        }
    }

    private var ringColor: Color {
        (invalid ? StemcellIntent.danger : StemcellIntent.plain).colors.focusRing.resolved
    }

    private var shape: SuperellipseRoundedRectangle {
        SuperellipseRoundedRectangle(cornerRadius: StemcellTokens.Shape.Continuous.Semantic.control)
    }

    /// 読むだけは無効ではない。面は普通のままにする。
    ///
    /// `FieldStyle` は読むだけの面を地へ寄せているが、明るいテーマでは `surface` が
    /// `background` の別名なので何も起きない（HOLES #24）。svelte は読むだけに視覚の差を
    /// 与えておらず、native の属性として渡すだけである。効かない差を真似ても仕方がないので、
    /// ここは svelte に揃えた。打てないことは押しても焦点が来ないことで伝わる。
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
        //
        // いま打っている桁の見せ方は Expressive である。焦点そのものの輪郭は native が
        // 描くので、ここは輪郭ではなく枠のチャンネルを動かしている（DESIGN.md の Ceded）。
        if !isEnabled { return DisabledColors.border.resolved }
        if invalid { return StemcellIntent.danger.colors.border.resolved }
        // 輪の色は枠にも回す（Svelte の `border-color: var(--_ring)` と同じ）。
        if current { return ringColor }
        return theme.colors.border.resolved
    }

    private var transition: Animation? { StemcellMotion.feedback(reduceMotion) }

    /// 伏せたときに見せ直す手段。契約が「必ず持つ」と定めている。打ち間違いを直す手段が
    /// 全部消して打ち直すことしか無くなるためである（PasswordField と同じ判断）。
    ///
    /// 欄の中の付属なので正方形で、角を丸めない（field.md §6-1-b）。`IconButton` では
    /// なく `FieldAdornmentButtonStyle` を使うのはそのためである。あちらの `shape` は
    /// 契約が control と pill しか許していない（発明不可）。
    private func revealToggle(_ mask: OneTimeCodeMask) -> some View {
        Button {
            revealed.toggle()
            // 切り替えの結果を文で知らせる。名前が入れ替わるだけだと、押した人には
            // 何が起きたか届かない。値そのものは流さない（契約の a11y notes）。
            AccessibilityNotification.Announcement(
                revealed ? mask.revealedMessage : mask.hiddenMessage
            ).post()
        } label: {
            Image(systemName: revealed ? "eye.slash" : "eye")
        }
        .buttonStyle(FieldAdornmentButtonStyle(side: side))
        .disabled(readOnly)
        .accessibilityLabel(revealed ? mask.hideValueLabel : mask.showValueLabel)
    }
}
