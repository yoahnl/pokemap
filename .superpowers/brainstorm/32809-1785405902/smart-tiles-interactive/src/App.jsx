import { useEffect, useMemo, useState } from 'react';
import {
  ArrowLeft,
  ArrowRight,
  CaretDown,
  Check,
  CheckCircle,
  CirclesThreePlus,
  Crosshair,
  FileImage,
  FloppyDisk,
  GridFour,
  Info,
  MapTrifold,
  Path,
  Plant,
  Plus,
  PuzzlePiece,
  SquaresFour,
  TreeEvergreen,
  UploadSimple,
} from '@phosphor-icons/react';

const steps = ['Usage', 'Guide', 'Placement', 'Essai', 'Publier'];

const gridPositions = (count, columns) => Array.from({ length: count }, (_, index) => ({ column: index % columns, row: Math.floor(index / columns), label: index + 1 }));
const erwGuidePositions = [
  [1, 0, 9], [2, 0, 8], [3, 0, 7],
  [0, 1, 11], [2, 1, 10], [4, 1, 6], [5, 1, 5],
  [0, 2, 12], [5, 2, 4],
  [0, 3, 13], [1, 3, 14], [4, 3, 2], [5, 3, 3],
  [1, 4, 15], [2, 4, 16], [3, 4, 1],
].map(([column, row, label]) => ({ column, row, label }));
const blobPositions = gridPositions(49, 7).filter((_, index) => index !== 0 && index !== 48).map((position, index) => ({ ...position, label: index + 1 }));

const usages = [
  { id: 'path', title: 'Path', shortTitle: 'Path', tag: 'TRACER', description: 'Chemins, routes, rails ou rivières : lignes, virages et jonctions.', Icon: Path },
  { id: 'terrain', title: 'Terrain', shortTitle: 'Terrain', tag: 'REMPLIR', description: 'Herbe, terre, eau ou pavés : une surface et ses contours.', Icon: MapTrifold },
  { id: 'environment', title: 'Environment Studio', shortTitle: 'Environment', tag: 'COMPOSER', description: 'Forêts, sous-bois et masses naturelles composées de plusieurs couches.', Icon: TreeEvergreen },
  { id: 'border', title: 'Border Studio', shortTitle: 'Border', tag: 'DÉLIMITER', description: 'Falaises, murs, rives et reliefs avec parois et collisions.', Icon: PuzzlePiece },
];

