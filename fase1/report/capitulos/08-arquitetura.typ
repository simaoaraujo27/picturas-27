#import "../template.typ": *

= Alterações Arquiteturais

#orientacao[
  Partam do documento de solução arquitetural de base e descrevam apenas o *delta* introduzido pelo suporte a
  vídeo. O nível de detalhe é o de um MVP: o suficiente para que outra equipa perceba, mantenha e estenda a
  solução na Fase 2. Cada alteração deve estar ligada aos requisitos que a motivam.
]

== Visão geral das alterações

O suporte a vídeo inclui os seguintes fluxos na arquitetura existente: o Upload, síncrono, que reutiliza os serviços web, de projetos e de armazenamento; e o Trim, assíncrono, que utiliza a fila dedicada do RabbitMQ e o novo `videoTrimWorker`. O Upload estende o `frontend`, o API Gateway, o Nginx, `projects` e `mediaStorageService`; usa o SeaweedFS e MongoDB existentes e não publica tarefas de processamento.

O UC-VID-003 acrescenta o fluxo assíncrono de remoção de segmento, com a fila dedicada `video_remove_segment_queue` e o `videoRemoveSegmentWorker`, reutilizando o modelo de tarefas, a quota diária e a quota acumulada do Trim, o ciclo de _staging_ do editor e o controlo otimista de versões. O UC-VID-004 acrescenta o fluxo assíncrono de compilação, com a fila dedicada` video_compile_queue` e o `videoCompileWorker`, reutilizando a quota, a biblioteca e o ciclo de vida de tarefas do recorte. O UC-VID-005 acrescenta o fluxo assíncrono de alteração de velocidade, com video_speed_queue e videoSpeedWorker, reutilizando os resultados, a quota, a biblioteca e a notificação de operações de projeto. Não usa TrimJob, polling de jobs ou cancelamento de Trim. A vista de componentes existente abaixo foi produzida para Upload/Trim/Compile; a integração de speed e da remoção de segmento consta das tabelas comuns e dos respetivos fluxos neste capítulo.

#paisagem[
  #align(center)[
    #figure(
      image("../images/picturas_arquitetura_video.svg", width: 96%),
      caption: [Vista de componentes da extensão de vídeo (novos e alterados destacados)],
    )
  ]
]

