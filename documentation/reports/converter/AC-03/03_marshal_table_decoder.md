# AC-03 — Décodeur Marshal, Table et zlib borné

Date locale : 12 octobre 2026. Base : `0da2e532d227d91c4fed869883a55968e1e4fba9`, branche `main`. Verdict technique : **PASS**, proposé **TO REVIEW** dans le cockpit, jamais DONE sans décision humaine. L’application finale reste prévue dans `apps/avelune_converter`.

## Audit initial et Gate 0

AC-02 fournit un inventaire sûr et une source Kanto autorisée. Le kit impose DEC-01 à DEC-06 : axes Table, identités du graphe, callbacks inertes, corruption localisée, décompression bornée et encodages sans remplacement silencieux. Aucun lecteur Marshal réutilisable n’a été trouvé dans la recherche ciblée ; l’import RMXP existant lit du YAML. Le contrat JSON actuel refuse les cycles et ne convient pas à une arène Marshal.

L’audit a retenu une arène immuable à références numériques, des tables distinctes pour objets et symboles et un localisateur binaire séparé du SourceLocator v1. Les classes source, modules, expressions régulières et mécanismes personnalisés restent des données. Le reader n’importe ni dart:io ni Flutter et ne résout aucune classe source.

Les préfixes Kanto observés sont Marshal 4.8. Les sources primaires ont été recoupées : [format Ruby](https://docs.ruby-lang.org/en/3.3/marshal_rdoc.html), [lecteur CRuby actuel](https://raw.githubusercontent.com/ruby/ruby/v3_3_0/marshal.c), [CRuby Ruby 1.8](https://raw.githubusercontent.com/ruby/ruby/ruby_1_8/marshal.c). La prose récente contient deux ambiguïtés : l’index d’objet est zéro et le symbole du wrapper e précède son objet. L’oracle Ruby contrôlé et le lecteur C règlent ces points. Ruby 1.8 peut ajouter une mantisse binaire à un float 4.8 ; le Converter la lit explicitement.

L’audit de la bibliothèque archive a trouvé des vérifications de corruption insuffisantes pour une promesse de zlib strict par wrapper seul. Le lot utilise donc un petit lecteur pur basé sur les [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950.html) et [RFC 1951](https://www.rfc-editor.org/rfc/rfc1951.html), sans dépendance supplémentaire ni copie de code tiers.

État Git initial : 257 chemins étrangers déjà modifiés, index vide, sur main à la base ci-dessus. Leurs contenus ont été hachés avant édition ; aucun de ces chemins n’entre dans le lot. Les PID 6272 et 82303 n’ont pas été touchés.

## Changement et inventaire exhaustif

| Fichier | Zone et responsabilité |
| --- | --- |
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | Imports typed_data/math et deux parts ; export public via le barrel existant. |
| `packages/avelune_converter_core/lib/src/marshal_decoder.dart` | 1–236 : types et quotas, graph/text/errors ; 237–379 : Table/Color/Tone ; 380–fin : builders internes, tags, références et floats historiques. |
| `packages/avelune_converter_core/lib/src/bounded_zlib.dart` | 1–64 : API/limites ; 65–279 : en-tête, blocs, checksum ; 280–363 : arbres ; 364–fin : historique et sortie bornée. |
| `packages/avelune_converter_core/test/marshal_decoder_test.dart` | 115 tests : graphes, tags, corruption, quotas, témoins callbacks, encodages, floats et payloads RGSS. |
| `packages/avelune_converter_core/test/bounded_zlib_test.dart` | 38 tests : oracles synthétiques et corruption, expansion, arbres vides/singletons, fenêtres et ring. |
| `tools/avelune_converter_cli/test/native_decoder_corpus_test.dart` | Qualification locale opt-in via AVELUNE_CONVERTER_TEST_SOURCE et MacOsSourceTree ; métriques/diagnostics seulement. |
| `documentation/reports/converter/AC-03/03_marshal_table_decoder.md` | Ce rapport consolidé, audit et Gates. |
| `documentation/reports/converter/AC-03/commands.json` | Receipts, états Git, sources et preuves de cette passe. |
| `documentation/reports/converter/AC-03/index.json` | Manifeste haché du lot ; son propre hash est volontairement exclu. |

Les diffs canoniques sont ceux de Git et ces sources. Aucun snapshot Markdown du code, aucune donnée ou média de Kanto et aucun script source n’ont été ajoutés au dépôt.

Marshal couvre les tags contrôlés nil/bool/fixnum/bignum/float/string/symbol, liens, arrays, hashes/defaults, objets, struct/data, user-defined/user-marshal, class/module et les wrappers I/e/C. Les enregistrements respectent les identités et cycles, notamment U avant son payload et Iu après ses ivars. Les longueurs, profondeurs, nœuds, slots, strings, arêtes, grands entiers et localisateurs sont limités. Un tag inconnu, une référence invalide ou des bytes après la racine sont refusés avec fichier, offset, tag et chemin.

Table vérifie l’en-tête de 20 bytes et les produits avant allocation. Les cellules int16 signées gardent l’ordre X puis Y puis Z ; le nombre de dimensions déclaré est conservé, y compris trois axes unitaires et un axe actif zéro. [Référence Table mkxp](https://raw.githubusercontent.com/Ancurio/mkxp/master/src/table.cpp). Color/Tone lisent quatre float64 little-endian, préservent les valeurs finies hors plage et refusent explicitement les composantes non finies. Ce dernier refus est une politique Converter. [Références Color/Tone](https://github.com/Ancurio/mkxp/blob/master/src/etc.cpp), [lecture des doubles](https://github.com/Ancurio/mkxp/blob/master/src/serial-util.h).

Les chaînes gardent leurs bytes et déclarations d’encodage. UTF-8, US-ASCII et ISO-8859-1 sont décodés strictement ; une déclaration non prise en charge ou des bytes invalides produisent un diagnostic et conservent les bytes. Le binaire non ASCII ne devient pas du texte par remplacement.

Zlib vérifie en-tête/CINFO, absence de dictionnaire, LEN/NLEN, arbres, limites de codes, distances/historique/fenêtre, fin de bloc, Adler-32 et trailing. Le quota précède chaque émission et nouvelle allocation de sortie. L’historique est fixe ; les segments et la copie finale restent chacun dans le plafond de sortie. Aucune mesure RSS ni garantie sur toute la mémoire du processus n’est revendiquée.

## TDD et corrections issues de la revue

La suite Marshal initiale compile et donne 101 UnimplementedError sur le scaffold : exit 1, 44 failure et 57 error. Les floats Ruby 1.8 ont ensuite été reproduits en RED : deux marshal.invalid_float. La nouvelle borne maximale a trouvé un overflow de math.pow avec base entière ; les quatre bases sont maintenant 2.0. Les six fixtures historiques comparent les bits exacts, dont valeurs subnormales et maximum fini.

Les précontrôles des slots objets et symboles ont été déplacés avant les payloads. Des listes instrumentées échoueraient si les bytes protégés étaient lus. L’ordre Iu reste testé contre un dump contrôlé Latin-1 avec string d’encodage enregistrée avant l’objet.

Zlib a donné 28 échecs intentionnels sur le scaffold. La critique a ensuite fourni un flux littéral-only avec HDIST=2 et arbre de distance vide : RED zlib.invalid_tree, puis correction ciblée. Le lecteur accepte l’arbre vide et refuse toute longueur qui tenterait de l’utiliser. [Source primaire zlib](https://github.com/madler/zlib/blob/master/inftrees.c#L117-L124).

Les témoins Ruby utilisent uniquement Marshal.dump sur des classes synthétiques maîtrisées ; leurs callbacks écriraient un marker s’ils étaient invoqués. Le marker reste absent après le décodage. Aucun Marshal.load sur le corpus, aucun Ruby source ni script décompressé exécuté.

## Vérification finale

| Commande et contexte | Résultat exact |
| --- | --- |
| Core : `dart test --reporter json` | Exit 0 ; 498 success, 0 failure/error ; completion success true ; 19.798 s. |
| Adapter : `dart test --reporter json` | Exit 0 ; 26 success ; 4.553 s. |
| CLI : `dart test --reporter json` sans source opt-in | Exit 0 ; 22 success, 2 skipped attendus ; 6.326 s. |
| `dart analyze` dans les trois packages | Exit 0, `No issues found!` dans chacun ; core final rejoué après le correctif pow. |
| Marshal ciblé final : `dart test test/marshal_decoder_test.dart --reporter json` | Exit 0 ; 115 tests ; 1.364 s. |
| Zlib ciblé final : `dart test test/bounded_zlib_test.dart --reporter expanded` | Exit 0 ; `+38: All tests passed!` ; receipt agent runtime. |
| CLI : `dart compile exe bin/avelune_converter.dart -o <temp>/avelune-converter` | Exit 0, Generated ; 3.243 s. |
| Probe original hors dépôt : `dart compile exe --packages=<core package_config> <temp>/decoder_smoke.dart -o <temp>/decoder-smoke` | Exit 0, Generated ; 1.341 s. |
| Exécutable probe AOT | Exit 0 ; cycle=true, maxFiniteExact=true, tableCells=18, zlibByte=65. |
| Exécutable CLI `--help` | Exit 0 ; aide réelle ; 0.239 s. |
| CLI avec source explicite : `dart test test/native_decoder_corpus_test.dart --reporter json` | Exit 0 ; completion success true ; 6.281 s ; bilan ci-dessous. |

Tous les runners ont été supervisés avec identités et descendants ; les receipts root finaux donnent confirmedSurvivors=[] et signals=[]. Les agents confirment aussi aucun survivant détenu, aucun signal. Les harnesses ne justifient aucun kill extérieur.

Un corpus différentiel synthétique temporaire de 100 cas Python zlib, seed 19501951, a comparé exactement 2 382 290 bytes selon le receipt runtime ; le temporaire a été supprimé. Cette preuve secondaire reste distincte des 38 tests versionnés. Un calcul Python indépendant a aussi comparé 2 004 floats pour préparer la reconstruction historique ; les preuves Dart et AOT ci-dessus restent les preuves d’exécution du lecteur.

## Corpus Kanto et limites

La source choisie est `Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto` ; le chemin exact et son Unicode sont enregistrés dans commands.json. Aucun fichier source n’a été écrit. L’empreinte indépendante des métadonnées avant/après est identique : `e8d978ec0c595a62d359051af11e0c20dd4d0a2bba4f191dfffa45cac441e2cd`, 24 273 entrées. Les lectures passent par les descriptors O_RDONLY de l’adapter.

Le probe final a décodé 423 documents Marshal : 399 des 400 rxdata et les 24 dat. Il observe 383 RPG::Map, 1 100 535 nœuds, 1 046 Tables et 1 915 140 cellules. Il valide aussi 15 Color et 1 956 Tone. Les 402 tuples de Scripts ont produit 5 316 166 bytes avec quota individuel et cumulé, sans exécution.

**Une source reste refusée : Data/PkmnAnimations.rxdata, 14 807 403 bytes.** Le budget par défaut des localisateurs atteint sa limite à l’offset 401075 ; code marshal.quota.locations. Un essai explicite avec plafond de 64 Mi code units atteint également sa limite à l’offset 3052697. Ces refus ont été conservés ; aucun plafond n’a été augmenté implicitement en production. Le probe continue uniquement sur marshal.quota.*, consigne le refus et propage toute autre erreur. Son succès ne signifie donc pas admission complète du corpus.

Les 567 diagnostics marshal.invalid_text du probe comprennent des strings binaires compressées et des séquences non UTF-8 ; ce compteur n’est pas un décompte de dialogues perdus. Les bytes restent disponibles. La qualification des textes/encodages métier appartient à AC-04. Aucun override de profil Essentials, aucune certification de version, aucune IR native, ouverture Studio ou jouabilité n’est démontrée ici.

## Verdicts des passes

| Passe | Responsable | Verdict et preuve |
| --- | --- | --- |
| Audit/Architecture | target_contracts | PASS de faisabilité ; contrats, références et Table vérifiés, DEC-06 confirmé. |
| Implémentation | root + runtime_contracts | PASS ; reader pur, floats historiques, payloads et inflater borné. |
| Tests | target_contracts + runtime_contracts ; root final | PASS ; RED puis 115 Marshal/38 zlib, et 498 core en régression. |
| Build/Validation | root | PASS ; analyses, AOT réel et probe source frais ; limite PkmnAnimations déclarée. |
| Critique finale | test_validation, lecture seule | PASS statique sur snapshots relus ; quatre findings levés, aucun restant. L’exécution est établie par les receipts root/runtime, pas un rerun du critique. |

## Parité MCP, auto-critique et Gate final

La nouvelle sémantique est un lecteur de source externe, sans commande d’authoring ni mutation de projet Avelune. La parité editor/JSONL/MCP et le rebuild du serveur sont N/A pour ce lot ; aucune action d’éditeur n’est contournée. AC-05 doit évaluer séparément l’écriture via les contrats/API natives. AOT lancé dans un nouveau processus vérifie le code Dart pur ; aucun hot reload d’une application Studio extérieure n’a été provoqué.

Risques : l’inflater pur demande des régressions pour tout nouveau cas ; les tests ne sont pas une certification exhaustive. Les quotas peuvent refuser une source valide mais volumineuse, comme le catalogue PkmnAnimations. Les floats historiques sont qualifiés sur IEEE754 float64 ; les encodages non implémentés conservent les bytes. L’IR et la gestion métier de ces refus restent à construire. Aucune perte silencieuse ou certification de compatibilité complète n’est revendiquée.

Gate final technique : DEC-01 à DEC-06 verts, analyses propres, AOT exécuté, critique PASS, source et 257 contenus étrangers inchangés. Les checks finaux de format, Markdown et diff, le manifeste et l’état Git avant commit sont dans commands.json/index.json. Le commit est scoped au lot ; l’état après commit et son SHA sont projetés dans le ticket Notion.

Ticket : [AC-03 — Décodeur Marshal et Table](https://app.notion.com/p/3f6197a7bfa581e8bdb3ee6e97995333), famille existante Monde, exploration et narration — Post Bêta. Bêta gelée inchangée. Prochaine étape autorisée : AC-04, normalisation traçable des maps/tilesets/events bruts et résolution des médias, en conservant explicitement toute donnée inconnue ou refusée.
