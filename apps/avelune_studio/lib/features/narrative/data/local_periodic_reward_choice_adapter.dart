import 'package:map_authoring/map_authoring_local.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/periodic_reward_choice_port.dart';

final class LocalPeriodicRewardChoiceAdapter implements PeriodicRewardChoicePort {
  const LocalPeriodicRewardChoiceAdapter({required this.session, this.reader = const LocalProjectFileReader()});
  final ProjectSession session;
  final ProjectFileReader reader;
  @override
  Future<AuthoringQueryPage> readPeriodicRewardChoices(AuthoringQueryRequest request) => LocalPeriodicRewardChoiceReader(projectRootPath: session.directoryPath, fileReader: reader).query(request);
}
