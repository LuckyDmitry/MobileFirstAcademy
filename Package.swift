// swift-tools-version:5.8

import PackageDescription

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.57.0")),
]

packageDependencies.append(.package(url: "https://github.com/nerzh/telegram-vapor-bot", .upToNextMajor(from: "2.1.0")))


let package = Package(
    name: "App",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: packageDependencies,
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "TelegramVaporBot", package: "telegram-vapor-bot"),
            ],
            path: "Sources"
        )
    ]
)


