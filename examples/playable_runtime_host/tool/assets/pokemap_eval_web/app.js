'use strict';

const state = {
  projects: [],
  scenarios: [],
  runs: [],
  projectId: null,
  scenarioId: null,
  runId: null,
  run: null,
  receipt: null,
  events: [],
  selectedStepId: null,
  selectedTab: 'diff',
  eventSource: null,
  connected: false,
  startedAt: null,
};

const terminalEventTypes = [
  'run.finished',
  'run.cancelled',
  'worker.failed',
  'assertion.failed',
];

const streamedEventTypes = [
  'run.started',
  'run.paused',
  'run.resumed',
  'run.cancelled',
  'step.started',
  'state.changed',
  'step.finished',
  'assertion.failed',
  'worker.failed',
  'run.finished',
];

const controlPaths = {
  step: '/step',
  pause: '/pause',
  resume: '/resume',
  cancel: '/cancel',
};

const interactiveTargetLabel = 'Interactif · Bientôt';

class ApiError extends Error {
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }

  static async from(response) {
    let code = `http_${response.status}`;
    try {
      const payload = await response.json();
      if (typeof payload.error === 'string') {
        code = payload.error;
      }
    } catch (_) {
      // The status code remains useful when an intermediary returns plain text.
    }
    return new ApiError(response.status, code);
  }
}

function element(id) {
  return document.getElementById(id);
}

function sessionToken() {
  return document
    .querySelector('meta[name="pokemap-eval-token"]')
    .getAttribute('content');
}

async function api(path, options = {}) {
  const headers = new Headers(options.headers || {});
  headers.set('Accept', 'application/json');
  if (options.method && options.method !== 'GET') {
    headers.set('Content-Type', 'application/json');
    headers.set('X-PokeMap-Eval-Token', sessionToken());
  }
  const response = await fetch(path, {...options, headers});
  if (!response.ok) {
    throw await ApiError.from(response);
  }
  return response.json();
}

function textNode(tagName, className, text) {
  const node = document.createElement(tagName);
  if (className) {
    node.className = className;
  }
  node.textContent = text;
  return node;
}

function safeText(value) {
  if (value === null || value === undefined) {
    return '—';
  }
  if (typeof value === 'string') {
    return value;
  }
  return JSON.stringify(value, null, 2);
}

function formatIdentifier(value) {
  if (!value) {
    return 'Étape';
  }
  return value
    .replaceAll('.', ' ')
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .replace(/\b\p{L}/gu, (letter) => letter.toUpperCase());
}

function setError(message) {
  const target = element('app-error');
  target.textContent = message || '';
  target.hidden = !message;
}

function setRunnerStatus(label, variant) {
  const target = element('runner-status');
  target.textContent = label;
  target.className = `connection-status connection-status--${variant}`;
}

function navigationButton({label, meta, selected, onClick}) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = selected
    ? 'navigation-item is-selected'
    : 'navigation-item';
  button.textContent = meta ? `${label} · ${meta}` : label;
  button.addEventListener('click', onClick);
  return button;
}

function renderProjects() {
  const target = element('project-list');
  target.replaceChildren();
  if (state.projects.length === 0) {
    target.append(textNode('p', 'navigation-placeholder', 'Aucun projet'));
    return;
  }
  for (const project of state.projects) {
    target.append(
      navigationButton({
        label: project.label,
        meta: project.id === state.projectId ? 'Prêt' : null,
        selected: project.id === state.projectId,
        onClick: () => selectProject(project.id),
      }),
    );
  }
}

function renderScenarioGroup(targetId, scenarios, emptyLabel) {
  const target = element(targetId);
  target.replaceChildren();
  if (scenarios.length === 0) {
    target.append(textNode('p', 'navigation-placeholder', emptyLabel));
    return;
  }
  for (const scenario of scenarios) {
    target.append(
      navigationButton({
        label: scenario.title,
        meta: scenario.policy === 'certify' ? 'Certification' : 'Diagnostic',
        selected: scenario.id === state.scenarioId,
        onClick: () => selectScenario(scenario.id),
      }),
    );
  }
}

