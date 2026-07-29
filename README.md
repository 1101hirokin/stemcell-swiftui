# stemcell-swiftui

stemcell の SwiftUI 実装。まだ何も動かない。設計の草案が [DESIGN.md](./DESIGN.md) にある。

規範は [stemcell-component-prompts](https://github.com/1101hirokin/stemcell-component-prompts) が持つ。
契約に適合すると宣言し、そこが pin する版に追従する（GOVERNANCE §6-2）。

## 立ち位置

SwiftUI を置き換えない。SwiftUI で書いたものが揃うようにする。

SwiftUI が持つ部品には様式を当て、持たない部品だけを型として足す。
`Button` は SwiftUI の `Button` のままで、`.buttonStyle(.stemcell)` が姿を決める。
`Badge` や `Card` のように SwiftUI に無いものは、契約の名前で型が来る。

この分け方の理由は [DESIGN.md](./DESIGN.md) §2 にある。要点は、SwiftUI の `Button` が
Liquid Glass も鍵盤操作も Dynamic Type も VoiceOver も無償で持っていて、自前で描くと
それを捨てることになる、である（第2条 / RFC 0010）。

## 入れ方（予定）

```swift
.package(url: "https://github.com/1101hirokin/stemcell-swiftui.git", from: "0.0.1")
```

床は iOS 26 と macOS 26。理由は [DESIGN.md](./DESIGN.md) §5。

## v0 の範囲

13 部品。網羅ではなく、規範の危ないところを通ることを狙う。
一覧と、それぞれで何が決まるかは [DESIGN.md](./DESIGN.md) §10。

## 穴

仕様どおりに作れなかったところ、仕様が黙っていたところは `HOLES.md` に記録する。
svelte 実装と同じ運用で、そこが上流へ還流する種になる。