const guideCatalog = {
  path: [
    { id: 'erw16', title: 'Guide ERW 16', badge: 'RECOMMANDÉ', description: 'La disposition exacte fournie avec le bundle Grass Land.', columns: 6, rows: 5, positions: erwGuidePositions },
    { id: 'edge16', title: 'Guide Edge 16', badge: 'CLASSIQUE', description: 'Seize raccords par les côtés pour les réseaux et intersections.', columns: 4, rows: 4, positions: gridPositions(16, 4) },
    { id: 'blob47', title: 'Guide Blob 47', badge: 'ORGANIQUE', description: 'Davantage de coins et de formes pour les chemins irréguliers.', columns: 7, rows: 7, positions: blobPositions },
    { id: 'free', title: 'Guide personnalisé', badge: 'LIBRE', description: 'Tu attribues toi-même le rôle des cellules qui ne suivent aucun guide.', columns: 5, rows: 4, positions: gridPositions(12, 5) },
  ],
  terrain: [
    { id: 'blob47', title: 'Guide Blob 47', badge: 'RECOMMANDÉ', description: 'Formes pleines, trous et coins rentrants pour une surface organique.', columns: 7, rows: 7, positions: blobPositions },
    { id: 'corner16', title: 'Guide Corner 16', badge: 'CLASSIQUE', description: 'Les coins de chaque tuile décrivent la frontière entre deux terrains.', columns: 4, rows: 4, positions: gridPositions(16, 4) },
    { id: 'simple9', title: 'Texture + variantes', badge: 'SIMPLE', description: 'Une texture répétable et quelques variantes, sans contour automatique.', columns: 3, rows: 3, positions: gridPositions(9, 3) },
    { id: 'free', title: 'Guide personnalisé', badge: 'LIBRE', description: 'Pour une disposition d’atlas qui ne correspond à aucun guide connu.', columns: 5, rows: 4, positions: gridPositions(12, 5) },
  ],
  environment: [
    { id: 'forest47', title: 'Surface forestière 47', badge: 'RECOMMANDÉ', description: 'Une surface raccordée, puis des couches de troncs et de canopée.', columns: 7, rows: 7, positions: blobPositions },
    { id: 'erw16', title: 'Guide ERW 16', badge: 'CLASSIQUE', description: 'Le guide utilisé par plusieurs bordures végétales du bundle.', columns: 6, rows: 5, positions: erwGuidePositions },
    { id: 'layers', title: 'Composition par couches', badge: 'MULTICOUCHE', description: 'Plusieurs blocs alignés partagent la même empreinte logique.', columns: 6, rows: 6, positions: gridPositions(36, 6) },
    { id: 'free', title: 'Guide personnalisé', badge: 'LIBRE', description: 'Configuration visuelle d’une famille environnementale atypique.', columns: 5, rows: 4, positions: gridPositions(12, 5) },
  ],
  border: [
    { id: 'erw16', title: 'Guide ERW 16', badge: 'RECOMMANDÉ', description: 'Le guide fourni pour les falaises et bordures du bundle.', columns: 6, rows: 5, positions: erwGuidePositions },
    { id: 'edge16', title: 'Guide Edge 16', badge: 'CLASSIQUE', description: 'Segments droits, angles et extrémités pour murs et rives.', columns: 4, rows: 4, positions: gridPositions(16, 4) },
    { id: 'cliffLayers', title: 'Falaise multicouche', badge: 'RELIEF', description: 'Dessus, paroi et base sont configurés comme trois couches liées.', columns: 6, rows: 6, positions: gridPositions(36, 6) },
    { id: 'free', title: 'Guide personnalisé', badge: 'LIBRE', description: 'Pour les reliefs dont les morceaux sont organisés librement.', columns: 5, rows: 4, positions: gridPositions(12, 5) },
  ],
};

const libraryItems = [
  { title: 'Chemin compacté clair', meta: 'Chemin · Historique', color: 'amber' },
  { title: 'Herbe courte', meta: 'Sol · Historique', color: 'green' },
  { title: 'Sol forestier', meta: 'Sol · Historique', color: 'green' },
];

const shapeTests = ['Ligne', 'Virage', 'T', 'Croix', 'Boucle', 'Cul-de-sac', 'Peinture libre'];
const usageTests = {
  path: shapeTests,
  terrain: ['Grand aplat', 'Îlot', 'Coin rentrant', 'Trou', 'Deux zones', 'Peinture libre'],
  environment: ['Lisière', 'Angle', 'Clairière', 'Trouée', 'Massif', 'Peinture libre'],
  border: ['Ligne', 'Angle', 'Angle rentrant', 'Extrémité', 'Double niveau', 'Peinture libre'],
};

function Stepper({ current, onStep }) {
  return (
    <nav className="stepper" aria-label="Progression de création">
      {steps.map((label, index) => {
        const number = index + 1;
        const isDone = number < current;
        const isCurrent = number === current;
        const canOpen = number <= current;
        return (
          <div className="step-group" key={label}>
            <button
              className={`step ${isCurrent ? 'is-current' : ''} ${isDone ? 'is-done' : ''}`}
              disabled={!canOpen}
              onClick={() => canOpen && onStep(number)}
            >
              <span className="step-number">{isDone ? <Check weight="bold" /> : number}</span>
              <span>{number}. {label}</span>
            </button>
            {number < steps.length && <span className={`step-line ${isDone ? 'is-done' : ''}`} />}
          </div>
        );
      })}
    </nav>
  );
}

function Topbar({ status }) {
  return (
    <header className="topbar">
      <div className="brand-mark"><SquaresFour weight="fill" /></div>
      <strong className="brand-name">PokeMap</strong>
      <span className="breadcrumb">Le train de 17h42 / Smart Tiles Studio / Nouveau</span>
      <div className="save-status"><span />{status}</div>
    </header>
  );
}

