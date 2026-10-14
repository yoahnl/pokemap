# AC-16 — Distribution du convertisseur V1

État courant au 15 octobre 2026, Europe/Paris : DOING / PARTIAL. La distribution locale issue de eec7ae856 est reconstruite, extraite et vérifiée hors ligne, y compris la relecture du projet Kanto livré de trois cartes. REL-01 interface de release et REL-03 interface du plan courant restent ouverts. Les sections datées du 13 et du 14 octobre conservent leurs preuves historiques ; elles ne certifient pas rétroactivement les binaires du 15 octobre. Ni V1 complète ni Kanto entièrement jouable déclarés.

## Résultat et périmètre — qualification historique du 13 octobre

L’application indépendante se trouve dans apps/avelune_converter. Son design system est extrait dans un package Flutter partagé, sans importer Studio, le runtime ou le moteur de combat. La CLI compilée et l’interface utilisent ConverterWorkflow, la même recette fermée et une recomposition fraîche avant une nouvelle approbation. Aucune approbation persistée ne devient une autorisation automatique. Le convertisseur reste déterministe et hors ligne ; le combat conserve l’autorité Avelune.

Le ZIP réel contient la release macOS, une CLI arm64, une fixture synthétique originale, les notices effectivement produites par le build et un README.txt de qualification privée. Après extraction dans un nouveau dossier, les 38 fichiers, 35 répertoires et neuf liens internes relatifs correspondent exactement à l’inventaire. Le binaire extrait réalise plan→convert→verify sur les deux cartes originales avec un PATH excluant les SDK Dart/Flutter, sans modifier la source et sans écrire pendant verify. L’application macOS contient arm64 et x86_64 ; l’exécution a été qualifiée sur la machine arm64 uniquement.

La qualification UI réelle du 13 octobre utilise une application native debug, la fixture originale et le même fichier de recette que la CLI. La sortie canonique de 20 fichiers est identique après vérification stricte. La release de cette qualification historique a été construite et lancée, mais ScreenCaptureKit -3811 bloque sa capture/son contrôle CUA : la capture debug ne remplace pas une capture de cette release. La release du 15 octobre n'a pas encore été lancée dans une fenêtre.

La lacune de bibliothèque signalée par Yoahn est également corrigée au niveau des propositions perdues : Route 9 donne désormais 69 propositions de tuiles effectivement utilisées, 8 167 placements liés à leur source, et aucun diagnostic de proposition. Cela reste une base de revue, pas une bibliothèque terminée de pinceaux de chemin et d’arbres assemblés. Les pixels d’origine sont conservés. Aucun média Pokémon, projet Kanto ou secret n’entre dans le ZIP logiciel ou dans ce commit.

## Audit initial, décisions et Gate 0

Sources relues : codex_rule.md, skills/README.md, skills/verification-before-completion/SKILL.md, skills/using-pokemap-mcp/SKILL.md, skill test-flutter-desktop, kit AC-16 et tests REL-01/02/03, rapport AC-15 et frontières du workflow/writer natif. Les consignes du kit sont des spécifications de travail ; les décisions humaines sur apps/avelune_converter, commits locaux, source Kanto, absence d’IA obligatoire et combat Avelune priment. La demande directe de ne pas ajouter de commentaires prime sur la règle Codex contradictoire.

L’audit de la release AC-14 révélait un couplage indésirable au design system public de Studio : 306 fichiers runtime, 15 fichiers Studio dont quatre médias Pokémon, cinq fichiers player_ui et un render_3d étaient embarqués. Les 20 implémentations du design system, 1 283 lignes Flutter, formaient une frontière extractible. Elles sont déplacées sans réécriture des widgets ; les chemins Studio deviennent des façades d’export et un test vérifie leur identité de types. Le graphe Converter final comporte 85 packages ; 52 dépendances liées notamment au runtime/battle/Flame/audio/vidéo/gamepads disparaissent.

La CLI précédente proposait seulement scan. Appeler directement le writer pour la compléter aurait contourné la préparation, les bindings, la vérification de source et l’approbation. La recette enregistre tous les paramètres et hashes nécessaires, puis restoreStudyPlanRecipe rescane/recompose par le workflow public et refuse tout écart. Le contrat accepte seulement le format/version courant, jusqu’à 4 MiB et 250 000 nœuds. Aucun reader legacy, changement du modèle natif ou exécution Ruby n’a été ajouté.

Le study AC-15 conservait quatre atlas et sept éléments techniques : quatre fragments d’occlusion et trois masques invisibles de collision. Le proposer associait tout le sol connecté de Route 9 à une composante de 4 392 cases / 8 167 parts et dépassait son quota 4 096. Le correctif produit une proposition par tuile statique utilisée, carte et couche, avec les claims exacts ; il ne relève pas le quota, ne tronque pas les placements et n’injecte pas les autres morceaux de l’atlas comme s’ils étaient présents sur la carte. L’API de composantes connectées conserve son rôle ; le workflow utilise usedStaticTiles. La revue/manipulation humaine existante permet ensuite les assemblages.

Une lenteur réelle du corpus a également révélé le recalcul de canonicalHash pour chaque validation de claim. ConverterDocument possède déjà une copie JSON profondément gelée. Le hash est donc mémorisé une seule fois par document immuable ; les contrôles de provenance sont conservés. Quatre tests prouvent l’identité du hash, le gel profond avant/après calcul, la distinction d’une nouvelle copie modifiée et le rejet d’un claim contre une source modifiée. Les durées observées sur Kanto ne constituent pas un benchmark isolé : des scans complets et d’autres travaux concurrents restent dans le temps total.

État initial : main, index vide, base fb654a223c7996f3caf3a0562574acd1ffa16940. Au gel initial AC-16, 39 chemins étrangers étaient déjà modifiés/non suivis ; spatial_scene_view.dart avait changé dans une autre session depuis le contrôle AC-15. D’autres travaux étrangers ont continué pendant le lot : 80 chemins étrangers au contrôle prérapport du 13 octobre. Aucun n’est restauré, stagé ou nettoyé. Le reçu de clôture donne le dernier état et compare les octets immédiatement avant/après le commit.

## Contrats et implémentation

ConverterStudyPlanRecipe conserve les paramètres, source snapshot, observations du profil, sélection de cartes, choix d’assets, artefacts, draft et plan approuvé. Les champs inconnus, formats obsolètes, hashes incohérents, recettes manipulées même avec un hash global recalculé, sources déplacées/modifiées et destinations occupées sont refusés. SourceLocator.fromJson réutilise le validateur strict à sept champs du contrat existant.

LocalStudyPlanStore lit et crée exclusivement un nouveau fichier régulier hors source et hors destination canonique, sans suivre un lien, remplacer un fichier ou masquer une erreur. Une preuve AOT a révélé un appel openat Darwin incorrect : le mode était déclaré comme un quatrième argument fixe alors qu’il est variadique. Le fichier résultant était illisible, mode 0100240 / EACCES 13. La signature FFI utilise maintenant VarArgs<(Uint32,)> ; les plans réels sont créés en 0600. Aucun chmod correctif ni contournement des contrôles n’a été utilisé.

Deux findings P2 de la critique ont été reproduits puis corrigés : alias /tmp contre /private/tmp pouvant laisser enregistrer la recette dans la destination, et mutation/annulation pendant la dernière relecture du verifier. Le store compare les parents canoniques. NativeStudyVerifier réalise sa dernière relecture avant ses derniers contrôles d’identité et d’annulation. Les cas RED correspondants restent dans les reçus, et les tests ciblés sont verts.

L’interface propose Enregistrer le plan et Charger un plan avec les sélecteurs natifs. Charger restaure un nouveau workflow, conserve les paramètres exacts et demande une nouvelle approbation visible. Les erreurs sont françaises et typées. La confirmation réussie retire le message d’approbation périmée. Le harnais dev/macOS Marionette capture l’état réel du workflow dans un conteneur de QA privé ; il n’intègre pas de faux writer et ne change pas l’entrée de production.

La CLI propose scan, plan, convert et verify, avec --offline obligatoire pour les opérations et --approve-plan égal au SHA exact lors de convert. Les codes 0/2/3/4/5/6/7/130 distinguent résultat d’étude, arguments/échecs et annulation ; SIGINT demande une annulation coopérative et conserve les chemins de récupération. Le code zéro et verified ne certifient jamais un jeu complet.

NativeStudyVerifier relit le projet natif et contrôle son inventaire exact, ses assets, receipts, mutations, blobs, révisions et journal. Le comparateur partagé avec PUB-04 contrôle également la chaîne des mutations et reconstruit le bootstrap à partir du beforeBlob du premier changement project.create. Seuls dates/chemins de staging/identités de transport sont normalisés selon un contrat fermé ; les hashes sémantiques ne sont pas ignorés. Les six sabotages PUB-04 restent testés, auxquels s’ajoutent préimage manquante, révision altérée, ordre inversé, attentes inconnues/périmées et racines invalides.

## REL-03 — mêmes recette et résultat par CLI et interface

Racine de la qualification native : /Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16 original 20261012. Les sept fichiers de la fixture sont originaux et byte-identical à ceux du générateur. La CLI publie d’abord dans output/native-study, puis cette sortie est conservée intacte sous output/native-study-cli-preserved pour libérer la destination demandée par la même recette.

Le fichier approved-plan.json est identique pour les deux transports. recipeHash f103da06e0858aee23acb62211bc3bbec31388377de51075525991ab54b29d4b ; approvedPlanHash 590c686e11edd17045d4ab1413a8a76b047c51e5228f2ad7fb31d9938672e51b ; nativeDraftHash def2553a16f53fe10d201bccee34cb143c0a31868055bc84ad16846d3820cd71. Les trois IDs d’opération attendus sont capturés depuis une nouvelle recomposition avant publication UI, dans native-expectations.json, et ne sont pas déduits des sorties comparées.

Dans l’application native debug PID 79392 : Chargement du plan→nouvelle préparation et approval null→case d’approbation cochée→confirmation→publication réelle et vérification. La sortie UI et la CLI portent la révision sha256:3c0bcc7cc6ee4538d8e1ccac19025b04f34e6b6484efd4ddc2cb098e85f71648. Le lancement Flutter rapporte un échec de foreground open=1 ; le rendu natif et les actions ont néanmoins été observés par Marionette. La fenêtre a été fermée par q ; aucun descendant possédé ne subsiste.

Captures réelles : /private/tmp/avelune-ac16-root-original-20261012/evidence/converter-native-initial.png et converter-native-published.png. La capture publiée a SHA 8b6a10a92f9b0ea685f64b5228d8ed57a87682f9e3f5042924627d2a21d54243 ; trace converter-native-journey.json. Cette observation précède uniquement les retouches de label/message et le cache de hash, testés ensuite sur les pins finaux ; elle n’est pas attribuée rétroactivement au binaire final de release.

Le replay du comparateur sur les pins finaux confirme 20 fichiers, verified true de chaque côté, equal true et fingerprint sha256:2f766c91e52bb4aebc94aaedb13c4f29eac4cdd9e218dc54e5fad75b9d6b6213. proofScope=closedNativeOutputEquality et transportsObservedByComparator=false : les traces CLI/UI séparées prouvent les transports ; le comparateur seul ne les observe pas. Résultat REL-03 : PASS.

## REL-01/02 — artefact local et installation réelle

Distribution finale : /Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC16-local-20261013. Archive AveluneConverter-local-validation.zip, 37 076 890 octets, SHA 8bf599f6b713a45be11e9a1b30f297743d422c811262b3e89768e44379a517aa. inventory.json SHA 20b41dc415226dd806ce58f17a0764a133693319ce5c80362198c980278ec8e1. Payload : 38 fichiers réguliers, 35 répertoires, neuf liens relatifs internes, une notice Flutter décompressée de la vraie NOTICES.Z. Aucune acknowledgement CocoaPods n’existe dans ce build utilisant Swift Package Manager ; le packager gère les sidecars réels quand ils existent, sans en fabriquer.

Le packager refuse secrets par noms/extensions, médias Pokémon/PSDK, ressources Studio/runtime/player/Flame, fichiers spéciaux, liens sortants/absolus ou revenant après une sortie lexicale, CLI non exécutable, fixture inconnue/incomplète et notices malformées ou dépassant la borne. Il conserve les modes et liens des frameworks, compare les entrées avant/après copie et archivage, et crée exclusivement une destination neuve. Les tests de packaging couvrent 22 cas. Les petits stubs de ces tests sont des entrées de test du packager ; la fixture effectivement distribuée est celle produite par le générateur Dart et convertie réellement.

Extraction finale : /private/tmp/avelune-ac16-final-install-20261013/AveluneConverter-local-validation. L’inventaire extrait, modes et liens inclus, correspond exactement. Sa CLI exécute --help, plan sur cartes 1 et 8, convert avec le hash 58ac113707c5a1b7c362393805d43666555780f9a7a539e3119cce7d331b917b, puis verify. Projet final : deux cartes, un atlas ; révision sha256:e97145a9bc0a6d6a32bc2e4215460f6b12b4c421a7aaba219f544b0c959a943c ; sourceUnchanged et verifyReadOnly true ; playableCertified false. Aucun SDK source ou appel réseau requis à l’exécution de ce binaire extrait.

REL-02 : PASS pour cette archive privée et son inventaire. Aucun grant de licence global du dépôt n’est inventé. L’archive n’est ni notarized ni publiée ; elle ne constitue pas une autorisation de redistribution publique. Le corpus Kanto est une entrée externe autorisée par Yoahn, jamais une dépendance livrée.

REL-01 : build propre, artefact extrait, exécution CLI complète et observation UI native debug PASS ; capture/contrôle de la release PARTIAL (ScreenCaptureKit -3811). Aucun réglage macOS de sécurité ou permission n’a été modifié pour contourner ce blocage.

