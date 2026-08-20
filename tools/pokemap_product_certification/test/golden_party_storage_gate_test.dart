import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

import 'support/golden_gate_hosts.dart';

/// Golden gate Party/PC — BETA-PTY-005.
///
/// Les briques étaient certifiées isolément (opérations pures, service PC,
/// réordonnancement pause) ; aucune gate ne fermait le parcours PRODUIT :
/// depuis un package exporté puis installé — l'espace auteur et l'archive sont
/// SUPPRIMÉS avant le lancement, donc rien ne peut fuir hors de la version
/// installée — un joueur démarre, réordonne sa Party, dépose, retire, consulte
/// la fiche PC, sauvegarde, quitte, recharge, et retrouve EXACTEMENT le même
/// roster, identités comprises.
///
/// Une seule entrée n'est pas le canal production : l'ouverture du PC
/// (debugOpenPlayerServicePc), parce que la fixture neutre n'a pas de terminal
/// sur sa carte. Tout le reste — commandes de transfert, commits, sauvegarde,
/// verrous — passe par les canaux réels (dispatchWorldService de la session,
/// actions du coordinateur).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'golden journey: reorder, deposit, withdraw, summary, save, reload',
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-golden-party-',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        const fixture = NeutralCertificationGameFixture(partySize: 2);
        final host = await GoldenGateHost.launch(
          fixture: fixture,
          root: root,
          profileId: 'player1',
          slotId: 'slot1',
        );
        addTearDown(host.dispose);

        await host.startNewGame();
        final started = host.mounted.gameStateSnapshot;
        expect(started.party.members, hasLength(2));
        final bulbasaur = started.party.members.first;
        final ivysaur = started.party.members.last;
        expect(bulbasaur.speciesId, 'bulbasaur');
        expect(ivysaur.speciesId, 'ivysaur');
        expect(bulbasaur.individualId, isNotEmpty);
        expect(ivysaur.individualId, isNotEmpty);

        // 1. Réordonner depuis le canal pause (BETA-PTY-002) : Charmander
        //    devient le Pokémon de tête.
        await host.openPause();
        await host.openPartySection();
        final reordered = await host.dispatchPlayer(
          RuntimePlayerAction.reorderParty,
          payload: RuntimePlayerPauseCommand.setPartyLead(
            partyTargetId: 'pokemon.${ivysaur.individualId}',
          ),
        );
        expect(reordered.status, RuntimePlayerCommandStatus.accepted);
        expect(
          host.mounted.gameStateSnapshot.party.members
              .map((member) => member.individualId),
          <String>[ivysaur.individualId, bulbasaur.individualId],
        );
        await host.resume();

        // 2. Le PC : déposer Bulbasaur, le retirer, le redéposer — le parcours
        //    « dépose, retire » du ticket, avec une trace durable en box.
        final pcResult = host.mounted.debugOpenPlayerServicePc();
        await host.waitForWorldService();
        final pcSnapshot = host.sessions.worldServiceSnapshot!;
        final pcContent = pcSnapshot.content! as RuntimePcServiceContent;
        expect(
          pcContent.party.map((entry) => entry.speciesId),
          <String>['ivysaur', 'bulbasaur'],
          reason: 'the PC view reflects the reordered party',
        );
        // 3. « Consulte un résumé » : la fiche du membre déposable porte ses
        //    données canoniques, pas un placeholder.
        final bulbasaurRow = pcContent.party.last;
        expect(bulbasaurRow.level, 5);
        expect(bulbasaurRow.natureId, 'hardy');
        expect(bulbasaurRow.abilityId, 'overgrow');
        expect(bulbasaurRow.canTransfer, isTrue);

        final deposited = await host.dispatchWorldService(
          RuntimeWorldServiceAction.deposit,
          targetId: 'pokemon.${bulbasaur.individualId}',
        );
        expect(deposited.status, RuntimeWorldServiceCommandStatus.accepted);

        final withdrawn = await host.dispatchWorldService(
          RuntimeWorldServiceAction.withdraw,
          targetId: 'pokemon.${bulbasaur.individualId}',
        );
        expect(withdrawn.status, RuntimeWorldServiceCommandStatus.accepted);

        final redeposited = await host.dispatchWorldService(
          RuntimeWorldServiceAction.deposit,
          targetId: 'pokemon.${bulbasaur.individualId}',
        );
        expect(redeposited.status, RuntimeWorldServiceCommandStatus.accepted);

        await host.dispatchWorldService(RuntimeWorldServiceAction.close);
        expect(
          (await pcResult).status,
          PlayerServiceRuntimeStatus.completed,
        );

        final beforeSave = host.mounted.gameStateSnapshot;
        expect(
          beforeSave.party.members.single.individualId,
          ivysaur.individualId,
        );
        final boxWithBulbasaur = beforeSave.pokemonStorage.boxes.firstWhere(
          (box) => box.pokemon.isNotEmpty,
        );
        expect(
          boxWithBulbasaur.pokemon.single.individualId,
          bulbasaur.individualId,
        );

        // 4. Sauvegarder, quitter, recharger depuis la version installée seule.
        await host.openPause();
        final saved = await host.dispatchPlayer(RuntimePlayerAction.save);
        expect(saved.status, RuntimePlayerCommandStatus.accepted);
        await host.returnToTitle();
        await host.continueGame();

        // 5. Égalité STRUCTURELLE du roster : mêmes individus, mêmes places,
        //    partout — party, box, et l'identité complète de chaque membre.
        final resumed = host.mounted.gameStateSnapshot;
        expect(
          resumed.party.members.single.individualId,
          ivysaur.individualId,
        );
        expect(
          resumed.party.members.single,
          beforeSave.party.members.single,
          reason: 'the party member reloads structurally identical',
        );
        final reloadedBox = resumed.pokemonStorage.boxes.firstWhere(
          (box) => box.pokemon.isNotEmpty,
        );
        expect(reloadedBox.id, boxWithBulbasaur.id);
        expect(
          reloadedBox.pokemon.single,
          boxWithBulbasaur.pokemon.single,
          reason: 'the boxed member reloads structurally identical',
        );
        expect(
          resumed.pokemonStorage.boxes.map((box) => box.id),
          beforeSave.pokemonStorage.boxes.map((box) => box.id),
          reason: 'the box layout itself is stable across the reload',
        );
      },
      createHttpClient: (_) => throw StateError(
        'The golden Party/PC gate must not touch the network.',
      ),
    ),
  );
}
