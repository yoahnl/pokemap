import 'package:map_authoring/map_authoring_api.dart';

abstract interface class PeriodicRewardChoicePort {
  Future<AuthoringQueryPage> readPeriodicRewardChoices(AuthoringQueryRequest request);
}
