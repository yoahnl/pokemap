# AC-06 — Conversion littérale des tuiles RMXP

Statut technique : PASS borné aux tuiles ordinaires, avec implémentation, tests, AOT et édition/sauvegarde/réouverture dans Studio vérifiés. Revue humaine non acquise. Application prévue : `apps/avelune_converter`, non créée dans ce lot.

## Périmètre et audit initial

Le lot reproduit les tuiles ordinaires dans des cartes natives éditables, sans image globale aplatie. Contrats du kit : TIL-01, TIL-02, TIL-03, TIL-04 et MAP-05. Le corpus humain autorisé est Kanto sous `Downloads/The-PMon-World-Project-main`. Les sources et les sessions Studio humaines sont préservées.

Départ : branche `main`, HEAD `010297e9808c8e6c0a4e1b003eb4702adc78d9c9`, index vide, 257 chemins étrangers préexistants. AC-05 fournissait le bootstrap et le writer natif vérifié. Audit des modèles source, codecs natifs, palette, pile visuelle, ports, quotas, admission et transferts statiques avant implémentation. Les contrôles frais ont confirmé 257 empreintes étrangères et 15 fichiers du contrat cible inchangés.

L'oracle local `pokemonsdk-development/scripts/4 Systems/003 Map Engine/2 Logic/02 Tilemap/010 MapData.rb:85–99` confirme les intervalles XP ; `1 Graphics/320 Sprite_Character.rb:108–115` confirme le crop ordinaire. Le transfert statique 201 est lu comme dépendance depuis `scripts/1 RMXP Scripts/028 Interpreter_5.rb:21–33`. Ces fichiers ont été lus, jamais exécutés ou copiés comme code Dart. Leur SHA est respectivement `b76ef747b8110523b00fa2bdf9e09aeff69707f0abbd6dc21edb98f07669a0ac`, `153261bbbc9ccca3867ae187af82814674baad382d4889920a730a29ff1df268` et `3a7371a6dbc2248e57a6c7fb1b6601dee6bd250c1ffe35da076f15fa2daaa341`.

La demande directe interdit les commentaires de code ; elle prime sur la préférence contraire de `codex_rule.md`. L'objectif humain autorise tous les lots et un commit par lot ; les contraintes particulières du kit restent des critères techniques, pas des approbations humaines.

## Décisions et limites

- ID 0 : vide ; 1–47 : diagnostic réservé ; 48–383 : autotiles différés à AC-07 ; à partir de 384 : index ordinaire `id - 384`, colonne modulo 8 et ligne divisée par 8, cellules 32 × 32, atlas de largeur 256.
- Le PNG original est conservé octet pour octet. Aucun colorkey magenta, aucun réencodage ni perte de RGB sous alpha zéro. CRC, chunks, IDAT et budgets sont vérifiés avant écriture.
- Identité du tileset fondée sur la source et le namespace, distincte du hash d'image. Deux sources partageant les mêmes octets gardent leurs propriétés et leurs identités ; les copies sont comptées dans les quotas.
- Provenance source Z0/Z1/Z2 conservée ; pile native sérialisée Z2/Z1/Z0 pour une peinture Z0/Z1/Z2. La priorité RGSS, les passages et les terrains sont conservés comme provenance ; leur consommation gameplay et l'occlusion des acteurs restent à AC-12.
- Dépendances statiques hors sélection : inclusion explicite, exclusion documentée d'étude ou blocage. Une décision est liée au snapshot, à la sélection et au locator. Transferts dynamiques inconnus bloqués ; aucun événement ou warp natif actif créé en AC-06.
- Composition et plan strictement liés aux mappings, archives, images, cellules et décisions. Les contradictions restent refusées même après recalcul de hashes et admission core valide. Mode étude seulement, `playableCertified=false` ; profil Kanto `requiresConfirmation`.
- Les noms cibles sont trimés ou remplacés par un nom de secours ; les libellés source et leur hash restent intacts. Toutes les collections exposées sont immuables.

## Fichiers et zones

