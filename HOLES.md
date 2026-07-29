# HOLES

仕様どおりに作れなかったところ、仕様が黙っていたところ、実装が先に決めてしまったところを記録する。
ここが上流（[stemcell-component-prompts](https://github.com/1101hirokin/stemcell-component-prompts)）へ
還流する種になる。

## #1 意味を持つ要素の選択（`as`）は Web の prop である

`Box.md` §4 が「意味要素の選択（`as` 相当）を中立に表現できるか。現状は各実装の表現に置いた」を
未確定にしていた。SwiftUI で書いてみて、答えが出た。

写せない。あれは HTML の要素を選ぶための prop であり、SwiftUI に要素の語彙が無い。
`section` にするか `nav` にするかという選択そのものが存在しない。

そして写す必要も無い。要素を選ぶ目的は意味を支援技術へ届けることで、SwiftUI ではそれを
到達性の修飾子が担う（`guidelines/accessibility.md` の写像表がまさにこの形を書いている。
役割に相手が居ないときは名前と値と状態で伝える）。

だから `as` は Web 固有の充足である。`Button.type` や `keyboard=email` と同じ側に置くのが
筋だと考える。中立契約から外し、Web の実装が持つ形。

## #2 交差軸の `stretch` は SwiftUI の揃えに無い

`Stack` の `align: stretch`（既定）は「内容が交差軸方向にいっぱいに広がろうとする」だが、
SwiftUI の `VStack(alignment:)` は `.leading` / `.center` / `.trailing` しか取らない。
広がりは揃えではなく枠の話なので、`.frame(maxWidth: .infinity)` の側で表した。

契約は破っていないが、`stretch` が他の三つと別の機構で実現されることは記録しておく。
実機で他の三つと同じように振る舞うかは、まだ見ていない。

## #3 `align` の四つを実機で見ていない

`start` / `center` / `end` を `VStack` の `alignment` へ写したが、Web の flex の
`align-items` と同じ見え方になるかは確かめていない。Example アプリを置いてから見る。
