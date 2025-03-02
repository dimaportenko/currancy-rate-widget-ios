// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "PrivateExchangeRate",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PrivateExchangeRate",
            targets: ["PrivateExchangeRate"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "PrivateExchangeRate",
            dependencies: ["KeychainAccess"]),
    ]
) 