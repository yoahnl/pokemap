import 'package:avelune_studio/features/presentations/coordination/presentation_editing_sessions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

PresentationCinematicAsset _asset({bool removeClip = false, int start = 0}) =>
    PresentationCinematicAsset(
      id: 'presentation',
      title: removeClip ? 'Revised' : 'Initial',
      durationUs: 1000000,
      layers: [PresentationLayer(id: 'image', label: 'Image', zIndex: 0)],
      tracks: [
        PresentationTrack(
          id: 'track',
          label: 'Image',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationVisualClip(
              id: 'keep',
              startUs: start,
              durationUs: 250000,
              layerId: 'image',
              resourceId: 'image-source',
            ),
            if (!removeClip)
              PresentationVisualClip(
                id: 'remove',
                startUs: 500000,
                durationUs: 250000,
                layerId: 'image',
                resourceId: 'image-source',
              ),
          ],
        ),
      ],
    );

void main() {
  test('preview ownership retains time for revisions, releases replacements and stops disposal', () async {
    final sessions = PresentationEditingSessions();
    final prepared = <(String, bool)>[];
    var releases = 0, binds = 0;
    final owner = Object();
    void bind(Object target) => sessions.bindPreview(
      target,
      bind: (transport) {
        expect(transport, same(sessions.transport));
        binds++;
      },
      prepare: (asset, {required portrait}) async {
        prepared.add((asset.title, portrait));
      },
      release: () async {
        releases++;
      },
    );
    bind(owner);
    bind(owner);
    final original = _asset();
    expect(sessions.installPreview(owner, original, portrait: false), isTrue);
    sessions.transport.seek(300000);
    expect(sessions.installPreview(owner, original, portrait: false), isFalse);
    expect(
      sessions.installPreview(owner, _asset(removeClip: true), portrait: true),
      isTrue,
    );
    expect(sessions.transport.timeUs, 300000);
    expect(prepared, [('Initial', false), ('Revised', true)]);
    expect(binds, 1);
    sessions.transport.play();
    await sessions.suspendPreview(owner);
    expect(sessions.transport.playing, isFalse);
    expect(releases, 1);
    final replacement = Object();
    bind(replacement);
    expect(binds, 2);
    expect(releases, 2);
    await sessions.releasePreview(replacement);
    expect(releases, 3);
    expect(sessions.transport.asset, isNull);
    sessions.dispose();
    sessions.dispose();
    expect(sessions.installPreview(owner, original, portrait: false), isFalse);
    expect(releases, 3);
    expect(
      sessions.invalidFieldsFor('a'),
      isNot(same(sessions.invalidFieldsFor('b'))),
    );
  });
  test('a superseded preview consumer cannot release suspend or replace its successor', () async {
    final sessions = PresentationEditingSessions();
    addTearDown(sessions.dispose);
    final a = Object(), b = Object();
    var releasesA = 0, releasesB = 0;
    sessions.bindPreview(
      a,
      bind: (_) {},
      prepare: (_, {required portrait}) async {},
      release: () async {
        releasesA++;
      },
    );
    sessions.installPreview(a, _asset(), portrait: false);
    Future<void> closeA() => sessions.releasePreview(a);
    sessions.bindPreview(
      b,
      bind: (_) {},
      prepare: (_, {required portrait}) async {},
      release: () async {
        releasesB++;
      },
    );
    final installed = _asset(removeClip: true);
    sessions.installPreview(b, installed, portrait: false);
    sessions.transport.play();
    await closeA();
    await sessions.suspendPreview(a);
    expect(sessions.installPreview(a, _asset(), portrait: true), isFalse);
    expect(sessions.transport.asset, same(installed));
    expect(sessions.transport.playing, isTrue);
    expect(releasesA, 1);
    expect(releasesB, 0);
    await sessions.releasePreview(b);
    expect(releasesB, 1);
    expect(sessions.transport.asset, isNull);
  });

  test(
    'leases remain distinct when consumers reuse the same visual resource',
    () async {
      final sessions = PresentationEditingSessions();
      addTearDown(sessions.dispose);
      final firstLease = Object(),
          secondLease = Object(),
          thirdLease = Object();
      var releases = 0;
      Future<void> releaseSharedVisual() async {
        releases++;
      }

      void bind(Object lease) => sessions.bindPreview(
        lease,
        bind: (_) {},
        prepare: (_, {required portrait}) async {},
        release: releaseSharedVisual,
      );
      bind(firstLease);
      bind(secondLease);
      final current = _asset();
      sessions.installPreview(secondLease, current, portrait: false);
      await sessions.releasePreview(firstLease);
      expect(sessions.transport.asset, same(current));
      expect(releases, 1);
      bind(thirdLease);
      sessions.installPreview(thirdLease, current, portrait: false);
      await sessions.releasePreview(firstLease);
      await sessions.releasePreview(secondLease);
      expect(sessions.transport.asset, same(current));
      expect(releases, 2);
      await sessions.releasePreview(thirdLease);
      expect(releases, 3);
    },
  );

  test('an asset revision preserves its editor and clipboard while reconciling clip selection', () {
    final sessions = PresentationEditingSessions();
    addTearDown(sessions.dispose);
    final editor = sessions.forAsset(_asset());
    editor.selectClip('keep');
    editor.selectClip('remove', additive: true);
    editor.copySelection();
    final revised = _asset(removeClip: true, start: 100000);
    final current = sessions.forAsset(revised);
    expect(current, same(editor));
    expect(current.asset, same(revised));
    expect(current.sourceClip('keep').startUs, 100000);
    expect(current.selectedClipIds, {'keep'});
    expect(current.hasClipboard, isTrue);
    expect(sessions.forAsset(revised), same(current));
    expect(current.selectedClipIds, {'keep'});
  });
}