| Fichier | Zones et impact |
|---|---|
| `packages/avelune_converter_adapters/lib/src/literal_tile_composer.dart` | 8–227 : contrats immuables de décision, crop, couche et résultat ; 228–747 : sélection, closure de dépendances, admission des images, fraîcheur et quotas ; 751–969 : cartes, palettes, mutations et preuves natives. Nouveau composeur déterministe. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | `NativeWriteLimits.validate`, `NativeProjectDraft.compositionEvidence`, import partagé sous budget ; 840–1110 : binding/contents exacts et refus du mode jouable ; 1177–1361 : validateur PNG public réutilisé. Aucune modification des modèles natifs. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Export du composeur. |
| `packages/avelune_converter_adapters/test/literal_tile_composer_test.dart` | 53 tests indépendants : bornes IDs, RGBA, ordre peint, identités, décisions, provenance forgée, budgets, annulation, scanner réel, write/edit/reopen et libellés. |
| `packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart` | Fixtures originales Marshal/Table, PNG exact 256 × 64 et port de lecture contrôlé, inventaire conforme au scanner. |
| `packages/avelune_converter_adapters/test/support/native_writer_fixture.dart` | Paramètres explicites de sélection/dépendances/mode, binding conservé ; admission synthétique bornée aux fixtures de test. |
| `packages/avelune_converter_adapters/test/native_project_writer_test.dart` | Test du coût de deux copies d'image, même si leurs octets sont identiques. |
| `packages/avelune_converter_adapters/tool/literal_tile_probe.dart` | AOT réel scan → normalisation → composition → writer sur source originale contrôlée, avec vérification native et empreintes source. |
| `packages/avelune_converter_adapters/tool/literal_tile_source_probe.dart` | Inspection AOT Kanto en lecture seule, compteurs et transferts réels ; preview optionnel de la composition, sans admission ni écriture de production. |
| `documentation/reports/converter/AC-06/06_literal_tiles.md` | Rapport consolidé du lot. |
| `documentation/reports/converter/AC-06/commands.json` | Commandes, résultats exacts, logs et reçus locaux hashés. |
| `documentation/reports/converter/AC-06/index.json` | Inventaire hashé, preuves source/native/MCP, gates et limites. |

Les sources et le diff Git sont les preuves des modifications ; aucun snapshot intégral des fichiers n'est recopié dans ce rapport. Avant ajout des preuves, le diff des quatre fichiers suivis était de 230 insertions et 15 suppressions ; les cinq nouveaux fichiers de code sont inventoriés séparément.

## Tests et builds frais

| Répertoire | Commande | Résultat exact |
|---|---|---|
| `packages/avelune_converter_adapters` | `dart test test/literal_tile_composer_test.dart --reporter expanded --concurrency 1 --name 'native source labels'` | Exit 0 ; `00:02 +2: All tests passed!` ; 4,660 s. |
| idem | `dart test --reporter expanded --concurrency 1` | Exit 0 ; `00:11 +164: All tests passed!` ; 13,366 s : 53 composer, 46 writer, 39 snapshot, 26 filesystem. |
| idem | `dart analyze` | Exit 0 ; `No issues found!` ; 1,556 s. |
| `packages/avelune_converter_core` | `dart test --reporter expanded --concurrency 1` | Exit 0 ; `00:20 +566: All tests passed!` ; 22,356 s. |
| idem | `dart analyze` | Exit 0 ; `No issues found!` ; 1,142 s. |
| `tools/avelune_converter_cli` | `dart test --reporter expanded --concurrency 1` | Exit 0 ; `00:13 +22 ~3: All tests passed!` ; 15,776 s ; trois tests opt-in ignorés. |
| idem | `dart analyze` | Exit 0 ; `No issues found!` ; 2,269 s. |
| `packages/map_authoring` | `dart test test/tooling/jsonl_mutation_worker_test.dart --reporter expanded --concurrency 1` | Exit 0 ; `00:00 +3: All tests passed!` ; 2,834 s. |
| `tools/pokemap_mcp` | `npm run check` puis `npm run build` | Exit 0/0 ; 1,414 s/1,314 s. |
| `packages/avelune_converter_adapters` | `dart compile exe tool/literal_tile_probe.dart -o /private/tmp/avelune-converter-ac06-literal-probe-final` | Exit 0 ; 22,940 s. |
| idem | `dart compile exe tool/literal_tile_source_probe.dart -o /private/tmp/avelune-converter-ac06-source-probe-final-5d3b` | Exit 0 ; 8,034 s. |
| idem | `/private/tmp/avelune-converter-ac06-literal-probe-final --offline --parent /Users/karim/Project/pokemonProject/.dart_tool/avelune_converter_ac06` | Exit 0 ; 0,357 s ; natif vérifié, source inchangée, publication et certification jouable fausses. |

