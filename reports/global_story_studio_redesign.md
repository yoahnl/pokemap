# Refonte du Global Story Studio (PokeMap) — rapport de redesign

**Date (contexte projet)** : avril 2026  
**Périmètre** : vue **Histoire globale** dans le Narrative Studio (`packages/map_editor`).  
**Objectif** : repartir d’une conception **produit / no-code**, alignée sur un studio narratif lisible (navigation + fil + détail), **sans** itération incrémentale de l’ancienne « macro-carte » fourre-tout.

---

## 1. Ce qui n’allait pas dans l’ancienne approche

### 1.1 Problèmes UX

- **Écran monolithique** mélangeant résumés, chapitres, liste projet, actions d’édition et pédagogie dans une seule colonne difficile à parcourir.
- **Hiérarchie visuelle faible** : tout semblait au même niveau d’importance ; difficile de répondre en quelques secondes à « où en est l’histoire ? ».
- **Lecture du flux global peu naturelle** : pas de **fil narratif vertical** clair comme référence mentale (contrairement à l’intention produit décrite pour PokeMap).
- **Panneau de détail dispersé** : l’inspecteur narratif n’était pas structuré comme un **fiche métier** (entrée → résultats → débloque → scènes).
- **Friction plateforme** : certains flux utilisaient des motifs très « iOS action sheet » au milieu d’un shell macOS/desktop.

### 1.2 Problèmes structurels (code)

- Un fichier unique très volumineux (`global_story_macro_editor.dart`) concentrait **présentation + wording + gestes + chrome**, ce qui rendait toute évolution risquée.
- La composition d’écran ne reflétait pas le **modèle mental** « studio en 4 zones » (top bar, nav, canvas, inspecteur).
- Du code mort / du legacy restait dans `global_story_studio_workspace.dart` après itérations successives (helpers de graphe non branchés) — dette technique.

---

## 2. Principes de redesign retenus

1. **Séparation stricte des niveaux** (rappel produit)  
   - **Histoire globale** = macro-progression, chapitres, enchaînements, embranchements **macro**.  
   - **Step** = logique métier locale (reste dans Step Studio).  
   - **Cutscene** = exécution de scène (hors périmètre d’édition ici).

2. **Vocabulaire no-code**  
   - Privilégier : *étape*, *chapitre*, *embranchement*, *convergence*, *débloque / mène à*, *résultat narratif*, *scènes liées*.  
   - Éviter : *node*, *edge*, *graph*, *signal*, *ref*, etc.

3. **Pas de graphe libre**  
   - Le centre n’est **pas** un node-editor infini : c’est un **fil vertical maîtrisé**, avec embranchements **latéraux** et re-convergence **explicite** lorsque le modèle de données le permet.

4. **Trois colonnes + top bar**  
   - Aligné sur le wireframe cible : ancrage, navigation, lecture du fil, détail de l’étape sélectionnée.

5. **Ne pas casser le domaine**  
   - Même document `GlobalStoryStudioDocument` + `StepStudioDocument`, mêmes callbacks de mutation côté workspace (sauvegarde, chapitres, ordre, point d’entrée, etc.).

---

## 3. Hiérarchie de l’écran implémentée

### 3.1 Top bar

- **Fil d’Ariane** : `Studio narratif › Histoire globale` (ton produit, en français).
- **Sélecteur de filière** : liste des scénarios `globalStory` du projet (souvent un seul item aujourd’hui ; extensible).
- **Actions** : `Réinitialiser`, `Tester` (désactivé + infobulle « bientôt »), `Valider` (persiste le brouillon), `+ Nouvelle étape`.
- **Bandeau d’état** : mention des modifications non enregistrées lorsque pertinent.

**Note UX** : `Valider` est l’équivalent produit du flux « je fige ma structure » ; le branchement technique reste le `onSave` existant du workspace.

### 3.2 Colonne gauche — navigation narrative

- Titre de section **STRUCTURE / Votre récit**.
- **Statistiques lisibles** : `N chapitres · M étapes` (ancrage immédiat sur la taille du récit).
- **Cartes chapitre** (`CH.n`) avec :
  - titre éditable (clé de test stable `macro_chapter_name_{id}`),
  - déplacement haut/bas, suppression,
  - liste des étapes (sélection = même état que le centre / droite),
  - actions compactes par ligne (déplacer / retirer du chapitre),
  - bouton **+ Ajouter une étape à ce chapitre…** (clé `macro_add_step_to_chapter_{id}`) ouvrant le sélecteur macOS avec filtrage des étapes déjà présentes.

### 3.3 Colonne centrale — fil narratif

- Titre **FIL NARRATIF / Progression globale** + courte phrase pédagogique.
- Rendu basé sur des **blocs** calculés par `buildGlobalStoryFlowBlocks` :
  - **Blocs linéaires** : enchaînement vertical d’étapes.
  - **Blocs d’embranchement** : étape « pivot », colonnes par bras, fusion éventuelle vers une étape commune détectée.
  - **Blocs notice** : messages calmes en cas de cycle ambigu ou de données incomplètes (pas d’erreur agressive).

**Carte d’étape** (centre) : nom fort, badge métier (Départ / Étape principale / Embranchement / …), résumé optionnel, indices de sortie en mode large ; mode **étroit** automatique sous contrainte de largeur (colonnes de branches).

