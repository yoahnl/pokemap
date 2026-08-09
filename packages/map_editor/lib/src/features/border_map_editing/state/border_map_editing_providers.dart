import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/active_border_feature_controller.dart';

final activeBorderFeatureControllerProvider =
    NotifierProvider<ActiveBorderFeatureController, ActiveBorderFeatureState>(
        ActiveBorderFeatureController.new);
