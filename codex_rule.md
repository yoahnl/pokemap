Règles obligatoires de travail Codex pour ce lot

0. Droit de remise en cause du prompt
   Avant de coder, tu dois auditer le prompt fourni.
   Tu as explicitement le droit de remettre en cause les instructions du prompt si tu détectes :
- une incohérence avec le repo ;
- une mauvaise continuité de lot ;
- un nom de lot ambigu ;
- un scope trop large ;
- une instruction dangereuse ;
- une contradiction avec l’architecture existante ;
- une meilleure stratégie plus petite et plus sûre.

Si tu remets en cause le prompt, tu dois expliquer clairement :
- quelle instruction pose problème ;
- pourquoi elle pose problème ;
- quelles preuves tu as trouvées dans le repo ;
- quelle alternative tu proposes ;
- si tu continues quand même, ce que tu changes exactement dans ton interprétation.

Tu ne dois jamais suivre aveuglément un prompt si le repo prouve que le prompt est mauvais.

1. Audit obligatoire avant implémentation
   Toujours commencer par un audit du code existant avant toute modification.
   L’audit doit identifier :
- les fichiers concernés ;
- les contrats existants ;
- les tests existants ;
- les rapports précédents pertinents ;
- les risques principaux ;
- les limites de scope à préserver.

Tu dois inclure un résumé de cet audit dans le rapport final.

2. Usage obligatoire de sub-agents
   Utiliser systématiquement des sub-agents ou, si l’environnement ne permet pas de vrais sub-agents, faire des passes séparées clairement nommées comme si elles étaient des sub-agents.

Sub-agents minimum attendus :
- Sub-agent Audit / Architecture
- Sub-agent Implémentation
- Sub-agent Tests
- Sub-agent Build / Validation
- Sub-agent Critique finale

Le rapport final doit inclure le verdict de chaque sub-agent.

3. Commentaires dans le code
   Mettre un maximum de commentaires utiles dans le code modifié ou ajouté.
   Les commentaires doivent expliquer :
- pourquoi le code existe ;
- quelle frontière de lot il protège ;
- pourquoi une décision a été prise ;
- ce qui est volontairement hors scope ;
- les invariants importants ;
- les garde-fous contre les faux comportements.

4. Rapport final obligatoire et détaillé
   Le rapport doit obligatoirement inclure :
- nom exact du lot ;
- résumé exécutif ;
- confirmation du scope ;
- audit initial ;
- état git initial ;
- liste complète de tous les fichiers modifiés ;
- pour chaque fichier modifié :
    - chemin du fichier ;
    - classes/fonctions/zones modifiées ;
    - raison de la modification ;
    - impact attendu ;
- tests créés ou modifiés ;
- commandes de test lancées ;
- résultats exacts ;
- commandes d’analyse lancées ;
- résultats exacts ;
- commande de build lancée ;
- résultat exact ;
- état git final ;
- limites explicitement conservées ;
- auto-critique finale ;
- éventuels risques restants ;
- prochaines étapes proposées sans les implémenter.

Le rapport doit aussi contenir le contenu complet de tous les fichiers créés.
Pour les fichiers modifiés, il doit montrer précisément où le code a été changé, avec diff ou découpage par zones modifiées.

5. Tests obligatoires
   Tu dois toujours créer ou modifier des tests pour couvrir le lot.
   Les tests doivent couvrir :
- le comportement positif attendu ;
- les cas négatifs ;
- les garde-fous ;
- au moins une non-régression pertinente.

Tu dois lancer les tests ciblés.
Si possible, lancer aussi la suite complète du package concerné.
Si une suite complète échoue, tu dois :
- donner le log ou le test exact qui échoue ;
- dire si l’échec semble lié au lot ;
- relancer le test suspect isolément si pertinent ;
- ne jamais prétendre que tout est vert si ce n’est pas vrai.

6. Build obligatoire
   Tu dois vérifier que l’application ou le package build correctement.
   Si le build complet n’est pas possible ou non applicable, tu dois l’indiquer explicitement avec la raison et lancer la meilleure validation alternative disponible.

7. Validation finale critique
   À la fin, lancer une passe de critique finale via sub-agent critique.
   Cette critique doit chercher activement :
- modifications inutiles ;
- effets de bord ;
- commentaires manquants ;
- tests insuffisants ;
- scopes mélangés ;
- fichiers modifiés par accident ;
- comportements non prouvés par test ;
- endroits où le code pourrait mentir à l’utilisateur ou au moteur.

8. Honnêteté obligatoire
   Ne jamais maquiller un résultat.
   Ne jamais écrire “all green” si une suite échoue.
   Ne jamais dire qu’un comportement est supporté si le moteur ne le consomme pas réellement.
   Ne jamais élargir le scope sans le signaler.
   Ne jamais modifier un autre chantier sans justification claire.
