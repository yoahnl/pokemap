import hashlib
import json
import sys
from pathlib import Path


def inventory(work):
    root = work.parents[1] / 'references/heartgold-fr'
    scripts = root / 'sources/decompilation/files/fielddata/script/scr_seq'
    rows = []
    def add(identity, label, state, source, behavior):
        path = scripts / source if source.endswith('.s') and '/' not in source else root / source
        if not path.is_file(): raise ValueError('Missing inventory witness: ' + str(path))
        rows.append({'id': identity, 'label': label, 'state': state, 'source': str(path.relative_to(root)),
            'sourceSha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'behavior': behavior})
    add('CAL-01', 'Lokhlass', 'C708_INTEGRATION', 'scr_seq_0058_D25R0103.s', 'Vendredi ; niveau20 ; issue sans défaite consomme ; C7-07 fige le jour du lancement.')
    add('CAL-02', 'Vanessa présence', 'C708_INTEGRATION', 'scr_seq_0232_R32.s', 'Vendredi ; aucun badge ; acteur natif14, position locale31,122.')
    add('CAL-03', 'Vanessa Pic Venin', 'C708_INTEGRATION', 'scr_seq_0232_R32.s', 'Un objet unique ; aucun flag ou compteur avant réception ; sac plein sans crédit du don.')
    add('CAL-04', 'Vanessa Ruban Détente', 'EXCLUDED_FUTURE_PROGRESSION', 'scr_seq_0232_R32.s', 'Sept frères et sœurs rencontrés, dont lieux futurs ; contrôle Pokémon vivant et ruban déjà possédé.')
    for identity, label, script, days in [
        ('CAL-05', 'F. Otto Route32', 'scr_seq_0232_R32.s', 'mardi/jeudi/samedi'),
        ('CAL-06', 'F. Otto extérieur Alpha', 'scr_seq_0037_D24R0101.s', 'vendredi/samedi/dimanche'),
        ('CAL-07', 'F. Otto entrée hall Alpha', 'scr_seq_0048_D24R0211.s', 'lundi/mardi/jeudi'),
        ('CAL-08', 'F. Otto variante Sinjoh', 'scr_seq_0054_D24R0217.s', 'lundi/mardi/jeudi'),
        ('CAL-09', 'F. Otto entrée Puits', 'scr_seq_0059_D26R0101.s', 'lundi/mercredi/vendredi')]:
        add(identity, label, 'EXCLUDED_FUTURE_PROGRESSION', script, 'Badge Plaine requis ; ' + days + (' ; variante Sinjoh/Arceus.' if identity == 'CAL-08' else '.'))
    for identity, label, source, entity in [
        ('CAL-10', 'Noigrumier rose Route33', 'cartes/evenements/034.json', 'hgss-noigrumier-9'),
        ('CAL-11', 'Noigrumier noir Route33', 'cartes/evenements/034.json', 'hgss-noigrumier-10'),
        ('CAL-12', 'Noigrumier blanc Écorcia', 'cartes/evenements/071.json', 'hgss-noigrumier-30')]:
        add(identity, label, 'EXISTING_PRESERVED', source, 'Cueillette quotidienne canonique déjà intégrée : ' + entity)
    add('CAL-13', 'Fargas fabrication', 'DEFERRED_C7_D1', 'scr_seq_0874_T23R0501.s', 'Fabrication différée à la refonte Pokémon/combat ; aucune Ball factice.')
    for identity, label, bank, contact in [
        ('TEL-01', 'Auffray / Ralph', '0712', 'auffray'), ('TEL-02', 'Elisabeth / Liz', '0680', 'elisabeth'),
        ('TEL-03', 'Olwen / Anthony', '0711', 'olwen'), ('TEL-04', 'Fargas / Kurt', '0661', 'fargas')]:
        source = f'dialogues/banques/{bank}.json'
        if identity == 'TEL-04': source = 'sources/decompilation/files/fielddata/script/scr_seq/scr_seq_0874_T23R0501.s'
        add(identity, label, 'EXISTING_PRESERVED', source, 'Inscription, refus/reproposition et appel sortant présents ; contact ' + contact)
    add('TEL-05', 'Hector / Bugsy', 'EXCLUDED_FUTURE_PROGRESSION', 'scr_seq_0115_D46R0101.s', 'Numéro obtenu en Forêt de Jade jeudi après GAME_CLEAR ; ne pas ajouter à Écorcia.')
    add('TEL-06', 'Autres contacts locaux', 'NO_SOURCE_CONTACT', 'sources/decompilation/files/tel/pmtel_book.json', 'Aucun autre contact résident Route32/33/Caves/Puits/Alpha ; aucun cadeau des trois dresseurs (ITEM_NONE).')
    add('TEL-07', 'Rematches des trois contacts', 'EXCLUDED_FUTURE_PROGRESSION', 'sources/decompilation/src/application/pokegear/phone/scripts/phone_scripts_generic.c', 'Après Tour Radio ; Auffray mercredi matin, Elisabeth jeudi journée, Olwen vendredi nuit.')
    add('TEL-08', 'Variantes et appels entrants', 'EXPLICITLY_DEFERRED_BY_USER', 'sources/decompilation/src/application/pokegear/phone/phone_generic_headers.c', 'Décision de Yoahn : conserver inscription/appel sortant actuel ; différer variantes et appels entrants. Certaines variantes existent sans progression future.')
    for row in rows:
        if row['id'] in {'CAL-01', 'CAL-02', 'CAL-03'}:
            row['evidence'] = ['publication-live.json', 'live-validation.json', 'preservation-final.json']
        elif row['id'] in {'CAL-10', 'CAL-11', 'CAL-12'}:
            row['evidence'] = ['../../arbres-fin/publication-live-recu.json', '../../arbres-fin/live-result.json',
                '../../preuves/sept-noigrumiers-verification.json', 'preservation-final.json']
        elif row['id'].startswith('TEL-0') and row['id'] in {'TEL-01', 'TEL-02', 'TEL-03', 'TEL-04'}:
            row['evidence'] = ['../../../ecorcia-chapitre7/preuves/contacts-integration.json', 'qa-validation.json', 'live-validation.json', 'preservation-final.json']
    return {'schema': 'heartgold.c708.inventory.v1', 'finite': True, 'entries': rows,
        'phoneScopeDecision': 'User confirmed: retain registration and current outgoing calls; explicitly defer ambience variants and incoming calls.',
        'nativeParityLimits': ['RNG des appels, scheduler entrant, rubans et photos non reproduits par C7-08.', 'Aucun statut FG global promu.']}


if __name__ == '__main__':
    work = Path(sys.argv[1]).resolve()
    result = inventory(work)
    target = work / 'revisites/c7-08/inventory.json'
    if target.exists(): raise ValueError('Preserve the finite inventory.')
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'entries': len(result['entries'])}))