#tab([Componentes novos e alterados],
  tabela(
    colunas: (3.2cm, 1.8cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [Componente / serviço], [Estado], [Responsabilidade / alteração], [Requisitos],

    [`Nginx`], [Estendido], [Rota específica de Upload com limite de corpo de 6 GB, `proxy_request_buffering off` e timeouts alargados, encaminhando o corpo progressivamente para o API Gateway. O limite do proxy não substitui os limites por plano aplicados pela aplicação.], [REQ-VID-UPL-012–014, REQ-VID-UPL-030],

    [`videoTrimWorker`], [Novo], [Microsserviço em Python com FFmpeg autónomo. Consome tarefas da fila `video_trim_queue`, efetua download de vídeo a partir do SeaweedFS, executa recorte temporal exato ao fotograma (ou _stream copy_), valida metadados de saída, persiste o resultado no armazenamento de objetos e notifica a conclusão do job.], [REQ-VID-TRIM-010, REQ-VID-TRIM-011, REQ-VID-TRIM-012, REQ-VID-TRIM-018, REQ-VID-TRIM-026, REQ-VID-TRIM-028],

    [`projects`], [Alterado], [No Upload, verifica autorização e versão do projeto, recebe o ficheiro em temporário de disco, valida-o com `ffprobe`, reserva quota, envia o objeto e associa metadados a `Project.videos`, separada de `imgs`. \\ Gestão do ciclo de vida de tarefas (`TrimJob`) em MongoDB; publicação de mensagens no RabbitMQ; fiscalização de quotas de armazenamento em disco por utilizador (1 GB / 5 GB); endpoints de listagem de jobs, cancelamento voluntário e emissão de cookies temporários seguros para reprodução HTTP Range. No speed, valida POST /speed, cria novos IDs, publica a operação e trata o resultado sem substituir o original; integra bytes reais em quota e incrementa a versão, sem criar TrimJob.], [REQ-VID-UPL-007–014, REQ-VID-UPL-016–019, REQ-VID-UPL-022–029, REQ-VID-UPL-030–032, REQ-VID-UPL-035, REQ-VID-UPL-037–040; REQ-VID-TRIM-004, REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-014, REQ-VID-TRIM-031–033, REQ-VID-TRIM-020, REQ-VID-TRIM-021, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038, REQ-VID-TRIM-027 ; REQ-VID-SPEED-008, REQ-VID-SPEED-014–015, REQ-VID-SPEED-019–021, REQ-VID-SPEED-028–029, REQ-VID-SPEED-031–032, REQ-VID-SPEED-034],

    [`users`], [Mantido no Upload; alterado no Trim e na remoção de segmento], [No Upload, é consultado para obter o perfil que determina o limite por ficheiro; a funcionalidade não consome quota diária de operações. \\ Extensão da gestão de quotas de operações diárias (`FREE_DAILY_OP = 5`): disponibilização de reserva atómica de operação por Job ID na submissão, confirmação na conclusão com sucesso e estorno automático em caso de falha de processamento ou cancelamento voluntário. \\ Para a remoção de segmento, os endpoints internos `/internal/remove-segment/:user/:job/:action` partilham o mesmo mecanismo de reserva, confirmação e estorno por tarefa.], [REQ-VID-UPL-012–013; REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-034–035, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038; REQ-VID-REM-018–020],

    [`frontend`], [Alterado], [Para Upload, `AddVideoDialog` seleciona um ficheiro, valida extensão/tipo declarados, apresenta nome e tamanho e comunica envio pendente, conclusão ou falha; o código também contém handlers de arrastar e largar, embora o dossiê marque essa interação como adiada. \\ Componente `VideoWorkspace` com reprodutor de vídeo HTML5, linha temporal interativa com seleção de marcadores de início e fim, pré-visualização local no cliente, barra indicadora de ocupação da quota de disco, acompanhamento de tarefas via _polling_ a cada 4 segundos e opção de cancelamento. Para speed, SpeedVideoDialog configura vários intervalos, permite editar/remover, valida e submete; apresenta aceitação e atualiza a biblioteca pelo evento de projeto, sem progresso ou aviso terminal de falha.], [REQ-VID-UPL-001–006, REQ-VID-UPL-015, REQ-VID-UPL-018–019, REQ-VID-UPL-021, REQ-VID-UPL-028, REQ-VID-UPL-033, REQ-VID-UPL-036–041; REQ-VID-TRIM-001, REQ-VID-TRIM-002, REQ-VID-TRIM-003, REQ-VID-TRIM-009, REQ-VID-TRIM-019, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038, REQ-VID-TRIM-024 ; REQ-VID-SPEED-001–009, REQ-VID-SPEED-026–029, REQ-VID-SPEED-033],

    [`apiGateway`], [Alterado], [No Upload, verifica JWT, encaminha a pré-validação de metadados e transmite o corpo por `PassThrough` com `highWaterMark` de 64 KiB, após nova verificação do pedido antes do encaminhamento. \\ Reencaminhamento das rotas de manipulação de vídeo (`/projects/:owner/:project/video/*`) para o microsserviço `projects`, preservando autenticação JWT e controlo de partilhas de projetos (`read`/`edit`). Encaminha também POST /speed com autenticação e contexto de versão/partilha, sem introduzir uma autorização paralela.], [REQ-VID-UPL-007–008, REQ-VID-UPL-012–014, REQ-VID-UPL-022–024, REQ-VID-UPL-028–030, REQ-VID-UPL-032, REQ-VID-UPL-039; REQ-VID-TRIM-019, REQ-VID-TRIM-027 ; REQ-VID-SPEED-008, REQ-VID-SPEED-028–029, REQ-VID-SPEED-035],

    [`mediaStorageService` (`img_storage`)], [Estendido], [Nova rota interna protegida por chave e identificadores validados recebe o MP4 em stream e envia-o ao SeaweedFS via S3 multipart, com partes de 16 MiB e `queueSize = 2` (estimativa de buffers multipart: 32 MiB). As rotas de imagens mantêm-se separadas. No speed, reutiliza a URL interna e o PUT protegido por chave para guardar o novo objeto com identificador distinto.], [REQ-VID-UPL-016–018, REQ-VID-UPL-029–031, REQ-VID-UPL-035, REQ-VID-UPL-037 ; REQ-VID-SPEED-014, REQ-VID-SPEED-030, REQ-VID-SPEED-035],

    [SeaweedFS (S3)], [Mantido], [Armazenamento de objetos existente, reutilizado para os vídeos originais e para os resultados do Trim. O `mediaStorageService` controla a chave interna e envia o conteúdo; não se introduz outro object storage. Guarda também os outputs de speed em chaves distintas, preservando o original.], [REQ-VID-UPL-016–017, REQ-VID-UPL-029, REQ-VID-TRIM-012–014, REQ-VID-TRIM-023, REQ-VID-TRIM-039–040 ; REQ-VID-SPEED-014, REQ-VID-SPEED-020],

    [`projects_mongoDB` / `Project.videos`], [Estendido], [O documento do projeto recebe metadados e referência ao objeto na lista `videos`, separada da lista de imagens `imgs`; a associação incrementa a versão do projeto. O estado da quota acumulada é guardado no modelo `VideoStorageAccount`, na mesma base de dados. No speed, a associação e o incremento de versão reutilizam o mesmo modelo.], [REQ-VID-UPL-016–019, REQ-VID-UPL-029, REQ-VID-UPL-035 ; REQ-VID-SPEED-014–015, REQ-VID-SPEED-032],

    [`videoQuota` / `VideoStorageAccount`], [Novo], [Reserva, confirmação e libertação da quota acumulada de vídeo por conta. O código usa este mecanismo também no Upload, além de impor o limite individual por ficheiro; o dossiê do Upload não especifica a quota acumulada, pelo que a regra aplicável ao UC-VID-001 carece de harmonização. O speed usa os bytes reais do output na conta do proprietário, com reserva, confirmação e compensação condicionada; não define quota diária.], [REQ-VID-UPL-016–017; REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-039–040, REQ-VID-TRIM-024 ; REQ-VID-SPEED-019, REQ-VID-SPEED-031–032, REQ-VID-SPEED-034],

    [`rabbitMQ`], [Alterado], [Declaração da fila durável `video_trim_queue`, isolando a carga de processamento de vídeo das filas legadas de processamento de imagem (`brightness_queue`, etc.). Para a remoção de segmento, é declarada a fila durável `video_remove_segment_queue`, ligada à exchange `picturas` e consumida pelo worker com `prefetch_count = 1`. Para a compilação, é declarada a fila durável video_compile_queue. No speed, video_speed_queue e video_results_queue são declaradas dinamicamente pelo worker; a integração reutiliza ws_queue/project-op/add-video, sem configuração estática adicional.], [REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-010; REQ-VID-REM-004, REQ-VID-REM-014; REQ-VID-SPEED-008, REQ-VID-SPEED-015, REQ-VID-SPEED-036],
  
    [#text(hyphenate: true, "videoSpeedWorker / video_speed")], [#text(hyphenate: true, "Novo")], [#text(hyphenate: true, "Contentor independente com FFmpeg/ffprobe: declara a fila, descarrega e valida a origem, transforma e concatena segmentos, envia o novo MP4 e publica o resultado.")], [#text(hyphenate: true, "REQ-VID-SPEED-010–012, REQ-VID-SPEED-017–018, REQ-VID-SPEED-030, REQ-VID-SPEED-034")],

    [#text(hyphenate: true, "wsGateway")], [#text(hyphenate: true, "Reutilizado")], [#text(hyphenate: true, "Difunde add-video pelo canal de operações do projeto; não é alterado nem cria um canal de progresso específico de speed.")], [#text(hyphenate: true, "REQ-VID-SPEED-015, REQ-VID-SPEED-036")],

    [`CompileVideosDialog` (frontend)],
    [Novo],
    [Diálogo de compilação: lista os vídeos do projeto, permite adicionar, ordenar e remover vídeos (mínimo de dois), definir um nome opcional, acompanhar o estado e o progresso (consulta de 3 em 3 segundos) e cancelar a tarefa; apresenta mensagens por código de erro.],
    [REQ-VID-COMP-001–003, REQ-VID-COMP-009, REQ-VID-COMP-013, REQ-VID-COMP-016, REQ-VID-COMP-018],

    [`projects` (rotas de compilação) / `CompileJob`],
    [Estendido],
    [Rotas `POST /compile`, `GET /compile/jobs`, `GET` e `DELETE /compile/jobs/:jobId` e endpoints internos do _worker_ (`claim`, `progress`, `storage/reserve`, `storage/release`, `complete` e `fail`), no mesmo ficheiro de rotas do recorte. Valida o pedido (2 a 10 vídeos do projeto, MP4/H.264, duração total por perfil), reserva a operação diária (`free`) e cria o `CompileJob`, com o mesmo ciclo de vida do `TrimJob`.],
    [REQ-VID-COMP-004–007, REQ-VID-COMP-011–014, REQ-VID-COMP-017, REQ-VID-COMP-020–021],

    [`videoCompileWorker`],
    [Novo],
    [_Worker_ Python com FFmpeg e FFprobe: descarrega os vídeos de origem, verifica a legibilidade e a duração total, normaliza-os (resolução do primeiro vídeo, 30 fps, H.264 e áudio AAC estéreo, com silêncio para vídeos sem áudio) e concatena-os pela ordem pedida. Comunica o progresso, reserva o armazenamento exato, envia o resultado como novo vídeo, remove os ficheiros temporários e termina o FFmpeg se a tarefa for cancelada.],
    [REQ-VID-COMP-008–010, REQ-VID-COMP-015, REQ-VID-COMP-017, REQ-VID-COMP-019, REQ-VID-COMP-NF-003, REQ-VID-COMP-NF-005],

    [`videoRemoveSegmentWorker` / `video_remove_segment_worker`],
    [Novo],
    [_Worker_ Python com FFmpeg/FFprobe que consome `video_remove_segment_queue` com `prefetch_count = 1`: reclama a tarefa (lease de 600 s e `attempt`), descarrega o original pela URL assinada do `mediaStorageService`, valida MP4/H.264 e a duração, remove o intervalo marcado (extração contínua nos cortes de extremo; concatenação via `filter_complex` com `trim`/`atrim`/`setpts`/`asetpts`/`concat` nos cortes intermédios, recodificando H.264 e AAC apenas quando existe áudio), reporta o progresso (0–99 %), reserva o armazenamento exato, envia o novo MP4 e publica conclusão ou falha; termina o FFmpeg em _timeout_ de 600 s ou cancelamento e purga a diretoria temporária.],
    [REQ-VID-REM-005, REQ-VID-REM-007, REQ-VID-REM-016, REQ-VID-REM-023, REQ-VID-REM-025, REQ-VID-REM-026],

    [`RemoveSegmentVideoDialog` (frontend)],
    [Novo],
    [Diálogo de remoção: reprodutor HTML5, campos e linha temporal com passos de 0,01 s, destaque visual do trecho a eliminar, duração resultante, pré-visualização simulada que salta o intervalo, validação do corte e da duração ≥ 1,0 s, submissão com `X-Project-Version`, estado e progresso por consulta de 4 s, cancelamento da tarefa, mensagens por código de erro e atualização da galeria sem recarregar a página.],
    [REQ-VID-REM-001–003, REQ-VID-REM-008–009, REQ-VID-REM-011, REQ-VID-REM-013, REQ-VID-REM-015, REQ-VID-REM-021–022],

    [`projects` (rotas de remoção) / `RemoveSegmentJob`],
    [Estendido],
    [Rotas `POST /:videoId/remove-segment`, `GET /remove-segment/jobs`, `GET` e `DELETE /remove-segment/jobs/:jobId` e endpoints internos do _worker_ (`claim`, `progress`, `storage/reserve`, `storage/release`, `complete`, `fail`), no módulo `removeSegment.js`. Valida o intervalo (múltiplo de 0,01 s) e a duração resultante ≥ 1,0 s, exige `X-Project-Version` (428/409), recusa formatos não MP4/H.264 (415), gera nome derivado único `<nome>-cut.mp4`, reserva a operação diária (`free`), publica na fila e, na conclusão, associa o novo vídeo com metadados e proveniência, incrementa a versão, confirma quotas e estorna em falha/cancelamento; `removeSegmentRecovery` reencaminha tarefas órfãs.],
    [REQ-VID-REM-002–006, REQ-VID-REM-012–021, REQ-VID-REM-023],

  ),
)

== Decisões arquiteturais

#tab([Decisões arquiteturais],
  tabela(
    colunas: (2cm, 2.5cm, 1fr, 3.7cm, 2.8cm),
    tamanho: 8pt,
    [ID], [Decisão], [Contexto e alternativas consideradas], [Consequências], [Requisitos / DQ],

    [DA-01],
    [Processamento assíncrono com fila RabbitMQ dedicada],
    [Contexto: O recorte de vídeo requer recodificação pesada com FFmpeg que excede o tempo limite de requisições HTTP normais. \ Alternativa: Execução síncrona na rota HTTP com timeout alargado (rejeitada por bloquear o gateway e threads do Node.js).],
    [API com retorno imediato HTTP 202 e Job ID. Permite escalamento horizontal independente dos workers de vídeo sem impactar o serviço web.],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-025, DQ-001],

    [DA-02],
    [Reserva atómica de quota com estorno condicional],
    [Contexto: O plano Free restringe a 5 operações diárias. Submissões concorrentes podiam esgotar recursos se a validação fosse tardia. \ Alternativa: Decrementar quota apenas no final (rejeitada por permitir submissões infinitas em paralelo).],
    [A quota é reservada no momento da submissão; se o processamento falhar ou for cancelado, a operação é reposta atomicamente em base de dados.],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-034–035, RN1],

    [DA-03],
    [Streaming com Range Requests via Cookie temporário seguro],
    [Contexto: Os reprodutores de vídeo necessitam de pedidos parciais (HTTP 206 Partial Content) para navegação temporal (_seeking_). \ Alternativa: Enviar token JWT na query string (rejeitada por expor credenciais em logs de acesso e histórico do browser).],
    [Gera-se uma rota de autorização que emite um cookie HttpOnly, Secure e SameSite Strict com validade de 5 minutos, garantindo reprodução segura.],
    [REQ-VID-TRIM-027, DQ-003],

    [DA-04],
    [Monitorização de estado via Polling leve a cada 4 segundos],
    [Contexto: No MVP, o gateway de WebSockets existente (`wsGateway`) estava acoplado ao modelo de eventos de imagem. \ Alternativa: Refatorizar o `wsGateway` para multiplexar eventos de vídeo (rejeitada por risco de instabilidade na baseline).],
    [O cliente consulta `GET /jobs/:jobId` a cada 4s. Reduz complexidade mantendo a interface reativa; atualização em tempo real via WebSockets diferida para a Fase 2.],
    [REQ-VID-TRIM-009, DQ-001],

    [DA-05],
    [Pré-validação dos metadados antes de encaminhar o corpo],
    [Contexto: o Upload pode transferir até 5 000 000 000 bytes. O frontend chama primeiro `/video/check`; o API Gateway também repete a verificação antes de encaminhar o corpo ao `projects`. Alternativa: transferir primeiro e verificar sessão, autorização e plano depois (rejeitada por desperdiçar largura de banda e armazenamento temporário).],
    [A autorização de edição, a versão do projeto, o perfil, o nome e o limite individual são verificados no backend antes da receção/encaminhamento integral. A verificação é repetida no endpoint de Upload e não depende apenas do frontend.],
    [REQ-VID-UPL-007–008, REQ-VID-UPL-012–014, REQ-VID-UPL-028, REQ-VID-UPL-032],

    [DA-06],
    [Transferência progressiva com staging em disco],
    [Contexto: os limites por ficheiro são 1 000 000 000 bytes no Free e 5 000 000 000 bytes no Premium. Nginx desativa o buffering do pedido; o API Gateway usa `PassThrough` de 64 KiB; `projects` recebe com `multer.diskStorage`; o armazenamento lê o temporário por stream e estima 2 × 16 MiB de buffers multipart. Alternativa: acumular o ficheiro integral em RAM (incompatível com os tamanhos).],
    [O alvo de pico de memória adicional é 1 GB decimal (1 000 000 000 bytes) por upload, conforme o REQ-VID-UPL-030. É referido um ensaio com ficheiro de 128 000 000 bytes, mas não estão registados o pico medido nem a configuração. O código compara apenas 32 MiB estimados com `maxUploadMemoryBytes = 1 000 000 000`; essa verificação não comprova o pico global nem valida o teto nos limites dos planos ou sob concorrência.],
    [REQ-VID-UPL-030; UC-VID-001/DQ-001],

    [DA-07],
    [Validação do conteúdo depois da receção],
    [Contexto: extensão e tipo MIME declarados pelo navegador não demonstram o conteúdo real. `projects` grava o corpo temporariamente em disco e executa `ffprobe` após a receção. Alternativa: confiar na seleção ou nos cabeçalhos do frontend (rejeitada por não validar o contentor nem os streams).],
    [Confirma MP4 válido, stream de vídeo H.264 e duração válida antes de reservar quota e enviar o objeto; a inspeção não executa processamento ou Trim.],
    [REQ-VID-UPL-009–011, REQ-VID-UPL-026–027, RNG-02],

    [DA-08],
    [Persistir o objeto antes da associação ao projeto],
    [Contexto: o vídeo só deve ficar disponível após armazenamento e associação bem-sucedidos. `projects` reserva quota, envia o ficheiro ao SeaweedFS e depois atualiza `Project.videos` em MongoDB. Alternativa: associar primeiro metadados sem objeto persistente (rejeitada por expor referências incompletas).],
    [A resposta 201 é enviada após a associação. A limpeza compensatória do objeto e a confirmação da quota são best-effort no código. O Upload aplica quota acumulada em código, embora essa regra não esteja definida no seu dossiê; em projeto partilhado, o limite por ficheiro usa o perfil do remetente e a quota acumulada usa o perfil do titular do projeto.],
    [REQ-VID-UPL-016–018, REQ-VID-UPL-029–031, REQ-VID-UPL-035, REQ-VID-UPL-037],

    [#text(hyphenate: true, "DA-SPEED-01")], [#text(hyphenate: true, "Worker independente")], [#text(hyphenate: true, "Worker independente baseado nos padrões de vídeo e em FFmpeg, em vez de alargar o worker de Trim.")], [#text(hyphenate: true, "Preserva o contrato do Trim e permite implantação independente; a fila é declarada dinamicamente pelo worker.")], [#text(hyphenate: true, "REQ-VID-SPEED-008, REQ-VID-SPEED-036–037")],

    [#text(hyphenate: true, "DA-SPEED-02")], [#text(hyphenate: true, "Segmentação e concatenação temporal")], [#text(hyphenate: true, "Construir segmentos ordenados com lacunas a 1x; trim/atrim, setpts/asetpts, atempo e concat.")], [#text(hyphenate: true, "Velocidade temporal coerente com os fatores; recodificação H.264/AAC e sem áudio artificial. Não implica cópia binária dos segmentos a 1x.")], [#text(hyphenate: true, "REQ-VID-SPEED-010–012, REQ-VID-SPEED-017, REQ-VID-SPEED-030")],

    [#text(hyphenate: true, "DA-SPEED-03")], [#text(hyphenate: true, "Quota sobre bytes efetivos")], [#text(hyphenate: true, "Contabilizar após codificar, usando size real no resultado e o utilitário videoQuota existente.")], [#text(hyphenate: true, "O storage recebe o output antes da reserva. Recusa de quota não acrescenta vídeo nem versão; rollback é best-effort e não é transação distribuída. Quota diária permanece por decidir.")], [#text(hyphenate: true, "REQ-VID-SPEED-019, REQ-VID-SPEED-031–032, REQ-VID-SPEED-034")],

    [#text(hyphenate: true, "DA-SPEED-04")], [#text(hyphenate: true, "Reutilização de resultados e eventos")], [#text(hyphenate: true, "Reutilizar o resultado e add-video existentes sem introduzir uma coleção de jobs de speed.")], [#text(hyphenate: true, "HTTP 202 confirma apenas aceitação. Não existem progresso persistente, cancelamento posterior ou aviso terminal de falha na interface.")], [#text(hyphenate: true, "REQ-VID-SPEED-009, REQ-VID-SPEED-013, REQ-VID-SPEED-015–016, REQ-VID-SPEED-038")],

    [DA-REM-01],
    [Fila e _worker_ dedicados, reutilizando o contrato do Trim],
    [Contexto: a remoção partilha o _pipeline_ assíncrono (A2 do UC-VID-003). Alternativa: estender o `videoTrimWorker` com um novo tipo de mensagem (rejeitada por acoplar operações distintas e comprometer a regressão do Trim).],
    [_Worker_ independente `videoRemoveSegmentWorker` com fila durável própria e endpoints internos no `projects`, replicando o ciclo de vida de tarefas (`QUEUED` $->$ `PROCESSING` $->$ `COMPLETED`/`FAILED`/`CANCELLED`), o lease com repetição única e o modelo transacional de quotas do Trim.],
    [REQ-VID-REM-004, REQ-VID-REM-007, REQ-VID-REM-014, REQ-VID-REM-023–025; UC-VID-003/DQ-001],

    [DA-REM-02],
    [Corte por extração contínua ou concatenação temporal],
    [Contexto: cortes que incidem num extremo dispensam concatenação. Alternativa: sempre concatenar duas partes, mesmo nos cortes de extremo (rejeitada por recodificar e demorar desnecessariamente).],
    [Extremos: `-ss`/`-t` com recodificação H.264 e AAC apenas quando existe áudio; intermédio: `filter_complex` com `trim`/`atrim`, `setpts`/`asetpts` e `concat`. A saída é validada com `ffprobe` (duração com tolerância de 0,6 s e AAC quando existe áudio) e usa `movflags +faststart`.],
    [REQ-VID-REM-005, REQ-VID-REM-026; UC-VID-003/RN2],
  ),
)

#paisagem[
  == Fluxo de processamento de vídeo

  === UC-VID-001 — Carregamento de vídeo (_Upload_)

  #align(center)[
    #figure(
      image("../images/picturas_sequencia_upload.svg", width: 96%, height: 12.5cm, fit: "contain"),
      caption: [Diagrama de sequência do carregamento de vídeo para um projeto (UC-VID-001).],
    )
  ]
]