function renderScenarios() {
  const visible = state.scenarios.filter(
    (scenario) => scenario.projectId === state.projectId,
  );
  renderScenarioGroup(
    'campaign-list',
    visible.filter((scenario) => scenario.policy === 'certify'),
    'Aucune certification',
  );
  renderScenarioGroup(
    'scenario-list',
    visible.filter((scenario) => scenario.policy !== 'certify'),
    'Aucun diagnostic ciblé',
  );
}

function renderHistory() {
  const target = element('history-list');
  target.replaceChildren();
  const history = state.runs
    .filter((run) => run.source === 'history')
    .slice(0, 8);
  if (history.length === 0) {
    target.append(
      textNode('p', 'navigation-placeholder', 'Aucune exécution récente'),
    );
    return;
  }
  for (const run of history) {
    target.append(
      navigationButton({
        label: formatIdentifier(run.scenarioId),
        meta: run.status || run.lifecycle,
        selected: run.runId === state.runId,
        onClick: () => loadRun(run.runId),
      }),
    );
  }
}

async function selectProject(projectId) {
  state.projectId = projectId;
  state.scenarioId = null;
  setError(null);
  renderProjects();
  renderScenarios();
  renderSelection();
}

function selectScenario(scenarioId) {
  state.scenarioId = scenarioId;
  state.runId = null;
  state.run = null;
  state.receipt = null;
  state.events = [];
  state.selectedStepId = null;
  closeEventSource();
  setError(null);
  renderScenarios();
  renderHistory();
  renderSelection();
  renderRun();
}

function selectedScenario() {
  return state.scenarios.find((scenario) => scenario.id === state.scenarioId);
}

function renderSelection() {
  const scenario = selectedScenario();
  element('target-interactive').textContent = interactiveTargetLabel;
  element('run-title').textContent = scenario
    ? scenario.title
    : 'Choisissez un scénario';
  element('run-subtitle').textContent = scenario
    ? `${scenario.stepCount} étapes · politique ${scenario.policy} · cible headless`
    : 'Lancez un diagnostic headless sans ouvrir la fenêtre du jeu.';
  element('run-button').disabled = !scenario || Boolean(state.runId);
}

function closeEventSource() {
  if (state.eventSource) {
    state.eventSource.close();
    state.eventSource = null;
  }
}

async function startRun() {
  const scenario = selectedScenario();
  if (!scenario) {
    return;
  }
  setError(null);
  element('run-button').disabled = true;
  setRunnerStatus('Démarrage du runner', 'waiting');
  try {
    const payload = await api('/api/runs', {
      method: 'POST',
      body: JSON.stringify({
        scenarioId: scenario.id,
        target: 'headless',
      }),
    });
    state.runId = payload.runId;
    state.run = payload.run;
    state.receipt = null;
    state.events = Array.isArray(payload.run?.events)
      ? [...payload.run.events]
      : [];
    state.selectedStepId = null;
    state.startedAt = Date.now();
    connectEvents(payload.runId);
    renderHistory();
    renderRun();
  } catch (error) {
    setRunnerStatus('Runner indisponible', 'failed');
    setError(messageForError(error));
    renderControls();
  }
}

function connectEvents(runId) {
  closeEventSource();
  const source = new EventSource(`/api/runs/${runId}/events`);
  state.eventSource = source;
  source.addEventListener('open', () => {
    state.connected = true;
    setRunnerStatus('Runner connecté', 'connected');
  });
  source.addEventListener('error', () => {
    if (!isTerminal()) {
      state.connected = false;
      setRunnerStatus('Flux interrompu', 'failed');
    }
  });
  for (const type of streamedEventTypes) {
    source.addEventListener(type, (message) => {
      try {
        acceptEvent(JSON.parse(message.data));
      } catch (_) {
        setError('Le runner a envoyé un événement illisible.');
      }
    });
  }
}

