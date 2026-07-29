// swift-tools-version: 6.2
import PackageDescription

// stemcell の SwiftUI 実装。規範は stemcell-component-prompts が持つ。
// 床が iOS 26 / macOS 26 なのは、Liquid Glass が既定になった最初の版だからである（DESIGN.md §5）。
let package = Package(
    name: "stemcell-swiftui",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Stemcell", targets: ["Stemcell"]),
    ],
    dependencies: [
        // 版は npm の側と同じ番号である。源が一つなので番号も一つにする。
        .package(url: "https://github.com/1101hirokin/stemcell-tokens.git", exact: "0.0.0-alpha.16"),
    ],
    targets: [
        .target(name: "Stemcell", dependencies: [
            .product(name: "StemcellTokens", package: "stemcell-tokens"),
        ]),
        .testTarget(name: "StemcellTests", dependencies: ["Stemcell"]),
    ]
)
