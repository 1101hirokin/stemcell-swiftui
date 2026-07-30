import SwiftUI
import StemcellTokens

/// 連続曲率の角（shape.md §4）。Web と同じ族の曲線を描く。
///
/// SwiftUI は `RoundedRectangle(style: .continuous)` を無償で持っているので、本来は
/// それに乗るのが第2条と RFC 0010 の筋である。実際 v0 はそうしていた。乗るのをやめた
/// 理由は、実測で別の曲線だと分かったからである。
///
/// 半径 60pt の角を両方で描かせ、上端からの輪郭を画素で取り出して比べた。
///
/// ```
/// SwiftUI .continuous  135, 116, 105, 98, 93, 88, 84, 80, 77, 74, 72, 69, 67 ...
/// 半径 120px の真円    120, 105,  98, 93, 89, 86, 83, 80, 77, 74, 72, 70, 68 ...
/// ```
///
/// Apple の連続曲率は角の端で公称の半径より外へ張り出し、途中で真円と交差してから
/// わずかに角ばる。CSS の `corner-shape` は `border-radius` が定める角の箱に収まるので、
/// 箱の外へは出られない。族が違うので、引数をどう選んでも重ならない。
/// CSS の八つの引数と突き合わせたところ、`.continuous` にいちばん近いのは
/// `superellipse(1.0)`、つまり円弧だった。契約が採っている 1.8 は最も遠い値である。
///
/// 姿を土地の間で揃えるほうを採り、Web の曲線へ寄せた。HOLES #10 に記録した。
public struct SuperellipseRoundedRectangle: InsettableShape {
    /// 角の半径。
    public var cornerRadius: CGFloat
    /// Lamé 指数。`|x/r|^n + |y/r|^n = 1` の n である。
    public var exponent: CGFloat
    private var insetAmount: CGFloat = 0

    public init(cornerRadius: CGFloat, exponent: CGFloat = StemcellTokens.Shape.lameExponent) {
        self.cornerRadius = cornerRadius
        self.exponent = exponent
    }

    public func inset(by amount: CGFloat) -> Self {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    public func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard r.width > 0, r.height > 0 else { return Path() }
        // 半径が辺の半分を超えたら詰める。pill（9999）はここで capsule 相当へ落ちる。
        let radius = min(cornerRadius, min(r.width, r.height) / 2)
        guard radius > 0 else { return Path(r) }

        var p = Path()
        let seg = 24
        let k = 2 / exponent

        /// 角の弧を、角の箱の左上を原点とみなした比 (u, v) で返す。
        /// `((r-x)/r)^n + ((r-y)/r)^n = 1` を、`A = cos^(2/n)t`、`B = sin^(2/n)t` で媒介する。
        /// t=0 で (0, 1)、t=π/2 で (1, 0) を通る。
        func arc(_ i: Int) -> (u: CGFloat, v: CGFloat) {
            let t = CGFloat(i) / CGFloat(seg) * (.pi / 2)
            return (1 - pow(cos(t), k), 1 - pow(sin(t), k))
        }

        // 左上。(minX, minY+radius) から (minX+radius, minY) へ。
        p.move(to: CGPoint(x: r.minX, y: r.minY + radius))
        for i in 0...seg {
            let a = arc(i)
            p.addLine(to: CGPoint(x: r.minX + a.u * radius, y: r.minY + a.v * radius))
        }
        // 右上。(maxX-radius, minY) から (maxX, minY+radius) へ。u と v を入れ替える。
        p.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
        for i in 0...seg {
            let a = arc(i)
            p.addLine(to: CGPoint(x: r.maxX - a.v * radius, y: r.minY + a.u * radius))
        }
        // 右下。(maxX, maxY-radius) から (maxX-radius, maxY) へ。
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radius))
        for i in 0...seg {
            let a = arc(i)
            p.addLine(to: CGPoint(x: r.maxX - a.u * radius, y: r.maxY - a.v * radius))
        }
        // 左下。(minX+radius, maxY) から (minX, maxY-radius) へ。
        p.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
        for i in 0...seg {
            let a = arc(i)
            p.addLine(to: CGPoint(x: r.minX + a.v * radius, y: r.maxY - a.u * radius))
        }
        p.closeSubpath()
        return p
    }
}

extension StemcellTokens.Shape {
    /// 正準のスムージング（0.6）を、この土地の尺度へ写した値。
    ///
    /// shape.md §4-1 は「正準値は一つで、それを自分の尺度へ写す責任は各プラットフォームが
    /// 持つ」と定める。Web の尺度は CSS の `superellipse()` の引数で、契約はそこへ 1.8 を
    /// 割り当てている。SwiftUI の尺度は Lamé 指数で、Chrome が実際に描く曲線へ当てはめると
    /// 3.53 が出た。`2^1.8 = 3.482` なので、CSS の引数 k は Lamé 指数 `2^k` に写っている。
    /// 画素の量子化ぶんの差なので、式のほうを採る。
    public static var lameExponent: CGFloat { pow(2, 1.8) }
}

extension View {
    /// 高さの段から影を当てる（elevation.md §4 の二層、§7 の「レベルから radius と offset を
    /// 導くのは SwiftUI 側の仕事」）。色と不透明度はトークンが持つ。
    ///
    /// 部品ごとに同じ式を書くと、いつか片方だけずれる。実際 `Dialog` と `Popover` で
    /// 同じ式が二度書かれていた。
    /// 段が 0 のときは影を当てない。半径 0 の影でも SwiftUI は合成の経路を作るので、
    /// 見えないものに描画の代価を払うことになる。`Card` の枠の面が最初にここを踏んだ。
    @ViewBuilder
    func stemcellShadow(level: CGFloat, colors: StemcellColors) -> some View {
        if level > 0 {
            self
                .shadow(color: colors.shadowPenumbra.resolved, radius: level * 4, y: level)
                .shadow(color: colors.shadowUmbra.resolved, radius: level, y: level / 2)
        } else {
            self
        }
    }
}