function acceptEvent(event) {
  if (
    !event ||
    event.runId !== state.runId ||
    !Number.isInteger(event.sequence) ||
    typeof event.type !== 'string'
  ) {
    return;
  }
  const existing = state.events.find(
    (candidate) => candidate.sequence === event.sequence,
  );
  if (!existing) {
    state.events.push(event);
    state.events.sort((left, right) => left.sequence - right.sequence);
  }
  const stepId = event.payload?.stepId;
  if (event.type === 'step.started' && typeof stepId === 'string') {
    state.selectedStepId = stepId;
  }
  if (
    event.type === 'assertion.failed' ||
    event.type === 'worker.failed' ||
    (event.type === 'step.finished' && event.payload?.passed === false) ||
    (event.type === 'run.finished' && event.payload?.status !== 'succeeded')
  ) {
    if (typeof stepId === 'string') {
      state.selectedStepId = stepId;
    }
    state.selectedTab = 'diff';
  }
  if (terminalEventTypes.includes(event.type)) {
    closeEventSource();
    void refreshRuns();
    void loadRunDetails(state.runId);
  }
  renderRun();
}

function buildSteps() {
  const steps = new Map();
  for (const event of state.events) {
    const stepId = event.payload?.stepId;
    if (typeof stepId !== 'string') {
      continue;
    }
    const step = steps.get(stepId) || {
      id: stepId,
      index: event.payload?.index,
      kind: event.payload?.kind,
      status: 'running',
      passed: null,
      events: [],
    };
    step.events.push(event);
    if (event.type === 'step.started') {
      step.status = 'running';
    }
    if (event.type === 'step.finished') {
      step.passed = event.payload?.passed === true;
      step.status = step.passed ? 'success' : 'failure';
      step.details = event.payload?.details;
    }
    if (event.type === 'assertion.failed' || event.type === 'worker.failed') {
      step.status = 'failure';
      step.passed = false;
    }
    steps.set(stepId, step);
  }
  return [...steps.values()].sort((left, right) => {
    const leftIndex = Number.isInteger(left.index)
      ? left.index
      : Number.MAX_SAFE_INTEGER;
    const rightIndex = Number.isInteger(right.index)
      ? right.index
      : Number.MAX_SAFE_INTEGER;
    return leftIndex - rightIndex;
  });
}

function renderTimeline() {
  const target = element('run-timeline');
  target.replaceChildren();
  const steps = buildSteps();
  if (steps.length === 0) {
    const empty = document.createElement('li');
    empty.className = 'timeline-empty';
    empty.append(
      textNode(
        'strong',
        null,
        state.runId ? 'Initialisation du parcours…' : 'Aucune exécution active',
      ),
      textNode(
        'span',
        null,
        state.runId
          ? 'Le premier événement arrivera dans quelques instants.'
          : 'Les étapes apparaîtront ici dans leur ordre réel.',
      ),
    );
    target.append(empty);
    return;
  }
  for (const step of steps) {
    const item = document.createElement('li');
    const button = document.createElement('button');
    button.type = 'button';
    button.className = [
      'timeline-step',
      step.id === state.selectedStepId ? 'is-selected' : '',
      step.status === 'success' ? 'timeline-step--success' : '',
      step.status === 'failure' ? 'timeline-step--failure' : '',
    ]
      .filter(Boolean)
      .join(' ');
    button.append(
      textNode('strong', 'timeline-step-title', formatIdentifier(step.id)),
      textNode(
        'span',
        'timeline-step-status',
        step.status === 'success'
          ? 'Réussie'
          : step.status === 'failure'
            ? 'Échec'
            : 'En cours',
      ),
    );
    button.addEventListener('click', () => {
      state.selectedStepId = step.id;
      renderRun();
    });
    item.append(button);
    target.append(item);
  }
}

function latestEvent(type) {
  return [...state.events].reverse().find((event) => event.type === type);
}

function isPaused() {
  const paused = latestEvent('run.paused');
  const resumed = latestEvent('run.resumed');
  return Boolean(paused && (!resumed || paused.sequence > resumed.sequence));
}

function terminalEvent() {
  return [...state.events]
    .reverse()
    .find((event) => terminalEventTypes.includes(event.type));
}

function isTerminal() {
  return Boolean(terminalEvent());
}

