import React, { useEffect, useReducer, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, BookOpen, Check, CheckCircle2, ChevronDown, CircleAlert, Clock3, FileClock, FileText, Folder, FolderOpen, HardDrive, History, Info, Layers, LockKeyhole, LogOut, Map, Mountain, RefreshCw, Save, ShieldCheck, Sparkles, X } from 'lucide-react';
import { busy, initialModel, project, sessionReducer, type Profile, type Scenario } from './SessionReferenceModel';
import './SessionReference.css';
const states: {
  id: Scenario;
  title: string;
  subtitle: string;
  icon: typeof LockKeyhole;
  number: string;
}[] = [{
  id: 'readonly',
  title: 'Lecture seule',
  subtitle: 'Consulter un catalogue portable',
  icon: LockKeyhole,
  number: '01'
}, {
  id: 'recovery',
  title: 'Récupération',
  subtitle: 'Reprendre une écriture interrompue',
  icon: History,
  number: '02'
}, {
  id: 'conflict',
  title: 'Conflit',
  subtitle: 'Choisir quelle version conserver',
  icon: FileClock,
  number: '03'
}, {
  id: 'draft',
  title: 'Fermeture avec brouillon',
  subtitle: 'Enregistrer, rester ou abandonner',
  icon: LogOut,
  number: '04'
}];
function ProfileMap({
  profile
}: {
  profile: Profile;
}) {
  const prefix = `s019-${profile}`;
  return <svg viewBox="0 0 300 150" aria-label={profile === 'twoD' ? 'Carte 2D schématique vue du dessus' : 'Carte 3D schématique en perspective'} role="img">
    <defs><pattern id={prefix} width="20" height="20" patternUnits="userSpaceOnUse"><path d="M20 0H0V20" fill="none" stroke="#75a18d" strokeOpacity=".25" /></pattern></defs>
    <g transform={profile === 'threeD' ? 'translate(150,12) scale(1,.52) rotate(45) translate(-110,0)' : 'translate(20,8)'}>
      <rect width="260" height="132" rx="3" fill="#395e50" />
      <rect width="260" height="132" fill={`url(#${prefix})`} />
      <path d="M0 77H260M117 0V132" stroke="#b6a785" strokeWidth="21" />
      {[27, 175].map((x, i) => <g key={x} transform={`translate(${x},${i ? 88 : 13})`}><rect x="3" y="5" width="49" height="29" fill="#b0b7a8" /><path d="M-2 1L25-10 53 1V14H-2Z" fill="#507a96" /><rect x="21" y="19" width="10" height="15" fill="#263f50" /></g>)}
      {[16, 47, 80, 203, 233].map(x => <g key={x}><circle cx={x} cy="119" r="10" fill="#244c3b" /><circle cx={x} cy="115" r="8" fill="#527c56" /></g>)}
    </g>
    {profile === 'threeD' && <path d="M38 85l112 57 112-57v8l-112 57L38 93z" fill="#304d47" />}
  </svg>;
}
export const AveluneStudioRUI019Sessions2DEt3D = () => {
  const params = new URLSearchParams(typeof window === 'undefined' ? '' : window.location.search);
  const initialProfile: Profile = params.get('profile') === 'twoD' ? 'twoD' : 'threeD';
  const initialScenario = states.some(s => s.id === params.get('state')) ? params.get('state') as Scenario : 'readonly';
  const [model, dispatch] = useReducer(sessionReducer, undefined, () => initialModel(initialProfile, initialScenario));
  const [failure, setFailure] = useState(false);
  const [details, setDetails] = useState(false);
  const dialogRef = useRef<HTMLDivElement>(null);
  const active = states.find(s => s.id === model.scenario)!;
  const data = project(model.profile);
  const working = busy(model);
  const closed = model.stage === 'closed';
  const readOnly = model.scenario === 'readonly';
  const selected = model.selection ? data.maps[data.ids.indexOf(model.selection)] : null;
  useEffect(() => {
    if (!working) return;
    const type = model.stage === 'saving' ? 'saveDone' : 'recoverDone';
    const timer = setTimeout(() => dispatch({
      type,
      failed: failure
    }), 1300);
    return () => clearTimeout(timer);
  }, [model.stage, failure, working]);
  useEffect(() => {
    if (!model.dialog) return;
    const previous = document.activeElement as HTMLElement | null;
    const panel = dialogRef.current;
    const initialFocus = panel?.querySelector<HTMLElement>('[data-initial-focus]:not(:disabled)');
    if (initialFocus) initialFocus.focus(); else panel?.focus();
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !working) {
        event.preventDefault();
        dispatch({
          type: 'cancel'
        });
      }
      if (event.key !== 'Tab' || !panel) return;
      const controls = Array.from(panel.querySelectorAll<HTMLElement>('button:not(:disabled), input:not(:disabled), select:not(:disabled), [tabindex="0"]'));
      if (!controls.length) {
        event.preventDefault();
        return;
      }
      const first = controls[0],
        last = controls[controls.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last?.focus();
      }
      if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first?.focus();
      }
    };
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('keydown', onKey);
      previous?.focus();
    };
  }, [model.dialog, working]);
  const chooseState = (scenario: Scenario) => {
    setDetails(false);
    dispatch({
      type: 'scenario',
      scenario
    });
  };
  const tone = model.scenario === 'recovery' || model.scenario === 'conflict' ? 'warning' : 'blue';
  const StateIcon = active.icon;
  return <div className="sr-root"><div className="sr-preview" inert={model.dialog ? true : undefined}>
    <div className="sr-reference-bar"><span><Sparkles size={14} /> Référence candidate <b>Session de projet</b></span><span>RUI-019 <i /> Données de démonstration · aucune écriture réelle</span></div>
    <header className="sr-header"><div className="sr-brand">Avelune<span>STUDIO</span></div><span className="sr-header-divider" /><FolderOpen size={17} /><strong>{data.name}</strong><span className="sr-profile-tag">{model.profile === 'twoD' ? '2D' : '3D'}</span><div className="sr-header-spacer" /><span className="sr-session-indicator"><i className={model.dirty ? 'is-dirty' : ''} />{closed ? 'Projet fermé' : model.dirty ? 'Modifications non enregistrées' : readOnly ? 'Consultation' : 'Session de projet'}</span><button className="sr-btn" disabled={working || closed} onClick={() => dispatch({
        type: 'close'
      })}><LogOut size={15} />Fermer le projet</button><span className="sr-avatar">Y</span></header>
    <div className="sr-layout">
      <aside className="sr-sidebar"><div className="sr-side-heading"><span className="sr-eyebrow">EXPLORER LES ÉTATS</span><h2>Une session, quatre situations.</h2><p>Choisissez un état pour examiner les décisions proposées.</p></div><nav aria-label="États de session">{states.map(state => <button key={state.id} aria-current={model.scenario === state.id ? 'page' : undefined} disabled={working} onClick={() => chooseState(state.id)}><span className="sr-state-number">{state.number}</span><span><strong>{state.title}</strong><small>{state.subtitle}</small></span><ArrowRight size={14} /></button>)}</nav><div className="sr-profile-control"><label htmlFor="sr-profile">Profil du projet de référence</label><select id="sr-profile" aria-label="Profil du projet de référence" disabled={working} value={model.profile} onChange={event => dispatch({
            type: 'profile',
            profile: event.target.value as Profile
          })}><option value="twoD">Projet 2D · vue du dessus</option><option value="threeD">Projet 3D · vue spatiale</option></select><p>Le contexte change ; les garanties de conservation restent identiques.</p></div><div className="sr-fixture-control"><label><input type="checkbox" checked={failure} disabled={working} onChange={event => setFailure(event.target.checked)} /> Montrer l’issue d’échec</label><p>Pour la reprise et l’enregistrement avant fermeture.</p></div><div className="sr-side-bottom"><ShieldCheck size={18} /><span>Des choix explicites.<br /><strong>Vos données restent les vôtres.</strong></span></div></aside>
      <main className="sr-main">
        <div className="sr-breadcrumb"><Folder size={14} />Projets<ChevronDown size={12} /><span>{data.name}</span><span>/</span><strong>Session</strong></div>
        <div className="sr-page-heading"><div className={`sr-page-icon ${tone}`}><StateIcon size={24} /></div><div><span className="sr-eyebrow">SESSION DE PROJET</span><h1>{closed ? 'Le projet est fermé' : active.title}</h1><p>{closed ? 'Vous pouvez retrouver ce projet dans vos projets récents.' : active.subtitle}</p></div><span className="sr-step-label">État {active.number} / 04</span></div>

        {closed ? <section className="sr-card sr-success-panel"><div className="sr-success-icon"><CheckCircle2 size={31} /></div><h2>Vous pouvez quitter cet espace.</h2><p>{model.notice ?? 'La consultation est terminée. Le catalogue d’origine est conservé.'}</p><div className="sr-preserved"><ShieldCheck size={17} /><span>La version enregistrée reste disponible.</span></div><button className="sr-btn primary" onClick={() => chooseState(model.scenario)}>Revenir à cet exemple<ArrowRight size={15} /></button></section> : readOnly ? <>
          <div className="sr-banner blue"><LockKeyhole size={20} /><div><strong>Ce catalogue s’ouvre en lecture seule</strong><p>Vous pouvez consulter ses cartes et ses ressources. L’édition et l’enregistrement sont indisponibles pour ce catalogue portable.</p></div><span className="sr-badge">Catalogue portable</span></div>
          <section className="sr-card"><div className="sr-card-heading"><div><h2>Parcourir le projet</h2><p>Les originaux restent inchangés.</p></div><button className="sr-btn" disabled title="Un catalogue portable ne peut pas être enregistré depuis cette consultation."><Save size={15} />Enregistrer</button></div><div className="sr-browser"><div className="sr-map-list">{data.maps.map((name, i) => <button key={data.ids[i]} aria-pressed={model.selection === data.ids[i]} onClick={() => dispatch({
                  type: 'select',
                  id: data.ids[i]
                })}><Map size={17} /><span>{name}<small>{i === 0 ? 'Carte de départ' : i === 1 ? 'Extérieur' : 'Intérieur'}</small></span><ArrowRight size={14} /></button>)}</div><div className="sr-map-detail"><ProfileMap profile={model.profile} /><div><span className="sr-eyebrow">{selected ? 'CARTE CONSULTÉE' : 'APERÇU DU PROJET'}</span><h3>{selected ?? 'Bourg Geon'}</h3><p>{data.detail}</p><label>Nom de la carte<input aria-label="Nom de la carte consultée" disabled value={selected ?? 'Bourg Geon'} readOnly /></label><small className="sr-lock-caption"><LockKeyhole size={12} />Consultation uniquement</small></div></div></div></section>
          <div className="sr-inline-info"><Info size={16} /><p>Pour modifier un projet, ouvrez son dossier éditable depuis l’accueil. Ce catalogue n’est pas converti automatiquement.</p></div>
        </> : model.scenario === 'recovery' ? <>
          {model.stage === 'recovered' ? <section className="sr-card sr-success-panel"><div className="sr-success-icon"><CheckCircle2 size={31} /></div><h2>La reprise est terminée.</h2><p>{model.notice}</p><div className="sr-preserved"><ShieldCheck size={17} /><span>La copie de sécurité reste disponible pour vérification.</span></div><button className="sr-btn primary" onClick={() => chooseState('recovery')}>Revoir cet exemple<ArrowRight size={15} /></button></section> : <>
            <div className="sr-banner warning"><History size={21} /><div><strong>Une écriture interrompue a été retrouvée</strong><p>Choisissez comment reprendre la session. Aucune récupération ne démarre sans votre accord.</p></div></div>
            <section className="sr-card"><div className="sr-card-heading"><div><h2>Deux repères pour reprendre sereinement</h2><p>Projet d’exemple · interruption à 14:18</p></div><span className="sr-badge"><Clock3 size={12} />Aujourd’hui</span></div><div className="sr-version-grid"><div><span className="sr-version-icon"><HardDrive size={20} /></span><small>DERNIÈRE VERSION COMPLÈTE</small><h3>Enregistrement de 14:12</h3><p>Révision 42 · données complètes</p><span className="sr-safe-line"><ShieldCheck size={13} />Copie de sécurité conservée</span></div><div><span className="sr-version-icon warning"><FileClock size={20} /></span><small>ÉCRITURE INTERROMPUE</small><h3>Modification de 14:18</h3><p>Entrée du laboratoire · carte et arrivée</p><span className="sr-muted">Reprise à vérifier avant application</span></div></div><div className="sr-option-list"><label className={model.recovery === 'resume' ? 'is-selected' : ''}><input type="radio" name="recovery" checked={model.recovery === 'resume'} disabled={working} onChange={() => dispatch({
                    type: 'chooseRecovery',
                    recovery: 'resume'
                  })} /><span><strong>Reprendre l’écriture interrompue</strong><small>Terminer la reprise existante, puis rouvrir la session.</small></span><span className="sr-badge">Recommandé</span></label><label className={model.recovery === 'rollback' ? 'is-selected' : ''}><input type="radio" name="recovery" checked={model.recovery === 'rollback'} disabled={working} onChange={() => dispatch({
                    type: 'chooseRecovery',
                    recovery: 'rollback'
                  })} /><span><strong>Revenir à la dernière version complète</strong><small>Abandonner l’écriture inachevée après confirmation.</small></span></label></div>{model.error && <div className="sr-error" role="alert"><CircleAlert size={18} /><span>{model.error}</span></div>}<footer className="sr-card-footer"><span><ShieldCheck size={15} />Les éléments de récupération sont conservés en cas d’échec.</span><button className="sr-btn primary" disabled={working} onClick={() => dispatch({
                  type: 'recover'
                })}>{working ? <><RefreshCw className="sr-spin" size={15} />Reprise en cours…</> : <><RefreshCw size={15} />{model.error ? 'Réessayer la reprise' : 'Continuer'}</>}</button></footer></section>
          </>}
        </> : model.scenario === 'conflict' ? <>
          <div className={`sr-banner ${model.stage === 'reloaded' ? 'success' : 'warning'}`}><FileClock size={21} /><div><strong>{model.stage === 'reloaded' ? 'La version sur disque est rechargée' : 'Le projet a changé depuis son ouverture'}</strong><p>{model.stage === 'reloaded' ? model.notice : 'Une autre écriture a modifié ce projet. Votre brouillon reste disponible ; il ne remplace pas la nouvelle version.'}</p></div></div>
          <section className="sr-card"><div className="sr-card-heading"><div><h2>Comparer avant de décider</h2><p>Une différence dans l’arrivée du laboratoire.</p></div><span className="sr-badge warning">{model.stage === 'reloaded' ? 'Conflit résolu' : 'Enregistrement bloqué'}</span></div><div className="sr-comparison"><div><div className="sr-compare-title"><span><FileText size={17} />Cette session</span><span className="sr-badge">{model.dirty ? 'Brouillon' : 'À jour'}</span></div><dl><dt>{model.stage === 'reloaded' ? 'Version chargée' : 'Version de départ'}</dt><dd>{model.stage === 'reloaded' ? 'Révision 43 · 14:23' : 'Révision 42 · 14:12'}</dd><dt>Nom de l’arrivée</dt><dd>{model.title}</dd><dt>Position</dt><dd>{model.stage === 'reloaded' ? 'X 12 · Y 8' : 'X 11 · Y 8'}</dd></dl></div><div><div className="sr-compare-title"><span><HardDrive size={17} />Sur disque</span><span className="sr-badge blue">{model.stage === 'reloaded' ? 'Même version' : 'Plus récent'}</span></div><dl><dt>Dernière écriture</dt><dd>Révision 43 · 14:23</dd><dt>Nom de l’arrivée</dt><dd>Arrivée au laboratoire</dd><dt>Position</dt><dd>X 12 · Y 8</dd></dl></div></div>{details && <div className="sr-diagnostic"><ShieldCheck size={17} /><div><strong>Aucun remplacement automatique</strong><p>Le projet sur disque et le brouillon de la session restent distincts. Recharger demande une confirmation explicite ; garder le brouillon ne débloque pas l’enregistrement.</p></div></div>}<button className="sr-text-button" onClick={() => setDetails(!details)}>{details ? 'Masquer les détails' : 'Comprendre ce conflit'}<ChevronDown size={14} /></button>{model.notice && model.stage === 'kept' && <p className="sr-feedback" role="status">{model.notice}</p>}<footer className="sr-card-footer"><button className="sr-btn" disabled={model.stage === 'reloaded'} onClick={() => dispatch({
                type: 'keep'
              })}>Garder ma session</button><button className="sr-btn primary" disabled={model.stage === 'reloaded'} onClick={() => dispatch({
                type: 'reload'
              })}><RefreshCw size={15} />Recharger la version sur disque</button></footer></section>
        </> : <>
          <div className="sr-banner blue"><FileText size={20} /><div><strong>Votre brouillon est toujours dans cette session</strong><p>Choisissez de l’enregistrer avant de fermer, de continuer à travailler ou d’abandonner explicitement ses modifications.</p></div></div><section className="sr-card"><div className="sr-card-heading"><div><h2>Entrée du laboratoire</h2><p>Carte · Bourg Geon / Arrivées</p></div><span className="sr-badge warning">1 modification</span></div><div className="sr-draft-editor"><label>Nom de l’arrivée<input aria-label="Nom de l’arrivée" value={model.title} onChange={event => dispatch({
                  type: 'title',
                  title: event.target.value
                })} /></label><div className="sr-draft-change"><span>Version enregistrée</span><strong>Arrivée du laboratoire</strong><ArrowRight size={17} /><span>Brouillon</span><strong>{model.title || 'Sans nom'}</strong></div></div><footer className="sr-card-footer"><span><Clock3 size={15} />Dernier enregistrement · 14:12</span><button className="sr-btn" onClick={() => dispatch({
                type: 'close'
              })}><LogOut size={15} />Fermer le projet</button></footer></section>
        </>}
        <div className="sr-main-bottom"><span><ShieldCheck size={14} />Aucun original n’est réinitialisé automatiquement.</span><span>{model.profile === 'twoD' ? 'Profil 2D' : 'Profil 3D'} · {active.title}</span></div>
      </main>
      <aside className="sr-context"><span className="sr-eyebrow">PROJET DE RÉFÉRENCE</span><div className="sr-context-map"><ProfileMap profile={model.profile} /><span>{model.profile === 'twoD' ? 'VUE DU DESSUS' : 'VUE SPATIALE'}</span></div><h2>{data.name}</h2><p>{data.path}</p><div className="sr-context-stat"><Map size={17} /><div><strong>{data.content}</strong><small>Contenu d’exemple</small></div></div><div className="sr-context-stat"><Layers size={17} /><div><strong>{data.resources}</strong><small>{model.profile === 'twoD' ? 'Médias et définitions 2D' : 'Profils visuels et modèles 3D'}</small></div></div><div className="sr-context-note"><ShieldCheck size={20} /><h3>Un changement de profil ne réutilise pas la sélection.</h3><p>Chaque projet retrouve son propre contexte. Un brouillon demande une décision avant le changement.</p></div><div className="sr-approval"><span className="sr-dot" />Candidate non approuvée<p>Quatre états dans deux profils. Les opérations de cette maquette sont simulées ; aucun projet Avelune n’est ouvert.</p></div></aside>
    </div>
    <footer className="sr-reference-footer"><span>RUI-019 · Ouverture et récupération de session</span><span>Référence interactive à examiner · aucune acceptation native</span></footer>

    </div>
    {model.dialog && <div className="sr-dialog-backdrop"><div ref={dialogRef} tabIndex={-1} className="sr-dialog" role="dialog" aria-modal="true" aria-labelledby="sr-dialog-title" aria-describedby="sr-dialog-description"><div className="sr-dialog-top"><span className={`sr-dialog-icon ${model.dialog === 'discard' || model.dialog === 'reload' || model.dialog === 'rollback' ? 'warning' : 'blue'}`}>{model.dialog === 'close' ? <LogOut size={23} /> : <ShieldCheck size={23} />}</span><button className="sr-icon-button" aria-label="Rester dans la session" data-initial-focus disabled={working} onClick={() => dispatch({
            type: 'cancel'
          })}><X size={19} /></button></div>
      <h2 id="sr-dialog-title">{model.dialog === 'close' ? working ? 'Enregistrement en cours…' : 'Fermer le projet ?' : model.dialog === 'discard' ? 'Abandonner ce brouillon ?' : model.dialog === 'reload' ? 'Recharger la version sur disque ?' : model.dialog === 'profile' ? 'Changer de projet ?' : 'Revenir à la dernière version complète ?'}</h2>
      <p id="sr-dialog-description">{model.dialog === 'close' ? 'Une modification n’est pas encore enregistrée. Elle concerne l’arrivée « Entrée du laboratoire » de Bourg Geon.' : model.dialog === 'discard' ? 'Les modifications non enregistrées de cette session seront abandonnées. La version déjà enregistrée du projet sera conservée.' : model.dialog === 'reload' ? 'La révision 43 remplacera le brouillon de cette session. Cette action abandonne vos modifications locales ; elle ne remplace aucun fichier sur disque.' : model.dialog === 'profile' ? `Le projet ${data.name} contient un brouillon. Le changement l’abandonnera et ouvrira un contexte ${model.pendingProfile === 'twoD' ? '2D' : '3D'} sans reprendre la sélection.` : 'L’écriture inachevée ne sera pas reprise. La dernière version complète et sa copie de sécurité resteront les repères de récupération.'}</p>
      {model.dialog === 'close' && <div className="sr-dialog-summary"><FileText size={18} /><div><strong>{model.title || 'Arrivée sans nom'}</strong><span>1 modification · {data.name}</span></div><span className="sr-badge warning">Brouillon</span></div>}
      {working && <div className="sr-operation-status" role="status"><RefreshCw className="sr-spin" size={18} /><span>Le projet reste ouvert jusqu’à la confirmation de l’enregistrement.</span></div>}
      {model.error && <div className="sr-error" role="alert"><CircleAlert size={18} /><span>{model.error}</span></div>}
      <div className="sr-dialog-actions">{model.dialog === 'close' ? <><button className="sr-btn primary" disabled={working} onClick={() => dispatch({
              type: 'saveClose'
            })}><Save size={15} />{working ? 'Enregistrement…' : model.error ? 'Réessayer et fermer' : 'Enregistrer et fermer'}</button><button className="sr-btn" disabled={working} onClick={() => dispatch({
              type: 'cancel'
            })}>Rester dans le projet</button><button className="sr-text-button danger" disabled={working} onClick={() => dispatch({
              type: 'discard'
            })}>Fermer sans enregistrer</button></> : <><button className="sr-btn" onClick={() => dispatch({
              type: 'cancel'
            })}>{model.dialog === 'profile' ? 'Rester sur ce projet' : 'Annuler'}</button><button className="sr-btn danger" onClick={() => dispatch({
              type: model.dialog === 'discard' ? 'confirmDiscard' : model.dialog === 'reload' ? 'confirmReload' : model.dialog === 'profile' ? 'confirmProfile' : 'confirmRollback'
            })}>{model.dialog === 'discard' ? 'Abandonner et fermer' : model.dialog === 'reload' ? 'Abandonner le brouillon et recharger' : model.dialog === 'profile' ? 'Abandonner et changer' : 'Confirmer le retour'}</button></>}</div>
      <div className="sr-dialog-footnote"><ShieldCheck size={13} />Les décisions de cette référence n’écrivent aucune donnée réelle.</div>
    </div></div>}
  </div>;
};
