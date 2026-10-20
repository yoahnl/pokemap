import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/source_interaction_inventory_fixture.dart';

SourceEventTouchResolution resolveTouch(
  SourceSemanticResolver resolver,
  SourceEventAnalysis analysis,
  SourceEventDefinition event,
) =>
    resolver.resolveEventTouch(
      cell: resolver.cellAt(event.sourceMapId, event.x, event.y),
      event: event,
      page: event.pages.single,
      mapEvents: analysis.events,
    );

void main() {
  test('repeated contact checks validate each owned page and document once',
      () async {
    final source = await qualifiedTouchSource();
    final analysis = analyze(source);
    final resolver = SourceSemanticResolver.forProject(source);
    final hashes = <Sha256Hash>[];
    for (var pass = 0; pass < 4; pass++) {
      hashes.add(canonicalHashOf([
        for (final event in analysis.events)
          resolveTouch(resolver, analysis, event).toJson(),
      ]));
    }
    expect(hashes.toSet(), hasLength(1));
    expect(resolver.touchPageValidationCount, 3);
    expect(resolver.touchDocumentValidationCount, 1);

    final independent = SourceSemanticResolver.forProject(source);
    expect(independent.touchPageValidationCount, 0);
    expect(independent.touchDocumentValidationCount, 0);
    final first = analysis.events.first;
    expect(resolveTouch(independent, analysis, first).toJson(),
        resolveTouch(resolver, analysis, first).toJson());
    expect(independent.touchPageValidationCount, 3);
    expect(independent.touchDocumentValidationCount, 1);
  });

  test('cached refusal preserves unsupported raw page fields', () async {
    final source = await qualifiedTouchSource(unsupportedPageField: true);
    final analysis = analyze(source);
    final resolver = SourceSemanticResolver.forProject(source);
    for (var pass = 0; pass < 3; pass++) {
      final result = resolveTouch(resolver, analysis, analysis.events.first);
      expect(result.kind, SourceEventTouchKind.unqualified);
      expect(result.reason, 'sourceContextUnqualified');
    }
    expect(resolver.touchPageValidationCount, 1);
    expect(resolver.touchDocumentValidationCount, 1);
  });

  test(
      'a warmed resolver rejects another source hash before consulting its cache',
      () async {
    final source = await qualifiedTouchSource();
    final analysis = analyze(source);
    final resolver = SourceSemanticResolver.forProject(source);
    resolveTouch(resolver, analysis, analysis.events.first);
    final pages = resolver.touchPageValidationCount;
    final documents = resolver.touchDocumentValidationCount;
    final changed =
        analyze(await qualifiedTouchSource(unsupportedPageField: true));
    for (var pass = 0; pass < 3; pass++) {
      final result = resolveTouch(resolver, changed, changed.events.first);
      expect(result.kind, SourceEventTouchKind.unqualified);
      expect(result.reason, 'sourceContextUnqualified');
    }
    expect(resolver.touchPageValidationCount, pages);
    expect(resolver.touchDocumentValidationCount, documents);
  });
}
