String cinematicActorName(String? label) =>
    label == null || label.trim().isEmpty ? 'Acteur sans nom' : label;

String cinematicActorChoiceLabel(String? label, String actorId) =>
    '${cinematicActorName(label)} · $actorId';

String cinematicEntityChoiceLabel(String name, String entityId) =>
    '${name.trim().isEmpty ? 'Personnage sans nom' : name} · $entityId';
