import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('control center exposes guarded preflight and publish choices',
      () async {
    final workflow = await File(
      '../../.github/workflows/release_control_center.yml',
    ).readAsString();

    expect(workflow, contains('name: Release Control Center'));
    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains('product:'));
    expect(workflow, contains('- pokemap'));
    expect(workflow, contains('- avelune'));
    expect(workflow, contains('- both'));
    expect(workflow, contains('action:'));
    expect(workflow, contains('- preflight'));
    expect(workflow, contains('- publish'));
    expect(workflow, contains('pokemap_version:'));
    expect(workflow, contains('avelune_version:'));
    expect(workflow, contains('confirmation:'));
  });

  test('control center validates requests before dispatching product workflows',
      () async {
    final workflow = await File(
      '../../.github/workflows/release_control_center.yml',
    ).readAsString();

    expect(
      workflow,
      contains(
        'dart run tool/release_control_center/'
        'validate_release_request.dart',
      ),
    );
    expect(workflow, contains('actions: write'));
    expect(workflow, contains('contents: read'));
    final validationJob = workflow.substring(
      workflow.indexOf('  validate-request:'),
      workflow.indexOf('  dispatch-preflight:'),
    );
    expect(validationJob, isNot(contains('actions: write')));
    expect(
      validationJob,
      contains(r'test "$GITHUB_REF" = refs/heads/main'),
    );
    expect(workflow, contains('environment: pokemap-release'));
    expect(workflow, contains('git ls-remote --exit-code --tags origin'));
    expect(
      workflow,
      contains(r'REQUEST_PRODUCT: ${{ inputs.product }}'),
    );
    expect(
      workflow,
      contains(r'REQUEST_ACTION: ${{ inputs.action }}'),
    );
    expect(
      workflow,
      contains(r'REQUEST_POKEMAP_VERSION: ${{ inputs.pokemap_version }}'),
    );
    expect(
      workflow,
      contains(r'REQUEST_AVELUNE_VERSION: ${{ inputs.avelune_version }}'),
    );
    expect(
      workflow,
      contains(r'REQUEST_CONFIRMATION: ${{ inputs.confirmation }}'),
    );
    expect(workflow, contains(r'--pokemap-version "$REQUEST_POKEMAP_VERSION"'));
    expect(workflow, contains(r'--avelune-version "$REQUEST_AVELUNE_VERSION"'));
    expect(workflow, contains(r'--confirmation "$REQUEST_CONFIRMATION"'));
    expect(workflow, contains(r'--product "$REQUEST_PRODUCT"'));
    expect(workflow, contains(r'--action "$REQUEST_ACTION"'));
    expect(
      workflow,
      isNot(contains(r'--confirmation "${{ inputs.confirmation }}"')),
    );
    expect(
      workflow,
      isNot(contains(r'--pokemap-version "${{ inputs.pokemap_version }}"')),
    );
    expect(
      workflow,
      isNot(contains(r'--avelune-version "${{ inputs.avelune_version }}"')),
    );
    expect(
      workflow,
      contains('gh workflow run pokemap_desktop_release.yml --ref main'),
    );
    expect(
      workflow,
      contains('gh workflow run avelune_android_release.yml --ref main'),
    );
    expect(workflow, contains(r'-f mode="$ACTION"'));
    expect(workflow, contains(r'-f confirmation="$CONFIRMATION"'));
    final publicationJob = workflow.substring(
      workflow.indexOf('  dispatch-publication:'),
    );
    expect(publicationJob, contains('ACTION: release'));
    expect(publicationJob, isNot(contains('ACTION: publish')));
    expect(workflow, isNot(contains('RELEASE_AUTOMATION_TOKEN')));
  });

  test('product workflows preserve tag releases and accept guarded dispatches',
      () async {
    final desktop = await File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsString();
    final avelune = await File(
      '../../.github/workflows/avelune_android_release.yml',
    ).readAsString();

    for (final workflow in <String>[desktop, avelune]) {
      expect(workflow, contains('mode:'));
      expect(workflow, contains('version:'));
      expect(workflow, contains('confirmation:'));
      expect(workflow, contains("inputs.mode == 'release'"));
      expect(
        workflow,
        contains(r'test "$GITHUB_REF" = refs/heads/main'),
      );
      expect(
        workflow,
        contains(r'REQUEST_CONFIRMATION: ${{ inputs.confirmation }}'),
      );
      expect(
        workflow,
        contains(r'REQUESTED_VERSION: ${{ inputs.version }}'),
      );
      expect(
        workflow,
        contains(r'test "$REQUEST_CONFIRMATION" = RELEASE'),
      );
      expect(
        workflow,
        contains(r'test -n "$REQUESTED_VERSION"'),
      );
      expect(
        workflow,
        isNot(contains(r'test "${{ inputs.confirmation }}" = RELEASE')),
      );
      expect(
        workflow,
        contains('git ls-remote --exit-code --tags origin'),
      );
    }

    expect(desktop, contains('tags: ["pokemap-v*"]'));
    expect(desktop, contains("format('pokemap-v{0}', inputs.version)"));
    expect(avelune, contains('tags: ["avelune-v*"]'));
    expect(avelune, contains("format('avelune-v{0}', inputs.version)"));
  });
}
