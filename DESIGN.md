# stemcell SwiftUI の v0 草案

2026-07-29。まだ一行も実装していない段階で、どう作るかを先に決めるための文書。
規範は [stemcell-component-prompts](https://github.com/1101hirokin/stemcell-component-prompts) が持つ。
ここが決めるのは、その規範を Apple のプラットフォームでどう満たすかである。

---

## 1. 読み手

想定するのは、SwiftUI を書いている iOS エンジニアである。

その人は SPM で依存を入れる。`.padding()` から始まる修飾子の連なりで画面を書く。
テーマは `@Environment` で降りてくるものだと思っている。`Button` も `NavigationStack` も
`Toggle` も自分のものだと思っていて、それを取り上げられることを望んでいない。

だからこのライブラリの立ち位置はこうである。SwiftUI を置き換えるものではない。
SwiftUI で書いたものが揃うようにするものである。

入れたあとに何が変わるかを一文で言えなければならない。いまのところの答えはこうである。
「`Button` の見た目が stemcell になり、SwiftUI に無い部品が使えるようになる」。

## 2. 名前の衝突をどう解くか

81 の契約のうち 11 が SwiftUI と同じ名前を持つ。`Button`、`DatePicker`、`Divider`、`Grid`、
`Link`、`List`、`Menu`、`Slider`、`Table`、`Text`、`TextField`。

`import SwiftUI` と `import Stemcell` を両方書いた画面で、裸の `Button` は曖昧になってコンパイルが
止まる。三つの案がある。

| 案 | 使うときの姿 | 問題 |
|---|---|---|
| 接頭辞 | `StemcellButton(…)` | 憲法の共通言語から名前が外れる。Swift API Design Guidelines も型接頭辞を勧めない |
| 名前空間 | `Stemcell.Button(…)` | 使うたびに長い。11 個のためだけに 81 個へ課す |
| 様式で出す | `Button(…) { }.buttonStyle(.stemcell)` | SwiftUI が持たない部品には使えない |

三つ目を採る。SwiftUI が持つ部品は型を出さず、様式（`ButtonStyle` など）と修飾子で出す。
SwiftUI が持たない 70 個は、契約の名前のまま型として出す。衝突しない。

理由は名前の都合ではない。[RFC 0010](https://github.com/1101hirokin/stemcell-component-prompts/blob/main/decisions/rfc/0010-prefer-native-mechanisms.md)
が第2条に「native の機構で満たす。無償で得られるものを自前で再発明しない」を書いている。
SwiftUI の `Button` は、Liquid Glass も、鍵盤とスイッチコントロールの操作も、Dynamic Type も、
VoiceOver の traits も、押したときの触覚も無償で持っている。自分で `Button` を描けば、それを全部
捨てて書き直すことになる。捨てた分を完全には戻せない。

観念の名は契約が持ち、その土地での言い方は違ってよい。これは新しい判断ではなく、
`state.md` が既に「SwiftUI の `TextField` は束縛を `text` と呼ぶが、それは Swift の土地の声であって
観念の名は `value` である」と書いた線の適用である。

### 対応の形

| 契約 | SwiftUI での姿 |
|---|---|
| `Button` | `Button` ＋ `.buttonStyle(.stemcell(…))` |
| `Switch` | `Toggle` ＋ `.toggleStyle(.stemcellSwitch)` |
| `Checkbox` | `Toggle` ＋ `.toggleStyle(.stemcellCheckbox)` |
| `Slider` | `Slider` ＋ 様式 |
| `TextField` / `Textarea` | `TextField` / `TextEditor` ＋ 様式 |
| `Dialog` / `Drawer` | `.sheet` / `.alert` の上に載る修飾子 |
| `Divider` / `List` / `Menu` / `Link` / `Table` / `Grid` / `Text` / `DatePicker` | SwiftUI のものへ様式を当てる |
| 上記以外の 70 | `Badge`、`Tag`、`Card` のように、契約の名前で型を出す |

## 3. 文脈の配り方

`StemcellProvider` は View ではなく修飾子にする。

SwiftUI の慣習は `.tint()` と `.preferredColorScheme()` と `.environment()` であり、
文脈を配るために木を一段包ませない。包む形にすると、`NavigationStack` や `TabView` の中の
どこに置くかで意味が変わり、消費者が置き場所を毎回考えることになる。

```swift
ContentView()
    .stemcellTheme(.standard)
    .stemcellDensity(.compact)
```

`.stemcellProvider()` という名前は採らない。修飾子の名前としては、何が起きるのかを言っていない。
これで [BACKLOG](https://github.com/1101hirokin/stemcell-component-prompts/blob/main/BACKLOG.md) の
「文脈を配る形が modifier か View か」は閉じる見込みだが、実機で書いてみるまで確定にしない。

## 4. Liquid Glass

憲法の第2条は Liquid Glass を Ceded に列挙している。iOS 26 では再コンパイルするだけで
システムの部品が自動で纏い、iOS 27 では外す道が消えると Apple が言っている。

第2条の判断と Apple の既定が同じ向きなので、ここは楽である。自前で面を描かず SwiftUI の
部品に乗る、という §2 の判断がそのまま効く。

ただし確かめることが二つある。ガラスは浮く層のためのもので、中身の層には敷かない、と Apple が
書いている。stemcell の [`layering.md`](https://github.com/1101hirokin/stemcell-component-prompts/blob/main/foundations/layering.md)
は 7 層を持っている。この二つの層の考え方がぶつからないか。もう一つ、ガラスはガラスを透かせない
ので、`Popover` を `Dialog` の上に出したときに何が起きるか。どちらも実機で見る。

## 5. 版の床

v0 は iOS 26 と macOS 26 を床にする。

理由は姿を一つに保つためである。Liquid Glass が既定になった最初の版がここで、これより下を
支えると、同じ契約から二つの姿が出る。第7条は「その環境で成立する最も近い形へ退避する」と
定めているが、v0 の範囲では退避先を作らず、範囲そのものを狭くする。

床を下げるのは v1 の話にする。下げるときは、退避が第7条を満たすかを一つずつ見ることになる。

## 6. 配布

SPM で配る。公開の git に `Package.swift` を置き、SemVer のタグを打つ。バイナリ（XCFramework）は
作らない。ソースで配れば Xcode が消費者の設定で最適化でき、中を読んで直せる。

```swift
.package(url: "https://github.com/1101hirokin/stemcell-swiftui.git", from: "0.0.1")
```

パッケージ名は `stemcell-swiftui`、モジュール名は `Stemcell` にする。図は
`StemcellCharts` として同じパッケージの別プロダクトに分ける。核だけ要る人に図の重さを
負わせない。これは Web 側で `@stemcell/svelte` と `@stemcell/svelte-charts` を分けたのと同じ判断である。

言語は Swift 6 の strict concurrency で書く。View は `@MainActor` に置く。
トークンの値のような不変の構造体は `Sendable` にする。

## 7. 検証をどう回すか

先に困りごとを書く。SwiftUI は Apple のプラットフォームでしか動かない。作業機は Linux なので、
私はここで書いた Swift をコンパイルも実行も実機確認もできない。

Web のときは実物を見ながら決められた。円グラフの掃きが見えなかったことも、比の書式が二つ
あったことも、動かして初めて分かった。ここではそれが回らない。
WORKFLOW の証拠の規律は「未検証の主張を断定で書かない」と定めているので、回し方を先に
決めないと、書いたそばから未検証の山ができる。

三つの案がある。

| 案 | 誰が回すか | 私の側 |
|---|---|---|
| オーナーが Mac で回す | ビルドと実機確認 | 結果を聞いて直す。往復が要る |
| macOS の CI を立てる | GitHub Actions の macOS ランナー | ログを読める。実機の見た目は見られない |
| 検証できないものを書かない | 契約から機械的に導ける部分だけ | 実装が痩せる |

二つ目を土台にして、姿の判断だけ一つ目で受けるのが現実的だと考えている。CI が
「ビルドが通る」「適合テストが green」までを持ち、「これは速すぎる」「これは読めない」は
実機で見てもらう。

### 7.1 画面を出さずに姿を焼く

上の前提は途中で変わった。作業機が Mac になり、その場でビルドも実行もできるようになった。
それでも姿の確認は詰まった。`screencapture` は画面収録の許可が要り、画面が消灯していれば
真っ黒を返し、窓を掴みそこねれば何も撮れない。実際にそこで何度も止まった。

窓を画面の外へ置いて `cacheDisplay` でビットマップへ落とせば、そのどれも要らない。
`Tools/Shots` がそれである。

```
swift run Shots <題目> <出力.png> [待ち秒] [dark]
```

題目は `Tools/Shots/main.swift` の `Subjects` に足す。部品を並べた View を一つ書けば、
そのまま焼ける対象になる。sheet は別の窓として出るので `attachedSheet` から辿る。

| 撮りたいもの | 手 | 画面が要るか |
|---|---|---|
| View 単体 | `ImageRenderer` | 要らない |
| 窓の中身 | 画面外へ置いて `cacheDisplay` | 要らない |
| macOS の `sheet` | `attachedSheet` から `cacheDisplay` | 要らない |
| iOS の画面 | `simctl io screenshot` | 要らない |
| 押した結果 | 無い | 人が要る |

焼いた画像は測る。行を横切って白でない区間を並べれば枠の幅と間隔が出るし、列を走査すれば
高さが出る。`OneTimeCodeField` の枠の高さが md で 43.0pt であることはこれで確かめた。
svelte が `internal/field-button.css` に「md で 43px」と書いている値と一致する。使えない
ときに枠の地と縁だけ落ちて字が濃いまま残っていたのも、撮って気づいた。

最後の一行が残る穴である。押した結果は撮れない。焦点が当たった桁の強調も、開いた popover も、
「背面を押しても閉じない」のような触った後の姿も、この道では出てこない。`XCUITest` を組むか、
人に押してもらうことになる。

## 8. 適合の検査

契約から生成する。svelte と同じ形だが、測るものが違う。DOM が無いので属性を読めない。

各部品が自分の表面を静的な値として持ち、それを契約と突き合わせる。svelte の `meta.ts` と同型である。

```swift
enum BadgeContract {
    static let props = ["color", "count", "dot", "label", "max", "variant"]
    static let defaults: [String: String] = ["color": "info", "max": "99"]
}
```

これで prop の名前と既定値の食い違いは捕まる。捕まらないのは、宣言と実装が食い違っている場合である。
そこは Swift の型で縛る。`variant` を `enum` にすれば、契約の値集合からずれた瞬間にコンパイルが
止まる。生成器が契約から enum を吐く形にすれば、宣言と実装が同じ源から来る。

見た目は測らない。色や間隔が正しいかは、トークンを引いているかどうかで見る。

## 9. トークン

止まっている。`@stemcell/tokens` は Web の CSS 変数しか出しておらず、Swift が読める形が無い。
出す形を決めるには pt と CSS px の関係を確かめる必要があり、それは
[`size.md`](https://github.com/1101hirokin/stemcell-component-prompts/blob/main/foundations/size.md) §6 が
未確認としている。長さのトークンを何倍で写すかがその答えに依存する。

v0 の最初の仕事はここになる。確かめて、Style Dictionary に Swift の出力を足す。
出す形の案は、`Color` と `CGFloat` と `Font` の静的な値を持つ `enum` である。
明暗は `Color(light:dark:)` 相当を自前で組むか、アセットカタログを生成するかで割れるので、
そこも決める必要がある。

## 10. v0 の範囲

13 部品にする。網羅ではなく、規範の危ないところを全部通ることを狙う。

| 部品 | これで何が決まるか |
|---|---|
| `StemcellProvider` | 文脈を配る形（§3） |
| `Box` | 意味を持つ要素の選び方を中立に書けるか |
| `Stack` / `Cluster` | 配置の原始と間隔のトークン |
| `Text` | 字の役割と Dynamic Type の噛み合わせ |
| `Button` | 様式で出す形（§2）、寸法の段が Ceded になるか、焦点の見せ方、動き |
| `IconButton` | 継承と、当たり判定の床（iOS 44） |
| `TextField` | 欄の解剖と、役割の写像 |
| `Checkbox` / `Switch` | 値と状態、`Toggle` への写像 |
| `Card` | 影と角丸と、暗いテーマで面が消える件 |
| `Dialog` | 焦点の移動と復帰がどこまで無償か、Liquid Glass との噛み合わせ |
| `Popover` | 同上と、ガラスの上のガラス |

これで [BACKLOG](https://github.com/1101hirokin/stemcell-component-prompts/blob/main/BACKLOG.md) の
「SwiftUI の実装で動くもの」12 件のうち、少なくとも 9 件に答えが出る。
残る 3 件（出典の相互参照、推論と道具の到達性、落とす面と貼り付け）は AI の柱と添付の部品なので、
v0 の外に置く。

## 11. 順序

1. トークンに Swift の出力を足す（§9）。pt と px の確認から
2. パッケージの骨組みと CI（§6、§7）
3. `StemcellProvider` と `Box` と `Stack`。ここで文脈と配置と間隔が通る
4. `Button` と `IconButton`。様式で出す形がここで確定する
5. `Text` と `Card`。字と面
6. `TextField` と `Checkbox` と `Switch`。欄と値
7. `Dialog` と `Popover`。焦点とガラス
8. 還流。ここで出た答えを上流の 12 件へ返す

4 と 7 が重い。4 は §2 の判断が実際に書けるかを試す最初の場所で、ここで無理だと分かったら
名前の解き方を選び直すことになる。7 は無償で得られるものの範囲を測る場所である。

## 12. まだ決めていないこと

- 様式に渡す値を引数にするか環境に置くか。`.buttonStyle(.stemcell(.filled, color: .primary))` と
  `.stemcellVariant(.filled)` のどちらが読みやすいか。実際に画面を書いてみるまで決めない
- 明暗のトークンをアセットカタログで配るか、コードで組むか（§9）
- 適合の生成器を Swift で書くか、Bun で書いて Swift を吐くか。svelte と同じ道具を使えるのは後者だが、
  Swift だけで閉じるのは前者である
- `Chart` は Apple の Swift Charts と名前が衝突する。図に着手するときに解く

---

## 12. 修飾子の名前（裁定 2026-07-29）

`View` の拡張は大域に効くので、名前をどう付けるかを場当たりで決めない。二種類に分ける。

| 種類 | 名前 | 例 |
|---|---|---|
| 文脈を配る | 接頭辞を持つ | `.stemcellTheme(_:)`、`.stemcellDensity(_:)` |
| 姿を当てる | native の形に寄せる | `.textStyle(_:)` |

分ける理由は、書く頻度と占める名前の重さが違うことである。文脈を配るのはアプリの根で
一度きりで、stemcell 固有の設定でもあるから、長くても構わないし固有であるべきである。
姿を当てるのは消費者が絶えず書くもので、観念自体は普遍だから、SwiftUI が付けたであろう
名前に寄せる。

SwiftUI が口を持っているものは、そもそも新しい修飾子を作らない。`Button` は
`.buttonStyle(.stemcell(...))` で、様式の値の側に `stemcell` が付く。`Font` や
`ButtonStyle` のような値の型が名前空間を担うのが SwiftUI の形であり、修飾子の名前は
名前空間を担っていない。

契約の prop も、SwiftUI に口があるものは引数にしない。`Button` の `disabled` は
`.disabled()`、`Text` の `truncate` は `.lineLimit(1)`、`muted` は
`.foregroundStyle(.stemcellMuted)` である。二つの道を作ると真実が二つになる（第2条）。

型の名前は二つに分ける。部品をまたぐ語彙（`StemcellIntent` / `StemcellVariant` /
`StemcellSize` / `StemcellTextRole`）は接頭辞を持ち、部品固有の語彙
（`StackDirection` / `StackAlign` / `IconButtonShape`）は部品の名前で呼ぶ。
