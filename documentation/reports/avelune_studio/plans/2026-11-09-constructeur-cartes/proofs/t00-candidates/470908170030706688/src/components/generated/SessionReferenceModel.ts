export type Profile = 'twoD' | 'threeD';
export type Scenario = 'readonly' | 'recovery' | 'conflict' | 'draft';
export type Stage = 'ready' | 'working' | 'saving' | 'recovered' | 'reloaded' | 'kept' | 'closed';
export type Dialog = 'close' | 'discard' | 'reload' | 'profile' | 'rollback' | null;
export type Model = {
  profile: Profile;
  scenario: Scenario;
  stage: Stage;
  dialog: Dialog;
  selection: string | null;
  title: string;
  dirty: boolean;
  error: string | null;
  notice: string | null;
  pendingProfile: Profile | null;
  recovery: 'resume' | 'rollback';
};
export type Action =
  | {type: 'scenario'; scenario: Scenario}
  | {type: 'profile'; profile: Profile}
  | {type: 'confirmProfile'}
  | {type: 'cancel'}
  | {type: 'select'; id: string}
  | {type: 'title'; title: string}
  | {type: 'close'}
  | {type: 'discard'}
  | {type: 'confirmDiscard'}
  | {type: 'saveClose'}
  | {type: 'saveDone'; failed: boolean}
  | {type: 'chooseRecovery'; recovery: 'resume' | 'rollback'}
  | {type: 'recover'}
  | {type: 'confirmRollback'}
  | {type: 'recoverDone'; failed: boolean}
  | {type: 'keep'}
  | {type: 'reload'}
  | {type: 'confirmReload'};

export const project = (profile: Profile) => profile === 'twoD'
  ? {name: 'Johto · édition 2D', path: 'Projets / Johto 2D', maps: ['Bourg Geon', 'Route 29', 'Maison de Maman'], ids: ['twoD-bourg', 'twoD-route', 'twoD-room'], revision: '42', content: '24 cartes · 48 images sources', resources: 'Tuiles, personnages et images', detail: 'Vue du dessus · tuiles 16 × 16'}
  : {name: 'Johto · édition 3D', path: 'Projets / Johto 3D', maps: ['Bourg Geon', 'Route 29', 'Laboratoire'], ids: ['threeD-bourg', 'threeD-route', 'threeD-lab'], revision: '42', content: '24 cartes · 16 modèles 3D', resources: 'Modèles, surfaces et matériaux', detail: 'Vue spatiale · décors et reliefs'};

export function initialModel(profile: Profile = 'threeD', scenario: Scenario = 'readonly'): Model {
  return {profile, scenario, stage: 'ready', dialog: scenario === 'draft' ? 'close' : null, selection: null, title: 'Entrée du laboratoire', dirty: scenario === 'draft' || scenario === 'conflict', error: null, notice: null, pendingProfile: null, recovery: 'resume'};
}

export const busy = (model: Model) => model.stage === 'working' || model.stage === 'saving';

export function sessionReducer(model: Model, action: Action): Model {
  if (busy(model) && action.type !== 'saveDone' && action.type !== 'recoverDone') return model;
  switch (action.type) {
    case 'scenario': return initialModel(model.profile, action.scenario);
    case 'profile':
      if (action.profile === model.profile) return model;
      return model.dirty ? {...model, dialog: 'profile', pendingProfile: action.profile} : initialModel(action.profile, model.scenario);
    case 'confirmProfile': return model.pendingProfile ? initialModel(model.pendingProfile, model.scenario) : model;
    case 'cancel': return {...model, dialog: null, pendingProfile: null};
    case 'select': return project(model.profile).ids.includes(action.id) ? {...model, selection: action.id} : model;
    case 'title': return model.scenario === 'draft' || model.scenario === 'conflict' ? {...model, title: action.title, dirty: true} : model;
    case 'close': return model.dirty ? {...model, dialog: 'close', error: null} : {...model, stage: 'closed', dialog: null};
    case 'discard': return {...model, dialog: 'discard'};
    case 'confirmDiscard': return model.dialog === 'discard' ? {...model, stage: 'closed', dialog: null, dirty: false, notice: 'Le projet est fermé. La dernière version enregistrée reste disponible.'} : model;
    case 'saveClose': return model.scenario === 'draft' && model.dirty ? {...model, stage: 'saving', dialog: 'close', error: null} : model;
    case 'saveDone':
      if (model.stage !== 'saving') return model;
      return action.failed ? {...model, stage: 'ready', dialog: 'close', error: 'L’enregistrement n’a pas abouti. Votre brouillon est toujours ouvert ; le projet n’a pas été fermé.'} : {...model, stage: 'closed', dialog: null, dirty: false, notice: 'Les modifications sont enregistrées, puis le projet est fermé.'};
    case 'chooseRecovery': return {...model, recovery: action.recovery, error: null};
    case 'recover': return model.scenario !== 'recovery' ? model : model.recovery === 'rollback' ? {...model, dialog: 'rollback'} : {...model, stage: 'working', error: null};
    case 'confirmRollback': return model.dialog === 'rollback' ? {...model, dialog: null, stage: 'working', error: null} : model;
    case 'recoverDone':
      if (model.stage !== 'working') return model;
      return action.failed ? {...model, stage: 'ready', error: 'La reprise n’a pas pu être terminée. Les données d’origine et les éléments de récupération restent conservés.'} : {...model, stage: 'recovered', selection: null, dirty: false, notice: model.recovery === 'resume' ? 'La session peut être rouverte après la reprise de l’écriture.' : 'La dernière version complète est prête à être rouverte.'};
    case 'keep': return {...model, stage: 'kept', dialog: null, notice: 'Votre brouillon reste dans cette session. L’enregistrement demeure bloqué tant que le conflit n’est pas résolu.'};
    case 'reload': return {...model, dialog: 'reload'};
    case 'confirmReload': return model.dialog === 'reload' ? {...model, stage: 'reloaded', dialog: null, title: 'Arrivée au laboratoire', dirty: false, selection: null, notice: 'La version sur disque est rechargée. Les anciennes modifications de cette session ont été abandonnées après confirmation.'} : model;
  }
}
