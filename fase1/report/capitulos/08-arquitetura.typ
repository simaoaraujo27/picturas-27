#import "../template.typ": *

= Alterações Arquiteturais

#orientacao[
  Partam do documento de solução arquitetural de base e descrevam apenas o *delta* introduzido pelo suporte a
  vídeo. O nível de detalhe é o de um MVP: o suficiente para que outra equipa perceba, mantenha e estenda a
  solução na Fase 2. Cada alteração deve estar ligada aos requisitos que a motivam.
]

== Visão geral das alterações

O incremento de suporte a manipulação de vídeo estende a arquitetura de microsserviços do PictuRAS sem quebrar os fluxos síncronos e assíncronos de processamento de imagem existentes. Para acomodar a natureza computacionalmente intensiva e demorada do vídeo, introduziu-se um pipeline assíncrono isolado com fila dedicada no RabbitMQ, um novo nó de execução autónomo (`videoTrimWorker`) e extensões aos serviços de projetos, utilizadores e interface web.

#figure(
  image("../images/arquitetura_componentes.png", width: 90%),
  caption: [Vista de componentes da extensão de vídeo (novos e alterados destacados)],
)

#tab([Componentes novos e alterados],
  tabela(
    colunas: (3.2cm, 1.8cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [Componente / serviço], [Estado], [Responsabilidade / alteração], [Requisitos],

    [`videoTrimWorker`],
    [Novo],
    [Microsserviço em Python com FFmpeg autónomo. Consome tarefas da fila `video_trim_queue`, efetua download de vídeo a partir do SeaweedFS, executa recorte temporal exato ao fotograma (ou _stream copy_), valida metadados de saída, persiste o resultado no armazenamento de objetos e notifica a conclusão do job.],
    [REQ-VID-TRIM-010, REQ-VID-TRIM-011, REQ-VID-TRIM-012, REQ-VID-TRIM-018, REQ-VID-TRIM-026, REQ-VID-TRIM-028],

    [`projects`],
    [Alterado],
    [Gestão do ciclo de vida de tarefas (`TrimJob`) em MongoDB; publicação de mensagens no RabbitMQ; fiscalização de quotas de armazenamento em disco por utilizador (1 GB / 5 GB); endpoints de listagem de jobs, cancelamento voluntário e emissão de cookies temporários seguros para reprodução HTTP Range.],
    [REQ-VID-TRIM-004, REQ-VID-TRIM-008, REQ-VID-TRIM-014, REQ-VID-TRIM-020, REQ-VID-TRIM-021, REQ-VID-TRIM-022, REQ-VID-TRIM-027],

    [`users`],
    [Alterado],
    [Extensão da gestão de quotas de operações diárias (`FREE_DAILY_OP = 5`): disponibilização de reserva atómica de operação por Job ID na submissão, confirmação na conclusão com sucesso e estorno automático em caso de falha de processamento ou cancelamento voluntário.],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-022],

    [`frontend`],
    [Alterado],
    [Componente `VideoWorkspace` com reprodutor de vídeo HTML5, linha temporal interativa com seleção de marcadores de início e fim, pré-visualização local no cliente, barra indicadora de ocupação da quota de disco, acompanhamento de tarefas via _polling_ a cada 4 segundos e opção de cancelamento.],
    [REQ-VID-TRIM-001, REQ-VID-TRIM-002, REQ-VID-TRIM-003, REQ-VID-TRIM-009, REQ-VID-TRIM-019, REQ-VID-TRIM-022, REQ-VID-TRIM-024],

    [`apiGateway`],
    [Alterado],
    [Reencaminhamento das rotas de manipulação de vídeo (`/projects/:owner/:project/video/*`) para o microsserviço `projects`, preservando autenticação JWT e controlo de partilhas de projetos (`read`/`edit`).],
    [REQ-VID-TRIM-019, REQ-VID-TRIM-027],

    [`rabbitMQ`],
    [Alterado],
    [Declaração da fila durável `video_trim_queue`, isolando a carga de processamento de vídeo das filas legadas de processamento de imagem (`brightness_queue`, etc.).],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-010],
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
    [REQ-VID-TRIM-008, REQ-VID-TRIM-025, DQ-001],

    [DA-02],
    [Reserva atómica de quota com estorno condicional],
    [Contexto: O plano Free restringe a 5 operações diárias. Submissões concorrentes podiam esgotar recursos se a validação fosse tardia. \ Alternativa: Decrementar quota apenas no final (rejeitada por permitir submissões infinitas em paralelo).],
    [A quota é reservada no momento da submissão; se o processamento falhar ou for cancelado, a operação é reposta atomicamente em base de dados.],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, RN1],

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
  ),
)

== Fluxo de processamento de vídeo

#figure(
  image("../images/sequencia_processamento.png", width: 95%),
  caption: [Diagrama de sequência do fluxo ponta a ponta de processamento de vídeo (_Trim_)],
)

O fluxo operacional do processamento de um recorte temporal desdobra-se nos seguintes passos coordenados:
1. *Parametrização e Submissão:* O utilizador seleciona $t_(i n)$ e $t_(o u t)$ na interface web e clica em "Confirmar Recorte". O frontend envia `POST /projects/:owner/:project/video/:videoId/trim` com os parâmetros.
2. *Validação e Reserva:* O serviço `projects` valida os limites temporais e consulta o serviço `users` para reservar atomicamente uma operação diária (se utilizador `free`). Verifica ainda se a quota de armazenamento acumulada da conta permite a adição do vídeo.
3. *Enfileiramento:* O serviço `projects` cria o documento `TrimJob` em MongoDB com estado `QUEUED`, publica uma mensagem contendo o `jobId` na fila RabbitMQ `video_trim_queue` e devolve HTTP 202 Accepted com o Job ID ao cliente.
4. *Consumo e Execução:* O `videoTrimWorker` consome a mensagem da fila, atualiza o job para `PROCESSING`, descarrega o vídeo original do SeaweedFS e executa o binário nativo FFmpeg numa diretoria efémera (`/tmp/picturas-trim-<jobId>`).
5. *Conclusão e Registo:* O worker valida o MP4 gerado com FFprobe, envia o novo ficheiro para o SeaweedFS, regista o novo vídeo na coleção do projeto com metadados de proveniência (`sourceVideoId`, `jobId`) e atualiza o job para `COMPLETED`. A quota de utilizador é confirmada em `users`.
6. *Notificação e Streaming:* O frontend deteta o estado `COMPLETED` através do polling periódico, obtém a URL temporária de reprodução via cookie seguro e apresenta o vídeo recortado pronto para visualização e descarregamento.

== Impacto na instalação e execução

A extensão introduz o novo contentor `video_trim_worker` na orquestração Docker Compose:
- *Contentor `video_trim_worker`:* Construído a partir de imagem Python 3.11 com FFmpeg nativo instalado. Liga-se às redes `internal` (RabbitMQ) e `storage` (SeaweedFS).
- *Filas de Mensagens:* Declaração da fila durável `video_trim_queue` no RabbitMQ já em execução.
- *Volumes e Armazenamento:* O worker utiliza um volume efémero em memória/disco temporário (`/tmp`), totalmente limpo após cada tarefa. Não requer configuração ad-hoc nem instalação de binários no sistema operativo anfitrião.
- *Variáveis de Ambiente:* Configuradas no `docker-compose.yaml` para resolução interna de DNS dos serviços (`RABBITMQ_URI`, `PROJECTS_SERVICE_URL`, `MEDIA_STORAGE_URL`). As instruções passo a passo para arranque e execução da suite de testes constam no Anexo A.
