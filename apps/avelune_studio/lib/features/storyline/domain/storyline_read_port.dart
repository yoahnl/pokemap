import 'package:map_core/map_core_domain.dart';

typedef StorylineProposalRead = ({StorylineAsset? storyline, String? reason});

abstract interface class StorylineReadPort {
  Future<StorylineOutline> outline();

  Future<StorylineProposalRead> proposal();

  Future<List<StorylineAsset>> storylines();
}