O fluxo de Upload é síncrono e termina com a associação do objeto persistente ao projeto; não publica tarefas RabbitMQ nem invoca o `videoTrimWorker`.
1. *Seleção e pré-validação:* `AddVideoDialog` permite escolher um ficheiro, verifica preliminarmente extensão/tipo declarado e ficheiro não vazio e apresenta nome e tamanho. Ao confirmar, a interface chama `POST /video/check` com JWT, versão do projeto, nome e tamanho. O API Gateway encaminha o pedido para `projects`, que verifica autorização de edição, versão, nome repetido e limite individual, consultando `users` para obter o perfil.
2. *Transferência progressiva:* Após a pré-validação, a interface envia o multipart. O Nginx desativa o buffering do pedido; o API Gateway repete a verificação antes de encaminhar o corpo, usando um `PassThrough` com `highWaterMark` de 64 KiB. `projects` recebe o corpo com `multer.diskStorage` em ficheiro temporário, sem manter o vídeo integral em RAM.
3. *Validação e armazenamento:* Depois da receção, `projects` verifica o tamanho real e usa `ffprobe` para confirmar contentor MP4, vídeo H.264 e duração válida. Reserva depois quota em `VideoStorageAccount`, envia o temporário por stream através de `mediaStorageService` e persiste o objeto no SeaweedFS. O limite por ficheiro é 1 000 000 000 bytes no Free e 5 000 000 000 bytes no Premium; estes valores não são o limite de memória.
4. *Associação e resposta:* Após receber a chave do objeto, `projects` acrescenta os metadados a `Project.videos` em `projects_mongoDB`, incrementa a versão e confirma a quota reservada. A interface recebe HTTP 201, atualiza a lista do projeto e confirma o carregamento. A lista `videos` é separada da lista de imagens `imgs`.

