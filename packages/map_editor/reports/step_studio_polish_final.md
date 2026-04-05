# Step Studio — polish final UX / sémantique / cohérence

**Date :** 2026-04-05  
**Portée :** Step Studio uniquement (`step_studio_authoring`, `step_studio_workspace`, `step_studio/*`, tests ciblés). Aucune écriture Git. Aucun nouveau champ JSON. Aucune abstraction morte.

---

## 1. Résumé exécutif

**Analysé**

- Canvas, palette, inspecteur après passes 2–3 : honnêteté renforcée mais vocabulaire parfois **trop technique** (`outcomes`, `scope`, `runtime`, `worldChanges`, `completion` en sous-titres palette).
- Titres de cartes parfois **génériques** (« Progression », « Outcomes locaux ») peu parlants pour un créateur non développeur.
- Quelques **incohérences** entre les noms palette / canvas / inspecteur (ex. « Notes sortie » vs besoin d’une lecture narrative « après l’étape »).

**Choix**

- **Réécrire les chaînes UI** vers un français **naturel** : fil de l’étape, variantes, scène liée, fin d’étape, après cette étape, sur la carte — **sans** mentir sur ce qui est enregistré vs note d’aide.
- **Garder** la structure des données, l’ordre des cartes, l’absence de `flowUnlocksStepId` sur le canvas, les tests d’honnêteté existants.
- **Documenter** dans le code (commentaires) l’arbitrage « vocabulaire créateur vs noms de champs JSON stables ».

**Refusé**

- Nouveaux widgets décoratifs, nouveaux champs, renommage des clés JSON, refonte Global Story / Cutscene / runtime.

---

## 2. Audit sémantique final (sévère)

| Élément | Nature | Lu par (repo) | Risque résiduel |
|---------|--------|----------------|-----------------|
| `flowEntryLabel` | Annotation auteur (fil) | Step Studio UI + JSON | Faible si la phrase sur le fil n’est pas présentée comme seule règle — **corrigé** par « Réglage enregistré » distinct. |
| `flowObjectiveLabel` | Annotation auteur (fil) | Idem | Redondance avec `description` — **acceptée**, texte UI le dit. |
| `flowValidationLabel` | Annotation auteur (fil) | Idem | **Corrigé** : carte « Fin de l’étape » + inspecteur alignés. |
| `flowExitLabel` | Annotation auteur (fil) | Idem | OK. |
| `flowUnlocksStepId` | Mémo éditeur | Inspecteur + JSON | **Moyen** : un créateur peut croire à un enchaînement — **canvas sans id** + libellé « sans effet automatique ». |
| `activation` | Donnée structurée | Authoring, projection (résumé), futur moteur potentiel | Honnête via résumé sous la note. |
| `completion` | Donnée structurée | Idem | Idem. |
| `cutscenes` | Références réelles (id scénario projet) | Authoring + projection | OK — rappel Cutscene Studio explicite. |
| `outcomes` | Donnée structurée | Authoring + projection (ids) | **Jargon** réduit en UI (« variantes », « résultat pour l’histoire ») ; le modèle reste `outcomes`. |
| `worldChanges` | Donnée structurée | Authoring | **Jargon** réduit (« sur la carte ») ; pas de renommage JSON. |

**Ambiguïté encore possible**

- Les **identifiants techniques** (`outcomeId`, `cutsceneId`) restent visibles où nécessaire pour l’intégrité du projet — ce n’est pas du no-code pur, mais **honnête** pour un outil qui sérialise des ids.

---

## 3. Signaux mensongers — contrôle

| Piège | Statut après polish |
|-------|---------------------|
| Champ débloque une step | **Non** : texte inspecteur + absence id sur canvas. |
| Note auteur = règle moteur | **Réduit** : formulations « phrase sur le fil » vs « réglage enregistré ». |
| Cutscene éditable ici | **Non** : « contenu dans Cutscene Studio » répété. |
| Branche locale = branche runtime | **Non** : « ce n’est pas le graphe de la cutscene ». |
| Carte = structure moteur | **Non** : fil = lecture ; pas de graphe d’exécution ajouté. |

---

## 4. Équilibre no-code vs technique

**Avant** : sous-titres palette du type « Donnée : outcomes (scope local) » — correct pour un dev, froid pour un créateur.

**Après** : « Issues différentes pour la même étape », « Ce qui fait avancer le jeu global », etc. — **sans** prétendre que la donnée sous-jacente change.

**Non fait** (sur-réaction) : masquer complètement les ids dans l’inspecteur — ce serait **désinformant** pour brancher des cutscenes réelles.

---

## 5. Cohérence du canvas (ordre & lecture)

Ordre conservé (produit validé en passes précédentes) :

1. Quand ça commence  
2. Objectif  
3. Scènes liées  
4. Variantes possibles  
5. Fin de l’étape  
6. Pour l’histoire globale  
7. Après cette étape  
8. Sur la carte  

