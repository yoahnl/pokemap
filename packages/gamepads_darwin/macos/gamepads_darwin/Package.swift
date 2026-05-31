// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "gamepads_darwin",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "gamepads-darwin", targets: ["gamepads_darwin"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "gamepads_darwin",
      dependencies: []
    )
  ]
)
