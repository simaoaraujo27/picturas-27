# Recorte temporal de vídeo: estado

## Análise

O frontend Next.js usa o API Gateway, que encaminha para `projects`. Os metadados estão no MongoDB e os vídeos no SeaweedFS via `mediaStorageService`. O upload existente valida MP4/H.264 com ffprobe, transmite sem carregar todo o vídeo em RAM e limita **cada ficheiro** a 1 GB (Free) ou 5 GB (Premium). Projetos têm vídeos e partilhas `read`/`edit`. RabbitMQ e workers Python já processam imagens. `videoConsumerExample` demonstra o download privado, mas não executa Trim. O `wsGateway` serve imagens; o Trim usa polling de 4 segundos.

Foram reutilizados autenticação, permissões, modelos de projeto, armazenamento, Gateway e RabbitMQ. Foram acrescentados `TrimJob`, rotas, fila e worker FFmpeg. O vídeo resultante fica no projeto original. O documento `usecaseSImao.md` permanece intacto; o seu identificador UC-VID-001 não foi alterado.

## Endpoints

Todos passam pelo Gateway, requerem Bearer JWT e aceitam `?share=<id>` conforme a partilha:

- `POST /projects/:owner/:project/video/:videoId/trim` com `{ "start": 1.25, "end": 3.50, "mode": "precise" }`: cria Job ID e devolve 202.
- `GET /projects/:owner/:project/video/trim/jobs`: últimos 50 jobs.
- `GET /projects/:owner/:project/video/trim/jobs/:jobId`: estado e progresso.
- Quando concluído, o detalhe do job inclui `result` com `id`, `duration`, `width`, `height`, `sourceVideoId` e `jobId`. A listagem do projeto expõe os mesmos metadados de duração, resolução e proveniência no vídeo resultante.
- `DELETE /projects/:owner/:project/video/trim/jobs/:jobId`: cancelamento.
- `GET /projects/:owner/:project/video/storage`: bytes de vídeo usados e limite da conta.
- `GET /projects/:owner/:project/video/:videoId/playback`: obtém URL temporária de reprodução.
- `GET /projects/:owner/:project/video/:videoId/play`: transmite MP4 com HTTP Range usando um cookie HttpOnly, Secure e SameSite Strict de cinco minutos; as permissões são verificadas de novo. O token não aparece no URL nem nos logs de acesso.

O worker recebe só o Job ID na fila, consulta o job no serviço de projetos, descarrega e valida o original, executa FFmpeg numa diretoria temporária, valida a saída e regista um novo vídeo no projeto. Os estados são QUEUED, PROCESSING, COMPLETED, FAILED e CANCELLED. O original não é modificado. Há uma repetição para falhas recuperáveis e jobs com lease expirado; jobs em fila sem consumidor são republicados. O serviço de utilizadores reserva uma operação Free por Job ID, confirma-a no sucesso e devolve-a em falha ou cancelamento. O serviço de projetos mantém uma quota de armazenamento de **vídeos** por proprietário, incluindo uploads e resultados de Trim.

## Rastreabilidade

| Estado | Requisitos | Evidência ou limite |
| --- | --- | --- |
| Implementado e verificado no teste local | 005, 007, 011, 013, 014, 027, 028 | Quota Free, modo rápido, hash do original, resultado associado, permissões e Docker. |
| Implementado, com verificação parcial | 001, 002, 003, 004, 006, 008, 009, 010, 012, 016, 017, 018, 019, 020, 021, 022, 023, 024 | A interface tem dois marcadores sem área destacada; Job ID é ObjectId e não UUID; faltam testes de grandes volumes, corrupção, timeout, cancelamento em execução e expiração; o upload aceita áudio não AAC e o Trim recodifica para AAC; quota acumulada cobre vídeos. |
| Ainda não demonstrado | 015, 025, 026 | Falta notificação global após sair da página e medição dos objetivos de latência p95 e desempenho em vídeo 1080p/60s. |

O teste `tests/trim_integration.py` cobre upload MP4/H.264, recorte com áudio, recorte sem áudio, início em zero, duração mínima de um segundo, centésimos, intervalo inválido, integridade do original, quota Free esgotada, cancelamento em fila com estorno, reprodução Range com cookie temporário, permissões de leitura/edição, recorte rápido Premium com keyframes e rejeição sem keyframes. Os dados de teste são removidos no fim.

## Validação realizada em 14/10/2026

- `docker compose config --quiet`: passou.
- `docker compose build api_gateway projects users video_trim_worker frontend`: passou; `projects` e `frontend` foram recompilados após o último ajuste de metadados e interface.
- `python3 tests/trim_integration.py`: passou no ambiente Compose local, com `remainingOperations: 0` depois de cinco Trims Free e resultado com áudio de 2,52 s para um intervalo pedido de 2,50 s.
- Serviços `api_gateway`, `projects`, `users`, `frontend` e `video_trim_worker`: em execução após o teste.
- Diretoria temporária do worker: sem diretórios `picturas-trim-*` residuais após o teste.
- `git diff --check`: passou. Não foi criado commit.

