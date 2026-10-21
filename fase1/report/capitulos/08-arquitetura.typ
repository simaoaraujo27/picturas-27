#import "../template.typ": *

= Alterações Arquiteturais

#orientacao[
  Partam do documento de solução arquitetural de base e descrevam apenas o *delta* introduzido pelo suporte a
  vídeo. O nível de detalhe é o de um MVP: o suficiente para que outra equipa perceba, mantenha e estenda a
  solução na Fase 2. Cada alteração deve estar ligada aos requisitos que a motivam.
]

== Visão geral das alterações

O suporte a vídeo acrescenta dois fluxos à arquitetura existente: o Upload, síncrono, que reutiliza os serviços web, de projetos e de armazenamento; e o Trim, assíncrono, que utiliza a fila dedicada do RabbitMQ e o novo `videoTrimWorker`. O Upload estende o `frontend`, o API Gateway, o Nginx, `projects` e `mediaStorageService`; usa o SeaweedFS e MongoDB existentes e não publica tarefas de processamento.

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

    [`Nginx`],
    [Estendido],
    [Rota específica de Upload com limite de corpo de 6 GB, `proxy_request_buffering off` e timeouts alargados, encaminhando o corpo progressivamente para o API Gateway. O limite do proxy não substitui os limites por plano aplicados pela aplicação.],
    [REQ-VID-UPL-012–014, REQ-VID-UPL-030],

    [`videoTrimWorker`],
    [Novo],
    [Microsserviço em Python com FFmpeg autónomo. Consome tarefas da fila `video_trim_queue`, efetua download de vídeo a partir do SeaweedFS, executa recorte temporal exato ao fotograma (ou _stream copy_), valida metadados de saída, persiste o resultado no armazenamento de objetos e notifica a conclusão do job.],
    [REQ-VID-TRIM-010, REQ-VID-TRIM-011, REQ-VID-TRIM-012, REQ-VID-TRIM-018, REQ-VID-TRIM-026, REQ-VID-TRIM-028],

    [`projects`],
    [Alterado],
    [No Upload, verifica autorização e versão do projeto, recebe o ficheiro em temporário de disco, valida-o com `ffprobe`, reserva quota, envia o objeto e associa metadados a `Project.videos`, separada de `imgs`. \\ Gestão do ciclo de vida de tarefas (`TrimJob`) em MongoDB; publicação de mensagens no RabbitMQ; fiscalização de quotas de armazenamento em disco por utilizador (1 GB / 5 GB); endpoints de listagem de jobs, cancelamento voluntário e emissão de cookies temporários seguros para reprodução HTTP Range.],
    [REQ-VID-UPL-007–014, REQ-VID-UPL-016–019, REQ-VID-UPL-022–029, REQ-VID-UPL-030–032, REQ-VID-UPL-035, REQ-VID-UPL-037–040; REQ-VID-TRIM-004, REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-014, REQ-VID-TRIM-031–033, REQ-VID-TRIM-020, REQ-VID-TRIM-021, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038, REQ-VID-TRIM-027],

    [`users`],
    [Mantido no Upload; alterado no Trim],
    [No Upload, é consultado para obter o perfil que determina o limite por ficheiro; a funcionalidade não consome quota diária de operações. \\ Extensão da gestão de quotas de operações diárias (`FREE_DAILY_OP = 5`): disponibilização de reserva atómica de operação por Job ID na submissão, confirmação na conclusão com sucesso e estorno automático em caso de falha de processamento ou cancelamento voluntário.],
    [REQ-VID-UPL-012–013; REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-034–035, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038],

    [`frontend`],
    [Alterado],
    [Para Upload, `AddVideoDialog` seleciona um ficheiro, valida extensão/tipo declarados, apresenta nome e tamanho e comunica envio pendente, conclusão ou falha; o código também contém handlers de arrastar e largar, embora o dossiê marque essa interação como adiada. \\ Componente `VideoWorkspace` com reprodutor de vídeo HTML5, linha temporal interativa com seleção de marcadores de início e fim, pré-visualização local no cliente, barra indicadora de ocupação da quota de disco, acompanhamento de tarefas via _polling_ a cada 4 segundos e opção de cancelamento.],
    [REQ-VID-UPL-001–006, REQ-VID-UPL-015, REQ-VID-UPL-018–019, REQ-VID-UPL-021, REQ-VID-UPL-028, REQ-VID-UPL-033, REQ-VID-UPL-036–041; REQ-VID-TRIM-001, REQ-VID-TRIM-002, REQ-VID-TRIM-003, REQ-VID-TRIM-009, REQ-VID-TRIM-019, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038, REQ-VID-TRIM-024],

    [`apiGateway`],
    [Alterado],
    [No Upload, verifica JWT, encaminha a pré-validação de metadados e transmite o corpo por `PassThrough` com `highWaterMark` de 64 KiB, após nova verificação do pedido antes do encaminhamento. \\ Reencaminhamento das rotas de manipulação de vídeo (`/projects/:owner/:project/video/*`) para o microsserviço `projects`, preservando autenticação JWT e controlo de partilhas de projetos (`read`/`edit`).],
    [REQ-VID-UPL-007–008, REQ-VID-UPL-012–014, REQ-VID-UPL-022–024, REQ-VID-UPL-028–030, REQ-VID-UPL-032, REQ-VID-UPL-039; REQ-VID-TRIM-019, REQ-VID-TRIM-027],

    [`mediaStorageService` (`img_storage`)],
    [Estendido],
    [Nova rota interna protegida por chave e identificadores validados recebe o MP4 em stream e envia-o ao SeaweedFS via S3 multipart, com partes de 16 MiB e `queueSize = 2` (estimativa de buffers multipart: 32 MiB). As rotas de imagens mantêm-se separadas.],
    [REQ-VID-UPL-016–018, REQ-VID-UPL-029–031, REQ-VID-UPL-035, REQ-VID-UPL-037],

    [SeaweedFS (S3)],
    [Mantido],
    [Armazenamento de objetos existente, reutilizado para os vídeos originais e para os resultados do Trim. O `mediaStorageService` controla a chave interna e envia o conteúdo; não se introduz outro object storage.],
    [REQ-VID-UPL-016–017, REQ-VID-UPL-029, REQ-VID-TRIM-012–014, REQ-VID-TRIM-023, REQ-VID-TRIM-039–040],

    [`projects_mongoDB` / `Project.videos`],
    [Estendido],
    [O documento do projeto recebe metadados e referência ao objeto na lista `videos`, separada da lista de imagens `imgs`; a associação incrementa a versão do projeto. O estado da quota acumulada é guardado no modelo `VideoStorageAccount`, na mesma base de dados.],
    [REQ-VID-UPL-016–019, REQ-VID-UPL-029, REQ-VID-UPL-035],

    [`videoQuota` / `VideoStorageAccount`],
    [Novo],
    [Reserva, confirmação e libertação da quota acumulada de vídeo por conta. O código usa este mecanismo também no Upload, além de impor o limite individual por ficheiro; o dossiê do Upload não especifica a quota acumulada, pelo que a regra aplicável ao UC-VID-001 carece de harmonização.],
    [REQ-VID-UPL-016–017; REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-039–040, REQ-VID-TRIM-024],

    [`rabbitMQ`],
    [Alterado],
    [Declaração da fila durável `video_trim_queue`, isolando a carga de processamento de vídeo das filas legadas de processamento de imagem (`brightness_queue`, etc.).],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-010],
  ),
)

