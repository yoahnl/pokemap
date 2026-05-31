// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "gamepads_ios",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "gamepads-ios", targets: ["gamepads_ios"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "gamepads_ios",
      dependencies: []
    )
  ]
)
