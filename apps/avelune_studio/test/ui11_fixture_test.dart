import 'package:flutter_test/flutter_test.dart';
import 'support/ui11_presentation_fixture.dart';

void main() {
  test(
    'UI11 isolated presentation fixture publishes real image and text',
    () async {
      final fixture = await Ui11PresentationFixture.create();
      addTearDown(fixture.dispose);
      final saved = await fixture.source.readManifest();
      expect(saved.presentationCinematics.single, fixture.asset);
      expect(fixture.asset.tracks, hasLength(2));
    },
  );
}