Lecture haut → bas = **parcours d’étape** puis **conséquences** (histoire + carte).

---

## 6. Modifications refusées (rappel)

- Supprimer `flowUnlocksStepId` du modèle.  
- Ajouter un « vrai » lien de déblocage Step Studio.  
- Renommer les clés JSON pour coller aux titres français.

---

## 7. Branchement réel des changements

- **Uniquement des `String` UI** (+ commentaires). Aucun nouveau consommateur, aucun nouveau producteur de données. Les tests protègent l’**honnêteté** du canvas (id mémo absent, titres présents).

---

## 8. Fichiers touchés

| Fichier | Rôle |
|---------|------|
| `step_flow_canvas.dart` | Titres, hints, en-tête, pied cutscene « Réf. projet ». |
| `step_flow_palette.dart` | Sections et sous-titres créateur. |
| `step_studio_workspace.dart` | Footnote, vide inspecteur, libellés sections flux. |
| `step_flow_focus.dart` | Commentaires d’architecture + doc enum. |
| `step_studio_authoring.dart` | Note vocabulaire UI vs JSON. |
| `test/step_flow_canvas_test.dart` | Test titres créateur. |

---

## 9. Tests exécutés

```bash
cd packages/map_editor && flutter test test/step_flow_canvas_test.dart test/step_studio_authoring_test.dart
```

**Résultat :** 7 tests, tous verts.

---

## 10. Extraits de code significatifs

### 10.1 En-tête canvas — ton « cette étape »

```dart
// step_flow_canvas.dart (extrait)
Text(
  'Cette étape',
  style: TextStyle(
    color: EditorChrome.primaryLabel(context),
    fontWeight: FontWeight.w800,
    fontSize: 15,
  ),
),
Text(
  'Du début à la fin de l’étape. Les scènes se conçoivent dans Cutscene Studio.',
  ...
),
```

**Intention :** ancrer la vue dans **une** étape de progression, pas dans un formulaire générique.

### 10.2 Carte « Après cette étape » — sans `flowUnlocksStepId`

```dart
// step_flow_canvas.dart (extrait)
_flowCard(
  context,
  focus: const StepFlowFocus(StepFlowSlot.exitNext),
  ...
  title: 'Après cette étape',
  body: step.flowExitLabel.trim().isNotEmpty
      ? Text(step.flowExitLabel, style: _emphasisStyle(context))
      : _emptyHint(
          context,
          'Phrase libre (facultative). Rappel sur une autre étape : panneau de droite.',
        ),
),
```

**Intention :** texte **visible** au centre ; mémo d’étape **déplacé** côté droit (déjà le cas depuis passe 3).

### 10.3 Palette — langage créateur

```dart
// step_flow_palette.dart (extrait)
_PaletteSectionLabel(context, 'Choix & suites'),
_paletteTile(
  context,
  icon: CupertinoIcons.tree,
  label: 'Variantes possibles',
  subtitle: 'Issues différentes pour la même étape',
  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.localBranches)),
),
```

**Intention :** parler **métier** ; la liste technique reste `outcomes` dans le code.

### 10.4 Inspecteur — distinction phrase / réglage

```dart
// step_studio_workspace.dart (extrait)
_StepSectionCard(
  title: 'Début de l’étape',
  subtitle:
      'Phrase facultative sur le fil ; en dessous, le vrai réglage « quand cette étape devient active ».',
  child: Column(
    children: [
      _InlineTextField(
        label: 'Phrase sur le fil (facultative)',
        value: selectedStep.flowEntryLabel,
        ...
      ),
      Text(
        'Réglage enregistré : ${summarizeStepActivation(selectedStep)}',
        ...
      ),
    ],
  ),
),
```

**Intention :** **pédagogique minimal** — une phrase structure la lecture sans pavé.

### 10.5 Authoring — stabilité JSON vs UI

```dart
// step_studio_authoring.dart (extrait, commentaire)
// Vocabulaire UI (fil, variante, phrase…) = confort créateur ; les noms de
// propriétés Dart / clés JSON restent `flow*` pour stabilité des sauvegardes.
```

---

## 11. Risques ouverts

- **Ids visibles** : toujours nécessaires pour un outil sérieux ; le créateur non technique peut les ignorer en lisant surtout les **titres** des cartes.
- **Global Story** : l’UI Step ne remplace pas la vision macro — si le produit attend une carte des étapes, ce n’est **pas** ici.

---

## 12. Conclusion honnête

Step Studio est **plus lisible** pour un public no-code, **sans** nouvelle couche technique et **sans** promesse runtime supplémentaire. Les compromis assumés : **garder** les noms de champs techniques dans le code/JSON et **traduire** l’expérience en langage naturel à l’écran. Toute évolution future qui **lirait** `flow*` ou `flowUnlocksStepId` côté moteur devra être **explicitement** spécifiée — ce polish ne préjuge pas de cette lecture.

---

*Fin du rapport — polish final Step Studio.*
