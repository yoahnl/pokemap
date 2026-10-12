# AC-11 — Assistance IA BYOK bornée

## Résultat et scope

Verdict technique : **PASS borné, prêt pour revue humaine**, avec un échec MCP préexistant explicitement isolé. Statut produit proposé : **TO REVIEW**, jamais DONE sans décision de Yoahn. Base `main` : `549b75273aa4925241b9e46d18be0148df16f15b` (AC-10). Application dans `apps/avelune_converter`. Le commit local du lot est demandé ; son SHA sera la référence Git/Notion après publication locale, sans push.

Un seul fournisseur visuel optionnel, OpenAI Responses, est implémenté. La revue et la conversion offline ne demandent aucune clé. L’IA ne renvoie que des propositions à vérifier : noms, catégories, tags, preuves, incertitudes et regroupements. Les pixels, les géométries, les placements et les mutations natives ne sont pas commandés par le modèle. Les unions utilisent la revue humaine existante.

Les tests AI-01…07 du kit sont couverts. Aucun appel au vrai fournisseur, accès à une vraie clé, upload Kanto ou facturation n’a été effectué. Le critère signé autorise la qualification offline/fake ; un appel réel exige une clé et l’autorisation précise d’envoyer les découpes. Aucun blocage artificiel du lot sur une autorisation absente.

## Gate 0 et audit initial

Le core AC-10 possédait les propositions d’assets, sessions immutables, claims, validation source et approbations exactes. L’ancien VisionPort/validateur de réponse couvrait les IDs, mais ne liait pas une demande au matériau affiché, au compte, à la session et à la sélection vivants. Aucun provider, coffre, ledger privé ou consentement UI réel n’existait.

Décision : contrats purs dans `avelune_converter_core`, IO/provider/cache dans `avelune_converter_adapters`, intégration facultative dans l’app. Aucun ajout au modèle cible PokeMap. Une rupture explicite de la session de revue privée vers1.1 rejette1.0 ; aucune migration/lecture duale pré1.0. Le corpus externe reste read-only ; zéro Ruby source exécuté.

État initial : converter propre après commitAC-10, index vide, 261 chemins hors scope. Qualification dans un nouveau snapshot HEAD549 +29 fichiers owned, avec dépendances locales et lockfile inchangé. Le snapshot AC-10 à84 pins reste une preuve séparée et n’a pas été converti en worktree AC-11.

Risque principal : consentement visuel incomplet ou réponse tardive/hostile qui muterait une session différente. Les guards sont rejoués avant dispatch et au retour, après les await, et la persistance n’accepte pas de secret.

## Implémentation et corrections vérifiées

Le matériau immutable lie source, session, révision, compte, candidat/hash, sourceRect, transformations, PNG/hash, provider/modèle/prompt/schema/options. Une sélection de1–2 candidats peut comporter au maximum8 parties. Les régions dérivent des deux identités candidateId/partId, car part:0 est réutilisé entre candidats. Miroir horizontal avant rotation horaire, sans redimensionnement. SHA, CRC/inflate PNG, dimensions et quotas précèdent le décodage. Les sources indexées sont converties en RGBA8 sans palette avant création d’un raster neuf, qui ne conserve aucune métadonnée PNG.

Le Trousseau est limité au service du bundle Converter et au compte openai. Construction sans lecture ; vérification explicite seulement. Canal/arguments stricts, erreurs fermées, saisie masquée et correction/suggestions/apprentissage IME désactivés. La qualification native utilise un bundle dédié et un secret leurre public supprimé en fin de parcours. SecItem file-based explicite, sandbox maintenue.

L’adapter utilise uniquement `https://api.openai.com/v1/responses`, aucune redirection/tool/action native/URL arbitraire, limites de taille/temps et cancellation. `store=false` n’est pas une promesse universelle de non-rétention distante. Source hash et pixels de chaque crop sont attestés avant lecture du coffre/HTTP. Le ledger borne20 tentatives, reprises comprises, avec au plus1 reprise par demande. Une réservation non remise au transport est libérée si la dernière garde échoue ; une tentative déjà remise conserve un usage inconnu lors d’un timeout/cancel/crash. Le cache exact exclut uniquement le nonce requestId ; un nouveau consentement reste nécessaire et la réponse est revalidée. Révision opaque du compte nouvelle par panneau/vérification : aucune promesse de cache partagé entre redémarrages.

