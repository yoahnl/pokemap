# ADR-0002 — Isolation de session par plateforme

- Statut : **Accepted**
- Date : 2026-07-25
- Décisions : P0-D12, P0-D13

## Contexte

Une session peut échouer par exception, OOM, erreur de plugin ou crash natif.
Le mobile interdit ou complique fortement les processus enfants, tandis que le
desktop public doit éviter qu’un jeu ferme la bibliothèque.

## Décision

Deux adaptateurs implémentent le même `GameSessionPort` :

| Cible | Topologie | Raison |
|---|---|---|
| V0 interne, iOS, Android | même processus, graphe jetable | compatibilité plateforme et simplicité |
| macOS/Windows/Linux public | processus enfant | frontière de crash et récupération du Hub |

Sur desktop, le Hub relance **son propre binaire signé** avec le mode privé :

```text
pokemap_hub --player-session --protocol=1
```

Ce mode n’apparaît pas dans l’interface et n’accorde aucun accès direct aux
saves ou à la bibliothèque. Le token éphémère est transmis après spawn par un
pipe anonyme hérité ou un endpoint OS protégé : jamais dans argv, les variables
d’environnement, un fichier persistant ou les logs. Il autorise seulement la
session préparée par le Hub. Un binaire `pokemap_player` distinct n’est pas retenu en
V1 ; il pourra être introduit par un nouvel ADR si la signature, la sandbox ou
le packaging l’exige.

## Autorité et données

- le Hub choisit une version installée et crée un descriptor de session
  immuable ;
- le player lit exclusivement la racine de version autorisée ;
- le Hub reste propriétaire des écritures de save : l’enfant envoie un
  checkpoint sérialisé, le Hub le valide puis le persiste ;
- aucun path arbitraire n’est reçu depuis le player ;
- une seule session active est autorisée par instance de Hub.

## Supervision

- handshake `ready` : 30 secondes après spawn ;
- heartbeat : toutes les 2 secondes, session suspecte après 10 secondes ;
- arrêt gracieux : 5 secondes avant terminaison forcée ;
- crash marker écrit avant création du runtime, supprimé seulement après
  teardown et flush réussis ;
- messages versionnés et séquencés ; les inconnus critiques ferment la session ;
- stdout/stderr sont bornés, redirigés vers des logs par session et purgés selon
  la politique de rétention.

## Même processus

L’adaptateur mobile utilise un container/session scope neuf. Le retour au Hub
exige : gameplay verrouillé, checkpoint terminé ou refus explicite, overlays et
audio arrêtés, subscriptions/input détachés, assets libérables relâchés, puis
destruction du runtime. Le jeu B ne peut démarrer avant l’événement
`sessionDisposed` du jeu A.

## Recovery

Au démarrage, un crash marker résiduel produit un diagnostic et propose :
rouvrir le Hub sans jeu, inspecter les logs, vérifier/réparer le jeu, ou
réessayer. Une save temporaire non validée n’est jamais promue. Un exit enfant
non nul ne modifie ni `current.json` ni les versions installées.

## Alternatives rejetées

- même processus partout : aucune frontière contre crash natif/OOM desktop ;
- processus enfant partout : non portable sur mobile ;
- deuxième application player en V1 : coûts de signature et distribution sans
  bénéfice démontré face au mode privé du même binaire.

## Critère du prototype desktop

Un test d’intégration doit provoquer un exit non nul et un timeout du child :
le Hub reste interactif, détecte l’échec en moins de 12 secondes, conserve la
dernière save valide, affiche le bon diagnostic et peut lancer une nouvelle
session après teardown.

## Risques

La récupération OOM n’est pas garantie en même processus mobile. Le protocole
IPC et la sandbox desktop devront être durcis en Phase 4/8. Les limites de logs
et les permissions OS doivent être testées sur chaque cible.
