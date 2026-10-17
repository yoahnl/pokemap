import CryptoKit
import Darwin
import Foundation

final class StudioResourcePackExportWriter {
  enum Fault: Equatable { case write, sync, close, rename, cleanup }
  struct Failure: LocalizedError {
    let code: String
    let message: String
    var errorDescription: String? { message }
  }
  private struct Identity: Equatable {
    let device: Int32
    let inode: UInt64
    let size: Int64
    let mode: UInt16
    let modifiedSeconds: Int
    let modifiedNanos: Int
    let changedSeconds: Int
    let changedNanos: Int
    init(_ value: stat) {
      device = value.st_dev
      inode = value.st_ino
      size = value.st_size
      mode = value.st_mode
      modifiedSeconds = value.st_mtimespec.tv_sec
      modifiedNanos = value.st_mtimespec.tv_nsec
      changedSeconds = value.st_ctimespec.tv_sec
      changedNanos = value.st_ctimespec.tv_nsec
    }
    var directory: Bool { mode & UInt16(S_IFMT) == UInt16(S_IFDIR) }
    var regular: Bool { mode & UInt16(S_IFMT) == UInt16(S_IFREG) }
    func sameNode(_ other: Identity) -> Bool {
      device == other.device && inode == other.inode && mode == other.mode
    }
  }
  private final class Session {
    let token = UUID().uuidString
    let folder: URL
    let name: String
    let length: Int64
    let hash: String
    let folderIdentity: Identity
    let destinationIdentity: Identity?
    var directoryFD: Int32
    var fileFD: Int32 = -1
    var temporaryName: String?
    var received: Int64 = 0
    var sealedIdentity: Identity?
    var state = "offered"
    var warning: String?
    var scoped = true
    init(
      folder: URL, name: String, length: Int64, hash: String, directoryFD: Int32,
      folderIdentity: Identity, destinationIdentity: Identity?
    ) {
      self.folder = folder
      self.name = name
      self.length = length
      self.hash = hash
      self.directoryFD = directoryFD
      self.folderIdentity = folderIdentity
      self.destinationIdentity = destinationIdentity
    }
  }
  private let queue = DispatchQueue(label: "avelune.resource-pack-export")
  private var sessions = [String: Session]()
  private var closed = false
  private let startAccess: (URL) -> Bool
  private let stopAccess: (URL) -> Void
  private let supportsExclusiveRename: (URL) throws -> Bool
  private let fault: (Fault) throws -> Void
  init(
    startAccess: @escaping (URL) -> Bool = { $0.startAccessingSecurityScopedResource() },
    stopAccess: @escaping (URL) -> Void = { $0.stopAccessingSecurityScopedResource() },
    supportsExclusiveRename: @escaping (URL) throws -> Bool = {
      try $0.resourceValues(forKeys: [.volumeSupportsExclusiveRenamingKey])
        .volumeSupportsExclusiveRenaming == true
    }, fault: @escaping (Fault) throws -> Void = { _ in }
  ) {
    self.startAccess = startAccess
    self.stopAccess = stopAccess
    self.supportsExclusiveRename = supportsExclusiveRename
    self.fault = fault
  }
  func choose(
    folder: URL, name: String, byteLength: Int64, rawSha256: String, confirm: (URL) -> Bool
  ) throws -> [String: Any]? {
    let session = try queue.sync { () throws -> Session in
      guard !closed else { throw failure("closed", "L’export natif est fermé.") }
      guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\0"),
        name.utf8.count <= 255, name.hasSuffix(".aveluneassets"), byteLength > 0,
        rawSha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil
      else {
        throw failure("input_invalid", "Le nom ou la description du fichier d’export est invalide.")
      }
      guard folder.isFileURL, startAccess(folder) else {
        throw failure("permission_denied", "Le dossier d’export n’est pas autorisé.")
      }
      var directoryFD: Int32 = -1
      do {
        directoryFD = Darwin.open(folder.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard directoryFD >= 0 else { throw systemFailure("directory_open") }
        var metadata = stat()
        guard fstat(directoryFD, &metadata) == 0 else { throw systemFailure("directory_identity") }
        let folderIdentity = Identity(metadata)
        guard folderIdentity.directory else {
          throw failure("directory_invalid", "La destination doit être un dossier.")
        }
        let existing = try identity(directoryFD, name)
        if let existing = existing, !existing.regular {
          throw failure(
            "destination_invalid",
            "Le fichier de destination doit être un fichier ordinaire, sans lien symbolique.")
        }
        if try existing == nil && !supportsExclusiveRename(folder) {
          throw failure(
            "exclusive_rename_unsupported", "Ce volume ne permet pas une création exclusive sûre.")
        }
        let value = Session(
          folder: folder, name: name, length: byteLength, hash: rawSha256, directoryFD: directoryFD,
          folderIdentity: folderIdentity, destinationIdentity: existing)
        sessions[value.token] = value
        return value
      } catch {
        if directoryFD >= 0 { _ = Darwin.close(directoryFD) }
        stopAccess(folder)
        throw error
      }
    }
    do {
      if session.destinationIdentity != nil && !confirm(folder.appendingPathComponent(name)) {
        _ = try release(token: session.token)
        return nil
      }
      return try queue.sync {
        guard !closed, sessions[session.token] === session else {
          throw failure("closed", "Le choix d’export a été fermé.")
        }
        try revalidate(session)
        let temporary = ".avelune-pack-\(UUID().uuidString).part"
        let descriptor = openat(
          session.directoryFD, temporary, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
          mode_t(S_IRUSR | S_IWUSR))
        guard descriptor >= 0 else { throw systemFailure("temporary_open") }
        session.fileFD = descriptor
        session.temporaryName = temporary
        session.state = "writing"
        return result(session)
      }
    } catch {
      do { _ = try release(token: session.token) } catch let cleanup {
        throw failure(
          "cleanup_failed",
          "\(error.localizedDescription) ; nettoyage : \(cleanup.localizedDescription)")
      }
      throw error
    }
  }
  func append(token: String, offset: Int64, bytes: Data) throws -> [String: Any] {
    try mutate(token) { session in
      guard session.state == "writing", offset == session.received, !bytes.isEmpty,
        bytes.count <= 128 * 1024, Int64(bytes.count) <= session.length - session.received
      else { throw failure("chunk_invalid", "Le bloc d’export ne correspond pas au flux attendu.") }
      try fault(.write)
      try bytes.withUnsafeBytes { buffer in
        var written = 0
        while written < buffer.count {
          let count = Darwin.write(
            session.fileFD, buffer.baseAddress!.advanced(by: written), buffer.count - written)
          if count < 0 && errno == EINTR { continue }
          guard count > 0 else { throw systemFailure("write") }
          written += count
        }
      }
      session.received += Int64(bytes.count)
      return result(session)
    }
  }
  func seal(token: String) throws -> [String: Any] {
    try mutate(token) { session in
      if session.state == "sealed" { return result(session) }
      guard session.state == "writing", session.received == session.length else {
        throw failure("length_mismatch", "La taille écrite ne correspond pas au pack préparé.")
      }
      try fault(.sync)
      guard fsync(session.fileFD) == 0 else { throw systemFailure("sync") }
      var before = stat()
      guard fstat(session.fileFD, &before) == 0 else { throw systemFailure("temporary_identity") }
      guard before.st_size == session.length else {
        throw failure("length_mismatch", "La taille du fichier temporaire a changé.")
      }
      var hasher = SHA256()
      var position: Int64 = 0
      var buffer = [UInt8](repeating: 0, count: 128 * 1024)
      while position < session.length {
        let length = min(buffer.count, Int(session.length - position))
        let count = buffer.withUnsafeMutableBytes {
          pread(session.fileFD, $0.baseAddress, length, off_t(position))
        }
        if count < 0 && errno == EINTR { continue }
        guard count > 0 else { throw systemFailure("temporary_read") }
        hasher.update(data: Data(buffer.prefix(count)))
        position += Int64(count)
      }
      let observed = hasher.finalize().map { String(format: "%02x", $0) }.joined()
      var after = stat()
      guard fstat(session.fileFD, &after) == 0 else { throw systemFailure("temporary_identity") }
      guard observed == session.hash, Identity(before) == Identity(after) else {
        throw failure(
          "hash_mismatch", "Le contenu du fichier temporaire ne correspond pas au pack préparé.")
      }
      session.sealedIdentity = Identity(after)
      try fault(.close)
      let descriptor = session.fileFD
      session.fileFD = -1
      guard Darwin.close(descriptor) == 0 else { throw systemFailure("close") }
      session.state = "sealed"
      return result(session)
    }
  }
  func finish(token: String) throws -> [String: Any] {
    try mutate(token) { session in
      if session.state == "published" { return result(session) }
      guard session.state == "sealed", let temporary = session.temporaryName else {
        throw failure("state_invalid", "Le fichier d’export n’est pas prêt à être publié.")
      }
      try fault(.rename)
      try revalidate(session)
      guard let sealed = session.sealedIdentity,
        try identity(session.directoryFD, temporary) == sealed
      else {
        throw failure("temporary_changed", "Le fichier temporaire a changé depuis sa vérification.")
      }
      if try session.destinationIdentity == nil && !supportsExclusiveRename(session.folder) {
        throw failure(
          "exclusive_rename_unsupported", "Ce volume ne permet pas une création exclusive sûre.")
      }
      let code =
        session.destinationIdentity == nil
        ? renameatx_np(
          session.directoryFD, temporary, session.directoryFD, session.name, UInt32(RENAME_EXCL))
        : renameat(session.directoryFD, temporary, session.directoryFD, session.name)
      guard code == 0 else { throw systemFailure("rename") }
      session.state = "published"
      session.temporaryName = nil
      do { try cleanup(session) } catch {
        session.warning = "Nettoyage à reprendre : \(error.localizedDescription)"
      }
      return result(session)
    }
  }
  func status(token: String) throws -> [String: Any] {
    try queue.sync { result(try session(token)) }
  }
  func release(token: String) throws -> [String: Any] {
    try queue.sync {
      guard let session = sessions[token] else { return ["released": true] }
      try cleanup(session)
      sessions.removeValue(forKey: token)
      return ["released": true, "state": session.state]
    }
  }
  func close() -> [String] {
    queue.sync {
      closed = true
      var errors = [String]()
      for (token, session) in sessions {
        do {
          try cleanup(session)
          sessions.removeValue(forKey: token)
        } catch { errors.append(error.localizedDescription) }
      }
      return errors
    }
  }
  private func mutate(_ token: String, work: (Session) throws -> [String: Any]) throws -> [String:
    Any]
  {
    try queue.sync {
      guard !closed else { throw failure("closed", "L’export natif est fermé.") }
      let value = try session(token)
      do { return try work(value) } catch {
        if value.state != "published" {
          value.state = "failed"
          value.warning = error.localizedDescription
        }
        throw error
      }
    }
  }
  private func session(_ token: String) throws -> Session {
    guard let value = sessions[token] else {
      throw failure("handle_unknown", "La session d’export est inconnue.")
    }
    return value
  }
  private func revalidate(_ value: Session) throws {
    var metadata = stat()
    guard lstat(value.folder.path, &metadata) == 0,
      value.folderIdentity.sameNode(Identity(metadata))
    else { throw failure("directory_changed", "Le dossier d’export a changé.") }
    guard try identity(value.directoryFD, value.name) == value.destinationIdentity else {
      throw failure(
        "destination_changed", "Le fichier de destination a changé depuis la confirmation.")
    }
  }
  private func identity(_ directoryFD: Int32, _ name: String) throws -> Identity? {
    var metadata = stat()
    guard fstatat(directoryFD, name, &metadata, AT_SYMLINK_NOFOLLOW) == 0 else {
      if errno == ENOENT { return nil }
      throw systemFailure("destination_identity")
    }
    return Identity(metadata)
  }
  private func cleanup(_ value: Session) throws {
    try fault(.cleanup)
    var errors = [String]()
    if value.fileFD >= 0 {
      let descriptor = value.fileFD
      value.fileFD = -1
      if Darwin.close(descriptor) != 0 { errors.append("close : \(errno)") }
    }
    if let name = value.temporaryName, value.directoryFD >= 0 {
      if unlinkat(value.directoryFD, name, 0) == 0 || errno == ENOENT {
        value.temporaryName = nil
      } else {
        errors.append("unlink : \(errno)")
      }
    }
    if value.temporaryName != nil {
      throw failure("cleanup_failed", errors.joined(separator: "; "))
    }
    if value.directoryFD >= 0 {
      let descriptor = value.directoryFD
      value.directoryFD = -1
      if Darwin.close(descriptor) != 0 { errors.append("directory close : \(errno)") }
    }
    if value.scoped {
      value.scoped = false
      stopAccess(value.folder)
    }
    if !errors.isEmpty { throw failure("cleanup_failed", errors.joined(separator: "; ")) }
  }
  private func result(_ value: Session) -> [String: Any] {
    var output: [String: Any] = [
      "token": value.token, "state": value.state, "receivedBytes": value.received,
    ]
    if value.state == "published" {
      output["path"] = value.folder.appendingPathComponent(value.name).path
    }
    if let warning = value.warning { output["warning"] = warning }
    return output
  }
  private func failure(_ code: String, _ message: String) -> Failure {
    Failure(code: "resource_pack.export_\(code)", message: message)
  }
  private func systemFailure(_ operation: String) -> Failure {
    failure(operation, "L’opération \(operation) a échoué (\(errno)).")
  }
}
