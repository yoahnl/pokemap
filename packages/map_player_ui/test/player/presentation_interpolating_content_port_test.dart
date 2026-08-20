import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

/// L'interpolation des clips texte Presentation — BETA-CIN-071.
///
/// Presentation ne possède jamais le draft : le décorateur reçoit le scope
/// courant depuis Scene au moment du rendu, interpole le texte du caption
/// résolu pour la locale, laisse les indisponibilités intactes, et un scope
/// qui avance entre deux rendus se reflète immédiatement — aucun rendu
/// périmé ne peut s'afficher.
void main() {
  const clip = PresentationCaptionFrameClip(
    clipId: 'caption_1',
    trackId: 'captions',
    captionId: 'welcome',
    startUs: 0,
    durationUs: 1000000,
    elapsedUs: 10,
    progress: 0.1,
  );

  PresentationInterpolationScope scopeWithName(String name, int revision) =>
      PresentationInterpolationScope(
        revision: revision,
        draftValues: {
          PresentationDraftInterpolationField.playerName: name,
        },
      );

  test('a ready caption is interpolated against the current scope', () {
    final port = PresentationInterpolatingFrameContentPort(
      delegate: _FixedCaptionPort(
        const PresentationCaptionReady(
          text: 'Bienvenue {{draft.playerName}} !',
        ),
      ),
      currentScope: () => scopeWithName('Zoé 🐉‍🔥', 1),
    );
    final resolution = port.resolveCaption(
      clip: clip,
      locale: const Locale('fr'),
    );
    expect(
      (resolution as PresentationCaptionReady).text,
      'Bienvenue Zoé 🐉‍🔥 !',
    );
  });

  test('an unavailable caption passes through untouched', () {
    const unavailable = PresentationCaptionUnavailable(
      reason: PresentationContentUnavailableReason.unsupported,
      message: 'Runtime captions are not loaded for this media.',
    );
    final port = PresentationInterpolatingFrameContentPort(
      delegate: _FixedCaptionPort(unavailable),
      currentScope: () => scopeWithName('Zoé', 1),
    );
    expect(
      port.resolveCaption(clip: clip, locale: const Locale('fr')),
      same(unavailable),
    );
  });

  test('rendering always reads the freshest scope, never a stale one', () {
    var scope = scopeWithName('Ancien', 1);
    final port = PresentationInterpolatingFrameContentPort(
      delegate: _FixedCaptionPort(
        const PresentationCaptionReady(text: '{{draft.playerName}}'),
      ),
      currentScope: () => scope,
    );
    final before = port.resolveCaption(clip: clip, locale: const Locale('fr'))
        as PresentationCaptionReady;
    expect(before.text, 'Ancien');

    scope = scopeWithName('Nouveau', 2);
    final after = port.resolveCaption(clip: clip, locale: const Locale('fr'))
        as PresentationCaptionReady;
    expect(
      after.text,
      'Nouveau',
      reason: 'a validated response bumped the scope: the next evaluation '
          'must render the new value, the old rendering is stale',
    );
  });

}

final class _FixedCaptionPort implements PresentationFrameContentPort {
  const _FixedCaptionPort(this.caption);

  final PresentationCaptionResolution caption;

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) =>
      throw StateError('unused');

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) =>
      caption;
}