function Sidebar({ step, published, usage }) {
  return (
    <aside className="sidebar">
      {step === 1 ? (
        <>
          <p className="sidebar-kicker">CRÉATION</p>
          <div className="studio-card is-active">
            <GridFour weight="fill" />
            <div><strong>Smart Tiles Studio</strong><small>Sols, chemins et forêts</small></div>
          </div>
          <p className="sidebar-kicker library-heading">BIBLIOTHÈQUE</p>
          <div className="library-list">
            {libraryItems.map((item) => (
              <div className="library-item" key={item.title}>
                <span className={`library-thumb ${item.color}`} />
                <div><strong>{item.title}</strong><small>{item.meta}</small></div>
              </div>
            ))}
          </div>
          <button className="sidebar-action"><Plus />Nouveau Smart Tile</button>
        </>
      ) : (
        <>
          <button className="back-library"><ArrowLeft />Retour à la bibliothèque</button>
          <section className="current-preset">
            <span>SMART TILE {published ? 'PUBLIÉ' : 'EN COURS'}</span>
            <strong>{usage.id === 'path' ? 'Chemin de terre ERW' : `Nouveau · ${usage.title}`}</strong>
            <em>Comportement : {usage.shortTitle}</em>
            <small>Étape {step} sur 5</small>
          </section>
          {step === 2 && (
            <aside className="sidebar-tip">
              <GridFour weight="fill" />
              <div><strong>Un guide, pas un format</strong><p>Le guide décrit seulement la position attendue des cellules dans l’image.</p></div>
            </aside>
          )}
          {step === 3 && (
            <aside className="sidebar-tip">
              <Crosshair weight="fill" />
              <div><strong>Placement déterministe</strong><p>Indique la première cellule : toutes les autres sont calculées depuis le guide.</p></div>
            </aside>
          )}
          {step === 4 && (
            <section className="tested-shapes">
              <span>CAS TESTÉS</span>
              {usageTests[usage.id].slice(0, 6).map((shape) => (
                <small key={shape}><Check weight="bold" />{shape}</small>
              ))}
            </section>
          )}
          {step === 5 && (
            <aside className="sidebar-tip">
              <CheckCircle weight="fill" />
              <div><strong>Prêt à peindre</strong><p>Le Smart Tile est maintenant disponible pour toutes les maps du projet.</p></div>
            </aside>
          )}
        </>
      )}
    </aside>
  );
}

function PrimaryButton({ children, onClick, disabled, icon = true }) {
  return (
    <button className="primary-button" onClick={onClick} disabled={disabled}>
      {children}{icon && <ArrowRight weight="bold" />}
    </button>
  );
}

function GuideDiagram({ guide, compact = false }) {
  return (
    <span
      className={`guide-diagram ${compact ? 'is-compact' : ''}`}
      style={{ '--guide-columns': guide.columns, '--guide-rows': guide.rows }}
      aria-hidden="true"
    >
      {guide.positions.map((position) => (
        <i
          key={`${position.column}-${position.row}-${position.label}`}
          style={{ gridColumn: position.column + 1, gridRow: position.row + 1 }}
        >{position.label}</i>
      ))}
    </span>
  );
}

function UsageStep({ selected, onSelect, next }) {
  return (
    <div className="step-content usage-step">
      <header className="page-heading">
        <div><h1>Créer un Smart Tile</h1><p>Choisis un usage, aligne un guide et vérifie immédiatement le résultat.</p></div>
        <span className="soft-badge">Nouveau parcours</span>
      </header>
      <h2>Comment veux-tu utiliser cette image ?</h2>
      <p className="lead">Ce choix décrit l’outil de peinture dans PokeMap. Il ne change pas encore le format technique de l’image.</p>
      <div className="usage-grid">
        {usages.map(({ id, title, tag, description, Icon }) => (
          <button
            key={id}
            className={`usage-card ${selected === id ? 'is-selected' : ''}`}
            onClick={() => onSelect(id)}
          >
            <span className="usage-card-heading"><span className="usage-icon"><Icon weight="fill" /></span><em>{tag}</em></span>
            <span className="usage-purpose" aria-hidden="true"><Icon weight="duotone" /></span>
            <strong>{title}</strong>
            <p>{description}</p>
            {selected === id && <span className="selection-label"><Check weight="bold" />Sélectionné</span>}
          </button>
        ))}
      </div>
      <div className="reassurance">
        <CheckCircle weight="fill" />
        <div><strong>Un même guide peut servir à plusieurs studios.</strong><p>Path, Terrain et Border décrivent l’usage. Les règles Wang seront produites ensuite à partir du guide sélectionné.</p></div>
      </div>
      <footer className="page-actions">
        <small>Tu pourras revenir à cette étape sans perdre ton travail.</small>
        <PrimaryButton onClick={next}>Continuer avec {usages.find((item) => item.id === selected)?.title}</PrimaryButton>
      </footer>
    </div>
  );
}

