import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

/// A deliberately non-Selbrume author project used only for product gates.
///
/// It is written as an author workspace, exported through `map_editor`, then
/// deleted before installation so the installed runtime cannot depend on it.
final class NeutralCertificationGameFixture {
  /// Writes two extra maps wired by warps when true. Off by default so the
  /// release artifact and the existing certifications keep their exact shape.
  const NeutralCertificationGameFixture({
    this.connectedMaps = false,
    this.partySize = 1,
    this.encounterField = false,
    this.trainerArena = false,
    this.economyTown = false,
    this.progressionArena = false,
    this.dialoguedPreSession = false,
  }) : assert(partySize == 1 || partySize == 2 || partySize == 6);

  final bool connectedMaps;

  /// BETA-CIN-083 : le parcours de presession dialogue vit en v7, parce que
  /// c'est la version qui porte les Presentations. Seul le MANIFESTE suit ce
  /// drapeau : les cartes restent en v6 dans un projet v7, exactement comme
  /// celles du vrai projet. Off par defaut, donc le paquet de release et
  /// toutes les gates existantes gardent leur forme exacte au bit pres.
  final bool dialoguedPreSession;

  ProjectVersion get projectVersion =>
      dialoguedPreSession ? ProjectVersion.v7 : ProjectVersion.v6;

  String get projectFormat => dialoguedPreSession ? 'v7' : 'v6';

  /// BETA-PTY-005 : la gate Party/PC exige deux membres — déposer l'unique
  /// Pokémon utilisable est refusé par la garde lastUsable. Un pour les autres
  /// gates, qui gardent leur forme exacte.
  final int partySize;

  /// BETA-ENC-006 : la gate rencontre → capture → Pokédex → stockage a besoin
  /// d'un terrain de rencontre entièrement déterministe PAR LES DONNÉES :
  /// une case d'herbe à 100 % de déclenchement, une seule espèce mono-niveau
  /// aux IVs figés (le maxHp du sauvage décide de l'issue du tirage de
  /// capture), et un sac de départ portant les deux Balls du scénario —
  /// la Poké Ball 1/1 dont l'échec est certain au seed générique du runtime,
  /// et une Ball 17/1 dont la réussite est une garantie mathématique
  /// (17 × 45 = 765, le plafond exact du dénominateur à PV pleins).
  /// Off par défaut : les gates existantes gardent leur forme exacte.
  final bool encounterField;

  /// BETA-TRN-005 : la gate boss/rival a besoin d'une arène déterminée par
  /// les données — un rival récurrent battable au niveau de départ, un boss
  /// trop fort pour lui (la défaite du premier assaut est certaine) dont la
  /// victoire au retour, après l'XP du rival, débloque badge, flag et Surf.
  /// Off par défaut : les gates existantes gardent leur forme exacte.
  final bool trainerArena;

  /// BETA-ITM-008 : la gate économie a besoin d'une ville — l'arène du rival
  /// (la récompense de victoire porte des objets), une boutique à stock
  /// authoré, un ramassage d'objet par événement V2 (le canal production en
  /// mode v2Only), une CT compatible et un objet tenu porté au sac de départ.
  /// Implique l'arène. Off par défaut : les gates existantes gardent leur
  /// forme exacte.
  final bool economyTown;

  /// BETA-PRG-006 : la gate progression a besoin d'un lead à QUATRE attaques
  /// (chaque nouveau move force un prompt de remplacement), d'un learnset où
  /// deux moves tombent sur le grind (growl au 6, vine_whip au 7) et d'une
  /// évolution au niveau 7 — surcharges de DONNÉES par-dessus le seed, dans
  /// l'espace auteur de la fixture. Implique l'arène.
  final bool progressionArena;

  bool get _arenaEnabled => trainerArena || economyTown || progressionArena;

  bool get _actorTilesetEnabled => _arenaEnabled || dialoguedPreSession;

  static const String shopId = 'certification_shop';
  static const String machineItemId = 'certification-tm-growl';
  static const String heldItemId = 'certification-leftovers';
  static const String pickupItemId = 'super-potion';
  static const GridPos pickupCell = GridPos(x: 2, y: 3);
  static const String pickupTriggerId = 'certification_pickup_trigger';

  static const String rivalTrainerId = 'certification_rival';
  static const String bossTrainerId = 'certification_boss';
  static const String bossBadgeId = 'certification_tide_badge';
  static const String bossVictoryFlagId = 'story:certification_boss_beaten';
  static const GridPos rivalCell = GridPos(x: 0, y: 3);
  static const GridPos bossCell = GridPos(x: 3, y: 1);

  static const String encounterTableId = 'certification_grass_table';
  static const String encounterZoneId = 'certification_grass_zone';
  static const String weakBallItemId = 'poke-ball';
  static const String guaranteedBallItemId = 'certification-ball';
  static const GridPos encounterCell = GridPos(x: 1, y: 2);
  static const String completionTriggerId = 'certification_corner_trigger';

  static const String dawnKeeperCharacterId = 'keeper_dawn';
  static const String duskKeeperCharacterId = 'keeper_dusk';
  static const String actorTilesetId = 'certification_actor_tileset';
  static const String actorTilesetPath =
      'assets/tilesets/certification_actors.png';

  /// BETA-CIN-083 : les quatre medias du parcours dialogue.
  ///
  /// Les OCTETS sont de la graine, comme le tileset d'acteur ; les CLIPS qui
  /// les referencent sont authores par actions canoniques. La frontiere est
  /// deliberee : le risque nomme du ticket est une fixture qui contourne
  /// l'authoring, et c'est le parcours qui doit passer par les actions, pas la
  /// donnee de base. L'import transactionnel des medias est certifie ailleurs
  /// (BETA-CIN-029) et part d'un handle d'artefact local au transport, donc il
  /// ne peut pas vivre dans une sequence rejouee par les quatre.
  static const String backdropMediaId = 'media.tower_night';
  static const String backdropWideMediaId = 'media.tower_night_wide';
  static const String backdropTallMediaId = 'media.tower_night_tall';
  static const String lighthouseMusicMediaId = 'media.lighthouse_loop';

