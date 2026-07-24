# Machine d’états Hub et player

## États de haut niveau

```text
bootingHub
  → recoveringLibrary?
  → hubReady
      → inspectingPackage → installing → gameDetail
      → gameDetail → playerTitle
      → playerTitle → preparingSession → loadingSession → playing
      → playing ↔ paused
      → playing → completing → result → credits
      → credits → playerTitle | disposingSession → hubReady
      → anySessionState → sessionError → disposingSession → hubReady
```

Une seule branche d’installation mutante et une seule session sont actives à
la fois. La bibliothèque reste consultable durant les opérations qui ne
nécessitent pas son verrou d’écriture.

## Transitions normatives

| Depuis | Événement/garde | Vers | Effet obligatoire |
|---|---|---|---|
| bootingHub | library valide | hubReady | supprimer crash markers résolus |
| bootingHub | journal incomplet | recoveringLibrary | replay/rollback idempotent |
| hubReady | package sélectionné | inspectingPackage | aucune extraction |
| inspectingPackage | compatible + consent | installing | staging |
| installing | promotion réussie | gameDetail | receipt puis library |
| installing | cancel/échec | hubReady | courant et saves inchangés |
| gameDetail | ouvrir | playerTitle | résoudre version courante |
| playerTitle | Continuer + save compatible | preparingSession | descriptor `continue` |
| playerTitle | Nouvelle partie + slot choisi | preparingSession | descriptor `newGame` |
| preparingSession | port prêt | loadingSession | crash marker |
| loadingSession | runtime running | playing | focus gameplay |
| loadingSession | cancel/timeout | disposingSession | diagnostic |
| playing | Menu/Start | paused | horloges/input monde suspendus |
| paused | Reprendre | playing | restaurer focus/input |
| playing | `GameCompleted` valide | completing | verrouiller gameplay |
| completing | save completed commit | result | progression library mise à jour |
| result | continuer | credits | crédits déclaratifs/localisés |
| credits | titre | playerTitle | monde déchargé |
| credits | Hub | disposingSession | teardown |
| sessionError | action quitter | disposingSession | dernière save conservée |
| disposingSession | `sessionDisposed` | hubReady | marker supprimé si propre |

## Sous-états de titre

`titleIdle`, `selectingProfile`, `selectingSlot`, `confirmingOverwrite`,
`options`, `creditsAbout`, `titleError`. Back retourne toujours au parent ou
au Hub après teardown ; il ne tue jamais une écriture en vol.

## Sous-états de pause

`pauseRoot`, `party`, `bag`, `pokedex`, `map`, `saving`, `options`,
`confirmReturnToTitle`. Boutique/soin/PC ne sont pas des sous-états globaux :
ils sont ouverts par interaction monde/capability.

## Lifecycle

Un background force `lifecyclePaused` depuis loading/playing/paused, garde
l’état précédent et demande un checkpoint si sûr. Foreground restaure vers
l’état précédent après validation. Un nouveau launch est interdit avant
`sessionDisposed`.

## Erreurs et recovery

Chaque état long a cancel/timeout. Les erreurs sont typées
`compatibility`, `integrity`, `storage`, `save`, `runtime`, `platform`.
Retry recommence depuis la dernière frontière atomique, jamais au milieu d’une
promotion. Repair et rollback reviennent au détail du jeu.

## Tests et DONE

Tests table-driven de toutes les transitions, gardes négatives, événements en
retard, double tap, back, background et crash. DONE exige qu’aucun état non
terminal ne manque timeout, cancel ou recovery.
