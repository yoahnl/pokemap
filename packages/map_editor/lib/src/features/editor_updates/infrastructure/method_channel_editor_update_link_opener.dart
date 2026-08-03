import 'package:flutter/services.dart';

import '../domain/editor_update_link_opener.dart';

final class MethodChannelEditorUpdateLinkOpener
    implements EditorUpdateLinkOpener {
  const MethodChannelEditorUpdateLinkOpener({
    this.channel = const MethodChannel('map_editor/editor_updates'),
  });

  final MethodChannel channel;

  @override
  Future<bool> open(Uri uri) async {
    if (uri.scheme != 'https' || uri.host != 'github.com') {
      return false;
    }
    return await channel.invokeMethod<bool>(
          'openExternalUri',
          {'uri': uri.toString()},
        ) ??
        false;
  }
}
