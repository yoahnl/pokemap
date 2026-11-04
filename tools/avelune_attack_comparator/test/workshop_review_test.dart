import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avelune_attack_compare/workshop_review.dart';
import 'package:avelune_attack_compare/workshop_review_controls.dart';

void main() {
  test('keeps reviews for distinct attacks and variants after reopening', () async {
    final root = await Directory.systemTemp.createTemp('atelier-review-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/reviews.json');
    final first = WorkshopReviewStore(file);
    await first.load();
    final tackle = workshopReviewKey('tackle');
    final flyOne = workshopReviewKey('fly', variant: 'Fly');
    final flyTwo = workshopReviewKey('fly', variant: 'Fly_Variant1');
    await Future.wait([
      first.save(tackle, WorkshopReviewStatus.approved),
      first.save(flyOne, WorkshopReviewStatus.issue),
      first.save(flyTwo, WorkshopReviewStatus.approved),
    ]);
    final reopened = WorkshopReviewStore(file);
    await reopened.load();
    expect(reopened.statusFor(tackle), WorkshopReviewStatus.approved);
    expect(reopened.statusFor(flyOne), WorkshopReviewStatus.issue);
    expect(reopened.statusFor(flyTwo), WorkshopReviewStatus.approved);
    await reopened.save(flyOne, WorkshopReviewStatus.toReview);
    final restored = WorkshopReviewStore(file);
    await restored.load();
    expect(restored.statusFor(flyOne), WorkshopReviewStatus.toReview);
    expect(restored.statusFor(tackle), WorkshopReviewStatus.approved);
  });

  test('does not overwrite malformed review data', () async {
    final root = await Directory.systemTemp.createTemp('atelier-review-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/reviews.json');
    await file.writeAsString('{broken');
    final store = WorkshopReviewStore(file);
    await expectLater(store.load(), throwsFormatException);
    await expectLater(store.save('tackle', WorkshopReviewStatus.approved), throwsFormatException);
    expect(await file.readAsString(), '{broken');
  });

  test('preserves changes made from two open stores', () async {
    final root = await Directory.systemTemp.createTemp('atelier-review-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/reviews.json');
    final first = WorkshopReviewStore(file);
    final second = WorkshopReviewStore(file);
    await Future.wait([first.load(), second.load()]);
    await Future.wait([
      first.save('tackle', WorkshopReviewStatus.approved),
      second.save('surf', WorkshopReviewStatus.issue),
    ]);
    final reopened = WorkshopReviewStore(file);
    await reopened.load();
    expect(reopened.statusFor('tackle'), WorkshopReviewStatus.approved);
    expect(reopened.statusFor('surf'), WorkshopReviewStatus.issue);
  });

  testWidgets('review controls navigate and report a human decision', (tester) async {
    var next = 0;
    WorkshopReviewStatus? chosen;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WorkshopReviewControls(
      status: WorkshopReviewStatus.toReview,
      enabled: true,
      canGoPrevious: false,
      canGoNext: true,
      onPrevious: () => fail('previous must be disabled'),
      onNext: () => next++,
      onChanged: (value) => chosen = value,
    ))));
    final previous = find.ancestor(of: find.byTooltip('Attaque précédente'), matching: find.byType(IconButton));
    expect(tester.widget<IconButton>(previous).onPressed, isNull);
    await tester.tap(find.byTooltip('Attaque suivante'));
    expect(next, 1);
    await tester.tap(find.text('À revoir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écart à corriger').last);
    await tester.pumpAndSettle();
    expect(chosen, WorkshopReviewStatus.issue);
  });
}
