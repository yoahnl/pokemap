import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_hub/src/ui/player/hub_save_profiles_screen.dart';

void main() {
  late _FakeSaveProfilesController controller;
  late HubSaveSelection initial;

  setUp(() {
    controller = _FakeSaveProfilesController();
    initial = const HubSaveSelection(
      profileId: 'default',
      slotId: 'slot-1',
    );
  });

  testWidgets('creates a named profile and slot then selects opaque ids',
      (tester) async {
    HubSaveSelection? selected;
    await tester.pumpWidget(
      _app(
        HubSaveProfilesScreen(
          manager: controller,
          initialSelection: initial,
          initialProfiles: await controller.load(),
          onSelected: (value) => selected = value,
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('save-profile-create')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('save-name-field')),
      'Alice',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('save-name-confirm')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('save-slot-create')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('save-name-field')),
      'Aventure principale',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('save-name-confirm')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('save-slot-select-slot-1')),
    );

    expect(selected?.profileId, 'profile-1');
    expect(selected?.slotId, 'slot-1');
  });

  testWidgets('slot deletion requires an exact confirmation', (tester) async {
    await tester.pumpWidget(
      _app(
        HubSaveProfilesScreen(
          manager: controller,
          initialSelection: initial,
          initialProfiles: await controller.load(),
          onSelected: (_) {},
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('save-slot-delete-slot-1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Supprimer définitivement le slot « Slot 1 » ?'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('save-delete-confirm')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucun slot'), findsOneWidget);
  });

  testWidgets('remains usable in a narrow viewport at 200% text scale',
      (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        HubSaveProfilesScreen(
          manager: controller,
          initialSelection: initial,
          initialProfiles: await controller.load(),
          onSelected: (_) {},
          onClose: () {},
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('save-profile-create')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('save-slot-select-slot-1')),
      findsOneWidget,
    );
  });
}

Widget _app(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: child,
    );

final class _FakeSaveProfilesController implements HubSaveProfilesController {
  final List<HubManagedSaveProfile> _profiles = <HubManagedSaveProfile>[
    HubManagedSaveProfile(
      profile: const SaveProfile(
        profileId: 'default',
        displayName: 'Joueur',
      ),
      slots: <HubManagedSaveSlot>[
        HubManagedSaveSlot(
          metadata: SaveSlotMetadata(
            slotId: 'slot-1',
            displayName: 'Slot 1',
            createdAt: DateTime.utc(2026, 7, 27),
          ),
        ),
      ],
    ),
  ];

  @override
  Future<List<HubManagedSaveProfile>> load() async =>
      List<HubManagedSaveProfile>.unmodifiable(_profiles);

  @override
  Future<SaveProfile> createProfile(String displayName) async {
    final profile = SaveProfile(
      profileId: 'profile-1',
      displayName: displayName,
    );
    _profiles.add(
      HubManagedSaveProfile(
        profile: profile,
        slots: const <HubManagedSaveSlot>[],
      ),
    );
    return profile;
  }

  @override
  Future<SaveSlotMetadata> createSlot({
    required String profileId,
    required String displayName,
  }) async {
    final metadata = SaveSlotMetadata(
      slotId: 'slot-1',
      displayName: displayName,
      createdAt: DateTime.utc(2026, 7, 27),
    );
    final index = _profiles.indexWhere(
      (entry) => entry.profile.profileId == profileId,
    );
    final profile = _profiles[index];
    _profiles[index] = HubManagedSaveProfile(
      profile: profile.profile,
      slots: <HubManagedSaveSlot>[
        ...profile.slots,
        HubManagedSaveSlot(metadata: metadata),
      ],
    );
    return metadata;
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((entry) => entry.profile.profileId == profileId);
  }

  @override
  Future<void> deleteSlot({
    required String profileId,
    required String slotId,
  }) async {
    final index = _profiles.indexWhere(
      (entry) => entry.profile.profileId == profileId,
    );
    final profile = _profiles[index];
    _profiles[index] = HubManagedSaveProfile(
      profile: profile.profile,
      slots: profile.slots
          .where((slot) => slot.metadata.slotId != slotId)
          .toList(growable: false),
    );
  }

  @override
  Future<SaveProfile> renameProfile(
    SaveProfile profile,
    String displayName,
  ) async {
    final renamed = SaveProfile(
      profileId: profile.profileId,
      displayName: displayName,
    );
    final index = _profiles.indexWhere(
      (entry) => entry.profile.profileId == profile.profileId,
    );
    _profiles[index] = HubManagedSaveProfile(
      profile: renamed,
      slots: _profiles[index].slots,
    );
    return renamed;
  }
}