function renderControls() {
  const hasRun = Boolean(state.runId);
  const terminal = isTerminal();
  const paused = isPaused();
  element('run-button').disabled = !selectedScenario() || hasRun;
  element('step-button').disabled = !hasRun || terminal || !paused;
  element('pause-button').disabled = !hasRun || terminal || paused;
  element('resume-button').disabled = !hasRun || terminal || !paused;
  element('cancel-button').disabled = !hasRun || terminal;
  element('receipt-button').disabled = !state.receipt;
}

function renderMetrics() {
  const steps = buildSteps();
  const successes = steps.filter((step) => step.status === 'success').length;
  const failures = steps.filter((step) => step.status === 'failure').length;
  const total = selectedScenario()?.stepCount || steps.length;
  element('metric-progress').textContent = `${successes + failures} / ${total}`;
  element('metric-success').textContent = `${successes}`;
  element('metric-failure').textContent = `${failures}`;
  const elapsed = state.receipt?.durationMilliseconds ??
    (state.startedAt ? Date.now() - state.startedAt : null);
  element('metric-duration').textContent =
    elapsed === null ? '—' : `${(elapsed / 1000).toFixed(1)} s`;
}

function renderRunStatus() {
  const terminal = terminalEvent();
  let label = state.runId ? 'En cours' : 'Prêt';
  if (isPaused()) {
    label = 'En pause';
  }
  if (terminal?.type === 'run.cancelled') {
    label = 'Annulé';
  }
  if (terminal?.type === 'run.finished') {
    label = terminal.payload?.status === 'succeeded' ? 'Réussi' : 'Échec';
  }
  if (terminal?.type === 'worker.failed') {
    label = 'Worker en échec';
  }
  element('timeline-status').textContent = label;
}

function selectedStep() {
  return buildSteps().find((step) => step.id === state.selectedStepId);
}

function renderInspectorTabs() {
  for (const tabName of ['diff', 'state', 'trace', 'proof']) {
    const button = element(`tab-${tabName}`);
    const selected = state.selectedTab === tabName;
    button.classList.toggle('is-selected', selected);
    button.setAttribute('aria-selected', String(selected));
  }
}

function inspectorSection(title) {
  const section = document.createElement('section');
  section.className = 'inspector-section';
  section.append(textNode('h3', null, title));
  return section;
}

function renderDiff(target, step) {
  const section = inspectorSection('Changements observés');
  const list = document.createElement('ul');
  list.className = 'inspector-list';
  const changeEvents = step.events.filter(
    (event) => event.type === 'state.changed',
  );
  const changes = changeEvents.flatMap(
    (event) => event.payload?.diff?.changes || [],
  );
  const finalChanges =
    latestEvent('run.finished')?.payload?.diff?.changes || [];
  const visibleChanges = changes.length > 0 ? changes : finalChanges;
  if (visibleChanges.length === 0) {
    section.append(
      textNode(
        'p',
        'inspector-placeholder',
        step.status === 'running'
          ? 'Les différences apparaîtront après l’exécution de l’étape.'
          : 'Cette étape n’a produit aucun changement d’état.',
      ),
    );
  } else {
    for (const change of visibleChanges.slice(0, 80)) {
      const row = document.createElement('li');
      row.className = 'inspector-row';
      row.append(
        textNode('strong', 'inspector-path', change.path || 'état'),
        textNode('span', 'inspector-key', 'Avant'),
        textNode('span', 'inspector-key', 'Après'),
        textNode('code', 'inspector-value', safeText(change.before)),
        textNode('code', 'inspector-value', safeText(change.after)),
      );
      list.append(row);
    }
    section.append(list);
  }
  target.append(section);
}