function GuideStep({ usage, selected, setSelected, next, back }) {
  const guides = guideCatalog[usage.id];
  const selectedGuide = guides.find((guide) => guide.id === selected) ?? guides[0];
  return (
    <div className="step-content guide-step">
      <h1>Quel guide ressemble à ton atlas ?</h1>
      <p className="lead">Compare uniquement la disposition des cases. Les couleurs et le dessin peuvent être complètement différents.</p>
      <div className="guide-grid">
        {guides.map((guide) => (
          <button className={`guide-card ${selectedGuide.id === guide.id ? 'is-selected' : ''}`} key={guide.id} onClick={() => setSelected(guide.id)}>
            <span className="guide-card-copy"><em>{guide.badge}</em><strong>{guide.title}</strong><p>{guide.description}</p></span>
            <span className="guide-card-preview"><GuideDiagram guide={guide} /></span>
            {selectedGuide.id === guide.id && <span className="selection-label"><Check weight="bold" />Sélectionné</span>}
          </button>
        ))}
      </div>
      <div className="guide-explainer">
        <Info weight="fill" />
        <div><strong>Tu ne renseignes aucune règle à la main.</strong><p>Chaque numéro du guide possède déjà sa signature de voisins. À l’étape suivante, tu indiqueras seulement où commence ce bloc dans l’image.</p></div>
      </div>
      <footer className="page-actions"><button className="back-button" onClick={back}><ArrowLeft />Revenir à l’usage</button><PrimaryButton onClick={next}>Placer le guide {selectedGuide.title}</PrimaryButton></footer>
    </div>
  );
}

