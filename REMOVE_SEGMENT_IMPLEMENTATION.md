# Remoção de Segmento de Vídeo: Estado e Implementação

## Análise

A remoção de segmento de vídeo implementa o caso de uso **UC-VID-2** (`UC2-RemocaoSegmento.md`), seguindo a mesma arquitetura de microsserviços e mensageria assíncrona do *Trim*.

O utilizador seleciona um intervalo temporal $[t_{\text{início}}, t_{\text{fim}}]$ a eliminar de um vídeo de um projeto. O sistema:
1. Valida a consistência do corte ($0 \le t_{\text{início}} < t_{\text{fim}} \le \text{duração}$) e se a duração útil combinada restante é $\ge 1,0\text{ s}$ (RN2, RN3).
2. Valida o controlo de versões otimista (`X-Project-Version`), rejeitando com HTTP 409 em caso de conflito (REQ-VID-REM-012).
3. Permite a pré-visualização interativa no cliente (FA1), saltando o trecho marcado a eliminar no reprodutor sem render no servidor.
4. Cria e submete um job durável na fila RabbitMQ `video_remove_segment_queue`.
5. O worker Python dedicado (`videoRemoveSegmentWorker`) consome a mensagem, descarrega o vídeo original do SeaweedFS e aplica o corte via FFmpeg:
   - Se corte no início ($t_{\text{início}} = 0$): extrai a parte restante contínua $[t_{\text{fim}}, \text{duração}]$.
   - Se corte no fim ($t_{\text{fim}} = \text{duração}$): extrai a parte restante contínua $[0, t_{\text{início}}]$.
   - Se corte intermédio: extrai as duas partes e concatena-as via `filter_complex` (`concat`) com recodificação H.264/AAC.
6. Grava o novo recurso multimédia no projeto de forma não-destrutiva com nome derivado (ex.: `<nome>-cut.mp4`), preservando integralmente o ficheiro original (RN4, REQ-VID-REM-006).

## Endpoints

Todos os endpoints passam pelo API Gateway, exigem Bearer JWT e aceitam `?share=<id>`:

- `POST /projects/:owner/:project/video/:videoId/remove-segment`:
  - Cabeçalhos: `Authorization: Bearer <jwt>`, `X-Project-Version: <version>` (obrigatório).
  - Corpo: `{ "start": 1.5, "end": 3.5 }`.
  - Resposta: HTTP 202 com os metadados do job criado (`QUEUED`).
- `GET /projects/:owner/:project/video/remove-segment/jobs`: listagem dos últimos 50 jobs do projeto.
- `GET /projects/:owner/:project/video/remove-segment/jobs/:jobId`: estado, progresso (0-100%) e resultado quando concluído.
- `DELETE /projects/:owner/:project/video/remove-segment/jobs/:jobId`: cancelamento de tarefas em fila ou em processamento com libertação de quotas.

### Endpoints Internos (`X-Internal-Video-Key`)

- `GET /internal/remove-segment/:jobId`
- `POST /internal/remove-segment/:jobId/claim`
- `POST /internal/remove-segment/:jobId/progress`
- `POST /internal/remove-segment/:jobId/storage/reserve`
- `POST /internal/remove-segment/:jobId/storage/release`
- `POST /internal/remove-segment/:jobId/complete`
- `POST /internal/remove-segment/:jobId/fail`

## Rastreabilidade de Requisitos (UC2-RemocaoSegmento)