Les SHA production avant/après les dernières suites sont identiques : composer `5d3ba67354a8d00a31b5757020336578fceb0959cf255b842b23bb0d5cb69c61`, writer `f64bfca2ae4a295cd0145c4cc9e20bd1beb3282d9c358fbc5b6f1b596b65fe4e`. Aucun survivant confirmé ni signal envoyé sur les commandes finales ; seuls les descendants possédés étaient surveillés. Les stdout complets des tests sont conservés dans le reçu local `/private/tmp/avelune-converter-ac06-post-labels-final-receipts.json`, SHA `f50a39470222e6f269a2c731faa30a4fe0b135de6043c9dce386099d7a03c248`.

Six RED réels ont précédé leurs corrections : stub non implémenté, PNG scanner `raster` refusé, pile visuelle inversée/alpha masqué, mode jouable et certification forgée admis, mappings/archive contradictoires rehashés, noms source avec espaces refusés à l'écriture. Les reçus RED locaux sous `/private/tmp/avelune-converter-ac06-*-red-receipt.json` restent distincts des GREEN finaux. Le premier GREEN sur fixture manuelle ne constituait pas une preuve du scanner réel.

## Qualification source et native

Le probe AOT relit Kanto sans mutation : 383 maps, 266 sans autotiles, 117 avec autotiles, zéro ID réservé ; 33 diagnostics source bloquants (32 images absentes et une métadonnée de tuiles absente). Snapshot frais inchangé `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de`. Le profil reste `requiresConfirmation` ; aucune approbation humaine de production.

Daisy's House (map 8) détecte deux transferts vers 6 et 79 : sans décision explicite, aucun draft n'est préparé. Route 9 (map 98, 72 × 61) prépare en lecture seule une composition avec 69 crops, trois couches et aucun blocker. Ses 16 événements restent différés ; aucun projet Kanto n'a été écrit ou publié par cette inspection.

L'AOT final sur source originale contrôlée produit un projet natif vérifié dans `.dart_tool/avelune_converter_ac06/ac06-original-qualification-2DLR67/.avelune-converter-stage-tM0X2h/converted-literal-fixture`. `sourceUnchanged=true`, `verified=true`, `published=false`, `playableCertified=false`, `humanProductionApproval=false`. Le consentement de ce harness reste synthétique et n'est jamais un mécanisme de production.

Une seconde fixture a été ouverte dans le MCP configuré puis peinte avec `map.apply_operations` / `region.paint` : Z2, cellule 2,2, localTileId 8. L'écriture, la relecture et la fermeture/réouverture fraîche conservent cette référence ; structure et références valides. Le workspace est fermé. Le catalogue live reste 397 mutations/60 resources, protocole `pokemap.authoring.v1`.

La certification globale MCP reste PARTIAL : les échecs généraux de conformance déjà documentés en AC-05 ne sont pas réparés dans ce lot. Aucune sémantique native nouvelle n'a été ajoutée ; le transport focalisé des cellules est prouvé. Le test de JSONL utilise la vraie API directe et le même type d'opération de palette. Aucun `map.save` générique n'est utilisé comme substitut de preuve sémantique.

## Qualification visible Studio

TIL-03 : PASS borné, `uiObserved=true`. Une instance Studio à bundle et container dédiés a ouvert la copie d'un projet original contrôlé. La capture initiale montre Z1 vert devant Z0 rouge au centre. La palette native a sélectionné `localTileId=8`, puis une peinture en 1,1 sur Z2 a changé la seule cellule `/layers/0/cells/4` de 0 à 3. Les couches inférieures sont intactes ; le root a vérifié indépendamment le diff JSON exact.

