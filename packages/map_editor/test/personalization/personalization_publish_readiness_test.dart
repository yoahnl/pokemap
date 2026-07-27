import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('projects readiness for every presentation category', () {
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
      intro: ProjectIntroVideoProfile(
        videoPath: 'assets/presentation/intro/intro.mp4',
        posterPath: 'assets/presentation/intro/poster.png',
        durationMilliseconds: 1200,
        width: 1920,
        height: 1080,
        bitrateKbps: 4000,
        sizeBytes: 2048,
        videoCodec: 'h264',
        audioCodec: 'aac',
      ),
      theme: safeProjectSemanticTheme,
    );

    final report = PersonalizationPublishReadiness.fromProfile(profile);

    expect(
      report.categories.map((item) => item.category),
      ProjectPresentationCategory.values,
    );
    expect(
      report.forCategory(ProjectPresentationCategory.branding).status,
      PersonalizationReadinessStatus.blocked,
    );
    expect(
      report.forCategory(ProjectPresentationCategory.intro).status,
      PersonalizationReadinessStatus.attention,
    );
    expect(
      report.forCategory(ProjectPresentationCategory.typography).status,
      PersonalizationReadinessStatus.ready,
    );
    expect(
      report.forCategory(ProjectPresentationCategory.theme).status,
      PersonalizationReadinessStatus.ready,
    );
    expect(report.blockerCount, 1);
    expect(report.warningCount, 1);
    expect(report.isReadyToExport, isFalse);
  });

  test('warnings stay visible without blocking export readiness', () {
    const profile = ProjectPresentationProfile(
      intro: ProjectIntroVideoProfile(
        videoPath: 'assets/presentation/intro/intro.mp4',
        posterPath: 'assets/presentation/intro/poster.png',
        durationMilliseconds: 1200,
        width: 1080,
        height: 1920,
        bitrateKbps: 4000,
        sizeBytes: 2048,
        videoCodec: 'h264',
        audioCodec: 'aac',
      ),
    );

    final report = PersonalizationPublishReadiness.fromProfile(profile);

    expect(report.status, PersonalizationReadinessStatus.attention);
    expect(report.warningCount, 1);
    expect(report.isReadyToExport, isTrue);
  });
}
