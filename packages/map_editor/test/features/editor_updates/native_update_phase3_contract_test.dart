import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UPD-04 macOS Sparkle contract', () {
    test('pins Sparkle 2.9.5 and links it only to Runner', () {
      final project = File(
        'macos/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(project, contains('https://github.com/sparkle-project/Sparkle'));
      expect(project, contains('kind = exactVersion;'));
      expect(project, contains('version = 2.9.5;'));
      expect(project, contains('Sparkle in Frameworks'));
      expect(project, contains('EditorUpdaterBridge.swift in Sources'));
    });

    test('configures signed feeds and sandbox installer services', () {
      final info = File('macos/Runner/Info.plist').readAsStringSync();
      final entitlements = File(
        'macos/Runner/Release.entitlements',
      ).readAsStringSync();

      expect(info, contains('<key>SUFeedURL</key>'));
      expect(
        info,
        contains(
          'https://github.com/yoahnl/pokemap/releases/download/'
          'pokemap-editor-update-stable/appcast-macos.xml',
        ),
      );
      expect(info, contains('<key>SUPublicEDKey</key>'));
      expect(info, contains(r'$(POKEMAP_SPARKLE_PUBLIC_ED_KEY)'));
      expect(info, contains('<key>SUEnableAutomaticChecks</key>'));
      expect(info, contains('<key>SURequireSignedFeed</key>'));
      expect(info, contains('<key>SUVerifyUpdateBeforeExtraction</key>'));
      expect(info, contains('<key>SUEnableInstallerLauncherService</key>'));
      expect(entitlements, contains(r'$(PRODUCT_BUNDLE_IDENTIFIER)-spks'));
      expect(entitlements, contains(r'$(PRODUCT_BUNDLE_IDENTIFIER)-spki'));
    });

    test('bridges Sparkle through the shared guarded update channel', () {
      final bridge = File(
        'macos/Runner/EditorUpdaterBridge.swift',
      ).readAsStringSync();

      expect(bridge, contains('import Sparkle'));
      expect(bridge, contains('SPUStandardUpdaterController'));
      expect(bridge, contains('case "openUpdateFlow"'));
      expect(bridge, contains('case "setRestartReady"'));
      expect(bridge, contains('case "respondToRestart"'));
      expect(bridge, contains('shouldPostponeRelaunchForUpdate'));
      expect(bridge, contains('DispatchQueue.main.async'));
      expect(bridge, isNot(contains('PRIVATE_KEY')));
    });
  });

  group('UPD-05 Windows WinSparkle contract', () {
    test('acquires WinSparkle 0.9.4 deterministically', () {
      final cmake = File(
        'windows/runner/CMakeLists.txt',
      ).readAsStringSync();

      expect(cmake, contains('set(WINSPARKLE_VERSION "0.9.4")'));
      expect(
        cmake,
        contains(
          '452f4076a41cebc81540dfa34af9a28d4718ac976612c1f41a0581ddcbdf9007',
        ),
      );
      expect(cmake, contains('build/native/include/winsparkle.h'));
      expect(cmake, contains('build/native/x64/WinSparkle.lib'));
      expect(cmake, contains('build/native/x64/WinSparkle.dll'));
      expect(cmake, contains('copy_if_different'));
      expect(cmake, contains('editor_updater_bridge.cpp'));
    });

    test('embeds only the HTTPS feed and EdDSA public key', () {
      final resources = File(
        'windows/runner/editor_update_resources.rc.in',
      ).readAsStringSync();

      expect(resources, contains('FeedURL APPCAST'));
      expect(
        resources,
        contains(
          'https://github.com/yoahnl/pokemap/releases/download/'
          'pokemap-editor-update-stable/appcast-windows.xml',
        ),
      );
      expect(resources, contains('EdDSAPub EDDSA'));
      expect(resources, contains('@POKEMAP_WINSPARKLE_EDDSA_PUBLIC_KEY@'));
      expect(resources, isNot(contains('\nDSAPub ')));
    });

    test('uses a thread-safe restart gate and generic native errors', () {
      final bridge = File(
        'windows/runner/editor_updater_bridge.cpp',
      ).readAsStringSync();
      final header = File(
        'windows/runner/editor_updater_bridge.h',
      ).readAsStringSync();

      expect(header, contains('std::atomic_bool can_restart_{false}'));
      expect(
        header,
        contains('std::atomic_bool restart_request_posted_{false}'),
      );
      expect(bridge, contains('win_sparkle_set_can_shutdown_callback'));
      expect(bridge, contains('win_sparkle_set_shutdown_request_callback'));
      expect(bridge, contains('win_sparkle_check_update_with_ui'));
      expect(bridge, contains('win_sparkle_cleanup'));
      expect(bridge, contains('PostMessageW'));
      expect(bridge, contains('restart_request_posted_.exchange(true)'));
      expect(bridge, contains('LoadLibraryExW'));
      expect(bridge, contains('native_update_failed'));
      expect(bridge, isNot(contains('signature_invalid')));
    });

    test('ships a stable per-user Inno Setup installer', () {
      final installer = File(
        'windows/installer/pokemap.iss',
      ).readAsStringSync();

      expect(
        installer,
        contains(r'DefaultDirName={localappdata}\Programs\PokeMap'),
      );
      expect(installer, contains('PrivilegesRequired=lowest'));
      expect(installer, contains('ArchitecturesAllowed=x64compatible'));
      expect(
        installer,
        contains('ArchitecturesInstallIn64BitMode=x64compatible'),
      );
      expect(installer, contains('AppId={{'));
      expect(installer, contains('CloseApplications=no'));
      expect(installer, contains('PokeMap-Editor-Setup-{#AppVersion}'));
    });
  });
}
