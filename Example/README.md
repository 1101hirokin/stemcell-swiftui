# Example

姿を見るための見本。svelte の playground にあたる。

## Mac で見る

```sh
swift run Example
```

## iOS の実機で見る

Xcode で iOS の App ターゲットを作り、`Example/Sources/` の中身を足して、この
パッケージを local package として依存に入れる。`.xcodeproj` を置いていないのは、
生成したものを検証できないまま持つと壊れたときに直せないからである。macOS の側で
一度作って、そのときコミットする。
