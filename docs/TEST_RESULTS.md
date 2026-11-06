# Resultado da regressão — 2026-11-06

**Suite principal atual: 183 PASS, 0 FAIL, 0 SKIP.** Executada por `make test-all` sobre o stack Docker Compose local, Node 22.22.1, Python 3.14.4, Chromium e Firefox. Base Git `0523102` com alterações locais; executor Codex. Foram corridas as suites Node (18), Python (83), API (36), integração (30), segurança (3), E2E (11), resiliência (1) e performance (1). A execução confirma a reorganização por pastas, sem alterações ao comportamento dos testes.

**Testes que falham: 13 casos separados**, repetidos após a reorganização por `make test-known-failures` com 0 PASS e 13 FAIL (`R-20261106-194934-known-failures`; saída 1 esperada). Permanecem em [tests/KNOWN_FAILURES.md](../tests/KNOWN_FAILURES.md), que distingue exigências do relatório e expectativas anteriores mantidas nos casos que o PDF não especifica. Estes resultados não entram nos 183 testes da suite principal. Os casos ajustados durante a auditoria foram reexecutados por seleção e continuam a falhar. O caso `PLAN-02` foi ainda alinhado com `REQ-VID-CANCEL-002` do PDF de requisitos: após cancelar, confirma ausência de resultado parcial e espera o saldo anterior; a reexecução `R-20261106-192244-known-failures` continua a falhar porque a operação não é reposta. O comando de falhas conhecidas sai com código diferente de zero enquanto estas persistirem.

Relatórios da suite principal: `tests/reports/20261106-194704-node.xml`, `20261106-194705-python.xml`, `20261106-194747-api.xml`, `20261106-194802-integration.xml`, `20261106-194845-security.xml`, `20261106-194848-e2e.xml`, `20261106-194912-resilience.xml` e `20261106-194919-performance.xml`. São artefactos locais ignorados pelo Git; a checklist conserva o histórico de execução. As contas de teste registadas foram limpas após cada suite.

O caso `PROJ-02/STORE-02` foi esclarecido: o teste usa uma imagem PNG. O PDF preserva os vídeos na biblioteca ao apagar um projeto, mas descreve que na solução de base apagar o projeto retirava as imagens ao utilizador. O teste de imagem mantém-se como falha conhecida.

A coluna **Última execução** da checklist conserva `FAIL` para requisitos com falhas conhecidas, mesmo quando os testes restantes do mesmo requisito passam. `PASS` nos 183 testes significa apenas que a suite principal passou. A cobertura parcial restante está descrita na checklist.

## Execução anterior, antes de isolar as falhas conhecidas — 2026-11-06

Execução local através do nginx HTTPS, serviços Docker Compose existentes, Node 22.22.1, Python 3.14.4, Chromium e Firefox. Commit base `0523102`, com alterações locais. Executor: Codex. Apenas testes, configuração e documentação foram alterados; os defeitos da aplicação permanecem por corrigir.

**194 testes distintos: 181 PASS e 13 FAIL.** Nenhum teste bloqueado nesta consolidação.

| Suite | PASS | FAIL |
| --- | --- | --- |
| node | 18 | 0 |
| python | 83 | 0 |
| api | 67 | 12 |
| e2e | 11 | 0 |
| resilience | 1 | 1 |
| performance | 1 | 0 |

A execução `make test-all` foi seguida de reexecução de Python após corrigir uma importação no teste, sete testes adicionais de API e reexecução completa de E2E. Os resultados abaixo usam essas últimas evidências, sem contar repetições. Os relatórios originais e as tentativas anteriores permanecem no histórico.

## Falhas reproduzidas

