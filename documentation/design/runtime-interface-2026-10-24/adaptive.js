(() => {
  const snapshots=new WeakMap();
  const pageMemory=new Map();
  const controlMemory=new Map();
  let uid=0;
  const visible=el=>el.getClientRects().length>0&&!el.closest('[hidden]');
  const axisOverflow=el=>el.scrollHeight>el.clientHeight+2||el.scrollWidth>el.clientWidth+2;
  const arrows={prev:'<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path d="m14 6-6 6 6 6" fill="none" stroke="currentColor" stroke-width="2"/></svg>',next:'<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path d="m10 6 6 6-6 6" fill="none" stroke="currentColor" stroke-width="2"/></svg>'};
  function controlKey(screen,el,index){const field=el.getAttribute('aria-label')||(el.dataset.nameInput!==undefined?'name':el.dataset.toggleCheck!==undefined?'check-'+index:el.tagName+'-'+index);return screen.dataset.composition+'|'+screen.dataset.state+'|'+field;}
  function capture(root) {
    root.querySelectorAll('.screen').forEach(screen=>screen.querySelectorAll('input,select,[data-toggle-setting],[data-toggle-check]').forEach((el,i)=>{
      if(el.hasAttribute('data-option'))return;const key=controlKey(screen,el,i);controlMemory.set(key,{value:el.value,checked:el.getAttribute('aria-checked'),pressed:el.getAttribute('aria-pressed'),selected:el.classList.contains('selected')});
    }));
  }
  function restoreControls(screen) {
    screen.querySelectorAll('input,select,[data-toggle-setting],[data-toggle-check]').forEach((el,i)=>{
      if(el.hasAttribute('data-option'))return;const data=controlMemory.get(controlKey(screen,el,i));if(!data)return;
      if(data.value!==undefined)el.value=data.value;
      if(data.checked!==null){el.setAttribute('aria-checked',data.checked);el.classList.toggle('off',data.checked!=='true');}
      if(el.dataset.toggleCheck!==undefined){el.classList.toggle('selected',data.selected);if(data.pressed!==null)el.setAttribute('aria-pressed',data.pressed);}
      if(el.matches('[data-name-input]')){const count=screen.querySelector('[data-name-count]');if(count)count.textContent=el.value.length+' / 12';screen.querySelectorAll('.screen-footer [data-screen]').forEach(b=>{if(/Valider|Validation/.test(b.textContent)){b.disabled=/submitting|applying|pending|busy/.test(screen.dataset.state)||!el.value.trim()||el.value.length>12;b.setAttribute('aria-disabled',String(b.disabled));}});}
      if(el.matches('input[type="range"]')){const label=el.closest('.setting')?.querySelector('[data-range-value]');if(label)label.textContent=el.value+' %';}
    });
    const choices=[...screen.querySelectorAll('[data-toggle-check]')];if(choices.length){const count=choices.filter(el=>el.classList.contains('selected')).length;choices.forEach(el=>{el.setAttribute('aria-pressed',String(el.classList.contains('selected')));const mark=el.querySelector('svg,i');if(mark)mark.setAttribute('data-lucide',el.classList.contains('selected')?'square-check':'square');});screen.querySelectorAll('.screen-footer [data-screen=\"interaction.message\"]').forEach(el=>{el.disabled=count<1||/submitting|applying|pending|busy/.test(screen.dataset.state);el.setAttribute('aria-disabled',String(el.disabled));});window.lucide?.createIcons();}
  }
  function prepare(screen) {
    screen.classList.add('adaptive-game');
    const keyboard=screen.querySelector('.controller-keyboard,.os-keyboard');
    if(keyboard){const body=keyboard.parentElement;const layout=document.createElement('div');layout.className='name-layout';const form=document.createElement('div');form.className='name-form';while(body.firstChild&&body.firstChild!==keyboard)form.appendChild(body.firstChild);const instructions=document.createElement('div');instructions.className='name-instructions';while(form.firstChild&&!form.firstChild.matches?.('input'))instructions.appendChild(form.firstChild);form.prepend(instructions);layout.append(form,keyboard);body.appendChild(layout);}
    const box=screen.querySelector('.box-grid');
    if(box&&screen.matches('.landscape')){const split=box.closest('.split-layout');const left=box.parentElement;const right=split.lastElementChild;right.classList.add('pc-actions');const team=left.querySelector('.mini-party');if(team){right.append(team.previousElementSibling,team);}const body=split.parentElement;[...body.children].filter(el=>el!==split).forEach(el=>right.prepend(el));}
    if(box&&screen.matches('.companion')){const gridHeader=screen.querySelector('.box-grid-header');gridHeader.querySelector('strong')?.remove();screen.querySelector('.screen-header').appendChild(gridHeader);}
    screen.querySelectorAll('.tabs').forEach(x=>x.style.overflow='visible');
  }
  function snapshot(screen) {
    const entries=[screen,...screen.querySelectorAll('*')].filter(e=>e instanceof HTMLElement).map(el=>({el,children:[...el.childNodes],style:el.getAttribute('style')}));
    return {entries};
  }
  function reset(screen,record) {
    record.entries.forEach(x=>{if(x.el.isConnected&&x.el.children.length===0&&!x.el.matches('input,select,textarea,img'))x.children=[...x.el.childNodes];});
    record.entries.forEach(x=>{if(!x.el.matches('input,textarea'))x.el.replaceChildren(...x.children);if(x.style===null)x.el.removeAttribute('style');else x.el.setAttribute('style',x.style);x.el.classList.remove('page-host');x.el.removeAttribute('data-page-error');});
  }
  function pageKey(screen,host,index){return [screen.dataset.composition,screen.dataset.state,screen.dataset.display,screen.className,index].join('|');}
  function activate(host,index,focus=false) {
    const pages=[...host.querySelector(':scope>.page-viewport').children];index=Math.max(0,Math.min(index,pages.length-1));
    pages.forEach((p,i)=>p.hidden=i!==index);host.dataset.page=String(index);pageMemory.set(host.dataset.pageKey,index);
    const label=host.querySelector(':scope>.page-navigation .page-count');const section=host.classList.contains('pc-actions')?'Actions / équipe':host.closest('[data-composition=\"pc.box\"]')?(pages[index].querySelector('.box-grid')?'Boîte · 30 emplacements':pages[index].querySelector('.mini-party')?'Équipe':'Actions'):host.closest('[data-composition^=\"options.\"]')?'Réglages':'';label.innerHTML=(section?`<strong>${section}</strong>`:'')+`<span>${host.closest('[data-composition="pc.box"]')?'Vue':'Page'} ${index+1} / ${pages.length}</span>`;
    host.querySelector(':scope>.page-navigation [data-page-prev]').disabled=index===0;host.querySelector(':scope>.page-navigation [data-page-next]').disabled=index===pages.length-1;
    const screen=host.closest('.screen');
    if(focus&&screen){screen.querySelectorAll('.focused').forEach(e=>e.classList.remove('focused'));const target=[...pages[index].querySelectorAll('button:not([disabled]),input:not([disabled]),select:not([disabled])')].find(visible)||host.querySelector(index===0?':scope>.page-navigation [data-page-next]':':scope>.page-navigation [data-page-prev]');if(target&&screen.matches('.gamepad,.primary-display,.companion'))target.classList.add('focused');}
  }
  function paginate(screen,host,index) {
    if(host.classList.contains('page-host')||!visible(host)||!axisOverflow(host)||host.clientHeight<90)return;
    const style=getComputedStyle(host);const total=host.clientHeight;const padding=parseFloat(style.paddingTop)+parseFloat(style.paddingBottom);const space=Math.floor(total-padding-52);
    if(space<96&&host.matches('.keyboard'))return;
    const inactive=new Set([...host.querySelectorAll('*')].filter(el=>getComputedStyle(el).display==='none'));
    const original=[...host.childNodes].filter(n=>n.nodeType!==3||n.textContent.trim());if(!original.length)return;
    const grid=style.display==='grid';const columns=style.gridTemplateColumns;const gap=style.gap;const key=pageKey(screen,host,index);
    host.replaceChildren();host.classList.add('page-host');host.style.height=total+'px';host.style.setProperty('--page-space',space+'px');host.dataset.pageKey=key;
    const viewport=document.createElement('div');viewport.className='page-viewport';viewport.style.height=space+'px';viewport.style.flex='0 0 '+space+'px';host.appendChild(viewport);
    const dormant=document.createElement('div');dormant.hidden=true;host.appendChild(dormant);const pages=[];let current;
    function newPage(){current=document.createElement('div');current.className='content-page';current.style.height=space+'px';if(grid){current.style.display='grid';current.style.gridTemplateColumns=columns;current.style.gap=gap;}viewport.appendChild(current);pages.push(current);return current;}
    function fits(){return current.scrollHeight<=space+2&&current.scrollWidth<=current.clientWidth+2;}
    function put(node,depth=0) {
      if(inactive.has(node)){dormant.appendChild(node);return;}
      if(node.nodeType===3){const p=document.createElement('p');p.textContent=node.textContent;node=p;}
      let merged=null;const previous=current.lastElementChild;
      if(node.dataset?.fragmentGroup&&previous?.dataset.fragmentGroup===node.dataset.fragmentGroup){merged=[...node.childNodes];previous.append(...merged);}else current.appendChild(node);
      if(fits())return;
      const tooLarge=node.scrollHeight>space+2||node.getBoundingClientRect().height>space+2;
      if(merged)merged.forEach(n=>node.appendChild(n));else node.remove();
      if(current.childNodes.length&&!tooLarge){newPage();put(node,depth);return;}
      const protectedNode=node.matches?.('button,input,select,textarea,svg,img,canvas')||node.classList?.contains('page-host')||node.classList?.contains('setting');
      if(!protectedNode&&depth<16&&node.children.length){
        if(node.childNodes.length===1&&node.firstChild.nodeType===1){put(node.firstElementChild,depth+1);return;}
        const group='fragment-'+(++uid);const children=[...node.childNodes].filter(n=>n.nodeType!==3||n.textContent.trim());
        for(const child of children){if(inactive.has(child)){put(child,depth+1);continue;}const part=node.cloneNode(false);part.removeAttribute('id');part.classList.add('paged-fragment');part.dataset.fragmentGroup=group;part.appendChild(child);put(part,depth+1);}return;
      }
      if(!protectedNode&&node.textContent.trim().split(/\s+/).length>6&&depth<12){
        const words=node.textContent.trim().split(/\s+/);let cursor=0;
        while(cursor<words.length){let low=1,high=words.length-cursor,best=0;const part=node.cloneNode(false);part.classList.add('paged-fragment');current.appendChild(part);
          while(low<=high){const mid=Math.floor((low+high)/2);part.textContent=words.slice(cursor,cursor+mid).join(' ');if(fits()){best=mid;low=mid+1;}else high=mid-1;}
          if(!best){part.textContent=words[cursor];host.dataset.pageError='unfitted text';cursor++;}else{part.textContent=words.slice(cursor,cursor+best).join(' ');cursor+=best;}
          if(cursor<words.length)newPage();
        }return;
      }
      current.appendChild(node);host.dataset.pageError='unfitted '+(node.className||node.tagName);
    }
    newPage();original.forEach(n=>put(n));
    const nav=document.createElement('nav');nav.className='page-navigation';nav.setAttribute('aria-label','Pages du contenu');nav.innerHTML=`<button data-page-prev aria-label="Page précédente">${arrows.prev}</button><span class="page-count" aria-live="polite"></span><button data-page-next aria-label="Page suivante">${arrows.next}</button>`;host.appendChild(nav);
    pages.forEach((p,i)=>{p.dataset.pageIndex=String(i);p.dataset.fit=String(p.scrollHeight<=space+2&&p.scrollWidth<=p.clientWidth+2);p.dataset.measuredHeight=String(p.scrollHeight);p.dataset.measuredWidth=String(p.scrollWidth);});if(pages.every(p=>p.dataset.fit==='true'))host.removeAttribute('data-page-error');host.dataset.pageCount=String(pages.length);activate(host,pageMemory.get(key)||0);
  }
  function contentText(screen){const walker=document.createTreeWalker(screen,NodeFilter.SHOW_TEXT);const value=[];while(walker.nextNode()){const node=walker.currentNode;if(!node.parentElement.closest('.page-navigation'))value.push(node.textContent);}return value.join(' ').trim().split(/\s+/).sort().join('\u0001');}
  function layout(root) {
    const screens=[...root.querySelectorAll('.screen')];
    for(const screen of screens){let record=snapshots.get(screen);if(record)reset(screen,record);else{prepare(screen);restoreControls(screen);record=snapshot(screen);snapshots.set(screen,record);}
      const beforeText=contentText(screen);const beforeControls=[...screen.querySelectorAll('button,input,select,textarea')];
      const candidates=[...screen.querySelectorAll('.screen-body,.modal-body,.dialogue,.combat-result-panel,.keyboard,.name-instructions,.pc-actions')];
      candidates.reverse().forEach((host,index)=>paginate(screen,host,index));
      screen.dataset.contentPreserved=String(contentText(screen)===beforeText);screen.dataset.controlsPreserved=String(beforeControls.every(el=>screen.contains(el)));
      screen.querySelectorAll('.focused').forEach(el=>{if(!visible(el))el.classList.remove('focused');});
      if(screen.matches('.gamepad,.companion')&&!screen.querySelector('.focused')&&screen.dataset.display!=='primary'){const target=[...screen.querySelectorAll('.selected:not([disabled]),button:not([disabled])')].find(visible);if(target)target.classList.add('focused');}
    }
  }
  document.addEventListener('click',e=>{const pager=e.target.closest('[data-page-prev],[data-page-next]');if(!pager||pager.disabled)return;const host=pager.closest('.page-host');activate(host,Number(host.dataset.page)+(pager.hasAttribute('data-page-next')?1:-1),true);});
  document.addEventListener('keydown',e=>{if(!['PageDown','PageUp','[',']'].includes(e.key)||e.target.matches('input,textarea,select'))return;const screen=document.querySelector('#stage [data-display="secondary"]')||document.querySelector('#stage .screen');const focused=screen?.querySelector('.focused');const host=focused?.closest('.page-host')||screen?.querySelector('.page-host');if(!host)return;e.preventDefault();activate(host,Number(host.dataset.page)+(['PageDown',']'].includes(e.key)?1:-1),true);});
  window.AvelunePages={layout,capture,activate};
  document.fonts?.ready.then(()=>{const root=document.getElementById('stage');if(root)layout(root);});
})();