function ImageStep({ next, back, usage, guide }) {
  const [advanced, setAdvanced] = useState(false);
  const [gridVisible, setGridVisible] = useState(true);
  const [anchor, setAnchor] = useState(null);

  const placeAnchor = (event) => {
    const bounds = event.currentTarget.getBoundingClientRect();
    const imageBounds = event.currentTarget.querySelector('img').getBoundingClientRect();
    const cellWidth = imageBounds.width / 55;
    const cellHeight = imageBounds.height / 72;
    const column = Math.max(0, Math.min(55 - guide.columns, Math.floor((event.clientX - imageBounds.left) / cellWidth)));
    const row = Math.max(0, Math.min(72 - guide.rows, Math.floor((event.clientY - imageBounds.top) / cellHeight)));
    setAnchor({
      column,
      row,
      x: ((imageBounds.left - bounds.left + column * cellWidth) / bounds.width) * 100,
      y: ((imageBounds.top - bounds.top + row * cellHeight) / bounds.height) * 100,
      width: (guide.columns * cellWidth / bounds.width) * 100,
      height: (guide.rows * cellHeight / bounds.height) * 100,
    });
  };

  return (
    <div className="step-content">
      <h1>Place le guide sur ton atlas</h1>
      <p className="lead">Clique sur la cellule correspondant au numéro 1 de « {guide.title} ». PokeMap sélectionnera automatiquement toutes les autres.</p>
      <div className="two-column image-layout">
        <section className="panel atlas-panel">
          <div className="panel-label">APERÇU DE L’IMAGE</div>
          <div
            className={`atlas-preview is-selectable ${gridVisible ? 'show-grid' : ''}`}
            role="button"
            tabIndex="0"
            aria-label="Placer le coin de départ du guide dans le tileset"
            onClick={placeAnchor}
            onKeyDown={(event) => event.key === 'Enter' && setAnchor({ column: 24, row: 34, x: 48, y: 47, width: 8, height: 8 })}
          >
            <img src="/assets/terrain-erw.png" alt="Tileset ERW Grass Land" />
            {gridVisible && <div className="grid-sample" aria-hidden="true">{Array.from({ length: 48 }).map((_, index) => <i key={index} />)}</div>}
            {anchor && (
              <span className="guide-overlay" style={{ left: `${anchor.x}%`, top: `${anchor.y}%`, width: `${anchor.width}%`, height: `${anchor.height}%` }}>
                <GuideDiagram guide={guide} compact />
                <em>Guide aligné</em>
              </span>
            )}
          </div>
          <div className="file-row">
            <span className="file-icon"><FileImage weight="fill" /></span>
            <div><strong>Tileset-Terrain-new grass.png</strong><small>1760 × 2304 px · PNG</small></div>
            <label className="text-button"><UploadSimple />Changer l’image<input type="file" accept="image/png,image/jpeg" /></label>
          </div>
        </section>
        <section className="panel detection-panel">
          <h3>1. Grille détectée</h3>
          <div className="success-row"><Check weight="bold" />Alignement exact sur 32 × 32 px</div>
          <div className="placement-guide-card"><span><small>2. Guide choisi</small><strong>{guide.title}</strong><em>{guide.positions.length} cellules attendues</em></span><GuideDiagram guide={guide} compact /></div>
          <div className={`anchor-instruction ${anchor ? 'is-complete' : ''}`}>
            <Crosshair weight="bold" />
            <div>
              <strong>3. Clique sur la cellule n°1</strong>
              <p>{anchor ? `Départ placé en colonne ${anchor.column}, ligne ${anchor.row}. Les ${guide.positions.length} cellules sont associées.` : 'Le guide complet se placera relativement à ce seul repère.'}</p>
            </div>
            {anchor && <CheckCircle weight="fill" />}
          </div>
          <label className="toggle-row"><span>Afficher la grille de contrôle</span><input type="checkbox" checked={gridVisible} onChange={(event) => setGridVisible(event.target.checked)} /><b /></label>
          <button className="accordion-button" onClick={() => setAdvanced(!advanced)}>Réglages avancés de la grille<CaretDown className={advanced ? 'is-open' : ''} /></button>
          {advanced && (
            <div className="advanced-grid">
              <label>Origine X<input value="0" readOnly /></label><label>Origine Y<input value="0" readOnly /></label>
              <label>Marge<input value="0" readOnly /></label><label>Espacement<input value="0" readOnly /></label>
            </div>
          )}
          <small className="helper">À utiliser seulement si l’image contient une marge ou un espace entre les cases.</small>
        </section>
      </div>
      <footer className="page-actions">
        <button className="back-button" onClick={back}><ArrowLeft />Choisir un autre guide</button>
        <PrimaryButton onClick={next} disabled={!anchor}>{anchor ? `Tester les ${guide.positions.length} cellules` : 'Place d’abord le guide'}</PrimaryButton>
      </footer>
    </div>
  );
}

function TestStep({ next, back, usage }) {
  const tests = usageTests[usage.id];
  const [shape, setShape] = useState(tests[Math.min(4, tests.length - 1)]);
  return (
    <div className="step-content">
      <h1>Teste « {usage.title} » sur une mini-carte</h1>
      <p className="lead">Choisis un cas représentatif ou peins librement. Les raccords et répétitions sont vérifiés immédiatement.</p>
      <div className="test-toolbar">
        {tests.map((item) => <button key={item} className={shape === item ? 'is-selected' : ''} onClick={() => setShape(item)}>{item}</button>)}
      </div>
      <div className="two-column test-layout">
        <section className="panel test-canvas">
          <img src="/assets/path-test-map.png" alt="Mini-carte de validation du chemin" />
          <span className="canvas-state"><CirclesThreePlus weight="fill" />Test actif : {shape}</span>
        </section>
        <section className="panel validation-panel">
          <h3>Validation</h3>
          <div className="score-card"><strong>6 / 6</strong><small>formes raccordées sans erreur</small></div>
          {[
            ['Aucun trou visible', 'Les bords restent continus.'],
            ['Aucun raccord cassé', 'Les coins se rejoignent correctement.'],
            ['Variantes équilibrées', 'Le motif ne se répète pas trop vite.'],
          ].map(([title, text]) => <div className="validation-row" key={title}><Check weight="bold" /><div><strong>{title}</strong><small>{text}</small></div></div>)}
          <button className="adjust-button">Ajuster une tuile détectée<ArrowRight /></button>
        </section>
      </div>
      <footer className="page-actions"><button className="back-button" onClick={back}><ArrowLeft />Revenir au placement</button><PrimaryButton onClick={next}>Publier dans la bibliothèque</PrimaryButton></footer>
    </div>
  );
}