Sans tarif actuel explicite, le coût reste inconnu/null ; aucun0 fictif. Un plafond monétaire strict bloque avant clé/HTTP si le tarif manque ou est périmé. Le verrou est qualifié dans un isolate et entre deux processus, pas cross-isolate. Temp/flush/rename locaux ne promettent pas une durabilité universelle après coupure électrique.

Les RED sont fonctionnels, avec compilation/chargement réussis :

| Défaut reproduit | Correctif minimal et GREEN |
|---|---|
| IDs part:0 communs et promptVersion incompatible | IDs composite contrôlés ; version1 alignée provider ; helper24 + app80 |
| Source PNG au CRC corrompu acceptée | NativePngValidator avant decoder ; helper24 |
| Texte tEXt privé conservé à l’envoi | Raster RGBA neuf + whitelist IHDR/IDAT/IEND transmis ; marqueur absent, pixels exacts |
| Palette RGBA/tRNS interprétée comme indices RGBA | Conversion uint8 sans palette ; alpha0/127 et pixels exacts ; PNG16bits clairement refusé |
| Réservation avant garde comptée sans HTTP | Libération sous verrou avant remise au transport, usage après envoi conservé |
| Écho de clé encodé Unicode dans réponse JSON | Parcours des chaînes décodées, clés et valeurs, avant cache/retour ; couverture guillemet/antislash |
| Catégorie/cible cachées avant application humaine | Libellés affichés, guard hash et bouton désactivé si périmé |
| Codes UI d’erreur différents du service | Codes actuels, message utile401/quota/timeout/refus sans copie du payload |

Les premiers échecs de snapshot liés à package_graph/GeneratedPluginSwiftPackage manquants sont des échecs de setup, distincts des RED produit. `flutter pub get --offline --enforce-lockfile` n’a modifié que le snapshot. Les infos analyzer intermédiaires ont été corrigées mécaniquement puis revérifiées.

## Inventaire complet des fichiers source

Les zones précises et SHA de tous les fichiers figurent dans `index.json` ; les sources et les diffs Git sont canoniques. Les lignes ci-dessous sont les entrées de classes/fonctions, pas des copies de sources.