| Requisito | Descrição | Implementação / Evidência |
| --- | --- | --- |
| `REQ-VID-REM-001` | Seleção de vídeo para remoção de segmento | Integrado no dropdown do vídeo com modal `RemoveSegmentVideoDialog`. |
| `REQ-VID-REM-002` | Validação de consistência do intervalo | Validação no frontend e na API (`0 <= start < end <= duration`). Código de erro: `INVALID_INTERVAL`. |
| `REQ-VID-REM-003` | Duração útil restante $\ge 1,0\text{ s}$ | Validação no diálogo e no backend; erro `DURATION_TOO_SHORT` quando $D - (end - start) < 1,0\text{ s}$. |
| `REQ-VID-REM-004` | Submissão assíncrona ao clicar em Aplicar | Criação de job `RemoveSegmentJob` e publicação na fila RabbitMQ `video_remove_segment_queue`. |
| `REQ-VID-REM-005` | Processamento assíncrono e concatenação no worker | Contentor `video_remove_segment_worker` executa FFmpeg com H.264 / AAC preservando/unindo trechos restantes. |
| `REQ-VID-REM-006` | Edição não-destrutiva e nome derivado | Vídeo original preservado intacto (hash SHA-256 verificado); novo ficheiro adicionado com `<nome>-cut.mp4`. |
| `REQ-VID-REM-007` | Fiabilidade e integridade em caso de falha/cancelamento | Reversão de quotas e limpeza de ficheiros temporários em caso de falha ou cancelamento (`DELETE`). |
| `REQ-VID-REM-008` | Pré-visualização local simulada no reprodutor | Simulação FA1 no reprodutor HTML5 saltando automaticamente o intervalo marcado durante o playback. |
| `REQ-VID-REM-009` | Descarte/cancelamento de operação pendente (*staged*) | Diálogo cancelável localmente antes de submeter e cancelamento assíncrono via `DELETE`. |
| `REQ-VID-REM-010` | Autenticação JWT e autorização no projeto | Validação rigorosa de token, permissões de dono e links partilhados (`read` vs `edit`). |
| `REQ-VID-REM-011` | Validação de formato/codec suportado | Rejeição com HTTP 415 `UNSUPPORTED_VIDEO` caso o codec não seja H.264 ou content-type não seja `video/mp4`. |
| `REQ-VID-REM-012` | Controlo de versões otimista (`X-Project-Version`) | Exigência obrigatória do cabeçalho na submissão, devolvendo HTTP 428 se ausente e HTTP 409 em caso de conflito. |
| `REQ-VID-REM-013` | Disponibilização do vídeo resultante no editor | Invalidação de cache React Query e disponibilização imediata do novo vídeo e do playback no editor. |

## Validação Realizada em 17/10/2026

1. **Sintaxe e Tipos**:
   - `docker compose config --quiet`: passou.
   - `python3 -m py_compile videoRemoveSegmentWorker/worker.py tests/remove_segment_integration.py`: passou.
   - `node --check` em todas as rotas e utilitários criados/modificados: passou.
   - `bun run build` no frontend Next.js: passou sem erros.

2. **Testes de Integração**:
   - `python3 tests/remove_segment_integration.py`: **passou com sucesso**.
     - Testou upload de vídeo original (6 s com áudio AAC e vídeo H.264).
     - Validou integridade SHA-256 do original antes e depois.
     - Validou exigência de `X-Project-Version` (428).
     - Validou deteção de conflito de concorrência com versão desatualizada (409).
     - Validou bloqueio de corte que resulte em menos de 1,0 s (400 `DURATION_TOO_SHORT`).
     - Validou bloqueio de intervalo invertido (400 `INVALID_INTERVAL`).
     - Processou corte intermédio (1,5 a 3,5 s), gerando ficheiro derivado `-cut.mp4` com ~4,0 s, vídeo H.264 e áudio AAC.
     - Processou corte no início (0,0 a 2,0 s -> restante ~4,0 s).
     - Processou corte no fim (4,0 a 6,0 s -> restante ~4,0 s).
     - Validou permissões de partilha (utilizador com permissão `read` bloqueado com 403 `EDIT_REQUIRED`; utilizador com permissão `edit` autorizado).
     - Validou cancelamento de job em fila com reposição de quota diária.
     - Processou corte em vídeo sem áudio (preservando saída sem canal de áudio espúrio).
     - Limpeza final de utilizadores, projetos e documentos de teste.
   - `python3 tests/trim_integration.py`: **passou com sucesso** em regressão (sem impacto no serviço Trim existente).
