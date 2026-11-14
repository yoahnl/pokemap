import 'package:map_core/map_core.dart';

Map<String, Object?> storylineOutlineJson(StorylineOutline outline) => {
      'storylines': [
        for (final storyline in outline.storylines)
          {
            'id': storyline.id,
            'title': storyline.title,
            'type': storyline.type.name,
            'status': storyline.status.name,
            'chapters': [
              for (final chapter in storyline.chapters)
                {
                  'id': chapter.id,
                  'title': chapter.title,
                  if (chapter.status case final status?) 'status': status.name,
                  'milestones': [
                    for (final milestone in chapter.milestones)
                      {
                        'id': milestone.id,
                        'title': milestone.title,
                        if (milestone.status case final status?)
                          'status': status.name,
                        'sceneIds': milestone.sceneIds,
                        'mapIds': milestone.mapIds,
                        if (milestone.completionFactId case final factId?)
                          'completionFactId': factId,
                        'issues': [
                          for (final issue in StorylineMilestoneIssue.values)
                            if (milestone.issues.contains(issue)) issue.name
                        ],
                      }
                  ],
                }
            ],
          }
      ],
      'scenesOutsideStorylines': [
        for (final scene in outline.scenesOutsideStorylines)
          {'id': scene.id, 'title': scene.title}
      ],
    };

Map<String, Object?> storylineProposalJson(StorylineProposal proposal) => {
      'storyline': proposal.storyline?.toJson(),
      'milestoneCount': proposal.milestoneCount,
      'unlockCount': proposal.unlockCount,
      'scenesOutsideStoryline': proposal.scenesOutsideStoryline,
      'persisted': false,
    };
