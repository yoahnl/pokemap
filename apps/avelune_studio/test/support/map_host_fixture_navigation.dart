part of 'map_host_fixture.dart';

extension MapHostFixtureNavigation on MapHostFixture {
  Future<void> go(String destination) async {
    final target = find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip(destination),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(target);
    await pumpIo(tester, frames: 12);
  }

  Future<void> enter(String label) async {
    final target = find.text(label).first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await pumpIo(tester, frames: 15);
  }
}