Não foram medidos p95 de submissão, desempenho em 1080p/60s, interrupção forçada do worker, cancelamento durante FFmpeg, limite real de 1/5 GB nem a expiração de cinco minutos do cookie. Esses cenários continuam pendentes de verificação.

## Validação final realizada em 15/10/2026

- `git status --short` e `git diff --stat`: alterações anteriores preservadas; sem commit ou push. `git diff --check`: passou.
- `docker compose config --quiet`, `node --check` nas rotas alteradas e `python3 -m py_compile` no worker e no teste: passaram.
- `docker compose build api_gateway projects users video_trim_worker frontend`: passou. Após acrescentar o resultado explícito ao endpoint do job, `docker compose build projects --quiet` também passou e o serviço foi recriado.
- `python3 tests/trim_integration.py`: passou **duas vezes** nesta data, a segunda após a alteração final. A API devolveu `result.duration > 0`, resolução 320×240, `result.sourceVideoId` igual ao vídeo de origem e `result.jobId` igual ao ID do job. O ficheiro descarregado apresentou 2,52 s para o pedido 1,25–3,75 s, vídeo H.264 e áudio AAC. O vídeo resultante apareceu na lista do projeto; o SHA-256 do original manteve-se. Foram exercitados upload, listagem, download, eliminação e redução de quota, recorte sem áudio, quota diária Free, cancelamento em fila com estorno, permissões de partilha `read`/`edit`, modo rápido Premium e reprodução HTTP Range.
- Regressão de imagens por API Gateway: passou. Upload PNG 24×24, inclusão de `brightness` com fator 1,2, processamento pela fila/worker Python e download do ZIP resultante; o pixel de teste passou de `(50, 100, 150)` para `(60, 120, 180)`.
- Frontend: compilação Next.js passou e `GET https://localhost:8080/` devolveu HTTP 200. **Não foi realizado teste interativo em browser**; a interface de Trim necessita ainda dessa verificação manual.
- RabbitMQ: `video_trim_queue` e `brightness_queue` tinham cada uma um consumidor e zero mensagens após os testes. Worker de Trim sem diretórios temporários `picturas-trim-*` residuais. API Gateway, projetos, utilizadores, frontend, RabbitMQ, SeaweedFS, MongoDB, armazenamento de imagens e workers relevantes estavam em execução.
- Ao retomar, RabbitMQ e três MongoDB estavam parados após reinício do Docker, provocando reinícios dos serviços dependentes. Foram iniciados. O contentor legado `picturas-video_trim-1` voltou a consumir a mesma fila com contrato incompatível e foi parado; permanece parado como órfão do Compose atual. Não foi removido.

O teste de imagem foi executado como script temporário na linha de comandos e apagou o utilizador/projeto de teste. O teste de Trim elimina os vídeos, projeto e utilizadores temporários no final.

## Limitações por resolver

Esta implementação **ainda não cobre o caso de uso completo**:

- A quota acumulada conta vídeos, não ficheiros de imagem. Os 1/5 GB por ficheiro de upload continuam independentes do teto global de vídeos. A reconciliação de quotas com imagens exigiria metadados de tamanho que o modelo atual de imagens não fornece.
- O Job ID público é um ObjectId MongoDB único, enquanto o documento pede UUID. Uma alteração desse contrato deve incluir migração dos jobs já persistidos.
- O limite de 10 minutos cobre a execução do FFmpeg; download e upload têm timeouts separados. Uma falha de energia entre upload e registo ainda pode deixar um objeto órfão; falta reconciliação periódica com o SeaweedFS.
- O modo rápido Premium exige keyframes nos pontos de corte e áudio AAC, e falha com código específico caso contrário. Falta fallback automático para recodificação precisa.
- A reprodução usa HTTP Range com URL temporária. Se a sessão de reprodução ultrapassar cinco minutos, o frontend ainda não renova automaticamente o token, pelo que uma nova operação de procura pode exigir reabrir o diálogo.
- A eliminação de um projeto inteiro segue o comportamento anterior e pode deixar vídeos no armazenamento; a eliminação individual de vídeo liberta o espaço contabilizado.
- Falta um painel global de jobs fora da página do projeto e testes de todas as condições de corrida. A recuperação de jobs em fila republica mensagens; o claim atómico impede execução dupla, mas ainda falta um padrão outbox para publicação transacional.

## Execução manual

`docker compose up --build` inicia o worker. Carregar MP4/H.264, abrir **Recortar vídeo**, escolher intervalo e submeter. A lista do projeto é atualizada após conclusão. Confirmar que o original continua disponível. O teste integrado local está em `tests/trim_integration.py` e requer a stack ativa, Python com `requests`, FFmpeg e ffprobe. Se existir um contentor legado `picturas-video_trim-1` ligado à mesma fila, é necessário pará-lo antes de executar o teste: esse consumidor usa outro contrato de mensagens.