  static const List<_SeededMedia> _seededMedia = <_SeededMedia>[
    _SeededMedia(
      mediaId: backdropMediaId,
      label: 'La tour, composition partagee',
      kind: 'image',
      mediaType: 'image/png',
      container: 'png',
      codec: 'png',
      logicalPath: 'assets/presentation/images/tower_night.png',
      base64:
          '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'
          '/n/R8Dq7sstjCgAAAABJRU5ErkJggg==',
      width: 320,
      height: 320,
    ),
    _SeededMedia(
      mediaId: backdropWideMediaId,
      label: 'La tour, cadrage paysage',
      kind: 'image',
      mediaType: 'image/png',
      container: 'png',
      codec: 'png',
      logicalPath: 'assets/presentation/images/tower_night_wide.png',
      base64:
          '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',
      width: 384,
      height: 216,
    ),
    _SeededMedia(
      mediaId: backdropTallMediaId,
      label: 'La tour, cadrage portrait',
      kind: 'image',
      mediaType: 'image/png',
      container: 'png',
      codec: 'png',
      logicalPath: 'assets/presentation/images/tower_night_tall.png',
      base64:
          'iVBORw0KGgoAAAANSUhEUgAAANgAAAGACAIAAABA6DuUAABNIUlEQVR42u3d9Xcc'
          'R942fP/yPu+9a1kW45CGWTPSgJjRDDJIJpmZHVPsmJlJZmZmTsxOYjsOczbJZune'
          'fZ57z3nev2Dfq6q7B6SRLdmS1e1UznVypJmqjnrq429VdSvtdv8VnsTyJvOHjsnt'
          'I5LDImUdomTh0fKOMfKIWEVknCIqXhkdr4xJUMUmquKSVPFJKQnJJIkydZKcJFmh'
          'QWSIUiNXauUqrYJGmcJFh6jU/qQERvPCBLT0dcfRuOOT/5aS/HfJD0B/EvxICPfj'
          'xSNJKfiB4xLJTx6boIohIeeCRMUh5OwiY0lwphExCpwySbQ8XAg+inZMxptVmPTH'
          'iOT2DRXGBShMDK1QIEgUKhooDOHPT02PqEOFvlVfJDkOYa0VIJL/LgcxqSFEojCF'
          'V5jIK4yJDwExgocorwcRHwWD+KbzR64cBiqM9SlUNknhSwkK+NTNDI9SKIccxIbl'
          'MKnp5fCFEMMZRJFMyhgSqlDxAoXJL1JI6lYDgsG8tE1IkMVml8MGEJWvMC8ziG05'
          'KQcpTOAVxodSGDgdc4XwJQSpME2Tw3FsRjmUhSqHiUHlsKnzcrSMQXzjk3Jk8KT8'
          'igrrEwz016g2XUAag6h+/XIYal6Offm8zCC2waSMYhBigxJSYcB0HKIQvoCgTq8l'
          'MbwsvMsmlENNI+WwSduUl87LDOIbURhOJuUGS8MmKQxdCH0Tcb0puEn4gtLq5fCF'
          '8zKD2AaTcuilIXfJMFih70phYwobVsGGwnT6l4QoDFEOtY1dO3z9cviCeTmMQXwD'
          'exRuUvYtDesrTApUqGmokJuOQxMMLoEvxedPqHLon5RbpRy+aF7mICaztF7+GCEL'
          'i8QnjgHAeCgjMULxKjojo5xgODG0GGAMtoYq1MpIKdIpVDrhTokeSVFzV6QNai30'
          '0PD4jIhOXz/6wBiECK+gAXpxx8ExcWTuv0JvpZDgjwF+DPwwyQhZHWqSZBr8kAkE'
          'ojoeSVLTcpgSSxOTkEIhqqLjSaLiEHKmkbEkEVwIRJpoRTgf8rFwCYuSt/uvjsks'
          'IROdbIiVGdtHKV75CFDYHn/i8ac/RkE3KERhNKeQrAsx06kTMczcvTuMPalGOgUI'
          'qklU3EVmUrcoQR0fLSZWYAIpgz9+cEbTC4KWtC85Do6JgxOIGr0SENXkPy1HVBSi'
          'Upus1OJnQ/BDIgSijEJMVsclk1OITaIQSch5ccE5oihGxlOLccqIOAKxY6yCCz4K'
          'Lh3ItRs+DGLoJKntrpyKki79S7tWZxR0URldr3CQP9CrhviI8aF35BUqMU4xjSiU'
          'BygkJSpQYeME6+EzNB7SgHZBd6KQg0gVqgSFCk6hileYTBUmBSqUBStM4hXGBCuM'
          'ClRIIPIKO8aEgBjGIIZMvMKcV9ZryOjp0+evfGfB6hET55R2q1Ya0ptdDqlCfNAY'
          'gAi/QlVsYwpT6iukm+IXEgzpzxQqAQpDlUP6Kw5EIV8O/Qr5cqhu2XIYHiNnEF8S'
          'm7ugZtikJet2HDxz/ej526u37h82fpYnr1Mzy2HgpEwGxqcQo/hihaEKoZ9gYAms'
          'h8/YSAzCpKzTN7scJrZyOeTmZQYxRLwFncdMnb/j8LmPvvz5sx//cejMjWnvriis'
          '7BOZoG3epBwdOCn7FcYThWqyOxEUKnwKA6bjwEKo0wcRDPTXgJ2ZxCykQTnkDkuO'
          'rzc50z0uT5Y1NU3RWDmUhyqHSYHlUPXSctiUeZlBDBF3buXISXO27D35/kdfPnj+'
          '/Z5jlybNWpJf3rtjnPoVJuWgDQpVmCB7kcLg6ZgnqKtHsB4+s9nUSALLYeCkDIKd'
          'uvUYMHjokOGj+9YMLiyt0BosgeXw5XuUliqHDGJj0duzetaMnLVw7abdx7buOzl/'
          'xebqYRNTvcXNnZTx0fuWhoHb5HoKyWUa/6KQn475Qvhigo3g4/4JVKgPnpTN1tRu'
          'PasmTZuxdNXaNRu3vLdk+fDR4wtKKpq4RwlZDqNerxwyiCHSIUaVllXWo/8ILA2x'
          'U+kzaGxmYZdYmbG5kzK5XhNqm1xPIb81CVUIQxNsyM5SP1ShubFJOSs3f/iYcas3'
          'bD598cq1D+4dOnF6/uLlVdUDTVbna+5RGi2HL9ym8BD/gI9PTElKsemtGTprRqLS'
          '0lY/Q4doJX6A9KwyV065yZETnahrYkf6W160FnJ3k4VbyfSqNV8LubsmSv5+CT8d'
          'a7T0AjW57cGvBQ1GxGQ0Enz8P2b/PxZLw3D/CBXRRPoahHLI39Mj1yP1RaXlE6dO'
          '37n34KOnz3/75/+5/sG91Ru2DBo20pGeIaMQ6d0UWhH523rcdWzhtl4Sdx3bd2eP'
          'WiSXsn33VHxXswNvq/AJD7yzEnBNW0QQ20fKba788u4D+g4eizpU2rW/2ZEjtj8n'
          'Lwi5icL9WgNdGmJshF9o8CuUNa5QJyg0GJpI0GJFrAERIJp8m2Vqmt5KoeWW3ErR'
          '5xYUj54waeO2nVdv33n09FPUxSUr1/YfONSami5rVKFauK3nu6HCK4wJqTAuQGGs'
          'X2HQjeZ6d1bEM5AGW2b3fsOnzl22bMOupet3Tpq1uHPvIWqTWyIKfTeUOYXkN2u4'
          'X6tpTCG9a8zfrNMJt+N8hbAewSB/1qDYaKxWn0KyOiTlMEChrxyCvt3p6tNvwKx3'
          '39tYt3PHvoOr1m8eP2VGWafuCpUuoBz6bi4Hl0NBYWywQh9EQaEyojnlkIMoE0P+'
          'GKnIKuw2Zsq8LXtPXLnz9OL7H23YcWT4hNnunEqR/IQvTntyQxmfNRkDejcZo0Xu'
          'ySaQ+8jkpq2Mv4PM3TsmN3npLWPuZjFKF9yYKEGyvAMmk7D68/1DsAn/2LjY+Fh5'
          'hhYTAohGMy2HJhxZuLNsVPN3lg34ATKyC6r6Dxw1bvKEKTOGjhzXuVuV1e5KpjeX'
          '8dMiifzNZU1Cska4uUyCkwq4v5wSjcSnkPvL/C1mVSQX/y1mZUd/fHeZsV9R4OPi'
          'EkYCiBEyMSQiXlNQWTV17vKDZ65/+cu/nv/wt73HL014Z1F2Sff2UQqR/JCN5Y+R'
          'cn6Dwl8yTBFun9Cr1uQmMrmHK+yOuRvHRmFTIlyappcA+S2If+rlyh5Pj5dnJ7HT'
          'kK9tnEPSxbdN0XMQ+W2KUbiVYlAJd5ZtDld2XnFecbknO19rtAlXbUj4qzZky6yJ'
          '9+9UKET/hRsSAtG/ZVZFcvFtVvjbKnzCAzfOMdQiTRiJaCBiLDMLu46eMm/znuOX'
          'Pvj4wq0P1+84PHzCLFdOhdgVRvA3lOkdFKzcU+iFa6KQ7JFfoJBMnVQhdyE6JMFg'
          'f3Y+NiFCObQKCs1QaBauHZqIQgqRU0jKIf/7DXrh9xt0+PGEqzYcRN/lQz9EQaE6'
          'YMvMK6wPMS4AYoDCjo0opBDlIoKI6G2Z3foOmzxn6dJ1Oxev3TFh5qJOvQaTNaK4'
          'IbYn164VHcmveKn4izU+hYpghdr6ChsWQmEODiDor38UX6otlQZf22ibQIXGYIVc'
          'ORRu6BmEG3p6360Uv0LlCxUmCwqFchjdhHLYscnlUERTMxdLen5pt+qqQWN6Dxxd'
          '3KWfEbtmCU3K/CVDdTx/K5n+cmFohfx0HLoQBhD0+UtNDQo44l2fwnqTsi5gUlY3'
          'mJQVKXrhhh4gBioMMSnHteak7CuHooOIJKqsWotXY/HGK8wiV/gH36TsXxoGK1Tp'
          'FD6FumCFdDr2F8JGCAbiczj40HLYYFImCs0vXRqGnJRfbWnY1Ek56Gp26HIoRogS'
          'in9SFpaGZIPSJIX8dOwrhNx2JCRBwZ+dJkChTUxLw+ZPyoHlkEF8nUlZFhbN/3KN'
          '8DsN3DaZjC79FdcAhdxv8PsWhQ0KYUOCPn9OxEmCr5u7NGyoUNEsha+0NGxsUg6v'
          'r1ARfIuPqWqJSZlTKFNBnpn7ResghcLWpGEhfBFBJ580n8LGloaCQp0+1NJQHbQ0'
          'bPoGpclLw2ZPyvXKIQdRztLctI/ER4kPGoOB4cGAaeRqc0ZuSWW3qm5V/cs7d3dn'
          '5KZooQEsTHQ6hhWIIReczcK1GRjEP8JeBM64yRclMNXpJEkTglcoRDsth9xlQytV'
          'aMEx6dLQrDOYaTk0aXQmNZmUjfgBVKQcGpRqA1Wol6tIADFZSZKk0NGlIUkCItPG'
          'A2KyJo5LkoaWQzVOkEt0gppCTIlC4kkikThEFcElVtUxIOExSl86INH+hHEVkb+a'
          'rWgfpWAQmx26UyYKMQx0aahOUugLSjvXjhw/892F8xYtmzpzbvWg2uzcAr9CU4BC'
          '7tYIMRiaIO8vLTU9jfwbr9RXaIVCa6BCfYBCTUOFFKI8pUkK45ulMD5AYTDEQIX1'
          'IIaFhhgpZ2lW8AmGxyojsEHBNhlbS5nG4c4eMHTU4pXrDhw7dfL8pe17D8ya916v'
          'vv0tdoce8yZmT1QvzKT0xrDVTgmSedaeym1ByPyb6qTsiL90xIGkpZMX8S6a0UnZ'
          'ZqX3lXEcHM1othjMZr4cGk1ag0kDiHpShlMQTMpag1JDgj2TXE0gylLIvJys0iUp'
          'SRIBUaFNUBCI8XINgSjTxMkIRJxXLF0gxtBEAyJdIEYlUogJKZFc4lURvsSpOvqC'
          '1WFAOsRSiELCYhQk/DJR0Z6GQWxe8GcXHyU+dAwGRgjDhlHMLSofN+Wd7XsP3v/4'
          '2dc//Xzpxq1V6zfUDh/pycwymDmCFgu3L4ZCutQLQVDw53KRpDdUaLf5FXIQAxUa'
          'mqowuYHChJZVGMf7i5MbkjW2eIUpWKGyoUIGsXn5I5bVMUp81pGcwmSiMEnph3jv'
          'oydffv/jxes3KMQR3sxMfyGkCjmCqS8kyClM8yu011No8ik08Qq1L1eoD1SYRBUm'
          'vp7CyMYVRiao7Z6C4s59OvceXNq1f1p2KccxrJFyyCC+yqQc6ZuUsdlUaDG66Rk5'
          'g4Zhal6z/+jxE2fPb9+zd/a8+VX9+6Ho1ZuOOYJEYSBBwZ/bzSl0+JaGRGGqX6H5'
          '5QqNLakwqbkKVVwtdGQUVQ0cPXn24rlL10+bt7xm+ARvfqeO8erGFDKIzZyU6dIw'
          'Slgacgox0iqtsbSiy/Ax42bPe++9xUumz5o9sLY2v7DQbA0ohKn+QugjyPsjBJ1I'
          'PYVBS0MotNZTaBanQpnGVtmzZvq8ZdsPnjp19c7e4xfmLlnfs3q4xuJuTOGrQ4yV'
          'm5SGdLnOGZGg/V1Nyr6lIVGoJAox6hh+vcmaX1TSvXdVVb/+XXv0yMnLs1iDpuPA'
          'udhP0E0IemjcPoUNNyihFOpEqRDRWj0oh0vW1l16/8Mf//bv248/W1t3YOCoyTZX'
          'vk9hfYh016xobszp+cVd+nfvP7Jr32E5pb1STJ5XOIi0EhaNjxhLQwwSRg6jiHHF'
          'SJMrIypyvRAmCA4DsNjsdDq20enYTrfGgAVeQOaga0FUPidXAj3uNI+HhJZDZ1q6'
          'A83QGF3o0pDcy7NYbXRpaDWarTi+3mShClEOzdgmq/WmFJ2JKjQqNST4keRIioEq'
          '1CcjSj1ViA0KCX54sk0m12u0OJe4ZG0sgaiJTdLE0EQjZGmojkISSCK50Os1EVzi'
          'UjoGBB+OL2qTu2f1iPdWbEY5/OiLn8Bx5aY91cMmmtPywvhrN8r29RKlbDZEgyOn'
          'W78Rk2YtWbBq27zlm0dOfhcokzWOt1ghPqYOsagBqBAoG9wGRYdhbqjQaLEKCgWC'
          '3KVBKKxHkPrzvlSh7Y0rTHwthUhMsiG/ovfoKe/C3/aDZ9bVHZw0a3F5jwEybWpj'
          'CpsNMTxOgxI4dvqCzXtPnr/1+OSVuys27R04cprdW/I2l8MYTD2YnojCeE6hKoRC'
          'E1FI6IQshISgiyfopcnw+hWmt6ZCnmCrKFTVU4g/sR1iVFqrF5vlgaOmgGPt2Bmd'
          'eg+2COUwpEIC8Y9RiqYnVmEu6z5g5sK1xy6+/+1f/v3xV7/sOHRuzNT53oIuzTqO'
          'hMIvDYNrIdZhEAANkKEnv8Rg8U3H/GVqbjnI74g5f07iz0v8ZWakI14Ckd+j0HKY'
          'SiEK12tsvus1Vnrt2sIvDekehYPIrQ5VvEWDgqwODb7VIYHov3bNWeSuXdMQi2SB'
          'yFtM5iz6FogCRyJSWCAmBHAkCVojEpQBLuV6hzOjOKOgc3p2mdrkCriIGJCAmbp5'
          'ECMTdQWVfSbPWbrr6IXbH35x5e7T9TuODB0/My27/K1UiA9I2KAItRAzMtmdEIXa'
          'YIU2QSE3F3M7Em4vUo8gElAOX1shv0GhCrkNyusoTFQHF8VXUUhLY8MbKo0qbDZE'
          'xO4t7lc7Yc6S9WvrDq3csm/ynGWdq2rVZs9bCbEDvaEsbJMDZmQ9mZHrKwxdCIMI'
          'ZmXWV5j+egqVDRWqGirU+hVykzK/U/YpDCqEgsKUJioMDzFBN0/hq0CMTja4cyu7'
          '9x8xcNTUmuGTK3oOsrgK3tZJmd5QpvfxyCXD0ArJ7y8ETMf+Qkjn4kCC2Vm8Qu/r'
          'KRQu1vgVyl+sUB6oUBOo8AXTcVRogikRcS2v8FUg0jqRghJodRea0/PlOufbPSlz'
          'S0NyyVCt9+1OiEJLfYX+TYmvEGak+QhmZ7kyM19RodbQHIUcwcYVttKikN+pvJJC'
          'ckH7j1FKloYJj03hrhrGC5cMsS0VFHKXabhrNGSf63RinedMJwTpRRkvwHFV0AV/'
          '2Vlu/Btf40WvJx1t6DbZSbfJDrpN5n793063yTZhm2yl22SLlt8mm/Ffp9tkk0pr'
          'Intksk02CttkQ7IKwR6ZJFGh922T47nwMzK2yXxignbKJFFI4E6ZbJbVEf4EXbIh'
          'V23IhRt/OvAQya7Zl7B6iebTPih8RWTs6gcfGT56jA1GLlGJYkMUpjSmMM13gZAo'
          '9BGkCt052VDoJgozXlGhJkChiig0BiqUvVShTBfnv1hDCQoKo5MCCNZT2ByCfoVN'
          'IBjWgCCDGDp0Uk7BwGDk6AbFoAhUaPYr5C4Tcgo9bsy5XCHkCLpAMLfpCq2NKlQH'
          'KuSvF1KFlKCMEqTXCwMUyusrDCiEoRS+ViFMeZ1CGAAxWskSGHzQkYnqWBl2mrpk'
          'crGGKNQYhVpos1lT7XYo4m6WoBB60jxY+WFHkpmehYk4mxLMIcnOduMVotCbjmYu'
          'N5m+nekO9E11puIgWF9a7HYc02S1Ga1Wg8VK14UWncmiNVKFBCJVqDMpUQu1RrvL'
          'W1DWqaJb75LK7u6sApnakIRaqNKjcmNdmKAktTBewc3I2jg5VSgkBuvCZE10MlWY'
          'pIniQteFkVwS1BEB6QiFAQmPpwoD0iFORRLrT1i9BHBsHxRlvTCIQcFnhwHAaGEs'
          'MbpQCAEaQ2iFgOXmVoREoSsriyeYl+vBv3NeptAaqNBCFOrNhCCphUa+FqYEKFRo'
          'jWnenF79Bo6d8s6MuQsnz5xbM3R0bnGlX6HCrzAuWCGZjjmFSQEKAwnWV5hSX+HL'
          'CL5A4YsJkrCKGBh8IvjEMUgYQowuVmCcQp2gkGyQubt2LqeL2xoHFsKcFylMC1Bo'
          'c9ipQltDhVq/QhMUqnR0Uagli8IUg6WyR9WUme9urNtz4MSZHQeOzluyqt+gEXZX'
          'lr8QKl6/EKa8uBB2aE4hfDnBGDY1h5qUo+ikTDYoagOGXx1KIb87JldnSCHMDiiE'
          '+XkvVkin4yCFVqLQ7FMYejqGQrnGYE3z9hs8fMnqDWev3nz+9Q/vP3y6ZffB0ZNm'
          'ZBWU1yuEsU0vhMFzcUTLEWxiIWwvfPiAqGJBwmJTIhIwZlgaYpuM4TdhZtSZAAVi'
          'yP9sl+p0OMk1mjS3J51Ox5iLySowJ8dDCXqR3FwPVejGu1RhusudRhSmoTP/oAar'
          'PZXOyHZaC21EocmK/xBqocZggcIUzMg6M1VoUiAak1xtlKmN1rSM6iEjl63ddPHG'
          'nW9//dv9p5/V7TsyZvKsrKLKeIWeKsTWRBdLE5Osowq10UgSSRRCtyaRviRoInyJ'
          'x4rQn3AkLigdOIix/oTVS4w/7f1RhQ7drwR+/gwiH3z6GC2MaHIKtskvVuiiK0JU'
          'PtQ/KPQWvEAh2SOT/zPZr5AQtButNoPFpjfzBHmFZFEIgmZypZAjiFpIFeLPhtqY'
          '2qV39Yx3F2/fd+TUpRsHT15YtHpTzbCxqd68OKow1q+wAcGkxgkmtBjB9q9EkEH0'
          'p0OcmlyvkWODQhRCA2QYAhTCk4tcJiSFMDOTFMJcoRAW5GcQhTmebEGhhyqEWvRy'
          'BCgMLoR+hbQQUoWkEJqVPoUCwWR6pRA/mzunqO+gEVNmLZi/dM2s95YNHTO5oKJ7'
          'coo5LphgTBDB4ELYVgQb8ccgBk3KGB6MYqLSgLGHhtAKhemYrgg5gt7CggCFmYJC'
          'd1qwQmyQXzgdN14Ik6nCJKoQPx4Wr86MgrIuVd36DO7UszqzoEKpTw1JMPo1CHZ4'
          'RYKv4i8AYozqd56OCeoYmTYBGxSNUYVaaKIK7XYbd5kGG2Rud0y2xnRFmOfJpwSJ'
          'wnwyI2fnuDNRCzOJQjROd6c5XU5HOjbIDlugQpvNYLXpLVad2Yr/isZIwi0K8d9V'
          'CotCKMRPQhSqDUkpJIlQqNLjJ0TilfqkFKPKkCrTWmMxHct1MVCIfYmMzsU0Ucla'
          'bmscySVRE+ELCAYkPIEqFNIhPoUkzp+wehEgtg+Kqn6owmaNwu8dIj53DBtGN1lt'
          'VJIL11BoDVRIFoWYjqEwx53LzcUF3qLCegpdQQpJLSQPEOEU4mgmm7AoDFBICBoI'
          'QbIv0VGCWqNcIJgcSFDFE8QSNk6hQziCsW+MYGxIgi3gzw+x0UXl7yCYcTBm8eQO'
          'CrlkSGdkK6qXnbuDzE3H9JYxnYs9mIuLCjKKizLxb3ydx+9OXMK6EDOyk87IvloY'
          'dMmaLgotWhO3NTELM7JJWBTyCmVUITcjJ9KL1aQWYl9Mr9HE+XfH9AKNTBuwNQm8'
          'TOjbmgRfoGk4KQdfpulQLyGm5tCXbF5zLNq1r7/SfGsTq7CkmL1InMrKvRJBl4ZJ'
          'KqNSa8ZaDRsIs408EMlJFoXpHi+3L/Hk5pJNMUpgcWFmSVFWUUEmNijYLGPXLOxO'
          'XGiPdSGthU5SC1Md2CDjaHSDbKcbZBtdFFq5rUmK3qLityZmuijE1sQkLAqN+JG4'
          'RWECojCQqzOohXIamT7gAg1JNOLbl5B1oTaST+CiUNMRifcnPHhp2KFeYvmE+RNi'
          'mdiCo/N7gah35BZ27tejZlTPAaOLu1ab0gswDBhFDDa5WGOw6IlCu08hvUZDLtCQ'
          'qzP5GcBXUsQrzM/LAE0ARQPM2h5ymSY9jSpMpc/TpBvkVDN3mYZukAlBk1XDKdRb'
          'uK0JIcjvjk3C7rgZBIm/5MCtsc+fNnhf8iJ/4S/xF3qP0hoD9LuAiCpY2WvIuBkL'
          'F6yuW7hm+8RZS7r2G2515WK+AwLIqK+Q2x3TrXFhPimEpcVZVCG3R/YrFC4WpnEb'
          'ZJvDQbcmqXRR2GghBEFhdxyCYGIDgrENCSaFJNhoCQznCL7QX6PFr9Xw/e4guvM6'
          'D5swe+32w2duPDx36/HG3cfHTp9f1Kk3BKToyIVrcqUmWCFdFPKFsIwozPRfqcly'
          'E4VeF3ex0EkVctNxiEIIgsbQc7FMmItfSFDXXILNmIJf5u9NjlG79vW34m9bOsRr'
          'cst7T5y9ZO+JK89/+NuXP//r8Lkbsxet7NZngN7qwB4W1cvmdDjpBplsTTAdk61x'
          'RlERKYRlpdk+hTm5nqxsepkmw+WCQrpBTqUKrY5UC90gG212eo3GRnfHPoXcBRoz'
          '3RpThRpsjY1JUMhvjclcHE+3xnFka6znL83wV2d00TIdvykm+2JtJJ+ATXEiJSgk'
          'PHhf3MEXQWEYn/q747YaprcfIpJR1G3U1Hmb9568dv+TG48+23n4zPR3F3fp3Q9c'
          'TFwthEJug0wuE9J9CQphSRZSTBXiRczUvEJymYYsCh1EIT8d+67R1CdoaDJBRTDB'
          'AH/R9f1pI5vgr0MDf2LD97uDqHfmdK8ZOW3+qlVbD6zfcWDe0rW1o8cXlFZgGedT'
          'mMktCvO9RdgaF2eVl2ZzCguoQgBFA7Io9Kbz16sDCmHAipASNFnURhC08AS5a4QN'
          'CCbUIygPQbB+CQz0lxjsr1nFT3xjBIjqtz5hcZrUzLJOfYYOGj1t2Pjp/WtHlXbu'
          'bklNsxKFaW5skLPINRrsjouLskpLsivKcspKsvF1QX4mv0HOctPpGK3TneTZ1k6b'
          'w2lNdZjJviTVYLXrLXad2cZtjVMMVpXeotRZaCE0yzVmmcaUrDYlpSDGRJUxASEE'
          'DXEKklhCUB+DyPTRCF0LRiFJukg+2ohEPh2RBD7hCdwuhKSDL3EkYXwEhaIfo98F'
          'RC5KkyctuySzoNyVnWew2OsrJPsSsiKEQlgsKszKzyeXabKyPRmZbnKlkJ+O0+xO'
          'J/pa7A4QNPoJ2kBQbbCSTYm+mQRlHEHBX/KL/BF8CW2JL05lM7sK03Ir8WcbHymD'
          '2OxgXEEBSrCMQzFDYQOvLLI1ySgkF2iyy8tyiMJiKMyEwpwcL4x6M9zAmh5QCC20'
          'EJJNSZMIGhM5gkoj/MU3UgKjgkpggL+El/h7w5VPpk/Pq+jTb+ikYRPnDBozo7Kq'
          '1uwuZBCbEYwfBIAI6FiCFaL4YSKuLCcKsTosLMjEi9lEITcdoxCm+wphwFzcOEG1'
          'QPDFJbD+FNyIv5fhe5MrnIyi7rXjZy1au2PzvpNr6g5NmrOsovcQhdHdEhBxJr+D'
          'oPzItCat2WZOTXW40iAM+4987I6xLynL7lSRW04VFhRm5uZ5s3I8GVlud4Yr3ZOO'
          '6Ts13WlzOiwOh4kWQr3VrrPYNCarmiwHLSqDRanHjsSMTTGpghpTkppUwYQUY7yK'
          'ElQaYrEXVtASKKdTsEwXJaNTMIk2IolPRzoFhydqSGgJ7MCFEgwjUZO00WeYpHNW'
          '9qmdvWTD4fO3Hnz6w+U7T1dvOzhw9HRbRsnrH/x3ARHjnaQ2qU1Wv0JuUViSVVGe'
          '06kyF0tDiITLnFxvZrbHm+l2ecm+hBTCNFoIUwMImgWCeotCb5brzCBO/QkE4U9F'
          '/HEEYyjBaEqwob+Ogf7Ehy8wcqOra/WI+au2nr356Ie//997n3y3ac+JoRNmO3Mq'
          'WgSi5u1OeIIW8yN2sia7w5Ge7slw5+RiUYjdcU5lRS5qYVlpTlFRVl5+JnRmZHnQ'
          'IN3jcrrS7WlpVqfTnOow2jEXp+osdhRUtclGN8VWhc4i11lkWnOyxgyCiSmmhBRT'
          'vAoLQWOc0hiLWVhhiJEbohGZPgpJ1kciSboImo6JJOHwR+ZfbQcu8SRhJISg2D7J'
          'WJWtuNuAyXOXbzt49syNhwfP3lywpq5P7QRjev7rH/zthwgQSr3FaEtNxbowkygs'
          'IrvjnM6VeYCIDTJQ5uZlZOV4vZkerhCipc1JNiWwW4+gkiOotcg0AQThT/UifxGh'
          '/Pnw+eSFif7DtHpLeg4aO2nu8nkrt85cvH7w2Jk55b1jlNYWgBjmX/y+hYlO1mMD'
          'AUyYZDHhYhdSXJRVUZbbtVNeZXkuNsjYmuTmZmTSQujyFUKH02x3wC53aUZj5Kug'
          'UmfB0QhBekWGJ4jtML8RIQS5jTD8+a7CRCSSBFx/0YbHc8WPTr6S+jzDE3Q2b0lx'
          't5qu/UdU9q71FnZL1qW1yJElCfGdlVu3H79w9f6T59/9/Ms//g+CL/AtXsRbAZ+a'
          'FmKAKTWNV1hSTPYlXTvlY4MMkfmYjnO8GZkeNwqhi/xtT7bQBC20CgYQ5C/HGF/m'
          '723A1zCxKqvc4ErSOlvwmJKEOGv1th0nLl57EAQR3+JFvOVrBihak83udHoz3Pn5'
          'GZiFMR13qcwrx6KwMAsus7LpipBuSvi5mBLUCgQxpyu0FnmgP1WQP3oVkM6/DYpf'
          'IL63e9ppIYj81kwC+c+l/P/c6PKfO9X/eTzqP8+m/+fLhf/5ft1/ft1Fgi/wLV7E'
          'W2iAZpfyU4xW8EItzC/ILC/L6do5HxBLS7MLCjNz6L4EK0I6Fzu5SzPYFNO1oJUj'
          'SLfDWAiaEtUmei3GSHfBBuyC6RYYS0Cy/41Ipou/JG7nyy3+yLZXQh+sGNIujF8s'
          'SyDNhWhxQKGnoDCrojy3e5eCyoq84uJs7I6zsr3uDHea22VPT0Mb7Ej01lSt2a42'
          '2lQGq0JvxV6EbkTMdCNsorsQI7cFiZIZIvn9h75jErfz0GHlhG3H65waNqQygytB'
          '45DQcLRs3maInkwPdsSdKvKgsLwst7AoC1tm0Ez3uFLT060CQY3ZnmK0YTtMLsdo'
          'LPCXWM+fDP7q4+vw2vi4dEwy2DJKi7rVdOk3vLzXYFdBl0Stg0F8qyAWFWV36ZSP'
          'Gbm0NAf7ksxsr8vrdrjSrU5K0JKqMdlVBhtKoExrSdIE+fMVPz++FpJXL/bMst6D'
          'x02eu3zeii0zFq4dOHpGVmnPKLmZQXx7IHbrUtCpMg8cs3MzsClxUoJGu0NnsatN'
          'fAlMDvDHFz/gS25dfL5gLi7tOWjqvJV1h86dvv5w/+nr81duhUu9M49BfHsgYjpG'
          'IfRmeZxul9WZZrQ5tHQWVgT44yZfrvgBHzfnvrEzSrFm9Bg4ZuHaHedvf/TjP/6/'
          'D558s37XsSHjZqZmlf/+IOJPvETSXIhZud40r8ualmawk4Wg0mCV6SzYAmP/G6sk'
          'k2+kTN8xWReepOuQ2DZnpDB7ulaPfHfF5mOX7jz6/KdLd56s3HpgwOhp1owSCY1L'
          'iwQQdVJJcyGiCuqtjhSjXa6zJqrNcSpTjMIYKTN0TNaHJ+rFcEYRMlN2edXwyfOW'
          'btyz9cCZNdsPT5q7vKKqVm7ySGhcWiRvM0TsQuAvVmmKkhN8HRLFeFIqa2Zh15qa'
          'UdNGTp0/ZPysTn2HWbzFvzeFbwhiii3L4i0xe4pf8w96cyF2TNJLYgwSdWm2zFJ3'
          'YVdHTiVc/g4VtjrESLk5Pb8LlkEDRk+vHjmtss9QfOJvDOLvc0QZxBCxZZb1GTpx'
          '5uL1q+sOYRk+Zd5KoNQ6chlElvoQsXJqpUTKTQVd+k+cs2zHkfM3Hn125d6zjXuO'
          'j5gyz1vc7dUO2FyIrXdqLC0eQNS3UuLUqWW9Br+zaN3Rix9889v/PPvuL3tOXJ4w'
          'e2lORZ9XO2DzIepZpJJWhBghM+V16jtu5pKtB05f/ODJ2ZuP1+44MmzSXKzKGUSW'
          'NwcRwU65x8CxU+atWrJh96J1O8fPWlLZZ5jansUgsrxRiIg9q6y895Cq2gm9Bo8v'
          '7j7A6Cp85UMxiAziayVJn65z5mpSc+I1jtc5DoP4VkNMMkglzYYonVNjYRBZGEQG'
          'kYVBZGEQGUQWKUPkMmvVts2Hz5y+ef/+J1999afffv3v/0HwBb7Fi3gLDdi4ShBi'
          'slFamb2mbsvhs2du3b//PBji86/wIt5CA8mdFIv0IM5Zu33rkbNnbz14AIg//4WH'
          '+PNf8C1exFtowMZVehDDk43Sytx1O7YdPXf2NiB+HQzxa7yIt9BAcifFIj2I767f'
          'WXfs/LnbDx9+GgQR3+JFvIUGbFwZxFbPvA27th+7cO59AvFrAeLXHMT3H+ItNGDj'
          'KkWIJmll/sbdO45fOP/+Ix7iP/8H4SDiRbyFBpI7KZZ24TKTtLJg0+4dJy5e+ODR'
          'o8++CYSIb/Ei3kIDyZ0Ui/QgLty8Z+fJSxc+eBwK4mO8hQZsXBnEVs+iLXt3nbx0'
          '8Q6F+IsA8RcCES/iLTRg48ogtnoWb9m3+9RlAeJfBYh/5SDiLTRg4ypFiGZpZcnW'
          '/btPX75098PHn38bCBHf4kW8hQaSOykW6UFcuu3AntNXOIjfCBC/ESDiLTRg4ypB'
          'iHKztLKs7sDeM1cv3/2oIUS8iLfQQHInxSI9iMu3H9x39urlex99+EUQRHyLF/EW'
          'GrBxZRBbNxMWrl2x49C+s9euEIjfBUP87gqBeA0N0IwNrcQgdpRbJJRJi9et2Hl4'
          '/7lrV+5/zEH88z//588+iPc/xltogGbSOi8WiUGcvGT9yp1HDpy7fvX+xx8B4q8C'
          'xF//im/xIt5CAzRjQys1iAqLhDJl6YZVu44cOH/96oMnH30JiH8TIP4N3+JFvIUG'
          'aCat82KRGMSpyzau3n304IUbFOL3wRC/x4t4Cw3QjA0tg9iKmbZ805o9xw5duHmN'
          'QvxWgPgthYgX8RYaoBkbWslBtEoo01dsXrv32KGLN689fPpxMER8ixfxFhqgmbTO'
          'i0ViEGes3LJu7/HDF29dB8SvgiF+9T1exFtogGZsaBnEVsw7K7eu33fi8KXGIV66'
          'hQZoxoZWahCVVgll5qpt6/efPHLp9o1Hzz7+6odgiD/gRbyFBmgmrfNikRjE2avr'
          'Nhw4efQygfgkGOITChFvoQGasaGVHESbhDJnTd3GA6eOXn7/xuNQEB8D4vtogGbS'
          'Oi8WiUGcu3b7poOnjl15/+bjT558/cO3fxYg/vlv+BYv4i00QDM2tAxiK2ZZ9eAN'
          'w0fvHD/p4LSZJ+e8e37BwsuLlyL4At/iRbyFBmjGhlZiECNUNgllWc2QjQTi5IPT'
          'AXHe+QWLBIiL8C1exFtogGbSOi8WiUFcLkA8FAriIQHicgZRghDtEsryAUM2jRiz'
          'a0KjEPEWGqCZtM6LRWIQVwyo9UOcGwxxrh8imrGhZRDfAMQph6bPCgVxFt5iEBnE'
          'Vs/KgbWbR47d3ThEvIUGaMaGVmoQU+wSCg9x4pTDM0JAxIt4i4coqfNiAcRUCWXV'
          'wKFNgYhm0jovFgaRhUFsZhZUVa8aBIjj9kyc2hhEvIUGaIbGbHQZxFbJwqqa1YOG'
          'bQHESQTiqWCIpziIk6aiAZqhMRtdSUFUp0olC/vUrB48bMsoH8T5wRDn8xBHjUMz'
          'NJbQqbG0i1Q7pBIKcTgH8UgoiEf8EIejsYROjUVKEBf1GbBm8PCtHMR3QkF8h0BE'
          'AzRDYza6DGKrZNqyTSt2Ht5z+vK52w/vPP38k+/+9P1v/+B+HxFf4Fu8iLfQAM3Q'
          'mI0ug9gqmb5880oC8cq59x/effrF82CI+BYv4i00QDM0ZqMrKYgah1QyY8XmVbuO'
          '7D1z5XzjEPEWGqAZGkvo1FgA0SmVvLNyy+rdR/eeuXr+/Ud3nwHiz8EQf8aLeAsN'
          '0AyNJXRqLFKCOHPV1jW7j+47e/XCB41CxFtogGZozEaXQWwliNvW7Dm27+w1aLv3'
          '7MuGEPEihXgNzdCYjS6D2CqZtXrb2r3H958DxMcE4vfBEL/nID5GAzRDYza6koKo'
          'TZNKZq+pW7f3+IFz1y/eeXzvky8//f7nH/7CQ8QX+BYv4i00QDM0ltCpsUgJ4py1'
          '29ftO3HgPCB+eN8P8d8IB/E+gfghGqAZGrPRZRBbJXPX7Vi//8TB8zcu3W0UIt5C'
          'AzRDYza6UoIYpU2TSt5dt2PD/pMHL3AQv/r0+1+CIf6CFwnECzfQDI0ldGosUoI4'
          'b/3ODQdOHrpwk0B8HgricwIRDdAMjdnoSgqiLl0qmbdh18YDpw5dvHn53kcPQkHE'
          'i3gLDdAMjSV0aixSgjh/w65NB08dFiB+9gMg/rcA8b/xLQcRDdBsPoPIILZS3tu4'
          'e9Oh04cv3bpCIH4dCuLXeAsN0AyN2egyiK2SBZv2bD505ggg3v/4waehIH76Nd5C'
          'AzRDYza60oLokkoWbt6z5TAg3oa2h6EgPuQh3kYzNJbQqbG0i9K7JJEJC9cu3Lx3'
          'y+GzRy/fvto4RLyFBmiGxugilbNjkQzEiYvWLdqyb+sRCvHBEwrxVwLxX/9GKMRf'
          'CcQHT9AAzdAYXdgAM4gtnEmL1y/eCojnjl15n0L85vNgiJ8TiN/gLTRAMzRGFzbA'
          'DGILZ/KS9Uu27t92lEC89uDJo8+++fzHYIg//ooXr1GIaIbG6MIGWDIQo/VuSWTK'
          'kg1Ltu2vO3r++NUPfBB/FCD+GAARDdAMjdFFKmfH0i7a4JZEpi7duLTuQN0xCvHh'
          '00YhPnxKIB47j8boIpWzY5EMxGnLNi2rO7j92AU4u+6D+FcB4l95iNcpRDRDY3Rh'
          'A8wgtjTE5ZuWbT+4/fiFE9fuQNvjz79tCBEv4i00QDM0Rhc2wBKC6JFEpi/fvHz7'
          'oR0cxEfPGoX46BkaoBkao4tUzo5FMhBnrNiyYsehHScunrx+50bjEPEWGqAZGqML'
          'G2DpQDR6JJF3Vm5ZufPwTgLxLgfxix//HAgR3woQ76IZGqOLVM6ORTIQZ67aClu7'
          'Tl46BYiPG4f4+BkaoBkaowsbYAaxxSFuW7XrCIF4497Nx598CIg/BUP86c94EW+h'
          'AZqhMbqwAZYQRK8kMms1gbj71GUe4hffhYD4xXccRDRDY3SRytmxtIs2eSWR2Wvq'
          'Vu8+CmGnXwbxNIWIxugilbNjaRdj8koic9ZsX7Pn2J7TV07fvH/zQx/EfwoQ/8lD'
          '/PATNEAzNEYXqZwdi2QgLqsevK525NbR4/dMnHpo+szjs989M2/BhYWLLy9ZiuAL'
          'fIsX8RYaoBkaowsbYAlBzJBEOIjbBIgnQkE8IUDc5oeYwSKJSAnieg7iJB7i2WCI'
          'Z30QJxGI6xlEiUE0Z0giy2uGrB86ctuYpkEcMx6N0UUqZ8ciOYgTKMRZjUOcRSFO'
          'YBAlBzFTEqEQR9UFQpy/4KIAEV/gWx/EOgJxFIWYySKJSAbiigG1AsRpL4M4jYOI'
          'LmyAGcSWzILe1VC1YRgP8fCMRiHSvwWNQERjdEFHNsYSgWjJFH8WVAkQx07Yy0Gc'
          'EwriHAIRDdCMh1hVLYkTZJEGxIVVNSsHAuLourETmwZxIhqjCzqyMZYGxFhLlviz'
          'sA8PcXvTIG73QexTI4kTZJEQxKEbh1OIk18GcTKBiMbowiBKB6I1S/xZ2GfAqmCI'
          'J0NBPBkMcRWBOEASJ8giDYiL+goQxzUN4jgeIjqyMZYKxGzxh0AcBIhjIGzfyyDu'
          '4yGOQRcKMZtF/JEGxOnLNy/ddmDrkbOHL966eOfxnSefP/n6h69+/stPf/vnb//6'
          'N4Iv8C1exFtogGZojC7oyMaYQWyxzFixeWndgW1Hzh2+BIgf3nnaOMSngPghmqEx'
          'uqAjG2OJQLRliz8zVmxZtv3gtqPnjly6dekuB/HHUBB/xFtogGZojC7oKIkTZAHE'
          'HPHnnZVblm8/WAeIl29zEJ+GgvjUB/HybTRGF3SUxAmySAPizFVbl+84VHfs/FEK'
          '8e7TLxqDiLfQAM3QGF3QkY0xg9iCELet2HFoO4V4+e5HL4aIBmiGxisIxG1sjKUB'
          'Mc6WI/7MWr1t5c7D249fOHbl/cv3Prr77Iun3/z4dTBEfIsX8RYaoBkaows6SuIE'
          'WdrF2XPFn9lr6qBqR3Mg7qAQ0VESJ8giGYirdh3ZceIihF2599E9P8R/CRD/xUHE'
          'W1c4iCcuoguDyCC2ZOas3c5BPH71gyv3P7737Mtn3/zUECJexFtogGYcRHRkY8wg'
          'tljmrt2xevfRnc2BiMbogo5sjCUCMTVP/Hl3HYV48hIP8RMe4p8EiH/yQfxEgHjy'
          'ErqgoyROkEUiENfvXLPn2K6Tl05cu3PVB/GXYIi/8BDRAM3QGF3QkY0xg9himbd+'
          '51pAPEUhPnhyn4f412CIf8WLeAsNCMRTl9BlHoPIILZUJixcO2/DrrV7j+8+dfkk'
          'D/GrZ9+GgvgtIH6FBmiGxuiCjujOhlkSEPNFnomL1s3fsGsdB/H63Wsvg4gGaIbG'
          '6IKO6C7+c2RpF+/IF3kmLVr33sbd6/ad2HP6Cg/x+VefhIKIF/EWBxGN0QUd0V38'
          '58giBYiL17+3afd6CvEUID58+oBC/CYY4jcUIt5Cg1MUIrqgI7qzYWYQWyCTl6xf'
          'sGnP+v0n9p65cuqGD+KfQkH8Ew/xxl00Rhd0RHc2zJKAWCDyTFmyYeHmPRv2n9x7'
          '5uqpG/euvwzidQLxHhqjCzqiu/jPkaVdvLNA5JmydOPCzXs3HCAQT/MQv24c4tdo'
          'cJqDeAAQ96K7+M+RRQIQpy7buGjL3o0HTu07e/X0zXvXHz198KkA8e8CxL8LED/9'
          'Gg3QDI3RBR3RnQ0zg9gCmbZs06It+zYeBMRrp2/ev/7o2UNA/C4UxO/+9JBAfIZm'
          'aIwu6IjubJglAbFQ5Jm2fNPirfs2HTy9/+y1Mzfv36AQn4eC+JxCRAM0Q2N0QUd0'
          'F/85srSLTysUeaYv37xk634C8VxzIJ4jENER3cV/jiwSgDhjxeYl2/ZvPgSI18/c'
          'ahrEW4B4HV3QEd3ZMEsAYkJaocgzY+WWpdsObD505sD562dvPbjx+BMe4q/BEH8V'
          'ID7+BM3QGF3QEd3Ff44sgFgk8ryzcuvSugNbDvMQbwLiZ988/+7nUBB/xls3BYjo'
          'go7oLv5zZJEAxJmrti6rO7jl8NmD52+cvU0gPuIh/i0Y4t/w4iMO4u0HaIwu6Iju'
          'bJilADG9SOSZuWrbsu0Htx45e/DCjXNNg4hmaIwu6Iju4j9HFglAnLV62/LthwSI'
          'D29+SCF+//O3wRDxLV4kED8ExIccRHREdzbMkoBYLPLMXl23fMehbUfOHbpwE8Ju'
          'ffgc2j4NBfFTChEN0AyN0QUd0V3858giBYhr6lYA4tFzhy7ePP9+kyCiGRqjCzqi'
          'OxtmKUB0FYs8y6oHrxkyfNMI8rjYveSvnZp5fNbc0+/OP/fewouLlvBPjF20BN/i'
          'RbyFBuQvFhg3EV3QEd3Ff44skoG4eeTY7eMmNQfiJHRhECUEsUTkgaS1Q0bwECc3'
          'DeJkHiI6UoglLCJPu0RXicjjg7ijORB3BEAU/zmytEt0l4g5C3pXL6sZsrY2EOIs'
          'CvG9UBDfoxBn+SHWjkB3HETkp8kieohV1ctfDyK64yBspMUPsVTMWUghriMQx8EW'
          '+UtWAiBeEiBeCoCIBvt4iOPWUYgLCcRSFjFH/BBrKMSRfogzZh2f3TjE2XO5v/NH'
          'gDiSQqxhI80gvh7EPjUrBtTC0xZAHO+D+C6BuCAY4gIOIv+XT6HxFgoR3XEQNtKi'
          'h+gpFXP8EEeN20kgTm8axOlojC5+iOI+TRZALBNzFvYZAEnrfRCnNA3iFB7ieh7i'
          'AJGfJovYIS7iIA7lIE4OhHg+GOL5+hAnE4hDCcRFDCKD+LoQ+w5YOZBA3BoC4qJg'
          'iIvqQdxKIaI7DsJGWuwQk7xlYk5IiCcah3iiEYgiP00WQCwXcxb3HUghjto6mkDc'
          '3zSI+zmIowFxFLrjICI/TRaxQ5y+YvOiLfs27D+55/SVE9fuXL730QdPPv/oy+8/'
          '++HX7/7895///r+530fEF/gWL+ItNEAzNEYXdER3HISNNIP4WpmxYsvirfs2HPBD'
          'vEMhfh4K4ucU4p1AiAdOojsOwkZa9BAzysWcd1ZuWbJ1/8YDp/acIRCvNA3iFQ7i'
          'mSvoiO44iMhPkwUQK8Scd1ZuXbJt/8aDp/aeuXryOiB+fOcphfhjKIg/UohPAfFj'
          'NEYXdER3HETkp8kidogzV21duu3ApoOnKcS7V+4TiB83DvFjDuJ9QLyLLuiI7jgI'
          'G2kG8TUhbltaRyDuO9tsiOhCINYB4jY20qKHmFkh5sxavW1Z3YHNhwDx2qnrd6/e'
          '//ju0y9eDBEN0OwUgXgNHdEdBxH5abIAYqWYM3t13bLtBzcfOkMg3hAgftU4xK8E'
          'iDc4iGfQHQcR+WmytEvOrBRzZq+pWw6Ih8/sPweI964+eHL3WQDEfwgQ/xEA8dkX'
          'aIbG6IKO6I6DiPw0WcQOcc6a7cu3H9pCIZ72Q/yhcYg/cBBPU4hbCMRDOAgbadFD'
          'zOok5sxZu33FDkA8u//c9eZDvI6O6I6DiPw0WcQOcS6FuPXI2QPnr5++ee/agyf3'
          'KMQvAPG3YIi//f0LChEN0AyN0QUd0X0ugyh+iFHWDNFm4sK1c9ftWLnzsADxPoX4'
          '5RMC8c+hIP75CYH4JYV4n4OI7jgIDiWGM4pJzYl3FSZllsnzOquKuqvLqnSd+hu6'
          'DTT1qrX2GW7rPzp1wDjn4IlptZNdw6a5R8zwjJrpHT0rY+zszHFzM8cj72YJwdd4'
          'MWPsnIwxs72jZ3pGvuMaPj196JS0IZMcA8fbq8dY+4409x5m7DFY36VGW9E3paSX'
          'oqCrLLsi0Vscl5YXZcsU1Vi3i7J4RZuJi9a9SyFuO3LuwPkbZwDx4VMfxO+DIX4f'
          'CPHh0zME4g10RHccBIcSwxlFWzPinHmJnmJZdrkiv0tKcU9NeR9952pjt0FmatHe'
          'f1RqzVjnoAnwBFWu4ZTjyHe8nMgxs33xjpmFVyDVM3KGe/h017Cp6bWTgZhTaOs7'
          '0tJ7mKnHYEOXAdrKfurS3qrCbvLcTkkZpfHpBTGp2WIb63aRZo9oM2nxunfX71y1'
          '68i2o+cO+iB+QiH+FAriTxTiJzxEdEFHdMdBcCiRnFS0LRMWEzzFyVnlirwuqqIe'
          'pC5W9jN0HQA35t5DrX1GkNJYMxakSHWEyNop6UOnokbCpT/4FvhQAmsnpw2eBLuo'
          'pjzBquGmnrXGbgNBXFPRB7VQWdBNllNJFLqIQhGOtcghrp/ng3jhxplb969zEL9u'
          'HOLXBCKaoTG6cBDnEYjrxXNemIlinbkJbjpH53aCkpQSUhrJNN11gLH7IHPPWkvV'
          'MGvfEbZ+o+zVBCWQwaWQCfwXA8bhLeCz9x9N/PUZDsemHkMMlCCmY1IIi7qDezKZ'
          'kUvi0vNj7NniHOt2kSa3aDN5yfp5G3ZBUt2x84cu3Dh760HTIaIxuqAjgbhhFw4l'
          'trOjpZFyzCiVZVdiplYVdleX9NKUkwIJSQRlt0GkTPYcYu411NIbGQagJL1peg3F'
          'hA55pu6DUP8MXWpAmfOXUtxDWdAVylF3sRKIT8+PpdOxaMda1BCnLNkwf8Ou1buP'
          'Uog3OYj3/RD/EQzxHxzE+36IN9ER3XEQHEqc54hVYyx2MOn5iZ4iKrKC1Mj8rkCJ'
          'FaS6tJemrEpb3ge8oJNPp/7cF3hRW9EHcCEPglOKgK8b6p88pxL+krwlCa5CWI+x'
          'Z0Wh6oh4oDmILtFmytIN723cDUnbAfEihfjoGYX4Y+MQfyQQHz0jEC/e3E4h4iA4'
          'lJjPFImyeGLsmbGOnPi0vARXAXVZkpwJmuWynArYAlBFXkByO8lzK+U5FWiQnFWG'
          'lkne4kR3IUwDX2xqVrTVG2l2i/ysfWkXYXSJNlOXboShNXuObT9+gUC8/eAGgfjV'
          '08YhPiUQv0IzNCYQj19AdxwEhxLzmYYI6gRWk5YMzOAoaVjbYZMBpv6k5uAVvIUG'
          'KKvctCuxcwwIIKaLNlOXbVywiYd4+OKtc7cfNh0iGqMLBxEHwaHEfKYsooY4bdmm'
          'BZv2rN1zbAcgXhIgPn8ZxOcCxEu30HEtgbgHh2KDLW6IhnTRZtryTQs371m79/iO'
          'ExdfEeKJi+iOg+BQYj5TFkBME22mL9+8cPPedRTiEUB8/+GNx88eUIhfhoL4JYWI'
          'BmiGxkcoxHUE4l4cSsxnyiJqiDPI/9S8d92+4zsJxNvn33948/EnBOI3jUP8hkBE'
          's/ME4m10RHccBIdigy1uiPo00WbGii2Ltuxbt+/EzpOXjlwGxEfNgfgIXdAR3XEQ'
          'HErMZ8rSrqPeKdq8s3LL4i371u87sevkpaN+iF9TiL+Fgvgbhfg1BxFd0BHdcRAc'
          'SsxnyiJyiFsXb923fr8A8QMe4jNA/FMoiH/67ZkP4gcCxP0ncBAcig22uCHqnKLN'
          'zFVbl2zdv2H/yV2nLh298v4FQPzwkwefAuJPHMRfBIi/+CH+hAZohsbogo7ojoPg'
          'UGI+UxZAdIg2M1dtW7Jt/4YDJ3efunyMQrz14ScPXwYRDW5RiOiCjuiOg+BQYj5T'
          'FlFDnLUaEA9sPHBKgPj41ofPmwbxORpzEMnjb7aR/7WZDTaD+OoQl9ZRiKcpxDvN'
          'gXiHQjxNIC6tYxDFD1GbKtrMXlNHIB48tef0leNXP7gYDPGHYIg/BENEY3RBR3TH'
          'QXAoMZ8pi6ghLu0/aPWgYRuGjd46ejx5bjH9GyGPzZpzcu68s/MXXFgY9MRYfIsX'
          '8RYaoBka04fGjkd3HASHYoPNIL5KyF8HWT149eCGEOe+DOLc+hAHD8OhcEA23uKF'
          'GK61s7C0edqFa+z/q0M0/s3SJmEfPhceIhf2cbxhguxjDw3xzX8uHbWOCL0zwpAW'
          'aUiPNCIuIeRb8nsZeifZ3mtT30qCDGIgRFu9z0X4dGwtm45ae4TBGWVyRVs9MfaM'
          'uNSseCf3PwrlJ7oLEt2FSZ4iEi+NpyjRU4jXE1wFCel58Wm5cY7sWHtmjM0bbXZH'
          'GgHU0eI/4RvIm/mopZh24erQnw7/Galtr5kInQP4YqzeuNRssEt0FSZ5i2WZpfLs'
          'CkVupTKvs4r8/7zdUpCi7uqiHupiEnxNUthNVdBVmd9FmdtJkVMhyypLziiB0YT0'
          '/HhHTqwtM9rsiTSkdcQfqdf+OVs7rfohvwV5CcRX/6Q0dhCJtnjgLyEtD3qAT5FT'
          'CVXgpS7uqSnrrSvvo6/sp+/U39Cl2tilxkj+f3JkIAm+7jrA0KXG0Lla36mfrqKv'
          'trxKU9pLXdQdNMn/SZlVnuwtSXQVUJEZsA7xkiPIIAZCtL70kwr4yKxNCeZNTKBx'
          'qZmYVZO9RfLsMmVeJ/jTlPTUlVcBFtiZug809xhs6VVrrRpq6zPc1neEHek30he8'
          'gtetVcOsvYdaeg4x9RhEaHbur6vsqy3rrS6GyC6kTGaWYAbHLI+iG2VEdbQ18Yds'
          '7bT4p/p2p3kQm/LBReqdMRZPvCMbPkgVzK1MKeyqKe2pq+gDRqZuA809hxB8YNd/'
          'VGr1GMeAsc6B49MGTUgbjEz0Z9AE56DxzoHjHDVjUqtHE5p9hgGumYisgWaeY35n'
          'eTaqYxHqLhaRUaZ0LEalQpBB9EPskNLsD44LOjYMdsFRZncspmNXQTJRSAthaW/6'
          'tKsaE0pgb0Iwtf9o4o/gm5heO9k1dIp72FT38Gnu4dPdI2jwBXng1VS8lT5kEppB'
          'JNTa+42yVg03C4+60pb3wYIS0z0sJnmK4525MdYMbMA7qG0hf7zWTgt+kr+3vDrE'
          'EB+i2gYEMbYMbEqwI5HnVGA9py7phRUeVntQaCUKR8ITKYEcQfgbMd0zcoZ31Dve'
          '0TMzRs/igq/JEwFHvuMZMYOIpBwB11EzFnXU2me4uRe12Km/tqwqhTzwqrMssww7'
          'ISxJ8ScBfx4kQZBBDIRoeZ0PUfgoLQg24ZHGdMyPZGmYUUIn5W6asl5kUdhtAJmR'
          '6YMoUQsx7abXTgpQSAmOmZU5djYX+ixKjiMs0uo4dLJQF0ejplrI89cGYZeDGV9d'
          'gqLYGXvqRE9hnCMHOyQsUrkf6Q2kpT6933laBqIvBKItg0Isxh5ZRVaHvfSVfbHP'
          'oEvDYVjqOcgTUcejwpEZefg0rhxmoByOCXwiKq2LpCjOIBDp41CDIdaaug8ykNm5'
          'is7OFKIbELOjLW7soMXvj0FsRYhcsIdN8hRCBnxACayQbUr3gdhq2ISiKFic7Bbq'
          'Ij9BC/FwBMlKcQpVOIFTCMrY62DHjS0LdtCAjrqL6osanJCez+1XwjV2SRBkEAMg'
          'qlr+k/VFnlWOnQRnEes5Uhd7DLH2HsbvV2r4/XI6eTrvZFftFNRIf2onc9sUsn0e'
          'wO9U4BiaSS3sUoOlp0+hLKM00VWABWK0mZZDlaXF03qfUmv8tJILIJpb7yPmwl/B'
          'oRcRDYRjjbnHIHoFkYhEhUvlruPUIGNRLEnwBb1qg7fs3AXF3kPNPQebyHNRq/Xc'
          'pcQi37WbYiwG4uyZ0WZXhC4VZ9Syae3Pp8V/YCnmTUD0RVWA6tgdZQw7DOxgyA2V'
          'rgO4K9tYQVp6IbX+9BxCXu8+yERutNT4LmUDNKqgMq8TRzDRlR/vyI6xeum9PpuE'
          '/DGIbQaxHsqUom6YtTWlPcELczfqJYD6U15F2JX2gjzwRU1F/UNxlZM7zsXk9yHS'
          'clEFYyyeFiTYJh8FU0ghKtvm0/cFyzt5ZhlWk6hwiuwKX8grWWWyzFKZtyTZU5Tk'
          'KkxMI7/rEGfPQv2LNrki9c6O2JQoza+ftv0EWuQUpB5ANLXtMNRLnC0DieVi9aLg'
          'Yf8RbUyPMjgjdQ5yKxmbLKXpNSOqU37903kL0i4MoxIWLdrgx2uR/B7OUdIRO8Tf'
          'Q5hCBpFBFA9EBYPY1hAVJhZANDIKbQ3RyMIgMogMIguDyCAyiCKDKDcwCm0MUW5g'
          'YRAZRAaRhUFkEBlEcUFsL9czCm0bDAFLu/YyBrGtIcr0LBzEKJY2DFPIIDKIDCIL'
          'gxgMUccotDVEHUu79skMYltDTNaxMIiig9hBYQxXmTuqrRFae6TOEWVwRhvTo02u'
          'GJM7xhwUvEj/b560KL0zUpsaIfwPPWGY7BhElldYI4YrzR01tki9A7BiLZ44W2a8'
          'IzshLTcxPT/JXZjsKZJ5i2UZJYg8sxSRZZSSb73FeCvZXZjkKkhMy0tw5sTbs8j/'
          'cWZ2Q2eENhUuw+RGqUDUMgptG9Q80ImzZ0BSkitf5i2Sk8c8l6vyKlMKOqsLu6qL'
          'umuKe2hKempLufTivtCU9NAUd1cXdUsp6KLK76TMrVBklckyikEzMT03PhUoPZAd'
          'qbOHp5hpmdSKNgxi2wfFj/orVmSXqcgznrtCmLasl76ij4E85rm/qWuNqdsAc/eB'
          '5u6DzD2E4NtuA01dBxi7VBs699dX9tWV94ZO4jK/szKnQp5ZkuwpTCSPIciIMbsi'
          'dSiQZrIzYBBZQkZGHuFXDj0ob7qy3uQpfl2qIc/SY7C1V62tapi973B7vxGp/bmH'
          'BI1yVI8iXyD9RtIHA/GPGSePZ+laYyDPvq/SlvREKVWSB2OUokCi1sbavNHGtAiN'
          'NUxuECPEPyYxiG0cJX2iKSZcfQUhCE8Wzl+/kanV3DPTxqVxj3lGhkziQ5+TljZw'
          'vHPAOEf1GLi09RlBHlXVYzDKJOFInxxJnlOVVY6lZIIzN9aagbUjtkFYlWLcRRUG'
          'se3DKySPM60x0wc8o86BIIRxz+xz1U7mnjHuIZnuGTHdQ543Ps1NnzHuqiUonQPH'
          'k+en8U/uG0Iem9a5f4DFMmx64h055FFB5LF9ZhFC1DAKbRs1ZmT6LFMs+zAXYyLG'
          '/OsUHvDs5p6rO2K6N/hBpuRZuiOpSHAkz5KcmEYtkr9+oWqYpSd5kCl5fl9pTyw6'
          'FTkV5OF9abmYoLE3wm4aG1UMvXjCILZ9sCPGqo6blK29a/lyiOl48ARUO/ewKZ4A'
          'iBkkM/0W6XOdXUMpxEFcUeQhmshfAgKIvQARexesRBMJxAzyt9GoLdi1MIgswRWx'
          'qJu2rDdWdWSD0nOwjX/S+BhYxJxL52UUxameEQJH6o+foHmFk6AQRZQ+13Q4NMO0'
          'kT7pHhtwVUFnRTaWiXTLYvVE6h3hZGrWiAxiIoPYxlHldVIXkf0ysdiVbpa5ZWL/'
          'URxHMkdDJF0sBobfspD9ylgH93cioRb2GmLuNtDYuVpPFPZMKeiiyK6QeVEO8+Js'
          'GdHG9I5qGzbOGHdRhUFs+8gzSsnGuYB7unMfQ6f+JvKwcd+1mxHYgpBHjtOnOzux'
          'iaYhT3rmHu1M/k6u4fwVHBAMfLRzXmcF3TKTq4lUYYTG3kFhFJtCDqKaUWjbYMZM'
          'dhfKM8GxAgVMU9ydXsrhrmZXc5eyUSbhzNoLqaWhT3ruOZhc2SaXtWuMwjVtzMXq'
          'wq6osorsMpm3KCk9j9xisbij9A4sDcPkeoy4CMMgtn3I/WWrN8GRDTSoXkRkTgW5'
          'xVLQBctHcpeltJeO/GWuVfoKpA8X8qTn8t7asl7akp7kRl9hV3JDJbeSu8uX5C6A'
          'b/JoZzNH0NpBYRAnQQZRLAER1KpIXWq0MY38xoM9AygT0/OAify6Q0YxufWcVYYN'
          'hyKnHEZpysm32WXyrFJ5ZgkqH/3Vh3zyew+p3O89uKIMTvL7OCpTGDbIIiboh/j/'
          'hEWxtGF8g8H9DljHFDMAwSX5BTBTOkoadMIWeaizHcmkyaDPePZiF4xpN4b8Plga'
          'Kl+k1o7iF640YQpuj92o6P0FQExgENsaYoL6BWmfpA1L1oXJ9B3kBhqjEEOYzBCW'
          'DHC69ljvv/Ag4g8gpjAKbQ0xhaXdHxjEtg6GgIVBZBAZRBYGkUFkEEUGMV7FKLQx'
          'xHgVC4PIIDKILAwig8ggMogsDGIIiEpGoa0hKlna/SGOQWxriHFKFgaRQWQQWRhE'
          'BpFBFBfE/4pTMAptGwwBC4PIIIoEYiyD2NYQYxUsDCKDyCCyMIgMIoMoNohyRqGt'
          'IcpZKMT2USxtGKaQQoxhENsaYoychUFkEBlEFgYxAKKMUWhriDIWDmIkSxuGKWQQ'
          'GUTRQPx/oxnENg6GgIVBZBAZRBYGMQBiMqPQ1hCTWRhEBpFBZGEQ/RCjGMS2hhiV'
          'zMIgMohigZjEKLQ1xCQWBpFBZBBZGEQGkUFkEFkYxIYQIxnEtoYYmcQCiImMQltD'
          'TGRp978YxLYOhoCFQWQQGUQWBpFBZBBFBjGCQWxriBGJLICYwCi0NcQEFgaRQWQQ'
          'WRhEIf8/wX8mPMvGE1sAAAAASUVORK5CYII=',
      width: 216,
      height: 384,
    ),
    // La musique : une SEULE source, jamais de variante d'orientation. Le
    // schema du clip audio le refuse et le resolveur runtime l'ignore.
    _SeededMedia(
      mediaId: lighthouseMusicMediaId,
      label: 'Boucle du phare',
      kind: 'audio',
      mediaType: 'audio/ogg',
      container: 'ogg',
      codec: 'vorbis',
      logicalPath: 'assets/presentation/audio/lighthouse_loop.ogg',
      base64: 'T2dnUwAB',
    ),
  ];