## Route 9, ressources et limites de Kanto

Source read-only : /Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto. Snapshot complet inchangé 5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de ; 383 cartes disponibles, sélection 98 uniquement. Le replay final scan→prepare→approve→write→verify→publish termine exit0 en 553.500s. Il produit 69 candidats needsReview/unclassified, liés à 8 167 placements exacts, aucun diagnostic de proposition, sourceUnchanged true, strictNativeReadPassed true et sourceScriptsExecuted/aiCalls zéro.

Révision publiée : sha256:64b185150e8057db66ab8b30d163305924d0df788e6c98bd0bf47a958fcbd054 ; draft 02697375d547605a11531c5bb235dae5d457101e0644a5d78a8a7ddcea63c43f. Route 9 garde 72×61, cinq couches, 315 décors placés et huit clips joueur ; nativeMapHash 17e9afc98e9f3c1cf22240970ed413e4c0a8033527cb865fae95a6022496077e. Les 536 transitions source non qualifiées restent fermées. Les 16 événements restent quarantinés, hors certification gameplay. Le spawn (35,22) est une prévisualisation, pas le départ source certifié. L’autorité de combat demeure Avelune.

Sortie et preuve conservées byte-identical dans /Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC16 ressources 20261013 (738 fichiers). Le binaire distribué vérifie la copie native en lecture seule, une carte et 59 assets, révision inchangée. Le premier contrôle a refusé une identité d’asset modifiée pendant la lecture (exit5/4.143s) ; la comparaison de tous les octets de la copie avec l’original n’a montré aucune différence. Une nouvelle vérification indépendante passe en 2.881s, sans changement de code/fichier ni assouplissement du contrôle. L’identité du port inclut taille, mtime et ctime ; la cause de cette variation transitoire de métadonnées n’est pas établie. Le refus initial est conservé comme limite observée, pas effacé. Le projet modifié, sauvegardé et rouvert réellement dans Studio au lot AC-15 demeure dans Kanto Route 9 - AC15 publié 20261012/Projet modifié dans Studio ; aucun de ses fichiers n’est remplacé par ce lot. La copie AC-16 a une preuve de lecture native stricte, pas une nouvelle preuve d’édition/reouverture dans Studio.

Les chemins existent en pixels dans l’atlas FRLG_Outside City 256×16192, notamment la grille de neuf tuiles 481/482/483, 489/490/491, 497/498/499. Les propositions ne créent pas encore un ProjectSmartTilePreset avec contrat cardinal/blob complet et parcours peindre→save→reopen qualifié. palette.upsert existe, mais une palette JSON invisible dans Studio ne suffirait pas à prouver un pinceau produit. La bibliothèque actuelle du study reste composée des sept éléments techniques tant qu’aucune revue n’approuve de ressources supplémentaires.

Un arbre isolé de l’atlas couvre 64×96, x128/y1664 : 804/805, 812/813 et 820/821. Les deux tuiles inférieures ne sont pas utilisées sur Route 9 ; elles ne sont pas ajoutées automatiquement à ses claims. D’autres sommets de forêt ont d’autres bases. L’assemblage doit préserver pixels, pivots, collisions et profondeur, sans prétendre qu’une composante alpha opaque identifie un arbre entier. Une IA facultative pourra suggérer reconnaissance et noms avec consentement, mais l’import et la recomposition n’en dépendent pas. Bibliothèque chemins/arbres : PARTIAL. KAN-03, départ/dialogue/warp/état/save en jeu : non certifié.

## Qualification, tests, analyses et incidents conservés

Snapshot qualifié : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository. Il provient de git archive de la base avec les seuls fichiers de ce lot, hors 39 puis 80 travaux étrangers. Les configurations locales ont été réécrites uniquement dans ce checkout temporaire. Les pins des 88 fichiers de code/manifestes/tests sont byte-identical au host après les derniers changements ; le rapport est le seul Markdown créé.

Les suites finales core/adapters/app donnent respectivement 710, 656 et 84 PASS, sans échec ; elles ne sont pas additionnées aux reruns précédents. Les trois analyses finales sont sans issue. Le packaging donne 22 PASS. Les tests CLI gardent leurs skips explicitement liés aux corpus optionnels/plateforme. Les fixtures et les corps de test malformés, annulation, TOCTOU, quotas, reprise et exactitude native demeurent actifs.

Le superviseur enregistre PID runner/descendants, UID, date de démarrage et commande, puis ne nettoie que ses survivants dont l’identité est reconfirmée. Tous les derniers runs finaux ont zéro survivant et PIDs protégés inchangés. Aucun kill par nom, ancienneté ou recherche globale ; la consigne humaine de laisser les PID préexistants tranquilles prime. Les instances release ouvertes par cette tâche sont laissées intactes après la défaillance de contrôle CUA.

Incidents RED préservés : signature FFI openat (plan illisible, deux essais UI échoués puis correction réelle) ; alias canonique du store et mutation/annulation finale du verifier (tests RED puis GREEN) ; première suite adapters concurrente, 649 PASS/1 FAIL par timeout 30s de la fixture à 3 321 répétitions, puis replay complet à concurrency=2 et dernier replay 656 PASS ; premier scan Kanto incomplet exit2/30.936s, cause non établie, suivi de deux scans complets, avec conservation des snapshots en erreur améliorée ; deux infos d’analyse sur imports relatifs dev, corrigées ; premier packaging refusé parce que son parent de sortie n’existait pas, parent privé créé puis nouveau run validé. Aucun test n’a été supprimé pour transformer ces échecs en succès.

Deux runs de parité MCP ont échoué worker254 dans le snapshot : pub get --offline avait résolu image4.11.0 avec archive4.0.9, incompatibles pour decodeLazy. map_authoring/pubspec.lock est ignoré et absent de git archive. Le lock réel du host, image4.9.2, est copié seulement dans le snapshot, suivi de pub get --offline --enforce-lockfile. Aucun lock/configuration du host n’est changé. Le build/check tools/pokemap_mcp puis deux tests live de catalogue/transport passent sur ce contexte corrigé.

Parité MCP : aucune nouvelle commande d’authoring cible n’est créée. Le workflow utilise map_authoring pour les mêmes opérations natives ; le mécanisme de recette/CLI, la proposition locale et l’extraction de widgets ne changent pas les modèles cibles. La preuve native/direct API et la comparaison JSONL des mutations existent dans les tests. Le catalog pokemap_describe live et les actions pertinentes ont été vérifiés dans une instance MCP privée avec racine étroite. Cette preuve ne vaut pas qualification de toutes les sessions MCP globales ni de la bibliothèque SmartTile encore absente.

Le contrôle global git diff --check relève des espaces de fin de ligne dans map_data.freezed.dart et map_entity_payloads.freezed.dart, fichiers générés modifiés par une autre session. Ces chemins sont étrangers et laissés intacts. Le contrôle scoped sur les 89 chemins du lot passe. L’hygiène Markdown passe : un seul nouveau fichier, en emplacement canonique, avec la borne explicitement autorisée par le livrable AC-16.

## Verdicts des agents et passes

| Passe | Responsabilité et preuve | Verdict |
| --- | --- | --- |
| Audit / Architecture | Frontière design system, recette exacte, suppression des dépendances de moteur ; audit initial root et ac12_native_mapping. | PASS pour le périmètre local ; les limites de V1 sont identifiées. |
| Implémentation | ac12_semantics : workflow/recipe/store/verifier/CLI, erreurs et reprise ; ac12_validation_design : usedStaticTiles, packaging et cache immuable ; extraction par ac12_native_mapping. | PASS, tous les pins possédés correspondent au snapshot final. |
| Tests | RED/GREEN des stores/verifier/hash cache, fixtures et attaques de normalisation ; suites finales root 710/656/84, packaging22. | PASS ; skips CLI et corpus externe documentés. |
| Build / Validation | Build70.0MB, CLI AOT, ZIP extrait, convert/verify réel, Kanto final et comparaison CLI/UI fermée. | PASS artefacts/CLI/REL03 ; REL01 visuel release PARTIAL. |
| Critique finale | ac12_native_mapping, passe séparée de lecture seule du 13 octobre, deux P2 corrigés, hashes finaux/receipts/archive/graphe relus, aucune nouvelle relance. | Aucun nouveau blocker P1/P2 ; TO REVIEW/PARTIAL avec KAN03 et bibliothèque métier non certifiés. |

## Auto-critique et clôture technique

L’extraction structurelle touche de nombreux petits fichiers, mais conserve les implémentations verbatim et prouve l’identité des imports Studio. La CLI ne contourne pas le workflow ; son installation réelle ferme le risque FFI que les seuls tests VM n’avaient pas détecté. La comparaison exige des attentes capturées avant publication et vérifie les métadonnées ; elle n’est pas une comparaison visuelle ou une preuve de gameplay.

Le point faible produit demeure la bibliothèque : exposer 69 tuiles d’étude évite la perte silencieuse, mais ne fournit pas à Yoahn un pinceau de route ou un arbre entier prêt à poser. Les prochaines corrections doivent qualifier les ressources natives correspondantes et leur usage dans Studio, à partir des pixels d’origine. Les événements et le parcours Kanto en jeu restent des critères distincts. Ces limites ne sont ni masquées par les tests verts ni transférées au moteur de combat.

Correction du périmètre Git : l’inventaire initial avait classé à tort packages/map_render_3d/test/spatial_surface_preview_picking_test.dart, arrivé d’une autre session après le contrôle AC-15. Le premier commit AC-16, 42e6f7c1c43336f810335939483310b8581a5485, l’a donc suivi par erreur. Une correction locale séparée retire uniquement son suivi, avec git rm --cached ; son fichier et ses octets sont conservés, et la ligne erronée de cet inventaire est supprimée. Aucune réécriture/amend du commit n’est faite. Le diff net final contre la base porte uniquement les 89 chemins du lot (88 code/manifestes/tests et ce rapport). Ce test n’était pas dans le graphe Converter, les suites exécutées ou le payload distribué. Cette erreur d’inventaire est conservée explicitement dans la clôture.

Le commit du lot doit contenir uniquement les chemins de l’inventaire ci-dessous et ce rapport. Aucun push, rebase, amend, changement de branche ou nettoyage étranger. Le reçu /private/tmp/avelune-ac16-root-close-20261013.json consigne le SHA local final, l’index vide et les hashes étrangers immédiatement avant/après. Le ticket existant AC-16 dans le seul grand domaine Post Bêta Monde & narration est porté à TO REVIEW/PARTIAL avec ce SHA et ces preuves, jamais DONE. Gate bêta reste false. Le worktree reste sale du fait des travaux étrangers ; cette saleté ne constitue pas un échec caché du lot.

## Commandes exactes et résultats

Les tableaux et blocs suivants reproduisent les commandes enregistrées par les superviseurs, avec cwd et durées. Les pins/logs/reçus complets demeurent les preuves techniques ; les résultats des tests de packages différents ne se substituent pas aux contrôles UI et gameplay.

Les suites core/adapters/app utilisent les pins finaux. Les tests adapters/app ont les trois variables AVELUNE_AC12_SOURCE_SCRIPTS, AVELUNE_AC13_SOURCE_SCRIPTS et AVELUNE_AUTOTILE_SCRIPTS_PATH pointant sur Data/Scripts.rxdata du corpus Kanto ci-dessus, en lecture seule. CLI : deux corpus optionnels non configurés et un test non-macOS sont SKIP, sans assimilation à des PASS. Les preuves Studio/design system précèdent le cache du core Converter qui ne les modifie pas.

### Core final, 710 PASS

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/packages/avelune_converter_core

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test
```

Exit 0 ; 22.074 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-core-final-20261012-01.json.

### Core analyse, aucune issue

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/packages/avelune_converter_core

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze
```

Exit 0 ; 2.649 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-core-analyze-final-20261012-01.json.

### Adapters final, 656 PASS

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test --concurrency=2
```

Exit 0 ; 296.392 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-adapters-cache-final-20261012-01.json.

### Adapters analyse, aucune issue

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze
```

Exit 0 ; 15.319 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-adapters-analyze-cache-20261012-01.json.

### Converter final, 84 PASS

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter test
```

Exit 0 ; 49.716 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-app-cache-final-20261012-01.json.

### Converter analyse, aucune issue

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter analyze
```

Exit 0 ; 21.793 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-app-analyze-cache-20261012-01.json.

### CLI final, 28 PASS / 3 SKIP

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/tools/avelune_converter_cli

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test
```

Exit 0 ; 23.036 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-cli-final-20261013-01.json.

### Build macOS final, 70.0 MB

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter build macos --release --no-pub
```

Exit 0 ; 94.822 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-build-release-cache-20261012-01.json.

### CLI AOT compilée

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/tools/avelune_converter_cli

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart compile exe bin/avelune_converter.dart -o /private/tmp/avelune-ac16-root-original-20261012/bin/avelune-converter-cached
```

Exit 0 ; 40.287 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-cli-compile-cache-20261012-01.json.

### Packager permanent, 22 PASS

Cwd : /Users/karim/Project/pokemonProject/apps/avelune_converter

```text
python3 -B tool/test_package_distribution.py
```

Exit 0 ; 1.228 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-package-tests-20261012-01.json.

### Archive finale

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/apps/avelune_converter

```text
python3 tool/package_distribution.py --app '/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/apps/avelune_converter/build/macos/Build/Products/Release/Avelune Converter.app' --cli /private/tmp/avelune-ac16-root-original-20261012/bin/avelune-converter-cached --fixture /private/tmp/avelune-ac16-root-original-20261012/source --output /Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC16-local-20261013
```

Exit 0 ; 13.974 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-package-final-20261012-01.json.

### Installation finale, --help/plan/convert/verify PASS

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository

```text
python3 /private/tmp/avelune-ac16-qualify-final-install-20261013.py
```

Exit 0 ; 1.218 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-installed-final-20261013-01.json.

### CLI/UI comparaison finale, equal=true

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart run tool/compare_native_studies.dart --parent '/Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16 original 20261012/output' --plan '/Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16 original 20261012/approved-plan.json' --expectations '/Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16 original 20261012/native-expectations.json' '/Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16 original 20261012/output/native-study-cli-preserved' '/Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16 original 20261012/output/native-study'
```