function renderState(target, step) {
  const started = latestEvent('run.started');
  const snapshot = started?.payload?.initialState;
  const section = inspectorSection('État normalisé');
  if (!snapshot || typeof snapshot !== 'object') {
    section.append(
      textNode('p', 'inspector-placeholder', 'Aucun snapshot disponible.'),
    );
  } else {
    const list = document.createElement('ul');
    list.className = 'proof-list';
    for (const [key, value] of Object.entries(snapshot)) {
      const row = document.createElement('li');
      row.className = 'proof-row';
      row.append(
        textNode('span', 'proof-label', formatIdentifier(key)),
        textNode('code', 'proof-value', safeText(value)),
      );
      list.append(row);
    }
    section.append(list);
  }
  const stepSection = inspectorSection('Résultat de l’étape');
  stepSection.append(
    textNode(
      'code',
      'proof-value',
      safeText(step.details || {status: step.status}),
    ),
  );
  target.append(section, stepSection);
}

function renderTrace(target, step) {
  const section = inspectorSection('Trace ordonnée');
  const list = document.createElement('ol');
  list.className = 'trace-list';
  for (const event of step.events) {
    const item = document.createElement('li');
    const failure =
      event.type === 'assertion.failed' ||
      event.type === 'worker.failed' ||
      event.payload?.passed === false;
    item.className = failure ? 'trace-item trace-item--failure' : 'trace-item';
    item.append(
      textNode(
        'span',
        'trace-type',
        `${event.sequence} · ${event.type}`,
      ),
      textNode('code', 'trace-payload', safeText(event.payload)),
    );
    list.append(item);
  }
  section.append(list);
  target.append(section);
}

function proofRow(label, value, success = false) {
  const row = document.createElement('li');
  row.className = 'proof-row';
  row.append(
    textNode('span', 'proof-label', label),
    textNode(
      'code',
      success ? 'proof-value proof-value--success' : 'proof-value',
      safeText(value),
    ),
  );
  return row;
}

function renderProof(target) {
  const started = latestEvent('run.started');
  const finished = latestEvent('run.finished');
  const receipt = state.receipt?.receipt || state.receipt;
  const section = inspectorSection('Preuves de l’exécution');
  const list = document.createElement('ul');
  list.className = 'proof-list';
  list.append(
    proofRow('Politique', receipt?.policy || started?.payload?.policy),
    proofRow('Cible', receipt?.target || state.run?.target || 'headless'),
    proofRow(
      'Niveau de preuve',
      receipt?.evidenceLevel || finished?.payload?.evidenceLevel,
      Boolean(receipt?.evidenceLevel || finished?.payload?.evidenceLevel),
    ),
    proofRow(
      'Checkpoint',
      receipt?.checkpointProvenance ||
        started?.payload?.checkpointProvenance ||
        'Nouveau jeu',
    ),
    proofRow('Raccourcis', receipt?.shortcutsUsed || []),
    proofRow('Artefacts', receipt?.artifacts || []),
  );
  section.append(list);
  target.append(section);
}

function renderInspector() {
  renderInspectorTabs();
  const target = element('inspector-content');
  target.replaceChildren();
  const step = selectedStep();
  element('inspector-title').textContent = step
    ? formatIdentifier(step.id)
    : 'Aucune étape';
  element('inspector-status').textContent = step
    ? step.status === 'success'
      ? 'Réussie'
      : step.status === 'failure'
        ? 'Échec'
        : 'En cours'
    : 'En attente';
  if (!step) {
    const empty = document.createElement('div');
    empty.className = 'inspector-empty';
    empty.append(
      textNode('strong', null, 'Sélectionnez une étape'),
      textNode(
        'p',
        null,
        'Ses différences, son état et ses preuves apparaîtront ici.',
      ),
    );
    target.append(empty);
    return;
  }
  if (state.selectedTab === 'diff') {
    renderDiff(target, step);
  } else if (state.selectedTab === 'state') {
    renderState(target, step);
  } else if (state.selectedTab === 'trace') {
    renderTrace(target, step);
  } else {
    renderProof(target);
  }
}

function renderConsole() {
  const latest = state.events.at(-1);
  element('event-console').textContent = latest
    ? `${latest.sequence} · ${latest.type} · ${safeText(latest.payload)}`
    : 'En attente d’un scénario.';
}

function renderRun() {
  renderSelection();
  renderControls();
  renderMetrics();
  renderRunStatus();
  renderTimeline();
  renderInspector();
  renderConsole();
}

