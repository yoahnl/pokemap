import test from 'node:test';
import assert from 'node:assert/strict';
import {initialModel, project, sessionReducer as reduce} from './src/components/generated/SessionReferenceModel.ts';

for (const profile of ['twoD', 'threeD']) {
  test(`${profile}: the portable catalogue cannot edit or save`, () => {
    const original = initialModel(profile, 'readonly');
    assert.equal(reduce(original, {type: 'title', title: 'Changed'}), original);
    assert.equal(reduce(original, {type: 'saveClose'}), original);
    const selected = reduce(original, {type: 'select', id: project(profile).ids[1]});
    assert.equal(selected.selection, project(profile).ids[1]);
    assert.equal(selected.dirty, false);
  });

  test(`${profile}: recovery failure retains the operation and can retry`, () => {
    const original = initialModel(profile, 'recovery');
    const started = reduce(original, {type: 'recover'});
    assert.equal(started.stage, 'working');
    assert.equal(reduce(started, {type: 'close'}), started);
    const failed = reduce(started, {type: 'recoverDone', failed: true});
    assert.equal(failed.stage, 'ready');
    assert.equal(failed.recovery, 'resume');
    assert.match(failed.error, /origine.*conservés/);
    const retried = reduce(failed, {type: 'recover'});
    assert.equal(reduce(retried, {type: 'recoverDone', failed: false}).stage, 'recovered');
  });

  test(`${profile}: rollback waits for explicit confirmation`, () => {
    const selected = reduce(initialModel(profile, 'recovery'), {type: 'chooseRecovery', recovery: 'rollback'});
    const pending = reduce(selected, {type: 'recover'});
    assert.equal(pending.stage, 'ready');
    assert.equal(pending.dialog, 'rollback');
    const canceled = reduce(pending, {type: 'cancel'});
    assert.equal(canceled.stage, 'ready');
    assert.equal(canceled.recovery, 'rollback');
    const confirmed = reduce(reduce(canceled, {type: 'recover'}), {type: 'confirmRollback'});
    assert.equal(confirmed.stage, 'working');
    assert.equal(confirmed.dialog, null);
  });

  test(`${profile}: keeping a conflicting session does not allow saving`, () => {
    const original = initialModel(profile, 'conflict');
    const kept = reduce(original, {type: 'keep'});
    assert.equal(kept.title, original.title);
    assert.equal(kept.dirty, true);
    assert.equal(reduce(kept, {type: 'saveClose'}), kept);
    const requested = reduce(kept, {type: 'reload'});
    assert.equal(requested.title, original.title);
    assert.equal(requested.dirty, true);
    const canceled = reduce(requested, {type: 'cancel'});
    assert.equal(canceled.title, original.title);
    const reloaded = reduce(reduce(canceled, {type: 'reload'}), {type: 'confirmReload'});
    assert.equal(reloaded.title, 'Arrivée au laboratoire');
    assert.equal(reloaded.dirty, false);
    assert.equal(reloaded.stage, 'reloaded');
  });

  test(`${profile}: canceling closure keeps the draft and selection`, () => {
    const original = reduce(reduce(initialModel(profile, 'draft'), {type: 'title', title: 'Mon brouillon'}), {type: 'select', id: project(profile).ids[0]});
    const canceled = reduce(original, {type: 'cancel'});
    assert.equal(canceled.stage, 'ready');
    assert.equal(canceled.dirty, true);
    assert.equal(canceled.title, 'Mon brouillon');
    assert.equal(canceled.selection, original.selection);
    assert.equal(reduce(canceled, {type: 'confirmDiscard'}), canceled);
    assert.equal(reduce(reduce(canceled, {type: 'discard'}), {type: 'confirmDiscard'}).stage, 'closed');
  });

  test(`${profile}: a failed save cannot close or discard the draft`, () => {
    const original = reduce(initialModel(profile, 'draft'), {type: 'title', title: 'Mon brouillon'});
    const saving = reduce(original, {type: 'saveClose'});
    assert.equal(saving.stage, 'saving');
    for (const action of [{type: 'close'}, {type: 'discard'}, {type: 'cancel'}, {type: 'profile', profile: profile === 'twoD' ? 'threeD' : 'twoD'}]) assert.equal(reduce(saving, action), saving);
    const failed = reduce(saving, {type: 'saveDone', failed: true});
    assert.equal(failed.title, 'Mon brouillon');
    assert.equal(failed.dirty, true);
    assert.equal(failed.stage, 'ready');
    assert.equal(failed.dialog, 'close');
    assert.match(failed.error, /toujours ouvert/);
    const closed = reduce(reduce(failed, {type: 'saveClose'}), {type: 'saveDone', failed: false});
    assert.equal(closed.stage, 'closed');
    assert.equal(closed.dirty, false);
    assert.equal(closed.dialog, null);
  });

  test(`${profile}: changing project requires a draft decision and clears old selection`, () => {
    const next = profile === 'twoD' ? 'threeD' : 'twoD';
    const original = reduce(reduce(initialModel(profile, 'draft'), {type: 'title', title: 'Brouillon du précédent projet'}), {type: 'select', id: project(profile).ids[0]});
    const pending = reduce(original, {type: 'profile', profile: next});
    assert.equal(pending.profile, profile);
    assert.equal(pending.dialog, 'profile');
    assert.equal(pending.title, original.title);
    const canceled = reduce(pending, {type: 'cancel'});
    assert.equal(canceled.profile, profile);
    assert.equal(canceled.selection, original.selection);
    const changed = reduce(reduce(canceled, {type: 'profile', profile: next}), {type: 'confirmProfile'});
    assert.equal(changed.profile, next);
    assert.equal(changed.selection, null);
    assert.notEqual(changed.title, original.title);
    assert.equal(reduce(changed, {type: 'select', id: original.selection}), changed);
  });
}
