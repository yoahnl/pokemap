import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import 'support/trainer_program_fixture.dart';
import 'support/interpretation_profile_fixture.dart';

List<TrainerRubyObject> portraitCommands() {
  List<TrainerRubyObject> route(int actor, List<TrainerRubyObject> moves,
          {bool barrier = false}) =>
      [
        trainerCommand(
            209,
            [
              actor,
              trainerRoute([...moves, trainerMove(0)])
            ],
            indent: 2),
        for (final move in moves) trainerCommand(509, [move], indent: 2),
        if (barrier) trainerCommand(210, [], indent: 2),
      ];
  return [
    trainerCommand(101, ['A photo of Dr. Fuji.']),
    trainerCommand(111, [1, 38, 0, 4, 1]),
    trainerCommand(111, [0, 64, 0], indent: 1),
    ...route(9, [trainerMove(19), trainerMove(35)], barrier: true),
    trainerCommand(355, ['pbExclaim(get_character(9))'], indent: 2),
    trainerCommand(101, ['Do you know him?'], indent: 2),
    ...route(-1, [trainerMove(16)], barrier: true),
    trainerCommand(106, [20], indent: 2),
    ...route(9, [
      for (final pattern in [1, 2, 3, 0]) ...[
        TrainerRubyObject('RPG::MoveCommand', {
          '@code': 41,
          '@parameters': ['trainer_SCIENTIST', 0, 8, pattern]
        }),
        TrainerRubyObject('RPG::MoveCommand', {
          '@code': 15,
          '@parameters': [2]
        }),
      ]
    ]),
    trainerCommand(106, [10], indent: 2),
    for (final text in [
      'He is safe.',
      'He founded the lab.',
      'I wish I could hear his stories.'
    ])
      trainerCommand(101, [text], indent: 2),
    ...route(9, [trainerMove(36)]),
    trainerCommand(111, [1, 38, 0, 4, 0], indent: 2),
    trainerCommand(122, [38, 38, 1, 0, 1], indent: 3),
    trainerCommand(0, [], indent: 3),
    trainerCommand(412, [], indent: 2),
    trainerCommand(0, [], indent: 2),
    trainerCommand(412, [], indent: 1),
    trainerCommand(0, [], indent: 1),
    trainerCommand(412, []),
    trainerCommand(0, []),
  ];
}

Future<NormalizedSourceProject> portraitSource(
        {void Function(List<TrainerRubyObject>)? mutate}) =>
    trainerSource(
        mapId: 61,
        eventId: 8,
        eventName: 'Fuji portrait',
        variableNames: List.generate(40, (i) => 'Variable $i'),
        switchNames: List.generate(66, (i) => 'Switch $i'),
        mutate: (pages) {
          pages.removeLast();
          pages.single.fields['@trigger'] = 0;
          (pages.single.fields['@graphic'] as TrainerRubyObject)
              .fields['@character_name'] = '';
          pages.single.fields['@list'] = portraitCommands();
          mutate?.call(pages);
        });

SourceEventAnalysis portraitAnalysis(NormalizedSourceProject source) {
  final profile = SourceInterpretationProfile.fromJson({
    ...fixtureSourceInterpretationProfile.toJson(),
    'sections': {
      ...fixtureSourceInterpretationProfile.toJson()['sections'] as Map,
      'events.Utilities': (fixtureSourceInterpretationProfile
          .toJson()['sections'] as Map)['events.Interpreter']
    }
  });
  return SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source,
              scriptsArchiveHash: profile.scriptsArchiveHash,
              interpretationProfile: profile))
      .analyze();
}

List<SourcePortraitProgramNode> programs(NormalizedSourceProject source) =>
    portraitAnalysis(source)
        .events
        .single
        .pages
        .expand((page) => page.body.nodes)
        .whereType<SourcePortraitProgramNode>()
        .toList();