Le bouton Enregistrer a produit la révision `sha256:d1b178a90be5dc992fe84b8beee5aacb7adfa0f21240834dad81631c132dadce`, avec `dirty=false` et `saving=false`. Une réouverture dans un nouveau processus, PID 75774 puis 79789, retrouve exactement la carte et la révision sauvegardées ; zéro erreur Flutter dans cette instance fraîche. Les captures avant peinture et après réouverture sont respectivement `ui-1-005-0.png`, SHA `5d9dfbd58385fd1740a0887f68f4a5e692812a7223ff113ff265da8ee94503d2`, et `ui-2-021-0.png`, SHA `f796eb0af38c1158e27249d838221241697a722fdaeb7929b105c7f309975b27`, sous `/private/tmp/avelune-converter-ac06-runtime-contracts-20261012/`. Cette preuve qualifie la composition opaque et la persistance Studio ; le mélange alpha à l'écran reste hors verdict.

Commande du superviseur : `python3 /private/tmp/avelune-converter-ac06-runtime-contracts-20261012/qualification_driver.py`, exit 0. Reçu complet : `qualification-receipt.json`, SHA `97eb98073558a3fb2682685073c46cc913b30fee730298ddd7308402080c083d`, dans le même dossier ; commandes Flutter/MCP, environnements et logs bruts y sont référencés. Le dernier superviseur a observé 75 processus possédés sur deux lancements, sans signal ni survivant. Les PID humains protégés 6272, 82303 et 61161 sont inchangés ; 28620 reste absent. La source, le stage original, les entrées de build suivies et l'ancien bundle Debug sont inchangés ; seule notre copie de carte est éditée.

Les incidents préparatoires restent visibles dans les reçus : premier build refusé avant lancement pour collision du PRODUCT_NAME global ; deuxième lancement arrêté pour corriger la lecture du message de boot brut ; un tap d'automation obsolète après fermeture automatique de la palette, sans mutation, corrigé après nouvelle inspection. Le nettoyage du deuxième lancement a envoyé trois SIGTERM aux seuls descendants ibtoold dont l'identité et l'appartenance étaient attestées. Les trois superviseurs sont terminés sans survivant.

La correction isole le build avec un `XDG_CONFIG_HOME` temporaire et un bundle `com.yoahnl.pokemap.editor.ac06qualification`, sans changer les configurations suivies ni les settings globaux. `--no-pub` évite une résolution Pub, mais le premier build isolé a annoncé un fetch SwiftPM Sparkle en cache : ce build UI n'est pas certifié hors ligne. Les preuves AOT natives hors ligne restent distinctes. Six captures et les reçus locaux, environ 6,4 MiB, sont conservés ; le build isolé ignoré de 1,16 GiB reste disponible pour revue.

## Verdicts et autocritique

Audit/Architecture : PASS borné aux tuiles ordinaires. Implémentation : PASS sur les SHA figés. Tests : PASS, 164 adapters et analyses propres. Build/Validation root : PASS AOT, parcours natif contrôlé et TIL-03 visible. Critique finale indépendante : PASS du composeur/writer, du dernier delta de noms et du parcours Studio ; finding ordre de couches fermé. Gate technique AC-06 acquis ; revue humaine non acquise.

Les modèles natifs et les contrats cibles sont inchangés. Les priorités gameplay, autotiles, événements, catalogues, publication et distribution restent leurs lots dédiés. Les logs locaux temporaires doivent être conservés pour une revue détaillée ; le dépôt garde les commandes, résultats et hashes, sans les volumineuses identités de compilateurs. La taille du composeur et du writer justifie une attention de revue ; aucune extraction sans besoin du lot n'a été effectuée.

Notion : ticket AC-06 `3f7197a7-bfa5-8139-aa70-da74c57612c4` rattaché au domaine Post Bêta existant 14, hors gate bêta ; passage à `TO REVIEW` après commit vérifié, `DONE` réservé à la décision humaine. Le commit du lot porte exactement neuf chemins de code et trois fichiers de preuves ; les 257 chemins étrangers et les 15 fichiers du contrat cible sont préservés. Le SHA final se consulte dans l'historique Git et le ticket, sans autoréférence au hash de ce rapport.

Hygiène Markdown avant commit : la commande par défaut refuse un nouveau document, exit 1 ; `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` passe, exit 0, avec un seul rapport consolidé dans l'emplacement canonique, autorisé par la réalisation des lots du kit. Le contrôle par défaut doit être relancé après commit. Le prochain lot prioritaire est AC-09, dont la dépendance est AC-06 ; les audits AC-07/09 sont uniquement préparatoires. L'objectif global reste ouvert : aucune application finale, conversion de Kanto jouable ou publication n'est revendiquée.
