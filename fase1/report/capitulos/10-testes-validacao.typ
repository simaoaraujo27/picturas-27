#import "../template.typ": *

= Testes e Validação do MVP

#orientacao[
  Os critérios de aceitação da ERS (_Dado… Quando… Então…_) são a base dos testes. Cada requisito implementado
  deve ter pelo menos um teste (automático ou manual) com resultado registado. Para os requisitos não
  funcionais, registem o valor medido face ao *Alvo*, sempre que aplicável.
]

== Estratégia e ambiente de testes

A estratégia de testes combinou verificações automatizadas e testes manuais na interface web. Para o Trim, a suite `tests/trim_integration.py` cobre a integração funcional dos microsserviços. Para a remoção de segmento, `tests/remove_segment_integration.py` foi executada em 2026-10-17 contra a stack Docker Compose, após verificações estáticas (`docker compose config --quiet`, `py_compile`, `node --check` e `bun run build`) e seguida da regressão do Trim. Para o Upload, `tests/video_upload_smoke_test.py` verifica a integração e a pré-validação, e `tests/video_upload_size_test.py` ensaia os limites Free e Premium. Para a compilação, `videoCompileWorker/test_worker.py` reúne sete testes `unittest` com FFmpeg/FFprobe reais e serviços HTTP simulados; a execução documentada usa `docker compose exec video_compile_worker python -m unittest test_worker -v`. Os ensaios de alteração de velocidade são identificados separadamente abaixo. Os resultados constam da secção seguinte; a existência de um script não implica que tenha sido executado. Os percursos manuais de interface são identificados como comunicados quando não existe registo automatizado.

*Ambiente de execução:*
- Orquestração completa de microsserviços via Docker Compose (`api_gateway`, `projects`, `users`, `mediaStorageService`, `videoTrimWorker`, `video_compile_worker`, `frontend`, `rabbitMQ`, `seaweedfs`, `mongo-projects`, `mongo-users`).
- Plataforma de teste: Ubuntu Linux (kernel 6.x), Python 3.11 com `requests` e `ffprobe`.
- Mídia de teste: ficheiros de vídeo MP4 codificados em H.264 com áudio AAC (`video_teste.mp4`, resolução 320$times$240 a 30 fps, duração 5.0 s), cobrindo variações com áudio estereofónico e vídeo mudo sem faixa de áudio.

*Âmbito da evidência de speed:*
Os resultados de speed são os registados durante a implementação associada ao commit 58d4414, não uma nova execução sobre o main atual. Os 118 testes históricos (66 + 6 + 28 + 18) incluem dependências externas simuladas; os testes sintéticos do worker e a regressão de upload em Projects usam FFmpeg/ffprobe reais. O E2E manual foi comunicado pelo utilizador. O ambiente Linux descrito para outras suites não é automaticamente o ambiente de speed; a confirmação manual refere a stack Docker do autor, sem benchmark de hardware registado.


== Testes realizados

