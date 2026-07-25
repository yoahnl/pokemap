import 'dart:typed_data';

/// Stable random-access view over an immutable package snapshot.
///
/// Filesystem and IPC adapters belong to the Hub application. Implementations
/// must keep [length] and every byte returned by [readAtSync] stable for the
/// complete inspection call.
abstract interface class RandomAccessPackageSource {
  int get length;

  Uint8List readAtSync(int offset, int length);
}
