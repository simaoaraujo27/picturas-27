#import "../template.typ": *

= Rastreabilidade

== Casos de uso $->$ requisitos

#orientacao[
  Cada elemento relevante de cada caso de uso (passos, FA, exceções, RN, pós-condições) tem pelo menos um
  requisito, ou justificação para não ter; nenhum requisito da ERS fica órfão. Requisitos de qualidade podem
  apontar para uma decisão de qualidade (DQ). Indiquem sempre o caso de uso no elemento de origem.
]

#tab([Matriz de rastreabilidade: casos de uso $->$ requisitos],
  tabela(
    colunas: (4.2cm, 1fr, 4.2cm),
    tamanho: 8.5pt,
    [Elemento de origem], [Descrição abreviada], [Requisito(s)],

    [UC-VID-001, Âmbito], [Módulo de processamento de vídeo assíncrono em nós isolados], [REQ-VID-TRIM-008, REQ-VID-TRIM-028],
    [UC-VID-001, Pré-condições], [Autenticação, quotas de operações e disco, formato MP4 e vídeo carregado], [REQ-VID-TRIM-005, REQ-VID-TRIM-012, REQ-VID-TRIM-019, REQ-VID-TRIM-021, REQ-VID-TRIM-027],
    [UC-VID-001, Passo 1], [Seleção do vídeo na biblioteca e abertura da interface de recorte], [REQ-VID-TRIM-001, REQ-VID-TRIM-024],
    [UC-VID-001, Passo 2], [Ajuste interativo dos marcadores temporais $t_(i n)$ e $t_(o u t)$ na linha temporal], [REQ-VID-TRIM-002],
    [UC-VID-001, Passo 3], [Confirmação da operação e validação de parâmetros, limites e quotas de disco/operações], [REQ-VID-TRIM-004, REQ-VID-TRIM-005, REQ-VID-TRIM-006, REQ-VID-TRIM-021],
    [UC-VID-001, Passo 4], [Reserva provisória de quota diária (`free`) e publicação assíncrona na fila], [REQ-VID-TRIM-007, REQ-VID-TRIM-008, REQ-VID-TRIM-025],
    [UC-VID-001, Passo 5], [Atribuição de Job ID, estado em fila e ecrã de acompanhamento], [REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-025],
    [UC-VID-001, Passo 6], [Execução do recorte no worker com FFmpeg e difusão de progresso], [REQ-VID-TRIM-009, REQ-VID-TRIM-010, REQ-VID-TRIM-026],
    [UC-VID-001, Passo 7], [Conclusão do processamento, integridade e persistência com controlo de quota], [REQ-VID-TRIM-012, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-021, REQ-VID-TRIM-024],
    [UC-VID-001, Passo 8], [Notificação de conclusão, reprodução via streaming seguro e download], [REQ-VID-TRIM-014, REQ-VID-TRIM-027],
    [UC-VID-001, FA1], [Pré-visualização local no browser antes de submeter a tarefa], [REQ-VID-TRIM-003],
    [UC-VID-001, FA2], [Recorte rápido sem recodificação (_Stream Copy_) para perfil `premium`], [REQ-VID-TRIM-011],
    [UC-VID-001, FA3], [Continuidade do processamento assíncrono ao fechar o browser], [REQ-VID-TRIM-015],
    [UC-VID-001, FA4], [Bloqueio de utilizadores não autenticados (`anonymous`) com convite a registo], [REQ-VID-TRIM-019],
    [UC-VID-001, FA5], [Cancelamento voluntário da tarefa pelo utilizador em fila ou execução], [REQ-VID-TRIM-022],
    [UC-VID-001, Exceção 1 / RN7], [Utilizador não autenticado tenta executar operação de vídeo], [REQ-VID-TRIM-019],
    [UC-VID-001, Exceção 2 / RN3], [Instantes temporais inválidos ($t_(i n) >= t_(o u t)$ ou intervalo $< 1.0$ s)], [REQ-VID-TRIM-004],
    [UC-VID-001, Exceção 3 / RN2], [Duração do excerto excede limite do perfil (180s `free` / 60 min `premium`)], [REQ-VID-TRIM-006],
    [UC-VID-001, Exceção 4 / RN1], [Quota diária de operações esgotada no perfil `free` (`FREE_DAILY_OP = 5`)], [REQ-VID-TRIM-005],
    [UC-VID-001, Exceção 5 / RN6], [Quota de armazenamento em disco excedida (1 GB `free` / 5 GB `premium`)], [REQ-VID-TRIM-021],
    [UC-VID-001, Exceção 6], [Ficheiro de vídeo com formato não suportado ou pacotes corrompidos], [REQ-VID-TRIM-016],
    [UC-VID-001, Exceção 7], [Falha de nó de processamento ou timeout de execução de 10 minutos], [REQ-VID-TRIM-017],
    [UC-VID-001, Pós-condição Sucesso], [Excerto gerado com sincronismo A/V, original intacto, na biblioteca e auditado], [REQ-VID-TRIM-010, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-020, REQ-VID-TRIM-021],
    [UC-VID-001, Pós-condição Mínima], [Original intacto, fragmentos temporários purgados e quotas estornadas], [REQ-VID-TRIM-013, REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-022],
    [UC-VID-001, RN1], [Gestão transacional de quotas diárias de operações (`FREE_DAILY_OP = 5`)], [REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-021, REQ-VID-TRIM-022],
    [UC-VID-001, RN2], [Limites de duração de excerto por perfil (180s em `free`, 60 min em `premium`)], [REQ-VID-TRIM-006],
    [UC-VID-001, RN3], [Precisão temporal ao centésimo de segundo e duração mínima de 1.0 s], [REQ-VID-TRIM-002, REQ-VID-TRIM-004],
    [UC-VID-001, RN4], [Formatos e codecs suportados no MVP (contentor MP4 com H.264 e AAC)], [REQ-VID-TRIM-012],
    [UC-VID-001, RN5], [Princípio da não destrutividade do vídeo de origem na biblioteca], [REQ-VID-TRIM-013],
    [UC-VID-001, RN6], [Quotas de armazenamento em disco por perfil (1 GB / 5 GB) e eliminação], [REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024],
    [UC-VID-001, RN7], [Autenticação obrigatória para ferramentas de vídeo e bloqueio a anónimos], [REQ-VID-TRIM-019],
    [DQ-001], [Desacoplamento assíncrono via RabbitMQ e monitorização periódica], [REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-025],
    [DQ-002], [Resiliência com repetição idempotente e métricas de processamento], [REQ-VID-TRIM-017, REQ-VID-TRIM-026],
    [DQ-003], [Acesso restrito com tokens de sessão e registo de auditoria], [REQ-VID-TRIM-020, REQ-VID-TRIM-027],
    [DQ-004], [Isolamento do motor FFmpeg em contentor Docker autónomo], [REQ-VID-TRIM-012, REQ-VID-TRIM-028],
    [DQ-005], [Retenção efêmera em workers e política de persistência na biblioteca], [REQ-VID-TRIM-018, REQ-VID-TRIM-023],
    [DQ-006], [Mecanismo cooperativo de cancelamento ativo pelo utilizador], [REQ-VID-TRIM-022],
  ),
)

