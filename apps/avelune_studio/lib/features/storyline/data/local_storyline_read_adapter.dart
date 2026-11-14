import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../game_memory/data/local_narrative_read.dart';
import '../../project_session/data/local_workshop_reader.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/storyline_read_port.dart';

final class LocalStorylineReadAdapter implements StorylineReadPort {
  LocalStorylineReadAdapter(
    this.session, {
    this.reader = const LocalProjectFileReader(),
  });

  final ProjectSession session;
  final ProjectFileReader reader;

  Future<Map<String, Object?>> _summary(String kind) =>
      readNarrativeIndex(session, reader, (reads, handle) async {
        final page = await reads.queryProject(
          handle,
          AuthoringQueryRequest(
            resourceKind: kind,
            operation: AuthoringQueryOperation.summary,
            pageSize: 1,
          ),
        );
        return Map<String, Object?>.from(page.items.single);
      });

  @override
  Future<StorylineOutline> outline() async =>
      _outline(await _summary(storylineOutlineResourceKind));

  @override
  Future<StorylineProposalRead> proposal() async {
    final item = await _summary(storylineProposalResourceKind);
    return (
      storyline: switch (item['storyline']) {
        final Map<Object?, Object?> json => StorylineAsset.fromJson(
          Map<String, dynamic>.from(json),
        ),
        _ => null,
      },
      reason: item['reason'] as String?,
    );
  }

  @override
  Future<List<StorylineAsset>> storylines() =>
      LocalWorkshopReader(session, reader: reader).read(
        metadataFields: const {'storylines'},
        operation: (project, _, _) async => project.storylines,
      );
}

List<Map<String, Object?>> _maps(Object? value) => [
  for (final item in value as List? ?? const [])
    if (item is Map) Map<String, Object?>.from(item),
];

List<String> _strings(Object? value) => [
  for (final item in value as List? ?? const [])
    if (item is String) item,
];

StorylineStatus? _status(Object? value) =>
    StorylineStatus.values.where((status) => status.name == value).firstOrNull;

StorylineOutline _outline(Map<String, Object?> json) => StorylineOutline(
  storylines: [
    for (final storyline in _maps(json['storylines']))
      StorylineOutlineStoryline(
        id: storyline['id'] as String,
        title: storyline['title'] as String,
        type: StorylineType.values.byName(storyline['type'] as String),
        status: _status(storyline['status']) ?? StorylineStatus.active,
        chapters: [
          for (final chapter in _maps(storyline['chapters']))
            StorylineOutlineChapter(
              id: chapter['id'] as String,
              title: chapter['title'] as String,
              status: _status(chapter['status']),
              milestones: [
                for (final milestone in _maps(chapter['milestones']))
                  StorylineOutlineMilestone(
                    id: milestone['id'] as String,
                    title: milestone['title'] as String,
                    status: _status(milestone['status']),
                    sceneIds: _strings(milestone['sceneIds']),
                    mapIds: _strings(milestone['mapIds']),
                    completionFactId: milestone['completionFactId'] as String?,
                    issues: {
                      for (final issue in _strings(milestone['issues']))
                        ?StorylineMilestoneIssue.values
                            .where((value) => value.name == issue)
                            .firstOrNull,
                    },
                  ),
              ],
            ),
        ],
      ),
  ],
  scenesOutsideStorylines: [
    for (final scene in _maps(json['scenesOutsideStorylines']))
      (id: scene['id'] as String, title: scene['title'] as String),
  ],
);
