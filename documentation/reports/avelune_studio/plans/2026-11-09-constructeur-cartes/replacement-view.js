(() => {
  const canonical=JSON.parse(document.getElementById("replacement-data").textContent);
  let plan=structuredClone(canonical),draft=false,theme="",activeLot=null,previewUrl=null;
  const id=x=>document.getElementById(x);
  const labels={planned:"Planifié",in_progress:"En cours",blocked:"Bloqué",review:"À revoir",rejected:"Refusé",accepted:"Accepté"};
  const retirement=lot=>(/^RUI-00[5-9]$/.test(lot.id)&&lot.kind==="retirement")||(lot.id==="RUI-010"&&lot.kind==="retirement_gate");
  const canonicalStates=lot=>canonical.lots.find(item=>item.id===lot.id).requiredEvidence;
  const norm=x=>String(x).normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();
  const node=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n};
  const list=(parent,title,items,ordered=false)=>{parent.append(node("h4",title));const ul=node(ordered?"ol":"ul");items.forEach(x=>ul.append(node("li",x)));parent.append(ul)};
  const safePath=value=>typeof value==="string"&&!value.includes(":")&&!value.includes("\\")&&!value.includes("?")&&!value.includes("#")&&!value.split("/").includes("..")&&!value.startsWith("/")?value:null;
  function announce(text){id("rp-source").textContent=text;id("rp-source").classList.toggle("draft",draft)}
  function summary(){
    const accepted=plan.lots.filter(l=>l.execution.status==="accepted").length;
    id("rp-stats").replaceChildren();
    [[plan.lots.length,"lots détaillés"],[plan.themes.length,"thématiques"],[accepted+"/"+plan.lots.length,draft?"acceptations déclarées":"lots acceptés"]].forEach(([value,title])=>{const n=node("div",undefined,"rp-stat");n.append(node("strong",String(value)),node("span",title));id("rp-stats").append(n)});
    id("rp-gates").replaceChildren();
    Object.entries(plan.gates).forEach(([key,gate])=>{const lot=plan.lots.find(l=>l.id===gate.lotId),n=node("div",undefined,"rp-gate"),body=node("div");body.append(node("strong",key==="G0"?"Zéro ancienne UI avant reconstruction":"Remplacement complet, 2D et 3D"),node("p",gate.lotId+" · "+labels[lot.execution.status]),node("p",gate.description));n.append(node("b",key),body);id("rp-gates").append(n)});
  }
  function contracts(){
    const root=id("rp-contract");root.replaceChildren();
    root.append(node("h3","Périmètre et autorité"),node("p",plan.scope),node("p",plan.authority));
    list(root,"Retrait intégral",plan.retirementRules);
    list(root,"Éléments protégés",plan.protectedAreas);
    list(root,"Références et lacunes",plan.referencePolicy.notes);
    root.append(node("h3","95/100 pour chaque état reconstruit dans chaque profil applicable"),node("p",plan.qualityContract.scope),node("p","Structure 40 · typographie 15 · espacements 15 · contrôles 15 · états 15. Déplacement de structure ≤ 8 px logiques ; erreur de largeur de panneau ≤ 2 % ; taille de texte ≤ 1 px logique ; espacement ≤ 4 px logiques."));
    list(root,"Refus obligatoire",plan.qualityContract.zeroTolerance);
    list(root,"Comparer puis décider",plan.qualityContract.comparisonProtocol,true);
    root.append(node("p",plan.qualityContract.review));
    list(root,"Mise à jour durable",plan.updateProtocol,true);
    root.append(node("h3","Ordre et validation"),node("p",plan.executionGuidance.order),node("p",plan.executionGuidance.testPolicy),node("p",plan.executionGuidance.nativeProof),node("p",plan.executionGuidance.gitPolicy));
    root.append(node("h3","Outil de contrôle"),node("p","update_plan.py validate vérifie les références et acceptations. record émet un patch du reçu. render --target readme ou html --emit-patch régénère le plan et l’artefact. invalidate rouvre le lot modifié et ses dépendants. Appliquer les patches avec l’outil natif d’édition, puis relancer validate."));
    root.append(node("p","Un formulaire et un score déclarés ne prouvent pas un résultat réel. Les empreintes sont vérifiées par le script, le visuel par une revue humaine ou indépendante."));
    const recovery=plan.executionGuidance.t00Recovery;
    if(recovery){
      root.append(node("h3","Reprise T00 et T01"),node("p",recovery.executionNote),node("p",recovery.evidencePolicy),node("p",recovery.nextAction));
      const coverage=recovery.referenceCoverage;
      if(coverage){
        root.append(node("p",coverage.sourceImages+" sources · "+coverage.requiredStateProfilePairs+" couples lot/état/profil requis · "+coverage.bindings+" liaisons · "+coverage.approvedBindings+" liaisons approuvées"));
        list(root,"Références à compléter",coverage.limitations);
      }
    }
    root.append(node("h3","État de cette préparation"),node("p",plan.verification.independentNativeReview),node("p",plan.verification.browserVisualReview));
    const checkpoint=plan.verification.executionCheckpoint;
    if(checkpoint){
      root.append(node("h3","Avancement vérifié de T01"),node("p",checkpoint.at+" · G0 : "+checkpoint.G0+" · "+checkpoint.acceptedLots+" lot accepté"));
      list(root,"Validations exécutées",checkpoint.knownPassed.map(x=>x.scope+" · "+x.tests+" tests · code de sortie "+x.exitCode));
      list(root,"Échecs et reprises conservés",checkpoint.knownFailed);
      list(root,"Limites actuelles",checkpoint.limits);
      if(checkpoint.evidenceFiles?.length){
        root.append(node("h4","Preuves durables"));
        const proofs=node("ul");
        checkpoint.evidenceFiles.forEach(proof=>{const path=safePath(proof.path);if(!path)return;const item=node("li"),link=node("a",proof.title||path);link.href=path;link.target="_blank";link.rel="noopener";item.append(link);proofs.append(item)});
        root.append(proofs);
      }
    }
  }
  function themes(){
    const root=id("rp-themes");root.replaceChildren();
    const all=node("button","Toutes les thématiques"+(theme?"":" · 88 lots"),!theme?"active":"");all.type="button";all.onclick=()=>{theme="";render()};root.append(all);
    plan.themes.forEach(t=>{const b=node("button",undefined,theme===t.id?"active":"");b.type="button";b.append(node("span",t.id+" · "+t.title),node("small",t.phase+" · "+t.lotIds.length+" lots"));b.onclick=()=>{theme=t.id;render()};root.append(b)});
  }
  function markDraft(){draft=true;announce("BROUILLON EN MÉMOIRE — aucune modification du dépôt. Exporter, vérifier le JSON canonique et régénérer l’artefact pour enregistrer le suivi. Aucun statut accepté ne peut être attribué par ce sélecteur.")}
  function lotCard(lot){
    const detail=node("details",undefined,"rp-lot");detail.id="plan-"+lot.id;
    const head=node("summary");head.append(node("span",lot.id,"rp-lot-id"),node("span",lot.title,"rp-lot-title"),node("span",(draft?"Brouillon · ":"")+labels[lot.execution.status],"rp-badge "+lot.execution.status));detail.append(head);
    const body=node("div",undefined,"rp-lot-body");body.append(node("p",lot.goal,"rp-goal"),node("p",lot.theme+" · Dépendances : "+(lot.dependencies.join(", ")||"aucune"),"rp-deps"));
    if(lot.execution.progressNote)body.append(node("h4","Avancement de réalisation"),node("p",lot.execution.progressNote));
    const profiles=node("div",undefined,"rp-profiles");
    [["2D",lot.profiles.twoD],["3D",lot.profiles.threeD]].forEach(([label,text])=>{const p=node("div",undefined,"rp-profile");p.append(node("b",label),node("p",text));profiles.append(p)});body.append(profiles);
    list(body,"Étapes de réalisation",lot.steps.map(s=>(s.done?"Terminé · ":"")+s.id+". "+s.text),true);
    list(body,"Propriétaires actuels",lot.owners.map(o=>o.path+" — "+o.role));
    if(lot.proposedFiles.length||lot.testFiles.length)list(body,"Nouveaux fichiers proposés",lot.proposedFiles.concat(lot.testFiles).map(o=>o.path+" — "+o.role));
    list(body,"Recette attendue, refus et non-régression",[lot.cases.expected,lot.cases.negative,lot.cases.nonRegression]);
    if(lot.profileCases)list(body,"Précisions de recette par profil",["2D : "+lot.profileCases.twoD.expected,"3D : "+lot.profileCases.threeD.expected]);
    list(body,retirement(lot)?"États et preuves de retrait exigés par profil":"États natifs à capturer par profil applicable",canonicalStates(lot).map(s=>s.id+" — "+s.title+(s.profiles?.length===1?" · "+(s.profiles[0]==="twoD"?"2D uniquement":"3D uniquement"):"")+(retirement(lot)?" · "+(s.proofKind==="native_capture"?"capture native et rapport":"rapport technique"):"")));
    list(body,"Critères de sortie",lot.acceptance);
    list(body,"Commandes prévues, pas des résultats actuels",lot.commands);
    body.append(node("p","MCP : "+lot.mcpParity),node("p","En cas de refus : "+lot.reworkRule));
    lot.referenceGaps.forEach(g=>body.append(node("p","Cible à compléter avant reconstruction : "+g,"rp-warning")));
    if(lot.references.length&&!retirement(lot)){
      body.append(node("h4","Références sources : à lier et approuver pour chaque état/profil"));
      const refbox=node("div",undefined,"rp-refs");
      lot.references.forEach(refId=>{const r=plan.references.find(x=>x.id===refId),path=r&&safePath(r.path);if(!r||!path)return;const a=node("a",undefined,"rp-ref");a.href=path;a.target="_blank";a.rel="noopener";const img=node("img");img.src=path;img.alt=r.title;img.loading="lazy";a.append(img,node("span",r.id+" · "+r.title+(r.designStatus==="known_issue"?" · Défaut à corriger":r.designStatus==="guide_only"?" · Fiche descriptive":"")));refbox.append(a)});body.append(refbox)
    }
    body.append(node("h4","Tentatives et preuves conservées"));
    const attempts=lot.execution.attempts;
    body.append(node("p",attempts.length?attempts.map(a=>a.attemptId+" · "+a.at+" · "+(labels[a.requestedStatus]||a.requestedStatus)+" · "+(a.review?.rationale||a.blockReason||"Revue à compléter")).join(" | "):"Aucune tentative native enregistrée. Aucun score ni aucune preuve inventés.","rp-attempt-list"));
    if(lot.execution.invalidations?.length)list(body,"Preuves rouvertes",lot.execution.invalidations.map(x=>x.at+" · "+x.reason));
    const actions=node("div",undefined,"rp-lot-actions"),compare=node("button",retirement(lot)?"Consulter les preuves de retrait":"Comparer maquette et réalisation");compare.type="button";compare.onclick=()=>openComparison(lot.id);actions.append(compare);
    const label=node("label","Statut de brouillon"),select=node("select");select.setAttribute("aria-label","Statut de brouillon "+lot.id);
    Object.entries(labels).filter(([key])=>key!=="accepted").forEach(([value,text])=>{const option=node("option",text);option.value=value;select.append(option)});
    if(lot.execution.status==="accepted"){const o=node("option","Accepté — lecture seule");o.value="accepted";select.append(o);select.disabled=true}
    select.value=lot.execution.status;select.onchange=()=>{lot.execution.status=select.value;markDraft();summary();head.querySelector(".rp-badge").textContent="Brouillon · "+labels[select.value];head.querySelector(".rp-badge").className="rp-badge "+select.value};label.append(select);actions.append(label);body.append(actions);detail.append(body);return detail;
  }
  function render(){
    themes();summary();
    const query=norm(id("rp-query").value).trim().split(/\s+/).filter(Boolean),status=id("rp-status").value;
    const exactId=/^rui-\d{3}$/i.test(id("rp-query").value.trim())?id("rp-query").value.trim().toUpperCase():null;
    const filtered=plan.lots.filter(l=>(!theme||l.theme===theme)&&(!status||l.execution.status===status)&&(!exactId||l.id===exactId)&&query.every(q=>norm(JSON.stringify(l)).includes(q)));
    id("rp-count").textContent=filtered.length+" lots affichés sur "+plan.lots.length+(plan.planningOnly?" · Planification initiale.":" · Suivi canonique de la réalisation ; les preuves conditionnent l’acceptation.");
    const root=id("rp-lots");root.replaceChildren();
    if(!filtered.length)root.append(node("p","Aucun lot ne correspond. Retirez le filtre ou changez la recherche.","rp-warning"));
    filtered.forEach(l=>root.append(lotCard(l)));
  }
  function setImage(imgId,linkId,emptyId,path,message){
    const img=id(imgId),a=id(linkId),empty=id(emptyId),safe=safePath(path);
    img.hidden=!safe;a.hidden=!safe;empty.hidden=!!safe;empty.textContent=message;
    if(safe){img.src=safe;a.href=safe}else{img.removeAttribute("src");a.removeAttribute("href")}
  }
  function compare(){
    const lot=plan.lots.find(l=>l.id===activeLot);if(!lot)return;
    const profile=id("rp-profile").value,stateId=id("rp-state").value,attemptIndex=Number(id("rp-attempt").value);
    const attempt=Number.isInteger(attemptIndex)?lot.execution.attempts[attemptIndex]:null;
    const state=attempt?.profiles?.[profile]?.states?.find(s=>s.id===stateId);
    const technical=retirement(lot),box=id("rp-compare-images");
    box.querySelector("figure:first-child").hidden=technical;
    box.style.gridTemplateColumns=technical?"1fr":"";
    id("rp-mode").closest("label").hidden=technical;
    id("rp-opacity").closest("label").hidden=technical;
    id("rp-local-label").textContent=technical?"Prévisualiser une capture locale provisoire":"Comparer une image locale provisoire";
    if(technical){
      const captureState=canonicalStates(lot).find(s=>s.id===stateId)?.proofKind==="native_capture";
      const capture=captureState?state?.capture:attempt?.profiles?.[profile]?.neutralHost;
      box.querySelector("figure:nth-child(2) figcaption").textContent=captureState?"Capture de l’état de retrait":"Hôte neutre du profil";
      setImage("rp-native-image","rp-native-link","rp-native-empty",capture?.screenshot?.path,"Aucune capture native de retrait pour ce profil dans cette tentative.");
      id("rp-proof-status").textContent=(draft?"BROUILLON IMPORTÉ/MODIFIÉ — ":"")+(state?"Tentative "+attempt.attemptId+" · état technique "+(state.passed===true?"déclaré vérifié":"non vérifié")+". Les preuves, empreintes et la revue restent à contrôler.":"Aucune preuve complète enregistrée pour cet état et ce profil. Le retrait n’est pas accepté.");
      box.classList.remove("overlay");box.querySelector("figure:nth-child(2)").style.opacity="1";
      const measures=id("rp-measures");measures.replaceChildren();
      if(state){
        measures.append(node("p",state.observation||"Observation absente."));
        const path=safePath(state.evidence?.path);
        if(path){const link=node("a","Ouvrir le rapport technique");link.href=path;link.target="_blank";link.rel="noopener";measures.append(link)}
        const issues=Array.isArray(state.criticalIssues)?(state.criticalIssues.length?state.criticalIssues.join(", "):"aucun déclaré"):"non renseigné";
        measures.append(node("p","Contrôle : "+(state.checkedBy||"auteur absent")+" · Écarts critiques : "+issues));
        if(attempt.review)measures.append(node("p","Revue : "+attempt.review.reviewer+" · "+attempt.review.rationale));
      }else measures.append(node("p","Le rapport, la capture et la revue apparaîtront après une vraie tentative."));
      id("rp-native-file").value="";
      if(previewUrl){URL.revokeObjectURL(previewUrl);previewUrl=null}
      return;
    }
    box.querySelector("figure:nth-child(2) figcaption").textContent="Réalisation native";
    const binding=state?plan.referenceBindings.find(b=>b.id===state.targetBindingId):plan.referenceBindings.find(b=>b.lotId===lot.id&&b.profile===profile&&b.stateId===stateId);
    const sourceId=binding?.referenceId||lot.references.find(refId=>!["known_issue","guide_only"].includes(plan.references.find(r=>r.id===refId)?.designStatus))||lot.references[0];
    const reference=plan.references.find(r=>r.id===sourceId);
    setImage("rp-reference-image","rp-reference-link","rp-reference-empty",reference?.path,"Aucune cible disponible. Préparer et approuver la référence de cet état dans RUI-003.");
    setImage("rp-native-image","rp-native-link","rp-native-empty",state?.screenshot?.path,"Aucune capture native pour cet état et ce profil. Le lot n’est pas démontré.");
    if(reference)id("rp-reference-image").alt=reference.id+" — "+reference.title;
    if(state)id("rp-native-image").alt=lot.id+" — "+profile+" — "+stateId+" — tentative "+attempt.attemptId;
    const approved=!!binding?.approvedBy&&!!binding?.approvedAt;
    let text=!approved?"Cible de cet état/profil non approuvée. La référence éventuellement visible est une source de conception, pas une preuve d’acceptation.":!state?"Cible approuvée, réalisation native absente.":"Tentative "+attempt.attemptId+" · "+(labels[attempt.requestedStatus]||attempt.requestedStatus)+" · score déclaré "+Object.values(state.score||{}).reduce((a,b)=>a+b,0)+"/100. La vérification durable passe par validate et une revue distincte.";
    if(reference?.designStatus==="known_issue")text="PREUVE DE DÉFAUT — ne pas reproduire cet état comme cible. "+text;
    if(draft)text="BROUILLON IMPORTÉ/MODIFIÉ — "+text;
    id("rp-proof-status").textContent=text;
    box.classList.toggle("overlay",id("rp-mode").value==="overlay");
    box.querySelector("figure:nth-child(2)").style.opacity=id("rp-mode").value==="overlay"?String(Number(id("rp-opacity").value)/100):"1";
    const measures=id("rp-measures");measures.replaceChildren();
    if(binding)measures.append(node("p","Cible : "+binding.id+" · approbation "+(binding.approvedBy||"absente")+" · "+(binding.approvedAt||"date absente")));
    if(state){list(measures,"Mesures déclarées",Object.entries(state.metrics||{}).map(([key,value])=>key+" : "+value));list(measures,"Écarts critiques",state.criticalIssues?.length?state.criticalIssues:["Aucun déclaré ; à confirmer par revue."]);if(attempt.review)measures.append(node("p","Revue : "+attempt.review.reviewer+" · "+attempt.review.rationale))}
    else measures.append(node("p","Les scores, mesures et captures apparaîtront ici après une vraie tentative. Ils restent vides aujourd’hui."));
    id("rp-native-file").value="";
    if(previewUrl){URL.revokeObjectURL(previewUrl);previewUrl=null}
  }
  function comparisonStates(lot){
    const profile=id("rp-profile").value,select=id("rp-state"),previous=select.value;
    select.replaceChildren();canonicalStates(lot).filter(s=>!s.profiles||s.profiles.includes(profile)).forEach(s=>{const o=node("option",s.id+" · "+s.title);o.value=s.id;select.append(o)});
    if(Array.from(select.options).some(o=>o.value===previous))select.value=previous;
  }
  function openComparison(lotId){
    activeLot=lotId;const lot=plan.lots.find(l=>l.id===lotId);id("rp-comparison-title").textContent=lot.id+" — "+lot.title;
    comparisonStates(lot);
    id("rp-attempt").replaceChildren();
    if(!lot.execution.attempts.length){const o=node("option","Aucune tentative");o.value="-1";id("rp-attempt").append(o)}
    lot.execution.attempts.forEach((a,i)=>{const o=node("option",a.attemptId+" · "+(labels[a.requestedStatus]||a.requestedStatus));o.value=String(i);id("rp-attempt").append(o)});if(lot.execution.attempts.length)id("rp-attempt").value=String(lot.execution.attempts.length-1);
    compare();id("rp-comparison").showModal();
  }
  id("rp-query").addEventListener("input",render);id("rp-status").addEventListener("change",render);
  id("rp-profile").addEventListener("change",()=>{const lot=plan.lots.find(l=>l.id===activeLot);if(lot)comparisonStates(lot);compare()});
  ["rp-state","rp-attempt","rp-mode"].forEach(x=>id(x).addEventListener("change",compare));id("rp-opacity").addEventListener("input",compare);
  id("rp-close").onclick=()=>id("rp-comparison").close();
  id("rp-native-file").onchange=()=>{const file=id("rp-native-file").files[0];if(!file)return;if(previewUrl)URL.revokeObjectURL(previewUrl);previewUrl=URL.createObjectURL(file);id("rp-native-image").src=previewUrl;id("rp-native-image").hidden=false;id("rp-native-empty").hidden=true;id("rp-native-link").hidden=true;id("rp-proof-status").textContent="APERÇU LOCAL PROVISOIRE — image non enregistrée dans proofs, aucune mesure ni acceptation. Le statut du lot ne change pas."};
  id("rp-import").onclick=()=>id("rp-file").click();
  id("rp-file").onchange=async()=>{try{const file=id("rp-file").files[0];if(!file)return;const value=JSON.parse(await file.text());if(value.id!==canonical.id||value.schemaVersion!==1||!Array.isArray(value.lots)||value.lots.length!==canonical.lots.length||value.lots.some((l,i)=>l.id!==canonical.lots[i].id)||!Array.isArray(value.references))throw new Error("Ce fichier ne correspond pas au plan de remplacement.");plan=value;markDraft();contracts();render()}catch(error){announce("Import refusé : "+error.message)}};
  id("rp-export").onclick=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify(plan,null,2)],{type:"application/json"}));const a=node("a");a.href=url;a.download="ui-replacement-plan.draft.json";a.click();URL.revokeObjectURL(url);announce("Brouillon exporté. Il ne remplace pas le JSON canonique du dossier ; vérifier et régénérer l’artefact après application.")};
  const reset=node("button","Revenir au canonique");reset.type="button";reset.onclick=()=>{plan=structuredClone(canonical);draft=false;theme="";id("rp-query").value="";id("rp-status").value="";announce("État canonique embarqué restauré ; aucun fichier du dépôt modifié.");contracts();render()};document.querySelector(".rp-actions").append(reset);
  id("read-lots").onclick=()=>{showPanel("replacement");location.hash="replacement"};
  function routePlan(){
    if(location.hash==="#replacement"){showPanel("replacement");return}
    const match=location.hash.match(/^#plan-(RUI-\d{3})$/);
    if(match&&plan.lots.some(l=>l.id===match[1])){theme="";id("rp-status").value="";id("rp-query").value=match[1];render();showPanel("replacement");const lot=id("plan-"+match[1]);lot.open=true;lot.scrollIntoView()}
  }
  window.addEventListener("hashchange",routePlan);
  contracts();render();
  if(!location.hash||location.hash==="#replacement")showPanel("replacement");
  routePlan();
})();