function PublishStep({ restart, onUse, usage, guide }) {
  const displayName = usage.id === 'path' ? 'Chemin de terre ERW' : `Smart Tile · ${usage.title}`;
  return (
    <div className="step-content publish-step">
      <section className="publish-hero">
        <span className="success-orb"><CheckCircle weight="fill" /></span>
        <span className="eyebrow">PUBLICATION TERMINÉE</span>
        <h1>Ton Smart Tile est prêt</h1>
        <p>{displayName} est disponible dans la bibliothèque de ton projet.</p>
      </section>
      <section className="published-card">
        <div className="published-thumb"><img src="/assets/path-test-map.png" alt="Aperçu du Smart Tile publié" /></div>
        <div className="published-info"><span>{usage.shortTitle.toUpperCase()}</span><h2>{displayName}</h2><p>Règles automatiques, variantes visuelles et validation intégrée.</p></div>
        <dl><div><dt>Grille</dt><dd>32 × 32 px</dd></div><div><dt>Guide</dt><dd>{guide.title}</dd></div><div><dt>Cellules</dt><dd>{guide.positions.length}</dd></div><div><dt>État</dt><dd className="valid">Validé</dd></div></dl>
      </section>
      <div className="publish-note"><FloppyDisk weight="fill" /><div><strong>Les détails techniques sont enregistrés automatiquement.</strong><p>Tu peux désormais utiliser ce Smart Tile comme n’importe quel outil natif de PokeMap.</p></div></div>
      <div className="publish-actions"><button className="secondary-button" onClick={restart}><Plus />Créer un autre Smart Tile</button><PrimaryButton onClick={onUse}>Utiliser dans une map</PrimaryButton></div>
    </div>
  );
}

export function App() {
  const [step, setStep] = useState(1);
  const [selectedUsage, setSelectedUsage] = useState('path');
  const [selectedGuide, setSelectedGuide] = useState('erw16');
  const [toast, setToast] = useState('');
  const selectedUsageData = usages.find((item) => item.id === selectedUsage);
  const selectedGuideData = guideCatalog[selectedUsage].find((guide) => guide.id === selectedGuide) ?? guideCatalog[selectedUsage][0];

  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: 'instant' });
    document.querySelector('.workspace')?.scrollTo({ top: 0, behavior: 'instant' });
  }, [step]);

  const status = useMemo(() => {
    if (step === 2) return 'Guide à sélectionner';
    if (step === 3) return 'Prêt à placer le guide';
    if (step === 4) return 'Tous les tests passent';
    if (step === 5) return 'Smart Tile publié';
    return 'Brouillon enregistré';
  }, [step]);

  const next = () => setStep((value) => Math.min(value + 1, 5));
  const chooseUsage = (usageId) => {
    setSelectedUsage(usageId);
    setSelectedGuide(guideCatalog[usageId][0].id);
  };

  const back = () => setStep((value) => Math.max(value - 1, 1));
  const restart = () => { setStep(1); setToast('Nouveau brouillon créé'); };
  const useInMap = () => {
    setToast(`${selectedUsageData.title} sélectionné · ouverture de la carte M01`);
    window.setTimeout(() => setToast(''), 2800);
  };

  return (
    <div className="app-shell">
      <Topbar status={status} />
      <Sidebar step={step} published={step === 5} usage={selectedUsageData} />
      <main className="workspace">
        {step > 1 && <Stepper current={step} onStep={setStep} />}
        {step === 1 && <UsageStep selected={selectedUsage} onSelect={chooseUsage} next={next} />}
        {step === 2 && <GuideStep usage={selectedUsageData} selected={selectedGuideData.id} setSelected={setSelectedGuide} next={next} back={back} />}
        {step === 3 && <ImageStep next={next} back={back} usage={selectedUsageData} guide={selectedGuideData} />}
        {step === 4 && <TestStep next={next} back={back} usage={selectedUsageData} />}
        {step === 5 && <PublishStep restart={restart} onUse={useInMap} usage={selectedUsageData} guide={selectedGuideData} />}
      </main>
      {toast && <div className="toast"><CheckCircle weight="fill" />{toast}</div>}
    </div>
  );
}
