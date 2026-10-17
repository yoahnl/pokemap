import CryptoKit
import Foundation
import XCTest

@testable import Runner

final class StudioResourcePackExportWriterTests: XCTestCase {
  var root: URL!
  var writers = [StudioResourcePackExportWriter]()
  var starts = 0
  var stops = 0
  override func setUpWithError() throws {
    root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "p11-writer-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  }
  override func tearDownWithError() throws {
    for writer in writers { XCTAssertTrue(writer.close().isEmpty) }
    XCTAssertEqual(starts, stops)
    try FileManager.default.removeItem(at: root)
  }
  func writer(
    exclusive: Bool = true,
    fault: @escaping (StudioResourcePackExportWriter.Fault) throws -> Void = { _ in }
  ) -> StudioResourcePackExportWriter {
    let writer = StudioResourcePackExportWriter(
      startAccess: { _ in
        self.starts += 1
        return true
      }, stopAccess: { _ in self.stops += 1 }, supportsExclusiveRename: { _ in exclusive },
      fault: fault)
    writers.append(writer)
    return writer
  }
  func begin(
    _ writer: StudioResourcePackExportWriter, bytes: Data, name: String = "original.aveluneassets",
    hash: String? = nil, confirm: (URL) -> Bool = { _ in true }
  ) throws -> String {
    let selected = try writer.choose(
      folder: root, name: name, byteLength: Int64(bytes.count),
      rawSha256: hash ?? SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(),
      confirm: confirm)
    let result = try XCTUnwrap(selected)
    return try XCTUnwrap(result["token"] as? String)
  }
  func append(_ writer: StudioResourcePackExportWriter, token: String, bytes: Data) throws {
    var offset = 0
    while offset < bytes.count {
      let end = min(offset + 128 * 1024, bytes.count)
      _ = try writer.append(
        token: token, offset: Int64(offset), bytes: bytes.subdata(in: offset..<end))
      offset = end
    }
  }
  func testNewFileHasExactBytesAndRetainsTerminalStatusUntilRelease() throws {
    let writer = writer()
    let bytes = Data(repeating: 37, count: 300000)
    let token = try begin(writer, bytes: bytes)
    try append(writer, token: token, bytes: bytes)
    XCTAssertFalse(
      FileManager.default.fileExists(
        atPath: root.appendingPathComponent("original.aveluneassets").path))
    XCTAssertEqual(try writer.seal(token: token)["state"] as? String, "sealed")
    let result = try writer.finish(token: token)
    XCTAssertEqual(result["state"] as? String, "published")
    XCTAssertEqual(
      try Data(contentsOf: root.appendingPathComponent("original.aveluneassets")), bytes)
    XCTAssertEqual(try writer.status(token: token)["state"] as? String, "published")
    _ = try writer.release(token: token)
    _ = try writer.release(token: token)
    XCTAssertThrowsError(try writer.status(token: token))
    XCTAssertEqual(
      try FileManager.default.contentsOfDirectory(atPath: root.path), ["original.aveluneassets"])
  }
  func testReplacementRequiresNativeConfirmationAndRejectsChangedIdentity() throws {
    let target = root.appendingPathComponent("original.aveluneassets")
    let old = Data("old destination".utf8)
    let next = Data("new archive".utf8)
    try old.write(to: target)
    let writer = writer()
    XCTAssertNil(
      try writer.choose(
        folder: root, name: target.lastPathComponent, byteLength: Int64(next.count),
        rawSha256: String(repeating: "a", count: 64), confirm: { _ in false }))
    XCTAssertEqual(try Data(contentsOf: target), old)
    XCTAssertThrowsError(
      try begin(
        writer, bytes: next,
        confirm: { url in
          try! Data("external edit".utf8).write(to: url)
          return true
        }))
    XCTAssertEqual(try Data(contentsOf: target), Data("external edit".utf8))
    let token = try begin(writer, bytes: next)
    try append(writer, token: token, bytes: next)
    _ = try writer.seal(token: token)
    _ = try writer.finish(token: token)
    XCTAssertEqual(try Data(contentsOf: target), next)
    _ = try writer.release(token: token)
  }
  func testNewDestinationAppearingBeforeCommitIsNeverOverwritten() throws {
    let writer = writer()
    let bytes = Data("new archive".utf8)
    let target = root.appendingPathComponent("original.aveluneassets")
    let token = try begin(writer, bytes: bytes)
    try append(writer, token: token, bytes: bytes)
    _ = try writer.seal(token: token)
    try Data("external".utf8).write(to: target)
    XCTAssertThrowsError(try writer.finish(token: token))
    XCTAssertEqual(try Data(contentsOf: target), Data("external".utf8))
    _ = try writer.release(token: token)
    XCTAssertEqual(
      try FileManager.default.contentsOfDirectory(atPath: root.path), [target.lastPathComponent])
  }
  func testUnsupportedExclusiveRenameAndSymlinksAreRefused() throws {
    let unsupported = writer(exclusive: false)
    XCTAssertThrowsError(try begin(unsupported, bytes: Data([1])))
    let writer = writer()
    let target = root.appendingPathComponent("original.aveluneassets")
    let actual = root.appendingPathComponent("actual")
    try Data([4]).write(to: actual)
    try FileManager.default.createSymbolicLink(at: target, withDestinationURL: actual)
    XCTAssertThrowsError(try begin(writer, bytes: Data([1])))
    XCTAssertThrowsError(try begin(writer, bytes: Data([1]), name: "../escape"))
    XCTAssertThrowsError(try begin(writer, bytes: Data([1]), name: "."))
    XCTAssertEqual(try Data(contentsOf: actual), Data([4]))
  }
  func testOffsetChunkLengthAndHashFailuresLeaveDestinationUntouched() throws {
    let target = root.appendingPathComponent("original.aveluneassets")
    let old = Data([7])
    let bytes = Data([1, 2, 3])
    try old.write(to: target)
    for mode in ["offset", "chunk", "length", "hash"] {
      let writer = writer()
      let token = try begin(
        writer, bytes: bytes, hash: mode == "hash" ? String(repeating: "0", count: 64) : nil)
      if mode == "offset" {
        XCTAssertThrowsError(try writer.append(token: token, offset: 1, bytes: bytes))
      } else if mode == "chunk" {
        XCTAssertThrowsError(
          try writer.append(token: token, offset: 0, bytes: Data(repeating: 0, count: 131073)))
      } else if mode == "length" {
        _ = try writer.append(token: token, offset: 0, bytes: Data([1]))
        XCTAssertThrowsError(try writer.seal(token: token))
      } else {
        try append(writer, token: token, bytes: bytes)
        XCTAssertThrowsError(try writer.seal(token: token))
      }
      _ = try writer.release(token: token)
      XCTAssertEqual(try Data(contentsOf: target), old)
    }
  }
  func testWriteSyncCloseAndRenameFaultsKeepOldDestination() throws {
    let target = root.appendingPathComponent("original.aveluneassets")
    let old = Data([7])
    let bytes = Data([1, 2, 3])
    try old.write(to: target)
    for checkpoint in [StudioResourcePackExportWriter.Fault.write, .sync, .close, .rename] {
      let writer = writer(fault: { point in
        if point == checkpoint { throw NSError(domain: "injected", code: 1) }
      })
      let token = try begin(writer, bytes: bytes)
      XCTAssertThrowsError(
        try {
          try append(writer, token: token, bytes: bytes)
          _ = try writer.seal(token: token)
          _ = try writer.finish(token: token)
        }())
      _ = try writer.release(token: token)
      XCTAssertEqual(try Data(contentsOf: target), old)
    }
  }
  func testPublishedResultSurvivesCleanupFailureAndCanBeQueriedAgain() throws {
    var fail = true
    let writer = writer(fault: { point in
      if point == .cleanup && fail {
        fail = false
        throw NSError(domain: "cleanup", code: 1)
      }
    })
    let bytes = Data([1, 2, 3])
    let token = try begin(writer, bytes: bytes)
    try append(writer, token: token, bytes: bytes)
    _ = try writer.seal(token: token)
    let result = try writer.finish(token: token)
    XCTAssertEqual(result["state"] as? String, "published")
    XCTAssertNotNil(result["warning"])
    XCTAssertEqual(try writer.status(token: token)["state"] as? String, "published")
    _ = try writer.release(token: token)
    XCTAssertEqual(
      try Data(contentsOf: root.appendingPathComponent("original.aveluneassets")), bytes)
  }
  func testConfirmedReplacementChangedAfterSealIsRefused() throws {
    let writer = writer()
    let target = root.appendingPathComponent("original.aveluneassets")
    let bytes = Data([1, 2, 3])
    try Data([7]).write(to: target)
    let token = try begin(writer, bytes: bytes)
    try append(writer, token: token, bytes: bytes)
    _ = try writer.seal(token: token)
    try Data([8, 9]).write(to: target)
    XCTAssertThrowsError(try writer.finish(token: token))
    _ = try writer.release(token: token)
    XCTAssertEqual(try Data(contentsOf: target), Data([8, 9]))
  }
  func testFolderSymlinkAndChangedDirectoryAreRefused() throws {
    let writer = writer()
    let alias = root.appendingPathComponent("alias")
    let folder = root.appendingPathComponent("folder")
    let moved = root.appendingPathComponent("moved")
    let bytes = Data([1, 2, 3])
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: folder)
    XCTAssertThrowsError(
      try writer.choose(
        folder: alias, name: "original.aveluneassets", byteLength: 3,
        rawSha256: String(repeating: "a", count: 64), confirm: { _ in true }))
    let selected = try writer.choose(
      folder: folder, name: "original.aveluneassets", byteLength: 3,
      rawSha256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(),
      confirm: { _ in true })
    let token = try XCTUnwrap(selected?["token"] as? String)
    try append(writer, token: token, bytes: bytes)
    _ = try writer.seal(token: token)
    try FileManager.default.moveItem(at: folder, to: moved)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    XCTAssertThrowsError(try writer.finish(token: token))
    _ = try writer.release(token: token)
    XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: moved.path).isEmpty)
  }
  func testFinishAndReleaseSerializeAndKeepPublishedDestination() throws {
    let entered = DispatchSemaphore(value: 0)
    let proceed = DispatchSemaphore(value: 0)
    let writer = writer(fault: { point in
      if point == .rename {
        entered.signal()
        _ = proceed.wait(timeout: .now() + 5)
      }
    })
    let bytes = Data([1, 2, 3])
    let token = try begin(writer, bytes: bytes)
    try append(writer, token: token, bytes: bytes)
    _ = try writer.seal(token: token)
    let group = DispatchGroup()
    let outcomes = PackWriterOutcomes()
    group.enter()
    DispatchQueue.global().async {
      do { outcomes.record(try writer.finish(token: token)["state"] as? String ?? "missing") } catch
      { outcomes.record("error: \(error)") }
      group.leave()
    }
    XCTAssertEqual(entered.wait(timeout: .now() + 5), .success)
    group.enter()
    DispatchQueue.global().async {
      do {
        outcomes.record(try writer.release(token: token)["state"] as? String ?? "missing")
      } catch { outcomes.record("error: \(error)") }
      group.leave()
    }
    proceed.signal()
    XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
    XCTAssertEqual(outcomes.values, ["published", "published"])
    XCTAssertEqual(
      try Data(contentsOf: root.appendingPathComponent("original.aveluneassets")), bytes)
  }
  func testCleanupFailureAtCloseDoesNotPermitMoreWrites() throws {
    var fail = true
    let writer = writer(fault: { point in
      if point == .cleanup && fail { throw NSError(domain: "cleanup", code: 1) }
    })
    let bytes = Data([1, 2, 3])
    let token = try begin(writer, bytes: bytes)
    XCTAssertFalse(writer.close().isEmpty)
    XCTAssertThrowsError(try writer.append(token: token, offset: 0, bytes: bytes))
    fail = false
    XCTAssertTrue(writer.close().isEmpty)
  }
  func testChangedTemporaryBytesAreRefusedBeforeAndAfterSeal() throws {
    for sealed in [false, true] {
      let writer = writer()
      let bytes = Data([1, 2, 3])
      let token = try begin(writer, bytes: bytes)
      try append(writer, token: token, bytes: bytes)
      if sealed { _ = try writer.seal(token: token) }
      let name = try XCTUnwrap(
        FileManager.default.contentsOfDirectory(atPath: root.path).first { $0.hasSuffix(".part") })
      try Data([8, 9, 0]).write(to: root.appendingPathComponent(name))
      if sealed {
        XCTAssertThrowsError(try writer.finish(token: token))
      } else {
        XCTAssertThrowsError(try writer.seal(token: token))
      }
      _ = try writer.release(token: token)
      let target = root.appendingPathComponent("original.aveluneassets")
      XCTAssertFalse(FileManager.default.fileExists(atPath: target.path))
      if FileManager.default.fileExists(atPath: target.path) {
        try FileManager.default.removeItem(at: target)
      }
    }
  }
  func testReleaseAfterSealCancelsAndCloseCleansEveryOwnedScope() throws {
    let writer = writer()
    let bytes = Data([1, 2, 3])
    let token = try begin(writer, bytes: bytes)
    try append(writer, token: token, bytes: bytes)
    _ = try writer.seal(token: token)
    _ = try writer.release(token: token)
    XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    _ = try begin(writer, bytes: bytes)
    XCTAssertTrue(writer.close().isEmpty)
    XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    XCTAssertThrowsError(try begin(writer, bytes: bytes))
  }
}

private final class PackWriterOutcomes: @unchecked Sendable {
  private let lock = NSLock()
  private var stored = [String]()
  func record(_ value: String) {
    lock.lock()
    defer { lock.unlock() }
    stored.append(value)
  }
  var values: [String] {
    lock.lock()
    defer { lock.unlock() }
    return stored
  }
}
