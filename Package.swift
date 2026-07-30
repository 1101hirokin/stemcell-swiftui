// swift-tools-version: 6.2
import PackageDescription

// stemcell の SwiftUI 実装。規範は stemcell-component-prompts が持つ。
// 床が iOS 26 / macOS 26 なのは、Liquid Glass が既定になった最初の版だからである（DESIGN.md §5）。
let package = Package(
    name: "stemcell-swiftui",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Stemcell", targets: ["Stemcell"]),
        // 実機で見るための見本。macOS では `swift run Example` で立ち上がる。
        // iOS の実機へ入れる Xcode ターゲットは、macOS の側で足す（Example/README.md）。
        .executable(name: "Example", targets: ["Example"]),
        // 画面を出さずに姿を焼く道具（DESIGN.md §7）。窓を画面の外へ置いて cacheDisplay で
        // ビットマップへ落とす。screencapture と違って画面収録の許可も、窓を掴むことも要らない。
        .executable(name: "Shots", targets: ["Shots"]),
    ],
    dependencies: [
        // 版は npm の側と同じ番号である。源が一つなので番号も一つにする。
        .package(url: "https://github.com/1101hirokin/stemcell-tokens.git", exact: "0.0.0-alpha.16"),
    ],
    targets: [
        .target(name: "Stemcell", dependencies: [
            .product(name: "StemcellTokens", package: "stemcell-tokens"),
        ]),
        .executableTarget(name: "Example", dependencies: ["Stemcell"], path: "Example/Sources"),
        .executableTarget(name: "Shots", dependencies: ["Stemcell"], path: "Tools/Shots"),
        .testTarget(name: "StemcellTests", dependencies: ["Stemcell"]),
    ]
)