O fluxo progressivo reduz cópias em memória: o Gateway limita o buffer do `PassThrough` a 64 KiB, `projects` usa disco temporário e `mediaStorageService` estima até 2 × 16 MiB de buffers multipart. O alvo do REQ-VID-UPL-030 é um pico adicional de 1 GB decimal (1 000 000 000 bytes) por upload. O ensaio com ficheiro de 128 000 000 bytes mencionado no capítulo de testes não documenta um valor medido nem demonstra conformidade nos limites dos planos ou sob concorrência. A constante `maxUploadMemoryBytes` compara apenas a estimativa de buffers multipart; não impõe um limite ao pico total. A interface comunica estado pendente, sucesso ou falha, sem percentagem de progresso.

As falhas de sessão, permissão, versão, nome ou limite são recusadas na pré-validação. A inspeção final rejeita conteúdo incompatível; quota acumulada insuficiente resulta em HTTP 507 e falha de armazenamento em HTTP 502. Se a associação MongoDB falhar depois da gravação do objeto, o serviço tenta removê-lo e libertar quota; a compensação é best-effort. O dossiê não especifica quota acumulada no Upload, embora o código aplique `videoQuota`. Em projetos partilhados, o limite individual é calculado pelo perfil do remetente, enquanto a quota acumulada é calculada pelo perfil do titular do projeto.