| Fichier | Zones | Rôle et impact |
|---|---|---|
| `apps/avelune_converter/lib/converter_app.dart` | 1905 lignes ; entrées 19, 75, 101 | DI vault/client ; Resources ; revalidation source et callback exact de session |
| `apps/avelune_converter/macos/Runner/DebugProfile.entitlements` | 16 lignes ; entrées exports / contrat | Accès client réseau du provider optionnel, sandbox conservée |
| `apps/avelune_converter/macos/Runner/MainFlutterWindow.swift` | 92 lignes ; entrées 5 | Canal secret SecItem limité au bundle, arguments stricts, erreurs fermées |
| `apps/avelune_converter/macos/Runner/Release.entitlements` | 12 lignes ; entrées exports / contrat | Accès client réseau du provider optionnel, sandbox conservée |
| `apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_draft_field.dart` | 68 lignes ; entrées 3, 28 | Variante obscureText et désactivation correction/suggestions/apprentissage IME |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | 15 lignes ; entrées exports / contrat | Exports publics vision ciblés |
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | 24 lignes ; entrées exports / contrat | Part public du contrat vision |
| `packages/avelune_converter_core/lib/src/asset_review_session.dart` | 1494 lignes ; entrées 3, 36, 72, 84, 103, 241, 249, 293 | Session privée1.1, propositions persistées/import atomique/application humaine metadata |
| `packages/avelune_converter_core/lib/src/ports.dart` | 26 lignes ; entrées exports / contrat | VisionPort reçoit matériau immutable et consentement exact |
| `apps/avelune_converter/lib/vision_desktop_services.dart` | 133 lignes ; entrées 7, 13, 20, 39, 62, 81, 88 | Client lazy, fichiers source vérifiés, Trousseau sans lecture au démarrage |
| `apps/avelune_converter/lib/vision_panel.dart` | 552 lignes ; entrées 13, 37 | Clé masquée, sélection, aperçu exact, consentement, propositions, coût inconnu |
| `apps/avelune_converter/lib/vision_preview.dart` | 201 lignes ; entrées 7, 14 | SHA/CRC avant decode, crop exact, IDs composites, raster RGBA neuf sans metadata |
| `apps/avelune_converter/test/vision_desktop_services_test.dart` | 76 lignes ; entrées 5 | Tests positifs/négatifs et non-régression |
| `apps/avelune_converter/test/vision_panel_test.dart` | 301 lignes ; entrées 14, 35, 74 | Tests positifs/négatifs et non-régression |
| `apps/avelune_converter/test/vision_preview_test.dart` | 541 lignes ; entrées 10, 119, 156 | Tests positifs/négatifs et non-régression |
| `packages/avelune_converter_adapters/lib/src/vision_assistance_service.dart` | 337 lignes ; entrées 12 | OpenAI Responses borné, gardes live, retries, validation, écho secret rejeté |
| `packages/avelune_converter_adapters/lib/src/vision_crop_verifier.dart` | 103 lignes ; entrées 11 | SHA source et comparaison RGBA transformée ; whitelist PNG envoyé |
| `packages/avelune_converter_adapters/lib/src/vision_http_transport.dart` | 111 lignes ; entrées 10, 25 | Endpoint HTTPS fixe, aucune redirection, timeout/quotas/cancellation |
| `packages/avelune_converter_adapters/lib/src/vision_local_store.dart` | 486 lignes ; entrées 12 | Ledger privé, cache exact, réservations et verrou, limites durables |
| `packages/avelune_converter_adapters/lib/src/vision_runtime.dart` | 129 lignes ; entrées 36 | Helpers bornés et vérification récursive chaînes décodées |
| `packages/avelune_converter_adapters/lib/src/vision_support.dart` | 96 lignes ; entrées 9, 25, 47, 63, 70, 84, 91 | Vault, politique, tarifs explicites et usage connu/inconnu |
| `packages/avelune_converter_adapters/test/support/vision_ledger_worker.dart` | 19 lignes ; entrées 7 | Support original de fixture/worker borné |
| `packages/avelune_converter_adapters/test/support/vision_test_fixture.dart` | 176 lignes ; entrées 20, 132, 143, 161 | Support original de fixture/worker borné |
| `packages/avelune_converter_adapters/test/vision_assistance_service_test.dart` | 396 lignes ; entrées 10, 388 | Tests positifs/négatifs et non-régression |
| `packages/avelune_converter_adapters/test/vision_crop_verifier_test.dart` | 40 lignes ; entrées 7 | Tests positifs/négatifs et non-régression |
| `packages/avelune_converter_adapters/test/vision_http_transport_test.dart` | 186 lignes ; entrées 8, 114, 143, 163, 172 | Tests positifs/négatifs et non-régression |
| `packages/avelune_converter_adapters/test/vision_local_store_test.dart` | 219 lignes ; entrées 10 | Tests positifs/négatifs et non-régression |
| `packages/avelune_converter_core/lib/src/vision_assistance.dart` | 599 lignes ; entrées 3, 21, 157, 241, 293, 409, 421, 436, 475, 495 | Contrats crops/matériau/consentement/live/propositions et fake |
| `packages/avelune_converter_core/test/vision_assistance_test.dart` | 506 lignes ; entrées 13, 25, 49, 60, 75, 113 | Tests positifs/négatifs et non-régression |

Le pack consolide ce document, `commands.json`, `index.json`, trois captures natives et cinq JSON de qualification. Aucune entrée dev de qualification, clé, cache, source Kanto ou dépendance générée n’est ajoutée au produit.

## Commandes et résultats exacts

Les argv/cwd, SHA des reçus/logs, PID, signaux et pins avant/après sont conservés dans `commands.json`. Tests depuis le package concerné du snapshot isolé :