- [AUTH-02] an unrelated user cannot read a private account profile — `tests/reports/20261106-184016-api.xml`.
- [AUTH-03.1] profile name and email survive a new login — `tests/reports/20261106-184016-api.xml`.
- [AUTH-03.4] deleting an account removes projects and original media — `tests/reports/20261106-184016-api.xml`.
- [ASSIST-02] URL-signing failure cleans up uploaded assistant previews — `tests/reports/20261106-184016-api.xml`.
- [PLAN-02] cancelling a video run refunds its reserved operations — `tests/reports/20261106-184016-api.xml`.
- [UP-01] image endpoint rejects video and corrupt image contents — `tests/reports/20261106-184016-api.xml`.
- [EDGE-01] Unicode filename survives upload and duplicate name is rejected — `tests/reports/20261106-184016-api.xml`.
- [AUTH-04] unauthenticated sockets cannot receive project operations — `tests/reports/20261106-184016-api.xml`.
- [AUTH-04] a valid account cannot subscribe to someone elses project — `tests/reports/20261106-184016-api.xml`.
- [STORE-01] exposed storage facade cannot issue a private URL without authentication — `tests/reports/20261106-184016-api.xml`.
- [PROJ-02,STORE-02] coverage: project deletion removes original objects — `tests/reports/20261106-184840-api.xml`.
- [PIPE-02] coverage: invalid dimensions are rejected before entering the pipeline — `tests/reports/20261106-184840-api.xml`.
- [RUN-03] isolated video worker resumes processing after broker restart — `tests/reports/20261106-184240-resilience.xml`.

A falha de reembolso (`PLAN-02`) corresponde a `REQ-VID-CANCEL-002`: cancelar deve repor as operações reservadas e descartar resultados parciais. O próprio documento de requisitos marca esta parte como não implementada. As restantes falhas registam diferenças concretas de autorização, persistência, validação, limpeza de objetos ou recuperação do consumidor após reinício do broker.

## Instabilidade observada

O E2E de editar/aplicar/obter resultados falhou uma vez por não publicar resultados em 60 segundos e passou na reexecução. O cenário de partilha também apresentou resultados diferentes entre tentativas de desenvolvimento. A última suite E2E tem 11 PASS, mas estes percursos precisam de investigação de sincronização; um rerun verde não prova ausência de intermitência. Não foram ativadas tentativas automáticas para esconder falhas.

## Cobertura e limites

Foram executados testes reais de todos os workers de imagem, vídeos com áudio, edição temporal, extração de frames, preview, OCR e legendas com fala real. Também foram exercitados perfis, quotas, pagamentos mock, presets, partilha, concorrência, autorização, exports, browsers, backup/restauro Mongo e reinício de broker isolado.

**Ainda não está concluída toda a cobertura do catálogo.** As linhas `Parcial` identificam as lacunas concretas: entre outras, recriação/persistência S3, todos os consumidores após reinício, falha de S3 durante processamento, acessibilidade do percurso completo, edição mobile e memória/carga sustentada. O teste de performance é uma medição local limitada, não uma certificação de capacidade. Mongodump não inclui os objetos S3. Não se marcou cobertura completa apenas porque um teste passou.

## Repetir e registar

`make test-all` executava então as suites que incluíam os 13 casos agora isolados e devolvia erro. `scripts/regression.py` atualiza a coluna de última execução e o histórico, seguindo `tests/TEST_EXECUTION_PROTOCOL.md`. As contas criadas são registadas por ID e limpas com os seus dados; os reinícios usam containers descartáveis, sem reiniciar o broker da aplicação.

Relatórios usados nesta consolidação (ignorados pelo Git; este resumo é persistente):

- `tests/reports/20261106-183936-node.xml` e `.log`.
- `tests/reports/20261106-184811-python.xml` e `.log`.
- `tests/reports/20261106-184016-api.xml` e `.log`.
- `tests/reports/20261106-184840-api.xml` e `.log`.
- `tests/reports/20261106-184900-e2e.xml` e `.log`.
- `tests/reports/20261106-184240-resilience.xml` e `.log`.
- `tests/reports/20261106-184428-performance.xml` e `.log`.
