import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _native(String name) => File('macos/Runner/$name').readAsStringSync();

void main() {
  test(
    'Converter macOS updater binds its dedicated signed manual-only feed',
    () {
      final plist = _native('Info.plist');
      final expected = <String, String>{
        'SUFeedURL': '<string>https://github.com/yoahnl/pokemap/releases/download/avelune-converter-update-stable/appcast-macos.xml</string>',
        'SUPublicEDKey':
            '<string>\$(AVELUNE_CONVERTER_SPARKLE_PUBLIC_ED_KEY)</string>',
        'SUAllowsAutomaticUpdates': '<false/>',
        'SUAutomaticallyUpdate': '<false/>',
        'SUEnableAutomaticChecks': '<false/>',
        'SURequireSignedFeed': '<true/>',
        'SUVerifyUpdateBeforeExtraction': '<true/>',
        'SUSignedFeedFailureExpirationInterval': '<integer>0</integer>',
        'SUEnableInstallerLauncherService': '<true/>',
      };
      for (final entry in expected.entries) {
        expect(
          RegExp('<key>${entry.key}</key>\\s*${RegExp.escape(entry.value)}')
              .hasMatch(plist),
          isTrue,
          reason: entry.key,
        );
      }
      final entitlements = _native('Release.entitlements');
      expect(
        entitlements,
        contains('<key>com.apple.security.app-sandbox</key>'),
      );
      expect(entitlements, contains('\$(PRODUCT_BUNDLE_IDENTIFIER)-spks'));
      expect(entitlements, contains('\$(PRODUCT_BUNDLE_IDENTIFIER)-spki'));
    },
  );

  test(
    'Converter Sparkle dependency is linked and pinned to reviewed 2.9.5',
    () {
      final project = File('macos/Runner.xcodeproj/project.pbxproj')
          .readAsStringSync();
      expect(project, contains('ConverterUpdaterBridge.swift in Sources'));
      expect(project, contains('Sparkle in Frameworks'));
      expect(project, contains('https://github.com/sparkle-project/Sparkle'));
      expect(project, contains('kind = exactVersion;'));
      expect(project, contains('version = 2.9.5;'));
      final file = File(
        'macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved',
      );
      expect(file.existsSync(), isTrue);
      if (!file.existsSync()) return;
      final package = jsonDecode(file.readAsStringSync()) as Map;
      final sparkle = (package['pins'] as List).cast<Map>().singleWhere(
        (pin) => pin['identity'] == 'sparkle',
      );
      expect(sparkle['location'], 'https://github.com/sparkle-project/Sparkle');
      expect(sparkle['state'], {
        'revision': '79bc9e872948e47877e76f194cb0c8e0412b0b90',
        'version': '2.9.5',
      });
    },
  );

  test(
    'Converter native update flow gates both ready and resumed install paths',
    () {
      final file = File('macos/Runner/ConverterUpdaterBridge.swift');
      expect(file.existsSync(), isTrue);
      if (!file.existsSync()) return;
      final bridge = file.readAsStringSync();
      for (final contract in [
        'com.avelune.converter/updates',
        'manualCheckRequested',
        'openUpdateFlow',
        'respondToRestart',
        'operationId',
        'canRestart',
        'restartRequested',
        'finished',
        'cancelled',
        'failed',
        'activeOperationId',
        'pendingInstallHandler = nil',
        'pendingCancelHandler = nil',
        'try candidate.start()',
        'override func showReady(toInstallAndRelaunch reply:',
        'super.showReady(toInstallAndRelaunch:',
        'showUpdateFound(',
        'state.stage == .installing',
        'restartAuthorized',
        'com.yoahnl.avelune.converter',
        'Data(base64Encoded: key)',
      ]) {
        expect(bridge, contains(contract), reason: contract);
      }
      expect(bridge, isNot(contains('checkForUpdatesInBackground(')));
      expect(bridge, isNot(contains('startUpdater()')));
      expect(bridge, isNot(contains('NSApp.terminate(')));
      expect(bridge, contains('operationId == activeOperationId'));
      expect(bridge, contains('activeOperationId == nil'));
      expect(bridge, contains('updateCheck == .updates'));
      expect(bridge, contains('reply(.skip)'));
      final delegate = _native('AppDelegate.swift');
      expect(delegate, contains('ConverterUpdaterBridge.requestManualCheck()'));
      expect(
        delegate,
        contains('ConverterUpdaterBridge.shouldBlockTermination'),
      );
      expect(delegate, contains('return .terminateCancel'));
      expect(delegate, contains('super.applicationShouldTerminate(sender)'));
    },
  );

  test('Converter registers updater without replacing its existing vision Keychain bridge', () {
    final window = _native('MainFlutterWindow.swift');
    expect(
      window,
      contains('ConverterUpdaterBridge.install(on: flutterViewController)'),
    );
    expect(window, contains('com.avelune.converter/vision_secret'));
    expect(window, contains('SecItemCopyMatching'));
    expect(window, contains('SecItemUpdate'));
    expect(window, contains('SecItemDelete'));
  });
}