#tab([Testes e resultados de validação do MVP],
  tabela(
    colunas: (2.3cm, 1.8cm, 1fr, 3.2cm, 1.5cm),
    tamanho: 8pt,
    [ID], [Tipo], [Descrição (Dado… Quando… Então…)], [Requisito(s)], [Resultado],

    [TST-UPL-01], [Manual comunicado],
    [Dado um utilizador autenticado num projeto com permissão de edição, quando abre o diálogo, seleciona um MP4 e confirma o envio, então o carregamento é iniciado e o vídeo fica listado no projeto.],
    [REQ-VID-UPL-001–004, REQ-VID-UPL-006, REQ-VID-UPL-018–019, REQ-VID-UPL-033],
    [Passa],

    [TST-UPL-02], [Automático],
    [Dado um pedido a `/video/check` com nome que não termina em `.mp4` ou tamanho zero, quando é validado, então a API rejeita-o com HTTP 400 `INVALID_VIDEO`.],
    [REQ-VID-UPL-005, REQ-VID-UPL-021],
    [Passa],

    [TST-UPL-03], [Integração],
    [Dado um pedido de upload sem credenciais, quando é submetido à API, então o pedido é rejeitado com HTTP 401.],
    [REQ-VID-UPL-007, REQ-VID-UPL-023],
    [Passa],

    [TST-UPL-04], [Integração],
    [Dado um utilizador com acesso apenas de leitura a um projeto partilhado, quando tenta validar o upload, então recebe HTTP 403; com permissão de edição, a pré-validação é aceite.],
    [REQ-VID-UPL-008, REQ-VID-UPL-024, REQ-VID-UPL-032],
    [Passa],

    [TST-UPL-05], [Automático],
    [Dado um MP4 com vídeo H.264, quando é validado, então passa a validação de mídia. Os ensaios negativos com conteúdo falso ou codec diferente de H.264 permanecem pendentes nesta revisão.],
    [REQ-VID-UPL-009–011, REQ-VID-UPL-026–027],
    [Parcial],

    [TST-UPL-06], [Automático],
    [Dado um pedido de pré-validação com o limite declarado do plano (1 000 000 000 bytes Free ou 5 000 000 000 bytes Premium), quando é validado, então a API aceita o tamanho declarado.],
    [REQ-VID-UPL-012–013, REQ-VID-UPL-022],
    [Passa],

    [TST-UPL-07], [Automático],
    [Dado um pedido de pré-validação com tamanho superior ao limite do plano, quando é validado, então a API rejeita o pedido com HTTP 413 `VIDEO_TOO_LARGE`.],
    [REQ-VID-UPL-012–013, REQ-VID-UPL-022],
    [Passa],

    [TST-UPL-08], [Integração],
    [Dado um MP4 pequeno válido, quando é carregado através do API Gateway, então o objeto deve ser armazenado no SeaweedFS e a referência e os metadados devem persistir no MongoDB após atualizar o projeto; nesta execução houve bloqueio por falta de volumes livres no SeaweedFS.],
    [REQ-VID-UPL-014, REQ-VID-UPL-016–017, REQ-VID-UPL-029],
    [Parcial],

    [TST-UPL-09], [Automático],
    [Dado um upload em curso, quando a transferência termina com sucesso ou falha, então a interface deve apresentar o estado correspondente ao utilizador. O percurso positivo foi observado; o estado de erro continua por ensaiar.],
    [REQ-VID-UPL-015, REQ-VID-UPL-018, REQ-VID-UPL-025, REQ-VID-UPL-033, REQ-VID-UPL-037–038],
    [Parcial],

    [TST-UPL-10], [Manual comunicado],
    [Dado um nome já utilizado para um vídeo no projeto, quando outro ficheiro com o mesmo nome é enviado, então o sistema recusa a duplicação e informa o utilizador.],
    [REQ-VID-UPL-028],
    [Passa],

    [TST-UPL-11], [Automático],
    [Dado o diálogo de upload aberto antes da confirmação, quando o utilizador o fecha, então nenhum upload é iniciado nem vídeo associado ao projeto.],
    [REQ-VID-UPL-036],
    [Não executado],

    [TST-UPL-12], [Integração],
    [Dado um erro durante a transferência ou indisponibilidade do armazenamento, quando o upload falha, então não deve ficar um vídeo parcialmente associado. A injeção destas falhas continua pendente.],
    [REQ-VID-UPL-025, REQ-VID-UPL-029, REQ-VID-UPL-031, REQ-VID-UPL-037–038],
    [Não executado],

    [TST-UPL-13], [Medição],
    [É referido um ensaio com ficheiro de 128 000 000 bytes, sem pico medido ou configuração registados. Medir o pico adicional por upload com MP4/H.264 próximo dos limites Free/Premium e sob concorrência, para verificar o teto de 1 000 000 000 bytes.],
    [REQ-VID-UPL-030],
    [Parcial; teto por validar],

    [TST-UPL-14], [Regressão],
    [Verificar carregamento e listagem de imagens num projeto com vídeo e comparar com um projeto sem vídeo; ensaio de regressão pendente.],
    [REQ-VID-UPL-034–035],
    [Não executado],

    [TST-UPL-15], [Automático],
    [Dado um ficheiro declarado como não MP4 selecionado no diálogo, quando a interface aplica a validação preliminar, então deve recusá-lo e informar o utilizador; ensaio específico na interface pendente.],
    [REQ-VID-UPL-005, REQ-VID-UPL-021],
    [Não executado],

    [TST-TRIM-01], [Manual], [Dado um vídeo carregado, quando a ferramenta de recorte é aberta, então a interface exibe o player, marcadores temporais e duração resultante dinâmica.], [REQ-VID-TRIM-001, REQ-VID-TRIM-002], [Passa],

    [TST-TRIM-02], [Manual], [Dado um intervalo parametrizado, quando o utilizador clica em pré-visualizar, então o browser executa apenas o intervalo sem gerar pedidos ao servidor.], [REQ-VID-TRIM-003], [Passa],

    [TST-TRIM-03], [Automático], [Dado um pedido com $t_(i n) >= t_(o u t)$ ou intervalo $< 1.0$ s, quando submetido a `POST /trim`, então a API devolve HTTP 400 com código `INVALID_INTERVAL`.], [REQ-VID-TRIM-004, REQ-VID-TRIM-006], [Passa],

    [TST-TRIM-04], [Automático], [Dado um utilizador `free`, quando submete 5 operações de recorte, então a quota decrementa até 0 e a 6.ª tentativa é bloqueada com `DAILY_QUOTA_EXHAUSTED`.], [REQ-VID-UNI-005, REQ-VID-UNI-006], [Passa],

    [TST-TRIM-05], [Automático], [Dado um pedido válido, quando submetido, então recebe HTTP 202 com Job ID e o polling reflete as transições `QUEUED` $->$ `PROCESSING` $->$ `COMPLETED`.], [REQ-VID-TRIM-008, REQ-VID-UNI-008, REQ-VID-TRIM-030, REQ-VID-TRIM-009, REQ-VID-TRIM-020, REQ-VID-UNI-004], [Passa],

    [TST-TRIM-06], [Automático], [Dado um pedido de corte de 1.25s a 3.75s (duração 2.5s), quando concluído, então o MP4 gerado tem 2.52s, codecs H.264/AAC e metadados no projeto.], [REQ-VID-TRIM-010, REQ-VID-UNI-001, REQ-VID-TRIM-014, REQ-VID-TRIM-031, REQ-VID-TRIM-026], [Passa],

    [TST-TRIM-07], [Automático], [Dado um corte rápido Premium, quando os pontos coincidem com keyframes, então conclui com sucesso; quando desalinhados, rejeita com erro explícito.], [REQ-VID-TRIM-011], [Passa],

    [TST-TRIM-08], [Automático], [Dado um vídeo de entrada com hash SHA-256 medido, quando o recorte é finalizado, então o hash do vídeo original na biblioteca permanece rigorosamente idêntico.], [REQ-VID-UNI-009], [Passa],

    [TST-TRIM-09], [Automático], [Dado um erro simulado no worker, quando o processamento falha, então a tarefa passa a `FAILED` e a operação diária Free é atomicamente estornada.], [REQ-VID-TRIM-016, REQ-VID-TRIM-034, REQ-VID-TRIM-017], [Passa],

    [TST-TRIM-10], [Automático], [Dado o término de uma tarefa, quando o worker finaliza, então a pasta temporária `/tmp/picturas-trim-*` é confirmada vazia sem ficheiros residuais.], [REQ-VID-UNI-003], [Passa],

    [TST-TRIM-11], [Automático], [Dado um utilizador não autenticado ou com permissão apenas de leitura (`read`), quando tenta aceder a `/trim`, então a API devolve HTTP 401 ou 403 `EDIT_REQUIRED`.], [REQ-VID-TRIM-019, REQ-VID-UNI-002], [Passa],

    [TST-TRIM-12], [Automático], [Dado um vídeo recortado adicionado, quando o endpoint `/storage` é consultado e o vídeo é eliminado via `DELETE`, então o espaço ocupado é subtraído da quota.], [REQ-VID-UNI-007, REQ-VID-TRIM-039–040, REQ-VID-TRIM-024], [Passa],

    [TST-TRIM-13], [Automático], [Dado um job em fila de espera (`QUEUED`), quando o utilizador emite `DELETE /jobs/:jobId`, então passa a `CANCELLED` e a quota debitada é reposta.], [REQ-VID-TRIM-022, REQ-VID-TRIM-034], [Passa],

    [TST-TRIM-14], [Automático], [Dado um vídeo privado, quando acedido com cookie temporário via `GET /play`, então responde com HTTP 206 Partial Content (Range bytes=0-99).], [REQ-VID-UNI-002], [Passa],

    [TST-TRIM-15], [Automático], [Dado o comando `docker compose build video_trim_worker`, quando o contentor arranca na rede do Compose, então consome mensagens sem erros no host.], [REQ-VID-TRIM-028], [Passa],

    [TST-REM-01], [Integração], [Dado um vídeo MP4/H.264 com áudio AAC (6 s) carregado num projeto, quando é submetida uma remoção válida com a versão atual do projeto, então a API devolve HTTP 202 com o Job ID e o estado inicial `QUEUED`, e a tarefa progride até `COMPLETED` com o resultado registado no projeto.], [REQ-VID-REM-004, REQ-VID-REM-013, REQ-VID-UNI-008, REQ-VID-REM-015], [Passa],

    [TST-REM-02], [Integração], [Dado um pedido sem o cabeçalho `X-Project-Version`, quando submetido, então a API devolve HTTP 428 `VERSION_REQUIRED`; dada uma versão desatualizada, então devolve HTTP 409 `PROJECT_CONFLICT` e nenhuma tarefa é criada.], [REQ-VID-REM-012, REQ-VID-REM-021], [Passa],

    [TST-REM-03], [Integração], [Dado um intervalo invertido (fim menor ou igual ao início), quando submetido, então a API devolve HTTP 400 `INVALID_INTERVAL` e nenhum job é criado.], [REQ-VID-REM-002], [Passa],

    [TST-REM-04], [Integração], [Dado um corte cuja duração resultante é inferior a 1,0 s, quando submetido, então a API devolve HTTP 400 `DURATION_TOO_SHORT` e nenhum job é criado.], [REQ-VID-REM-003], [Passa],

    [TST-REM-05], [Integração], [Dado um corte intermédio (1,5–3,5 s de um vídeo de 6 s), quando o _worker_ conclui, então o resultado tem ~4,0 s, vídeo H.264 e áudio AAC, nome `<nome>-cut.mp4`, fica registado no projeto com proveniência (`sourceVideoId`, `removeSegmentJobId`) e o vídeo original mantém o hash SHA-256 idêntico.], [REQ-VID-REM-005, REQ-VID-REM-006, REQ-VID-REM-016, REQ-VID-UNI-001], [Passa],

    [TST-REM-06], [Integração], [Dado um corte no início (0–2 s) e um corte no fim (4–6 s) do mesmo vídeo, quando processados, então cada resultado corresponde à parte contínua restante (~4,0 s).], [REQ-VID-REM-005; UC-VID-003/RN2], [Passa],

    [TST-REM-07], [Integração], [Dado um colaborador com partilha apenas de leitura, quando tenta submeter uma remoção, então recebe HTTP 403 `EDIT_REQUIRED`; com partilha de edição, a operação é aceite.], [REQ-VID-REM-010], [Passa],

    [TST-REM-08], [Integração], [Dado um _job_ em fila de espera, quando é emitido `DELETE /remove-segment/jobs/:jobId`, então a tarefa passa a `CANCELLED` e a operação diária debitada é reposta.], [REQ-VID-UNI-006, REQ-VID-REM-020], [Passa],

    [TST-REM-09], [Integração], [Dado um vídeo sem faixa de áudio, quando o corte é processado, então a saída mantém-se sem canal de áudio espúrio.], [REQ-VID-REM-005, REQ-VID-UNI-001], [Passa],

    [TST-REM-10], [Regressão], [Executada a suite `tests/trim_integration.py` após a integração da remoção de segmento, então passa sem impacto no serviço Trim; as verificações estáticas (`docker compose config --quiet`, `py_compile`, `node --check`, `bun run build`) concluem sem erros.], [— (verificação de integração e build)], [Passa],

    [TST-COMP-01],
    [Automático],
    [Dados dois vídeos com resolução e áudio diferentes (um deles sem áudio), quando a compilação termina, então o resultado é um MP4 com vídeo H.264 e áudio AAC, com a resolução do primeiro vídeo e duração aproximadamente igual à soma, começa pelo primeiro vídeo, a reserva de armazenamento é pedida e a conclusão regista tamanho, duração e dimensões (`test_compiles_in_order_with_mixed_formats`).],
    [REQ-VID-COMP-006, REQ-VID-COMP-008, REQ-VID-COMP-010, REQ-VID-COMP-011, REQ-VID-UNI-001],
    [Passa],

    [TST-COMP-02],
    [Automático],
    [Dada uma lista com a ordem trocada e um vídeo repetido, quando a compilação termina, então o resultado começa pelo primeiro vídeo da lista e a duração é a soma das três partes (`test_order_can_be_swapped_and_repeated`).],
    [REQ-VID-COMP-003, REQ-VID-COMP-008],
    [Passa],

    [TST-COMP-03],
    [Automático],
    [Dado um ficheiro que não é um vídeo, quando a tarefa é processada, então falha com `VIDEO_UNREADABLE` e não é enviado nenhum resultado (`test_unreadable_video_fails_without_upload`).],
    [REQ-VID-COMP-015, REQ-VID-UNI-010],
    [Passa],

    [TST-COMP-04],
    [Automático],
    [Dada uma tarefa cancelada, quando o _worker_ a processa, então termina sem enviar resultado nem registar a conclusão (`test_cancelled_job_stops_and_uploads_nothing`).],
    [REQ-VID-UNI-010, REQ-VID-COMP-NF-003],
    [Passa],

    [TST-COMP-05],
    [Automático],
    [Dada uma tarefa com apenas um vídeo, quando é processada, então é rejeitada (`test_needs_two_videos`).],
    [REQ-VID-COMP-013],
    [Passa],

    [TST-COMP-06],
    [Automático],
    [Dada uma soma de durações acima do limite configurado, quando a tarefa é processada, então falha com `TOTAL_TOO_LONG` e não é enviado resultado (`test_total_length_limit`).],
    [REQ-VID-COMP-020],
    [Passa],

    [TST-COMP-07],
    [Manual],
    [Dado um utilizador `free` com operações diárias disponíveis, quando uma compilação é concluída, então o contador «Daily Operations» desce uma unidade.],
    [REQ-VID-COMP-005, REQ-VID-COMP-021],
    [Passa],

    [TST-COMP-08],
    [Automático],
    [Dada uma compilação com um vídeo de origem inexistente, quando o worker a processa, então a tarefa falha sem enviar nenhum resultado (`test_missing_video_fails_without_upload`).],
    [REQ-VID-COMP-004, REQ-VID-UNI-010],
    [Passou],

    [TST-COMP-09],
    [Manual],
    [Dado o diálogo de compilação aberto, quando o projeto tem ficheiros que não são vídeos, então esses ficheiros não aparecem em «Available videos».],
    [REQ-VID-COMP-001, REQ-VID-COMP-004],
    [Passa],

    [TST-COMP-10],
    [Manual],
    [Dado um único vídeo adicionado, quando o utilizador tenta compilar, então o botão «Compile videos» fica desativado e surge a mensagem «Select at least 2 videos.».],
    [REQ-VID-COMP-002, REQ-VID-COMP-013],
    [Passa],

    [TST-COMP-11],
    [Manual],
    [Dada uma compilação em curso, quando o utilizador carrega em «Cancel», então a tarefa passa a «Cancelled» sem criar o vídeo resultante.],
    [REQ-VID-UNI-010],
    [Não verificado na interface: com vídeos curtos a compilação terminou antes de ser possível cancelar; o cancelamento do worker é coberto pelo TST-COMP-04.],

    [#text(hyphenate: true, "TST-SPEED-01")], [#text(hyphenate: true, "Automático isolado")], [#text(hyphenate: true, "Projects: valida velocidades/intervalos, edição/partilhas/versão, mensagem, associação e erros; quota com utilitário real e modelos MongoDB simulados, incluindo limites, output size, release, repetição sequencial e falha de commit.")], [#text(hyphenate: true, "REQ-VID-SPEED-003–006, REQ-VID-SPEED-008, REQ-VID-SPEED-014–015, REQ-VID-UNI-007, REQ-VID-SPEED-022–025, REQ-VID-SPEED-028–029, REQ-VID-SPEED-031–032, REQ-VID-SPEED-034, REQ-VID-SPEED-037")], [#text(hyphenate: true, "Histórico: 66/66; não reexecutado.")],

    [#text(hyphenate: true, "TST-SPEED-02")], [#text(hyphenate: true, "Contrato HTTP isolado")], [#text(hyphenate: true, "API Gateway: proxy /speed, autenticação, headers, versão, contexto de partilha e erros, com Projects simulado.")], [#text(hyphenate: true, "REQ-VID-SPEED-008, REQ-VID-SPEED-028–029, REQ-VID-SPEED-035")], [#text(hyphenate: true, "Histórico: 6/6; não reexecutado.")],

    [#text(hyphenate: true, "TST-SPEED-03")], [#text(hyphenate: true, "Validação frontend")], [#text(hyphenate: true, "Parsing e validação dos intervalos, fatores, valores finitos, limites, sobreposições e adjacência; não automatiza cliques/renderização do diálogo.")], [#text(hyphenate: true, "REQ-VID-SPEED-003, REQ-VID-SPEED-005–006, REQ-VID-SPEED-022–025, REQ-VID-SPEED-033")], [#text(hyphenate: true, "Histórico: 28/28; não reexecutado.")],

    [#text(hyphenate: true, "TST-SPEED-04")], [#text(hyphenate: true, "Worker sintético / contrato")], [#text(hyphenate: true, "FFmpeg/ffprobe reais: fatores e vários intervalos, duração/ordem, codecs, áudio/ausência de áudio e hash do original. HTTP/RabbitMQ são simulados nos testes de contrato.")], [#text(hyphenate: true, "REQ-VID-SPEED-010–012, REQ-VID-SPEED-017–018, REQ-VID-UNI-009, REQ-VID-SPEED-024, REQ-VID-UNI-001, REQ-VID-SPEED-034")], [#text(hyphenate: true, "Histórico: 18/18; não reexecutado.")],

    [#text(hyphenate: true, "TST-SPEED-05")], [#text(hyphenate: true, "E2E manual comunicado")], [#text(hyphenate: true, "Utilizador confirmou upload e Modificar velocidade funcionais na stack Docker, também após correção da quota. A confirmação não enumera todos os fatores, partilhas, limites ou falhas testados.")], [#text(hyphenate: true, "REQ-VID-SPEED-001–002, REQ-VID-SPEED-004, REQ-VID-SPEED-007–009, REQ-VID-SPEED-014–015, REQ-VID-SPEED-026–027")], [#text(hyphenate: true, "Percurso positivo comunicado; sem nova execução.")],

    [#text(hyphenate: true, "TST-SPEED-06")], [#text(hyphenate: true, "Build / análise estática")], [#text(hyphenate: true, "TypeScript, build, sintaxe e whitespace registados na revisão da implementação. Não equivalem a ensaios funcionais nem a uma prova de regressão global.")], [#text(hyphenate: true, "REQ-VID-SPEED-037")], [#text(hyphenate: true, "Histórico; não reexecutado nesta integração.")],

    [#text(hyphenate: true, "TST-SPEED-07")], [#text(hyphenate: true, "Matriz real pendente")], [#text(hyphenate: true, "Ensaiar todos os fatores e vários intervalos, vídeo sem áudio, leitura/edição, limites reais de quota, falhas assíncronas, diferentes timestamps e indisponibilidade. Definir ambiente e alvos antes de medir carga.")], [#text(hyphenate: true, "REQ-VID-SPEED-010–012, REQ-VID-UNI-007–021, REQ-VID-SPEED-028–029, REQ-VID-SPEED-031–032, REQ-VID-SPEED-034–037")], [#text(hyphenate: true, "Não executado; alvos quantitativos por decidir.")],
  ),
)

=== Casos de duração esperada

A duração esperada é a duração original menos a soma dos comprimentos selecionados, mais a soma desses comprimentos divididos pelos fatores aplicados. Mantém-se a ordem original.

#tabela(
    colunas: (1.1cm, 1fr, 6cm),
    tamanho: 9pt,
    [#text(hyphenate: true, "Caso")], [#text(hyphenate: true, "Entrada e configuração")], [#text(hyphenate: true, "Duração esperada")],

    [#text(hyphenate: true, "A")], [#text(hyphenate: true, "10 s; [2,4] a 2x.")], [#text(hyphenate: true, "10 - 2 + 1 = 9 s.")],

    [#text(hyphenate: true, "B")], [#text(hyphenate: true, "10 s; [2,4] a 0,5x.")], [#text(hyphenate: true, "10 - 2 + 4 = 12 s.")],

    [#text(hyphenate: true, "C")], [#text(hyphenate: true, "10 s; [2,4] a 2x e [6,8] a 0,5x.")], [#text(hyphenate: true, "10 - 4 + 1 + 4 = 11 s.")],

    [#text(hyphenate: true, "D")], [#text(hyphenate: true, "10 s; [2,4] a 1x.")], [#text(hyphenate: true, "10 s.")],

    [#text(hyphenate: true, "E")], [#text(hyphenate: true, "10 s; [1,3] a 2x e [5,7] a 0,5x.")], [#text(hyphenate: true, "11 s; também é necessário verificar a posição e ordem de ambos os trechos.")],
)


A tolerância de 0,2 s pertence aos ensaios sintéticos, não é uma precisão universal aprovada. A inspeção deve abranger a duração total e dos streams, H.264/AAC quando aplicável, ausência de áudio artificial e posição/ordem dos trechos. Duração correta isoladamente não prova aplicação aos intervalos corretos. Os bytes para quota são o tamanho do ficheiro codificado, não uma estimativa pela fórmula temporal.



== Limitações e defeitos conhecidos

No âmbito da validação do MVP da Fase 1, assumem-se de forma transparente as seguintes limitações técnicas:
1. *Notificações fora de página (`REQ-VID-TRIM-015` parcial):* Se o utilizador fechar o navegador durante o processamento, o vídeo é guardado com sucesso na biblioteca do projeto, mas não existe ainda um mecanismo de notificação global na plataforma (push notification) que alerte o utilizador no regresso.
2. *Métricas quantitativas de desempenho em carga (`REQ-VID-UNI-004` e `026` parciais):* O tempo de resposta da submissão é inferior a 200 ms em testes locais e um recorte de 2.5s demora cerca de 1.2s ($0.48 times$ tempo real). Contudo, não foram realizados testes sistemáticos de percentil p95 sob concorrência nem medições formais com ficheiros pesados de 1080p a 60 fps e duração de 60 minutos.
3. *Identificador de Job:* O sistema utiliza atualmente identificadores nativos `ObjectId` do MongoDB em vez de identificadores `UUIDv4` estritos.
4. *Validação de Interface Gráfica:* A interface do Upload foi validada por testes E2E automatizados em navegador; os restantes fluxos da aplicação não dispõem de uma suite E2E abrangente nesta fase.
5. *Âmbito da medição de memória (`TST-UPL-13`):* É mencionado um ensaio com ficheiro de 128 000 000 bytes, mas não estão registados o pico medido, o consumo de referência nem a configuração. Não se considera demonstrado o teto de 1 000 000 000 bytes por upload nos limites dos planos ou sob concorrência.
6. *Evidência de testes manuais:* Alguns resultados manuais foram comunicados sem artefactos de execução associados, limitando a sua reprodução e auditoria independente.

7. *Acompanhamento de speed:* REQ-VID-SPEED-013, 016 e 038 não estão implementados: não há progresso consultável/percentual, cancelamento de pedido aceite nem alerta terminal de falha. Cancelar no diálogo apenas desiste antes de enviar.
8. *Validação distribuída de speed:* A API pode aceitar um pedido que o worker rejeita depois de medir a duração real; erro terminal não é apresentado na UI atual.
9. *Quota e compensação de speed:* Reserva/commit/release usam bytes reais do output. O rollback de associação depende de conseguir confirmar a ausência de associação; não há transação distribuída nem garantia de recolha de outputs órfãos. Resultados status error são apenas registados.
10. *Precisão e concorrência de speed:* Não há tolerância universal aprovada para conteúdos com timestamps/taxas de fotogramas distintos, nem prova de exatamente uma vez sob mensagens concorrentes. A cobertura de repetição é sequencial.
11. *Evidência de speed:* Os resultados anteriores não substituem reexecução após alterações do main. Falta ensaio E2E abrangente, quota real nos limites, benchmark e cobertura completa da interface. A correção inicial de upload por reconstrução de img_storage foi uma ocorrência de deployment comunicada, não prova de resolução de outras falhas de storage observadas pelos colegas.
12. *Evidência da remoção de segmento:* Os alvos de desempenho (REQ-VID-UNI-004 e 025) não foram medidos e a injeção de falhas do _worker_ e a inspeção de resíduos não foram ensaiadas (REQ-VID-REM-007 e 023 parciais). A recusa no limite exato da quota acumulada (REQ-VID-UNI-007) e o esgotamento específico da quota diária (REQ-VID-UNI-005) não têm ensaio próprio. A interface foi validada por percurso comunicado, sem suite E2E, e a miniatura do resultado não é gerada (REQ-VID-REM-016 parcial); a notificação por _WebSocket_ de REQ-VID-REM-013 não está implementada (acompanhamento por consulta de 4 s, como no Trim).