  Future<void> _writeSeededMedia(Directory root) async {
    final store = Directory(p.join(root.path, 'assets', '.pokemap-store'));
    await store.create(recursive: true);
    final records = <Map<String, Object?>>[];
    final entries = <Map<String, Object?>>[];
    for (final media in _seededMedia) {
      final bytes = base64Decode(media.base64);
      // The fingerprint is a DOMAIN-FRAMED sha256, not a bare one, so it is
      // computed by the repository's own function rather than recomputed here:
      // a bare hash produces a blob the loader rejects as mismatched.
      final artifact = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: media.mediaType,
      );
      await File(
        p.join(store.path, '${artifact.hexDigest}.blob'),
      ).writeAsBytes(bytes, flush: true);
      final assetId = 'asset.${media.mediaId}';
      records.add(<String, Object?>{
        'id': assetId,
        'logicalPath': media.logicalPath,
        'artifact': artifact.toJson(),
        'usages': const <Object?>[],
        'tags': const <String>['presentation'],
      });
      entries.add(<String, Object?>{
        'id': media.mediaId,
        'label': media.label,
        'kind': media.kind,
        'sourceAssetId': assetId,
        // La publication EXIGE une provenance authoree, et c'est justifie :
        // un paquet redistribuable doit pouvoir dire d'ou vient chaque media.
        // Ceux-ci sont generes par la fixture, donc rien de proprietaire.
        'provenance': const <String, Object?>{
          'source': 'Genere par la fixture de certification PokeMap',
          'creator': 'PokeMap Certification Studio',
        },
        'license': const <String, Object?>{
          'identifier': 'CC0-1.0',
          'name': 'Domaine public (media genere, aucune source tierce)',
        },
        'technicalMetadata': <String, Object?>{
          'mediaType': media.mediaType,
          'container': media.container,
          'codec': media.codec,
          'sizeBytes': bytes.length,
          if (media.width != null) 'width': media.width,
          if (media.height != null) 'height': media.height,
        },
      });
    }
    await _writeJson(
      File(p.join(root.path, 'assets', '.pokemap-assets.json')),
      <String, Object?>{'schemaVersion': 1, 'records': records},
    );
    await _writeJson(
      File(p.join(root.path, 'assets', '.pokemap-media.json')),
      <String, Object?>{'schemaVersion': 1, 'entries': entries},
    );
  }

  static const String fixedGameId = 'games.pokemap.certification.neutral';
  static const String fixedGameVersion = '1.0.0';
  static const String fixedMapId = 'neutral_harbor';
  static const String fixedSpawnId = 'neutral_spawn';
  static const String secondMapId = 'neutral_causeway';
  static const String thirdMapId = 'neutral_lighthouse';
  static const String secondSpawnId = 'neutral_causeway_spawn';
  static const String thirdSpawnId = 'neutral_lighthouse_spawn';

  String get gameId => fixedGameId;
  String get gameVersion => fixedGameVersion;
  String get mapId => fixedMapId;
  String get spawnId => fixedSpawnId;
  String get authorSecret => 'phase8-author-secret-must-never-ship';

  // Un paquet ne declare que les locales dont il porte VRAIMENT le contenu.
  // Le parcours dialogue de BETA-CIN-083 est authore entierement en francais ;
  // declarer 'en' en plus faisait resoudre l'anglais sur un appareil anglais,
  // et le joueur lisait des invites francaises sous un chrome anglais. Le
  // resolveur de locale avait raison, c'est la declaration qui mentait.
  GamePackageExportProfile get exportProfile => GamePackageExportProfile(
    gameId: gameId,
    gameVersion: gameVersion,
    title: 'The Clockwork Harbor',
    description: dialoguedPreSession
        ? 'Un mini-jeu neutre de certification PokeMap.'
        : 'A neutral PokeMap certification mini-game.',
    authorName: 'PokeMap Certification Studio',
    defaultLocale: dialoguedPreSession ? 'fr' : 'en',
    supportedLocales: dialoguedPreSession
        ? const <String>['fr']
        : const <String>['en', 'fr'],
  );

  GamePackageHostCompatibility get hostCompatibility =>
      GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const <String>{
          'dialogue.choices@1',
          'map@1',
          'overworld.menu@1',
          'world.shop@1',
        },
        supportedProjectFormats: <String>{projectFormat},
        currentProjectFormat: projectFormat,
        supportedSaveFormats: const <int>{1},
      );

  static MapData _linkedMap({
    required String id,
    required String name,
    required String spawnId,
    MapWarp? warp,
  }) =>
      MapData(
        id: id,
        name: name,
        version: ProjectVersion.v6,
        size: const GridSize(width: 4, height: 4),
        warps: warp == null ? const <MapWarp>[] : <MapWarp>[warp],
        entities: <MapEntity>[
          MapEntity(
            id: spawnId,
            name: '$name arrival',
            kind: MapEntityKind.spawn,
            pos: const GridPos(x: 1, y: 1),
            blocksMovement: false,
            spawn: const MapEntitySpawnData(
              role: EntitySpawnRole.playerStart,
              facing: EntityFacing.south,
            ),
          ),
        ],
        mapMetadata: MapMetadata(defaultSpawnId: spawnId),
      );

  Future<void> writeAuthorWorkspace(Directory root) async {
    await root.create(recursive: true);
    final manifest = ProjectManifest(
      name: 'The Clockwork Harbor',
      version: projectVersion,
      maps: <ProjectMapEntry>[
        const ProjectMapEntry(
          id: fixedMapId,
          name: 'Clockwork Harbor',
          relativePath: 'maps/clockwork_harbor.json',
          role: MapRole.exterior,
        ),
        if (connectedMaps) ...const <ProjectMapEntry>[
          ProjectMapEntry(
            id: secondMapId,
            name: 'Neutral Causeway',
            relativePath: 'maps/neutral_causeway.json',
            role: MapRole.exterior,
          ),
          ProjectMapEntry(
            id: thirdMapId,
            name: 'Neutral Lighthouse',
            relativePath: 'maps/neutral_lighthouse.json',
            role: MapRole.interior,
          ),
        ],
      ],
      tilesets: _actorTilesetEnabled
          ? const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: actorTilesetId,
                name: 'Certification actors',
                relativePath: actorTilesetPath,
              ),
            ]
          : const <ProjectTilesetEntry>[],
      characters: <ProjectCharacterEntry>[
        if (_arenaEnabled)
          const ProjectCharacterEntry(
            id: 'certification_actor',
            name: 'Certification actor',
            tilesetId: actorTilesetId,
          ),
        // BETA-CIN-083 : les deux silhouettes que le choix d'avatar propose.
        // Elles partagent le tileset d'acteur existant plutot que d'en
        // introduire un second — meme PNG, meme ecriture deterministe.
        if (dialoguedPreSession) ...const <ProjectCharacterEntry>[
          ProjectCharacterEntry(
            id: dawnKeeperCharacterId,
            name: 'Gardienne de l’aube',
            tilesetId: actorTilesetId,
          ),
          ProjectCharacterEntry(
            id: duskKeeperCharacterId,
            name: 'Gardien du crépuscule',
            tilesetId: actorTilesetId,
          ),
        ],
      ],
      dialogues: _arenaEnabled
          ? const <ProjectDialogueEntry>[
              ProjectDialogueEntry(
                id: 'dlg_certification_rival_pre',
                name: 'Rival pre-battle',
                relativePath: 'dialogues/certification_rival_pre.yarn',
              ),
              ProjectDialogueEntry(
                id: 'dlg_certification_rival_victory',
                name: 'Rival victory',
                relativePath: 'dialogues/certification_rival_victory.yarn',
              ),
              ProjectDialogueEntry(
                id: 'dlg_certification_boss_victory',
                name: 'Boss victory',
                relativePath: 'dialogues/certification_boss_victory.yarn',
              ),
            ]
          : const <ProjectDialogueEntry>[],
      badges: _arenaEnabled
          ? const <BadgeDefinition>[
              BadgeDefinition(
                id: bossBadgeId,
                label: 'Tide Badge',
                fieldAbilityUnlock: FieldAbility.surf,
              ),
            ]
          : const <BadgeDefinition>[],
      trainers: _arenaEnabled
          ? const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: rivalTrainerId,
                name: 'Rival Nao',
                trainerClass: 'Rival',
                templateKind: ProjectTrainerTemplateKind.rival,
                rematchPolicy: ProjectTrainerRematchPolicy.allowed,
                battleDifficulty: 1,
                moneyReward: 120,
                preBattleDialogueId: 'dlg_certification_rival_pre',
                victoryDialogueId: 'dlg_certification_rival_victory',
                rewardFlagIds: <String>['story:certification_rival_beaten'],
                rewardItemGrants: <ProjectTrainerItemGrant>[
                  ProjectTrainerItemGrant(itemId: 'antidote', quantity: 1),
                ],
                team: <ProjectTrainerPokemonEntry>[
                  ProjectTrainerPokemonEntry(
                    speciesId: 'bulbasaur',
                    level: 4,
                    moves: <String>['tackle'],
                  ),
                ],
              ),
              ProjectTrainerEntry(
                id: bossTrainerId,
                name: 'Harbormaster Sel',
                trainerClass: 'Gym Leader',
                templateKind: ProjectTrainerTemplateKind.gymLeader,
                battleDifficulty: 8,
                moneyReward: 600,
                victoryDialogueId: 'dlg_certification_boss_victory',
                rewardBadgeId: bossBadgeId,
                rewardFlagIds: <String>[bossVictoryFlagId],
                rewardFieldAbilityUnlock: FieldAbility.surf,
                team: <ProjectTrainerPokemonEntry>[
                  ProjectTrainerPokemonEntry(
                    speciesId: 'bulbasaur',
                    level: 6,
                    moves: <String>['tackle'],
                  ),
                ],
              ),
            ]
          : const <ProjectTrainerEntry>[],
      shops: economyTown
          ? const <ShopDefinition>[
              ShopDefinition(
                id: shopId,
                label: 'Échoppe du port',
                entries: <ShopEntryDefinition>[
                  ShopEntryDefinition(
                    itemId: 'potion',
                    price: 100,
                    sellPrice: 50,
                  ),
                  ShopEntryDefinition(
                    itemId: 'super-potion',
                    price: 250,
                    sellPrice: 125,
                  ),
                ],
              ),
            ]
          : const <ShopDefinition>[],
      encounterTables: encounterField
          ? <ProjectEncounterTable>[
              const ProjectEncounterTable(
                id: encounterTableId,
                name: 'Certification grass',
                encounterKind: EncounterKind.walk,
                chancePerStep: 1,
                entries: <ProjectEncounterEntry>[
                  // Ivysaur, PAS l'espèce du starter : le Pokédex de la gate
                  // doit discriminer « vu au combat fui » puis « capturé » —
                  // une espèce déjà possédée au départ ne prouverait rien.
                  ProjectEncounterEntry(
                    speciesId: 'ivysaur',
                    minLevel: 5,
                    maxLevel: 5,
                    pokemonOverrides: ProjectEncounterPokemonOverrides(
                      natureId: 'hardy',
                      abilityId: 'overgrow',
                      ivs: PokemonStatSpread(),
                      shinyPolicy: ProjectEncounterShinyPolicy.never,
                    ),
                  ),
                ],
              ),
            ]
          : const <ProjectEncounterTable>[],
      newGame: ProjectNewGameConfig(
        enabled: true,
        startMapId: fixedMapId,
        startSpawnId: fixedSpawnId,
        playerName: 'Ari',
        startingMoney: 300,
        initialParty: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            currentHp: 20,
            // BETA-ITM-008 : growl est libre pour l'apprentissage par CT.
            knownMoveIds: economyTown
                ? const <String>['tackle']
                : progressionArena
                    ? const <String>[
                        'tackle',
                        'leer',
                        'quick_attack',
                        'tail_whip',
                      ]
                    : const <String>[],
          ),
          if (partySize > 1)
            const PlayerPokemon(
              speciesId: 'ivysaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 7,
              currentHp: 22,
            ),
          // BETA-ENC-006 : la branche « party pleine -> PC » part d'une équipe
          // de six, en alternant les deux espèces du seed.
          for (var member = 2; member < partySize; member++)
            PlayerPokemon(
              speciesId: member.isEven ? 'bulbasaur' : 'ivysaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 5 + member,
              currentHp: 18 + member,
            ),
        ],
        initialBag: encounterField
            ? const <BagEntry>[
                BagEntry(itemId: weakBallItemId, quantity: 1),
                BagEntry(itemId: guaranteedBallItemId, quantity: 1),
              ]
            : economyTown
                ? const <BagEntry>[
                    BagEntry(itemId: 'potion', quantity: 4),
                    BagEntry(itemId: machineItemId, quantity: 1),
                    BagEntry(itemId: heldItemId, quantity: 1),
                  ]
                : trainerArena || progressionArena
                    ? const <BagEntry>[
                        BagEntry(itemId: 'potion', quantity: 4),
                      ]
                    : const <BagEntry>[],
        // BETA-CIN-083 : les deux silhouettes que le choix d'avatar du
        // parcours dialogue est autorise a proposer. Une option de choix
        // liee a avatarCharacterId doit etre declaree ici, sinon l'action
        // d'authoring la refuse — c'est la graine du projet, pas le parcours,
        // qui les declare, comme les especes et les objets des autres gates.
        playerAvatarCharacterIds: dialoguedPreSession
            ? const <String>[dawnKeeperCharacterId, duskKeeperCharacterId]
            : const <String>[],
      ),
      scenes: <SceneAsset>[
        _completionScene,
        if (economyTown) _pickupScene,
      ],
      // BETA-ENC-006 : le déclencheur mapEnter de la scène de complétion finit
      // le jeu AU BOOT (surface completion, autorité bloquée) — la gate de
      // démarrage certifie exactement cela, mais un journey overworld doit y
      // échapper. L'export exige une fin ATTEIGNABLE : la scène migre alors
      // sur un trigger d'entrée de case que le journey ne visite jamais.
      eventRegistry: economyTown
          ? _economyEventRegistry
          : encounterField || _arenaEnabled
              ? _cornerEventRegistry
              : _eventRegistry,
      globalProperties: <String, Object?>{
        'certificationFixture': true,
        'apiKey': authorSecret,
      },
    );
    final manifestJson = manifest.toJson();
    final settings = Map<String, Object?>.from(manifestJson['settings'] as Map);
    settings['mistralApiKey'] = authorSecret;
    manifestJson['settings'] = settings;
    await _writeJson(File(p.join(root.path, 'project.json')), manifestJson);

    final map = MapData(
      id: fixedMapId,
      name: 'Clockwork Harbor',
      version: ProjectVersion.v6,
      size: const GridSize(width: 4, height: 4),
      triggers: <MapTrigger>[
        if (encounterField || _arenaEnabled)
          const MapTrigger(
            id: completionTriggerId,
            name: 'Certification corner',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 3, y: 3),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        if (economyTown)
          const MapTrigger(
            id: pickupTriggerId,
            name: 'Certification pickup',
            type: TriggerType.event,
            area: MapRect(
              pos: pickupCell,
              size: GridSize(width: 1, height: 1),
            ),
          ),
      ],
      gameplayZones: encounterField
          ? const <MapGameplayZone>[
              MapGameplayZone(
                id: encounterZoneId,
                name: 'Certification grass',
                kind: GameplayZoneKind.encounter,
                area: MapRect(
                  pos: encounterCell,
                  size: GridSize(width: 1, height: 1),
                ),
                encounter: EncounterZonePayload(
                  encounterTableId: encounterTableId,
                  encounterKind: EncounterKind.walk,
                ),
              ),
            ]
          : const <MapGameplayZone>[],
      warps: connectedMaps
          ? const <MapWarp>[
              MapWarp(
                id: 'warp_harbor_to_causeway',
                pos: GridPos(x: 2, y: 1),
                targetMapId: secondMapId,
                targetPos: GridPos(x: 1, y: 1),
              ),
            ]
          : const <MapWarp>[],
      entities: <MapEntity>[
        const MapEntity(
          id: fixedSpawnId,
          name: 'Player arrival',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        if (_arenaEnabled) ...const <MapEntity>[
          MapEntity(
            id: 'npc_certification_rival',
            name: 'Rival Nao',
            kind: MapEntityKind.npc,
            pos: rivalCell,
            blocksMovement: true,
            npc: MapEntityNpcData(
              displayName: 'Rival Nao',
              facing: EntityFacing.east,
              trainerId: rivalTrainerId,
              characterId: 'certification_actor',
              // En mode événementiel v2Only, l'interaction manuelle ne
              // retombe jamais sur le canal legacy : les dresseurs se
              // déclenchent par ligne de vue, comme en production.
              lineOfSightRange: 1,
            ),
          ),
          MapEntity(
            id: 'npc_certification_boss',
            name: 'Harbormaster Sel',
            kind: MapEntityKind.npc,
            pos: bossCell,
            blocksMovement: true,
            npc: MapEntityNpcData(
              displayName: 'Harbormaster Sel',
              facing: EntityFacing.west,
              trainerId: bossTrainerId,
              characterId: 'certification_actor',
              lineOfSightRange: 1,
            ),
          ),
        ],
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: fixedSpawnId),
    );
    await _writeJson(
      File(p.join(root.path, 'maps', 'clockwork_harbor.json')),
      map.toJson(),
    );

    if (connectedMaps) {
      await _writeJson(
        File(p.join(root.path, 'maps', 'neutral_causeway.json')),
        _linkedMap(
          id: secondMapId,
          name: 'Neutral Causeway',
          spawnId: secondSpawnId,
          warp: const MapWarp(
            id: 'warp_causeway_to_lighthouse',
            pos: GridPos(x: 2, y: 1),
            targetMapId: thirdMapId,
            targetPos: GridPos(x: 1, y: 1),
          ),
        ).toJson(),
      );
      await _writeJson(
        File(p.join(root.path, 'maps', 'neutral_lighthouse.json')),
        _linkedMap(
          id: thirdMapId,
          name: 'Neutral Lighthouse',
          spawnId: thirdSpawnId,
        ).toJson(),
      );
    }
    await _writePokemonCatalogsWithMinimalMedia(root);
    if (encounterField) {
      await _appendGuaranteedBallToItemCatalog(root);
    }
    if (_arenaEnabled) {
      await _writeArenaDialogues(root);
    }
    if (_actorTilesetEnabled) {
      await _writeActorTileset(root);
    }
    if (dialoguedPreSession) {
      await _writeSeededMedia(root);
    }
    if (economyTown) {
      await _appendEconomyItemsToCatalog(root);
    }
    if (progressionArena) {
      await _overrideProgressionLearnsetAndEvolution(root);
    }
    await File(
      p.join(root.path, 'LICENSE.txt'),
    ).writeAsString('PokeMap neutral certification fixture.', flush: true);

    // These author-only artifacts must be dropped by the runtime projection.
    await File(
      p.join(root.path, 'runtime_host_launch_save.json'),
    ).writeAsString('{}', flush: true);
    await File(
      p.join(root.path, 'debug.log'),
    ).writeAsString(authorSecret, flush: true);
    final saves = Directory(p.join(root.path, 'saves'));
    await saves.create(recursive: true);
    await File(
      p.join(saves.path, 'slot.json'),
    ).writeAsString(authorSecret, flush: true);
  }

  Future<void> writeSpeciesCatalog(Directory root, {required int count}) async {
    if (count < 2 || count > 10000) {
      throw ArgumentError.value(count, 'count', 'must be between 2 and 10000');
    }
    final species = Directory(p.join(root.path, 'data', 'pokemon', 'species'));
    await species.create(recursive: true);
    await for (final entity in species.list()) {
      if (entity is File &&
          p.basename(entity.path).endsWith('-clockling.json')) {
        await entity.delete();
      }
    }
    final template =
        jsonDecode(
              await File(
                p.join(species.path, '0001-bulbasaur.json'),
              ).readAsString(),
            )
            as Map<String, dynamic>;
    for (var start = 2; start < count; start += 64) {
      final end = (start + 64).clamp(0, count);
      await Future.wait(<Future<void>>[
        for (var index = start; index < end; index++)
          _writeJson(
            File(
              p.join(
                species.path,
                '${index.toString().padLeft(4, '0')}-clockling.json',
              ),
            ),
            _speciesFromTemplate(template, index),
          ),
      ]);
    }
  }

  Future<GamePackageExportArtifact> export(
    Directory authorRoot,
    File outputFile,
  ) => const GamePackageExportService().exportToFile(
    projectRoot: authorRoot,
    profile: exportProfile,
    outputFile: outputFile,
  );

  /// La Ball 17/1 du scénario de capture garantie, déclarée DANS le catalogue
  /// projet seedé pour rester connue de la validation d'export et du runtime.
  Future<void> _appendGuaranteedBallToItemCatalog(Directory root) async {
    final itemsFile = File(
      p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
    );
    final catalog =
        jsonDecode(await itemsFile.readAsString()) as Map<String, dynamic>;
    final entries = (catalog['entries'] as List).cast<Map<String, dynamic>>();
    final template = entries.singleWhere(
      (entry) => entry['id'] == weakBallItemId,
    );
    final guaranteedBall =
        jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
    guaranteedBall['id'] = guaranteedBallItemId;
    guaranteedBall['displayName'] = 'Certification Ball';
    (guaranteedBall['capture'] as Map<String, dynamic>)
      ..['rateNumerator'] = 17
      ..['rateDenominator'] = 1;
    entries.add(guaranteedBall);
    await _writeJson(itemsFile, catalog);
  }

  /// La CT growl (compatible learnset) et l'objet tenu à effet porté
  /// (leftovers) du parcours économie, déclarés DANS le catalogue projet.
  Future<void> _appendEconomyItemsToCatalog(Directory root) async {
    final itemsFile = File(
      p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
    );
    final catalog =
        jsonDecode(await itemsFile.readAsString()) as Map<String, dynamic>;
    final entries = (catalog['entries'] as List).cast<Map<String, dynamic>>();
    entries.add(<String, Object?>{
      'id': machineItemId,
      'displayName': 'CT Grondement',
      'pocketId': 'machines',
      'tags': <String>['machine'],
      'machine': <String, Object?>{
        'moveId': 'growl',
        'kind': 'tm',
        'consumable': true,
      },
    });
    entries.add(<String, Object?>{
      'id': heldItemId,
      'displayName': 'Restes certifiés',
      'pocketId': 'held',
      'tags': <String>['held'],
      'heldEffectId': 'leftovers',
    });
    await _writeJson(itemsFile, catalog);
  }

  /// Surcharge le learnset et l'évolution du starter pour que le grind de la
  /// gate progression produise deux prompts d'apprentissage puis une
  /// proposition d'évolution — des données, pas du code.
  Future<void> _overrideProgressionLearnsetAndEvolution(Directory root) async {
    final learnsetFile = File(
      p.join(root.path, 'data', 'pokemon', 'learnsets', 'bulbasaur.json'),
    );
    final learnset =
        jsonDecode(await learnsetFile.readAsString()) as Map<String, dynamic>;
    learnset['levelUp'] = <Object?>[
      <String, Object?>{
        'moveId': 'tackle',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'growl',
        'level': 6,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'vine_whip',
        'level': 7,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
    ];
    await _writeJson(learnsetFile, learnset);

    final evolutionFile = File(
      p.join(root.path, 'data', 'pokemon', 'evolutions', 'bulbasaur.json'),
    );
    final evolution =
        jsonDecode(await evolutionFile.readAsString()) as Map<String, dynamic>;
    final targets = (evolution['evolutions'] as List?)
        ?.cast<Map<String, dynamic>>();
    if (targets == null || targets.isEmpty) {
      throw StateError('The seed bulbasaur evolution file has no targets.');
    }
    targets.first['minLevel'] = 7;
    await _writeJson(evolutionFile, evolution);
  }

  Future<void> _writeActorTileset(Directory root) async {
    final file = File(p.join(root.path, actorTilesetPath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
        '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      flush: true,
    );
  }

  Future<void> _writeArenaDialogues(Directory root) async {
    final dialogues = Directory(p.join(root.path, 'dialogues'));
    await dialogues.create(recursive: true);
    const lines = <String, String>{
      'certification_rival_pre.yarn': 'On se mesure encore une fois ?',
      'certification_rival_victory.yarn': 'Bien joué… pour cette fois.',
      'certification_boss_victory.yarn':
          'Le port te reconnaît. Prends ce badge.',
    };
    for (final entry in lines.entries) {
      await File(p.join(dialogues.path, entry.key)).writeAsString(
        'title: Start\n---\n${entry.value}\n===\n',
        flush: true,
      );
    }
  }

  Future<void> _writePokemonCatalogsWithMinimalMedia(Directory root) async {
    await SeedPokemonDemoDataUseCase(
      snapshotController: FilePokemonReadRepository(),
    ).execute(ProjectFileSystem(root.path));
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    for (final speciesId in const <String>['bulbasaur', 'ivysaur']) {
      final frontPath = 'assets/pokemon/sprites/$speciesId/front.png';
      final backPath = 'assets/pokemon/sprites/$speciesId/back.png';
      await _writeJson(
        File(p.join(root.path, 'data', 'pokemon', 'media', '$speciesId.json')),
        <String, Object?>{
          'schemaVersion': currentPokemonDataSchemaVersion,
          'speciesId': speciesId,
          'defaultFormId': 'base',
          'variants': <String, Object?>{
            'base': <String, Object?>{
              'frontStatic': frontPath,
              'backStatic': backPath,
            },
          },
        },
      );
      for (final relativePath in <String>[frontPath, backPath]) {
        final file = File(p.join(root.path, relativePath));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(imageBytes, flush: true);
      }
    }
  }
}

final NarrativeEventRegistry _economyEventRegistry = NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: <NarrativeEventRecord>[
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000002',
        name: 'Corner completion',
        source: NarrativeEventSourceRef.triggerEnter(
          NeutralCertificationGameFixture.fixedMapId,
          NeutralCertificationGameFixture.completionTriggerId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.complete',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000003',
        name: 'Harbor pickup',
        source: NarrativeEventSourceRef.triggerEnter(
          NeutralCertificationGameFixture.fixedMapId,
          NeutralCertificationGameFixture.pickupTriggerId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.pickup',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 1,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

final SceneAsset _pickupScene = SceneAsset(
  id: 'scene.certification.pickup',
  name: 'Harbor pickup',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'grant',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.giveItem(
            itemId: NeutralCertificationGameFixture.pickupItemId,
            quantity: 1,
          ),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'start-grant',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'grant',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'grant-end',
        fromNodeId: 'grant',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

final NarrativeEventRegistry _cornerEventRegistry = NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: <NarrativeEventRecord>[
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000002',
        name: 'Corner completion',
        source: NarrativeEventSourceRef.triggerEnter(
          NeutralCertificationGameFixture.fixedMapId,
          NeutralCertificationGameFixture.completionTriggerId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.complete',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

final NarrativeEventRegistry _eventRegistry = NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: <NarrativeEventRecord>[
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000001',
        name: 'Runtime start',
        source: NarrativeEventSourceRef.mapEnter(
          NeutralCertificationGameFixture.fixedMapId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.complete',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

final SceneAsset _completionScene = SceneAsset(
  id: 'scene.certification.complete',
  name: 'Certification journey',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'finish',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.finishGame(
            endingId: 'ending.certification.complete',
            outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Adventure complete'),
              summary: SceneLocalizedText(
                fallback: 'The certification journey reached its ending.',
              ),
            ),
            postGamePolicy: ScenePostGamePolicy.returnToTitle,
          ),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'start-finish',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'finish',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'finish-end',
        fromNodeId: 'finish',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

Map<String, Object?> _speciesFromTemplate(
  Map<String, dynamic> template,
  int index,
) {
  final species = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
  final speciesId = 'clockling_$index';
  species['id'] = speciesId;
  species['slug'] = 'clockling-$index';
  species['nationalDex'] = index + 1;
  species['names'] = <String, String>{
    'en': 'Clockling $index',
    'fr': 'Horlogre $index',
  };
  (species['forms']! as Map<String, dynamic>)['baseFormId'] = speciesId;
  return species;
}

Future<void> _writeJson(File file, Map<String, Object?> value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(value),
    flush: true,
  );
}

/// Un media seme : les octets et ce qu'il faut pour les declarer.
final class _SeededMedia {
  const _SeededMedia({
    required this.mediaId,
    required this.label,
    required this.kind,
    required this.mediaType,
    required this.container,
    required this.codec,
    required this.logicalPath,
    required this.base64,
    this.width,
    this.height,
  });

  final String mediaId;
  final String label;
  final String kind;
  final String mediaType;
  final String container;
  final String codec;
  final String logicalPath;
  final String base64;
  final int? width;
  final int? height;
}
