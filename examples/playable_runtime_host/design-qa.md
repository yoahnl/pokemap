# PokeMap Eval Web Cockpit — Design QA

## Source de vérité visuelle

- Référence : `/Users/karim/Project/pokemonProject/.superpowers/brainstorm/14071-1784849311/content/web-cockpit-timeline-refined.html`
- Implémentation : `tool/assets/pokemap_eval_web/index.html`, `app.css` et `app.js`
- Vue principale vérifiée : `1264 × 792`, densité `1×`
- Vue d’échec worker vérifiée : `1280 × 720`, densité `1×`
- Vue large vérifiée : `1440 × 900`, densité `1×`
- Vue responsive vérifiée : `1050 × 800`, densité `1×`

## États et interactions vérifiés

- état prêt avant exécution ;
- exécution headless réelle et progression en direct ;
- pause, reprise et annulation ;
- succès avec timeline complète et reçu historique rechargeable ;
- échec d’assertion avec ouverture automatique de l’onglet Diff ;
- déconnexion volontaire du worker avec échec d’infrastructure explicite ;
- inspecteur Diff, État, Trace et Preuves ;
- inspecteur responsive ouvert comme tiroir ;
- absence de débordement horizontal à `1050 × 800` ;
- zéro erreur dans la console du navigateur sur les parcours contrôlés.

La visualisation des collisions est volontairement désactivée et n’a été
utilisée dans aucun parcours ou capture : elle ne fait pas partie du cockpit
d’évaluation et son coût de rendu est incompatible avec la cible de performance.

## Comparaison et itérations

### Itération 1

- P1 — Un reçu historique était rouvert comme une exécution vide avec des
  contrôles actifs. Corrigé en reconstruisant la timeline depuis les résultats
  d’étapes du reçu et en rendant les contrôles terminaux.
- P2 — Les titres et statuts de la timeline se concaténaient sans rail visuel.
  Corrigé avec des marqueurs, une ligne de progression et des états sémantiques.

### Itération finale

- Les trois colonnes, la hiérarchie, les surfaces bleu nuit, la timeline et
  l’inspecteur correspondent à la structure de la référence.
- La typographie conserve volontairement la famille sans-serif du design system
  PokeMap plutôt que la police serif du prototype exploratoire.
- Aucun visuel produit n’est requis dans ce cockpit ; la qualité d’image est donc
  non applicable.
- Aucun problème P0, P1 ou P2 ne subsiste après la comparaison finale.

## Preuves conservées

- `evaluation/evidence/web_cockpit_phase5/reference_shell_1264x792.png`
- `evaluation/evidence/web_cockpit_phase5/success_postfix_1264x792.png`
- `evaluation/evidence/web_cockpit_phase5/comparison_postfix_1264x792.png`
- `evaluation/evidence/web_cockpit_phase5/responsive_1050x800.png`
- `evaluation/evidence/web_cockpit_phase5/responsive_inspector_1050x800.png`
- `evaluation/evidence/web_cockpit_phase5/paused_1264x792.png`
- `evaluation/evidence/web_cockpit_phase5/assertion_failure_1264x792.png`
- `evaluation/evidence/web_cockpit_phase5/worker_failure_1280x720.png`

final result: passed
