# Agent Rules — PokeMap

## 1. Truthfulness

- **Never claim a lot is complete unless the acceptance criteria are actually proven.**
- **Never replace evidence with confidence.**
- If a requirement is not met, say so clearly.
- Every claim must be backed by executable evidence (commands run, output shown).

## 2. Tests

- **Never write fake tests.**
- Forbidden patterns include:
  - `expect(true, isTrue)`
  - `expect(1, 1)`
  - tests that only prove compilation while claiming to prove behavior
- Integration tests must exercise the real integration path, or explicitly state what is not covered.
- Unit tests must test actual logic, not just type compilation.
- If a test cannot cover the full path, document exactly what is and is not covered.

## 2.1. Production logic vs test helpers

- **A test helper must NOT duplicate production integration logic and then claim to prove the production path.**
- If a helper represents production behavior, it must live in **production code** and be used by the production code.
- Tests may use helper builders for fixtures, but **must NOT duplicate the behavior under test**.
- Example of violation: Creating a helper in the test file that duplicates the logic of a production callback, then testing only that helper and claiming the production callback works.

## 3. Repository discipline

- **Do not leave temporary files at the repository root.**
- Plans, reports and evidence files must go into the appropriate `reports/` directory unless the file is a deliberate project-level document.
- Do not create duplicate architecture files by guessing names.
- Temporary analysis files (e.g., `mistralplan.md`, `mistral_lot20_plan.md`) belong in `reports/pathPattern/` or should be removed.

## 4. Git discipline

- **Git is strictly read-only unless the human explicitly requests a write operation.**
- Do not run: `git add`, `git commit`, `git push`, `git reset`, `git restore`, `git stash`, `git checkout`, `git switch`, `git merge`, `git rebase`, `git rm`
- Allowed commands: `git status`, `git diff`, `git log`, `git show`, `git ls-files`
- Always document git status before and after changes.

## 5. Architecture

- **Do not invent providers, services, repositories, files or APIs.**
- Audit existing code before writing new code.
- Prefer the smallest change that fits the existing architecture.
- Do not duplicate logic that already exists in another package.
- Respect package boundaries: `map_core` for models, `map_editor` for editor UI, `map_runtime` for game execution.

## 6. Scope control

- Follow the lot scope exactly as defined in the prompt.
- Do not jump to older roadmaps or assumptions from previous lots.
- Do not start work on Tall Grass, Surface Studio, TSX/TMX, runtime, painter, gameplay or battle unless the current prompt explicitly asks for it.
- Do not modify `map_core`, `ProjectManifest`, or codecs unless explicitly requested.
- Do not add disk persistence unless explicitly requested.

## 7. Evidence

- Reports must include real commands and real results.
- Do not use "see the repo", "truncated output", "rerun git diff", or equivalent as a substitute for required evidence.
- If a command cannot be run, explain why.
- Include complete command output, not just summaries.
- Evidence Pack must contain: git status, git diff, test outputs, analyze outputs.

## 8. Self-review

- Every lot must include an honest self-review section.
- The self-review must list what was proven and what was not proven.
- If a previous mistake is found, document it and update this rules file when appropriate.
- Critically review: Did I prove what I claimed? Did I test what I implemented?

## 9. Test-driven development

- Write tests before implementation when possible.
- Tests must fail first (RED phase) before passing (GREEN phase).
- If code exists before tests, delete it and start over with TDD.
- One behavior per test, clear test names describing behavior not implementation.

## 10. Code quality

- Run static analysis before claiming completion: `dart analyze` or `flutter analyze`.
- Fix all errors before claiming completion.
- Warnings should be addressed or explicitly documented as non-critical.
- Follow existing code style and patterns in the touched files.

## 11. Reporting

- Final reports must be complete and self-contained.
- Include: changed files, created files, deleted files, commands run, exact test totals, known limitations, remaining risks.
- Reports go in `reports/<domain>/` with descriptive names including lot number and version.
- Use Evidence Pack format for lot reports.

## 12. PathPattern-specific guidance

- Legacy PathPattern lots use existing manifest operations from `map_core`.
- Do not create new save architectures for PathPattern without explicit request.
- The existing flow: PathStudioWorkspace -> PathStudioPanel -> callback -> upsertProjectPathPatternPreset -> applyInMemoryProjectManifest.
- "Depuis un path existant" flow must use existing ProjectPathPreset as base.
- "Nouveau chemin" flow must remain blocked for save until explicitly implemented.

## 13. When in doubt

- Stop and ask for clarification rather than guessing.
- Document assumptions explicitly.
- Prefer the smallest, safest interpretation of ambiguous requirements.
- If evidence is missing, state what evidence would prove the claim.