== Decisões arquiteturais

#tab([Decisões arquiteturais],
  tabela(
    colunas: (1.3cm, 2.5cm, 1fr, 3.2cm, 2.5cm),
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
    [O alvo de pico de memória adicional é 1 GB decimal (1 000 000 000 bytes) por upload, conforme o REQ-VID-UPL-030. Não existem medições experimentais. O código compara apenas 32 MiB estimados com `maxUploadMemoryBytes = 1 000 000 000`; essa verificação não comprova o pico global.],
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
  ),
)

== Fluxo de processamento de vídeo

=== UC-VID-001 — Carregamento de vídeo (_Upload_)

#paisagem[
  #align(center)[
    #figure(
      image("../images/picturas_sequencia_upload.svg", width: 96%),
      caption: [Diagrama de sequência do carregamento de vídeo para um projeto (UC-VID-001).],
    )
  ]
]

O fluxo de Upload é síncrono e termina com a associação do objeto persistente ao projeto; não publica tarefas RabbitMQ nem invoca o `videoTrimWorker`.
1. *Seleção e pré-validação:* `AddVideoDialog` permite escolher um ficheiro, verifica preliminarmente extensão/tipo declarado e ficheiro não vazio e apresenta nome e tamanho. Ao confirmar, a interface chama `POST /video/check` com JWT, versão do projeto, nome e tamanho. O API Gateway encaminha o pedido para `projects`, que verifica autorização de edição, versão, nome repetido e limite individual, consultando `users` para obter o perfil.
2. *Transferência progressiva:* Após a pré-validação, a interface envia o multipart. O Nginx desativa o buffering do pedido; o API Gateway repete a verificação antes de encaminhar o corpo, usando um `PassThrough` com `highWaterMark` de 64 KiB. `projects` recebe o corpo com `multer.diskStorage` em ficheiro temporário, sem manter o vídeo integral em RAM.
3. *Validação e armazenamento:* Depois da receção, `projects` verifica o tamanho real e usa `ffprobe` para confirmar contentor MP4, vídeo H.264 e duração válida. Reserva depois quota em `VideoStorageAccount`, envia o temporário por stream através de `mediaStorageService` e persiste o objeto no SeaweedFS. O limite por ficheiro é 1 000 000 000 bytes no Free e 5 000 000 000 bytes no Premium; estes valores não são o limite de memória.
4. *Associação e resposta:* Após receber a chave do objeto, `projects` acrescenta os metadados a `Project.videos` em `projects_mongoDB`, incrementa a versão e confirma a quota reservada. A interface recebe HTTP 201, atualiza a lista do projeto e confirma o carregamento. A lista `videos` é separada da lista de imagens `imgs`.

