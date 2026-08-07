import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pokemap_hub/core/ports/support_root_port.dart';

/// Resolves the Hub's support root through `path_provider`.
///
/// The only place in the app that knows where the platform puts application
/// support data. Moved out of the composition root so the path can be
/// overridden wholesale in tests.
final class PathProviderSupportRootAdapter implements SupportRootPort {
  const PathProviderSupportRootAdapter();

  @override
  Future<Directory> resolve() async {
    final platformRoot = await getApplicationSupportDirectory();
    return Directory(p.join(platformRoot.path, 'PokeMap'));
  }
}