async function controlRun(action) {
  if (!state.runId) {
    return;
  }
  setError(null);
  try {
    await api(`/api/runs/${state.runId}${controlPaths[action]}`, {
      method: 'POST',
      body: '{}',
    });
  } catch (error) {
    setError(messageForError(error));
  }
}

async function loadRun(runId) {
  setError(null);
  closeEventSource();
  state.runId = runId;
  state.events = [];
  state.selectedStepId = null;
  state.receipt = null;
  await loadRunDetails(runId);
  renderHistory();
  renderRun();
}

async function loadRunDetails(runId) {
  if (!runId) {
    return;
  }
  try {
    const payload = await api(`/api/runs/${runId}`);
    if (state.runId !== runId) {
      return;
    }
    state.run = payload.run;
    state.receipt = payload.run.receipt || null;
    if (Array.isArray(payload.run.events)) {
      state.events = [...payload.run.events].sort(
        (left, right) => left.sequence - right.sequence,
      );
    }
    state.scenarioId = payload.run.scenarioId;
    const steps = buildSteps();
    state.selectedStepId = steps.at(-1)?.id || null;
    renderRun();
  } catch (error) {
    setError(messageForError(error));
  }
}

async function refreshRuns() {
  try {
    const payload = await api('/api/runs');
    state.runs = Array.isArray(payload.runs) ? payload.runs : [];
    renderHistory();
  } catch (error) {
    setError(messageForError(error));
  }
}

function messageForError(error) {
  if (!(error instanceof ApiError)) {
    return 'Le cockpit n’a pas pu joindre le runner local.';
  }
  const labels = {
    forbidden: 'La session du cockpit a expiré. Rechargez la page.',
    target_unavailable: 'La cible interactive arrivera dans la V2.',
    invalid_run_state: 'Cette commande n’est pas disponible dans cet état.',
    run_cancelled: 'Cette exécution est déjà annulée.',
    run_finished: 'Cette exécution est déjà terminée.',
    worker_failed: 'Le worker headless a rencontré une erreur.',
  };
  return labels[error.code] || `Erreur locale : ${error.code}`;
}

function bindControls() {
  element('run-button').addEventListener('click', startRun);
  for (const action of ['step', 'pause', 'resume', 'cancel']) {
    element(`${action}-button`).addEventListener('click', () => {
      void controlRun(action);
    });
  }
  element('receipt-button').addEventListener('click', () => {
    state.selectedTab = 'proof';
    renderInspector();
  });
  for (const tabName of ['diff', 'state', 'trace', 'proof']) {
    element(`tab-${tabName}`).addEventListener('click', () => {
      state.selectedTab = tabName;
      renderInspector();
    });
  }
  element('inspector-toggle').addEventListener('click', () => {
    const inspector = element('workspace-inspector');
    const expanded = inspector.classList.toggle('is-open');
    element('inspector-toggle').setAttribute(
      'aria-expanded',
      String(expanded),
    );
  });
}

async function initialize() {
  bindControls();
  renderRun();
  setRunnerStatus('Connexion au runner', 'waiting');
  try {
    const [projectsPayload, scenariosPayload, runsPayload] = await Promise.all([
      api('/api/projects'),
      api('/api/scenarios'),
      api('/api/runs'),
    ]);
    state.projects = Array.isArray(projectsPayload.projects)
      ? projectsPayload.projects
      : [];
    state.scenarios = Array.isArray(scenariosPayload.scenarios)
      ? scenariosPayload.scenarios
      : [];
    state.runs = Array.isArray(runsPayload.runs) ? runsPayload.runs : [];
    state.projectId = state.projects.at(0)?.id || null;
    renderProjects();
    renderScenarios();
    renderHistory();
    renderSelection();
    setRunnerStatus('Runner connecté', 'connected');
  } catch (error) {
    renderProjects();
    renderScenarios();
    renderHistory();
    setRunnerStatus('Runner indisponible', 'failed');
    setError(messageForError(error));
  }
}

window.addEventListener('beforeunload', closeEventSource);
void initialize();
