(() => {
  'use strict';
  const C = window.ATLAS;
  const modes = C.modes;
  const screenMap = new Map(C.screens.map(s => [s.id, s]));
  const groups = {startup:'01 · Démarrage',title:'02 · Titre',newgame:'03 · Nouvelle partie',session:'04 · Session et fin',world:'05 · Exploration',dialogue:'06 · Dialogues',interaction:'07 · Interactions',pause:'08 · Pause',party:'09 · Équipe',pokemon:'10 · Fiche Pokémon',bag:'11 · Sac',dex:'12 · Pokédex',map:'13 · Carte',profile:'14 · Profil',quests:'15 · Journal',contacts:'16 · Contacts',options:'17 · Options',save:'18 · Sauvegarde',shop:'19 · Boutique',heal:'20 · Soin',pc:'21 · Stockage',gift:'22 · Don de Pokémon',trade:'23 · Échange',battle:'24 · Combat',postbattle:'25 · Après-combat',companion:'26 · Compagnon',host:'27 · Outil développeur'};
  const pokemon = [
    {id:'bulbasaur',name:'Bulbi',species:'Bulbizarre',level:16,hp:32,max:48,type:'Plante',typeClass:'grass',second:'Poison',status:'',held:'Baie Oran'},
    {id:'charmander',name:'Salamèche',species:'Salamèche',level:15,hp:41,max:41,type:'Feu',typeClass:'fire',status:'',held:'Aucun'},
    {id:'squirtle',name:'Carapuce',species:'Carapuce',level:14,hp:25,max:43,type:'Eau',typeClass:'water',status:'',held:'Aucun'},
    {id:'pikachu',name:'Pikachu',species:'Pikachu',level:13,hp:18,max:36,type:'Électrik',typeClass:'electric',status:'PAR',held:'Aucun'},
    {id:'eevee',name:'Évoli',species:'Évoli',level:12,hp:0,max:39,type:'Normal',typeClass:'',status:'K.O.',held:'Aucun'},
    {id:'pidgey',name:'Roucool',species:'Roucool',level:11,hp:35,max:35,type:'Normal',typeClass:'',status:'',held:'Aucun'}
  ];
  const moves = [{name:'Fouet Lianes',type:'Plante',pp:22,max:25},{name:'Charge',type:'Normal',pp:30,max:35},{name:'Vampigraine',type:'Plante',pp:10,max:10},{name:'Poudre Dodo',type:'Plante',pp:0,max:15}];
  const items = [{name:'Potion',count:8,desc:'Restaure 20 PV à un Pokémon.',icon:'flask-conical',price:300},{name:'Super Potion',count:3,desc:'Restaure 50 PV à un Pokémon.',icon:'flask-round',price:700},{name:'Antidote',count:4,desc:'Soigne l’empoisonnement d’un Pokémon.',icon:'pill',price:100},{name:'Rappel',count:1,desc:'Ranime un Pokémon K.O. avec la moitié de ses PV.',icon:'sparkles',price:1500},{name:'Huile',count:2,desc:'Restaure des PP à une capacité.',icon:'droplets',price:0},{name:'Baie Oran',count:5,desc:'Une baie à donner ou à utiliser pour récupérer des PV.',icon:'cherry',price:0}];
  const talents={bulbasaur:'Engrais',charmander:'Brasier',squirtle:'Torrent',pikachu:'Statik',eevee:'Fuite',pidgey:'Regard Vif'};
  const speciesMoves={charmander:[['Flammèche','Feu',20,25],['Griffe','Normal',30,35],['Rugissement','Normal',40,40],['Brouillard','Normal',20,20]],squirtle:[['Pistolet à O','Eau',20,25],['Charge','Normal',30,35],['Mimi-Queue','Normal',30,30],['Repli','Eau',40,40]],pikachu:[['Éclair','Électrik',25,30],['Vive-Attaque','Normal',25,30],['Rugissement','Normal',40,40],['Cage Éclair','Électrik',15,20]],eevee:[['Charge','Normal',30,35],['Mimi-Queue','Normal',30,30],['Jet de Sable','Sol',15,15],['Vive-Attaque','Normal',25,30]],pidgey:[['Tornade','Vol',25,35],['Charge','Normal',30,35],['Jet de Sable','Sol',15,15],['Vive-Attaque','Normal',25,30]]};
  const movesFor=p=>speciesMoves[p.id]?.map(([name,type,pp,max])=>({name,type,pp,max}))||moves;
  const statsFor=p=>[p.max,...({bulbasaur:[28,30,36,34,26],charmander:[27,23,30,25,31],squirtle:[24,31,26,30,22],pikachu:[25,20,24,24,36],eevee:[24,23,21,28,25],pidgey:[22,21,18,18,28]}[p.id])];
  items.forEach(x=>x.pocket='Soins');
  items.push({name:'Poké Ball',count:12,desc:'Permet de capturer un Pokémon sauvage en combat.',icon:'circle-dot',pocket:'Balls',target:'battle',price:200},{name:'Super Ball',count:3,desc:'Une Ball plus efficace pour capturer un Pokémon sauvage.',icon:'circle-dot',pocket:'Balls',target:'battle',price:600},{name:'Bicyclette',count:1,desc:'Permet de se déplacer plus vite lorsque le terrain le permet.',icon:'bike',pocket:'Objets rares',target:'world',price:0},{name:'Pierre Plante',count:1,desc:'Fait évoluer certaines espèces compatibles.',icon:'gem',pocket:'Objets',target:'evolution',price:0},{name:'CT · Protection',count:1,desc:'Permet à un Pokémon compatible d’apprendre Protection.',icon:'disc',pocket:'Objets',target:'teach',price:0});
  const bagTargetReason=(item,p)=>{
    if(item.target==='battle')return 'Cet objet s’utilise uniquement pendant un combat.';
    if(item.target==='world')return 'Cet objet s’utilise directement sur le terrain.';
    if(item.target==='evolution')return p.id==='eevee'?'':'Cette espèce n’évolue pas avec une Pierre Plante.';
    if(item.target==='teach')return '';
    if(item.name==='Rappel')return p.hp===0?'':'Ce compagnon n’est pas K.O.';
    if(p.hp===0)return 'Cet objet ne ranime pas les compagnons K.O.';
    if(item.name==='Antidote')return p.status==='PSN'?'':'Ce compagnon n’est pas empoisonné.';
    if(item.name==='Huile')return movesFor(p).some(x=>x.pp<x.max)?'':'Toutes les capacités disposent de leurs PP.';
    return p.hp<p.max?'':'Les PV sont déjà au maximum.';
  };
  const optionCategories = [['general','Général','message-circle'],['display','Affichage','monitor'],['audio','Son','volume-2'],['controls','Commandes','gamepad-2'],['language','Langue','languages'],['accessibility','Accessibilité','accessibility']];
  const defaultHash = new URLSearchParams(location.hash.slice(1));
  let selected = screenMap.has(defaultHash.get('screen')) ? defaultHash.get('screen') : 'pause.root';
  let mode = modes[defaultHash.get('mode')] ? defaultHash.get('mode') : 'portrait-touch';
  let variant = defaultHash.get('state') || '';
  let view = defaultHash.get('view') || 'single';
  let zoom = 'fit';
  let query = '';
  const demo = {pokemon:0,item:0,move:0,bagResult:null,summaryTab:'summary',dexFilter:'all',dexQuery:'',bagPocket:'Soins',optionsCategory:'general',shopMode:'buy',quantity:3};
  let toastTimer;
  const esc = value => String(value ?? '').replace(/[&<>"']/g, s => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[s]));
  const icon = name => `<i class="icon" data-lucide="${esc(name)}" aria-hidden="true"></i>`;
  const sprite = (p = pokemon[0], cls = 'party-sprite', side = 'front') => `<img class="sprite ${cls}" src="assets/${p.id}-${side}.png" alt="${esc(p.species)}">`;
  const attr = target => target ? ` data-screen="${esc(target)}"` : '';
  const button = (label, target = '', cls = '', disabled = false, ico = '') => `<button class="game-button ${cls}"${attr(target)}${disabled ? ' disabled aria-disabled="true"' : ''}>${ico ? icon(ico) : ''}${esc(label)}</button>`;
  const row = (label, secondary = '', target = '', ico = '', selectedRow = false, disabled = false) => `<button class="game-row${selectedRow ? ' selected' : ''}"${attr(target)}${disabled ? ' disabled' : ''}>${ico ? icon(ico) : ''}<span class="row-text"><strong>${esc(label)}</strong>${secondary ? `<span class="secondary-line">${esc(secondary)}</span>` : ''}</span>${icon('chevron-right').replace('class="icon"','class="icon chevron"')}</button>`;
  const badge = (label, cls = '') => `<span class="badge ${cls}">${esc(label)}</span>`;
  const gauge = (p, extra = '') => `<div class="gauge ${extra}"><span style="width:${Math.round(p.hp / p.max * 100)}%;${p.hp / p.max < .5 ? 'background:var(--warn)' : ''}"></span></div>`;
  const notice = (text, type = '', ico = 'info') => `<div class="notice ${type}" role="status">${icon(ico)}<span>${esc(text)}</span></div>`;
  const hints = (m, action = 'Valider', back = 'Retour') => `<div class="input-hints"><span><b class="key">${m === 'thor-dual' ? 'B' : 'A'}</b>${esc(action)}</span>${back ? `<span><b class="key">${m === 'thor-dual' ? 'A' : 'B'}</b>${esc(back)}</span>` : ''}</div>`;
  const isPad = m => modes[m].input === 'gamepad';
  const isLandscape = m => modes[m].orientation === 'landscape';
  const footer = (m, actions, primary = 'Valider', backTarget = 'pause.root') => {
    if(!isPad(m))return `<footer class="screen-footer"><div class="footer-actions row" style="width:100%">${actions || button('Retour',backTarget,'',false,'arrow-left')}</div></footer>`;
    const match=(actions||'').match(/data-screen="([^"]+)"/);
    const label=(actions||'').replace(/<[^>]*>/g,'').trim()||primary;
    const first=match?`<button class="prompt-button" data-screen="${match[1]}"${/disabled/.test((actions||'').split('</button>')[0])?' disabled':''}><b class="key">${m==='thor-dual'?'B':'A'}</b>${esc(label)}</button>`:'';
    return `<footer class="screen-footer">${first}${backTarget?`<button class="prompt-button" data-screen="${backTarget}"><b class="key">${m==='thor-dual'?'A':'B'}</b>Retour</button>`:''}</footer>`;
  };
  const header = (title, subtitle = '', back = 'pause.root') => `<header class="screen-header">${back ? `<button class="icon-button"${attr(back)} aria-label="Retour">${icon('arrow-left')}</button>` : ''}<div><h2>${esc(title)}</h2>${subtitle ? `<div class="subtitle">${esc(subtitle)}</div>` : ''}</div></header>`;
  const shell = (s, m, body, actions = '', back = 'pause.root', title = s.label, subtitle = '') => `<div class="game-shell">${header(title, subtitle, back)}<div class="screen-body">${body}</div>${footer(m, actions, 'Valider', back)}</div>`;
  const modal = (m, title, text, actions, extra = '', status = '') => `<div class="world dimmer"></div><div class="modal-backdrop"><section class="modal-card" role="dialog" aria-label="${esc(title)}"><div class="modal-heading"><h3>${esc(title)}</h3>${status ? notice(status, 'error','circle-alert') : ''}</div><div class="modal-body"><p class="body-copy">${esc(text)}</p>${extra}</div><div class="modal-actions">${actions}</div>${isPad(m) ? `<div class="modal-hints">${hints(m)}</div>` : ''}</section></div>`;
  const empty = (title, text, ico = 'inbox') => `<div class="empty-state">${icon(ico)}<h3>${esc(title)}</h3><p>${esc(text)}</p></div>`;
  const tabs = (entries, active) => `<div class="tabs">${entries.map(([id,label]) => `<button${attr(id)} class="${id === active ? 'selected' : ''}">${esc(label)}</button>`).join('')}</div>`;
  const busyState = v => /pending|applying|submitting|saving|resuming|closing|mount|validating|busy/.test(v);
  const errorState = v => /failed|failure|error|hasFailure/.test(v);
  const emptyState = v => /^(empty|no-results|no-sellable-item|no-points|no-region|no-moves|no-compatible-bag-item)$/.test(v);
  const stateNames = {root:'Menu principal',normal:'État nominal',active:'Étape active',completed:'Étape terminée',enabled:'Disponible',selected:'Sélection',unknown:'Non découvert',seen:'Vu',caught:'Capturé',all:'Toutes les entrées',savePresent:'Sauvegarde présente',current:'Lieu actuel',discovered:'Lieu découvert',empty:'Aucun contenu',pending:'Action en cours',applying:'Application en cours',submitting:'Validation en cours',saving:'Enregistrement en cours',failed:'Échec',failure:'Échec',error:'Erreur',busy:'Occupé',playing:'Lecture',animating:'Animation',editing:'Saisie',typing:'Texte en cours',revealed:'Texte complet',confirm:'Confirmation',unavailable:'Indisponible',readonly:'Lecture seule',readOnly:'Lecture seule',selectedSlot:'Sauvegarde sélectionnée',noSave:'Aucune sauvegarde',unusableSave:'Sauvegarde inutilisable',sixMembers:'Six membres',faintedMember:'Membre K.O.',commandError:'Échec de commande',noResults:'Aucun résultat',emptyPocket:'Poche vide',emptyFavorites:'Favoris vides',disabledOption:'Option indisponible',longLabels:'Libellés longs',scrolling:'Contenu réparti en pages',missingImage:'Image absente',missingMedia:'Illustration absente',missingDescription:'Description absente',noPp:'Aucun PP',fullPpDisabled:'PP déjà au maximum',insufficientFunds:'Argent insuffisant',stockLimit:'Stock limité',inventoryLimit:'Inventaire plein',outOfStock:'Rupture de stock',lastUsableProtected:'Dernier membre protégé',controllerNoVirtualControls:'Manette active',leftHanded:'Commandes gaucher',inputLocked:'Commandes verrouillées',interactionAvailable:'Interaction disponible',textSpeed:'Vitesse du texte',menuEffects:'Effets des menus',touchRunMode:'Course tactile',worldServiceOnOwner:'Service sur écran principal',noBack:'Retour interdit',multipleValidTargets:'Plusieurs cibles',forcedReplacement:'Remplacement obligatoire',mediaFailed:'Média indisponible',posterFallback:'Image de repli',reducedMotion:'Mouvements réduits',missingReceipt:'Confirmation manquante',unexpectedFailure:'Erreur inattendue'};
  const stateLabel = value => {
    const key = value.replace(/-([a-z])/g, (_,c) => c.toUpperCase());
    return C.stateLabels?.[value] || stateNames[value] || stateNames[key] || value.replace(/([a-z])([A-Z])/g,'$1 $2').replaceAll('-',' ').replace(/^./,c=>c.toUpperCase());
  };
  const stateNotice = v => {
    if (errorState(v)) return notice('L’action n’a pas abouti. Les données confirmées sont conservées. Vous pouvez réessayer.', 'error', 'circle-alert');
    if (busyState(v)) return notice('En cours… Un instant, s’il vous plaît.','', 'loader-circle');
    if (/read-only/.test(v)) return notice('Consultation uniquement. Ces réglages ne peuvent pas être modifiés ici.');
    if (/disabled|unavailable|ineligible|no-effect|trapped|protected|locked|content-missing|capability-missing/.test(v)) return notice('Cette action n’est pas disponible dans la situation actuelle.','', 'lock-keyhole');
    return '';
  };
  const partyRow = (p, index, target, options = {}) => `<button class="game-row${index === demo.pokemon ? ' selected' : ''}" data-pokemon="${index}"${attr(target)}${options.disabled?.(p,index) ? ' disabled' : ''}>${sprite(p)}<span class="row-text"><span class="name-line"><strong>${esc(p.name)}</strong><span class="level">Niv. ${p.level}</span></span><span class="species-name">${esc(p.species)} ${p.status ? badge(p.status,p.status === 'K.O.' ? 'danger' : 'status') : ''}</span>${gauge(p)}<span class="health-numbers">${p.hp} / ${p.max} PV${index === 0 ? ' · En tête' : ''}</span></span></button>`;
  const partyList = (target = 'party.detail', options = {}) => `<div class="party-list">${pokemon.map((p,i) => partyRow(p,i,target,options)).join('')}</div>`;
  const overview = (p = pokemon[demo.pokemon], detailed = false, missing = false) => `<div class="pokemon-overview">${missing ? `<div class="dex-unknown">${icon('image-off')}</div>` : sprite(p,'hero-sprite')}<div class="detail-summary"><div class="meta">${esc(p.species)} · Niv. ${p.level}</div><h3>${esc(p.name)}</h3><div style="margin-top:8px">${badge(p.type,p.typeClass)} ${p.second ? badge(p.second,'poison') : ''} ${p.status ? badge(p.status,'status') : ''}</div><div class="health-summary"><div class="row between"><span>Points de vie</span><strong>${p.hp} / ${p.max}</strong></div>${gauge(p)}${gauge({hp:62,max:100},'exp')}</div>${detailed ? `<div class="info-line"><span>Talent</span><strong>${talents[p.id]}</strong></div><div class="info-line"><span>Objet tenu</span><strong>${esc(p.held)}</strong></div>` : ''}</div></div>`;
  const moveRows = (target = 'battle.target', disabledEmpty = false,p=pokemon[demo.pokemon]) => `<div class="stack">${movesFor(p).map((x,i) => `<button class="game-row${i === 0 ? ' selected' : ''}"${attr(target)}${disabledEmpty && !x.pp ? ' disabled' : ''}><span class="row-text"><strong>${esc(x.name)}</strong><span class="secondary-line">${esc(x.type)}</span></span><span class="meta">PP ${x.pp} / ${x.max}</span></button>`).join('')}</div>`;
  const statRows = (p=pokemon[demo.pokemon]) => ['PV','Attaque','Défense','Attaque Spé.','Défense Spé.','Vitesse'].map((n,i)=>{const val=statsFor(p)[i];return `<div class="stat-row"><span>${n}</span><strong>${val}</strong><div class="stat-bar"><span style="width:${val}%"></span></div></div>`;}).join('');
  function renderWorld(s,m,v) {
    const pad = isPad(m);
    const locked = v === 'input-locked' || s.id === 'session.lifecycle-paused';
    const touch = locked ? '' : `<div class="touch-dock"${v === 'left-handed' ? ' style="flex-direction:row-reverse"' : ''}><div class="joystick" aria-label="Joystick virtuel"><span></span></div><div class="touch-actions"><button class="touch-secondary" data-toast="Course : geste ou touche selon profil">${icon('footprints')}</button><button class="touch-primary" data-screen="dialogue.line">${icon('hand')}Parler</button></div></div>`;
    const n = s.id === 'world.notification' ? `<div class="world-notification">${icon(v === 'success' ? 'check' : 'info')} ${esc(v === 'error' ? 'Impossible d’effectuer cette action.' : v === 'warning' ? 'Votre équipe a besoin de repos.' : v === 'success' ? 'Une Potion a été ajoutée au Sac.' : 'Vous entrez dans la Clairière des Sources.')}</div>` : '';
    return `<div class="world"><div class="location">Clairière des Sources</div>${!locked ? `<button class="hud-menu icon-button" data-screen="pause.root" aria-label="Ouvrir le menu">${icon('menu')}</button>` : ''}${v === 'interaction-available' || v === 'idle' ? `<div class="context-action">${icon('message-circle')}Parler</div>` : ''}${n}${locked ? `<div class="modal-backdrop"><div class="modal-card"><h3>Partie en pause</h3><p class="body-copy">Vous pourrez reprendre une fois le jeu de nouveau actif.</p></div></div>` : pad ? `<div class="world-hints">${hints(m,'Parler','Menu')}</div>` : touch}</div>`;
  }
  function renderPause(s,m,v) {
    if(s.id === 'pause.unavailable') return modal(m,'Section indisponible','Cette fonction sera accessible lorsque votre aventure le permettra.',button('Retour','pause.root','primary'),'', 'Disponible après la prochaine étape de l’histoire.');
    const entries = [['Équipe','party.list','paw-print'],['Sac','bag.list','backpack'],['Pokédex','dex.list','scan-search'],['Carte','map.view','map'],['Journal','quests.list','book-open'],['Contacts','contacts.list','phone'],['Profil','profile.card','contact-round'],['Options','options.categories','settings-2']];
    const menu = entries.filter((_,i) => v !== 'entry-hidden' || i !== 4).map(([label,target,ico],i)=>row(label,'',target,ico,i===0,v==='entry-disabled-with-reason'&&i===4)).join('');
    return `<div class="world dimmer"></div><section class="pause-panel">${header('Pause','Clairière des Sources','world.explore')}<div class="screen-body"><div class="pause-grid">${menu}</div>${v==='entry-disabled-with-reason'?'<p class="scroll-note">Journal · Aucun objectif disponible pour le moment.</p>':''}</div><footer class="screen-footer"><div class="row" style="width:100%">${button('Reprendre','world.explore','primary',false,'play')}${button('Sauvegarder','save.confirm','',false,'save')}<button class="icon-button" data-screen="save.exit" aria-label="Revenir au titre">${icon('log-out')}</button></div>${isPad(m)?hints(m,'Ouvrir','Reprendre'):''}</footer></section>`;
  }
  function renderTitle(s,m,v) {
    const actions = `<div class="stack">${v!=='no-save'?button('Continuer',v==='unusable-save'?'save.recovery':'session.loading','primary',false,'play'):''}${button('Nouvelle partie',v==='no-save'?'newgame.name':'newgame.overwrite',v==='no-save'?'primary':'',false,'sparkles')}${v!=='no-save'&&v!=='configured-actions-hidden'?button('Charger la partie','session.loading','',false,'folder-open'):''}${v!=='configured-actions-hidden'?button('Options','options.categories','',false,'settings-2'):''}<div class="row">${button('Crédits','session.credits','',false,'scroll-text')}${button('Quitter','session.closing','',v==='action-disabled-with-reason','log-out')}</div></div>`;
    return `<div class="title-scene"></div><div class="title-content"><div><div class="game-subtitle">Une aventure à votre rythme</div><h2 class="game-title">Les Clairières</h2><div class="title-save">${v==='no-save'?'<strong>Votre aventure vous attend</strong><p class="meta">Aucune partie enregistrée</p>':'<strong>Yoahn · Clairière des Sources</strong><div class="meta" style="margin-top:5px">Équipe : 6 compagnons · 02 h 34</div>'}</div></div>${actions}${isPad(m)?hints(m,'Choisir',''):''}</div>`;
  }
  function renderLoading(s,m,v) {
    const labels = {manifestAndIdentity:'Ouverture de votre aventure',playerPreferences:'Préparation de vos réglages',saveDiscovery:'Recherche de la partie',initialMap:'Préparation du monde',presentationProfile:'Préparation de la présentation',splashBranding:'Préparation de l’accueil',introAndPoster:'Préparation de l’introduction',titleMenuAndMusic:'Tout est presque prêt',project:'Ouverture du jeu',save:'Lecture de votre partie',world:'Préparation du monde',mount:'Installation de la scène',resources:'Chargement des ressources',map:'Préparation du lieu',player:'Préparation du personnage',ready:'Prêt à jouer',disposingSession:'Fermeture de votre partie',externalExit:'Retour à votre bibliothèque'};
    if(s.id==='startup.splash') return `<div class="loading-scene"><div class="loading-content"><img class="eclipse-mark" src="assets/eclipse.png" alt="Éclipse Avelune"><h2 style="letter-spacing:5px;font-weight:400">AVELUNE</h2><p>Des mondes à explorer.</p></div></div>`;
    if(s.id==='startup.title-prompt') return `<div class="title-scene"></div><div class="title-content"><div><div class="game-subtitle">Avelune présente</div><h2 class="game-title">Les Clairières</h2></div>${button(isPad(m)?'Appuyez pour commencer':'Touchez pour commencer','title.menu','primary')}</div>`;
    if(s.id==='startup.intro'||s.id==='world.cinematic') return `<div class="world dimmer"></div>${v!=='unskippable'?`<button class="cutscene-skip game-button" data-screen="startup.title-prompt">${/poster|media-failed|reduced-motion/.test(v)?'Continuer':'Passer'} ${isPad(m)?'· Menu':''}</button>`:''}${/failed/.test(v)?notice('L’introduction est indisponible. Vous pouvez continuer votre aventure.','error'):''}<div class="cutscene-caption">${v==='captions'?'Au-delà de la forêt, une nouvelle aventure commence…':v==='reduced-motion'?'Une nouvelle aventure commence.':'Les Clairières'}${v==='poster'?button('Rejouer','startup.intro'):''}</div>`;
    const title = s.id==='save.progress'?'Sauvegarde en cours':s.id==='session.lifecycle-paused'?'Partie en pause':s.id==='session.completing'?'Fin de l’aventure':s.id==='session.closing'?'À bientôt':s.id==='heal.applying'?'Votre équipe se repose':s.label;
    return `<div class="loading-scene"><div class="loading-content"><img class="eclipse-mark" src="assets/eclipse.png" alt=""><h2>${esc(title)}</h2><p>${esc(s.id==='save.progress'?'Enregistrement de votre progression…':s.id==='heal.applying'?'Nous prenons soin de vos compagnons.':labels[v]||'Un instant, votre aventure se prépare…')}</p>${s.id==='save.progress'||s.id==='session.lifecycle-paused'?'<div class="spinner-static"></div>':`<div class="loading-track"><span></span></div>`}${errorState(v)?notice('La validation a échoué. Réessayez avant de quitter.','error'):''}${s.id==='session.lifecycle-paused'?button('Reprendre','world.explore','primary'):''}<p class="meta">${s.id==='save.progress'?'Gardez le jeu ouvert jusqu’à confirmation.':''}</p></div></div>`;
  }
  function renderParty(s,m,v) {
    const missing=/missing-(illustration|media)/.test(v);
    if(s.id==='party.action-menu') return modal(m,'Bulbi','Que souhaitez-vous faire ?',button('Voir la fiche','pokemon.summary','primary')+button('Objet tenu','party.held-item')+button('Déplacer','party.reorder')+button('Retour','party.list'),sprite(pokemon[0],'hero-sprite'));
    if(s.id==='party.held-item') {
      const has=v!=='no-held-item';
      return shell(s,m,`${stateNotice(v)}${overview()}<div class="section-title">Objet tenu</div>${has?notice('Bulbi tient une Baie Oran.'):notice('Bulbi ne tient aucun objet.')}<div class="stack">${button(has?'Remplacer l’objet':'Donner un objet','bag.list','primary',v==='no-compatible-bag-item')}${has?button('Retirer l’objet','party.detail'):''}</div>`,button('Fermer','party.detail'),'party.detail','Objet tenu');
    }
    if(s.id==='party.reorder') return shell(s,m,`${stateNotice(v)}${notice('Bulbi est sélectionné. Choisissez sa nouvelle position.')}<div class="party-list">${pokemon.map((p,i)=>partyRow(p,i,'party.list')).join('')}</div>`,button('Annuler','party.list'),'party.list','Déplacer Bulbi');
    if(s.id==='party.list'||s.id.startsWith('trade.select')||s.id==='trade.choose-partner'||s.id==='bag.target-party'||s.id==='battle.medicine-target') {
      if(emptyState(v)||v==='empty-party') return shell(s,m,empty('Votre équipe est vide','Les compagnons reçus au fil de l’aventure apparaîtront ici.','paw-print'),button('Retour','pause.root'));
      const target = s.id==='party.list'?'party.detail':s.id==='bag.target-party'?'bag.confirm':s.id==='trade.select-first'?'trade.choose-partner':s.id==='trade.choose-partner'?'trade.select-partner':s.id==='trade.select-partner'?'trade.review':'battle.turn';
      const content=partyList(target,{disabled:(_,i)=>(/ineligible|fainted/.test(v)&&i===4)||v==='disabled-candidate'&&i===0});
      const intro=s.id==='party.list'?'':notice(s.id==='bag.target-party'?'Potion · Choisissez un compagnon à soigner.':s.label);
      return shell(s,m,`${stateNotice(v)}${intro}<div class="split-layout"><div>${content}</div><div class="detail-panel landscape-only">${overview(pokemon[0],true)}${s.id==='party.list'?button('Voir la fiche','pokemon.summary','primary'):notice('Sélectionnez une cible pour continuer.')}</div></div>`,button('Retour',s.id.startsWith('bag.')?'bag.detail':s.id.startsWith('trade.')?'party.list':'pause.root'),s.id.startsWith('bag.')?'bag.detail':'pause.root',s.id==='party.list'?'Équipe':s.label,'6 compagnons');
    }
    if(s.id==='pokemon.summary'||s.id==='pc.summary') {
      const p=pokemon[demo.pokemon];
      const tabButtons=`<div class="tabs">${[['summary','Résumé'],['moves','Capacités'],['stats','Statistiques']].map(([id,label])=>`<button data-summary-tab="${id}" class="${demo.summaryTab===id?'selected':''}">${label}</button>`).join('')}</div>`;
      const origins=`<div class="info-line"><span>Nature</span><strong>Modeste</strong></div><div class="info-line"><span>Sexe</span><strong>Mâle</strong></div><div class="info-line"><span>Forme / chromatique</span><strong>Standard · Non</strong></div><div class="info-line"><span>Expérience</span><strong>4 120 · Prochain niveau 4 913</strong></div><div class="info-line"><span>Amitié</span><strong>70 / 255</strong></div><div class="info-line"><span>Rencontré à</span><strong>Clairière des Sources</strong></div><div class="info-line"><span>Obtention</span><strong>Reçu · Niveau 5 · Poké Ball</strong></div>`;
      const detail=demo.summaryTab==='moves'?`${moveRows('pokemon.summary')}<div class="move-detail"><h3>${movesFor(p)[0].name}</h3><p class="body-copy">${p.id==='bulbasaur'?'La cible est frappée par de fines lianes.':'Capacité de type '+movesFor(p)[0].type+'.'}</p><div class="data-grid"><div><span class="meta">Puissance</span><div class="value">${({bulbasaur:45,charmander:40,squirtle:40,pikachu:40,eevee:40,pidgey:40})[p.id]}</div></div><div><span class="meta">Précision</span><div class="value">100 %</div></div><div><span class="meta">PP</span><div class="value">${movesFor(p)[0].pp} / ${movesFor(p)[0].max}</div></div></div></div>`:demo.summaryTab==='stats'?statRows():origins;
      return shell(s,m,`${tabButtons}<div class="split-layout"><div>${overview(p,true,missing)}</div><div class="detail-panel">${detail}</div></div>`,button('Retour',s.id==='pc.summary'?'pc.box':'party.detail'),s.id==='pc.summary'?'pc.box':'party.detail','Fiche de '+p.name,'Résumé · Capacités · Statistiques');
    }
    const p=v==='fainted'?pokemon[4]:v==='status'?pokemon[3]:pokemon[demo.pokemon];
    return shell(s,m,`${stateNotice(v)}${overview(p,true,missing)}<div class="stack" style="margin-top:16px">${button('Voir la fiche complète','pokemon.summary','primary',false,'scan-search')}${button('Objet tenu · '+p.held,'party.held-item','',false,'cherry')}${button('Déplacer dans l’équipe','party.reorder','',false,'arrow-up-down')}</div><div class="section-title">Capacités</div>${moveRows('pokemon.summary')}`,button('Retour à l’équipe','party.list'),'party.list',p.name,p.species+' · Niv. '+p.level);
  }
  function renderBag(s,m,v) {
    if(s.id==='bag.target-party') {
      const item=items[demo.item];
      const target=item.target==='teach'?'bag.teach-replace':item.name==='Huile'?'bag.target-move':'bag.confirm';
      const list=pokemon.map((p,i)=>{const reason=bagTargetReason(item,p);const choice=partyRow(p,i,target,{disabled:()=>Boolean(reason)});return `${item.target==='teach'?choice.replace('data-screen="bag.teach-replace"','data-screen="bag.teach-replace" data-state="replacement-required"'):choice}${reason?`<p class="meta">${esc(p.name)} · ${esc(reason)}</p>`:''}`;}).join('');
      return shell(s,m,`${stateNotice(v)}${notice(item.name+' · Choisissez un compagnon.')}${v==='empty-party'?empty('Votre équipe est vide','Aucune cible ne peut recevoir cet objet.','paw-print'):`<div class="party-list">${list}</div>`}`,button('Retour','bag.detail'),'bag.detail',item.target==='evolution'?'Choisir une évolution':item.target==='teach'?'Apprendre Protection':'Choisir une cible');
    }
    if(s.id==='bag.target-move'||s.id==='bag.teach-replace'||s.id==='battle.medicine-move') {
      const learn=s.id==='bag.teach-replace';
      const p=pokemon[demo.pokemon];
      if(learn&&v==='free-move-slot')return modal(m,'Apprendre Protection ?',p.name+' dispose d’un emplacement libre. Aucune capacité ne sera oubliée.',`<button class="game-button primary" data-screen="postbattle.moveLearned" data-bag-result="teach">Apprendre</button>`+button('Retour','bag.detail'));
      if(learn&&v==='incompatible-target')return shell(s,m,empty('Capacité incompatible','Ce compagnon ne peut pas apprendre cette capacité.','shield-alert'),button('Retour','bag.detail'),'bag.detail','Apprendre une capacité');
      const target=learn?'move-replacement':'party-move';
      const choices=movesFor(p).map((x,i)=>`<button class="game-row${i===demo.move?' selected':''}" data-move="${i}" data-screen="${s.id==='battle.medicine-move'?'battle.turn':'bag.confirm'}" data-state="${target}"${!learn&&x.pp===x.max?' disabled':''}><span class="row-text"><strong>${esc(x.name)}</strong><span class="secondary-line">${x.type}${!learn&&x.pp===x.max?' · PP au maximum':''}</span></span><span class="meta">PP ${x.pp} / ${x.max}</span></button>`).join('');
      return shell(s,m,`${stateNotice(v)}${notice(learn?p.name+' souhaite apprendre Protection. Quelle capacité remplacer ?':'Huile · Choisissez une capacité de '+p.name+'.')}${v==='no-moves'?empty('Aucune capacité','Aucune cible ne peut recevoir cet objet.'):choices}`,button('Retour',s.id==='battle.medicine-move'?'battle.bag':'bag.detail'),s.id==='battle.medicine-move'?'battle.bag':'bag.detail',learn?'Apprendre Protection':'Récupérer des PP');
    }
    if(s.id==='bag.world-confirm')return modal(m,'Utiliser la Bicyclette ?','Vous monterez sur votre Bicyclette si le terrain le permet.',button('Monter','world.explore','primary')+button('Retour','bag.detail'),notice('Objet rare · conservé après utilisation'));
    if(s.id==='bag.confirm') {
      const pp=v==='party-move',learn=v==='move-replacement';
      const p=pokemon[demo.pokemon],item=learn?items.find(x=>x.target==='teach'):pp?items.find(x=>x.name==='Huile'):items[demo.item];
      const move=movesFor(p)[demo.move]||movesFor(p)[0],restored=Math.min(10,move.max-move.pp);
      const evolution=item.target==='evolution',reason=bagTargetReason(item,p);
      const healed=item.name==='Rappel'?Math.max(1,Math.floor(p.max/2)):Math.min(p.max,p.hp+({Potion:20,'Super Potion':50,'Baie Oran':10}[item.name]||0));
      const text=learn?p.name+' oubliera '+move.name+' et apprendra Protection.':pp?item.name+' restaurera '+restored+' PP à '+move.name+' de '+p.name+'.':evolution?p.name+' évoluera en Phyllali. La Pierre Plante sera consommée.':item.name==='Antidote'?p.name+' sera libéré de l’empoisonnement. Un Antidote sera retiré du Sac.':p.name+(item.name==='Rappel'?' sera ranimé avec '+healed+' PV.':' récupérera '+(healed-p.hp)+' PV.')+' Un exemplaire de '+item.name+' sera retiré du Sac.';
      const value=learn?move.name+' → Protection':pp?move.pp+' → '+(move.pp+restored)+' / '+move.max+' PP':evolution?p.species+' → Phyllali':item.name==='Antidote'?'Empoisonnement → Aucun statut':p.hp+' → '+healed+' / '+p.max+' PV';
      const result=learn?'teach':evolution?'evolution':'';
      const action=`<button class="game-button primary" data-screen="${learn?'postbattle.moveReplaced':evolution?'postbattle.evolutionAccepted':'bag.detail'}"${result?` data-bag-result="${result}"`:''}${busyState(v)||reason||pp&&restored===0?' disabled':''}>${busyState(v)?'En cours…':'Confirmer'}</button>`;
      return modal(m,learn?'Remplacer '+move.name+' ?':'Utiliser '+item.name+' ?',reason||text,action+button('Retour',pp?'bag.target-move':learn?'bag.teach-replace':'bag.target-party'),`<div class="row" style="justify-content:center">${sprite(p)}<strong>${esc(reason?'Cible incompatible':value)}</strong></div>`,errorState(v)?'Impossible d’utiliser cet objet.':'');
    }
    const chosen=items[demo.item];
    if(s.id==='bag.detail') return shell(s,m,`${stateNotice(v)}<div class="detail-hero"><div class="item-hero">${icon(chosen.icon)}</div></div><h3 class="big-copy">${chosen.name} <span class="meta">×${chosen.count}</span></h3><p class="body-copy">${chosen.desc}</p><div class="info-line"><span>Poche</span><strong>${chosen.pocket}</strong></div><div class="info-line"><span>Utilisation</span><strong>${chosen.target==='world'||v==='world-only'?'Terrain':chosen.target==='battle'||v==='battle-only'?'Combat uniquement':chosen.target==='teach'||chosen.target==='evolution'?'Équipe':'Équipe · Combat'}</strong></div><div class="stack" style="margin-top:20px">${button('Utiliser',chosen.target==='world'||v==='world-only'?'bag.world-confirm':'bag.target-party','primary',/unusable|no-effect|battle-only/.test(v)||chosen.target==='battle', 'hand')}${button('Ajouter aux favoris','bag.detail','',false,'star')}</div>${v==='result-message'?notice('L’objet a été utilisé.','success','check'):''}`,button('Retour au Sac','bag.list'),'bag.list',chosen.name,chosen.pocket+' · '+chosen.count+' dans le Sac');
    const pocket=demo.bagPocket;
    const list=items.filter((x,i)=>pocket==='Favoris'?i===0:x.pocket===pocket).map(x=>{const i=items.indexOf(x);return `<button class="game-row${i===demo.item?' selected':''}" data-item="${i}" data-screen="bag.detail"><span class="item-symbol">${icon(x.icon)}</span><span class="row-text"><strong>${x.name}</strong><span class="secondary-line">${x.desc}</span></span><span>×${x.count}</span></button>`;}).join('');
    return shell(s,m,`${tabs([['bag.list#heal','Soins'],['bag.list#balls','Balls'],['bag.list#items','Objets'],['bag.list#key','Objets rares'],['bag.list#fav','Favoris']],{'Soins':'bag.list#heal','Balls':'bag.list#balls','Objets':'bag.list#items','Objets rares':'bag.list#key','Favoris':'bag.list#fav'}[pocket])}<div class="split-layout"><div>${/empty/.test(v)?empty(v==='empty-favorites'?'Aucun favori':'Cette poche est vide','Les objets trouvés pendant votre aventure seront rangés ici.','backpack'):list}</div><div class="detail-panel landscape-only"><div class="item-hero">${icon(chosen.icon)}</div><h3>${chosen.name}</h3><p class="body-copy">${chosen.desc}</p>${button('Consulter','bag.detail','primary')}</div></div>`,button('Retour','pause.root'),'pause.root','Sac','3 250 ₽');
  }
  function dexSpecies(p,v) {
    const numbers={bulbasaur:1,charmander:4,squirtle:7,pikachu:25,eevee:133,pidgey:16};
    return `<div class="pokemon-overview">${v==='missing-image'?'<div class="dex-unknown">?</div>':sprite(p,'hero-sprite')}<div class="detail-summary"><div class="meta">N° ${String(numbers[p.id]).padStart(3,'0')}</div><h3>${esc(p.species)}</h3><div style="margin-top:10px">${badge(p.type,p.typeClass)} ${p.second?badge(p.second,'poison'):''}</div><div class="info-line"><span>Observation</span><strong>${v==='seen'?'Vu':'Capturé'}</strong></div></div></div>`;
  }
  function renderDex(s,m,v) {
    if(s.id==='dex.detail') {
      if(v==='unknown') return shell(s,m,`${empty('Entrée inconnue','Explorez la région pour découvrir ce Pokémon.','scan-search')}<div class="info-line"><span>Numéro</span><strong>001</strong></div><div class="info-line"><span>Nom</span><strong>???</strong></div>`,button('Retour au Pokédex','dex.list'),'dex.list','Entrée inconnue');
      const p=pokemon[demo.pokemon];
      return shell(s,m,`${dexSpecies(p,v)}<div class="section-title">Description</div><p class="body-copy">${v==='missing-description'?'Aucune description disponible.':p.id==='bulbasaur'?'Il porte une graine sur son dos depuis sa naissance. Elle grandit avec lui.':'Les observations de cette espèce sont consignées dans votre Pokédex.'}</p>`,button('Retour au Pokédex','dex.list'),'dex.list',p.species,'Entrée du Pokédex · Données de l’espèce');
    }
    const filter=v==='seen'||v==='caught'?v:demo.dexFilter;
    const numbers=[1,4,7,25,133,16];
    const searchTerm=v==='query'?'Bulbizarre':'';
    const list=pokemon.filter((p,i)=>(filter!=='caught'||i<4)&&(!searchTerm||p.species.toLowerCase().includes(searchTerm.toLowerCase())||String(numbers[i]).padStart(3,'0').includes(searchTerm))).map(p=>{const i=pokemon.indexOf(p);return `<button class="game-row${i===demo.pokemon?' selected':''}" data-pokemon="${i}" data-dex-row="${String(numbers[i]).padStart(3,'0')} ${p.species}" data-screen="dex.detail" data-state="${i<4?'caught':'seen'}"><span class="dex-num">${String(numbers[i]).padStart(3,'0')}</span>${sprite(p)}<span class="row-text"><strong>${p.species}</strong><span class="secondary-line">${i<4?'Capturé':'Vu'}</span></span>${icon(i<4?'check-circle-2':'eye')}</button>`;}).join('')+(filter==='all'&&!searchTerm?`<button class="game-row" data-dex-row="152 inconnu" data-screen="dex.detail" data-state="unknown"><span class="dex-num">152</span><span class="dex-unknown">?</span><span class="row-text">???</span></button>`:'');
    return shell(s,m,`${tabs([['dex.list#all','Tous'],['dex.list#seen','Vus'],['dex.list#caught','Capturés']],'dex.list#'+filter)}<label class="row" style="margin-bottom:12px">${icon('search')}<input class="input-field" data-dex-search style="font-size:16px;min-height:48px" placeholder="Nom ou numéro" aria-label="Rechercher dans le Pokédex" value="${esc(v==='query'?'Bulbizarre':demo.dexQuery)}"></label><div class="split-layout"><div class="dex-list">${emptyState(v)?empty('Aucune entrée','Essayez un autre nom ou un autre filtre.','search'):list}</div><div class="detail-panel landscape-only">${dexSpecies(pokemon[demo.pokemon],'caught')}${button('Consulter','dex.detail','primary')}</div></div>`,button('Retour','pause.root'),'pause.root','Pokédex','Vus 24 · Capturés 12');
  }
  function renderMap(s,m,v) {
    if(s.id==='map.regions'||s.id==='map.overlap') return shell(s,m,`<div class="stack">${(s.id==='map.regions'?['Les Clairières','Les Hautes Terres']:['Clairière des Sources','Maison du garde']).map((n,i)=>row(n,i===0?'Lieu actuel':'Découvert','map.view','map-pin',i===0)).join('')}</div>`,button('Retour','map.view'),'map.view',s.id==='map.regions'?'Régions':'Choisir un lieu');
    if(s.id==='map.location') return modal(m,v==='unknown'?'Lieu inconnu':'Clairière des Sources',v==='unknown'?'Vous n’avez pas encore découvert cet endroit.':'Un village paisible à l’orée de la forêt. Vous vous trouvez ici.',button('Retour à la carte','map.view','primary'),`<div class="map-area" style="height:150px;aspect-ratio:auto"><span class="map-label">Les Clairières</span></div>`);
    if(s.id==='map.travel-service') return shell(s,m,`${stateNotice(v)}${notice('Choisissez une destination accessible avec votre capacité de voyage.')}<div class="map-area"><button class="map-marker" data-screen="map.travel-service" data-state="applying" aria-label="Voyager vers Clairière des Sources">${icon('map-pin')}</button><span class="map-label">Clairière des Sources · Découvert</span></div><div class="stack" style="margin-top:12px">${button(busyState(v)?'Voyage en cours…':'Voyager vers ce lieu','world.explore','primary',busyState(v)||v==='unavailable')}</div>`,button('Annuler','world.explore'),'world.explore','Choisir une destination');
    if(v==='no-region'||v==='no-points') return shell(s,m,empty('Carte indisponible','Aucun lieu n’est disponible dans cette région pour le moment.','map'),button('Retour','pause.root'));
    return shell(s,m,`${tabs([['map.regions','Les Clairières'],['map.regions','Changer de région']],'map.regions')}<div class="split-layout map-split"><div class="map-area"${v==='missing-background'?' style="background-image:none"':''}><button class="map-marker" data-screen="map.location"${v==='unknown'?' data-state="unknown"':''} aria-label="Informations sur le lieu">${icon('map-pin')}</button><span class="map-label">${v==='unknown'?'Lieu inconnu':'Clairière des Sources'}</span></div><div class="detail-panel"><h3 style="margin-top:0">${v==='unknown'?'Lieu inconnu':'Clairière des Sources'}</h3><p class="body-copy">${v==='unknown'?'Explorez le monde pour découvrir cet endroit.':'Vous vous trouvez ici. Un village calme au bord de la forêt.'}</p>${button('Informations','map.location','primary')}<div class="row" style="margin-top:12px">${button('−','','',false,'zoom-out')}${button('+','','',false,'zoom-in')}</div></div></div>`,button('Retour','pause.root'),'pause.root','Carte régionale');
  }
  function renderProfile(s,m,v) {
    return shell(s,m,`<div class="split-layout"><div class="profile-card"><div class="meta">CARTE DE DRESSEUR</div><div class="row between"><div><h3 class="profile-name">Yoahn</h3><div class="meta">Aventure commencée aux Clairières</div></div><img src="assets/leo.png" alt="Portrait du joueur" style="width:80px;height:80px;border-radius:50%;object-fit:cover"${v==='portrait-missing'?' hidden':''}></div><div class="data-grid" style="margin-top:18px"><div><div class="label">Temps de jeu</div><div class="value">${v==='missing-playtime'?'—':'02 h 34'}</div></div><div><div class="label">Argent</div><div class="value">3 250 ₽</div></div></div></div><div class="detail-panel"><div class="section-title">Progression</div><div class="info-line"><span>Pokédex · Vus</span><strong>${v==='pokedex-disabled'?'Indisponible':'24'}</strong></div><div class="info-line"><span>Capturés</span><strong>${v==='pokedex-disabled'?'—':'12'}</strong></div><div class="section-title">Badges</div><div class="badges-row">${Array.from({length:8},(_,i)=>`<span class="badge-slot${i>1||v==='no-badges'?' locked':''}">${icon(i===0?'leaf':'hexagon')}</span>`).join('')}</div><div class="info-line"><span>Lieu actuel</span><strong>Clairière des Sources</strong></div></div></div>`,button('Retour','pause.root'),'pause.root','Profil');
  }
  function renderContacts(s,m,v) {
    if(s.id==='contacts.call') return renderDialogue({id:'dialogue.line',label:'Appel de Léa'},m,v==='unavailable'?'advance-unavailable':'revealed','Léa · Appel','Salut ! Tu as découvert la clairière ? Rejoins-moi près du pont quand tu peux.');
    if(s.id==='quests.list') return shell(s,m,emptyState(v)||v==='unavailable'?empty('Aucune entrée','Votre journal se remplira au fil de votre aventure.','book-open'):`<div class="stack">${row('Un passage dans la forêt','En cours · Parler au garde','quests.list','circle-dot',true)}${row('Le premier compagnon','Terminé · Rencontrer le professeur','quests.list','circle-check')}${row('Au bord du ruisseau','En cours · Explorer les environs','quests.list','circle-dot')}</div><div class="section-title">Entrée sélectionnée</div><p class="body-copy">Le garde vous attend près du pont de la Clairière des Sources.</p>`,button('Retour','pause.root'),'pause.root','Journal');
    return shell(s,m,emptyState(v)||v==='unavailable'?empty('Aucun contact','Les personnes rencontrées pourront vous laisser leurs coordonnées.','phone'):`<div class="phone-contacts">${[['Léa','Disponible','phone'],['Professeur Orme','Disponible','graduation-cap'],['Garde du pont','Indisponible pour le moment','shield']].map(([name,sub,ico],i)=>row(name,sub,'contacts.call',ico,i===0,v==='call-disabled'||i===2)).join('')}</div>${v==='call-disabled'?notice('Aucun appel n’est possible dans ce lieu.'):''}`,button('Retour','pause.root'),'pause.root','Contacts');
  }
  function keyboard(m) {
    const rows='AZERTYUIOPQSDFGHJKLMWXCVBNÉÈÀÙ0123456789'.split('').map((x,i)=>`<button data-key="${x}" class="${i===0&&isPad(m)?'active':''}">${x}</button>`).join('');
    return `<div class="${isPad(m)?'controller-keyboard':'os-keyboard'}"><div class="keyboard">${rows}<button class="wide" data-key=" ">Espace</button><button class="wide" data-key="backspace">Effacer</button></div><div class="os-keyboard-caption">${isPad(m)?'Croix / stick : déplacer · Valider : saisir · Retour : effacer':'Clavier logiciel · représentation de maquette'}</div></div>`;
  }
  function renderInteraction(s,m,v) {
    if(s.id==='newgame.overwrite') return modal(m,'Commencer une nouvelle partie ?', 'Une partie est déjà enregistrée. Elle sera remplacée lorsque la nouvelle partie sera sauvegardée.',button('Garder ma partie','title.menu','primary')+button('Commencer','newgame.name','danger'),'<p class="meta">Yoahn · Clairière des Sources · 02 h 34</p>');
    if(s.id==='newgame.avatar'||s.id==='newgame.starter') {
      const starter=s.id==='newgame.starter';
      const choices=starter?pokemon.slice(0,3).map((p,i)=>`<button class="avatar-tile${i===0?' selected':''}" data-screen="world.explore"${v==='option-disabled'&&i===2?' disabled':''}>${sprite(p,'hero-sprite')}<strong>${p.species}</strong>${badge(p.type,p.typeClass)}</button>`).join(''):`<button class="avatar-tile selected" data-screen="newgame.starter"><img src="assets/leo.png" alt="Personnage" style="width:90px;height:90px;border-radius:9px;object-fit:cover"><strong>Léo</strong></button><button class="avatar-tile" data-screen="newgame.starter">${icon('user-round')}<strong>Éline</strong></button>`;
      return shell(s,m,`${notice(starter?'Lequel souhaitez-vous choisir ?':'Choisissez le personnage de votre aventure.')}<div class="avatar-grid">${choices}</div>`,button('Confirmer',starter?'world.explore':'newgame.starter','primary'),'',starter?'Votre premier compagnon':'Votre personnage');
    }
    if(s.id==='newgame.name'||s.id==='interaction.text'||s.id==='gift.nickname') {
      const error=/invalid|too-|server-error/.test(v);
      const name=/empty|too-short/.test(v)?'':/too-long/.test(v)?'Un surnom vraiment trop long':s.id==='gift.nickname'?'Bulbi':'Yoahn';
      return shell(s,m,`${error?notice(v.includes('long')?'Ce nom est trop long. Choisissez un nom plus court.':v.includes('server')?'La saisie n’a pas été enregistrée. Réessayez.':'Ce nom est trop court. Saisissez au moins un caractère.','error','circle-alert'):''}<p class="body-copy">${s.id==='gift.nickname'?'Quel surnom souhaitez-vous lui donner ?':'Comment vous appelez-vous ?'}</p><input class="input-field" data-name-input value="${esc(name)}" aria-label="Nom" maxlength="12"><div class="row between" style="margin-top:8px"><span class="meta">1 à 12 caractères</span><span class="meta" data-name-count>${name.length} / 12</span></div>${keyboard(m)}`,button(busyState(v)?'Validation…':'Valider',s.id==='gift.nickname'?'gift.destination':s.id==='newgame.name'?'newgame.avatar':'interaction.message','primary',busyState(v)||error||!name.trim()),s.id==='gift.nickname'?'gift.nickname-confirm':'dialogue.line',s.id==='gift.nickname'?'Surnom':'Votre nom');
    }
    if(s.id==='interaction.integer') return modal(m,'Choisissez une quantité','Combien souhaitez-vous en prendre ?',button('Valider','interaction.message','primary',v==='out-of-range')+(v==='cancel-forbidden'?'':button('Annuler','world.explore')),`<div class="quantity"><button class="game-button" data-quantity="-1">−</button><strong data-quantity-value>${v==='out-of-range'?11:3}</strong><button class="game-button" data-quantity="1">+</button></div><p class="quantity-label">Entre 1 et 10</p>`,v==='out-of-range'?'La valeur doit être comprise entre 1 et 10.':v==='error'?'Cette quantité ne peut pas être confirmée.':'');
    if(s.id==='interaction.selection') return shell(s,m,`${notice(v==='maximum-reached'?'Vous avez sélectionné le maximum de deux choix.':'Choisissez entre un et deux compagnons.')}<div class="multi-choice-list">${pokemon.slice(0,4).map((p,i)=>`<button class="game-row${(i<2&&v==='maximum-reached')||(i===0&&v==='normal')?' selected':''}" data-toggle-check>${icon((i<2&&v==='maximum-reached')||(i===0&&v==='normal')?'square-check':'square')}${sprite(p)}<span class="row-text">${p.name}</span></button>`).join('')}</div>`,button('Valider','interaction.message','primary',v==='minimum-not-met'),'world.explore','Choisir des compagnons');
    if(s.id==='interaction.confirmation') return modal(m,'Accepter cette proposition ?','Le garde vous propose de vous accompagner jusqu’à la forêt.',button('Oui','dialogue.line','primary',busyState(v))+button('Non','world.explore'),'',v==='disabled'?'Cette proposition n’est pas disponible.':'');
    return renderDialogue(s,m,v,s.id==='interaction.choice'?'Garde du pont':'Information',s.id==='interaction.choice'?'Quelle direction souhaitez-vous prendre ?':'Vous trouvez une Potion. Elle a été ajoutée à votre Sac.');
  }
  function renderDialogue(s,m,v,speaker='Léa',text='Le sentier traverse la forêt. Prends le temps de préparer ton équipe avant de partir !') {
    const choice=s.id==='dialogue.choices'||s.id==='interaction.choice';
    const t=v==='typing'?text.slice(0,42)+'…':v==='long-labels'?'Le sentier le plus court traverse une forêt dense, mais vous pouvez aussi suivre la rivière pour rejoindre le village sans traverser les hautes herbes. Que préférez-vous ?':text;
    const next=v==='typing'?'dialogue.line':s.id==='interaction.message'||v==='last-line'?'world.explore':'dialogue.choices';
    const advance=`<button class="${isPad(m)?'prompt-button':'game-button primary'}" data-screen="${next}"${v==='typing'?' data-state="revealed"':''}${v==='advance-unavailable'||v==='pending'?' disabled':''}>${isPad(m)?`<b class="key">${m==='thor-dual'?'B':'A'}</b>`:''}${v==='typing'?'Afficher le texte':v==='last-line'?'Terminer':'Continuer'}</button>`;
    const choices=choice?`<div class="choices">${button(v==='long-labels'?'Traverser la forêt en passant par le vieux pont':'Traverser la forêt','world.explore','primary')}${button(v==='long-labels'?'Suivre la rivière jusqu’au village des Sources':'Suivre la rivière','world.explore','',v==='disabled-option')}${v==='scrolling'?button('Attendre près du pont','world.explore')+button('Demander un conseil','dialogue.line'):''}</div>`:advance;
    return `<div class="world dimmer"></div><section class="dialogue">${v==='with-portrait'?'<img src="assets/leo.png" alt="Léa" style="width:60px;height:60px;border-radius:50%;object-fit:cover;float:right;margin-left:12px">':''}<span class="speaker">${esc(speaker)}</span><p>${esc(t)}</p>${choices}</section>`;
  }
  function setting(label,value,kind='choice',target='options.choice') {
    if(kind==='slider') return `<div class="setting"><div class="row between"><span>${esc(label)}</span><strong class="value" data-range-value>${value} %</strong></div><input type="range" min="${label==='Taille du texte'?80:label==='Opacité tactile'?30:0}" max="${label==='Taille du texte'?160:100}" step="${label==='Taille du texte'?10:5}" value="${value}" aria-label="${esc(label)}"></div>`;
    if(kind==='toggle') return `<div class="setting"><div class="row between"><span>${esc(label)}</span><button class="toggle${value?'':' off'}" role="switch" aria-checked="${value}" data-toggle-setting aria-label="${esc(label)}"><span></span></button></div></div>`;
    return `<div class="setting"><span>${esc(label)}</span><button class="game-button"${attr(target)}><span>${esc(value)}</span>${icon('chevron-right')}</button></div>`;
  }
  function renderOptions(s,m,v) {
    if(s.id==='options.categories') return shell(s,m,optionCategories.map(([id,label,ico],i)=>row(label,'','options.'+id,ico,i===0)).join('')+row('Réaffecter les commandes','Clavier et manette','options.bindings','keyboard'),button('Retour','pause.root'),'pause.root','Options');
    if(s.id==='options.reset') return modal(m,'Rétablir ces réglages ?',`La catégorie « ${optionCategories.find(x=>x[0]===(v||demo.optionsCategory))?.[1]||'Général'} » retrouvera ses valeurs par défaut. Les autres catégories seront conservées.`,button('Annuler','options.'+demo.optionsCategory,'primary')+button('Rétablir','options.'+demo.optionsCategory));
    if(s.id==='options.choice') return modal(m,v==='language'?'Langue':v==='menu-effects'?'Effets des menus':v==='touch-run-mode'?'Course tactile':'Vitesse du texte','Choisissez la valeur souhaitée.',(v==='language'?['Français','English']:v==='menu-effects'?['Complet','Réduit','Sans transparence']:v==='touch-run-mode'?['Course au geste','Marche seule','Course automatique si permise']:['Lente','Normale','Rapide','Instantanée']).map((x,i)=>button(x,'options.'+demo.optionsCategory,i===1?'primary':'')).join(''));
    if(s.id==='options.bindings') return shell(s,m,`${stateNotice(v)}${notice(v==='keyboard'?'Clavier · Appuyez sur une touche pour réaffecter une action.':'Manette Xbox dans cet exemple · Les symboles suivent le périphérique et vos réglages.')}<div class="stack">${[['Valider','A'],['Retour','B'],['Menu','Start'],['Interagir','A'],['Courir','B']].map(([label,value],i)=>row(label,value,'options.bindings',i?'gamepad-2':'circle-dot',i===0)).join('')}</div>${v==='conflict-rejected'?notice('Cette touche est déjà utilisée par une autre action.','error'):''}`,button('Réinitialiser ce périphérique','options.reset'),'options.controls','Réaffecter les commandes');
    const key=s.id.split('.')[1];
    const content={general:setting('Vitesse du texte','Rapide'),display:setting('Effets des menus','Complet'),audio:setting('Volume général',80,'slider')+setting('Musique',65,'slider')+setting('Effets sonores',85,'slider'),controls:setting('Course tactile','Course au geste')+setting('Commandes gaucher',false,'toggle')+setting('Afficher les aides',true,'toggle')+setting('Opacité tactile',70,'slider')+button('Réaffecter les commandes','options.bindings'),language:setting('Langue de l’interface','Français'),accessibility:setting('Taille du texte',100,'slider')+setting('Mouvements réduits',false,'toggle')+setting('Contraste renforcé',false,'toggle')+setting('Vibrations',true,'toggle')}[key]||'';
    return shell(s,m,`${stateNotice(v)}<div class="split-layout"><div class="landscape-only">${optionCategories.map(([id,label,ico])=>row(label,'','options.'+id,ico,key===id)).join('')}</div><div>${content}<div style="margin-top:18px">${button('Rétablir la catégorie','options.reset')}</div></div></div>`,button('Catégories','options.categories'),'options.categories',optionCategories.find(x=>x[0]===key)?.[1]||'Options');
  }
  function renderSave(s,m,v) {
    if(s.id==='save.progress') return renderLoading(s,m,v);
    if(s.id==='save.success') return modal(m,'Partie sauvegardée','Votre progression a bien été enregistrée.',button('Reprendre','world.explore','primary'),notice('Yoahn · Clairière des Sources · 02 h 34','success','check'));
    if(s.id==='save.failure') return modal(m,'Sauvegarde impossible','La partie n’a pas été enregistrée. Votre progression reste disponible tant que le jeu est ouvert.',button('Réessayer','save.progress','primary')+button('Retour au jeu','world.explore'),'',v==='disk-error'?'Vérifiez l’espace disponible sur votre appareil.':v==='missing-receipt'?'La confirmation d’enregistrement est manquante.':'Une erreur inattendue est survenue.');
    if(s.id==='save.exit') {
      if(v==='saving')return renderLoading(screenMap.get('save.progress'),m,'exit-after-save');
      if(v==='exiting')return renderLoading(screenMap.get('session.closing'),m,'disposingSession');
      return modal(m,'Revenir au titre ?','Que souhaitez-vous faire avant de quitter votre partie ?',button('Sauvegarder et quitter','save.progress','primary',v==='save-and-exit-unavailable')+button('Quitter sans sauvegarder','title.menu','danger',v==='discard-unavailable')+button('Rester','pause.root'),'',v==='exit-failed'?'La sortie a échoué. Votre partie est toujours ouverte.':'');
    }
    if(s.id==='save.recovery') return modal(m,'Cette sauvegarde est inutilisable',v==='unsupportedSchema'?'Cette version du jeu ne peut pas lire le format de cette sauvegarde.':'La sauvegarde n’a pas pu être lue. Aucune partie n’a été chargée.',button('Réessayer','session.loading','primary')+button('Retour au titre','title.menu')+button('Supprimer la sauvegarde','save.delete-confirm','danger'));
    if(s.id==='save.delete-confirm') return modal(m,'Supprimer définitivement ?', 'Cette sauvegarde et toute sa progression seront perdues. Cette action est irréversible.',button('Conserver','title.menu','primary')+button('Supprimer définitivement','title.menu','danger'));
    return modal(m,'Sauvegarder la partie ?','Votre progression actuelle remplacera la sauvegarde précédente.',button('Sauvegarder','save.progress','primary',v==='save-unavailable')+button('Annuler','pause.root'),'<div class="card-inline"><strong>Yoahn</strong><div class="meta" style="margin-top:6px">Clairière des Sources · 02 h 34<br>6 compagnons · 2 badges</div></div>',v==='save-unavailable'?'La sauvegarde n’est pas disponible pendant cette action.':'');
  }
  function renderShop(s,m,v) {
    if(s.id==='shop.quantity') {
      const selling=demo.shopMode==='sell';const item=items[demo.item];const unit=selling?Math.floor(item.price/2):item.price;const q=demo.quantity;const balance=v==='insufficient-funds'?200:3250;const stock=v==='stock-limit'?2:selling?item.count:12;const capacity=v==='inventory-limit'?2:99;const invalid=(!selling&&q*unit>balance)||q>stock||q>capacity;
      const action=`<button class="game-button primary" data-purchase data-screen="shop.${selling?'sell':'buy'}"${busyState(v)||invalid?' disabled':''}>${busyState(v)?'Transaction…':(selling?'Vendre':'Acheter')+' · '+q*unit+' ₽'}</button>`;
      return modal(m,(selling?'Vendre · ':'Acheter · ')+item.name,item.desc,action+button('Annuler','shop.'+demo.shopMode),`<div data-transaction data-unit-price="${unit}" data-balance="${balance}" data-stock="${stock}" data-capacity="${capacity}" data-selling="${selling}"><div class="quantity"><button class="game-button" data-quantity="-1">−</button><strong data-quantity-value>${q}</strong><button class="game-button" data-quantity="1">+</button></div><p class="quantity-label">${selling?'Dans le Sac':'Stock'} : ${stock} · Prix unitaire : ${unit} ₽</p><div class="cost-line"><span>Total</span><strong data-transaction-total>${q*unit} ₽</strong></div><div class="cost-line"><span>Argent</span><strong>${balance} ₽</strong></div><div class="cost-line"><span>Après ${selling?'la vente':'l’achat'}</span><strong data-transaction-after>${invalid?'—':(selling?balance+q*unit:balance-q*unit)+' ₽'}</strong></div></div>`,v==='insufficient-funds'?'Vous n’avez pas assez d’argent.':errorState(v)?'La transaction a échoué. Aucun argent n’a été retiré.':v==='inventory-limit'?'Cette quantité dépasse la place disponible. Réduisez-la.':v==='stock-limit'?'Le stock ne permet pas cette quantité. Réduisez-la.':'');
    }
    const selling=s.id==='shop.sell';
    return shell(s,m,`${tabs([['shop.buy','Acheter'],['shop.sell','Vendre']],s.id)}${emptyState(v)?empty('Aucun objet disponible','Vous pouvez revenir plus tard.','store'):`<div class="split-layout"><div>${items.slice(0,4).map((x,i)=>row(x.name,`${selling?'Dans le Sac : '+x.count:'Stock : 12'} · ${selling?Math.floor(x.price/2):x.price} ₽`,'shop.quantity',x.icon,i===0,(v==='out-of-stock'&&i===0)||(v==='unsellable'&&i===3)).replace('data-screen=',`data-item="${i}" data-screen=`)).join('')}</div><div class="detail-panel landscape-only"><div class="item-hero">${icon('flask-conical')}</div><h3>Potion</h3><p>Restaure 20 PV à un Pokémon.</p>${button(selling?'Vendre':'Acheter','shop.quantity','primary')}</div></div>`}`,button('Fermer','world.explore'),'world.explore','Boutique','Argent · 3 250 ₽');
  }
  function renderHeal(s,m,v) {
    if(s.id==='heal.applying') return renderLoading(s,m,v);
    const healed=(s.id==='heal.result'&&!errorState(v))||v==='already-healthy';
    const team=v==='empty'?empty('Équipe vide','Aucun compagnon ne peut être soigné.','paw-print'):`<div class="heal-team">${pokemon.map(p=>`<div class="row heal-member">${sprite(p)}<span style="flex:1"><strong>${p.name}</strong><span class="secondary-line">${healed?p.max:p.hp} / ${p.max} PV · ${healed?'PP restaurés · Aucun statut':p.status||'PP à restaurer'}</span>${gauge(healed?{...p,hp:p.max}:p)}</span></div>`).join('')}</div>`;
    if(s.id==='heal.result') return modal(m,errorState(v)?'Soin impossible':'Votre équipe est en pleine forme !',errorState(v)?'Le soin n’a pas abouti. Vous pouvez réessayer.':'Les PV, les PP et les altérations de statut de votre équipe ont été restaurés.',button(errorState(v)?'Réessayer':'Reprendre',errorState(v)?'heal.confirm':'world.explore','primary'),team);
    return modal(m,'Soigner votre équipe ?', v==='already-healthy'?'Votre équipe est déjà en pleine forme.':'Nous pouvons restaurer les PV et les PP de vos compagnons.',button('Soigner','heal.applying','primary',/already-healthy|empty|unavailable/.test(v))+button('Annuler','world.explore'),team);
  }
  function renderPc(s,m,v) {
    if(s.id==='pc.summary') return renderParty(s,m,v);
    if(s.id==='pc.swap') return shell(s,m,`${notice('Choisissez le membre de votre équipe à échanger avec Bulbi.')}<div class="party-list">${pokemon.map((p,i)=>partyRow(p,i,'pc.box',{disabled:(_,j)=>v==='disabled-candidate'&&j===0})).join('')}</div>`,button('Annuler','pc.box'),'pc.box','Échanger avec l’équipe');
    if(s.id==='pc.move-box') return shell(s,m,`${stateNotice(v)}${notice('Choisissez la boîte de destination de Bulbi.')}<div class="stack">${row('Boîte 1','12 / 30 · Boîte actuelle','pc.box','grid-3x3')}${row('Boîte 2',v==='box-full'?'30 / 30 · Pleine':'8 / 30','pc.box','grid-3x3',false,v==='box-full')}${row('Boîte 3','0 / 30','pc.box','grid-3x3',true)}</div>`,button('Annuler','pc.box'),'pc.box','Choisir une boîte');
    const full=v==='full-box';
    const grid=Array.from({length:30},(_,i)=>`<button class="box-cell${i===0?' selected':''}" data-screen="pc.summary" aria-label="${full||i<12&&v!=='empty-box'?pokemon[i%6].species:'Emplacement vide '+(i+1)}">${full||i<12&&v!=='empty-box'?sprite(pokemon[i%6]):''}</button>`).join('');
    return shell(s,m,`${stateNotice(v)}${v==='last-usable-protected'?notice('Vous devez conserver au moins un compagnon capable de combattre.','', 'shield'):''}<div class="split-layout"><div><div class="box-grid-header"><button class="icon-button" data-toast="Boîte précédente" aria-label="Boîte précédente">${icon('chevron-left')}</button><strong>Boîte 1</strong><button class="icon-button" data-toast="Boîte suivante" aria-label="Boîte suivante">${icon('chevron-right')}</button></div><div class="box-grid">${grid}</div><div class="section-title">Équipe · 6 / 6</div><div class="mini-party">${pokemon.map(p=>`<button class="box-cell" data-screen="pc.swap">${sprite(p)}</button>`).join('')}</div></div><div class="detail-panel"><div class="row">${sprite()}<div><strong>Bulbi</strong><div class="meta">Bulbizarre · Niv. 16</div></div></div><div class="stack" style="margin-top:12px">${button('Voir la fiche','pc.summary','primary')}${button('Échanger avec l’équipe','pc.swap')}${button('Retirer','pc.box','',v==='full-party')}${button('Déposer','pc.box','',v==='last-usable-protected'||full)}</div></div></div>`,button('Fermer','world.explore'),'world.explore','Stockage PC','Boîte 1 · 12 / 30');
  }
  const postText = {victory:['Victoire !','Votre équipe a remporté le combat.'],defeat:['Votre équipe est K.O.','Vous allez être raccompagné vers un lieu sûr.'],fled:['Vous prenez la fuite','Votre équipe a quitté le combat.'],captured:['Capture réussie !','Roucool rejoint votre aventure.'],experience:['Expérience gagnée','Bulbi reçoit 164 points d’expérience.'],levelUp:['Niveau supérieur !','Bulbi passe du niveau 15 au niveau 16.'],moveAutomaticallyLearned:['Nouvelle capacité','Bulbi a appris Poudre Dodo.'],moveLearningPrompt:['Apprendre une capacité ?','Bulbi souhaite apprendre Poudre Dodo.'],moveReplacementPrompt:['Quelle capacité oublier ?','Bulbi connaît déjà quatre capacités.'],moveLearned:['Capacité apprise','Bulbi a appris Poudre Dodo.'],moveReplaced:['Capacité remplacée','Poudre Dodo remplace Rugissement.'],moveDeclined:['Apprentissage refusé','Bulbi conserve ses capacités actuelles.'],evolutionPrompt:['Faire évoluer Bulbi ?','Bulbi est prêt à évoluer.'],evolutionAccepted:['Évolution acceptée','La progression de Bulbi a été confirmée.'],evolutionRefused:['Évolution refusée','Bulbi conserve sa forme actuelle.'],money:['Argent obtenu','Vous recevez 480 ₽.'],item:['Objet obtenu','Une Potion a été ajoutée au Sac.'],flag:['Votre aventure progresse','Votre victoire ouvre la suite de l’histoire.'],badge:['Badge obtenu','Le Badge Forêt récompense votre victoire.'],fieldAbility:['Nouvelle possibilité sur le terrain','Vous pouvez désormais utiliser la capacité débloquée.'],trainerDefeated:['Dresseur vaincu','Vous avez remporté le défi de Léa.'],captureDestination:['Compagnon envoyé au PC','Roucool a été envoyé dans la Boîte 1. Votre équipe est complète.'],error:['Progression interrompue','La progression n’a pas pu être appliquée.']};
  function renderPost(s,m,v) {
    const key=s.id.split('.')[1];
    let [title,text]=postText[key];
    const bagResult=demo.bagResult;
    if(bagResult?.kind==='teach'&&['moveLearned','moveReplaced'].includes(key))text=bagResult.name+' a appris Protection'+(key==='moveReplaced'?' à la place de '+bagResult.move:'')+'.';
    if(bagResult?.kind==='evolution'&&key==='evolutionAccepted')text=bagResult.name+' a évolué en Phyllali. La Pierre Plante a été consommée.';
    if(key==='moveReplacementPrompt') return shell(s,m,`${notice(text)}${moveRows('postbattle.moveReplaced')}`,button('Ne pas apprendre','postbattle.moveDeclined'),'postbattle.moveLearningPrompt',title);
    const next={victory:'postbattle.experience',defeat:'world.explore',fled:'world.explore',captured:'gift.pokedex',experience:'postbattle.levelUp',levelUp:'postbattle.moveLearningPrompt',moveLearningPrompt:'postbattle.moveReplacementPrompt',moveLearned:'postbattle.money',moveReplaced:'postbattle.money',evolutionPrompt:'postbattle.evolutionAccepted',evolutionAccepted:'postbattle.money',money:'world.explore',captureDestination:'world.explore'}[key]||'world.explore';
    const decision=/Prompt/.test(key);
    const visual=key==='badge'?`<div class="detail-hero">${icon('award')}</div>`:key==='item'?`<div class="detail-hero"><div class="item-hero">${icon('flask-conical')}</div></div>`:bagResult?.kind==='evolution'&&key==='evolutionAccepted'?`<div class="detail-hero">${icon('sparkles')}<strong>Phyllali</strong></div>`:sprite(bagResult&&['moveLearned','moveReplaced'].includes(key)?pokemon[bagResult.pokemon]:key==='captured'||key==='captureDestination'?pokemon[5]:pokemon[0],'hero-sprite');
    return modal(m,title,text,button(decision?'Oui, continuer':'Continuer',next,'primary')+(decision?button('Non',key==='evolutionPrompt'?'postbattle.evolutionRefused':'postbattle.moveDeclined'):''),`<div style="text-align:center">${visual}</div>${key==='experience'?`<div class="progress-label"><span>Niv. 15</span><span>+164 EXP</span></div>${gauge({hp:84,max:100},'exp')}`:''}${key==='levelUp'?'<div class="data-grid"><div><span class="meta">PV</span><div class="value">45 → 48</div></div><div><span class="meta">Attaque</span><div class="value">26 → 28</div></div></div>':''}`,key==='error'?'Les récompenses non confirmées ne doivent pas être présentées comme acquises.':'');
  }
  function renderGiftTrade(s,m,v) {
    if(s.id==='gift.nickname') return renderInteraction(s,m,v);
    if(s.id.startsWith('trade.select')) return renderParty(s,m,v);
    if(s.id==='trade.choose-partner')return shell(s,m,`${stateNotice(v)}${overview()}<div class="section-title">Partenaire d’échange</div><div class="stack">${button('Conserver le partenaire sélectionné','trade.review','primary')}${button('Choisir un autre membre','trade.select-partner')}${button('Annuler','party.list')}</div>`,button('Retour','trade.select-first'),'trade.select-first','Choisir le partenaire');
    if(s.id==='trade.review'||s.id==='trade.result') return modal(m,s.id==='trade.review'?'Confirmer cet échange ?':'Échange terminé',s.id==='trade.review'?'Les deux compagnons sélectionnés seront échangés selon les règles de cette interaction.':'Les compagnons ont été échangés.',button(busyState(v)?'En cours…':s.id==='trade.review'?'Confirmer':'Fermer',s.id==='trade.review'?'trade.result':'world.explore','primary',busyState(v))+(s.id==='trade.review'?button('Annuler','trade.select-first'):''),`<div class="trade-pair"><div>${sprite(pokemon[0],'hero-sprite')}<h3>Bulbi</h3><span class="meta">Niv. 16</span></div>${icon('arrow-right-left')}<div>${sprite(pokemon[2],'hero-sprite')}<h3>Carapuce</h3><span class="meta">Niv. 14</span></div></div>`,errorState(v)?'L’échange n’a pas été appliqué.':'');
    const isDest=s.id==='gift.destination';
    const title=s.id==='gift.received'?'Vous recevez Bulbizarre !':s.id==='gift.pokedex'?'Nouvelle entrée au Pokédex':s.id==='gift.nickname-confirm'?'Donner un surnom ?':'Direction le PC';
    const text=isDest?'Votre équipe est complète. Bulbi a été envoyé dans la Boîte 1.':s.id==='gift.pokedex'?'Les données de Bulbizarre ont été ajoutées à votre Pokédex.':s.id==='gift.nickname-confirm'?'Souhaitez-vous donner un surnom à Bulbizarre ?':'Bulbizarre rejoint votre aventure.';
    const target={'gift.received':'gift.pokedex','gift.pokedex':'gift.nickname-confirm','gift.nickname-confirm':'gift.nickname','gift.destination':'world.explore'}[s.id];
    return modal(m,title,text,button(s.id==='gift.nickname-confirm'?'Oui':'Continuer',target,'primary',busyState(v))+(s.id==='gift.nickname-confirm'?button('Non','gift.destination'):''),`<div style="text-align:center">${sprite(pokemon[0],'hero-sprite')}</div>`,errorState(v)?'L’étape n’a pas pu être confirmée. Réessayez.':'');
  }
  const combat={active:0,move:0,item:0,member:0,pp:0,target:5,action:'move',pocket:'medicine',forgot:0,targetChoices:[5]};
  const activeFighter=()=>pokemon[combat.active];
  const selectedAttack=()=>movesFor(activeFighter())[combat.move]||movesFor(activeFighter())[0];
  const combatMoveMeta=x=>({ 'Fouet Lianes':['45','100 %','La cible est fouettée avec de fines lianes.','Peu efficace'],Charge:['40','100 %','Le lanceur percute la cible avec tout son corps.','Efficacité normale'],Vampigraine:['—','90 %','Des graines drainent les PV de la cible à chaque tour.','Statut'], 'Poudre Dodo':['—','75 %','Une poudre qui endort la cible.','Statut']}[x.name]||['—','—','Consultez les informations de cette capacité.','']);
  const combatType=x=>({'Plante':'grass','Poison':'poison','Feu':'fire','Eau':'water','Électrik':'electric','Vol':'flying','Sol':'ground'}[x]||'normal');
  const combatAction=(label,target,cls='',data='',disabled=false)=>`<button class="combat-button ${cls}" data-screen="${target}" ${data}${disabled?' disabled aria-disabled="true"':''}>${label}</button>`;
  function combatFooter(m,back='battle.root',confirm='Choisir') {
    return `<footer class="combat-footer">${back?combatAction(`${icon('arrow-left')}<span>Retour</span>`,back,'combat-back'):''}${isPad(m)?hints(m,confirm,back?'Retour':''):''}</footer>`;
  }
  function combatHud(p,side) {
    return `<div class="battle-hud combat-hud ${side}"><div class="combat-hud-name"><strong>${esc(p.name)}</strong><span class="combat-sex">♂</span><span>N.${p.level}</span></div><div class="combat-health"><b>PV</b>${gauge(p)}</div>${side==='ally'?`<div class="combat-numbers">${p.status?`<span class="combat-status">${p.status}</span>`:''}<strong>${p.hp}<small> / ${p.max}</small></strong></div><div class="combat-exp"><span>EXP</span>${gauge({hp:62,max:100},'exp')}</div>`:''}</div>`;
  }
  function battleScene(expanded=false,extra='',ally=activeFighter(),sceneState={}) {
    const target=sceneState.target;
    const enemies=sceneState.multiple?[{...pokemon[5],level:12,hp:27,max:36},{...pokemon[4],hp:28,status:'',level:12}]:[{...pokemon[5],level:12,hp:27,max:36}];
    return `<div class="battle-scene combat-arena${expanded?' expanded-battle':''}${sceneState.multiple?' multi-targets':''}${target!==undefined?' targeting':''}">${enemies.map((p,i)=>`<div class="enemy-position enemy-${i}${target===pokemon.indexOf(p)||target===(i===0?5:4)?' target-selected':''}">${sprite(p,'battle-creature enemy')}${target===(i===0?5:4)?`<span class="target-reticle">${icon('chevrons-down')}<span>Cible</span></span>`:''}</div>`).join('')}${sprite(ally,'battle-creature ally','back')}${combatHud(enemies[0],'enemy')}${sceneState.multiple?`<div class="second-enemy-name"><strong>Évoli</strong> · N.12${gauge({hp:28,max:39})}</div>`:''}${combatHud(ally,'ally')}${extra}</div>`;
  }
  function combatMessage(text,actions='',label='') {
    return `<section class="battle-message combat-narration">${label?`<span class="combat-event-label">${esc(label)}</span>`:''}<div class="combat-message-copy">${esc(text)}</div>${actions?`<div class="combat-message-actions">${actions}</div>`:''}</section>`;
  }
  function combatTurnText(v) {
    const p=activeFighter(),item=items[combat.item],member=pokemon[combat.member];
    if(v==='hp-tween')return 'Roucool perd des PV !';
    if(v==='xp-tween')return p.name+' gagne de l’expérience !';
    if(combat.action==='switch')return 'En avant, '+p.name+' !';
    if(combat.action==='capture')return 'Vous lancez une '+item.name+' !';
    if(combat.action==='item')return 'Vous utilisez '+item.name+' sur '+member.name+'.';
    if(combat.action==='pp')return 'Vous utilisez une Huile sur '+movesFor(member)[combat.pp].name+'.';
    return p.name+' utilise '+(combat.action==='struggle'?'Lutte':selectedAttack().name)+(combat.target===4?' sur Évoli':'')+' !';
  }
  function combatPanel(title,body,m,kind,back='battle.root',extra='') {
    return `<section class="battle-dock combat-surface combat-${kind}"><header class="combat-panel-title"><span class="combat-kicker">${kind==='root'?'À VOUS DE JOUER':kind==='moves'?'CHOISIR UNE CAPACITÉ':kind==='bag'?'SAC DE COMBAT':kind==='target'?'CHOISIR LA CIBLE':'VOTRE ÉQUIPE'}</span><h3>${title}</h3></header>${body}${extra}${combatFooter(m,back)}</section>`;
  }
  function combatInfoPanel(p,v,restoring=false) {
    const choices=v==='struggle-if-projected'?[{name:'Lutte',type:'Normal',pp:0,max:0}]:movesFor(p);
    const active=Math.min(combat.move,choices.length-1);
    return `<section class="combat-info-panel" role="dialog" aria-modal="true" aria-label="Informations des capacités" hidden><h3>${restoring?'Choisissez la capacité dont vous souhaitez restaurer les PP.':'Informations des capacités'}</h3><div class="combat-info-tabs">${choices.map((x,i)=>`<button data-move-info="${i}" class="${i===active?'selected':''}">${esc(x.name)}</button>`).join('')}</div>${choices.map((x,i)=>{const meta=combatMoveMeta(x);return `<div class="combat-info-copy" data-move-info-copy="${i}"${i!==active?' hidden':''}><div class="row between"><strong>${esc(x.type)} · PP ${x.pp} / ${x.max}</strong><strong>Puiss. ${meta[0]} · Préc. ${meta[1]}</strong></div><p>${esc(x.name==='Lutte'?'Le lanceur s’inflige aussi des dégâts.':meta[2])}</p></div>`;}).join('')}<button class="game-button" data-combat-info-close>Fermer les informations</button></section>`;
  }
  function renderBattle(s,m,v,commandsOnly=false) {
    const p=s.id==='battle.forced-replacement'?{...activeFighter(),hp:0,status:'K.O.'}:activeFighter();
    let panel='',kind='root';
    const root=s.id==='battle.root'||s.id==='companion.battle';
    if(['battle.intro','battle.turn','battle.continue'].includes(s.id)) {
      const intro=s.id==='battle.intro',turn=s.id==='battle.turn';
      const text=intro?(v==='trainer'?'Léa veut se battre !':'Un Roucool sauvage apparaît !'):turn?combatTurnText(v):'Ce n’est pas très efficace…';
      const next=intro?'battle.root':'postbattle.victory';
      const actions=!turn&&v!=='transition'?combatAction(`Continuer ${icon('chevron-right')}`,next,'combat-continue'):'';
      if(commandsOnly)return `<div class="combat-ui combat-phase"><span class="combat-kicker">${turn?'RÉSOLUTION DU TOUR':'COMBAT'}</span><h3>${turn?'L’action se déroule':'Suivez le combat'}</h3><p>${esc(text)}</p><div class="combat-phase-line"></div><span class="combat-phase-note">${turn?'Les commandes reviendront après la résolution.':'La scène est affichée sur l’écran principal.'}</span>${actions}${isPad(m)?hints(m,turn?'Veuillez patienter':'Continuer',''):''}</div>`;
      return `<div class="combat-ui combat-view-message">${battleScene(true,combatMessage(text,m==='thor-dual'?'':actions,intro?'RENCONTRE':turn?'ACTION EN COURS':'COMBAT'),p,{multiple:turn&&combat.targetChoices.length>1})}</div>`;
    }
    if(s.id==='battle.decision')return renderCombatPost(screenMap.get(v==='evolution'?'postbattle.evolutionPrompt':'postbattle.moveLearningPrompt'),m,'active',commandsOnly);
    if(root) {
      const locked=v==='commands-disabled-while-turn';
      const entries=combatAction(`<span>Attaquer</span>${icon('arrow-up-right')}`,'battle.fight','battle-command command-fight selected','',locked)+combatAction(`<span>Pokémon</span>`,'battle.party','battle-command command-party','',locked)+combatAction(`<span>Sac</span>`,'battle.bag','battle-command command-bag','data-state="medicine"',locked||v==='bag-unavailable')+combatAction(`<span>Fuite</span>`,'postbattle.fled','battle-command command-run','',locked||v==='run-forbidden');
      panel=combatPanel(`Que doit faire <strong>${esc(p.name)}</strong> ?`,`<div class="battle-entries battle-command-grid">${entries}</div>`,m,'root','',v==='run-forbidden'?'<p class="combat-rule">Vous ne pouvez pas fuir ce combat.</p>':v==='bag-unavailable'?'<p class="combat-rule">Le Sac est indisponible dans ce combat.</p>':locked?'<p class="combat-rule">Le tour se déroule…</p>':'');
    } else if(s.id==='battle.fight') {
      kind='moves';
      const fightMoves=movesFor(p);
      const targets=v==='multiple-valid-targets'?[5,4]:[5];
      const destination=targets.length>1?'battle.target':'battle.turn';
      const targetData=`data-combat-targets="${targets.join(',')}" data-state="${targets.length>1?'multiple-valid-targets':'presentingTurn'}"`;
      const entries=v==='struggle-if-projected'?combatAction('<strong>Lutte</strong><span>Aucune capacité ne dispose de PP.</span>',destination,'combat-move selected',`data-combat-struggle="true" ${targetData}`):fightMoves.map((x,i)=>combatAction(`<span class="combat-move-top"><strong>${x.name}</strong><b class="combat-type ${combatType(x.type)}">${x.type}</b></span><span class="combat-move-bottom"><span>${x.pp===0?'Épuisée':combatMoveMeta(x)[3]||'Capacité'}</span><strong>PP ${x.pp}<small> / ${x.max}</small></strong></span>`,destination,`combat-move type-${combatType(x.type)}${i===combat.move?' selected':''}`,`data-combat-move="${i}" ${targetData}`,x.pp===0)).join('');
      const x=selectedAttack(),meta=combatMoveMeta(x);
      panel=combatPanel(p.name,`<div class="battle-entries combat-move-grid">${entries}</div>`,m,'moves','battle.root',`<div class="combat-move-detail"><span>${esc(v==='struggle-if-projected'?'Le lanceur s’inflige aussi des dégâts.':meta[2])}</span><div><b>Puiss. ${meta[0]}</b><b>Préc. ${meta[1]}</b></div></div>`);
    } else if(s.id==='battle.target') {
      kind='target';
      const x=combat.action==='struggle'?{name:'Lutte',type:'Normal'}:selectedAttack();
      const entries=[5,4].map(i=>combatAction(`${sprite(pokemon[i],'combat-target-sprite')}<span><strong>${pokemon[i].species}</strong><small>Niveau ${i===5?12:pokemon[i].level}</small></span>${icon('crosshair')}`,'battle.turn',`combat-target-choice${i===combat.target?' selected':''}`,`data-combat-target="${i}" data-combat-targets="5,4"`,v==='disabled-target')).join('');
      panel=combatPanel(x.name,`<p class="combat-instruction">Quelle cible souhaitez-vous viser ?</p><div class="battle-entries combat-target-list">${entries}</div>`,m,'target','battle.fight',v==='disabled-target'?'<p class="combat-rule">La cible n’est plus disponible.</p>':'').replace('data-screen="battle.fight"','data-screen="battle.fight" data-state="multiple-valid-targets"');
    } else if(s.id==='battle.bag') {
      kind='bag';
      const pocket=v==='balls'?'balls':v==='medicine'?'medicine':combat.pocket;
      const list=pocket==='balls'?items.filter(x=>x.pocket==='Balls'):items.filter(x=>x.pocket==='Soins');
      const tabsHtml=`<div class="combat-pockets">${combatAction('Soins','battle.bag',pocket==='medicine'?'selected':'','data-state="medicine"')}${combatAction('Balls','battle.bag',pocket==='balls'?'selected':'','data-state="balls"')}</div>`;
      const entries=list.map(x=>{const i=items.indexOf(x);return combatAction(`${icon(x.icon)}<span><strong>${x.name}</strong><small>${x.name==='Huile'?'Récupérer des PP':pocket==='balls'?'Capture':x.desc.replace(' à un Pokémon.','.').replace(' d’un Pokémon.','.').replace('Une baie à donner ou à utiliser pour récupérer des PV.','Récupérer 10 PV.')}</small></span><b>×${x.count}</b>`,pocket==='balls'?'battle.turn':'battle.medicine-target',`combat-item${i===combat.item?' selected':''}`,`data-combat-item="${i}" data-combat-action="${pocket==='balls'?'capture':'item'}"`,v==='item-disabled'&&i===1);}).join('');
      panel=combatPanel('Choisir un objet',`${tabsHtml}<div class="battle-entries combat-item-grid">${v==='empty'?empty('Cette poche est vide','Choisissez une autre poche.','backpack'):entries}</div>`,m,'bag','battle.root');
    } else if(s.id==='battle.medicine-move') {
      kind='moves';const member=pokemon[combat.member];
      const entries=movesFor(member).map((x,i)=>combatAction(`<span class="combat-move-top"><strong>${x.name}</strong><b class="combat-type ${combatType(x.type)}">${x.type}</b></span><span class="combat-move-bottom"><span>${x.pp===x.max?'PP au maximum':`+${Math.min(10,x.max-x.pp)} PP`}</span><strong>${x.pp} / ${x.max}</strong></span>`,'battle.turn',`combat-move type-${combatType(x.type)}`,`data-combat-pp="${i}"`,x.pp===x.max)).join('');
      panel=combatPanel(`Huile · ${member.name}`,`<div class="battle-entries combat-move-grid">${entries}</div>`,m,'moves','battle.medicine-target','<p class="combat-rule">Choisissez la capacité dont vous souhaitez restaurer les PP.</p>');
    } else if(['battle.party','battle.forced-replacement','battle.medicine-target'].includes(s.id)) {
      kind='team';const forced=s.id==='battle.forced-replacement',medicine=s.id==='battle.medicine-target',item=items[combat.item];
      const entries=pokemon.map((base,i)=>{const member=forced&&i===combat.active?{...base,hp:0,status:'K.O.'}:base;let reason=medicine?({'Les PV sont déjà au maximum.':'PV au maximum','Cet objet ne ranime pas les compagnons K.O.':'K.O.','Ce compagnon n’est pas K.O.':'Pas K.O.','Ce compagnon n’est pas empoisonné.':'Aucun poison','Toutes les capacités disposent de leurs PP.':'PP au maximum'}[bagTargetReason(item,member)]||bagTargetReason(item,member)):i===combat.active?(forced?'K.O.':'Au combat'):member.hp===0?'K.O.':'';if(!medicine&&v==='trapped-if-runtime')reason='Changement impossible';if(medicine&&v==='ineligible'&&i===0)reason='Cible incompatible';return combatAction(`${sprite(member,'combat-party-sprite')}<span class="combat-member-data"><span class="combat-member-name"><strong>${member.name}</strong><small>N.${member.level}</small></span>${gauge(member)}<span class="combat-member-hp"><b>${member.hp} / ${member.max}</b><small>${reason||member.status||(medicine?'Choisir':'Prêt')}</small></span></span>`,medicine&&item.name==='Huile'?'battle.medicine-move':'battle.turn',`combat-member${i===(medicine?combat.member:combat.active)?' selected':''}`,medicine?`data-combat-member="${i}" data-combat-action="${item.name==='Huile'?'pp':'item'}"`:`data-combat-active="${i}"`,Boolean(reason));}).join('');
      panel=combatPanel(medicine?item.name:forced?'Choisir un remplaçant':'Changer de Pokémon',`<p class="combat-instruction">${medicine?esc(item.desc):forced?esc(p.name)+' est K.O. Choisissez un autre Pokémon.':'Qui souhaitez-vous envoyer au combat ?'}</p><div class="battle-entries combat-team-grid">${entries}</div>`,m,'team',forced?'':medicine?'battle.bag':'battle.root');
    }
    if(['battle.fight','battle.medicine-move'].includes(s.id)&&isLandscape(m))panel=panel.replace('<footer class=\"combat-footer\">','<footer class=\"combat-footer\"><button class=\"combat-button combat-info-open\" data-combat-info-open>'+icon('info')+'<span>Infos</span></button>')+combatInfoPanel(s.id==='battle.medicine-move'?pokemon[combat.member]:p,v,s.id==='battle.medicine-move');
    return `<div class="combat-ui combat-view-${kind}${commandsOnly?' commands-only':''}">${commandsOnly?'':battleScene(false,'',p,{target:s.id==='battle.target'?combat.target:undefined,multiple:(s.id==='battle.target')||(s.id==='battle.fight'&&v==='multiple-valid-targets')||(s.id==='battle.turn'&&combat.targetChoices.length>1)})}${panel}</div>`;
  }
  function renderCombatPost(s,m,v,commandsOnly=false) {
    if(demo.bagResult)return renderPost(s,m,v);
    const key=s.id.split('.')[1],p=activeFighter();
    let [title,text]=postText[key]||[s.label,'Votre progression a été confirmée.'];
    text=text.replaceAll('Bulbi',p.name);
    text=text.replaceAll('Poudre Dodo','Croissance');
    if(key==='moveReplaced')text='Croissance remplace '+movesFor(p)[combat.forgot].name+'.';
    if(key==='levelUp')text=p.name+' passe du niveau '+p.level+' au niveau '+(p.level+1)+'.';
    const next={victory:'postbattle.experience',defeat:'world.explore',fled:'world.explore',captured:'postbattle.captureDestination',experience:'postbattle.levelUp',levelUp:'postbattle.moveLearningPrompt',moveLearningPrompt:'postbattle.moveReplacementPrompt',moveLearned:'postbattle.money',moveReplaced:'postbattle.money',evolutionPrompt:'postbattle.evolutionAccepted',evolutionAccepted:'postbattle.money',money:'world.explore',captureDestination:'world.explore'}[key]||'world.explore';
    const decision=/Prompt/.test(key);
    let body=`<div class="combat-result-heading"><span class="combat-kicker">${key==='victory'?'FIN DU COMBAT':key==='experience'?'PROGRESSION':'VOTRE AVENTURE'}</span><h3>${esc(title)}</h3></div><p class="combat-result-copy">${esc(text)}</p>`;
    if(key==='experience')body+=`<div class="combat-reward"><strong>+164</strong><span>POINTS D’EXPÉRIENCE</span></div><div class="combat-xp-line"><span>Niv.${p.level}</span>${gauge({hp:84,max:100},'exp')}<span>Niv.${p.level+1}</span></div>`;
    if(key==='levelUp'){const stats=statsFor(p);body+=`<div class="combat-level-stats"><span>PV<strong>${p.max} → ${p.max+3}</strong></span><span>Attaque<strong>${stats[1]} → ${stats[1]+2}</strong></span><span>Défense<strong>${stats[2]} → ${stats[2]+2}</strong></span></div>`;}
    if(key==='money')body+='<div class="combat-reward"><strong>+480 ₽</strong></div>';
    let actions=combatAction(decision?'Accepter':'Continuer',next,'combat-continue selected')+(decision?combatAction('Refuser',key==='evolutionPrompt'?'postbattle.evolutionRefused':'postbattle.moveDeclined','combat-refuse'):'');
    if(key==='moveReplacementPrompt'){body+=`<div class="combat-forget-list">${movesFor(p).map((x,i)=>combatAction(`<strong>${x.name}</strong><small>${x.type} · PP ${x.pp} / ${x.max}</small>`,'postbattle.moveReplaced','combat-forget',`data-combat-forget="${i}"`)).join('')}</div>`;actions=combatAction('Ne pas apprendre','postbattle.moveDeclined','combat-refuse');}
    if(key==='error'){actions=combatAction('Réessayer','postbattle.victory','combat-continue')+combatAction('Fermer','world.explore','combat-refuse');body+='<p class="combat-rule">Les récompenses non confirmées ne sont pas acquises.</p>';}
    const panel=`<section class="combat-result-panel">${body}<div class="combat-result-actions">${actions}</div>${isPad(m)?hints(m,decision?'Choisir':'Continuer',decision?'Refuser':''):''}</section>`;
    return `<div class="combat-ui combat-view-result${commandsOnly?' commands-only':''}">${commandsOnly?'':battleScene(true,'',p)}${panel}</div>`;
  }
  function renderSession(s,m,v) {
    if(s.id==='session.credits') return `<div class="game-shell">${header('Crédits','','')}<div class="screen-body"><div style="text-align:center;padding:22px"><h2 class="big-copy">Les Clairières</h2><p class="muted">Une aventure créée avec Avelune</p><div class="section-title">Création du jeu</div><p>Yoahn</p><div class="section-title">Remerciements</div><p class="body-copy">À toutes celles et ceux qui donnent vie à ces mondes.</p><div class="section-title">Ressources</div><p class="meta">Les crédits et licences du jeu sont fournis par son auteur.</p></div></div>${footer(m,button('Retour au titre','title.menu','primary'),'Retour au titre','title.menu')}</div>`;
    if(s.id==='session.result') return modal(m,'Merci d’avoir joué !','Vous avez terminé cette aventure. Votre équipe et votre progression sont conservées selon les règles du jeu.',button('Voir les crédits','session.credits','primary',v==='credits-disabled')+button('Retour au titre','title.menu'),`<div class="mini-party">${pokemon.map(p=>`<span class="box-cell">${sprite(p)}</span>`).join('')}</div>`);
    if(/error/.test(s.id)) return modal(m,s.id==='startup.error'?'Le jeu n’a pas pu démarrer':'Impossible de poursuivre', 'Une erreur empêche la poursuite de la session. Votre partie n’a pas été remplacée.',button('Réessayer','session.loading','primary',v==='hubOnly')+button('Retour au titre','title.menu','',v==='hubOnly')+button('Fermer','session.closing'),'', 'Le chargement des ressources n’a pas abouti.');
    return renderLoading(s,m,v);
  }
  function renderCompanionState(s,m,v) {
    return `<div class="companion-idle">${icon(s.id==='companion.blocked'?'monitor-x':'monitor')}<h3>${s.id==='companion.blocked'?'Écran principal actif':s.id==='companion.waiting'?'Votre aventure se prépare':'Menu compagnon'}</h3><p>${v==='world-service-on-owner'?'Cette interaction se déroule sur l’écran principal.':v==='not-attached'||v==='detached'?'L’écran compagnon n’est plus disponible. Les commandes reviennent à l’écran principal.':s.id==='companion.blocked'?'Une interaction est en cours. Les commandes seront de nouveau disponibles ensuite.':'Vous retrouverez ici vos menus et les commandes de combat.'}</p>${s.id==='companion.menu'?button('Ouvrir le menu','pause.root','primary'):s.id==='companion.battle'?button('Commandes de combat','battle.root','primary'):''}</div>`;
  }
  function renderHost(s,m,v) {
    if(s.id==='host.legacy-menu') return shell(s,m,`${notice('Chemin de secours du host de développement.')}<div class="stack">${row('Équipe','','party.list','paw-print')}${row('Sauvegarder','','save.confirm','save')}${row('Charger','','session.loading','folder-open')}${row('Quitter','','session.closing','log-out')}</div>`,button('Fermer','world.explore'),'world.explore','Menu de secours');
    return shell(s,m,`${notice('Outil développeur · hors parcours du jeu distribué.')}<div class="stack">${button('Choisir un dossier de jeu','host.project-loader','primary',false,'folder-open')}${row('Projet sélectionné','golden_battle_slice','host.project-loader','folder')}${row('Carte de départ','Clairière des Sources','map.view','map-pin')}${button('Lancer le jeu','startup.prepare','',v==='empty'||v==='loading')}</div>${errorState(v)?notice('Le dossier sélectionné ne contient pas un jeu valide.','error'):''}`,button('Fermer','session.closing'),'','Ouvrir un projet');
  }
  function content(s,m,v,commandsOnly=false) {
    const id=s.id;
    if(id==='title.menu') return renderTitle(s,m,v);
    if(id==='title.load-slot') return shell(s,m,`${notice('Choisissez une partie enregistrée.')}<div class="stack">${row('Yoahn','Clairière des Sources · 02 h 34','session.loading','save',true)}${row('Emplacement indisponible','Aucune donnée lisible','save.recovery','circle-alert',false,v==='unavailable')}</div>`,button('Retour','title.menu'),'title.menu','Charger une partie');
    if(id.startsWith('startup.')&&!id.endsWith('error')) return renderLoading(s,m,v);
    if(id==='startup.error'||id.startsWith('session.')) return renderSession(s,m,v);
    if(id==='world.cinematic') return renderLoading(s,m,v);
    if(id.startsWith('world.')) return renderWorld(s,m,v);
    if(id.startsWith('dialogue.')) return renderDialogue(s,m,v);
    if(id.startsWith('newgame.')||id.startsWith('interaction.')) return renderInteraction(s,m,v);
    if(id.startsWith('pause.')) return renderPause(s,m,v);
    if(id.startsWith('party.')||id==='pokemon.summary') return renderParty(s,m,v);
    if(id.startsWith('bag.')) return renderBag(s,m,v);
    if(id.startsWith('dex.')) return renderDex(s,m,v);
    if(id.startsWith('map.')) return renderMap(s,m,v);
    if(id.startsWith('profile.')) return renderProfile(s,m,v);
    if(id.startsWith('quests.')||id.startsWith('contacts.')) return renderContacts(s,m,v);
    if(id.startsWith('options.')) return renderOptions(s,m,v);
    if(id.startsWith('save.')) return renderSave(s,m,v);
    if(id.startsWith('shop.')) return renderShop(s,m,v);
    if(id.startsWith('heal.')) return renderHeal(s,m,v);
    if(id.startsWith('pc.')) return renderPc(s,m,v);
    if(id.startsWith('gift.')||id.startsWith('trade.')) return renderGiftTrade(s,m,v);
    if(id.startsWith('battle.')) return renderBattle(s,m,v,commandsOnly);
    if(id.startsWith('postbattle.')) return renderCombatPost(s,m,v,commandsOnly);
    if(id.startsWith('companion.')) return renderCompanionState(s,m,v);
    if(id.startsWith('host.')) return renderHost(s,m,v);
    throw new Error('Composition non définie : '+id);
  }
  const proposedDual = s => /^(newgame|dialogue|interaction|shop|heal|pc|gift|trade|postbattle|contacts)\./.test(s.id);
  function primaryPreview(s,m,v) {
    if(s.id.startsWith('battle.')||s.id==='companion.battle'||s.id.startsWith('postbattle.')&&!demo.bagResult){const p=s.id==='battle.forced-replacement'?{...activeFighter(),hp:0,status:'K.O.'}:activeFighter();const text=s.id==='battle.turn'?combatTurnText(v):s.id==='battle.intro'?(v==='trainer'?'Léa veut se battre !':'Un Roucool sauvage apparaît !'):s.id==='battle.continue'?'Ce n’est pas très efficace…':'';return `<div class="combat-ui combat-primary">${battleScene(true,text?combatMessage(text):'',p,{target:s.id==='battle.target'?combat.target:undefined,multiple:(s.id==='battle.target')||(s.id==='battle.fight'&&v==='multiple-valid-targets')||(s.id==='battle.turn'&&combat.targetChoices.length>1)})}</div>`;}
    if(/^(party|pokemon|dex|gift|trade|pc)\./.test(s.id)) {
      if(s.id==='dex.detail'&&v==='unknown') return `<div class="game-shell">${empty('Observation inconnue','Cette entrée sera révélée au fil de votre aventure.','scan-search')}</div>`;
      return `<div class="game-shell">${s.id.startsWith('dex.')?dexSpecies(pokemon[demo.pokemon],v):overview(pokemon[demo.pokemon],true)}</div>`;
    }
    if(s.id.startsWith('startup.')||s.id.startsWith('title.')||s.id==='session.credits'||s.id==='session.result') return `<div class="title-scene"></div><div class="preview-shade"></div><div class="preview-title"><strong>Les Clairières</strong><small>Votre aventure commence ici</small></div>`;
    return `<div class="world"><div class="location">Clairière des Sources</div></div><div class="preview-shade"></div><div class="preview-title"><strong>${esc(s.id.startsWith('shop.')?'Boutique des Sources':s.id.startsWith('heal.')?'Le repos de votre équipe':s.id.startsWith('map.')?'Les Clairières':s.id.startsWith('dialogue.')?'Une rencontre':s.id.startsWith('options.')?'À votre rythme':'Clairière des Sources')}</strong><small>${esc(s.id.startsWith('save.')?'Votre partie est suspendue':s.id==='world.explore'?'Exploration en cours':'La partie est suspendue pendant cette interaction')}</small></div>`;
  }
  function secondaryContent(s,m,v) {
    if(s.id==='world.explore'||s.id==='world.notification') return `<div class="game-shell">${header('Mon aventure','Clairière des Sources','')}<div class="screen-body"><div class="pause-grid">${[['Équipe','party.list','paw-print'],['Sac','bag.list','backpack'],['Pokédex','dex.list','scan-search'],['Carte','map.view','map'],['Journal','quests.list','book-open'],['Contacts','contacts.list','phone'],['Profil','profile.card','contact-round'],['Options','options.categories','settings-2']].map(([label,id,ico])=>row(label,'',id,ico)).join('')}</div></div><footer class="screen-footer"><span class="input-hints"><span><b class="key">Menu</b>Ouvrir la navigation</span></span></footer></div>`;
    if(s.id==='companion.menu') return renderPause(screenMap.get('pause.root'),m,'root');
    if(s.id==='companion.battle') return renderBattle(screenMap.get('battle.root'),m,v==='busy'?'commands-disabled-while-turn':'normal',true);
    if(s.id.startsWith('postbattle.'))return renderCombatPost(s,m,v,true);
    if(s.id.startsWith('battle.'))return renderBattle(s,m,v,true);
    if(s.id.startsWith('startup.')&&s.id!=='startup.title-prompt'||s.id==='session.loading'||s.id==='session.closing'||s.id==='world.cinematic') return `<div class="companion-idle">${icon('sparkles')}<h3>Les Clairières</h3><p>L’aventure se prépare sur l’écran principal.</p></div>`;
    if(s.id==='party.list') return shell(s,m,partyList('party.detail'),'', 'pause.root','Équipe','6 compagnons');
    if(s.id==='party.detail'||s.id==='pokemon.summary'||s.id==='pc.summary') return renderParty(s,m,v);
    return content(s,m,v,true);
  }
  function decorateState(node,s,v,m) {
    const screen=node.querySelector('.screen');if(!screen)return;
    screen.dataset.composition=s.id;screen.dataset.state=v;
    const locked=busyState(v)||v==='read-only'||v==='completed'||v==='commands-disabled-while-turn'||v==='disabled-busy'||v==='disabled';
    if(locked) {
      screen.querySelectorAll('button,input,select').forEach(el=>{el.disabled=true;el.setAttribute('aria-disabled','true');});
      if(!screen.querySelector('.notice,.loading-scene,.battle-message')&&screen.querySelector('.screen-body'))screen.querySelector('.screen-body').insertAdjacentHTML('afterbegin',notice(v==='completed'?'Étape confirmée. La suite de la présentation va commencer.':v==='read-only'?'Consultation uniquement. Les valeurs ne peuvent pas être modifiées ici.':'Opération en cours… Les commandes sont temporairement indisponibles.'));
    }
    if(s.id==='battle.target'&&v==='disabled-target') {
      const el=screen.querySelector('.battle-entries button');if(el){el.disabled=true;el.classList.remove('selected');el.insertAdjacentHTML('beforeend','<span class="meta">Cible indisponible</span>');}
    }
    if(s.id==='battle.medicine-target')screen.querySelectorAll('[data-pokemon]').forEach(el=>{
      const p=pokemon[Number(el.dataset.pokemon)];if(bagTargetReason(items[combat.item],p)||(v==='ineligible'&&Number(el.dataset.pokemon)===0)){el.disabled=true;el.classList.remove('selected');}
    });
    if(s.id==='battle.party'&&v==='trapped-if-runtime') {
      screen.querySelectorAll('[data-pokemon]').forEach(el=>{el.disabled=true;el.classList.remove('selected');});
      screen.querySelector('.screen-body')?.insertAdjacentHTML('afterbegin',notice('Le combattant ne peut pas être remplacé pour le moment.','', 'lock-keyhole'));
    }
    if(s.id==='newgame.avatar'&&v==='option-disabled') {const el=screen.querySelector('.avatar-tile:last-child');if(el){el.disabled=true;el.insertAdjacentHTML('beforeend','<span class="meta">Indisponible</span>');}}
    if(/^newgame\.(avatar|starter)$/.test(s.id)&&v==='selection-required') {screen.querySelectorAll('.selected').forEach(x=>x.classList.remove('selected'));const el=screen.querySelector('.screen-footer .primary,.screen-footer .prompt-button');if(el)el.disabled=true;}
    if(s.id==='battle.intro'&&v==='hud-not-yet-revealed')screen.querySelectorAll('.battle-hud').forEach(x=>x.remove());
    if(s.id==='map.view'&&v==='selection-invalidated') {screen.querySelectorAll('.map-marker,.map-label').forEach(x=>x.remove());const el=screen.querySelector('.detail-panel');if(el)el.innerHTML=empty('Choisissez un lieu','La sélection précédente n’est plus disponible.','map-pin');}
    if(s.id==='party.detail'&&v==='missing-pp')screen.querySelectorAll('.game-row .meta').forEach(x=>{if(x.textContent.startsWith('PP'))x.textContent='PP —';});
    if(s.id==='world.explore'&&(v==='moving'||v==='running')) {const el=screen.querySelector('.joystick>span');if(el)el.style.transform='translateY(-24px)';screen.querySelector('.world')?.insertAdjacentHTML('beforeend',`<div class="movement-status">${icon(v==='running'?'footprints':'move-up')}${v==='running'?'Course':'Marche'}</div>`);}
    if(s.id==='postbattle.error'&&v==='pending')screen.querySelectorAll('.modal-actions button').forEach(x=>x.disabled=true);
    if(s.id==='options.bindings'&&v==='touch-swap-ab') {const body=screen.querySelector('.screen-body');if(body)body.innerHTML=notice('Inversez la position des deux actions tactiles.')+setting('Inverser les actions tactiles',false,'toggle');}
    if(s.id==='title.menu'&&v==='action-disabled-with-reason')screen.querySelector('.title-save')?.insertAdjacentHTML('beforeend','<p class="meta">La sortie vers la bibliothèque est indisponible dans cette session.</p>');
    if(s.id==='party.list'&&v==='missing-media')screen.querySelectorAll('.party-sprite').forEach(x=>x.remove());
    if(s.id==='options.choice')screen.querySelectorAll('button').forEach(x=>{if(x.dataset.screen)x.dataset.screen='options.'+demo.optionsCategory;});
    if(s.id==='options.reset'&&v)screen.querySelectorAll('[data-screen]').forEach(x=>x.dataset.screen='options.'+v);
    if(s.id==='battle.bag'&&v==='item-disabled')screen.querySelector('.battle-dock')?.insertAdjacentHTML('beforeend','<p class="meta">Cet objet ne peut pas être utilisé dans ce combat.</p>');
    if(s.id==='battle.fight'&&v==='struggle-if-projected') {const grid=screen.querySelector('.battle-entries');if(grid&&!grid.querySelector('[data-combat-struggle]'))grid.innerHTML=combatAction('<strong>Lutte</strong><small>Aucun PP disponible</small>','battle.turn','combat-move selected','data-combat-struggle="true" data-combat-targets="5" data-state="presentingTurn"');}
    if(s.id==='map.location'&&v==='discovered') {const p=screen.querySelector('.body-copy');if(p)p.textContent='Vous avez déjà découvert cet endroit. Vous pouvez consulter ses informations.';}
    if(v==='cancel-forbidden'||s.id==='battle.forced-replacement')screen.dataset.cannotCancel='true';
  }
  function applyFocus(node,m) {
    if(!isPad(m)) return;
    const buttons=[...node.querySelectorAll('button:not([disabled])')];
    const chosen=[...node.querySelectorAll('.selected:not([disabled])')].find(x=>x.getClientRects().length)||buttons.find(x=>!x.classList.contains('icon-button'));
    if(chosen){chosen.classList.add('focused');chosen.dataset.logicalFocus='true';}
  }
  function buildFrame(s,m,v,scale=1) {
    const def=modes[m];
    const board=document.createElement('div');board.className='board';board.dataset.screenId=s.id;board.dataset.mode=m;board.dataset.variant=v;
    board.innerHTML=`<div class="board-label">${esc(def.label)}<small>${m==='thor-dual'?'16:9 + 31:27':def.width+' × '+def.height}</small></div>`;
    if(m==='thor-dual') {
      const pair=document.createElement('div');pair.className='companion-pair';
      pair.style.width=(768*scale)+'px';
      const bottomPhysicalScale=.88;
      for(const [part,w,h,k,html] of [['primary',768,432,scale,primaryPreview(s,m,v)],['secondary',496,432,scale*bottomPhysicalScale,secondaryContent(s,m,v)]]) {
        const unit=document.createElement('div');unit.className='surface-unit';unit.style.width=(w*k)+'px';
        unit.innerHTML=`<div class="surface-label">${part==='primary'?'Écran principal':'Écran compagnon'}<span>${part==='primary'?'6″ · 1920 × 1080':'3,92″ · 1240 × 1080'}</span></div><div class="frame-shell" style="width:${w*k}px;height:${h*k}px"><div class="frame-scaler" style="transform:scale(${k});width:${w}px;height:${h}px"><div class="screen gamepad ${part==='primary'?'primary-display':'companion'}" style="width:${w}px;height:${h}px" data-display="${part}">${html}</div></div></div>`;
        pair.appendChild(unit);
        decorateState(unit,s,v,m);if(part==='secondary'&&!s.id.startsWith('world.'))applyFocus(unit,m);
      }
      board.appendChild(pair);
    } else {
      const shellNode=document.createElement('div');shellNode.className='frame-shell phone-frame';shellNode.style.width=def.width*scale+'px';shellNode.style.height=def.height*scale+'px';
      shellNode.innerHTML=`<div class="frame-scaler" style="transform:scale(${scale});width:${def.width}px;height:${def.height}px"><div class="screen ${def.orientation} ${def.input}" style="width:${def.width}px;height:${def.height}px" data-display="single">${content(s,m,v)}</div></div>`;
      board.appendChild(shellNode);decorateState(shellNode,s,v,m);applyFocus(shellNode,m);
    }
    return board;
  }
  function navigation() {
    const nav=document.getElementById('screen-nav');const oldScroll=nav.scrollTop;nav.innerHTML='';
    const visible=C.screens.filter(s=>!query||[s.id,s.label,s.group,...s.fields,...s.actions].join(' ').toLowerCase().includes(query));
    for(const group of Object.keys(groups)) {
      const list=visible.filter(s=>s.id.split('.')[0]===group);if(!list.length)continue;
      const section=document.createElement('div');section.className='nav-group';
      section.innerHTML=`<h2>${groups[group]}</h2>`+list.map(s=>`<button class="nav-item${selected===s.id?' active':''}" data-screen="${s.id}"><span class="nav-code">${String(C.screens.indexOf(s)+1).padStart(3,'0')}</span><span>${esc(s.label)}</span></button>`).join('');nav.appendChild(section);
    }
    if(!visible.length)nav.innerHTML='<div class="empty-search">Aucun écran ne correspond.</div>';
    nav.scrollTop=oldScroll;
    document.getElementById('sidebar-count').textContent=visible.length+' compositions · '+C.screens.length+' au total';
  }
  function annotations(s,m,v) {
    const def=modes[m];
    const combatScreen=/^(battle|postbattle)\./.test(s.id)||s.id==='companion.battle';
    const layout=combatScreen?(m==='thor-dual'?'Combat : scène et HUD sur le principal 768 × 432 ; tableau de décision sur le compagnon 496 × 432. Le focus appartient au compagnon. Attaquer domine la racine ; les capacités utilisent quatre choix typés.':isLandscape(m)?isPad(m)?'Combat paysage 844 × 390 : scène plein cadre et commandes angulaires au bas droit. Les sous-menus denses prennent un panneau dédié, avec le contexte du combattant à gauche.':'Combat paysage tactile 844 × 390 : barre de commandes basse, puis capacités en grille 2 × 2, rail Retour / Infos de 60 px et panneau de 140 px. Les cibles tactiles restent de 48 px au minimum.':'Combat portrait 390 × 844 : duel en haut, tableau de décision en bas. La manette rend davantage de hauteur à la scène. Les soins et changements montrent les six membres dans un panneau compact.') : m==='thor-dual'?'Principal : 768 × 432 logiques. Compagnon : 496 × 432 logiques. Cadre inférieur affiché à 88 % pour approcher l’écart de dimensions physiques. Les deux surfaces restent simultanément visibles.':isLandscape(m)?`844 × 390 logiques. Insets fictifs 12 / 44 / 20 / 44. Deux colonnes pour les listes avec détail. Les groupes dépassant l’espace disponible utilisent des pages explicites ; en-tête et actions restent ancrés.`:`390 × 844 logiques. Insets fictifs 32 / 0 / 24 / 0. Actions produit ≥ 48 px, clavier logiciel selon son propre gabarit. ${isPad(m)?'Le dock tactile est supprimé et son espace rendu au contenu.':'Joystick 112 px et action 68 px, éloignés des informations essentielles.'}`;
    const interaction=isPad(m)?`Profil ${m==='thor-dual'?'Nintendo standard : B = validation (sud), A = retour (est)':'Xbox d’exemple : A = validation, B = retour'}. Une seule cible de focus. Dans l’atlas : flèches pour naviguer, Entrée pour valider, Échap pour revenir ; Page précédente / suivante ou touches PageUp / PageDown pour changer de page. Les boutons restent cliquables.`:'Tactile : action directe, pas de premier appui uniquement pour mettre au point. Retour remonte d’un niveau. Le clavier logiciel est figuré dans les saisies. Les insets réels du téléphone restent à vérifier.';
    const dualNote=m==='thor-dual'&&proposedDual(s)?'Extension de conception : déplacer ce service sur le compagnon demande une évolution du routage actuel, qui réserve encore ces services à l’écran principal.':m==='thor-dual'?'Répartition cible. Les menus et commandes de combat existent déjà sur le compagnon ; cette planche ne certifie pas le routage actuel de tous les sous-écrans.':'';
    const preview=document.querySelector('#stage [data-display="secondary"]')||document.querySelector('#stage .screen');
    const measured=preview?(combatScreen?['.combat-panel-title','.battle-entries','.combat-footer']:['.screen-header','.screen-body','.screen-footer']).map((sel,i)=>{const el=preview.querySelector(sel);return el?['En-tête','Corps visible','Pied'][i]+' : '+el.offsetHeight+' px':'';}).filter(Boolean).join(' · '):'';
    document.getElementById('inspector').innerHTML=`<article><h2>Composition et mesures</h2><p>${esc(layout)}</p>${measured?`<p><strong>Gabarit rendu :</strong> ${esc(measured)}</p>`:''}<p>${combatScreen?'Combat : noms en premier, PV et niveaux sur plaques claires, PP et type lisibles ; les informations d’efficacité sont des données de démonstration.':'Texte courant 16 px · titre 23/24 px · rythme 8 / 12 / 16 / 24.'} Police DM Sans embarquée. Les dimensions concernent la maquette, pas une certification appareil.</p>${dualNote?`<p><strong>${esc(dualNote)}</strong></p>`:''}</article><article><h2>État et parcours</h2><p><strong>${esc(stateLabel(v))}</strong> · ${esc(s.notes||'Données d’exemple cohérentes avec les actions de cette famille.')}</p>${C.stateNotes?.[v]?`<p>${esc(C.stateNotes[v])}</p>`:''}<ul>${s.actions.map(a=>`<li>${esc(a)}</li>`).join('')}</ul><p>${esc(interaction)}</p><div>${related(s).map(id=>`<button class="transition-button" data-screen="${id}">${esc(screenMap.get(id)?.label||id)}</button>`).join('')}</div></article><article><h2>Contenu et traçabilité</h2><p>${s.fields.map(esc).join(' · ')}</p><span class="annotation-label">ANCRAGE CODE · CONSULTÉ EN LECTURE SEULE</span>${s.sources.map(x=>`<code>${esc(x.path)}:${x.line}</code><br>`).join('')}<p>${s.support!=='existing'?'Composition proposée ; surface autonome actuelle non trouvée.':'Surface ou contrat existant ; présentation redessinée.'}</p>${combatScreen?'<p>Inspiration : <a href="https://csassets.nintendo.com/noaext/image/private/t_KA_PDF/DS_pokemon_black_2?_a=DATAg1AAZAA0" target="_blank" rel="noreferrer">manuel Nintendo Noir 2, p.10</a> · <a href="https://www.pokemon.co.jp/ex/sword_shield/howtoplay/190605_02.html" target="_blank" rel="noreferrer">captures officielles Épée/Bouclier</a>. La composition Avelune est une adaptation, pas une reproduction exacte.</p>':''}<button class="transition-button" data-overview>Règles communes et périmètre</button></article>`;
  }
  function related(s) {
    const chains=[['startup.prepare','startup.splash','startup.intro','startup.title-prompt','title.menu'],['title.menu','newgame.overwrite','newgame.name','newgame.avatar','newgame.starter','world.explore'],['world.explore','pause.root','party.list','party.detail','pokemon.summary'],['bag.list','bag.detail','bag.target-party','bag.confirm','bag.list'],['battle.root','battle.fight','battle.turn','battle.continue','postbattle.victory'],['battle.fight','battle.target','battle.turn'],['gift.received','gift.pokedex','gift.nickname-confirm','gift.nickname','gift.destination'],['trade.select-first','trade.choose-partner','trade.select-partner','trade.review','trade.result'],['save.confirm','save.progress','save.success','world.explore'],['shop.buy','shop.quantity','shop.buy']];
    const chain=chains.find(x=>x.includes(s.id));return chain?chain.filter((x,i)=>chain.indexOf(x)===i&&x!==s.id).slice(0,5):C.screens.filter(x=>x.group===s.group&&x.id!==s.id).slice(0,4).map(x=>x.id);
  }
  function showOverview() {
    const div=document.createElement('div');div.className='atlas-intro';
    div.innerHTML=`<span class="eyebrow">CONTRAT DE CONCEPTION · 24 OCTOBRE 2026</span><h2>Une interface de jeu.<br>Cinq dispositions conçues séparément.</h2><p>Ce dossier couvre ${C.screens.length} compositions, étapes ou messages et ${C.screens.reduce((n,s)=>n+s.states.length,0)} états recensés. Les variantes sont sélectionnables ; certaines partagent volontairement leur géométrie. Les écrans se consultent dans les cinq dispositions, sans présenter une simple mise à l’échelle comme une adaptation.</p><div class="atlas-contract">${Object.entries(modes).map(([id,d])=>`<article><h3>${esc(d.label)}</h3><p>${id==='thor-dual'?'Haut 16:9, bas 31:27, deux surfaces à chaque étape. Choix sur le compagnon, contexte et résultat sur le principal.':d.orientation==='portrait'?d.input==='touch'?'Monde en haut, commandes au pouce ; menus denses en plein écran.':'Aucun joystick virtuel. Les listes et le monde récupèrent toute la hauteur.':d.input==='touch'?'Commandes en dehors de la zone centrale ; menus et détails côte à côte lorsque possible.':'Scène dégagée, focus visible et légendes du périphérique.'}</p><button class="transition-button" data-mode="${id}">Voir la disposition</button></article>`).join('')}<article><h3>Contenu générique</h3><p>Les noms, Pokémon, objets, chiffres et lieux servent de données de démonstration. Les capacités visibles doivent suivre le jeu créé. Les scènes nom/avatar/starter sont des exemples facultatifs, pas un wizard imposé.</p></article><article><h3>Accessibilité</h3><p>Cibles de 48 px minimum, contraste sémantique, commandes réassignables et mouvement réduit. Les libellés se replient, les longs contenus se répartissent en pages sans défilement interne. Les essais appareil, lecteur d’écran et manette réelle restent à réaliser.</p><button class="transition-button" data-large-text>Afficher le texte à 150 %</button><button class="transition-button" data-high-contrast>Contraste renforcé</button></article><article><h3>Périmètre exact</h3><p>133 IDs ne signifient pas 133 fonctionnalités certifiées. 23 entrées correspondent aux contenus successifs de progression. Les services en bas du Thor, le sélecteur de sauvegarde et le déplacement PC inter-boîtes sont signalés comme propositions. Le host développeur est séparé du jeu distribué.</p></article><article><h3>Usage de l’atlas</h3><p>Choisir un écran dans la colonne gauche, puis un état et un format. « Comparer les 5 » juxtapose les compositions. « Tous les écrans » parcourt la disposition courante. Les actions relient les étapes de démonstration, sans exécuter la mécanique du jeu.</p></article><article><h3>Sources matérielles</h3><p><a href="https://www.ayntec.com/products/ayn-thor" target="_blank" rel="noreferrer">AYN Thor officiel</a> : deux écrans tactiles de 6″ et 3,92″. <a href="https://ae-pic-a1.aliexpress-media.com/kf/S21d979b6c8d840ddaebfeb976094e0cfP.pdf" target="_blank" rel="noreferrer">Manuel fabricant</a> : 1920 × 1080 et 1240 × 1080. Les pixels logiques du dossier sont des choix de conception, pas les densités Android.</p></article><article><h3>Ressources visuelles</h3><p>Décors originaux générés pour cette étude. Sprites de démonstration issus du projet local de référence ; aucune publication ni intégration dans la runtime. DM Sans et Lucide embarqués, licences présentes dans assets.</p></article></div><p><button class="atlas-button" data-screen="pause.root">Ouvrir le menu pause</button> <button class="atlas-button" data-screen="battle.root">Ouvrir le combat</button></p>`;
    const stage=document.getElementById('stage');stage.className='';stage.replaceChildren(div);document.getElementById('screen-title').textContent='Règles et couverture';document.getElementById('inspector').innerHTML='';
  }
  function render() {
    const s=screenMap.get(selected);if(!s)return;
    if(/^options\.(general|display|audio|controls|language|accessibility)$/.test(s.id))demo.optionsCategory=s.id.split('.')[1];
    if(s.id==='shop.buy'||s.id==='shop.sell')demo.shopMode=s.id.split('.')[1];
    if(!s.states.includes(variant))variant=s.states[0];
    document.getElementById('screen-title').textContent=s.label;
    document.getElementById('screen-id').textContent=String(C.screens.indexOf(s)+1).padStart(3,'0')+' · '+s.id;
    document.getElementById('screen-kind').textContent=s.support==='existing'?'Surface existante · design cible':'Proposition supplémentaire';
    const select=document.getElementById('state-select');select.innerHTML=s.states.map(v=>`<option value="${esc(v)}"${variant===v?' selected':''}>${esc(stateLabel(v))}</option>`).join('');
    const stage=document.getElementById('stage');window.AvelunePages?.capture(stage);stage.innerHTML='';stage.className=view==='compare'?'atlas-compare':view==='gallery'?'atlas-gallery':'';
    if(view==='compare') for(const m of Object.keys(modes))stage.appendChild(buildFrame(s,m,variant,m==='thor-dual'?.5:isLandscape(m)?.65:.65));
    else if(view==='gallery'||view==='coverage') {
      for(const item of C.screens.filter(x=>!query||[x.id,x.label,x.group].join(' ').toLowerCase().includes(query))) {
        for(const itemState of view==='coverage'?item.states:[item.states[0]]) {
        const board=buildFrame(item,mode,itemState,view==='coverage'?.25:mode==='thor-dual'?.34:isLandscape(mode)?.34:.6);
        board.dataset.openScreen=item.id;
        const caption=document.createElement('div');caption.className='gallery-caption';caption.innerHTML=`<strong>${String(C.screens.indexOf(item)+1).padStart(3,'0')} · ${esc(item.label)}</strong><br>${esc(view==='coverage'?stateLabel(itemState):item.states.length+' états · '+item.fields.slice(0,2).join(' / '))}`;board.appendChild(caption);stage.appendChild(board);
        }
      }
    } else {
      const available=Math.max(330,stage.clientWidth-64);
      const frameWidth=mode==='thor-dual'?768:modes[mode].width;
      const scale=view==='plate'?1:zoom==='fit'?Math.min(1,available/frameWidth):zoom;
      if(frameWidth*scale>available)stage.classList.add('wide-preview');
      stage.appendChild(buildFrame(s,mode,variant,scale));
    }
    document.body.classList.toggle('plate-view',view==='plate');
    if(view==='coverage')stage.className='atlas-gallery';
    document.getElementById('mode-tabs').innerHTML=Object.entries(modes).map(([id,d])=>`<button role="tab" aria-selected="${mode===id}" data-mode="${id}">${esc(d.label)}</button>`).join('');
    document.getElementById('compare').classList.toggle('active',view==='compare');document.getElementById('gallery').classList.toggle('active',view==='gallery');
    document.getElementById('atlas-total').textContent=C.screens.length+' compositions · 5 dispositions · '+C.screens.reduce((n,s)=>n+s.states.length,0)+' états recensés';
    navigation();annotations(s,mode,variant);
    if(window.lucide)window.lucide.createIcons();
    window.AvelunePages?.layout(stage);
    history.replaceState(null,'','#'+new URLSearchParams({screen:selected,mode,state:variant,view}).toString());
  }
  function navigate(id,state='') {
    const [base,tab]=id.split('#');
    if(!screenMap.has(base)){toast('Cette action dépend du contenu configuré dans le jeu.');return;}
    if(!['postbattle.moveLearned','postbattle.moveReplaced','postbattle.evolutionAccepted'].includes(base))demo.bagResult=null;
    if(base==='shop.buy'||base==='shop.sell')demo.shopMode=base.split('.')[1];
    if(/^options\.(general|display|audio|controls|language|accessibility)$/.test(base))demo.optionsCategory=base.split('.')[1];
    if(base==='options.choice'&&!state)state={display:'menu-effects',language:'language',controls:'touch-run-mode'}[demo.optionsCategory]||'text-speed';
    if(base==='options.reset'&&!state)state=demo.optionsCategory;
    if(base==='pokemon.summary'&&tab)demo.summaryTab=tab;
    if(base==='dex.list'&&tab)demo.dexFilter=tab;
    if(base==='bag.list'&&tab){demo.bagPocket={balls:'Balls',items:'Objets',key:'Objets rares',fav:'Favoris'}[tab]||'Soins';demo.item=Math.max(0,items.findIndex(x=>x.pocket===demo.bagPocket));}
    if(base==='battle.bag'&&['balls','medicine'].includes(state))combat.pocket=state;
    selected=base;variant=state||'';view='single';render();
    document.getElementById('stage').scrollTop=0;
  }
  function toast(text) {const el=document.getElementById('atlas-toast');el.textContent=text;el.classList.add('visible');clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.classList.remove('visible'),2600);}
  function updateName(input) {
    const container=input.closest('.screen');const value=input.value;const counter=container.querySelector('[data-name-count]');if(counter)counter.textContent=value.length+' / 12';
    container.querySelectorAll('.screen-footer [data-screen]').forEach(el=>{if(/Valider|Validation/.test(el.textContent)){el.disabled=!value.trim()||value.length>12;el.setAttribute('aria-disabled',String(el.disabled));}});
  }
  function updateQuantity(container) {
    const tx=container.querySelector('[data-transaction]');if(!tx)return;
    const unit=Number(tx.dataset.unitPrice),balance=Number(tx.dataset.balance),selling=tx.dataset.selling==='true';const cost=demo.quantity*unit;
    const invalid=(!selling&&cost>balance)||demo.quantity>Number(tx.dataset.stock)||demo.quantity>Number(tx.dataset.capacity);
    const total=container.querySelector('[data-transaction-total]'),after=container.querySelector('[data-transaction-after]');if(total)total.textContent=cost.toLocaleString('fr-FR')+' ₽';if(after)after.textContent=invalid?'—':(selling?balance+cost:balance-cost).toLocaleString('fr-FR')+' ₽';
    const purchase=container.querySelector('[data-purchase]');if(purchase){purchase.textContent=(selling?'Vendre':'Acheter')+' · '+cost.toLocaleString('fr-FR')+' ₽';purchase.disabled=invalid;purchase.setAttribute('aria-disabled',String(invalid));}
  }
  function updateCombatFocus(button,container) {
    if(!button||!container.querySelector('.combat-ui'))return;
    if(button.dataset.combatMove!==undefined){combat.move=Number(button.dataset.combatMove);const meta=combatMoveMeta(selectedAttack());const detail=container.querySelector('.combat-move-detail');if(detail)detail.innerHTML=`<span>${esc(meta[2])}</span><div><b>Puiss. ${meta[0]}</b><b>Préc. ${meta[1]}</b></div>`;}
    if(button.dataset.combatTarget!==undefined){combat.target=Number(button.dataset.combatTarget);const primary=document.querySelector('#stage [data-display="primary"] .combat-ui');if(primary){primary.innerHTML=battleScene(true,'',activeFighter(),{target:combat.target,multiple:true});window.lucide?.createIcons();}}
  }
  document.addEventListener('input',e=>{
    if(e.target.matches('[data-name-input]'))updateName(e.target);
    if(e.target.matches('input[type=range]')){const display=e.target.closest('.setting')?.querySelector('[data-range-value]');if(display)display.textContent=e.target.value+' %';}
    if(e.target.matches('[data-dex-search]')){demo.dexQuery=e.target.value;const rows=[...document.querySelectorAll('#stage [data-dex-row]')];rows.forEach(el=>el.hidden=!el.dataset.dexRow.toLowerCase().includes(demo.dexQuery.toLowerCase()));window.AvelunePages?.layout(document.getElementById('stage'));}
  });
  document.addEventListener('click',e=>{
    const open=e.target.closest('[data-open-screen]');
    if(open&&view==='gallery'){navigate(open.dataset.openScreen);return;}
    const infoOpen=e.target.closest('[data-combat-info-open]');if(infoOpen){const screen=infoOpen.closest('.screen'),panel=screen.querySelector('.combat-info-panel');panel.hidden=false;screen.querySelectorAll('.focused').forEach(x=>x.classList.remove('focused'));panel.querySelector('button.selected,button')?.classList.add('focused');return;}
    const infoClose=e.target.closest('[data-combat-info-close]');if(infoClose){const screen=infoClose.closest('.screen');infoClose.closest('.combat-info-panel').hidden=true;screen.querySelectorAll('.focused').forEach(x=>x.classList.remove('focused'));screen.querySelector('[data-combat-info-open]')?.classList.add('focused');return;}
    const infoTab=e.target.closest('[data-move-info]');if(infoTab){const panel=infoTab.closest('.combat-info-panel');panel.querySelectorAll('[data-move-info]').forEach(x=>x.classList.toggle('selected',x===infoTab));panel.querySelectorAll('[data-move-info-copy]').forEach(x=>x.hidden=x.dataset.moveInfoCopy!==infoTab.dataset.moveInfo);return;}
    const target=e.target.closest('[data-screen]');
    if(target&&!target.disabled){if(target.dataset.combatMove!==undefined||target.dataset.combatStruggle){const targets=[...new Set((target.dataset.combatTargets||'').split(',').filter(x=>x.trim()!=='').map(Number).filter(i=>Number.isInteger(i)&&i>=0&&i<pokemon.length))];if(!targets.length){toast('Aucune cible valide pour cette capacité.');return;}combat.targetChoices=targets;combat.target=targets[0];if(target.dataset.combatMove!==undefined)combat.move=Number(target.dataset.combatMove);combat.action=target.dataset.combatStruggle?'struggle':'move';navigate(targets.length>1?'battle.target':'battle.turn',targets.length>1?'multiple-valid-targets':'presentingTurn');return;}if(target.dataset.combatActive!==undefined){combat.active=Number(target.dataset.combatActive);combat.move=0;combat.action='switch';combat.targetChoices=[5];}if(target.dataset.combatItem!==undefined)combat.item=Number(target.dataset.combatItem);if(target.dataset.combatMember!==undefined)combat.member=Number(target.dataset.combatMember);if(target.dataset.combatPp!==undefined){combat.pp=Number(target.dataset.combatPp);combat.action='pp';}if(target.dataset.combatTarget!==undefined){combat.targetChoices=(target.dataset.combatTargets||'').split(',').map(Number);combat.target=Number(target.dataset.combatTarget);if(combat.action!=='struggle')combat.action='move';}if(target.dataset.combatAction)combat.action=target.dataset.combatAction;if(target.dataset.combatForget!==undefined)combat.forgot=Number(target.dataset.combatForget);if(target.dataset.pokemon!==undefined)demo.pokemon=Number(target.dataset.pokemon);if(target.dataset.item!==undefined)demo.item=Number(target.dataset.item);if(target.dataset.move!==undefined)demo.move=Number(target.dataset.move);if(target.dataset.bagResult){const p=pokemon[demo.pokemon];demo.bagResult={kind:target.dataset.bagResult,pokemon:demo.pokemon,name:p.name,move:(movesFor(p)[demo.move]||movesFor(p)[0]).name};}navigate(target.dataset.screen,target.dataset.state||'');return;}
    const modeTarget=e.target.closest('button[data-mode]');
    if(modeTarget){mode=modeTarget.dataset.mode;render();return;}
    const qty=e.target.closest('[data-quantity]');if(qty){const el=qty.parentElement.querySelector('[data-quantity-value]');demo.quantity=Math.max(1,Math.min(10,Number(el.textContent)+Number(qty.dataset.quantity)));el.textContent=demo.quantity;updateQuantity(qty.closest('.screen'));return;}
    const key=e.target.closest('[data-key]');if(key){const input=key.closest('.screen').querySelector('.input-field');if(input){input.value=key.dataset.key==='backspace'?input.value.slice(0,-1):(input.value+key.dataset.key).slice(0,12);updateName(input);}return;}
    const sheet=e.target.closest('[data-summary-tab]');if(sheet){demo.summaryTab=sheet.dataset.summaryTab;render();return;}
    const toggle=e.target.closest('[data-toggle-setting]');if(toggle){const value=toggle.getAttribute('aria-checked')!=='true';toggle.setAttribute('aria-checked',value);toggle.classList.toggle('off',!value);return;}
    const check=e.target.closest('[data-toggle-check]');if(check){const list=check.closest('.screen');if(!check.classList.contains('selected')&&list.querySelectorAll('[data-toggle-check].selected').length>=2){toast('Deux choix au maximum.');return;}check.classList.toggle('selected');check.setAttribute('aria-pressed',String(check.classList.contains('selected')));const mark=check.querySelector('svg');if(mark){mark.outerHTML=icon(check.classList.contains('selected')?'square-check':'square');window.lucide?.createIcons();}const count=list.querySelectorAll('[data-toggle-check].selected').length;list.querySelectorAll('.screen-footer [data-screen="interaction.message"]').forEach(x=>{x.disabled=count<1;x.setAttribute('aria-disabled',String(x.disabled));});return;}
    if(e.target.closest('[data-overview]')){showOverview();return;}
    if(e.target.closest('[data-large-text]')){navigate('dialogue.choices','long-labels');document.querySelectorAll('#stage .screen').forEach(x=>x.classList.add('text-large'));window.AvelunePages?.layout(document.getElementById('stage'));return;}
    if(e.target.closest('[data-high-contrast]')){navigate('party.list');document.querySelectorAll('#stage .screen').forEach(x=>x.classList.add('high-contrast'));return;}
    const notify=e.target.closest('[data-toast]');if(notify)toast(notify.dataset.toast);
  });
  document.addEventListener('keydown',e=>{
    if(e.target.matches('input,textarea,select')||!isPad(mode)||view!=='single')return;
    const screen=document.querySelector('#stage [data-display="secondary"]')||document.querySelector('#stage .screen');if(!screen)return;const container=screen.querySelector('.combat-info-panel:not([hidden])')||screen;
    const buttons=[...container.querySelectorAll('button:not([disabled])')].filter(x=>x.getClientRects().length&&!x.closest('[hidden]'));
    const index=Math.max(0,buttons.findIndex(x=>x.classList.contains('focused')));
    if(['ArrowDown','ArrowRight','ArrowUp','ArrowLeft'].includes(e.key)) {
      e.preventDefault();const next=(index+(e.key==='ArrowDown'||e.key==='ArrowRight'?1:-1)+buttons.length)%buttons.length;
      buttons.forEach(x=>{x.classList.remove('focused');if(container.querySelector('.combat-ui'))x.classList.remove('selected');});buttons[next]?.classList.add('focused');updateCombatFocus(buttons[next],container);
    } else if(e.key==='Enter') {e.preventDefault();buttons[index]?.click();}
    else if(e.key==='Escape') {
      e.preventDefault();if(container.matches?.('.combat-info-panel')){container.querySelector('[data-combat-info-close]').click();return;}if(container.dataset.cannotCancel==='true'||busyState(variant)||variant==='completed')return;
      const back=container.querySelector('.screen-header [data-screen]:not([disabled])')||container.querySelector('.return-link:not([disabled]),.combat-back:not([disabled])')||buttons.find(x=>/^(Annuler|Retour|Rester|Conserver|Garder|Non)/.test(x.textContent.trim()));
      if(back)back.click();else if(selected==='pause.root')navigate('world.explore');
    }
  });
  document.getElementById('search').addEventListener('input',e=>{query=e.target.value.trim().toLowerCase();navigation();if(view==='gallery')render();});
  document.getElementById('state-select').addEventListener('change',e=>{variant=e.target.value;render();});
  document.getElementById('zoom').addEventListener('change',e=>{zoom=e.target.value==='fit'?'fit':Number(e.target.value);render();});
  document.getElementById('compare').addEventListener('click',()=>{view=view==='compare'?'single':'compare';render();});
  document.getElementById('gallery').addEventListener('click',()=>{view=view==='gallery'?'single':'gallery';render();});
  document.getElementById('print').addEventListener('click',()=>window.print());
  document.querySelector('.atlas-brand').addEventListener('click',e=>{e.preventDefault();showOverview();});
  window.addEventListener('hashchange',()=>{const p=new URLSearchParams(location.hash.slice(1));if(screenMap.has(p.get('screen')))selected=p.get('screen');if(modes[p.get('mode')])mode=p.get('mode');variant=p.get('state')||'';view=p.get('view')||'single';render();});
  window.ATLAS_PREVIEW={navigate,render,buildFrame,content,screenMap,modes,combat,get state(){return{selected,mode,variant,view};}};
  render();
})();