| Commande | Résultat |
|---|---|
| Core `dart test --reporter expanded` | `00:15 +632: All tests passed!`, exit0,17.602s |
| Adapters `dart test --reporter expanded` | `00:52 +424 ~8: All tests passed!`, exit0,55.519s ;8 skips existants conservés |
| App `flutter test --no-pub --reporter expanded --concurrency 1` | `01:04 +80: All tests passed!`, exit0,68.364s |
| Preview/panel/vault ciblés | `+32: All tests passed!`, exit0,8.215s |
| Panel/vault après corrections de lint | `+8: All tests passed!`, exit0,7.963s |
| Core `dart analyze` | `No issues found!`, exit0,1.233s |
| Adapters `dart analyze` | `No issues found!`, exit0,3.497s |
| App `flutter analyze --no-pub` | `No issues found! (ran in 6.2s)`, exit0,7.441s |
| Production `flutter build macos --debug --no-pub -t lib/main.dart` | `✓ Built .../Avelune Converter.app`, exit0,32.696s |
| MCP `npm run check` puis `npm run build` | exit0,1.304s et1.287s |
| Kanto API/JSONL/MCP `node transports_read.mjs config.json` | exit0,26.276s ;36 queries, records identiques, source witnesses2 exacts/inchangés |
| MCP config/protocol tests |7/8, exit1 ; échec identique sur baseline AC-10, hors modification AC-11 |
| `bash tools/scripts/check_markdown_hygiene.sh` (budget1 pour le pack signé) | `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.`, exit0,3.034s |
| `git diff --check -- <40 chemins owned>` ; relecture des pins et preuves | exit0 ;29 sources host=snapshot,84 pins AC-10 inchangés,8 artefacts de preuve exacts |
| `git diff --check` global | exit2 ;21 blancs terminaux dans smart_tile.freezed.dart hors scope, conservés |

Le build produit l’entrée réelle `lib/main.dart`, bundle `com.yoahnl.avelune.converter`, exécutableSHA `0dd515b3e8b234962d8578e19a7a0df7dc165e5140876ec7d01bb8a57752517c`. Copie préservée : `/private/tmp/avelune-converter-ac11-production-app-ashe7qvz/Avelune Converter.app`. Debug macOS, aucune distribution/release signée annoncée. Le log Xcode conserve un diagnostic «exit code0 but produced no further output» et le warning de dépréciation `kSecUseAuthenticationUIFail`; le bundle est construit et la qualification native distincte fonctionne.

Tests/analyses/transport final : zéro survivant confirmé et aucun signal. Build production : deux ibtoold descendants92399/92400 vérifiés puis TERM, zéro survivant. Qualification Keychain : trois ibtoold confirmés74913/74914/75304 TERM. Aucun signal vers35037/6272/82303/61161/28620, aucun kill global, aucun SIGKILL. Un processus Flutter d’une autre session est préservé.

## Fenêtre macOS et persistance réelles

Bundle QA dédié `com.yoahnl.avelune.converter.ac11uiqualification`, vrai ConverterApp avec fixture originale contrôlée, workflow/scan/source verification/store réels ; seulement vault/provider simulés. Entrée TEMP jamais livrée. Container unique `ac11-native-ui-owned-daXWYD`.

Au démarrage et après analyse/revue : zéro lecture de clé, zéro factory/HTTP. Une vérification explicite de la clé leurre précède la sélection des deux candidats petits. L’aperçu montre quatre crops32×32,492octetsPNG, metadata/IDs/transforms/hashes et coût inconnu. Send est désactivé avant consentement. Le contrôle visuel est activé, puis une seule demande fake reçoit les mêmes hashes : matériau=consentement `aee5b66afc0d0559c5a3dd909d92367930b0feffad2c3b134faf7a4ad50e2308`, quatre crop hashes identiques à l’affichage.

Enregistrement revision2 : deux propositions pending ; tous les candidates hashes et claims initiaux inchangés. Application humaine d’un seul nom/catégorie puis enregistrement revision3 : candidat e00f69… nommé «Arbre suggéré en qualification», nature, needsReview et approvedRevision null ; une proposition demeure pending. Les quatre autres candidats, sources, pixels, parts, anchors et claims sont inchangés. SessionSHA `333fcee7f108cd498ad8e7cbd041bc550ca2b6211b875b3aad70202a0ad191c9`. Secret leurre absent. Zéro fournisseur réel/upload ; source fixture inchangée à tous les probes.

Capture `native_ui_consent.png` : aperçu avant consentement ; `native_ui_pending.png` : catégorie/cible/proposition avant application humaine. `native_keychain.png` : six checks natifs vrais (vide/create/read/update/delete +2 refusargs). Keychain réellement supprimé, aucun credential retenu. Reçu UI runner92917 exit0/565.649s ; application93309 quittée au menu natif, PID absent ; Marionette déconnecté, aucun survivant.

