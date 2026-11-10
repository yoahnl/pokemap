import 'package:map_core/map_core_domain.dart';

String eventValueLabel(NarrativeValue value) =>
    value.kind == NarrativeValueKind.boolean
    ? value.boolValue
          ? 'Oui'
          : 'Non'
    : value.toJson().toString();