== Decisões de qualidade

#tab([Decisões de qualidade],
  tabela(
    colunas: (1.6cm, 3.8cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [ID], [Decisão de qualidade], [Justificação], [Requisitos],

    [DQ-001],
    [Processamento assíncrono desacoplado via RabbitMQ e polling leve],
    [Previne o bloqueio do servidor HTTP da API durante operações demoradas de vídeo e assegura a responsividade contínua da interface do utilizador com atualizações periódicas de estado.],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-025],

    [DQ-002],
    [Resiliência baseada em reexecução idempotente do início],
    [Simplifica a arquitetura da Fase 1 evitando a complexidade de persistir _checkpoints_ parciais de fotogramas, tolerando quebras pontuais de workers com repetição automática garantida.],
    [REQ-VID-TRIM-017, REQ-VID-TRIM-026],

    [DQ-003],
    [Acesso seguro com autenticação de sessão, cookies temporários e auditoria],
    [Assegura a confidencialidade dos ficheiros de vídeo, evitando a exposição de credenciais ou JWT em URLs de streaming e prevenindo acessos ilegítimos por enumeração.],
    [REQ-VID-TRIM-020, REQ-VID-TRIM-027],

    [DQ-004],
    [Encapsulamento do motor FFmpeg e dependências em imagem Docker autónoma],
    [Garante portabilidade total e reprodutibilidade do ambiente de execução do worker entre desenvolvimento e produção, sem requerer instalação de binários nativos no sistema operativo anfitrião.],
    [REQ-VID-TRIM-012, REQ-VID-TRIM-028],

    [DQ-005],
    [Retenção efêmera em workers e eliminação explícita na biblioteca permanente],
    [Previne o esgotamento do disco dos nós de computação através da purga imediata de diretórios temporários e capacita o utilizador a gerir o volume ocupado na sua conta.],
    [REQ-VID-TRIM-018, REQ-VID-TRIM-023],

    [DQ-006],
    [Cancelamento cooperativo de tarefas com estorno imediato de quota],
    [Evita o desperdício de tempo de computação em tarefas submetidas por engano e garante justiça na contabilidade de quotas para utilizadores do plano gratuito.],
    [REQ-VID-TRIM-022],
  ),
)