Observabilité : Marionette get_logs retourne Server error. Le log du runner est conservé et montre une erreur de scroll sur un ID incorrect utilisé par l’agent, corrigée avec l’ID observé. Un tap sur le centre du libellé consentement n’activait pas le switch ; l’action sur le switch visible confirme l’état et active Send. Aucun faux «absence d’erreurs runtime» n’est déduit de l’outil logs indisponible. Le timeout CUA après Quit est remplacé comme preuve par le PID disparu et l’exit0 runner. Les captures ont été sauvegardées par blocs après un refus de taille de payload Node ; aucune édition d’image.

## Parité native et limite MCP préexistante

Ce lot modifie des drafts privés Converter et un provider, sans nouveau comportement d’authoring PokeMap ni nouveau schéma natif. Exposition de propositions IA/import privé via transports map_authoring : N/A, car il s’agit d’une session source privée et non d’un projet PokeMap. Les contrats publics converter_core/ports portent les mêmes guards pour UI/fake/service. Aucune sauvegarde JSON brute n’est annoncée comme une action native.

Le writer et ses sept actions canoniques natives sont inchangés ; les suites adapters/app incluent leur non-régression. Le MCP est reconstruit et le catalogue vivant vérifié. Nouvelle lecture API directe, JSONL et MCP des deux copies Route9 : projet/carte/atlas/asset/element/category, records/révisions identiques, sourcePNG identiques, strict loader sans diagnostics. Diff exact original/modifié : nom et cellule3285 de layer1(44→0), aucune autre différence. Logiciel108pins vérifié, MCPbinSHA `ea8d735de103a8c0fb7fe182ad2ffa83333082dfd673ad8d385999651e565ffc`.

Le test protocol_compatibility attend une ancienne liste de15tools, alors que le serveur expose aussi project_create_preview et project_create(17). Même7pass/1fail reproduit dans le snapshot AC-10 ; index.ts/server.ts/config.test/protocol.test identiques au Git549. Les appels réels describe/open/query/validate/close de la qualification Kanto passent. Le test n’est ni modifié ni ignoré et aucune suite MCP globale verte n’est revendiquée. Cet échec hors scope est tracé ici, sans nouveau ticket beta ni dépendance beta.

## Verdict des passes et autocritique

| Passe | Verdict |
|---|---|
| Audit/Architecture | Frontières core/adapters/app cohérentes, aucun modèle cible détourné |
| Core/session/contrats |39tests nouveaux et core632PASS ; contexte live/import atomique/humanmetadata |
| Adapters implémentation/tests | Réservation, secret échappé, PNG metadata reproduits/corrigés ; adapters424~8PASS |
| Preview pixels | CRC, tEXt, palette/tRNS, 16bits qualifiés ;24tests helperPASS |
| Build/validation root | App80, analyses, mainbuild et vrai parcours natif PASS borné |
| Critique indépendante | Trois P2 et messages corrigés ; aucun P1/P2 concret restant dans le périmètre relu |

Cette livraison prouve un provider implémenté et facultatif avec ses guards, pas sa qualité de reconnaissance ou le compte distant. Une fixture contrôlée ne qualifie pas le rendu de tout Kanto. Le debug bundle et le coffre leurre ne prouvent pas une release signée ni un cycle de compte réel. Le warning SecItem et le test MCP préexistant restent visibles. Le cache ne promet pas une reprise stable d’identité compte entre redémarrages. Les PNG16bits sont rejetés plutôt que dégradés silencieusement.

Le résultat utilisateur Route9 reste accessible dans `Documents/Avelune Converter Studies/Kanto Route 9 - ouverture Studio 20261012`, avec ouverture/modification/save/fresh-reopen Studio déjà acquises. AC-11 n’ajoute pas de capacité gameplay. Prochaine étape autorisée : AC-12, qualification des passages/priorités, puis AC-13/14 événements/données Essentials et AC-15/16 corpus/publication. Kanto complet et jouable reste non certifié.

## État Git et traçabilité

29fichiers source owned et un pack consolidé, 261chemins étrangers maintenus hors staging. Aucun push/rebase/changement de branche. Le ticket AC-11 appartient au grand domaine Post Bêta Monde/exploration/narration existant, Gatebêta false ; statut TO REVIEW après preuves, DONE réservé à Yoahn. SHA du commit local et statut index/postcommit seront synchronisés dans le ticket. Les résultats de l’hygiène Markdown et de diff--check sont indexés avant commit.