O fluxo progressivo reduz cópias em memória: o Gateway limita o buffer do `PassThrough` a 64 KiB, `projects` usa disco temporário e `mediaStorageService` estima até 2 × 16 MiB de buffers multipart. O alvo do REQ-VID-UPL-030 é um pico adicional de 1 GB decimal (1 000 000 000 bytes) por upload, ainda não medido. A constante `maxUploadMemoryBytes` compara apenas a estimativa de buffers multipart; não impõe um limite ao pico total. A interface comunica estado pendente, sucesso ou falha, sem percentagem de progresso.

As falhas de sessão, permissão, versão, nome ou limite são recusadas na pré-validação. A inspeção final rejeita conteúdo incompatível; quota acumulada insuficiente resulta em HTTP 507 e falha de armazenamento em HTTP 502. Se a associação MongoDB falhar depois da gravação do objeto, o serviço tenta removê-lo e libertar quota; a compensação é best-effort. O dossiê não especifica quota acumulada no Upload, embora o código aplique `videoQuota`. Em projetos partilhados, o limite individual é calculado pelo perfil do remetente, enquanto a quota acumulada é calculada pelo perfil do titular do projeto.

=== UC-VID-002 — Recorte temporal (_Trim_)

#paisagem[
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

== Impacto na instalação e execução

A extensão introduz o novo contentor `video_trim_worker` na orquestração Docker Compose:
- *Upload:* reutiliza Nginx, API Gateway, `projects`, `mediaStorageService`, SeaweedFS e MongoDB já existentes; requer a rota de armazenamento de vídeo e a configuração de encaminhamento/streaming descritas acima. O processamento do Upload não requer RabbitMQ nem o worker de Trim. O alvo de memória adicional de 1 GiB por upload ainda não é imposto nem validado experimentalmente pelo código atual.
- *Contentor `video_trim_worker`:* Construído a partir de imagem Python 3.11 com FFmpeg nativo instalado. Liga-se às redes `internal` (RabbitMQ) e `storage` (SeaweedFS).
- *Filas de Mensagens:* Declaração da fila durável `video_trim_queue` no RabbitMQ já em execução.
- *Volumes e Armazenamento:* O worker utiliza um volume efémero em memória/disco temporário (`/tmp`), totalmente limpo após cada tarefa. Não requer configuração ad-hoc nem instalação de binários no sistema operativo anfitrião.
- *Variáveis de Ambiente:* Configuradas no `docker-compose.yaml` para resolução interna de DNS dos serviços (`RABBITMQ_URI`, `PROJECTS_SERVICE_URL`, `MEDIA_STORAGE_URL`). As instruções passo a passo para arranque e execução da suite de testes constam no Anexo A.
