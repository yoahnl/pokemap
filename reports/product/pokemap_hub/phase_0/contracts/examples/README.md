# Payloads des fixtures manifest

Les dossiers `payload/` contiennent les octets utilisés pour vérifier les
tailles et SHA-256 des manifests valides.

- les fichiers texte sont hashés tels quels, newline finale incluse ;
- `complete-valid/payload/presentation/icon.png.base64` est un transport texte
  nécessaire au repository documentaire : le test décode le base64, sans
  whitespace, vers le path logique `presentation/icon.png` avant calcul ;
- le fichier `.base64` n’est jamais une entrée du package ;
- la fixture projet est minimale pour les tests de contrat distribution, pas
  une preuve de smoke runtime. La Phase 1/3 ajoutera un projet neutre complet.