Exit 0 ; 28.234 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-comparison-final-20261012-01.json.

### Native UI debug réelle, exit0 après q

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -t dev/marionette_main.dart -d macos --debug --no-pub '--dart-define=AVELUNE_CONVERTER_QA_PLAN=/Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16 original 20261012/approved-plan.json'
```

Exit 0 ; 478.278 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-native-ui-20261012-01.json.

### Kanto réel final, nativeStudyPublished

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart run tool/source_semantics_study.dart '/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto' /private/tmp/avelune-ac16-kanto-resources-final-20261012/output /private/tmp/avelune-ac16-kanto-resources-final-20261012/evidence 98 'Route 9 — bibliothèque AC16' --approved-study
```

Exit 0 ; 553.5 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-kanto-resources-final-20261012-01.json.

### Kanto original relu par binaire distribué, verified=true

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository

```text
/Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC16-local-20261013/payload/AveluneConverter-local-validation/bin/avelune-converter verify --project '/private/tmp/avelune-ac16-kanto-resources-final-20261012/output/Projet converti' --offline --json
```

Exit 0 ; 3.441 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-kanto-verify-original-20261013-01.json.

### Design system analyse, aucune issue

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-ac16-design-system-g3plj6df/repository/packages/avelune_design_system

```text
/opt/homebrew/bin/flutter analyze --no-pub
```

Exit 0 ; 5.17 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-ds-package-analyze-20261012-01.json.

### Studio façades, 20 PASS

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-ac16-design-system-g3plj6df/repository/apps/avelune_studio

```text
/opt/homebrew/bin/flutter test --no-pub test/presentation/studio_design_system_identity_test.dart test/presentation/studio_design_system_test.dart test/presentation/studio_review_dialog_test.dart test/pokemon/pokemon_move_presentation_test.dart
```

Exit 0 ; 8.988 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-ds-studio-focused-green-20261012-02.json.

### Studio analyse, aucune issue

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-ac16-design-system-g3plj6df/repository/apps/avelune_studio

```text
/opt/homebrew/bin/flutter analyze --no-pub
```

Exit 0 ; 17.404 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-ds-studio-analyze-20261012-03.json.

### MCP build

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/tools/pokemap_mcp

```text
npm run build
```

Exit 0 ; 1.865 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-mcp-build-20261012-01.json.

### MCP check

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/tools/pokemap_mcp

```text
npm run check
```

Exit 0 ; 3.092 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-mcp-check-20261012-01.json.

### MCP catalogue/transport live, 2 PASS

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/tools/pokemap_mcp

```text
node --import tsx --test test/pokemon_authoring.test.ts
```

Exit 0 ; 18.727 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-mcp-live-catalog-20261012-03.json.

### Copie Kanto utilisateur relue, verified=true

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository

```text
/Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC16-local-20261013/payload/AveluneConverter-local-validation/bin/avelune-converter verify --project '/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC16 ressources 20261013/output/Projet converti' --offline --json
```

Exit 0 ; 2.881 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-user-study-verify-20261013-02.json.

### CLI analyse finale, aucune issue