#paisagem[
  === UC-VID-002 — Recorte temporal (_Trim_)

  #align(center)[
    #figure(
      image("../images/picturas_sequencia_trim.svg", width: 80%),
      caption: [Diagrama de sequência do fluxo ponta a ponta de processamento de vídeo (_Trim_)],
    )
  ]
]

O fluxo operacional do processamento de um recorte temporal desdobra-se nos seguintes passos coordenados:
1. *Parametrização e Submissão:* O utilizador seleciona $t_(i n)$ e $t_(o u t)$ na interface web e clica em "Confirmar Recorte". O frontend envia `POST /projects/:owner/:project/video/:videoId/trim` com os parâmetros.
2. *Validação e Reserva:* O serviço `projects` valida os limites temporais e consulta o serviço `users` para reservar atomicamente uma operação diária (se utilizador `free`). Verifica ainda se a quota de armazenamento acumulada da conta permite a adição do vídeo.
3. *Enfileiramento:* O serviço `projects` cria o documento `TrimJob` em MongoDB com estado `QUEUED`, publica uma mensagem contendo o `jobId` na fila RabbitMQ `video_trim_queue` e devolve HTTP 202 Accepted com o Job ID ao cliente.
4. *Consumo e Execução:* O `videoTrimWorker` consome a mensagem da fila, atualiza o job para `PROCESSING`, descarrega o vídeo original do SeaweedFS e executa o binário nativo FFmpeg numa diretoria efémera (`/tmp/picturas-trim-<jobId>`).
5. *Conclusão e Registo:* O worker valida o MP4 gerado com FFprobe, envia o novo ficheiro para o SeaweedFS, regista o novo vídeo na coleção do projeto com metadados de proveniência (`sourceVideoId`, `jobId`) e atualiza o job para `COMPLETED`. A quota de utilizador é confirmada em `users`.
6. *Notificação e Streaming:* O frontend deteta o estado `COMPLETED` através do polling periódico, obtém a URL temporária de reprodução via cookie seguro e apresenta o vídeo recortado pronto para visualização e descarregamento.