### 3.4 Colonne droite — détail de l’étape

Sections structurées :

- **Entrée** (activation traduite en langage métier),
- **Résultats narratifs possibles** (outcomes de la step),
- **Changements dans le monde** (via projection narrative quand disponible),
- **Débloque / mène à** (liens macro),
- **Scènes liées** (compte de cutscenes — renvoie vers Step Studio plutôt qu’un mini-éditeur ici),
- **Rappel automatique** (résumé d’activation issu de la projection, utile pour cohérence trans-package).

Actions en bas : **Ouvrir Step**, **Voir cutscenes** (désactivé si aucune scène listée), **Définir comme point de départ** (si pertinent).

---

## 4. Composants et fichiers créés

| Fichier | Rôle |
|--------|------|
| `lib/src/ui/canvas/global_story_studio/global_story_flow_layout.dart` | **Logique pure** de découpe du graphe macro en blocs UI (linéaire / branche / notice). Nombreux commentaires sur limites & évolution. |
| `lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart` | **Assemblage** des 4 zones + branchement des callbacks + enrichissement projection. |
| `lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart` | **Widgets** : top bar, navigation, fil, panneau détail (+ petits helpers UI). |
| `lib/src/ui/canvas/global_story_studio_workspace.dart` | **Intégration** : remplace l’usage de l’ancien `GlobalStoryMacroEditor` par `GlobalStoryStudioShell`. |

**Supprimé** : `global_story_macro_editor.dart` (ancienne implémentation monolithique).

---

## 5. Choix de layout et contraintes techniques

- **Row principale** : largeurs fixes pour nav (248) et détail (300), zone centrale **Expanded** — lecture « studio » stable.
- **Top bar** : deux demi-espaces **Expanded** + scroll horizontal interne pour éviter les **overflows** sur petites largeurs (tests widget 1280×900 inclus).
- **Cartes de fil** : `LayoutBuilder` pour basculer automatiquement en **mise en page étroite** (titre + badge empilés) lorsque la largeur utile est faible (colonnes de branches).
- **Liste macOS** : réutilisation de `showMacosListPicker` (déjà harmonisée avec `MacosTheme` de secours dans l’éditeur).

---

## 6. Vocabulaire UI (français produit)

- Étapes, chapitres, embranchement, convergence, départ, valider, scènes liées, résultats narratifs.
- Les termes techniques du domaine (`outcomeId`, etc.) ne sont montrés **que** en secours si le libellé métier est vide.

---

## 7. Règles « philosophie no-code » appliquées

- Montrer **la progression** et **ce qui débloque quoi**, pas la mécanique runtime.
- Ne pas éditer le **script** de cutscene dans cet écran.
- Préférer **guidage** (textes de section, notices) à des codes d’erreur bruts.
- Garder une **surface calme** (nuances de gris, hiérarchie typo, cartes aérées).

---

## 8. Tests

- `global_story_studio_behavior_test.dart` et `global_story_studio_ux_test.dart` mis à jour (libellé stats `étapes`, interaction picker sans `scrollUntilVisible` ambigu).
- Validation locale : `flutter test test/global_story_studio_behavior_test.dart test/global_story_studio_ux_test.dart`.

---

## 9. Pistes d’amélioration futures

1. **Graphe plus riche** : affiner l’algorithme de convergence (aujourd’hui : intersection de reachabilité bornée + ordre métier des steps) pour couvrir des cas narratifs plus complexes sans perdre la lisibilité.
2. **Arcs nommés** : aujourd’hui, les « arcs » du wireframe sont modélisés comme des **chapitres** au niveau données ; on pourra introduire un type `arc`/`lane` distinct si le modèle produit le exige.
3. **Tester** : brancher un playtest narratif global sur le bouton `Tester`.
4. **Édition des liens macro** : ajouter des actions guidées (« ajouter une sortie », « fusion ») **sans** transformer le centre en blueprint technique.
5. **Nettoyage workspace** : supprimer les helpers privés désormais inutilisés dans `global_story_studio_workspace.dart` (graphe / inspecteur inline legacy) pour réduire le bruit et les avertissements d’analyse statique.
6. **Accessibilité** : audits contrastes / tailles dynamiques / navigation clavier sur la grille 3 colonnes.

---

## 10. Honnêteté produit (limites actuelles)

- Le wireframe ChatGPT montrait un scénario **exemple** (starter → 3 routes → convergence) : le rendu réel dépend du **contenu** `GlobalStoryStudioDocument` (modes de sortie, liens, chapitres). Sur un projet linéaire, le fil reste volontairement **simple**.
- La vue ne remplace pas l’inspecteur complet du **Step Studio** : elle **oriente** et **cadre** la macro-structure.

---

## 11. Conclusion

Cette refonte **ne patche pas** l’ancienne UI : elle **recompose** l’écran selon un modèle de studio narratif (top bar + 3 colonnes), avec un module de layout **testable** et **commenté**, tout en **préservant** le modèle de données et les flux de sauvegarde existants. La base est pensée pour évoluer vers un outil PokeMap plus large, tout en restant compréhensible pour un auteur non développeur.