Cwd : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac16-qualified-m5bf0qiz/repository/tools/avelune_converter_cli

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze
```

Exit 0 ; 2.917 s ; survivants possédés 0 ; protectedUnchanged=true. Reçu : /private/tmp/avelune-ac16-root-cli-analyze-final-20261013-01.json.

## Inventaire des fichiers et zones modifiées

Les coordonnées Ldébut,nombre proviennent du diff unifié contre fb654a223c7996f3caf3a0562574acd1ffa16940. Pour les fichiers créés, le nombre de lignes et les symboles sont relevés dans la source. Les widgets partagés et les façades ont la même raison d’extraction, précisée sur chaque ligne. Les détails de diff sont accessibles par git show du commit de ce rapport ; aucun snapshot intégral de code n’est recopié.

| Fichier | Zones modifiées/créées | Raison et impact |
| --- | --- | --- |
| apps/avelune_converter/assets/avelune_logo.png | créé, 0 lignes | Logo Converter autonome ; retire la dépendance aux assets Studio. |
| apps/avelune_converter/dev/marionette_main.dart | créé, 66 lignes | Harnais QA debug macOS du workflow réel ; entrée shipping inchangée. |
| apps/avelune_converter/lib/asset_review_canvas.dart | L5 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Import du design system canonique ; comportement de revue inchangé. |
| apps/avelune_converter/lib/asset_review_panel.dart | L7 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Import du design system canonique ; comportement de revue inchangé. |
| apps/avelune_converter/lib/converter_app.dart | L7 import 'package:avelune_converter_core/avelune_converter_core.dart'; ; L23 class ConverterApp extends StatelessWidget { ; L25 class ConverterApp extends StatelessWidget { ; L35 class ConverterApp extends StatelessWidget { ; L37 class ConverterApp extends StatelessWidget { ; L67 class ConverterApp extends StatelessWidget { ; L69 class ConverterApp extends StatelessWidget { ; L85 class ConverterWindow extends StatefulWidget { ; L87 class ConverterWindow extends StatefulWidget { ; L97 class ConverterWindow extends StatefulWidget { ; L99 class ConverterWindow extends StatefulWidget { ; L112,3 class _ConverterWindowState extends State<ConverterWindow> { ; L128 class _ConverterWindowState extends State<ConverterWindow> { ; L147,2 class _ConverterWindowState extends State<ConverterWindow> { ; L187,4 class _ConverterWindowState extends State<ConverterWindow> { ; L210 class _ConverterWindowState extends State<ConverterWindow> { ; L676,72 class _ConverterWindowState extends State<ConverterWindow> { ; L875 class _ConverterWindowState extends State<ConverterWindow> { ; L890,4 class _ConverterWindowState extends State<ConverterWindow> { ; L987 class _ConverterWindowState extends State<ConverterWindow> { ; L1031,3 class _ConverterWindowState extends State<ConverterWindow> { ; L1044,20 class _ConverterWindowState extends State<ConverterWindow> { ; L1923,3 class _ConverterWindowState extends State<ConverterWindow> { ; L1941,9 class _ConverterWindowState extends State<ConverterWindow> { ; L2089,15 String _failureMessage(Object error) { | Chargement/sauvegarde natifs de recette, nouvelle approbation et confirmation claire. |
| apps/avelune_converter/lib/desktop_services.dart | L8,6 import 'package:path_provider/path_provider.dart'; ; L17 typedef ConverterFolderOpener = Future<void> Function(String directory); ; L27,8 Future<String?> pickConverterPath(ConverterPathKind kind) async { ; L50,7 Future<String?> pickConverterPath(ConverterPathKind kind) async { | FilePicker natif pour lire/créer le fichier de plan. |
| apps/avelune_converter/lib/map_comparison.dart | L8 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Import du design system canonique ; comportement de revue inchangé. |
| apps/avelune_converter/lib/vision_panel.dart | L7 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Import du design system canonique ; comportement de revue inchangé. |
| apps/avelune_converter/pubspec.lock | L27,0 packages: ; L42 packages: ; L45 packages: ; L48 packages: ; L104,0 packages: ; L152,0 packages: ; L162,0 packages: ; L183,0 packages: ; L206,0 packages: ; L214,0 packages: ; L299,0 packages: ; L314,0 packages: ; L335,0 packages: ; L359,0 packages: ; L383,0 packages: ; L495,0 packages: ; L516,0 packages: ; L540,0 packages: ; L572,0 packages: ; L588,0 packages: | Dépendance au package partagé ; graphe autonome sans moteur et lock ciblé. |
| apps/avelune_converter/pubspec.yaml | L19,2 dependencies: ; L38,2 flutter: | Dépendance au package partagé ; graphe autonome sans moteur et lock ciblé. |
| apps/avelune_converter/test/asset_review_canvas_test.dart | L5 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| apps/avelune_converter/test/asset_review_panel_test.dart | L7 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| apps/avelune_converter/test/asset_review_session_panel_test.dart | L5 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| apps/avelune_converter/test/converter_app_test.dart | L6 import 'package:avelune_converter/converter_app.dart'; ; L8 import 'package:avelune_converter_adapters/avelune_converter_adapters.dart'; ; L41,9 void main() { ; L56,111 void main() { ; L766 Future<void> _scanAndPrepare( ; L774 Future<void> _scanAndPrepare( | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| apps/avelune_converter/test/converter_session_lifecycle_test.dart | L7 import 'package:avelune_converter_adapters/avelune_converter_adapters.dart'; | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| apps/avelune_converter/test/vision_panel_test.dart | L8 import 'package:avelune_converter_core/avelune_converter_core.dart'; | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| apps/avelune_converter/tool/create_original_fixture.dart | créé, 81 lignes | Générateur rerunnable de deux cartes/atlas originaux et déclaration de fixture. |
| apps/avelune_converter/tool/package_distribution.py | créé, 362 lignes ; PackageError | Archive privée inventoriée, modes/liens/notices/source originale vérifiés. |
| apps/avelune_converter/tool/test_package_distribution.py | créé, 254 lignes ; DistributionTests | Archive privée inventoriée, modes/liens/notices/source originale vérifiés. |
| apps/avelune_studio/lib/avelune_design_system.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/buttons/studio_button.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/buttons/studio_tool.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/dialogs/studio_review_dialog.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/feedback/studio_badge.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/feedback/studio_empty_state.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/feedback/studio_notice.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_choice.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_draft_field.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_path_field.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_search_field.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_select.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_toggle_row.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_action_bar.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_asset_preview.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_page_header.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_panel.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_section.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_sidebar.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/theme/studio_theme.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/lib/presentation/theme/studio_tokens.dart | L1 | Façade export-only du design system partagé ; conserve les identités/types Studio. |
| apps/avelune_studio/pubspec.lock | L100,7 packages: | Dépendance au package partagé ; graphe autonome sans moteur et lock ciblé. |
| apps/avelune_studio/pubspec.yaml | L15,2 dependencies: | Dépendance au package partagé ; graphe autonome sans moteur et lock ciblé. |
| apps/avelune_studio/test/presentation/studio_design_system_identity_test.dart | créé, 157 lignes | Vérifie l’identité des types canoniques et façades Studio. |
| packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart | L28,3 export 'src/source_catalog_study_composer.dart'; | Exporte les trois contrats/API locaux de recette, store et verification. |
| packages/avelune_converter_adapters/lib/src/converter_study_plan_recipe.dart | créé, 274 lignes ; ConverterStudyPlanRecipe | Recette complète fermée, paramètres/hashes bornés et identité exacte. |
| packages/avelune_converter_adapters/lib/src/converter_workflow.dart | L9 import 'approved_asset_library.dart'; ; L439,2 final class ConverterWorkflow { ; L448,43 final class ConverterWorkflow { ; L492,57 final class ConverterWorkflow { ; L578,6 final class ConverterWorkflow { ; L613,4 final class ConverterWorkflow { ; L645,4 final class ConverterWorkflow { ; L656,7 final class ConverterWorkflow { ; L694 final class ConverterWorkflow { ; L750,5 final class ConverterWorkflow { ; L782 final class ConverterWorkflow { ; L788 final class ConverterWorkflow { ; L994 int _workflowSequence = 0; ; L1333 Future<void> _converterWorker(_WorkerLaunch launch) async { ; L1364 Future<void> _converterWorker(_WorkerLaunch launch) async { ; L1854 ConverterWorkflowFailure _workflowFailure(Object error, | Export/restauration fermée du plan via recomposition fraîche ; stratégie des tuiles utilisées. |
| packages/avelune_converter_adapters/lib/src/local_asset_proposer.dart | L11,2 import 'native_project_writer.dart'; ; L126,2 final class LocalAssetProposer { ; L167 final class LocalAssetProposer { ; L227,3 final class LocalAssetProposer { ; L445,129 final class LocalAssetProposer { ; L1001,32 final class _AssetInputs { | Propositions bornées par tuile utilisée/couche avec tous les placements source. |
| packages/avelune_converter_adapters/lib/src/local_study_plan_store.dart | créé, 217 lignes ; LocalStudyPlanStore, _PlanNative | Persistance exclusive sans symlink/recouvrement canonique ; openat Darwin variadique. |
| packages/avelune_converter_adapters/lib/src/native_study_verifier.dart | créé, 161 lignes ; NativeStudyVerification, NativeStudyVerifier | Lecture stricte du projet/assets ; dernier contrôle d’identité/annulation après la relecture. |
| packages/avelune_converter_adapters/test/converter_asset_workflow_test.dart | L20,6 void main() { ; L41 void main() { ; L153,2 void main() { ; L309,2 void main() { ; L314 void main() { ; L377,2 void main() { ; L384 void main() { ; L398,2 void main() { ; L401 void main() { ; L587,32 final class _AssetWorkflow { | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_adapters/test/converter_study_plan_recipe_test.dart | créé, 353 lignes | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_adapters/test/local_asset_proposer_test.dart | L4 import 'package:avelune_converter_core/avelune_converter_core.dart'; ; L10,59 import 'support/original_asset_fixture.dart'; ; L93,133 void main() { | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_adapters/test/native_reproducibility_test.dart | créé, 126 lignes | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_adapters/test/publication_workflow_reproducibility_test.dart | L10 import 'support/native_writer_fixture.dart'; ; L12,0 const _authoringRoot = '.pokemap/authoring/'; ; L22 void main() { ; L45 void main() { ; L66,2 void main() { ; L71,5 void main() { ; L77,11 void main() { ; L119 void main() { ; L127,2 void main() { ; L133 void main() { ; L144,32 void main() { ; L182 void main() { ; L189 void main() { ; L192,3 void main() { ; L207,0 void main() { ; L236,0 Map<String, dynamic> _object(Object? value) { ; L239,0 void _require(bool condition, String message) { | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart | L105 final class LiteralFixtureTileset { ; L118,5 final class LiteralFixtureTileset { ; L126 final class LiteralFixtureTileset { ; L357,20 _Object _tileset(LiteralFixtureTileset tileset) => _Object('RPG::Tileset', { | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_adapters/test/support/native_reproducibility.dart | créé, 616 lignes ; NativeReproducibilityComparison, _LogNormaliser | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_adapters/tool/compare_native_studies.dart | créé, 112 lignes | Comparaison fermée des deux sorties à partir d’attentes capturées avant publication. |
| packages/avelune_converter_adapters/tool/source_semantics_study.dart | L97,3 Future<void> main(List<String> args) async { ; L101,0 Future<void> main(List<String> args) async { ; L103,0 Future<void> main(List<String> args) async { ; L120,4 Future<void> main(List<String> args) async { | Conserve propositions/diagnostics et snapshot même en erreur pour le corpus réel. |
| packages/avelune_converter_core/lib/src/models.dart | L115 sealed class ConverterDocument extends _JsonRecord { ; L337,3 final class SourceLocator extends _JsonRecord { | Décodeur public SourceLocator strict ; hash mémorisé du document gelé sans supprimer la validation. |
| packages/avelune_converter_core/test/immutable_document_hash_test.dart | créé, 89 lignes | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_converter_core/test/source_locator_decode_test.dart | créé, 42 lignes | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| packages/avelune_design_system/analysis_options.yaml | créé, 1 lignes | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/avelune_design_system.dart | créé, 20 lignes | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/buttons/studio_button.dart | créé, 68 lignes ; StudioButtonVariant, StudioButton | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/buttons/studio_tool.dart | créé, 81 lignes ; StudioTool | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/dialogs/studio_review_dialog.dart | créé, 46 lignes ; StudioReviewDialog | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/feedback/studio_badge.dart | créé, 63 lignes ; StudioTone, StudioBadge | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/feedback/studio_empty_state.dart | créé, 43 lignes ; StudioEmptyState | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/feedback/studio_notice.dart | créé, 60 lignes ; StudioNotice | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/inputs/studio_choice.dart | créé, 122 lignes ; StudioChoice, _StudioChoiceState | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/inputs/studio_draft_field.dart | créé, 68 lignes ; StudioDraftField, _StudioDraftFieldState | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/inputs/studio_path_field.dart | créé, 40 lignes ; StudioPathField | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/inputs/studio_search_field.dart | créé, 43 lignes ; StudioSearchField | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/inputs/studio_select.dart | créé, 39 lignes ; StudioSelect | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/inputs/studio_toggle_row.dart | créé, 24 lignes ; StudioToggleRow | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/layout/studio_action_bar.dart | créé, 30 lignes ; StudioActionBar | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/layout/studio_asset_preview.dart | créé, 61 lignes ; StudioAssetPreview, _PreviewBackground | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/layout/studio_page_header.dart | créé, 67 lignes ; StudioPageHeader | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/layout/studio_panel.dart | créé, 53 lignes ; StudioPanel | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/layout/studio_section.dart | créé, 38 lignes ; StudioSection | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/shared/widgets/layout/studio_sidebar.dart | créé, 22 lignes ; StudioSidebar | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/theme/studio_theme.dart | créé, 217 lignes | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/lib/presentation/theme/studio_tokens.dart | créé, 98 lignes ; StudioColors | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| packages/avelune_design_system/pubspec.yaml | créé, 20 lignes | Extraction Flutter canonique verbatim ; retire le couplage Converter→Studio. |
| tools/avelune_converter_cli/bin/avelune_converter.dart | L6,2 Future<void> main(List<String> arguments) async { | Commandes offline plan/convert/verify, même workflow et annulation SIGINT. |
| tools/avelune_converter_cli/lib/avelune_converter_cli.dart | L1 ; L10,3 Future<int> runConverterCli(List<String> arguments, ; L15 Future<int> runConverterCli(List<String> arguments, ; L17,6 Future<int> runConverterCli(List<String> arguments, ; L25,11 Future<int> runConverterCli(List<String> arguments, ; L37,10 Future<int> runConverterCli(List<String> arguments, ; L49,10 Future<int> runConverterCli(List<String> arguments, ; L71,9 Future<int> runConverterCli(List<String> arguments, ; L83,0 Future<int> runConverterCli(List<String> arguments, ; L87,12 Future<int> runConverterCli(List<String> arguments, ; L100,42 Future<int> runConverterCli(List<String> arguments, ; L144,17 Future<int> runConverterCli(List<String> arguments, ; L162,59 Future<int> runConverterCli(List<String> arguments, ; L222,47 Future<int> runConverterCli(List<String> arguments, ; L270 Future<int> runConverterCli(List<String> arguments, ; L272,2 Future<int> runConverterCli(List<String> arguments, ; L276,20 Future<int> runConverterCli(List<String> arguments, ; L297 Future<int> runConverterCli(List<String> arguments, ; L299 Future<int> runConverterCli(List<String> arguments, ; L301,7 Future<int> runConverterCli(List<String> arguments, ; L309,47 Future<int> runConverterCli(List<String> arguments, ; L357 Future<int> runConverterCli(List<String> arguments, | Commandes offline plan/convert/verify, même workflow et annulation SIGINT. |
| tools/avelune_converter_cli/test/scan_cli_test.dart | L149 void main() { ; L176 void main() { ; L254 void main() { ; L273 void main() { ; L288 void main() { | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| tools/avelune_converter_cli/test/study_cli_test.dart | créé, 220 lignes ; _ObservedSink | Assertions ciblées sur contrat/transport/immuabilité/propositions/reproductibilité ; conserve les cas négatifs. |
| documentation/reports/converter/AC-16/16_local_distribution.md | Document consolidé : audit, frontières, preuves, limites, inventaire et clôture | Livrable AC-16 explicitement demandé par le kit ; un seul nouveau Markdown. |

## Actualisation AC-16 — parcours normal et distribution du 14 octobre 2026

**Verdict : PARTIAL / DOING.** Les corrections du parcours de préparation et la distribution actualisée sont vérifiées. Le dossier Kanto original testé depuis la fenêtre bloque sur une ressource manquante ; aucune conversion complète depuis cette fenêtre, aucun jeu arbitraire et aucun parcours Player KAN-03 ne sont certifiés. Le lot complet AC-16 et le goal AC-00 à AC-16 restent ouverts.

### Audit initial et périmètre de cette actualisation

Base Git : b34b2e80988a18cbf7bb7e8241a825d128a3e3c9, branche main, index initial vide. Neuf fichiers de code/tests possédés ; 64 chemins étrangers déjà modifiés/non suivis, identifiés par SHA/mode dans start.json. Le writer natif sale appartient à un autre chantier : il est exclu du snapshot propre construit par git archive HEAD. Aucun checkout/worktree/rebase/push/amend. Les sources/test possédés du host et du snapshot sont byte-identical au gel source-pins-final-04.json.

Quatre obstacles de code : scan préparant toutes les cartes immédiatement ; plafond implicite256 insuffisant pour les274/276 propositions de la paire réelle ; budgets importés perdus à la préparation/sauvegarde suivante ; décisions de dépendances vidant leur propre contexte de revue. Correction limitée à la découverte, la préparation et les paramètres ; aucune modification du modèle natif, du moteur de combat ni des règles de gameplay. La conversion reste locale/déterministe, sans exécution Ruby source ni IA obligatoire.

Les défauts résolus sont concrets et hashés : une carte128 artefacts/256 mutations, deux cartes256/512 ; saturation aux plafonds existants256/2048. Le plafond distinct de revue reste1024 candidats. Les limites explicites importées ou reprises sont prioritaires et conservées ; une dépendance supplémentaire peut toujours provoquer un refus de quota, sans extension automatique.

### Fichiers modifiés et zones du diff contre la base

| Fichier | Zones exactes du diff (-avant +après) | Motif / impact |
|---|---|---|
| apps/avelune_converter/lib/converter_app.dart | -136,0 +137; -247,2 +248,7; -502,0 +509; -533,0 +541; -614,0 +623,3; -626 +637; -634,5 +644,0; -662,0 +669; -666 +673; -707,0 +715; -768,0 +777; -861 +870; -1285 +1294; -1302 +1311; -1413,2 +1422,2; -1553 +1562,2; -1951 +1961,2; -2024 +2035,3 | _scan, _settings, import/reprise, _changeDependency et catalogue : choix explicite des cartes, conservation des budgets et contexte de revue sans approbation périmée. |
| apps/avelune_converter/test/converter_app_test.dart | -20,0 +21,259; -958,0 +1218,11; -1084,0 +1355,12; -1189,0 +1472,10 | Nouveaux parcours scan sans préparation, sélection nommée, recette/budgets et décisions de dépendances groupées ; adaptations des helpers explicites. |
| apps/avelune_converter/test/converter_session_lifecycle_test.dart | -399,0 +400,8 | Le helper sélectionne et prépare explicitement avant la qualification de reprise. |
| packages/avelune_converter_adapters/lib/src/converter_workflow.dart | -117 +117; -118,0 +119,2; -360,0 +363; -377,0 +381; -394,0 +399; -415,0 +421,3; -588,0 +597; -1127 +1136,5; -1128,0 +1142; -1296,0 +1311,11; -1298 +1323 | ConverterStudySettings résout le défaut de budget ; ConverterWorkflowState et worker exposent le catalogue MapInfos avant préparation. |
| packages/avelune_converter_adapters/lib/src/source_catalog_study_composer.dart | -11,0 +12,17 | sourceCatalogStudyWriteLimitsFor : défaut par nombre de cartes, sans augmenter les plafonds globaux d’artefacts/mutations/octets/JSON/pixels/cellules. |
| packages/avelune_converter_adapters/test/converter_workflow_test.dart | -17,0 +18,63; -645,0 +709,9 | 288 candidats sur deux cartes admis avec le défaut ; même cas refusé avec limite explicite256 ; catalogue scan limité à MapInfos. |
| packages/avelune_converter_core/lib/src/source_normalization.dart | -388,0 +389,14; -658 +672; -673 +687,5; -752 +769,0; -769,11 +786; -842,0 +850,25 | inspectMapHierarchy et extractHierarchy : réutilisation du lecteur borné, sans lire cartes/tilesets/scripts pendant cette inspection. |
| packages/avelune_converter_core/test/source_normalization_test.dart | -476,0 +477,64 | Inspection de métadonnées même si une carte non sélectionnée est malformée ; refus SHA/inventaire incomplet/quota et annulation. |
| packages/avelune_converter_adapters/test/converter_asset_workflow_test.dart | -79 +79,2 | Le refus négatif conserve un budget explicitement fixé à 256 mutations ; aucun assouplissement de l’assertion. |
| documentation/reports/converter/AC-16/16_local_distribution.md | Append de cette actualisation | Preuves consolidées et limites actuelles ; aucun nouveau Markdown. |

### Tests, analyses et builds terminés

Racine de QA privée : /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej. Chaque reçu contient la commande argv, cwd, durée, pins avant/après, log SHA et identités PID/UID/date/commande. Les logs de tous les reçus ci-dessous sont rehashés avant ajout de cette actualisation. Tous ont exit0, timedOut=false, zéro descendant possédé survivant et protectedUnchanged=true. Les pins déclarés des tests/build/installation sont stables ; les reçus d’analyse et de packaging n’ont pas de pins pendant leur run. Leur raccord repose sur le gel final04 identique host/snapshot et sur les pins des suites/build, pas sur une surveillance de source absente de ces reçus. Un exit0 du superviseur seul ne suffit jamais : l’exitCode du reçu enfant est contrôlé.

| Reçu JSON | Commande (depuis le package du snapshot) | Résultat exact | Durée |
|---|---|---|---|
| core-tests-final-01.json | /opt/homebrew/bin/dart test --reporter expanded --concurrency=2 | 820 PASS / 1 SKIP / 0 FAIL | 65.459 s |
| adapters-tests-final-02.json | /opt/homebrew/bin/dart test --reporter expanded --concurrency=2 | 763 PASS / 90 SKIP / 0 FAIL | 186.554 s |
| app-tests-final-02.json | /opt/homebrew/bin/flutter test --no-pub --reporter expanded --concurrency=2 | 91 PASS / 4 SKIP / 0 FAIL | 55.959 s |
| cli-tests-final-01.json | /opt/homebrew/bin/dart test --reporter expanded --concurrency=2 | 28 PASS / 3 SKIP / 0 FAIL | 23.768 s |
| core-analyze-final-01.json | /opt/homebrew/bin/dart analyze | No issues found | 5.496 s |
| adapters-analyze-final-01.json | /opt/homebrew/bin/dart analyze | No issues found | 11.387 s |
| app-analyze-final-01.json | /opt/homebrew/bin/flutter analyze --no-pub | No issues found | 10.827 s |
| cli-analyze-final-01.json | /opt/homebrew/bin/dart analyze | No issues found | 3.591 s |
| build-release-final-02.json | /opt/homebrew/bin/flutter build macos --release --no-pub | Release71.1MB, arm64+x86_64 | 72.185 s |
| cli-compile-final-02.json | /opt/homebrew/bin/dart compile exe bin/avelune_converter.dart -o '/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/bin/avelune-converter-current' | CLI AOT arm64 produite | 26.483 s |
| package-current-01.json | /usr/bin/python3 tool/package_distribution.py --app '/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/repository/apps/avelune_converter/build/macos/Build/Products/Release/Avelune Converter.app' --cli '/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/bin/avelune-converter-current' --fixture /Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16-refresh-20261014-ftgqyeej/source --output /Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC16-local-20261014-current | ZIP/inventaire scellés | 4.494 s |
| install-current-run-01.json | python3 '/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/qualify_extracted.py' | Extraction/inventaire/CLI réels PASS | 1.308 s |

Les SKIP restent des preuves absentes : corpus externes optionnels non activés et cas de plateforme inapplicable. RED conservés : sélection initiale produisant un plan malgré zéro sélection ; budget deux cartes refusant288 candidats ; contexte des choix disparaissant après la première décision. Les replays ciblés GREEN sont selection-import-green-02 (2 PASS), workflow-green-02 (2 PASS), dependencies-green-01 (1 PASS). La première suite adapters finale01 échoue sur un ancien test qui comptait sur le défaut256 : la correction du test exprime maintenant cette limite explicitement ; la suite finale02 passe. Aucun test supprimé.

La résolution pub/locks a lieu exclusivement dans le snapshot. La CLI nécessitait une entrée map_gameplay absente de son lock privé ; pub get offline l’a résolue. Les locks app/core/adapters sont copiés/enforced dans le snapshot. Aucun lock, .dart_tool ou dependency config du host modifié.

### Installation réelle de la nouvelle archive

Archive : apps/avelune_converter/build/distribution/AC16-local-20261014-current/AveluneConverter-local-validation.zip, 37 761 635 octets, SHA effd1aff022ec84674e9000b022cb9d95739b59fdfca71e928de8c1a41e14f32. Inventaire SHA6f5c64f664d0b60d028042bbc7069cb87483f04bd2107e3f00c9df3e4cfd3a7c :38 fichiers réguliers,35 répertoires,9 liens internes relatifs,1NOTICE Flutter réel,0 sidecar Pods. Non notarized, non publié, aucune licence globale inventée.

Extraction ditto dans QA/install-current-01 : inventaire complet, modes et liens exactement égaux. Le binaire extrait exécute --help → plan → convert avec le SHA exact du plan → verify, PATH=/usr/bin:/bin:/usr/sbin:/sbin. Fixture originale synthétique incluse, cartes1/8, aucun SDK Dart/Flutter requis à l’exécution. Résultat :2 cartes/1atlas, published=true, verified=true, playableCertified=false ; source inchangée ; inventaire natif inchangé pendant verify. Révision sha256:642a26b19527a118df8767afb34f8d0eeb0bcc4a3cc935546f8ec661fc28dcb6. Reçus install-current-cli-01.json et install-current-run-01.json. Ceci ne prouve pas un import Kanto complet.

### Interface normale avec Kanto original — blocage source réellement observé

Entrée originale : /Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto. Copie de QA originale de23 707 fichiers, hashes source avant=copie=source après, zéro symlink, original-kanto-source-copy-01.json (32.562s). Elle est distincte de la copie complétée employée pour la démo r9.

Le helper QA est hors dépôt, observe ConverterApp réelle et démarre vide : aucun plan injecté, aucun picker substitué, aucun scan ou préparation automatique. Depuis les champs et boutons normaux : source/destination/nom entrés → Analyser →383 cartes nommées, archive catalogue Data/MapInfos.rxdata seulement, zéro sélection/préparation → recherche et sélection Route9(ID98)/Route10-N(ID100) → acknowledgment du profil d’étude → Préparer explicitement. Paramètres effectifs256 artefacts/512 mutations.

Préparation bloquée : normalisation signale normalization.missing_image, tileset FRLG_Outside absent, locator Data/Tilesets.rxdata ; UI affiche0cartes natives,33 événements extraits,2données bloquantes/4observations. Le dossier de destination Kanto-interface-original-r1 n’existe pas. Aucun export/publication/contournement du refus. Trace normal-interface-trace-01.json ; captures normal-source-original-kanto.png et normal-original-kanto-blocked.png.

Trois variantes réelles256×16192 ont des SHA différents : Kanto/FRLG_Outside_backup.png f147d2ff225eb152c8130b4f984b8a0b89b96d9bcb498a117aaed5dae9faab3a ; Johto/FRLG_Outside.png fea9e5fab963dda8c831ba6a71f2668ce39523cf44c0fbf137daa130ae6b562a ; Hoenn/FRLG_Outside.png fb9950c4130bf1201d924af4de2da65f744c7c663ac41993ce332867c24cdd81. La démo r9 complétée utilisait cette variante Hoenn. Aucun renommage/alias/choix automatique implémenté ici. Remplacer une variante sans revue ne prouverait pas la fidélité.

La comparaison actuelle avec la copie r9 qualifiée trouve11 fichiers ajoutés à cette dernière : image, BGM Route03, Scripts.rxdata, items.dat, species.dat, Game.exe et cinq PBS (items/moves/pokemon/pokemon_base_Gen_9_Pack/pokemon_forms). Les preuves r9 sur cette copie complétée ne sont pas des preuves d’import autonome de ce dossier original. Aucun exécutable source ni Ruby lancé.

Limites observation : deux hot reloads du helper hors dépôt ont ajouté une observation plus robuste après erreur d’extension ; la lecture d’état bloqué par extension restait indisponible et le diagnostic a été constaté dans la vraie UI. Les sources produit restent gelées. La release native ouverte lors d’un premier essai n’était pas contrôlable via CUA (-10005, ambiguïté de bundle) ; elle a été fermée avec identité vérifiée. Le parcours observé est une app debug réelle, pas la certification de la fenêtre release finale.

Fermeture : QA Converter PID35004 fermé par l’action de qualification, Marionette déconnecté ; normal-interface-run-01 exit0,1620.747s, sans timeout ni survivant. La fenêtre Studio que Yoahn garde pour jouer, PID1307 avec runner310/superviseur308, reste vivante et protégée. Aucune reprise/fermeture de ces PID et aucun blanket kill.

### Parité, passes et critique

Parité MCP : aucune sémantique native nouvelle ; le writer map_authoring, les actions projet et schémas cibles sont inchangés. Le catalogue source MapInfos et la préparation sont des contrats Converter core/workflow/CLI ; ils ne deviennent pas une action d’authoring Studio/MCP. Tests directs core/workflow, CLI et UI ci-dessus. Aucun nouveau catalog natif à enregistrer ; les anciennes preuves MCP ne sont pas présentées comme un nouveau run live de cette actualisation.

| Passe | Verdict et preuve |
|---|---|
| Audit / Architecture | Quatre obstacles de parcours identifiés ; frontières source/cible, budgets et source read-only conservés. |
| Implémentation | Neuf fichiers ciblés, changements indépendants du chantier writer/borders et du moteur de combat. |
| Tests | Quatre suites finales et quatre analyses PASS dans leur portée, SKIP et RED explicités. |
| Build / Validation | Release universelle, CLI arm64, archive/extraction/CLI fixture PASS ; interface Kanto originale bloquée et release visuelle non certifiée. |
| Critique finale | Revue indépendante ac15_connection_review_fresh : aucune P1/P2 dans les neuf fichiers gel04 ; logs/SHA des suites et de l’installation relus. Analyses/package sans pins de source pendant run, parcours GUI bloqué et portée fixture correctement distingués. |

Auto-critique : des totaux de tests et une conversion accompagnée ont été trop faciles à confondre avec un convertisseur autonome. Cette actualisation conserve explicitement le verdict incomplet. Le défaut de scan est corrigé ; la ressource manquante, le choix entre trois variantes, la publication depuis une fenêtre normale et KAN-03 restent à traiter. Aucune promesse de conversion universelle ou d’estimation horaire sans preuve.

État Git avant commit ciblé : neuf fichiers possédés et ce rapport ;64 chemins étrangers inchangés depuis start.json, index vide. Le contrôle final et le SHA du commit seront consignés dans le reçu de clôture et Notion. Pas de nouveau Markdown. Prochaine action autorisée : résolution explicite/traçable des ressources manquantes puis qualification de source → sélection → revue → publication → Studio, sans réduire le goal aux fixtures.


## Association explicite des atlas et parcours Kanto — 14 octobre 2026

**Verdict : correction implémentée/vérifiée ; AC-16 PARTIAL / DOING et goal AC-00 à AC-16 actif.** Le dossier Kanto original publie maintenant deux cartes depuis l’interface normale avec décisions d’étude explicites. Leur ouverture, le renommage natif, la sauvegarde et la réouverture à froid dans Studio sont observés. Aucune certification nouvelle d’édition des cellules/décors, des collisions ni du parcours Player KAN-03 ; aucune conversion universelle annoncée.

### Audit initial, décision et contrats

Base fc03653a6b26996ef3a47ef568f43a01909325a9, branche main, index vide. Treize fichiers de code/tests possédés et64 chemins étrangers inchangés, SHA/modes revérifiés dans image-binding-pins-04.json. Le writer concurrent reste exclu du snapshot. Le tour de statut précédent était sans progrès de code : la continuation a revalidé le runner GUI réellement vivant avant de poursuivre le même job. Aucun redémarrage pour un simple timeout d’observation.

Cause source : FRLG_Outside manque dans Kanto, mais FRLG_Outside_backup.png existe. Le choix entre variantes ne peut pas être silencieux. Le contrat SourceImageBinding conserve référence déclarée, chemin relatif exact et SHA du fichier admis. Il n’altère aucune source. Liste figée/canonique, maximum256, chemins4096, dossiers Tilesets/Autotiles seulement, un nom de fichier sans sous-dossier ; refus des traversées, doublons de casse, SHA erroné, choix inutilisé et association non nécessaire. La GUI/CLI proposent seulement les PNG réguliers raster admis du même dossier ; aucun alias externe ni reconnaissance IA. Les charsets ne sont pas couverts par ce nouveau contrat.

Extracteur rmxp-normalization-v3 ; Settings3, Recipe4, Store3 ; converter ac16-study-v2/rulesHash4. La preuve de liaison entre dans les hashes de normalisation/paramètres/plan/reprise. Les anciennes recettes/sessions sont rejetées et doivent être rescannées ; aucune migration pré1.0. Le modèle natif et le moteur de combat Avelune restent inchangés.

### Inventaire complet et zones exactes du diff contre fc03653a6

| Fichier | Hunks -avant +après | Motif / impact |
|---|---|---|
| apps/avelune_converter/lib/converter_app.dart | -121,0 +122 ; -267,0 +269 ; -517,0 +520,3 ; -624,0 +630 ; -650,0 +657 ; -777,0 +785,3 ; -861,0 +872,43 ; -1406,0 +1460,2 ; -1411,0 +1467,60 | _settings/_resumeSettings, import/reprise, _changeImageBinding, panneau Analyse : choix PNG source et invalidation de l’approbation. |
| apps/avelune_converter/test/converter_app_test.dart | -20,0 +21,89 ; -526 +615 | Parcours sélecteur, source manquante, nouvelle préparation et recette avec liaison non vide. |
| packages/avelune_converter_adapters/lib/src/converter_study_plan_recipe.dart | -83 +83 ; -94 +94 ; -130,0 +131,3 ; -234 +237 | Recette4, lecture Settings3 et décodage fermé de imageBindings. |
| packages/avelune_converter_adapters/lib/src/converter_workflow.dart | -111,0 +112 ; -173,0 +175 ; -180,0 +183 ; -194,0 +198 ; -206,0 +211 ; -217 +222 ; -224,0 +230 ; -1030 +1036 ; -1364,0 +1371 ; -1968 +1975,2 | Settings3 immuables/hashées, passage au normalizer, converter ac16-study-v2 et rulesHash4. |
| packages/avelune_converter_adapters/lib/src/local_review_session_store.dart | -154,0 +155 ; -189,0 +191 ; -199,0 +202 ; -212,0 +216 ; -227,0 +232 ; -246,0 +252,3 ; -260,0 +269 ; -273,0 +283 ; -330 +340 ; -352 +362 | ResumeSettings et Store3 : liste canonique persistée, contrôles et hashes. |
| packages/avelune_converter_adapters/lib/src/review_session_resumer.dart | -121,0 +122 | _settings réinjecte les associations dans la découverte puis la reprise exacte. |
| packages/avelune_converter_adapters/test/converter_study_plan_recipe_test.dart | -177 +177 ; -321,2 +321,2 | Version courante et refus des recettes/settings obsolètes. |
| packages/avelune_converter_adapters/test/converter_workflow_test.dart | -17,0 +18,94 ; -1932,0 +2027 ; -1962,0 +2058 | Source manquante → liaison → recette/publication ; Store3 → disque → workflow neuf → reprise non vide. |
| packages/avelune_converter_adapters/test/local_review_session_store_test.dart | -196 +196 ; -201 +201 | Contrat Store3 et liste requise dans la projection de reprise. |
| packages/avelune_converter_core/lib/src/source_normalization.dart | -117,0 +118,76 ; -127,0 +204 ; -137,0 +215 ; -147,0 +226,2 ; -349 +429 ; -399 +479 ; -410,0 +491 ; -414,0 +496,2 ; -422 +505,2 ; -435 +519,2 ; -459,0 +545,4 ; -686,0 +776,18 ; -691,0 +799,9 ; -1400,0 +1517,23 ; -1533,0 +1673 | SourceImageBinding, canonicalize/quotas, SourceImageReference.appliedImageBinding, admission du fichier régulier exact et normalizer-v3. |
| packages/avelune_converter_core/test/source_normalization_test.dart | -332 +332 ; -476,0 +477,178 ; -591 +769 | Association explicite, SHA/chemins/quotas/doublons, mutation du caller et choix inutilisé/non nécessaire refusés ; versionv3. |
| tools/avelune_converter_cli/lib/avelune_converter_cli.dart | -30,0 +31,3 ; -87,2 +90,2 ; -131,0 +135,13 ; -195,0 +212,4 ; -314,0 +335,38 | --atlas-binding, _atlasImagePaths commun insensible à la casse, _sourceImageBinding : SHA du snapshot, mêmes Settings3. |
| tools/avelune_converter_cli/test/study_cli_test.dart | -52,0 +53,81 | Plan→convert avec liaison ; refus sans sortie ; caractères = dans les deux noms et casse des dossiers préservés. |
| documentation/reports/converter/AC-16/16_local_distribution.md | Append de cette section | Preuves/limites consolidées ; aucun nouveau Markdown. |

Treize fichiers code/tests :801 insertions/22 suppressions au gel04. Le diff intégral est conservé dans atlas-final-source-diff.json et dans Git. Aucun commentaire de code ajouté : l’instruction directe utilisateur prime la demande de commentaires de codex_rule.md.

### Commandes, tests et builds terminés

Racine QA : /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej. Les chemins/argv complets et pins sont dans chaque reçu. Les commandes abrégées ci-dessous restent package-scoped ; seul le snapshot possède les pub/locks/builds temporaires. Les suites core/app et le build app demeurent celles du gel stable de leurs fichiers, inchangés par les dernières corrections CLI et l’assertion Store. Les analyses adapters/CLI, leur suite et la compilation CLI sont rejouées après ces corrections. Tous les reçus listés sont terminaux exit0, sans timeout ni survivant, logs SHA contrôlés et pins stables.

| Reçu | Commande / parcours | Résultat exact | Durée |
|---|---|---|---|
| image-binding-core-full-02.json | dart test --reporter expanded --concurrency=2 | 825 PASS / 1 SKIP / 0 FAIL, exit0 | 57.787s |
| image-binding-adapters-full-02.json | dart test --reporter expanded --concurrency=2 | 764 PASS / 90 SKIP / 0 FAIL, exit0 | 169.419s |
| image-binding-app-full-01.json | flutter test --no-pub --reporter expanded --concurrency=2 | 92 PASS / 4 SKIP / 0 FAIL, exit0 | 60.924s |
| image-binding-cli-full-04.json | dart test --reporter expanded --concurrency=2 | 32 PASS / 3 SKIP / 0 FAIL, exit0 | 17.578s |
| image-binding-core-analyze-final-01.json | dart analyze | No issues found, exit0 | 2.841s |
| image-binding-adapters-analyze-final-02.json | dart analyze | No issues found, exit0 | 4.475s |
| image-binding-app-analyze-final-01.json | flutter analyze --no-pub | No issues found, exit0 | 11.614s |
| image-binding-cli-analyze-final-03.json | dart analyze | No issues found, exit0 | 3.252s |
| image-binding-release-build-01.json | flutter build macos --release --no-pub | App release universelle71.1MB ; App.framework SHA bda9184965aa0121c9a727ee07d01a48b53c770ab45217b56b47b40a6b9503fd, exit0 | 70.704s |
| image-binding-cli-compile-03.json | dart compile exe bin/avelune_converter.dart -o QA/bin/avelune-converter-bindings-final-case | CLI finale AOT arm64, exit0 | 26.261s |
| image-binding-package-final-01.json | python3 tool/package_distribution.py --app release --cli final-case --fixture originale --output atlas-bindings-final | ZIP/inventaire final scellés, exit0 | 4.470s |
| install-bindings-final-run-01.json | python3 qualify_extracted_bindings_final.py | Extraction exacte ; --help→plan→convert→verify,2cartes/1atlas, exit0 | 1.360s |
| install-bindings-final-case-run-01.json | python3 qualify_installed_case_binding.py | CLI extraite : liaison non vide, = et dossier en minuscules ; plan→convert→verify, exit0 | 5.661s |
| image-binding-store-resume-01.json | dart test test/converter_workflow_test.dart --plain-name 'workflow consumes and persists explicit missing atlas image decisions' --reporter expanded --concurrency=1 | 1 PASS ; Store3 non vide relu/repris, exit0 | 11.497s |
| normal-interface-bindings-run-01.json | flutter run --debug --no-pub -t QA/normal_interface_bindings_main.dart -d macos | Source originale → sélection → choix → approbation → publication depuis UI normale, exit0 | 1693.960s |
| studio-kanto-interface-run-01.json | flutter run --debug --no-pub -t QA/studio_kanto_interface_main.dart -d macos | Projet exporté ouvert ; renommage et sauvegarde via UI normale, exit0 | 293.729s |
| studio-kanto-interface-reopen-01.json | Même commande dans un nouveau processus après fermeture | Réouverture à froid ; nom/rendu sauvegardés présents, exit0 | 82.302s |
| original-kanto-source-after-run-01.json | python3 verify_original_kanto_after.py | 23 707 fichiers originaux et copie inchangés, exit0 | 8.752s |

Les SKIP restent des absences de preuve, notamment corpus externes optionnels et cas de plateforme non applicable. Les RED initiaux de contrat/normalisation, workflow, sélecteur GUI et CLI sont conservés. La revue indépendante a trouvé deux P2 dans le parser CLI : premier = puis casse du dossier. RED effectifs image-binding-cli-equals-red-01 et image-binding-cli-case-red-01 : expected0/actual2. Parser commun _atlasImagePaths, séparateur suivi d’un dossier atlas admis, insensible à la casse et substrings exacts. GREEN suite CLI04 :32PASS/3SKIP. Aucun garde-fou réduit pour les faire passer.

Reprise exécutée : liaison non vide → Store3 créé → nouvelle instance du store → chargement disque → workflow neuf → resumer ; même binding/hash de revue, canApprove=true, aucune approbation/résultat réutilisé, hash du store inchangé. Le test termine ensuite la publication normale et vérifie la source inchangée.

### Kanto original : publication réelle puis Studio

Source : /Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto. Copie QA originale23707 fichiers, source/copie revérifiés intégralement après le parcours, reçus original-kanto-source-copy-01 et original-kanto-source-unchanged-after-interface-01. Aucun des11 compléments de l’ancienne démo r9 injecté.

UI debug réelle démarrée vide, aucun plan/bootstrap source/picker substitué : champs source/destination → scan383 noms → sélection98/100 → acceptation du profil d’étude et première frame d’eau → préparation bloquée → choix FRLG_Outside_backup.png dans Analyse → préparation → quatre sorties hors sélection explicitement exclues → préparation → plan visible2cartes/1atlas → approbation → publication. SHA backup f147d2ff225eb152c8130b4f984b8a0b89b96d9bcb498a117aaed5dae9faab3a ; aucune équivalence avec les variantes Johto/Hoenn certifiée.

Résultat GUI : /Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16-refresh-20261014-ftgqyeej/output/Kanto-interface-atlas-r1,2cartes/2ressources, published=true, sourceUnchanged=true, playableCertified=false, révision sha256:3d0c261f4554e43a630eeedf27942744b16725b424525d744283cc6ebc400acd. Trace normal-interface-bindings-trace-02.json et capture normal-bindings-kanto-published.png. Les33 événements extraits restent différés dans cette sortie littérale ; quatre sorties de Route10Nord vers205/166/102/205 inactives. Toutes les frames d’eau sont conservées, seule la première active ; horloge source non vérifiée. Ce résultat ne remplace pas une tranche source/Player qualifiée.

Incidents de conduite conservés : premier tap100 avant la mise à jour de la recherche, puis trois scroll_to après44 tentatives. Relecture effective de l’état corrige la sélection ; swipe dans la marge du viewport principal atteint le panneau atlas. Aucune correction produit de worker/défilement inférée de ces erreurs. Aucun hot reload dans ce run ; sources produit gelées. L’ouverture par launcher signale foreground unavailable ; les contrôles/captures Marionette portent sur la vraie fenêtre debug, pas sur la fenêtre release ni son picker natif.

Studio : copie byte-identical29 fichiers dans /Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/AC16-Kanto-interface-20261014-ftgqyeej/Projet converti. Bootstrap debug exige chemin canonique et ouvre réellement le projet avant runApp. UI Carte → actions Route9 → Renommer → Route9 — modifiée dans Studio → Enregistrer. Nouveau processus après fermeture affiche nom et rendu persistés, Enregistré et aucun incident sur les ressources. La différence de la map est uniquement name ; project.json et journaux/blobs authoring sont les seules autres mutations enregistrées. Les29 fichiers publiés d’origine demeurent inchangés. Reçu studio-kanto-interface-edit-persistence-01, traces/captures studio-kanto-interface-*. Ce contrôle ne prouve pas encore la peinture/édition de cellules ou de décors.

Fermeture réelle : Converter71191, Studio89738 puis94256 fermés par leurs actions QA, connexions Marionette déconnectées et runners terminaux. Reopen réape uniquement2ibtoold possédés avec SIGTERM et identité UID/date/commande revérifiée ; zéro survivant. Studio utilisateur1307 et runner310/superviseur308 conservés ; aucun signal sur eux et aucun blanket kill.

### Archive finale extraite et CLI réellement exécutée

Distribution : apps/avelune_converter/build/distribution/AC16-local-20261014-atlas-bindings-final/AveluneConverter-local-validation.zip, 37771299 octets, SHA 4d454414dac6b59dce77aee16c1426164e59ea584244d0a9bfc5492d2f2a20eb. Inventaire SHA 0064cc40805384823c9dffe3a49f2bb85768b99ce6ba2c113553df25c642e991,38 fichiers/35répertoires/9liens internes relatifs,1NOTICE Flutter réel,0sidecar Pods. App universelle, CLI arm64 ; exécution qualifiée arm64. Archive privée/non notarized/non publiée, aucune licence globale inventée, aucun média Pokémon ni source de jeu intégré.

Extraction install-bindings-final-01, inventaire/modes/liens égaux ; PATH=/usr/bin:/bin:/usr/sbin:/sbin ; --help→plan→convert→verify avec les vrais binaires extraits et fixture originale distribuée :2cartes/1atlas, source inchangée, verify read-only, révision d825cb78780d29bbf096fee34eac4c8391459412a891ab7b111a60237b84aa48. Le scénario supplémentaire install-bindings-final-case-01 utilise une fixture originale générée avant exécution, puis la CLI extraite avec Référence=Graphics/Tilesets/Terrain=Night et PNG source exact graphics/tilesets/Terrain=Night_backup.png. Plan4 à liaison non vide → convert → verify :1carte/1atlas, source inchangée, révision e15e47e21a73471832de31d2933f6fd7f64f7cb8259d4f9319dd4e6ef36cdf7e. Aucun SDK requis pour exécuter le binaire ; génération de fixture de test distincte de ce runtime.

L’ancienne archive d89b1af… et ses reçus restent distincts ; ils ne qualifient pas rétroactivement le parser final. La parité CLI/GUI historique REL03 n’est pas annoncée comme rejouée sur ce nouveau plan Kanto : le contrat commun est exercé dans chaque transport, mais la comparaison du même nouveau plan dans les deux sorties reste à compléter.

### Parité, passes et critique finale

MCP : ce choix appartient aux contrats source Converter et ne crée aucune sémantique de modèle/authoring Avelune. API core/workflow, recipe/session, GUI et CLI sont exercés. Aucune nouvelle action cible à enregistrer ; catalogue live/MCP non rejoué ici et anciennes preuves distinctes. Le renommage Studio utilise l’action canonique existante map.update_metadata ; aucun fichier projet modifié à la main.

| Passe | Verdict |
|---|---|
| Audit / Architecture | Source manquante prouvée ; association explicite/hashée, frontières/quotas conservés, modèle natif inchangé. |
| Implémentation |13fichiers ciblés, paramètres et reprises raccordés, aucun source/writer/combats modifié. |
| Tests |Quatre suites finales/analyses et Store3 non vide passent ; SKIP/RED et portée exacte conservés. |
| Build / Validation |Release et CLI finales, archive extraite réelle, GUI originale publiée et renommage Studio à froid observés ; Player/édition de décors encore absents. |
| Critique indépendante |ac15_connection_review_fresh : deux P2 CLI reproduits/corrigés ; gel04 exact, aucun P1/P2 restant dans13fichiers ; différences de preuves/versions relues. |

Auto-critique : le choix explicite de backup et l’étude à deux cartes ne suffisent pas à rendre automatique la conversion complète de Kanto. La publication/renommage sauvegardé sont maintenant des preuves réelles ; la fidélité complète du backup, l’édition des cellules/décors, KAN03 et le contrôle de la fenêtre release finale ne sont pas acquis. Les règles native/runtime ne sont pas affaiblies pour présenter un faux vert. Goal complet ouvert, aucune estimation horaire inventée.

Git avant commit :13fichiers possédés et ce rapport,64 chemins étrangers inchangés, index vide. Aucun nouveau Markdown ni pub/lock de dépendances du host modifié ; les distributions locales déclarées sont générées sous build/distribution. Aucun push/rebase/amend/branche/worktree. Le reçu commit-atlas-after-01.json et Notion portent le SHA et l’état final vérifiés après le commit local ciblé. Prochaine action : édition de décors réellement sauvegardée/reouverte puis parcours Player contrôlé, sans réduire les lots restants à ce test de métadonnées.

## Édition de cellule et absence d’un sprite de PNJ — 14 octobre 2026

**Verdict : correction du blocage de carte vérifiée ; AC-16 et le goal complet restent DOING / PARTIAL.** Une vraie cellule du nouvel export Kanto original a été effacée dans Studio, sauvegardée et retrouvée exactement après fermeture/réouverture. La préparation d’une tranche de trois cartes incluant le Centre Pokémon aboutit maintenant malgré un sprite absent. La première publication de cette tranche a été interrompue par le délai du harnais ; aucun projet final de trois cartes n’est annoncé comme publié ou jouable.

### Audit initial et portée

Base19b55b84bf8c60b086638395650bdcc31fbe4732, main, index vide,64 chemins étrangers inchangés. Le dernier tour de statut a fourni une nouvelle preuve de cold-reopen puis fermé sa propre fenêtre, donc est classé PROGRESS. Le writer natif étranger est exclu de la qualification et du commit. Les skills systematic-debugging, test-driven-development, verification-before-completion, using-pokemap-mcp et test-flutter-desktop guident la vérification ; codex_rule.md et les exigences KAN-03 du kit ont été relus. Les instructions humaines sur commits locaux, source immuable, absence d’IA obligatoire et combat Avelune priment.

Le probe source98/100/166/205 termine avec FRLG_Caves manquant. Le probe98/100/102 termine avec normalization.missing_image sur Map102/event7/page0, NPC_FRLG_WOMAN_2_FORMAL, absent du corpus régional inspecté. Un sprite de PNJ absent bloquait toute la carte alors que la projection canonique sait déjà quarantiner l’événement entier lorsqu’aucun character binding n’existe. Le correctif vise uniquement cette absence ; aucune image de remplacement n’est inventée. Les ambiguïtés, chemins invalides, images de tileset/autotile, quotas, hashes et changements de source restent bloquants.

Inventaire exact contre la base :

| Fichier | Zones du diff | Raison / impact |
|---|---|---|
| packages/avelune_converter_core/lib/src/source_normalization.dart | _normalizedJson, ligne429 ; resolveImage, ligne1540 | Extracteur v4 ; diagnostic non bloquant uniquement pour une image character absente avec locator map/event/page complet. Référence et raw data conservées. |
| packages/avelune_converter_core/test/source_normalization_test.dart | Version attendue ; tests autour de1315 | Absence non bloquante avec locator exact ; ambiguïté et traversal restent bloquants. |
| packages/avelune_converter_adapters/test/source_event_study_composer_test.dart | Nouveau test autour de31 | PNJ manquant à deux pages avec self-switch, voisin valide, writer réel et relecture stricte ; aucun acteur/fact/dialogue actif issu du manquant. |
| documentation/reports/converter/AC-16/16_local_distribution.md | Présent complément | Preuves, interruption, artefacts et limites consolidés ; zéro nouveau Markdown. |

Trois fichiers code/tests :138 insertions/4 suppressions. Aucun commentaire de code ajouté, conformément à l’instruction directe. Source_normalization.dart et les deux tests host sont byte-identical au snapshot qualifié ; ledger missing-npc-final-pins-01.json. Le modèle natif, Studio, runtime, moteur de combat et writer ne sont pas modifiés. La version d’extraction entre dans les hashes de normalisation/plan ; Settings3/Recipe4/Store3 demeurent leurs contrats courants. Un ancien plan v3 doit être recomposé et approuvé de nouveau.

### Édition native réellement persistée

Source publiée originale : …/AC16-refresh-20261014-ftgqyeej/output/Kanto-interface-atlas-r1. Nouvelle copie byte-identical29 fichiers : /Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/AC16-Kanto-cell-edit-20261014-ftgqyeej/Projet converti. La fenêtre normale Studio ouvre Route9 ; zoom36%, gomme choisie dans la vraie palette, geste au centre observé de la cellule10,10. Le layer z0 passe uniquement son index730 de17 à0. Undo restaure la map entière ; redo retrouve exactement cette cellule ; Enregistrer termine dirty=false/error=null. Les captures avant/après montrent568 pixels changés dans le seul rectangle de cellule24×24 à cette échelle.

La relecture disque retrouve cette unique différence ; toutes les autres données map sont conservées. Hash du fichier map modifié77cab1205f5a7424f22ea3e7ccddcfe79d0180e73076c57d81ad6dc26eec4580. Après fermeture du PID356 et nouveau processus4203, la map entière observée est exactement égale à la map éditée/sauvegardée, dirty=false/error=null. Preuves Q/cell-edit-01/trace-01.json, saved-cell-proof-01.json et cold-reopen-proof-01.json contenant la map réellement relue. Les29 fichiers de la publication source restent intacts. La peinture d’une autre tuile n’a pas été menée à son terme et n’est pas revendiquée.

Les deux fenêtres QA sont fermées, connexions Marionette déconnectées : studio-run-01 exit0/401.032s et studio-reopen-01 exit0/562.088s, aucun signal ni survivant, protégés inchangés. Studio utilisateur1307 et son runner310/superviseur308 restent intacts ; aucun contrôle sur sa partie.

### Commandes et résultats terminaux

Q = /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej. Les argv/cwd complets, identités de processus, pins et SHA des logs sont conservés dans les reçus. Les commandes ci-dessous s’exécutent dans leurs packages du snapshot privé ; aucun lock/pub/config du host modifié.

| Reçu | Commande / contrôle | Résultat exact | Durée |
|---|---|---|---|
| missing-npc-core-red-01 | dart test source_normalization_test, plain-name du nouveau comportement | RED : expected true / actual false, exit1 |3.899s|
| missing-npc-adapters-red-02 | dart test source_event_study_composer_test, plain-name du nouveau comportement | RED : expected true / actual false, exit1 |5.183s|
| missing-npc-core-green-01 | dart test test/source_normalization_test.dart --reporter expanded --concurrency=1 |66PASS/1SKIP, exit0|5.618s|
| missing-npc-adapters-green-01 | Test composer/writer/relecture stricte avec Scripts attestés |1PASS/0SKIP, exit0|8.577s|
| missing-npc-core-full-01 | dart test --reporter expanded --concurrency=2 |827PASS/1SKIP, exit0|60.786s|
| missing-npc-adapters-regression-01 | dart test : composer, character importer, projection, workflow, recette et composer littéral |185PASS/3SKIP, exit0|33.542s|
| missing-npc-core-analyze-01 | dart analyze |No issues found, exit0|2.113s|
| missing-npc-adapters-analyze-01 | dart analyze |No issues found, exit0|2.729s|
| missing-npc-cli-build-01 | dart compile exe bin/avelune_converter.dart -o Q/bin/avelune-converter-missing-npc-v4 |AOT arm64, exit0|27.188s|
| missing-npc-app-build-01 | flutter build macos --release --no-pub |71.1MB, arm64+x86_64 vérifiés par lipo, exit0|63.585s|
| normalizer-upgrade-run-02 | Ancienne CLI v3 plan → nouvelle CLI v4 convert avec ancien hash approuvé |Refus réel workflow.recipe.stale/code7 ; source/recette intactes, aucune destination ; contrôle exit0|0.396s|
| missing-npc-package-01 | python3 tool/package_distribution.py, release/CLI v4/fixture originale |ZIP/inventaire scellés, exit0|4.217s|
| install-missing-npc-v4-run-01 | Archive extraite, inventaire/modes/liens ; CLI --help→plan→convert→verify |2cartes/1atlas synthétiques, source intacte, verify read-only, exit0|1.359s|
| missing-npc-mcp-dependencies-01 | npm ci --offline --ignore-scripts dans snapshot |22packages installés, lock stable, exit0|1.015s|
| missing-npc-mcp-build-01 / check-01 | npm run build / npm run check |exit0 / exit0|1.812s /1.834s|
| missing-npc-mcp-live-01 | node --import tsx --test --test-concurrency=1 test/narrative_event_typed_stdio.test.ts |1PASS/0SKIP ; describe, action canonique, apply/refus/reopen/query/close live|10.903s|
| centre-source-copy-run-01 | Copie APFS de la source restaurée ; deux médias au hash historique exact |23720fichiers, copie de base intacte, exit0|16.969s|
| kan03-probe-run-04 | Workflow public, source restaurée, sélection98/100/102, trois sorties hors sélection exclues |canApprove=true, profil exact,44events,78artefacts natifs/421mutations ; aucun export à ce stade, exit0|206.231s|

Les SKIP restent des absences de preuve. Le premier harnais Dart offrepo ne compilait pas (paramètre profile et méthode draft), et le premier test adapter ajouté ne compilait pas (commands requis/nom GridSize) ; les erreurs et leurs logs sont conservés avant les RED fonctionnels. Le premier contrôle AOT de version pointait une fixture inexistante : source.root_invalid/code3 ; chemin corrigé, contrôle02 ci-dessus. Aucun contournement de validation ni suppression de test. Build app réape seulement deux ibtoold prouvés avec SIGTERM ; zéro survivant et protégés inchangés dans tous les reçus terminaux réussis.

Nouvelle archive locale : apps/avelune_converter/build/distribution/AC16-local-20261014-missing-npc-v4/AveluneConverter-local-validation.zip,37772313octets, SHA9fd23706722dc8c569aafb9150e5fd9f502bbd169fc81defe2c3d175e08d27d7 ; inventaire SHA957bb919288ae3fee3eb0c570c558a0e3b27952cc2462896e397a9669198c752.38fichiers/35répertoires/9liens relatifs,1NOTICE réel,0sidecar Pods. App.framework SHA9a96fb01786dbff7962d52ffa9536900413960998e22d0f6649eaa60330fc728 ; CLI SHA6a66af109f1e84a27d2033661be710bc89b21530bd51869292ad75790261cf20. L’installation extraite publie la révision synthétique6b3a9535a1bfb5d9cc566b8bbf759e6dabdfe6024ea4a34fcafe8fa3c656049a. Distribution privée, non notarized/non publiée ; aucun média Pokémon incorporé.

### Tranche Centre et publication interrompue

Entrée /Users/karim/Library/Containers/com.yoahnl.avelune.converter/Data/Documents/AC16-Kanto-Centre-20261014-w6qqnxwc/Kanto source restaurée : copie exacte des23718 fichiers r9 attestés, plus BGM Centre et SE Exit Door depuis Hoenn, correspondant en taille et SHA aux witnesses Kanto r8. Les deux correspondances historiques sont relues par le root dans centre-media-historical-check-01.json. Cette entrée demeure une restauration partielle de source historique ; elle ne remplace pas le dossier Kanto original actuel et ne rend pas ses fichiers manquants disponibles silencieusement.

Préparation : snapshot fd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e ;8events adaptés/36whole-quarantined, dont les11events du Centre ; aucune arrival anchor de porte active. Map102/event7 conserve characterBindingMissing. Trois transferts vers166/205/205 exclus explicitement en étude, première frame d’eau admise explicitement. Recette4167octets, plan approuvé245bb21a2f355828c24d5a4cd7a31d5f8e6a01c2579d911404240f11fa473dec. La préparation admissible n’est pas une preuve de jeu jouable.

La CLI réelle v4 restaure cette recette et applique155/421 opérations avant la borne du harnais600s. centre-native-convert-01 : exit-15, timedOut=true,600.405s, SIGTERM limité à son PID19051, zéro survivant, protégés inchangés. Le projet final n’existe pas ; journal privé c32767c002445f564c9310683e11c9f651833e18 conservé jusqu’à bootstrapCompleted, staging partiel conservé. Une tentative de protéger le superviseur échoue sur son contrôle d’identité car le processus est déjà terminal ; aucun signal supplémentaire envoyé. Le sample échoue également parce que le PID est absent. Ces erreurs ne sont pas maquillées en attente d’un processus vivant.

Après lecture de begin/reconcile, le retry utilise exactement la même recette et les mêmes binaires dans un nouveau job privé, sans supprimer le précédent staging ni recréer un projet final existant ; borne2400s et reçu centre-native-convert-02. Ce run reste à surveiller et n’est pas inclus dans les résultats terminaux ci-dessus. Aucun redémarrage sur simple expiration d’observation : le premier arrêt a été confirmé par son reçu et son handle terminal.

### Parité, passes et critique finale

MCP : aucun nouveau contrat ou action natifs. Le writer conserve ses appels map_authoring canoniques ; le test du PNJ manquant vérifie ses vrais effets et la relecture stricte. Le serveur est néanmoins reconstruit/checké dans le snapshot et son catalogue event_v2.record_upsert observé par un vrai client stdio sur une racine temporaire étroite. La projection MCP des nouveaux trois fichiers Kanto et leur UI n’est pas revendiquée. La révision de normalisation ne modifie pas le modèle de combat.

| Passe | Verdict |
|---|---|
| Audit / Architecture root + ac15_connection_review_fresh | Cause globale trop large prouvée ; dépendance d’image de PNJ distinguée des images nécessaires au rendu de carte. Source incomplète et commandes Centre non qualifiées identifiées. |
| Implémentation root |7lignes de normalizer, deux zones de tests ; source raw/locator conservés, événement entier fermé, zéro modèle natif modifié. |
| Tests root |RED fonctionnels puis827core/185adapter ; writer/relecture et ancien plan réellement refusé ; SKIP/erreurs initiales déclarés. |
| Build / Validation root |Release/AOT/ZIP/extraction réelle PASS ; édition native cold-reopen prouvée ; première publication de trois cartes interrompue, retry encore en cours. |
| Critique indépendante |Aucun P1/P2 trouvé dans les consommateurs inspectés : importer exige fichier/hash, toute page sans binding ferme l’événement, aucune entité/fact/scène active ; limites de source et de KAN03 conservées. |

Auto-critique : le correctif rend la carte importable, pas le PNJ manquant visible ni les portes/soins du Centre fonctionnels. Le jeune PNJ102/14 contient contrôles de texte et route25 vers le joueur ; la porte exige SE/tone/wait/no-fade et un garde de réentrée. Ajouter seulement un facing de warp ou ignorer ces commandes serait un faux raccourci. KAN03 reste non certifié, l’édition par peinture et la fenêtre release/picker restent ouvertes, les anciens travaux publiés/qualifiés demeurent distincts. Aucune roadmap ou gate bêta modifiée.

Git avant commit : quatre chemins de l’inventaire à commiter, index vide, hashes/modes des64 étrangers revérifiés inchangés. Le contrôle après commit produira et vérifiera commit-missing-npc-after-01.json avec SHA/parent/blobs/index et conservation des étrangers. Aucun push/rebase/amend/branche/worktree. Le ticket AC16 existant reste dans son unique grand domaine Post Bêta Monde & narration, DOING/PARTIAL. La suite conserve le goal complet : terminer la publication en cours, puis porter et tester le véritable dialogue/passage Centre avec état et sauvegarde.


## Actualisation du 14 octobre — Centre publié et dialogue en qualification

La seconde publication précédemment en cours est terminale et réussie : centre-native-convert-02, exit0/1138.108s, verified/published/sourceUnchanged=true, playableCertified=false ; révision76958a78264921e865c12bce028ded97051c3a66d7f76d81021c3dfa6aa4e22c. Les3cartes sont copiées exactement dans le sandboxStudio ; Centre20×20 à29% réellement affiché, capture centre-studio-01.png, UI fermée et protégés intactes. Ce résultat a encore8events adaptés/36inactifs.

Le complément AC13 suivant reconnaît le vrai PNJ102/14 : texte b/r/n et route209/509 strictement bornée, sans changement natif/runtime/combats. Preuve finale de préparation9adaptés/35inactifs ; nouvelle publication centre-dialogue-native-convert-01 encore en cours. Rapport consolidé, audit, inventaire6fichiers, RED/GREEN, passes et risques : documentation/reports/converter/AC-13/13_native_events.md, complément du14octobre. Aucun Player du PNJ, porte ou KAN03 encore certifié.

Distribution désormais AC16-local-20261014-static-dialogue-v2 : ZIP37791981B/SHA2c831dbd5cb438e9d5f826c5c8e46f2ff7b3007e19c3e652dfb0a68a3a20ea16 ;38files/35dirs/9liens, aucun médiaPokémon. Release71.1MB universelle/72.299s, CLIAOT27.513s ; extraction réelle help→plan→convert→verify2maps/1atlas PASS1.297s, source inchangée/vérificationread-only. Les vieilles archives/preuves demeurent leurs versions distinctes. REL01GUI/picker et REL03nouveauplanCLI/GUI restent ouverts ; AC16DOING/PARTIAL, goal complet actif.

## Actualisation du 15 octobre — distribution des programmes de porte originaux

**Verdict : artefact local et CLI extraits vérifiés ; AC-16 DOING / PARTIAL.** La distribution actuelle contient les changements poussés de `63577610e` et `eec7ae856`. La CLI extraite convertit la fixture originale et relit sans écriture le projet utilisateur Route 9 / Route 10 Nord / Centre Pokémon. Aucun lancement GUI de cette release ni aucune certification du jeu complet ne sont déduits de ces contrôles.

### Audit initial, périmètre et inventaire

Base exacte : `eec7ae856216bde9c9fc1f99256831be9e02c207`, main et origin/main synchronisés, index vide. Le reçu initial compte 96 chemins étrangers modifiés/non suivis, tous conservés en hash pendant la qualification. L'archive Git privée contient 10 710 membres ; un lien absolu historique de `packages/map_editor/macos/Flutter/ephemeral_backup_20260323/Packages/.packages/file_picker` est exclu de cette seule extraction. Aucun nettoyage du checkout hôte.

La passe relit le kit AC-00 à AC-16, ses 80 cas d'acceptation, les rapports courants, `codex_rule.md`, les skills `verification-before-completion` et `using-pokemap-mcp`. Le tour précédent a surtout fourni un tableau de statut ; sa revue packaging a également renforcé les assertions requises pour la nouvelle extraction. Ce progrès de preuve est distinct d'une mutation produit. Ce tour ferme les preuves d'artefact et d'exécution de la distribution actuelle. L'objectif intégral conserve les 17 lots.

Seul ce rapport existant est modifié dans le dépôt : en-tête actualisé et présent complément. Aucun code produit, test permanent, modèle, action MCP, dépendance, workflow CI ni ressource Kanto ajouté. Les scripts de qualification et les reçus restent externes sous `Q/native-global-routes-01/distribution-refresh-20261015`, où `Q=/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-source-door-timing-20261014-83ui2yih`.

Le candidat et ses 40 fichiers épinglés correspondent aux blobs Git. `candidate-01.json` SHA `52b88370432e275940e2771e1ddb06d81d10d3a0020e6c497450423744e0420f`. Résolution offline uniquement dans l'archive privée ; aucun lockfile hôte modifié. Les packages Converter ne dépendent pas de Studio pour distribuer leur design system.

### Commandes terminées et résultats

Chaque commande utilise `Q/run_owned.py` avec cwd, 40 pins produit, scripts de contrôle, log/hash, identités des descendants et garde des PID protégés. Les temps ci-dessous sont ceux du superviseur, hors addition artificielle des replays.

| Package / artefact | Commande exacte ou script contrôlé | Résultat |
|---|---|---|
| `packages/avelune_converter_adapters` | `dart pub get --offline` | exit 0, 1,327 s |
| `tools/avelune_converter_cli` | `dart pub get --offline` | exit 0, 1,341 s |
| `apps/avelune_converter` | `flutter pub get --offline` | exit 0, 1,338 s |
| `tools/avelune_converter_cli` | `dart test --concurrency=1 --reporter=expanded` | exit 0, 32 PASS / 3 SKIP, 26,138 s ; corpus optionnels et branche non-macOS non exercés |
| `tools/avelune_converter_cli` | `dart analyze` | exit 0, No issues found, 4,074 s |
| `apps/avelune_converter` | `python3 -B tool/test_package_distribution.py` | exit 0, 22 PASS, 0,695 s |
| `apps/avelune_converter` | `flutter build macos --release --no-pub --target lib/main.dart` | exit 0, 71,7 MB, 72,637 s ; warnings Swift de dépréciation et phase Flutter sans outputs conservés |
| `tools/avelune_converter_cli` | `dart compile exe bin/avelune_converter.dart -o D/bin/avelune-converter` | exit 0, 25,488 s ; D est le dossier de qualification ci-dessus |
| Fixture originale | `dart --packages=N/packages/avelune_converter_adapters/.dart_tool/package_config.json N/apps/avelune_converter/tool/create_original_fixture.dart D/original-source-01` | exit 0, 4,404 s ; N=D/repository, deux cartes 8×8, PNG original, aucun script Ruby |
| Archive | `python3 -B tool/package_distribution.py --app 'N/apps/avelune_converter/build/macos/Build/Products/Release/Avelune Converter.app' --cli D/bin/avelune-converter --fixture D/original-source-01 --output /Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC16-local-20261015-original-doors` | exit 0, 4,085 s |
| Installation extraite | `python3 -B D/qualify_extracted_01.py` | exit 0, 1,664 s ; extraction réelle et cinq commandes CLI, dont refus d'approbation périmée |
| Kanto utilisateur | `python3 -B D/qualify_kanto_readonly_01.py` | exit 0, 5,290 s ; CLI verify réelle 4,464 s, 3 cartes / 88 assets, 1 403 fichiers inchangés |

Les suites core/adapters/application déjà enregistrées pour la cohorte Source30 ne sont pas présentées comme de nouveaux runs. Les tests du packager utilisent volontairement des exécutables synthétiques ; leur réussite est distincte de la compilation et de l'exécution AOT réelles ci-dessus.

### Archive, extraction et vérification stricte

Sortie locale : `apps/avelune_converter/build/distribution/AC16-local-20261015-original-doors`. ZIP de **38 172 807 octets**, SHA `b52fd0c6c9c1fdbae50962fc2787db76fc40682a8a65e25c84fda8ddda581fcd`. Inventaire SHA `10f7e20d0bd22a371bf22ce67a173db3c87b612566319dc353046d3de569826b` : 38 fichiers, 35 répertoires, neuf liens internes relatifs et une notice Flutter réelle. Fixture synthétique originale, aucun média Pokémon ni secret dans le logiciel. L'archive reste privée, non notarized, non publiée ; aucun grant global de licence du dépôt inventé.

Après `ditto -x -k`, l'inventaire des octets/modes/liens est identique. La CLI extraite a le même SHA `54409e345152089100571c4f9288312ac13aed02e905dbcad40cd92dd417b8a9` que l'AOT compilée. Les deux exécutables sont de vrais Mach-O ; l'application annonce `x86_64 arm64`, et `codesign --verify --deep --strict` réussit. Seule l'exécution arm64 de la CLI est exercée ; ni lancement graphique ni exécution x86_64 ne sont inférés.

Avec `PATH=/usr/bin:/bin:/usr/sbin:/sbin`, la CLI extraite exécute `--help`, `plan --maps 1,8 --ack-profile --offline --json`, `convert` avec mauvais hash (exit 7, `workflow.stale_approval`, aucune destination créée), puis `convert` avec l'approbation fraîche exacte et `verify --offline --json`. La recette version 4, ses hashes d'approbation/préparation/snapshot et ses chemins sont contrôlés ; le projet comporte réellement deux fichiers de cartes 8×8 et deux IDs distincts. Les JSON convert/verify doivent annoncer les kinds/versions attendus, `verified=true`, `playableCertified=false`, deux cartes/un asset et la même révision `sha256:82301a2f5149ba98d409fd94b4f3c81019291985dad8a8ef861ba75dcb5a87b5`. Source, recette, payload extrait et projet après verify restent inchangés.

Le même binaire extrait relit ensuite `/Users/karim/Documents/Avelune Converter Studies/Kanto - Route 9 Route 10 et Centre - 20261015/Projet Avelune`. Les 1 403 hashes correspondent avant et après au reçu de livraison Source30 ; trois cartes et 88 assets sont réellement relus, révision `sha256:f4f83a06aacb181c037eddb82dcfdd8c702ca2bb7485f7ebf8773c4b4aa07447`. `verified=true` reste distinct de `playableCertified=false` et de l'ouverture GUI du projet.

### Preuves, passes et limites

`build-qualification-01.json` SHA `9ceaf3059556c4d418f24c9b8592ad4a032407dbca97c22b05041dee127fd88c` lie les dix reçus terminaux. `extracted-qualification-01.json` SHA `3facf266aa38a945a74d32e4d2a43a38e3cc61dab2bacc4c17193e65581ba561` ; `extracted-run-01.json` SHA `ca20c9c7015e19f8c6997fe8b40b96f1c18a53e0099d3e3e593a4473e6030f06`. Le contrôle Root relit effectivement les exit codes, hashes des logs, pins avant/après/courants et absences de survivants. Deux descendants `ibtoold` du build ont reçu SIGTERM après revalidation PID/UID/start/commande ; les onze autres commandes supervisées n'ont aucun signal. Tous les PID protégés restent inchangés.

Audit/Architecture : revue globale `overall-gates-audit-01.json`, SHA `e6bfee4929dacb9967e7e828dc4255ef2f6ef134a9137a7b190fb4178e369636`, avec les 17 critères de lot et 80 cas, sans exiger une conversion universelle absente du kit. Implémentation : aucune modification produit nécessaire pour reconstruire la cohorte publiée. Tests : 32 PASS/3 SKIP CLI et 22 PASS packaging ; Build/Validation : release, AOT, extraction/CLI et relecture Kanto acquises. Revue packaging indépendante `packaging-readonly-review-01.json`, SHA `849e49fb0acfaaa8341ccd3a9776a969effd7b49d21fef983cddcc185dc970bf`, puis contre-revue finale `final-independent-review-01.json`, SHA `5018d325c77f64af6c328be056d6de9b2cfd53a4222b222977ee5349affd48fa` : favorable dans ces limites, aucun P1/P2 identifié. La passe indépendante recalcule les pins et logs, les inventaires build/extrait, la chaîne d'ascendance des deux ibtoold et les 1 403 hashes de la livraison Kanto. Le contrôle Root confirme ces preuves ; les seules modifications du rapport après sa relecture sont cette référence et la précision de classement du tour précédent.

Parité MCP nouvelle N/A : ce complément ne change aucune sémantique d'authoring, seulement la distribution des contrats déjà qualifiés. REL-03 du même plan courant via le transport interface reste ouvert ; un comparateur ou un workflow headless ne prouve pas ce transport. La GUI release/picker, Studio Source30 ouvrir/modifier/save/cold-reopen, le trajet unique KAN-03 incluant le vrai dialogue et l'audibilité restent des preuves distinctes. Les 11/44 événements adaptés et 33 quarantinés de ces trois cartes ne mesurent pas l'avancement global du produit. Pas de nouvel appel IA, aucune exécution Ruby source, moteur de combat Avelune conservé.

Auto-critique : cette passe ferme la livraison logicielle actuelle et sa lecture native ; elle ne ferme pas les gates visibles ni l'objectif intégral. La suite reste le trajet KAN-03 combiné puis les gates GUI après déverrouillage humain du Mac, avec fermeture des outils possédés. Ticket existant AC-16 dans le seul domaine Post Bêta Monde & narration conservé DOING/PARTIAL, Gate bêta false. État Git final et SHA du commit consignés dans le reçu externe de publication après contrôle ciblé ; aucun changement étranger ne doit être indexé.