void main() {
  test('portrait requires the pinned Utilities role for its exclamation helper',
      () async {
    final source = await portraitSource();
    expect(
        analyzeTrainerSource(source)
            .events
            .single
            .pages
            .single
            .body
            .nodes
            .whereType<SourcePortraitProgramNode>(),
        isEmpty);
  });
  test(
      'complete source portrait exposes guards presentation and conditional writer38',
      () async {
    final source = await portraitSource();
    final program = programs(source).single;
    expect(program.actorEventId, 9);
    expect(program.sourcePoseCharset, 'trainer_SCIENTIST');
    expect(program.body.nodes.first, isA<SourceTextNode>());
    final gate = program.body.nodes.last as SourceConditionalNode;
    expect(gate.condition.variableId, 38);
    expect(gate.condition.minimum, 4);
    expect(gate.condition.comparisonOperator, 1);
    final flag = gate.whenTrue.nodes.single as SourceConditionalNode;
    expect(flag.condition.factId, contains(':switch:64'));
    expect(
        flag.whenTrue.nodes
            .whereType<SourcePortraitPresentationNode>()
            .map((n) => n.stage),
        SourcePortraitPresentationStage.values);
    final once = flag.whenTrue.nodes.last as SourceConditionalNode;
    expect(once.condition.comparisonOperator, 0);
    expect((once.whenTrue.nodes.single as SourceVariableAdjustNode).delta, 1);
    expect(
        program.isBoundToSourceEvent(
            source: source,
            profile: portraitAnalysis(source).profile,
            sourceMapId: 61,
            event: source.maps.single.map.events.single),
        isTrue);
  });
  for (final mutation in <String, void Function(List<TrainerRubyObject>)>{
    'extra page': (pages) => pages.add(pages.single),
    'trigger': (pages) => pages.single.fields['@trigger'] = 1,
    'condition': (pages) =>
        (pages.single.fields['@condition'] as TrainerRubyObject)
            .fields['@switch1_valid'] = true,
    'autonomous movement': (pages) => pages.single.fields['@move_type'] = 3,
    'unknown raw field': (pages) =>
        pages.single.extraFields.add(const MapEntry('@custom', 1)),
    'extra command': (pages) => (pages.single.fields['@list'] as List)
        .insert(1, trainerCommand(355, ['pbUnknown'])),
    'wrong actor': (pages) =>
        ((pages.single.fields['@list'] as List)[3] as TrainerRubyObject)
            .fields['@parameters'] = [
          10,
          trainerRoute([trainerMove(19), trainerMove(35), trainerMove(0)])
        ],
    'wrong variable': (pages) =>
        ((pages.single.fields['@list'] as List)[1] as TrainerRubyObject)
            .fields['@parameters'] = [1, 39, 0, 4, 1],
    'wrong comparison': (pages) =>
        ((pages.single.fields['@list'] as List)[1] as TrainerRubyObject)
            .fields['@parameters'] = [1, 38, 0, 4, 0],
    'wrong switch': (pages) =>
        ((pages.single.fields['@list'] as List)[2] as TrainerRubyObject)
            .fields['@parameters'] = [0, 65, 0],
    'wrong exclamation': (pages) =>
        ((pages.single.fields['@list'] as List)[7] as TrainerRubyObject)
            .fields['@parameters'] = ['pbExclaim(get_character(10))'],
    'wrong wait': (pages) =>
        ((pages.single.fields['@list'] as List)[12] as TrainerRubyObject)
            .fields['@parameters'] = [21],
    'missing unlock': (pages) =>
        (pages.single.fields['@list'] as List).removeAt(26),
    'wrong increment': (pages) {
      final command = (pages.single.fields['@list'] as List)
          .cast<TrainerRubyObject>()
          .singleWhere((c) => c.fields['@code'] == 122);
      command.fields['@parameters'] = [38, 38, 1, 0, 2];
    },
    'pose outside row': (pages) {
      final route =
          ((pages.single.fields['@list'] as List)[13] as TrainerRubyObject)
              .fields['@parameters'] as List;
      final steps = (route[1] as TrainerRubyObject).fields['@list'] as List;
      (steps.first as TrainerRubyObject).fields['@parameters'] = [
        'trainer_SCIENTIST',
        0,
        8,
        4
      ];
    },
    'pose different charset': (pages) {
      final route =
          ((pages.single.fields['@list'] as List)[13] as TrainerRubyObject)
              .fields['@parameters'] as List;
      final steps = (route[1] as TrainerRubyObject).fields['@list'] as List;
      (steps.first as TrainerRubyObject).fields['@parameters'] = [
        'NPC_FRLG_SCIENTIST',
        0,
        8,
        1
      ];
    },
    'repeating reaction': (pages) {
      final route =
          ((pages.single.fields['@list'] as List)[3] as TrainerRubyObject)
              .fields['@parameters'] as List;
      (route[1] as TrainerRubyObject).fields['@repeat'] = true;
    },
    'route raw extension': (pages) {
      final route =
          ((pages.single.fields['@list'] as List)[3] as TrainerRubyObject)
              .fields['@parameters'] as List;
      (route[1] as TrainerRubyObject)
          .extraFields
          .add(const MapEntry('@custom', 1));
    },
    'mismatched route copy': (pages) =>
        ((pages.single.fields['@list'] as List)[4] as TrainerRubyObject)
            .fields['@parameters'] = [trainerMove(16)],
    'script route': (pages) {
      final route =
          ((pages.single.fields['@list'] as List)[3] as TrainerRubyObject)
              .fields['@parameters'] as List;
      final steps = (route[1] as TrainerRubyObject).fields['@list'] as List;
      steps[0] = TrainerRubyObject('RPG::MoveCommand', {
        '@code': 45,
        '@parameters': ['customScript']
      });
    },
    'extra effects': (pages) => (pages.single.fields['@list'] as List)
        .insert(28, trainerCommand(121, [1, 1, 0], indent: 2)),
    'excess command budget': (pages) => (pages.single.fields['@list'] as List)
        .insertAll(
            1,
            List<TrainerRubyObject>.generate(
                129, (_) => trainerCommand(101, ['Extra']))),
  }.entries) {
    test('portrait refuses ${mutation.key} in the complete program', () async {
      expect(programs(await portraitSource(mutate: mutation.value)), isEmpty);
    });
  }
}
