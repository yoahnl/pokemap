import 'package:avelune_studio/features/cinematics/application/cinematic_input_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the public field constructor preserves its callback and input behavior',
    () {
      var changes = 0;
      final field = CinematicFieldInput('1400', () => changes++);

      field
        ..edit('1750')
        ..reject('Durée refusée');
      field.synchronize('1400');
      expect(field.text, '1750');
      expect(field.problem, 'Durée refusée');
      expect(changes, 2);
      field.accept();
      field.synchronize('1750');

      expect(field.text, '1750');
      expect(field.pending, isFalse);
      expect(field.problem, isNull);
      expect(changes, 3);
    },
  );

  test('a clean field skips validation without advancing its revision', () {
    final inputs = CinematicInputState();
    final field = inputs.field('duration', '1400');
    final revision = inputs.revision;

    final result = inputs.commitField(
      field,
      tryCommit: (_) => throw StateError('Validation inattendue'),
      fallbackError: 'Durée refusée',
    );

    expect(result, CinematicFieldCommitResult.skipped);
    expect(inputs.revision, revision);
    expect(inputs.valid, isTrue);
    expect(inputs.validating, isFalse);
    expect(field.text, '1400');
  });

  test('always commit validates a clean field through the owner', () {
    final inputs = CinematicInputState();
    final field = inputs.field('duration', '1400');
    final values = <String>[];
    final revision = inputs.revision;

    final result = inputs.commitField(
      field,
      tryCommit: (value) {
        expect(inputs.validating, isTrue);
        values.add(value);
        return true;
      },
      fallbackError: 'Durée refusée',
      alwaysCommit: true,
    );

    expect(result, CinematicFieldCommitResult.accepted);
    expect(values, ['1400']);
    expect(inputs.revision, revision + 1);
    expect(inputs.valid, isTrue);
    expect(inputs.validating, isFalse);
  });

  test('accepting a corrected field clears its rejection in place', () {
    final inputs = CinematicInputState();
    final field = inputs.field('duration', '1400');
    field
      ..edit('-2')
      ..reject('Durée refusée')
      ..edit('1750');
    String? committed;

    final result = inputs.commitField(
      field,
      tryCommit: (value) {
        committed = value;
        return true;
      },
      fallbackError: 'Durée refusée',
    );

    expect(result, CinematicFieldCommitResult.accepted);
    expect(committed, '1750');
    expect(inputs.field('duration', '1750'), same(field));
    expect(field.text, '1750');
    expect(field.pending, isFalse);
    expect(field.problem, isNull);
    expect(inputs.valid, isTrue);
  });

  test('a rejected field is retried even without another edit', () {
    final inputs = CinematicInputState();
    final field = inputs.field('duration', '1400');
    field
      ..edit('-2')
      ..reject('Durée refusée');
    final values = <String>[];

    final result = inputs.commitField(
      field,
      tryCommit: (value) {
        values.add(value);
        return false;
      },
      fallbackError: 'Durée refusée',
    );

    expect(result, CinematicFieldCommitResult.rejected);
    expect(values, ['-2']);
    expect(field.text, '-2');
    expect(field.pending, isFalse);
    expect(field.problem, 'Durée refusée');
    expect(inputs.valid, isFalse);
  });

  test(
    'a refusal uses the supplied fallback when validation has no diagnostic',
    () {
      final inputs = CinematicInputState();
      final field = inputs.field('duration', '1400')..edit('-2');

      final result = inputs.commitField(
        field,
        tryCommit: (_) => false,
        fallbackError: 'Corrigez la durée',
      );

      expect(result, CinematicFieldCommitResult.rejected);
      expect(field.problem, 'Corrigez la durée');
      expect(field.text, '-2');
      expect(field.pending, isFalse);
      expect(inputs.valid, isFalse);
    },
  );

  test(
    'validation diagnostics retain their field provenance through rejection',
    () {
      final inputs = CinematicInputState();
      final field = inputs.field('duration', '1400')..edit('-2');

      final result = inputs.commitField(
        field,
        tryCommit: (_) {
          inputs.error = inputs.inspectorError = 'Durée invalide';
          return false;
        },
        fallbackError: 'Diagnostic de secours',
      );

      expect(result, CinematicFieldCommitResult.rejected);
      expect(field.problem, 'Durée invalide');
      expect(inputs.error, 'Durée invalide');
      expect(inputs.inspectorError, 'Durée invalide');
      expect(inputs.validating, isFalse);
      inputs.discard(preserveDiagnostics: true);
      expect(inputs.field('duration', '1400'), same(field));
      expect(field.text, '1400');
      expect(inputs.error, isNull);
      expect(inputs.inspectorError, isNull);
      expect(inputs.valid, isTrue);
    },
  );

  test('an identical independent diagnostic survives discarding the committed field', () {
    final inputs = CinematicInputState();
    final field = inputs.field('duration', '1400')..edit('-2');
    inputs.commitField(
      field,
      tryCommit: (_) {
        inputs.error = inputs.inspectorError = 'Durée invalide';
        return false;
      },
      fallbackError: 'Diagnostic de secours',
    );
    final revision = inputs.revision;

    inputs.error = inputs.inspectorError = 'Durée invalide';

    expect(inputs.revision, greaterThan(revision));
    inputs.discard(preserveDiagnostics: true);
    expect(field.text, '1400');
    expect(field.problem, isNull);
    expect(inputs.error, 'Durée invalide');
    expect(inputs.inspectorError, 'Durée invalide');
    expect(inputs.valid, isFalse);
  });

  test(
    'a thrown validation restores provenance without accepting the field',
    () {
      final inputs = CinematicInputState();
      final field = inputs.field('duration', '1400')..edit('-2');
      final revision = inputs.revision;

      expect(
        () => inputs.commitField(
          field,
          tryCommit: (_) => throw StateError('Validation interrompue'),
          fallbackError: 'Durée refusée',
        ),
        throwsStateError,
      );

      expect(inputs.validating, isFalse);
      expect(inputs.revision, revision);
      expect(field.pending, isTrue);
      expect(field.text, '-2');
      inputs.actionError = 'Action indépendante';
      inputs.discard(preserveDiagnostics: true);
      expect(inputs.actionError, 'Action indépendante');
    },
  );

  test('committing one owner preserves another cinematic inputs', () {
    final inputs = CinematicInputState();
    final other = CinematicInputState();
    final field = inputs.field('duration', '1400')..edit('1750');
    final otherField = other.field('duration', '800')
      ..edit('-3')
      ..reject('Erreur B');
    final revision = other.revision;

    expect(
      inputs.commitField(
        field,
        tryCommit: (_) => true,
        fallbackError: 'Durée refusée',
      ),
      CinematicFieldCommitResult.accepted,
    );

    expect(other.revision, revision);
    expect(other.field('duration', '800'), same(otherField));
    expect(otherField.text, '-3');
    expect(other.error, 'Erreur B');
    expect(other.dirty, isTrue);
  });

  test('a foreign field is refused without changing either owner', () {
    final inputs = CinematicInputState();
    final other = CinematicInputState();
    final field = other.field('duration', '800')..edit('-3');
    final revision = other.revision;

    expect(
      () => inputs.commitField(
        field,
        tryCommit: (_) => throw StateError('Validation inattendue'),
        fallbackError: 'Durée refusée',
      ),
      throwsArgumentError,
    );

    expect(inputs.revision, 0);
    expect(inputs.validating, isFalse);
    expect(other.revision, revision);
    expect(field.text, '-3');
    expect(field.pending, isTrue);
    expect(field.problem, isNull);
  });
}