=== UC-VID-003 — Remover segmento (_Remove segment_)

O fluxo operacional da remoção de segmento reutiliza o padrão assíncrono do Trim, com fila e _worker_ dedicados:
1. *Seleção e marcação:* O utilizador abre o diálogo `RemoveSegmentVideoDialog` sobre um vídeo do projeto; o reprodutor HTML5 carrega a duração e o diálogo apresenta a marcação temporal com passos de 0,01 s, o destaque visual do trecho a eliminar e a duração resultante. A pré-visualização (FA1) simula localmente a união das partes, saltando o intervalo durante a reprodução, sem pedidos ao servidor nem consumo de quota.
2. *Submissão e validação:* Ao acionar «Apply cut», o frontend envia `POST /projects/:user/:project/video/:videoId/remove-segment` com `start`/`end`, JWT e `X-Project-Version`. O serviço `projects` valida a sessão e a permissão de edição, exige o cabeçalho de versão (HTTP 428 `VERSION_REQUIRED` se ausente; 409 `PROJECT_CONFLICT` se desatualizado), recusa formatos não MP4/H.264 com base nos metadados registados (415 `UNSUPPORTED_VIDEO`), valida o intervalo (400 `INVALID_INTERVAL`) e a duração resultante ≥ 1,0 s (400 `DURATION_TOO_SHORT`) e verifica a quota de armazenamento (507 `STORAGE_QUOTA_EXCEEDED`).
3. *Reserva e enfileiramento:* O serviço consulta o plano em `users`, reserva 1 operação diária no perfil `free` (429 `DAILY_QUOTA_EXHAUSTED` se esgotada), cria o `RemoveSegmentJob` em `QUEUED` com Job ID, nome derivado `<nome>-cut.mp4` e `resultId`, publica o `jobId` na fila `video_remove_segment_queue` e devolve HTTP 202 com o estado inicial da tarefa.
4. *Consumo e execução:* O `videoRemoveSegmentWorker` consome a mensagem, reclama a tarefa (lease de 600 s), descarrega o original pela URL assinada do `mediaStorageService`, valida com `ffprobe` o contentor, o codec e a duração, e remove o intervalo: extração contínua (`-ss`/`-t`) nos cortes de extremo ou `filter_complex` com concatenação nos cortes intermédios, recodificando H.264 e AAC apenas quando existe faixa de áudio. O progresso (0–99 %) é reportado ao `projects`.
5. *Conclusão e registo:* O _worker_ reserva o armazenamento exato, envia o novo MP4 ao `mediaStorageService` (PUT protegido pela chave interna) e publica `complete` com tamanho, duração e dimensões; o `projects` associa o novo vídeo com metadados e proveniência (`sourceVideoId`, `removeSegmentJobId`), incrementa a versão do projeto e confirma as quotas diária e de armazenamento. Em falha, publica `fail` — com repetição única quando recuperável e `FAILED` com estorno em falha definitiva — e liberta a reserva.
6. *Acompanhamento e cancelamento:* O diálogo consulta o estado de 4 em 4 s e apresenta o estado e o progresso; na conclusão, a galeria é atualizada sem recarregar a página (invalidação de cache no cliente) e o resultado é reproduzível e descarregável. O cancelamento (`DELETE .../remove-segment/jobs/:jobId`) marca a tarefa `CANCELLED`, estorna a operação diária e liberta a reserva; o _worker_ verifica o estado entre etapas e abandona o processamento sem publicar resultado.

