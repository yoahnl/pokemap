import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const service = BattleProgressionService();

  group('BattleProgressionService move learning', () {
    test('automatically adds a crossed move with max PP and preserves rewards',
        () {
      final result = service.apply(
        state: _state(
          knownMoveIds: const <String>['tackle', 'growl'],
          currentPpByMoveId: const <String, int>{
            'tackle': 7,
            'growl': 4,
          },
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:vine_whip:6',
              moveId: 'vine_whip',
              learnedAtLevel: 6,
              maxPp: 25,
            ),
          ],
        ),
        reward: BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          money: 120,
        ),
      );

      final member = result.state.party.members.single;
      expect(member.level, 6);
      expect(member.experience, 265);
      expect(member.knownMoveIds, <String>['tackle', 'growl', 'vine_whip']);
      expect(member.currentPpByMoveId, <String, int>{
        'tackle': 7,
        'growl': 4,
        'vine_whip': 25,
      });
      expect(result.state.trainerProfile.money, 120);
      expect(result.pendingMoveLearning, isNull);
    });

    test('ignores an already known move without resetting its current PP', () {
      final result = service.apply(
        state: _state(
          knownMoveIds: const <String>['tackle'],
          currentPpByMoveId: const <String, int>{'tackle': 3},
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:tackle:6',
              moveId: 'tackle',
              learnedAtLevel: 6,
              maxPp: 35,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      final member = result.state.party.members.single;
      expect(member.knownMoveIds, <String>['tackle']);
      expect(member.currentPpByMoveId, <String, int>{'tackle': 3});
      expect(result.pendingMoveLearning, isNull);
    });

    test('does not learn candidates when no level was gained', () {
      final result = service.apply(
        state: _state(
          knownMoveIds: const <String>['tackle'],
          currentPpByMoveId: const <String, int>{'tackle': 7},
        ),
        context: _context(
          opponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(level: 1, baseExperience: 1),
          ],
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:vine_whip:6',
              moveId: 'vine_whip',
              learnedAtLevel: 6,
              maxPp: 25,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      final member = result.state.party.members.single;
      expect(member.level, 5);
      expect(member.knownMoveIds, <String>['tackle']);
      expect(member.currentPpByMoveId, <String, int>{'tackle': 7});
      expect(result.pendingMoveLearning, isNull);
    });

    test('auto-learns in order then exposes deterministic pending candidates',
        () {
      final result = service.apply(
        state: _state(
          knownMoveIds: const <String>['move_1', 'move_2', 'move_3'],
          currentPpByMoveId: const <String, int>{
            'move_1': 1,
            'move_2': 2,
            'move_3': 3,
          },
        ),
        context: _context(
          opponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(level: 50, baseExperience: 200),
          ],
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:move_4:6',
              moveId: 'move_4',
              learnedAtLevel: 6,
              maxPp: 14,
            ),
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:1:move_5:7',
              moveId: 'move_5',
              learnedAtLevel: 7,
              maxPp: 15,
            ),
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:2:move_6:8',
              moveId: 'move_6',
              learnedAtLevel: 8,
              maxPp: 16,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.state.party.members.single.level, 11);
      expect(
        result.state.party.members.single.knownMoveIds,
        <String>['move_1', 'move_2', 'move_3', 'move_4'],
      );
      expect(
          result.state.party.members.single.currentPpByMoveId!['move_4'], 14);
      expect(result.pendingMoveLearning!.partySlot, 0);
      expect(
        result.pendingMoveLearning!.opportunityId,
        'sproutle:1:move_5:7',
      );
      expect(result.pendingMoveLearning!.candidate.moveId, 'move_5');
      expect(
        result.pendingMoveLearning!.phase,
        BattleMoveLearningPhase.awaitingDecision,
      );
      expect(result.remainingMoveLearningCount, 1);

      expect(
        () => result.resolvePendingMoveLearning(
          const BattleMoveLearningDecision.replace(
            opportunityId: 'sproutle:1:move_5:7',
            partySlot: 0,
            moveId: 'move_5',
            replaceMoveIndex: 1,
            expectedReplacedMoveId: 'move_2',
          ),
        ),
        throwsStateError,
      );

      final awaitingReplacement = result.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.learn(
          opportunityId: 'sproutle:1:move_5:7',
          partySlot: 0,
          moveId: 'move_5',
        ),
      );
      expect(awaitingReplacement.state, same(result.state));
      expect(
        awaitingReplacement.state.party.members.single.knownMoveIds,
        <String>['move_1', 'move_2', 'move_3', 'move_4'],
      );
      expect(
        awaitingReplacement.state.party.members.single.currentPpByMoveId,
        result.state.party.members.single.currentPpByMoveId,
      );
      expect(
        awaitingReplacement.pendingMoveLearning!.phase,
        BattleMoveLearningPhase.awaitingReplacement,
      );
      expect(awaitingReplacement.remainingMoveLearningCount, 1);

      final replaced = awaitingReplacement.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.replace(
          opportunityId: 'sproutle:1:move_5:7',
          partySlot: 0,
          moveId: 'move_5',
          replaceMoveIndex: 1,
          expectedReplacedMoveId: 'move_2',
        ),
      );
      final replacedMember = replaced.state.party.members.single;
      expect(
        replacedMember.knownMoveIds,
        <String>['move_1', 'move_5', 'move_3', 'move_4'],
      );
      expect(replacedMember.currentPpByMoveId, <String, int>{
        'move_1': 1,
        'move_3': 3,
        'move_4': 14,
        'move_5': 15,
      });
      expect(replaced.pendingMoveLearning!.candidate.moveId, 'move_6');
      expect(
        replaced.pendingMoveLearning!.phase,
        BattleMoveLearningPhase.awaitingDecision,
      );
      expect(replaced.remainingMoveLearningCount, 0);

      final declined = replaced.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.decline(
          opportunityId: 'sproutle:2:move_6:8',
          partySlot: 0,
          moveId: 'move_6',
        ),
      );
      expect(declined.state, replaced.state);
      expect(declined.pendingMoveLearning, isNull);
      expect(
        declined.moveLearningChanges.map((change) => change.kind),
        <BattleMoveLearningChangeKind>[
          BattleMoveLearningChangeKind.automaticallyLearned,
          BattleMoveLearningChangeKind.replacementRequested,
          BattleMoveLearningChangeKind.replaced,
          BattleMoveLearningChangeKind.declined,
        ],
      );
    });

    test('four known moves produce pending without silent replacement', () {
      final result = service.apply(
        state: _state(
          knownMoveIds: const <String>['one', 'two', 'three', 'four'],
          currentPpByMoveId: const <String, int>{
            'one': 1,
            'two': 2,
            'three': 3,
            'four': 4,
          },
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:five:6',
              moveId: 'five',
              learnedAtLevel: 6,
              maxPp: 5,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(
        result.state.party.members.single.knownMoveIds,
        <String>['one', 'two', 'three', 'four'],
      );
      expect(result.pendingMoveLearning!.candidate.moveId, 'five');
      expect(
        result.pendingMoveLearning!.phase,
        BattleMoveLearningPhase.awaitingDecision,
      );
    });

    test('rejects stale, mismatched, and impossible pending decisions', () {
      final pending = service.apply(
        state: _state(
          knownMoveIds: const <String>['one', 'two', 'three', 'four'],
          currentPpByMoveId: const <String, int>{
            'one': 1,
            'two': 2,
            'three': 3,
            'four': 4,
          },
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:five:6',
              moveId: 'five',
              learnedAtLevel: 6,
              maxPp: 5,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(
        () => pending.resolvePendingMoveLearning(
          const BattleMoveLearningDecision.decline(
            opportunityId: 'sproutle:0:five:6',
            partySlot: 0,
            moveId: 'stale_move',
          ),
        ),
        throwsStateError,
      );
      expect(
        () => pending.resolvePendingMoveLearning(
          const BattleMoveLearningDecision.replace(
            opportunityId: 'sproutle:0:five:6',
            partySlot: 0,
            moveId: 'five',
            replaceMoveIndex: 1,
            expectedReplacedMoveId: 'two',
          ),
        ),
        throwsStateError,
      );

      final awaitingReplacement = pending.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.learn(
          opportunityId: 'sproutle:0:five:6',
          partySlot: 0,
          moveId: 'five',
        ),
      );
      expect(
        () => awaitingReplacement.resolvePendingMoveLearning(
          const BattleMoveLearningDecision.replace(
            opportunityId: 'sproutle:0:five:6',
            partySlot: 0,
            moveId: 'five',
            replaceMoveIndex: 1,
            expectedReplacedMoveId: 'wrong_old_move',
          ),
        ),
        throwsStateError,
      );
      expect(
        () => awaitingReplacement.resolvePendingMoveLearning(
          const BattleMoveLearningDecision.replace(
            opportunityId: 'sproutle:0:five:6',
            partySlot: 0,
            moveId: 'five',
            replaceMoveIndex: 4,
            expectedReplacedMoveId: 'four',
          ),
        ),
        throwsRangeError,
      );
      expect(
        () => awaitingReplacement.resolvePendingMoveLearning(
          const BattleMoveLearningDecision.learn(
            opportunityId: 'sproutle:0:five:6',
            partySlot: 0,
            moveId: 'five',
          ),
        ),
        throwsStateError,
      );
      final declinedAfterAcceptance =
          awaitingReplacement.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.decline(
          opportunityId: 'sproutle:0:five:6',
          partySlot: 0,
          moveId: 'five',
        ),
      );
      expect(declinedAfterAcceptance.state, same(awaitingReplacement.state));
      expect(declinedAfterAcceptance.pendingMoveLearning, isNull);
      expect(
        declinedAfterAcceptance.moveLearningChanges.map(
          (change) => change.kind,
        ),
        <BattleMoveLearningChangeKind>[
          BattleMoveLearningChangeKind.replacementRequested,
          BattleMoveLearningChangeKind.declined,
        ],
      );
    });

    test('rejects a decision from the first of two identical opportunities',
        () {
      final firstPending = service.apply(
        state: _state(
          knownMoveIds: const <String>['one', 'two', 'three', 'four'],
          currentPpByMoveId: const <String, int>{
            'one': 1,
            'two': 2,
            'three': 3,
            'four': 4,
          },
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:duplicate:6',
              moveId: 'duplicate',
              learnedAtLevel: 6,
              maxPp: 10,
            ),
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:1:duplicate:6',
              moveId: 'duplicate',
              learnedAtLevel: 6,
              maxPp: 10,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );
      const firstDecision = BattleMoveLearningDecision.decline(
        opportunityId: 'sproutle:0:duplicate:6',
        partySlot: 0,
        moveId: 'duplicate',
      );

      final secondPending = firstPending.resolvePendingMoveLearning(
        firstDecision,
      );

      expect(
        secondPending.pendingMoveLearning!.opportunityId,
        'sproutle:1:duplicate:6',
      );
      expect(secondPending.pendingMoveLearning!.candidate.moveId, 'duplicate');
      expect(secondPending.pendingMoveLearning!.candidate.learnedAtLevel, 6);
      expect(
        () => secondPending.resolvePendingMoveLearning(firstDecision),
        throwsStateError,
      );
      expect(
        secondPending
            .resolvePendingMoveLearning(
              const BattleMoveLearningDecision.decline(
                opportunityId: 'sproutle:1:duplicate:6',
                partySlot: 0,
                moveId: 'duplicate',
              ),
            )
            .pendingMoveLearning,
        isNull,
      );
    });

    group('strict known-move PP invariant', () {
      final invalidCases = <({
        String name,
        List<String> knownMoveIds,
        Map<String, int>? currentPpByMoveId,
      })>[
        (
          name: 'null PP map with known moves',
          knownMoveIds: const <String>['one'],
          currentPpByMoveId: null,
        ),
        (
          name: 'missing PP key',
          knownMoveIds: const <String>['one', 'two'],
          currentPpByMoveId: const <String, int>{'one': 1},
        ),
        (
          name: 'extra PP key',
          knownMoveIds: const <String>['one'],
          currentPpByMoveId: const <String, int>{'one': 1, 'extra': 2},
        ),
        (
          name: 'untrimmed known move id',
          knownMoveIds: const <String>[' one'],
          currentPpByMoveId: const <String, int>{' one': 1},
        ),
        (
          name: 'untrimmed PP key',
          knownMoveIds: const <String>['one'],
          currentPpByMoveId: const <String, int>{' one': 1},
        ),
        (
          name: 'negative current PP',
          knownMoveIds: const <String>['one'],
          currentPpByMoveId: const <String, int>{'one': -1},
        ),
        (
          name: 'duplicate known move id',
          knownMoveIds: const <String>['one', 'one'],
          currentPpByMoveId: const <String, int>{'one': 1},
        ),
        (
          name: 'empty known move id',
          knownMoveIds: const <String>[''],
          currentPpByMoveId: const <String, int>{'': 1},
        ),
      ];

      for (final invalidCase in invalidCases) {
        test('auto-add rejects ${invalidCase.name} before mutation', () {
          final state = _state(
            knownMoveIds: invalidCase.knownMoveIds,
            currentPpByMoveId: invalidCase.currentPpByMoveId,
          );
          final memberBefore = state.party.members.single;
          final knownMovesBefore = <String>[...memberBefore.knownMoveIds];
          final ppBefore = memberBefore.currentPpByMoveId == null
              ? null
              : <String, int>{...memberBefore.currentPpByMoveId!};

          expect(
            () => service.apply(
              state: state,
              context: _context(
                candidates: const <PokemonMoveLearningCandidate>[
                  PokemonMoveLearningCandidate(
                    opportunityId: 'sproutle:strict:auto:6',
                    moveId: 'new_move',
                    learnedAtLevel: 6,
                    maxPp: 20,
                  ),
                ],
              ),
              reward: BattleReward(
                sourceKind: BattleRewardSourceKind.wild,
              ),
            ),
            throwsStateError,
          );
          expect(state.party.members.single, same(memberBefore));
          expect(state.party.members.single.knownMoveIds, knownMovesBefore);
          expect(state.party.members.single.currentPpByMoveId, ppBefore);
        });
      }

      test('replacement rejects invalid PP keys before mutation', () {
        final state = _state(
          knownMoveIds: const <String>['one', 'two', 'three', 'four'],
          currentPpByMoveId: const <String, int>{
            'one': 1,
            'two': 2,
            'three': 3,
            'four': 4,
            'extra': 5,
          },
        );
        final memberBefore = state.party.members.single;
        final pending = service.apply(
          state: state,
          context: _context(
            candidates: const <PokemonMoveLearningCandidate>[
              PokemonMoveLearningCandidate(
                opportunityId: 'sproutle:strict:replace:6',
                moveId: 'five',
                learnedAtLevel: 6,
                maxPp: 5,
              ),
            ],
          ),
          reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
        );
        final awaitingReplacement = pending.resolvePendingMoveLearning(
          const BattleMoveLearningDecision.learn(
            opportunityId: 'sproutle:strict:replace:6',
            partySlot: 0,
            moveId: 'five',
          ),
        );

        expect(
          () => awaitingReplacement.resolvePendingMoveLearning(
            const BattleMoveLearningDecision.replace(
              opportunityId: 'sproutle:strict:replace:6',
              partySlot: 0,
              moveId: 'five',
              replaceMoveIndex: 0,
              expectedReplacedMoveId: 'one',
            ),
          ),
          throwsStateError,
        );
        expect(state.party.members.single, same(memberBefore));
        expect(awaitingReplacement.state.party.members.single.knownMoveIds,
            memberBefore.knownMoveIds);
        expect(awaitingReplacement.state.party.members.single.currentPpByMoveId,
            memberBefore.currentPpByMoveId);
      });
    });

    test('public result rejects a duplicate opportunity identity per slot', () {
      final state = _state(
        knownMoveIds: const <String>['one', 'two', 'three', 'four'],
        currentPpByMoveId: const <String, int>{
          'one': 1,
          'two': 2,
          'three': 3,
          'four': 4,
        },
      );
      const candidate = PokemonMoveLearningCandidate(
        opportunityId: 'replayed-opportunity',
        moveId: 'five',
        learnedAtLevel: 6,
        maxPp: 5,
      );

      expect(
        () => BattleProgressionResult(
          rulesetReference: PokemonRulesetProfile.pokeMapBetaV1Reference,
          state: state,
          appliedReward: BattleReward(
            sourceKind: BattleRewardSourceKind.wild,
          ),
          changes: const <BattlePokemonProgressionChange>[],
          moveLearningOpportunities: const <BattleMoveLearningOpportunity>[
            BattleMoveLearningOpportunity(partySlot: 0, candidate: candidate),
            BattleMoveLearningOpportunity(partySlot: 0, candidate: candidate),
          ],
        ),
        throwsArgumentError,
      );
      expect(state.party.members.single.knownMoveIds,
          <String>['one', 'two', 'three', 'four']);
    });

    test(
        'keeps move-learning queues isolated and deterministic across participants',
        () {
      final state = _twoPartyState();
      final result = service.apply(
        state: state,
        context: BattleProgressionContext(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          outcome: BattleProgressionOutcomeKind.victory,
          playerParticipantPartySlots: const <int>{1, 0},
          defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(
              level: 28,
              baseExperience: 70,
            ),
          ],
          partySlotMetadata: <BattleProgressionPartySlotMetadata>[
            _metadataForSlot(1),
            _metadataForSlot(0),
          ],
          moveLearningCandidatesByPartySlot: const <int,
              List<PokemonMoveLearningCandidate>>{
            0: <PokemonMoveLearningCandidate>[
              PokemonMoveLearningCandidate(
                opportunityId: 'shared-across-slots',
                moveId: 'a_four',
                learnedAtLevel: 6,
                maxPp: 14,
              ),
            ],
            1: <PokemonMoveLearningCandidate>[
              PokemonMoveLearningCandidate(
                opportunityId: 'shared-across-slots',
                moveId: 'b_five',
                learnedAtLevel: 6,
                maxPp: 15,
              ),
              PokemonMoveLearningCandidate(
                opportunityId: 'slot-b-next',
                moveId: 'b_six',
                learnedAtLevel: 6,
                maxPp: 16,
              ),
            ],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.changes.map((change) => change.partySlot), <int>[0, 1]);
      expect(result.state.party.members[0].knownMoveIds,
          <String>['a_one', 'a_two', 'a_three', 'a_four']);
      expect(result.state.party.members[0].currentPpByMoveId, <String, int>{
        'a_one': 1,
        'a_two': 2,
        'a_three': 3,
        'a_four': 14,
      });
      expect(result.state.party.members[1].knownMoveIds,
          <String>['b_one', 'b_two', 'b_three', 'b_four']);
      expect(result.pendingMoveLearning!.partySlot, 1);
      expect(result.pendingMoveLearning!.opportunityId, 'shared-across-slots');
      expect(result.remainingMoveLearningCount, 1);

      final awaitingReplacement = result.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.learn(
          opportunityId: 'shared-across-slots',
          partySlot: 1,
          moveId: 'b_five',
        ),
      );
      final replaced = awaitingReplacement.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.replace(
          opportunityId: 'shared-across-slots',
          partySlot: 1,
          moveId: 'b_five',
          replaceMoveIndex: 1,
          expectedReplacedMoveId: 'b_two',
        ),
      );

      expect(replaced.state.party.members[0], result.state.party.members[0]);
      expect(replaced.state.party.members[1].knownMoveIds,
          <String>['b_one', 'b_five', 'b_three', 'b_four']);
      expect(replaced.state.party.members[1].currentPpByMoveId, <String, int>{
        'b_one': 1,
        'b_three': 3,
        'b_four': 4,
        'b_five': 15,
      });
      expect(replaced.pendingMoveLearning!.partySlot, 1);
      expect(replaced.pendingMoveLearning!.opportunityId, 'slot-b-next');
      expect(replaced.remainingMoveLearningCount, 0);

      final completed = replaced.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.decline(
          opportunityId: 'slot-b-next',
          partySlot: 1,
          moveId: 'b_six',
        ),
      );
      expect(completed.pendingMoveLearning, isNull);
      expect(completed.state.party.members[0], result.state.party.members[0]);
      expect(completed.state.party.members[1], replaced.state.party.members[1]);
    });

    test('round-trips automatically learned and replacement move PP', () {
      final pending = service.apply(
        state: _state(
          knownMoveIds: const <String>['one', 'two', 'three'],
          currentPpByMoveId: const <String, int>{
            'one': 1,
            'two': 2,
            'three': 3,
          },
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:0:four:6',
              moveId: 'four',
              learnedAtLevel: 6,
              maxPp: 14,
            ),
            PokemonMoveLearningCandidate(
              opportunityId: 'sproutle:1:five:6',
              moveId: 'five',
              learnedAtLevel: 6,
              maxPp: 15,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );
      final awaitingReplacement = pending.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.learn(
          opportunityId: 'sproutle:1:five:6',
          partySlot: 0,
          moveId: 'five',
        ),
      );
      final resolved = awaitingReplacement.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.replace(
          opportunityId: 'sproutle:1:five:6',
          partySlot: 0,
          moveId: 'five',
          replaceMoveIndex: 0,
          expectedReplacedMoveId: 'one',
        ),
      );

      final json = saveDataFromGameState(resolved.state).toJson();
      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(SaveData.fromJson(json)),
      );

      expect(
        reloaded.party.members.single.knownMoveIds,
        <String>['five', 'two', 'three', 'four'],
      );
      expect(reloaded.party.members.single.currentPpByMoveId, <String, int>{
        'five': 15,
        'two': 2,
        'three': 3,
        'four': 14,
      });
    });
  });
}

