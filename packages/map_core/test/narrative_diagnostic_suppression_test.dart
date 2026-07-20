import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips an auditable versioned suppression', () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'warning:event:evt_port',
      diagnosticFingerprint: 'sha256:${'a' * 64}',
      reason: 'Accepté pour la démo publique.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 20, 10),
      expiresAt: DateTime.utc(2026, 8),
    );

    final decoded = NarrativeDiagnosticSuppression.fromJson(
      suppression.toJson(),
    );

    expect(decoded.schemaVersion, 1);
    expect(decoded.diagnosticId, suppression.diagnosticId);
    expect(decoded.diagnosticFingerprint, suppression.diagnosticFingerprint);
    expect(decoded.reason, suppression.reason);
    expect(decoded.author, suppression.author);
    expect(decoded.createdAt, DateTime.utc(2026, 7, 20, 10));
    expect(decoded.expiresAt, DateTime.utc(2026, 8));
  });

  test('expiration is inclusive and evaluated against UTC', () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'diagnostic',
      diagnosticFingerprint: 'sha256:${'b' * 64}',
      reason: 'Dette suivie.',
      author: 'Auteur',
      createdAt: DateTime.utc(2026, 7, 20),
      expiresAt: DateTime.utc(2026, 7, 21),
    );

    expect(
      suppression.isExpiredAt(DateTime.utc(2026, 7, 20, 23, 59)),
      isFalse,
    );
    expect(
      suppression.isExpiredAt(DateTime.utc(2026, 7, 21)),
      isTrue,
    );
  });

  test('rejects malformed fingerprints and incomplete audit fields', () {
    expect(
      () => NarrativeDiagnosticSuppression(
        diagnosticId: 'diagnostic',
        diagnosticFingerprint: 'not-a-fingerprint',
        reason: 'Raison',
        author: 'Auteur',
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeDiagnosticSuppression(
        diagnosticId: 'diagnostic',
        diagnosticFingerprint: 'sha256:${'c' * 64}',
        reason: ' ',
        author: 'Auteur',
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });

  test('atomic mutation cannot smuggle an unrelated manifest change', () {
    final before = ProjectManifest(
      name: 'Before',
      maps: const [],
      tilesets: const [],
    );
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'diagnostic',
      diagnosticFingerprint: 'sha256:${'d' * 64}',
      reason: 'Décision auditée.',
      author: 'Auteur',
      createdAt: DateTime.utc(2026),
    );

    expect(
      () => NarrativeDiagnosticSuppressionsUpdated(
        before: before,
        after: before.copyWith(
          name: 'Smuggled',
          narrativeDiagnosticSuppressions: [suppression],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      NarrativeDiagnosticSuppressionsUpdated(
        before: before,
        after: before.copyWith(
          narrativeDiagnosticSuppressions: [suppression],
        ),
      ).isApplicable,
      isTrue,
    );
  });

  test('project validator rejects two owners for one diagnostic', () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'diagnostic',
      diagnosticFingerprint: 'sha256:${'e' * 64}',
      reason: 'Décision auditée.',
      author: 'Auteur',
      createdAt: DateTime.utc(2026),
    );
    final project = ProjectManifest(
      name: 'Duplicate owner',
      maps: const [],
      tilesets: const [],
      narrativeDiagnosticSuppressions: [suppression, suppression],
    );

    expect(() => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()));
  });
}