#paisagem[
=== UC-VID-004 — Compilar vídeos (_Compile_)
#align(center)[
  #figure(
    image("../images/picturas_sequencia_compile.svg", width: 96%, height: 13cm, fit: "contain"),
    caption: [Diagrama de sequência de UC-VID-004 — compilação assíncrona de vídeos.],
  )
]
]

#paisagem[
  === UC-VID-005 — Modificar velocidade

  #align(center)[
    #figure(
      image("../images/picturas_sequencia_speed.svg", width: 100%, height: 13cm, fit: "contain"),
      caption: [Diagrama de sequência de UC-VID-005 — percurso principal da alteração de velocidade por intervalos.],
    )
  ]
]

#paisagem[
  #align(center)[
    #figure(
      image("../images/picturas_sequencia_speed_resultados.svg", width: 100%, height: 14cm, fit: "contain"),
      caption: [Diagrama de sequência de UC-VID-005 — detalhe do tratamento de resultados, quota e falhas.],
    )
  ]
]

O percurso é frontend → API Gateway → Projects → video_speed_queue → videoSpeedWorker/FFmpeg → Media Storage/SeaweedFS → video_results_queue → Projects/MongoDB/quota → ws_queue/project-op/add-video → biblioteca.

1. *Configuração e submissão:* SpeedVideoDialog recebe o vídeo e configura uma lista não vazia de intervalos com início, fim e velocidade. Os fatores válidos são 0,5x, 1x e 2x; a interface permite editar/remover e rejeita sobreposições. Envia POST /projects/:user/:project/video/:videoId/speed com intervals, JWT, contexto de partilha e versão do projeto.
2. *Aceitação:* Projects verifica edição, versão e associação do original; valida os números e intervalos, ordena-os e cria messageId, newVideoId e nome seguro. Publica procedure video_speed e devolve HTTP 202 com status queued. Não reserva operações diárias; não mede a duração do ficheiro nesta rota.
3. *Leitura e validação real:* O worker obtém a URL interna em GET /video/:ownerId/:projectId/:videoId/url usando X-Internal-Video-Key, descarrega para TemporaryDirectory e usa ffprobe para verificar MP4/H.264, duração e existência de áudio. Rejeita intervalos fora da duração medida.
4. *Transformação:* Constrói os segmentos por ordem original e inclui as partes não selecionadas a 1x. Aplica trim e setpts=(PTS-STARTPTS)/speed ao vídeo; quando existe áudio, atrim, asetpts e atempo com o mesmo fator. Concatena e codifica MP4 com libx264, AAC apenas se existir áudio e movflags +faststart. O original nunca é usado como ficheiro de saída.
5. *Armazenamento e resultado:* Envia PUT /video/:ownerId/:projectId/:newVideoId com a chave interna, Content-Type video/mp4 e Content-Length real. Publica sucesso em video_results_queue com size igual ao tamanho do output e correlationId igual ao messageId do pedido. A mensagem tem também messageId próprio, timestamp, status, procedure e parameters.
6. *Quota e associação:* Projects verifica se o resultado já está associado, reserva size em videoQuota na conta do proprietário, acrescenta o vídeo e incrementa version. Confirma a contabilização e emite add-video pelo canal existente. A repetição sequencial não acrescenta novamente o resultado nem os bytes; não se afirma exatamente uma vez sob concorrência.
7. *Falhas e limites:* Uma falha do worker provoca nack sem requeue e tentativa de resultado de erro VIDEO_SPEED_FAILED. Projects apenas regista status error. No tratamento de sucesso cuja quota/associação falha, tenta DELETE/release após confirmar que o vídeo não está associado. Se commit falhar após associação, mantém os bytes contabilizados. Um upload concluído com falha de publicação pode deixar output órfão; não há recolha automática garantida.

