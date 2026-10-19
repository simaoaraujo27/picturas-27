#import "../template.typ": *

= Impacto no Sistema Existente

#orientacao[
  Que elementos do PictuRAS existente (perfis, quotas, armazenamento, biblioteca, encadeamento, lote,
  exportação, …) e do documento de requisitos de base (UCnn, RFnn, RNFnn) são afetados pelas funcionalidades
  de vídeo. Para cada elemento: *Manter* (fica igual), *Estender* (passa a fazer mais) ou *Alterar* (muda o
  comportamento atual). Incluam todos os requisitos ALT e os NOVO que interagem com mecanismos existentes.
  Se duas funcionalidades afetam o mesmo elemento de forma diferente, há uma inconsistência a resolver aqui.
]

#paisagem[#tab([Impacto no sistema existente],
  tabela(
    colunas: (3.6cm, 1.8cm, 1fr, 2.2cm, 3.2cm),
    tamanho: 8.5pt,
    [Elemento existente afetado], [Impacto], [Descrição do impacto], [Caso(s) de uso], [Requisitos],

    [Interface Web (`frontend`) / `AddVideoDialog` e `VideoWorkspace`],
    [Estender],
    [A interface existente passa a disponibilizar o carregamento de um vídeo para o projeto aberto, com validação preliminar, apresentação do nome e tamanho, confirmação e estados de envio, sucesso ou falha. O código inclui handlers de arrastar e largar, apesar de essa interação estar adiada no dossiê do Upload. Para o Trim, acrescenta reprodutor HTML5, linha temporal, pré-visualização local, indicador de quota, acompanhamento de tarefas e cancelamento.],
    [UC-VID-001; UC-VID-002; UC02, UC03 (interface existente)],
    [REQ-VID-UPL-001–006, REQ-VID-UPL-015, REQ-VID-UPL-018–025, REQ-VID-UPL-033; REQ-VID-TRIM-001–003, REQ-VID-TRIM-009, REQ-VID-TRIM-019, REQ-VID-TRIM-022, REQ-VID-TRIM-024],

    [Perfis, serviço `users` e controlo de acessos (`userSchema`) (RF01)],
    [Estender],
    [O Upload consulta o perfil `free`/`premium` para aplicar o limite máximo por ficheiro e exige sessão válida e permissão de edição no projeto. O Trim acrescenta o bloqueio a utilizadores anónimos, limites de duração por perfil, quota diária e autorização do modo de recorte rápido. A documentação do Trim também formula restrições de acesso pela titularidade da conta que submeteu o vídeo; no código, o acesso ao Trim passa pela autorização de edição do projeto e o resultado é associado ao projeto, com `uploadedBy` a identificar quem o submeteu. A relação entre permissão no projeto e titularidade da conta carece de decisão da equipa.],
    [UC-VID-001; UC-VID-002],
    [RF01; REQ-VID-UPL-007–008, REQ-VID-UPL-012–013, REQ-VID-UPL-022; REQ-VID-TRIM-005–007, REQ-VID-TRIM-011, REQ-VID-TRIM-019, REQ-VID-TRIM-021, REQ-VID-TRIM-027],

    [API Gateway (`apiGateway/routes/projects.js`)],
    [Estender],
    [As rotas de Upload verificam a sessão JWT, encaminham a pré-validação antes do corpo e transmitem o pedido multipart num `PassThrough` com buffer de 64 KiB e backpressure, incluindo versão, nome e tamanho. Para o Trim, encaminham os pedidos e respostas associados à submissão e gestão das tarefas.],
    [UC-VID-001; UC-VID-002],
    [REQ-VID-UPL-007–008, REQ-VID-UPL-012–014, REQ-VID-UPL-022–025, REQ-VID-UPL-028, REQ-VID-UPL-030, REQ-VID-UPL-032; REQ-VID-TRIM-008–009, REQ-VID-TRIM-019, REQ-VID-TRIM-025],

    [Serviço `projects` e modelo `Project`],
    [Estender],
    [As rotas verificam a autorização e a versão do projeto, recebem o corpo com `multer.diskStorage` em ficheiro temporário, validam o MP4/H.264 com `ffprobe`, guardam o objeto e associam metadados e referência persistente à coleção `videos`, separada de `imgs`. O Trim cria e acompanha tarefas, guarda o resultado no projeto e regista a identidade de quem submeteu. A validação com `ffprobe` no Upload não executa o recorte.],
    [UC-VID-001; UC-VID-002],
    [REQ-VID-UPL-007–014, REQ-VID-UPL-016–019, REQ-VID-UPL-022–032, REQ-VID-UPL-034–035; REQ-VID-TRIM-004, REQ-VID-TRIM-008–010, REQ-VID-TRIM-013–015, REQ-VID-TRIM-020–021],

    [Nginx],
    [Estender],
    [A configuração acrescenta uma rota de Upload com limite de corpo, buffering desativado e timeouts alargados, encaminhando progressivamente o conteúdo para o API Gateway.],
    [UC-VID-001],
    [REQ-VID-UPL-012–014, REQ-VID-UPL-030],

    [Serviço de armazenamento e biblioteca (`mediaStorageService` / `img_storage`) (RF06)],
    [Estender],
    [O serviço existente passa a gerir vídeos além de imagens: recebe uma nova rota protegida por chave interna, que envia objetos MP4 em partes de 16 MiB, com duas partes simultâneas (buffer multipart máximo de 32 MiB por upload), para o SeaweedFS, e suporta a persistência e eliminação dos resultados do Trim. A rota de vídeo é acrescentada em separado das rotas de imagem, preservando estas últimas.],
    [UC-VID-001; UC-VID-002],
    [REQ-VID-UPL-016–018, REQ-VID-UPL-025, REQ-VID-UPL-029–031, REQ-VID-UPL-035; REQ-VID-TRIM-012–014, REQ-VID-TRIM-018, REQ-VID-TRIM-023],

    [SeaweedFS (armazenamento S3 compatível)],
    [Manter],
    [O object storage existente é reutilizado para persistir vídeos de origem e resultados do Trim; não é introduzido nem alterado um serviço de armazenamento.],
    [UC-VID-001; UC-VID-002],
    [REQ-VID-UPL-016–017, REQ-VID-UPL-029; REQ-VID-TRIM-012–014, REQ-VID-TRIM-023],

    [Mecanismo novo de quota acumulada de vídeo (`videoQuota` / `VideoStorageAccount`)],
    [Estender],
    [Este mecanismo foi introduzido nesta fase para estender o controlo de armazenamento à biblioteca de vídeo, com limites acumulados de 1 GB (`free`) e 5 GB (`premium`) especificados pelo Trim. O código também reserva e confirma quota no Upload, além de aplicar o limite individual por ficheiro; o dossiê do Upload não define o teto acumulado. A sua abrangência normativa no Upload permanece por decidir.],
    [UC-VID-001; UC-VID-002],
    [RF06; REQ-VID-UPL-016–017 (persistência; sem requisito UPL explícito para limite acumulado); REQ-VID-TRIM-021, REQ-VID-TRIM-023–024],

    [Quota diária de operações do perfil `free` (`FREE_DAILY_OP`) (RF05)],
    [Alterar],
    [A quota de cinco operações diárias, existente para transformações de imagem, passa a incluir o recorte de vídeo: o sistema reserva uma unidade na submissão e pode estorná-la em falha ou cancelamento. O Upload não consome esta quota.],
    [UC-VID-002],
    [RF05; REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016–017, REQ-VID-TRIM-022],

    [Infraestrutura de mensagens e filas (`rabbitMQ`)],
    [Estender],
    [É acrescentada uma fila dedicada ao processamento assíncrono de Trim, separada das filas de imagem e com suporte ao controlo de cancelamento. O Upload não submete tarefas de processamento.],
    [UC-VID-002],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-010, REQ-VID-TRIM-017, REQ-VID-TRIM-022, REQ-VID-TRIM-025],

    [Workers do sistema (novo worker de vídeo: `videoTrimWorker`)],
    [Estender],
    [É acrescentado o worker `videoTrimWorker`, contentorizado e com FFmpeg, para executar o recorte, reportar o estado e remover ficheiros temporários.],
    [UC-VID-002],
    [REQ-VID-TRIM-010, REQ-VID-TRIM-012, REQ-VID-TRIM-015, REQ-VID-TRIM-018, REQ-VID-TRIM-026, REQ-VID-TRIM-028],

    [Pipelines de imagem e processamento em lote (UC06, UC07)],
    [Manter],
    [O encadeamento de ferramentas e o processamento em lote de imagens permanecem inalterados e sem ligação ao pipeline atómico de recorte de vídeo.],
    [UC-VID-002; UC06, UC07],
    [Sem requisitos de vídeo associados],
  ),
)]
