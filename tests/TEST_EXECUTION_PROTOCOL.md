# Test execution record for coding agents

This file is an instruction for every AI agent that runs tests in this repository. The regression catalog is `docs/REGRESSION_CHECKLIST.md`.

Prefer the `make test-*` commands backed by `scripts/regression.py`: they write JUnit/log reports, update the catalog, aggregate failures across suites, and clean up only recorded test accounts. When running a test command directly, perform the same recording steps below manually. Do not mark skipped tests as successful.

Known failing tests live in `tests/known_failures/` and are documented in `tests/KNOWN_FAILURES.md`. The normal runner excludes them from totals and preserves their `FAIL` catalog cells; `make test-known-failures` executes and records them separately. Do not mark a known failing requirement resolved because its passing subset passed.

## Required after every test command

1. Record the exact command, execution time (ISO 8601 with timezone), commit or working-tree state, test count and outcome in the **Execution history** section of the regression checklist. Identify the runtime and environment when relevant (for example, host Node or Docker Compose).
2. Identify the catalog IDs **actually exercised by the tests that ran**. Update only their **Última execução** cells. Do not infer that an entire requirement passed because a test file or suite passed.
3. Use `PASS` only for assertions that passed, `FAIL` for failed assertions, and `BLOCKED` when the selected tests could not run because of missing dependencies or environment failure. Include the run ID in each updated cell. Keep `Parcial` or `Completa` only in **Cobertura / referência**, never in **Última execução**. A `PASS` result reports the tests that ran, not approval of the whole requirement.
4. If some tests in a suite fail, inspect the individual test outcomes. Update each mapped row according to its own tests, not the suite's overall exit code. If a test is skipped, not discovered, or unrelated to a row, do not mark that row `PASS`. Record skips and empty suites in the history.
5. Leave unrelated rows and their prior execution results unchanged. When adding a new test, add or refine its catalog ID and coverage reference. Split a broad row into stable sub-IDs if this is needed to state exactly what was verified.
6. Keep the log concise and auditable. Link to a report in `tests/reports/` when available, but also record the command and summary in Markdown because generated reports are Git-ignored.

**Cell format:** `PASS [run ID]`, `FAIL [run ID]` or `BLOCKED [run ID]`. Automated IDs use `R-YYYYMMDD-HHMMSS-suite` in UTC; earlier records use minute precision. For manual checks, add `manual` and the executor in the history.

## Example

| ID | Cobertura / referência | Última execução |
| --- | --- | --- |
| UP-02.1 | Completa: `projects/tests/video-validation.test.js` | PASS [R-20261106-1811] |
| UP-02.2 | Inexistente | Não executado |

The first row reports the validator tests. It does not imply that the upload endpoint in the second row was tested.