*Contrato do pedido:* procedure video_speed; messageId e timestamp no envelope; ownerId, projectId, videoId, newVideoId, newVideoName, intervals, callerId e projectVersion nos parâmetros. O size de entrada, quando presente, não é a medida de quota do resultado. O resultado de sucesso substitui size pelos bytes efetivos do novo ficheiro.

A interface distingue erro HTTP de submissão de processamento ainda pendente: ao receber 202 mostra confirmação e fecha o diálogo; a atualização final da biblioteca usa o evento de projeto. Não existe preview transformado, percentagem de progresso ou cancelamento após submissão.

== Impacto na instalação e execução

A extensão inclui os workers de Trim e speed na orquestração Docker Compose:
- *Upload:* reutiliza Nginx, API Gateway, `projects`, `mediaStorageService`, SeaweedFS e MongoDB já existentes; requer a rota de armazenamento de vídeo e a configuração de encaminhamento/streaming descritas acima. O processamento do Upload não requer RabbitMQ nem o worker de Trim. O alvo de memória adicional de 1 GB decimal (1 000 000 000 bytes) por upload não é imposto como limite global pelo código e a sua validação nos limites dos planos e sob concorrência permanece pendente.
- *Contentor `video_trim_worker`:* Construído a partir de `./videoTrimWorker`, com imagem Python 3.11 e FFmpeg nativo instalado. Liga-se à rede `elk` e depende de `rabbitmq` saudável, `projects` e `img_storage` iniciados.
- *Filas de Mensagens:* Declaração da fila durável `video_trim_queue` no RabbitMQ já em execução.
- *Volumes e Armazenamento:* O worker utiliza um volume efémero em memória/disco temporário (`/tmp`), totalmente limpo após cada tarefa. Não requer configuração ad-hoc nem instalação de binários no sistema operativo anfitrião.
- *Variáveis de Ambiente:* O Compose configura `RABBITMQ_HOST`, `RABBITMQ_PORT`, `RABBITMQ_USER`, `RABBITMQ_PASS` e `INTERNAL_VIDEO_KEY` no worker de Trim. Este lê ainda `PROJECTS_URL` e `MEDIA_STORAGE_URL`, com valores predefinidos `https://projects:9001` e `http://img_storage:11000`; estas duas variáveis não são explicitamente definidas no serviço de Trim no Compose atual. A chave interna deve coincidir entre os serviços envolvidos. As instruções passo a passo para arranque e execução da suite de testes constam no Anexo A.

- *Contentor `video_speed`:* O serviço Compose chama-se video_speed e usa build ./videoSpeedWorker, dependendo de rabbitmq e img_storage na rede elk. Usa RABBITMQ_HOST/PORT/USER/PASS, MEDIA_STORAGE_URL e INTERNAL_VIDEO_KEY; a chave interna deve coincidir com a configurada no Media Storage e não deve ser divulgada no cliente. FFmpeg/ffprobe são instalados na imagem do worker. As filas video_speed_queue e video_results_queue são declaradas pelo worker, sem definições estáticas adicionais. O modo --once termina após tratar uma mensagem; não é um cancelamento de tarefa.

- *Contentor `video_remove_segment_worker`:* Construído a partir de `./videoRemoveSegmentWorker`, com FFmpeg/ffprobe instalados na imagem; depende de `rabbitmq` saudável e de `projects` e `img_storage` iniciados, na rede `elk`, configurado com `RABBITMQ_HOST/PORT/USER/PASS` e `INTERNAL_VIDEO_KEY` (a chave interna deve coincidir entre os serviços envolvidos). A fila durável `video_remove_segment_queue` é declarada pelo próprio worker na exchange `picturas`, sem definições estáticas adicionais.
