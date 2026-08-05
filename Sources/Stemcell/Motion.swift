import SwiftUI
import StemcellTokens

/// 動きの意味の段（motion.md §5）。契約は `motion.feedback` `motion.transition`
/// `motion.entrance` `motion.exit` という意味の名前で動きを要求する。
///
/// 前の版はここが無く、各部品が `Motion.Duration.fast02` という生の段を直に引き、曲線は
/// SwiftUI の `.easeOut` で代用していた。`Motion.Feedback.duration` はたまたま `fast02` と
/// 同じ 0.11 なので見た目には出なかったが、値が同じことは名前が同じ理由にならない。
/// 曲線に至っては `Motion.Easing.standard`（0.2, 0, 0.38, 0.9）をどの部品も引いていなかった。
/// 落とす面のレビューで見つかった。
///
/// 動きを減らす設定は時間を 0 にする。0 のときは `nil` を返して、SwiftUI に動きそのものを
/// 持たせない（a11y.md。環境が言ったことを偽装しない）。
enum StemcellMotion {
    /// 触れたことへの返し。ホバー、押下、焦点の移り。
    static func feedback(_ reduce: Bool) -> Animation? {
        curve(StemcellTokens.Motion.Feedback.duration, StemcellTokens.Motion.Feedback.easing, reduce)
    }

    /// 場所や姿の移り。
    static func transition(_ reduce: Bool) -> Animation? {
        curve(StemcellTokens.Motion.Transition.duration, StemcellTokens.Motion.Transition.easing, reduce)
    }

    /// 現れる。
    static func entrance(_ reduce: Bool) -> Animation? {
        curve(StemcellTokens.Motion.Entrance.duration, StemcellTokens.Motion.Entrance.easing, reduce)
    }

    /// 去る。
    static func exit(_ reduce: Bool) -> Animation? {
        curve(StemcellTokens.Motion.Exit.duration, StemcellTokens.Motion.Exit.easing, reduce)
    }

    private static func curve(
        _ seconds: TimeInterval,
        _ easing: (CGFloat, CGFloat, CGFloat, CGFloat),
        _ reduce: Bool
    ) -> Animation? {
        // 尺は環境ごとの倍率を持つ（Web の `--motion-scale`）。いまは 1 だが、引かないと
        // 倍率を変えたときに SwiftUI だけ追従しない。
        let d = reduce
            ? StemcellTokens.Motion.None.duration
            : seconds * StemcellTokens.Motion.scale
        guard d > 0 else { return nil }
        return .timingCurve(easing.0, easing.1, easing.2, easing.3, duration: d)
    }
}