BattleProgressionContext _context({
  List<BattleProgressionDefeatedOpponent> opponents =
      const <BattleProgressionDefeatedOpponent>[
    BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
  ],
  List<PokemonMoveLearningCandidate> candidates =
      const <PokemonMoveLearningCandidate>[],
}) {
  return BattleProgressionContext(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    outcome: BattleProgressionOutcomeKind.victory,
    playerParticipantPartySlots: const <int>{0},
    defeatedOpponents: opponents,
    partySlotMetadata: <BattleProgressionPartySlotMetadata>[
      BattleProgressionPartySlotMetadata(
        partySlot: 0,
        growthRateId: 'medium',
        oldMaxHp: 19,
        baseStats: const PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
      ),
    ],
    moveLearningCandidatesByPartySlot: <int,
        List<PokemonMoveLearningCandidate>>{0: candidates},
  );
}

GameState _state({
  required List<String> knownMoveIds,
  required Map<String, int>? currentPpByMoveId,
}) {
  return GameState(
    saveId: 'move-learning',
    trainerProfile: const TrainerProfile(name: 'Player'),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          experience: 125,
          knownMoveIds: knownMoveIds,
          currentPpByMoveId: currentPpByMoveId,
          currentHp: 19,
        ),
      ],
    ),
  );
}

GameState _twoPartyState() {
  return GameState(
    saveId: 'multi-participant-move-learning',
    trainerProfile: const TrainerProfile(name: 'Player'),
    party: PlayerParty(
      members: const <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle_a',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          experience: 125,
          knownMoveIds: <String>['a_one', 'a_two', 'a_three'],
          currentPpByMoveId: <String, int>{
            'a_one': 1,
            'a_two': 2,
            'a_three': 3,
          },
          currentHp: 19,
        ),
        PlayerPokemon(
          speciesId: 'sproutle_b',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          experience: 125,
          knownMoveIds: <String>['b_one', 'b_two', 'b_three', 'b_four'],
          currentPpByMoveId: <String, int>{
            'b_one': 1,
            'b_two': 2,
            'b_three': 3,
            'b_four': 4,
          },
          currentHp: 19,
        ),
      ],
    ),
  );
}

BattleProgressionPartySlotMetadata _metadataForSlot(int partySlot) {
  return BattleProgressionPartySlotMetadata(
    partySlot: partySlot,
    growthRateId: 'medium',
    oldMaxHp: 19,
    baseStats: const PokemonBaseStats(
      hp: 45,
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
  );
}
