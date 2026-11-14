import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class PackNativeChannel {
  final methods = <String>[];
  String statusState = "published";
  int offset = 0;
  int releaseAttempts = 0;
  bool released = false, loseReleaseReply = false;
  bool cancelPicker = false,
      sealError = false,
      loseFinish = false,
      loseStatus = false,
      releaseError = false;
  Completer<void>? appendGate, chooseGate;
  final chooseEntered = Completer<void>();
  final appendEntered = Completer<void>();
  void Function()? onSeal;
  Future<Object?> call(MethodCall call) async {
    methods.add(call.method);
    final input = call.arguments as Map;
    switch (call.method) {
      case 'resourcePackExportChoose':
        if (!chooseEntered.isCompleted) chooseEntered.complete();
        if (chooseGate != null) await chooseGate!.future;
        expect(input['suggestedName'], endsWith('.aveluneassets'));
        return cancelPicker
            ? null
            : {'token': 'native-token', 'state': 'writing'};
      case 'resourcePackExportAppend':
        expect(input['token'], 'native-token');
        expect(input['offset'], offset);
        final bytes = input['bytes'] as Uint8List;
        expect(bytes.length, lessThanOrEqualTo(128 * 1024));
        offset += bytes.length;
        if (!appendEntered.isCompleted) appendEntered.complete();
        if (appendGate != null) await appendGate!.future;
        return {'state': 'writing'};
      case 'resourcePackExportSeal':
        if (sealError) throw PlatformException(code: 'hash_mismatch');
        onSeal?.call();
        return {'state': 'sealed'};
      case 'resourcePackExportFinish':
        if (loseFinish) throw PlatformException(code: 'lost_finish');
        return {'state': 'published', 'path': '/native/Original.aveluneassets'};
      case 'resourcePackExportStatus':
        if (released) throw PlatformException(code: 'handle_unknown');
        if (loseStatus) throw PlatformException(code: 'lost_status');
        return {'state': statusState, 'path': '/native/Original.aveluneassets'};
      case 'resourcePackExportRelease':
        releaseAttempts++;
        if (releaseError) throw PlatformException(code: 'cleanup');
        released = true;
        if (loseReleaseReply) {
          loseReleaseReply = false;
          throw PlatformException(code: 'lost_release_reply');
        }
        return {'released': true};
      default:
        throw StateError(call.method);
    }
  }
}