== Realização e verificação dos requisitos

#orientacao[
  Fecha o ciclo *requisito → componente → teste → estado*. Uma linha por requisito da ERS (podem agrupar
  requisitos com o mesmo destino). Deve ser possível responder a: "que requisitos estão implementados e
  verificados?" e "que componentes foram tocados por cada funcionalidade?". Requisitos não implementados não se
  apagam: ficam com estado "Não implementado" e justificação. Os detalhes estão nos capítulos de Arquitetura e de Testes.
]

#tab([Realização e verificação dos requisitos],
  tabela(
    colunas: (2.8cm, 3.2cm, 2.2cm, 2.2cm, 1fr),
    tamanho: 8pt,
    [Requisito], [Componente(s)], [Estado], [Teste(s)], [Resultado / observações],

    [REQ-VID-TRIM-001], [Frontend (VideoWorkspace)], [Implementado], [TST-TRIM-01], [Passa. Player HTML5 e seletores temporais carregados com sucesso.],
    [REQ-VID-TRIM-002], [Frontend (VideoWorkspace)], [Implementado], [TST-TRIM-01], [Passa. Marcadores atualizam dinamicamente os tempos e duração resultante.],
    [REQ-VID-TRIM-003], [Frontend (VideoWorkspace)], [Implementado], [TST-TRIM-02], [Passa. Pré-visualização local no browser sem chamadas de rede ao worker.],
    [REQ-VID-TRIM-004], [Projects (`/trim`), Frontend], [Implementado], [TST-TRIM-03], [Passa. Rejeita $t_(i n) >= t_(o u t)$ e intervalo $< 1.0$ s com HTTP 400.],
    [REQ-VID-TRIM-005], [Users (`/quota`), Projects], [Implementado], [TST-TRIM-04], [Passa. Bloqueia submissão com HTTP 403 após 5 operações Free no teste.],
    [REQ-VID-TRIM-006], [Projects (`/trim`)], [Implementado], [TST-TRIM-03], [Passa. Rejeita intervalos superiores a 180s no perfil Free.],
    [REQ-VID-TRIM-007], [Users, Projects], [Implementado], [TST-TRIM-04], [Passa. Débito provisório imediato da quota Free ao submeter para fila.],
    [REQ-VID-TRIM-008], [Projects, RabbitMQ], [Implementado], [TST-TRIM-05], [Passa. Tarefa publicada na fila `video_trim_queue` e Job ID retornado em HTTP 202.],
    [REQ-VID-TRIM-009], [Projects, VideoTrimWorker, UI], [Implementado], [TST-TRIM-05], [Passa. Polling a cada 4s reflete progressão de QUEUED a COMPLETED.],
    [REQ-VID-TRIM-010], [VideoTrimWorker (FFmpeg)], [Implementado], [TST-TRIM-06], [Passa. Excerto recortado gerado com sincronismo áudio/vídeo preservado.],
    [REQ-VID-TRIM-011], [VideoTrimWorker, Projects], [Implementado], [TST-TRIM-07], [Passa. Modo rápido Premium aceita corte em keyframes e rejeita se desalinhado.],
    [REQ-VID-TRIM-012], [MediaStorageService, Worker], [Implementado], [TST-TRIM-06], [Passa. Ingestão e exportação validadas em contentor MP4 com codecs H.264/AAC.],
    [REQ-VID-TRIM-013], [Projects, SeaweedFS], [Implementado], [TST-TRIM-08], [Passa. Hash SHA-256 do vídeo original permanece idêntico após recorte.],
    [REQ-VID-TRIM-014], [Projects, Frontend], [Implementado], [TST-TRIM-06], [Passa. Novo vídeo surge na lista do projeto com `sourceVideoId` e download funcional.],
    [REQ-VID-TRIM-015], [Projects, Worker], [Parcial], [TST-TRIM-05], [Parcial. Job conclui assincronamente em background; notificação global fora de página pendente.],
    [REQ-VID-TRIM-016], [VideoTrimWorker, Users], [Implementado], [TST-TRIM-09], [Passa. Erros de processamento transitam job para FAILED e quota Free é estornada.],
    [REQ-VID-TRIM-017], [VideoTrimWorker, Projects], [Implementado], [TST-TRIM-09], [Passa. Mecanismo de repetição para jobs com lease expirado implementado no worker.],
    [REQ-VID-TRIM-018], [VideoTrimWorker], [Implementado], [TST-TRIM-10], [Passa. Verificado no teste que `/tmp/picturas-trim-*` é purgado sem resíduos em disco.],
    [REQ-VID-TRIM-019], [ApiGateway, Projects], [Implementado], [TST-TRIM-11], [Passa. Pedidos não autenticados rejeitados com HTTP 401/403.],
    [REQ-VID-TRIM-020], [Projects, Logs], [Implementado], [TST-TRIM-05], [Passa. Registo em base de dados com parâmetros, tempos de processamento e utilizador.],
    [REQ-VID-TRIM-021], [Projects (`storage.js`)], [Implementado], [TST-TRIM-12], [Passa. Quota de armazenamento monitorizada por utilizador (1 GB Free / 5 GB Premium).],
    [REQ-VID-TRIM-022], [Projects, Worker, Users], [Implementado], [TST-TRIM-13], [Passa. Cancelamento em fila transita para CANCELLED e estorna quota diária Free.],
    [REQ-VID-TRIM-023], [Projects (`DELETE`)], [Implementado], [TST-TRIM-12], [Passa. Eliminação de vídeo liberta espaço da quota de armazenamento da conta.],
    [REQ-VID-TRIM-024], [Projects, Frontend], [Implementado], [TST-TRIM-12], [Passa. Endpoint de storage devolve bytes ocupados e limite da conta.],
    [REQ-VID-TRIM-025], [Projects, ApiGateway], [Parcial], [TST-TRIM-05], [Parcial. Resposta HTTP 202 rápida em testes locais; benchmark formal de p95 pendente.],
    [REQ-VID-TRIM-026], [VideoTrimWorker], [Parcial], [TST-TRIM-06], [Parcial. Excerto de 2.5s processado em ~1.2s; medição sistemática em 1080p/60s pendente.],
    [REQ-VID-TRIM-027], [Projects (`/playback`), Gateway], [Implementado], [TST-TRIM-14], [Passa. Stream via HTTP Range e cookie de 5 min; partilhas read/edit validadas.],
    [REQ-VID-TRIM-028], [Docker Compose, Worker], [Implementado], [TST-TRIM-15], [Passa. Contentor `video_trim_worker` arranca e executa FFmpeg isolado sem dependências no host.],
  ),
)
