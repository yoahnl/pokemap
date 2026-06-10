# Roadmap Build & Maintenance

## Objectif
Suivre et documenter les lots d'infrastructures, d'environnements, de dépendances et de compatibilités de build, séparés des lots fonctionnels et documentaires métier.

## Lots de Build & Maintenance

| Lot ID | Titre | Statut | Description | Fichiers impactés |
|---|---|---|---|---|
| BUILD-MACOS-01 | macOS Deployment Target 12.0 Build Compatibility | DONE | Passage du MACOSX_DEPLOYMENT_TARGET de 10.15 à 12.0 pour compatibilité Xcode 15+. | `project.pbxproj` (map_editor et playable_runtime_host) |
