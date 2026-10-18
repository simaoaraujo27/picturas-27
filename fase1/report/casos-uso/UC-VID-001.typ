#import "../template.typ": *

// =============================================================================
//  CASO DE USO — UC-VID-001: Recortar Intervalo Temporal de Vídeo (Trim)
// =============================================================================

== UC-VID-001 — Recortar Intervalo Temporal de Vídeo (_Trim_)

=== Cabeçalho

#tab([Caso de uso UC-VID-001 — Recortar Intervalo Temporal de Vídeo (_Trim_)],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-001],
    [Nome], [Recortar Intervalo Temporal de Vídeo (_Trim_)],
    [Versão], [v1.2],
    [Autor], [Simão Araújo],
    [Data], [2026-10-18],
    [Objetivo], [Permitir ao utilizador isolar um excerto contínuo de um vídeo através da definição de instantes inicial e final, gerando um novo ficheiro de vídeo correspondente exclusivamente a esse intervalo temporal.],
    [Âmbito], [Módulo de Processamento de Vídeo do PictuRAS — Serviço de Projetos e Gestão de Tarefas (_Video Trim Worker_).],
    [Ator Principal], [Utilizador Registado Gratuito (perfil: `free`), sendo igualmente aplicável a Subscritor Pago (perfil: `premium`) com limites alargados. Utilizadores não autenticados (`anonymous`) são estritamente impedidos de aceder ao processamento de vídeo e encaminhados para a criação de conta.],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: Pretende isolar rapidamente excertos de vídeo relevantes sem perda de qualidade e com controlo temporal preciso.
      - *Proprietário do Sistema (SaaS)*: Quer rentabilizar a plataforma fazendo cumprir o modelo de negócio (quotas diárias de 5 operações e limite de 1 GB no nível gratuito `free`, incentivando o plano `premium` com 5 GB e operações ilimitadas), controlando os custos de computação na nuvem e prevenindo abusos por utilizadores anónimos.
      - *Equipa de Desenvolvimento/Operações*: Pretende validar a arquitetura assíncrona orientada a filas de mensagens para processamento demorado de vídeo sem bloquear a interface web nem degradar os serviços existentes de processamento de imagem.
    ],
    [Pré-condições], [
      - O utilizador encontra-se autenticado com sessão ativa num perfil registado (`free` ou `premium`). Utilizadores `anonymous` não têm acesso.
      - O utilizador dispõe de saldo na quota de operações diárias (no perfil `free`, saldo $> 0$ da quota diária de 5 operações; no perfil `premium`, ilimitado).
      - O utilizador dispõe de espaço disponível na quota de armazenamento da sua conta (limite de 1 GB para `free` e 5 GB para `premium`).
      - O vídeo de origem foi carregado com sucesso ou já se encontra na biblioteca do utilizador.
      - O ficheiro de vídeo está no formato suportado no MVP (MP4 com codecs de vídeo H.264 e áudio AAC).
    ],
    [_Trigger_], [O utilizador autenticado seleciona um vídeo na plataforma e escolhe a opção *Recortar vídeo (Trim)*.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-001 — Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1],
    [O utilizador autenticado seleciona um vídeo carregado na biblioteca e ativa a ferramenta *Recortar vídeo (Trim)*.],
    [Carrega os metadados do vídeo e apresenta a interface de recorte com reprodutor, linha temporal (_timeline_), duração total, indicador de espaço ocupado na biblioteca e controlos de início e fim ($t_(i n)$ e $t_(o u t)$).],

    [2],
    [O utilizador ajusta os marcadores temporais definindo o instante inicial ($t_(i n)$) e o instante final ($t_(o u t)$) do segmento.],
    [Atualiza a linha temporal destacando a área a preservar e atualiza em tempo real os campos numéricos e a duração resultante ($t_(o u t) - t_(i n)$).],

    [3],
    [O utilizador confirma a operação clicando em *Confirmar Recorte*.],
    [Valida os parâmetros temporais ($0 <= t_(i n) < t_(o u t) <= "duração"$), verifica o saldo de quota diária de operações (se perfil `free`), os limites de duração e a disponibilidade de espaço na quota de armazenamento da conta (1 GB para `free` e 5 GB para `premium`).],

    [4],
    [—],
    [Reserva provisoriamente 1 operação da quota diária do utilizador (se perfil `free`) e submete uma tarefa assíncrona de processamento para a fila de execução RabbitMQ.],

    [5],
    [—],
    [Gera e atribui um identificador único de tarefa (_Job ID_) e apresenta o ecrã de acompanhamento em estado "Em fila de espera" com botão de cancelamento disponível.],

    [6],
    [—],
    [O _worker_ retira a tarefa da fila, inicia o recorte com recodificação de fotogramas e disponibiliza atualizações periódicas de progresso percentual (0% a 100%).],

    [7],
    [—],
    [O _worker_ conclui a renderização do excerto, valida a integridade do ficheiro de saída e guarda o novo vídeo no armazenamento da biblioteca, somando o espaço em disco ocupado à quota da conta.],

    [8],
    [—],
    [Notifica o utilizador da conclusão com sucesso, disponibiliza a reprodução do vídeo recortado via URL temporária segura, a opção de descarregar (_download_) e adiciona o vídeo à lista do projeto.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-001 — Fluxos alternativos],
  tabela(
    colunas: (4.2cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição $->$ comportamento $->$ retorno)],
    [FA1 – Pré-visualização local antes de submeter],
    [No Passo 2: o utilizador clica em *Pré-visualizar Excerto*. O sistema reproduz diretamente no navegador apenas o intervalo entre $t_(i n)$ e $t_(o u t)$ recorrendo aos controlos nativos de reprodução do browser, sem submeter tarefa ao servidor nem consumir quota de operações. O utilizador pode reajustar os marcadores antes de prosseguir para o Passo 3.],

    [FA2 – Recorte rápido sem recodificação (_Stream Copy_)],
    [No Passo 3: caso o utilizador disponha de perfil `premium` e ative a opção "Recorte Rápido (em _keyframes_)", o sistema verifica a viabilidade de efetuar cópia direta de fluxos de vídeo/áudio sem transcodificação. A operação é concluída em poucos segundos no Passo 6 e o sistema transita de imediato para o Passo 8.],

    [FA3 – Utilizador sai da página durante o processamento],
    [No Passo 5 ou 6: o utilizador fecha o separador ou navega para outra secção da aplicação. O processamento assíncrono continua no servidor; aquando da conclusão, o sistema regista o vídeo resultante no projeto e disponibiliza-o na biblioteca da conta do utilizador.],

    [FA4 – Tentativa de acesso por utilizador não autenticado],
    [No Passo 1: caso um utilizador não autenticado (`anonymous`) tente aceder à ferramenta de recorte de vídeo, o sistema impede a visualização da ferramenta, exibe uma mensagem informativa e redireciona o utilizador para o formulário de registo/login.],

    [FA5 – Cancelamento voluntário da tarefa pelo utilizador],
    [No Passo 5 ou 6: o utilizador clica em *Cancelar Processamento* no ecrã de acompanhamento. O sistema cancela a tarefa, elimina de imediato quaisquer artefactos intermédios ou parciais, estorna a operação debitada na quota diária do utilizador (se perfil `free`) e apresenta a confirmação de cancelamento bem-sucedido.],
  ),
)

=== Exceções

#tab([UC-VID-001 — Exceções],
  tabela(
    colunas: (1fr, 1fr),
    [Condição], [Comportamento do Sistema],
    [Utilizador não autenticado tenta executar operação de vídeo],
    [No Passo 1 ou 3: o sistema rejeita a operação com código HTTP 401/403, apresenta mensagem informativa e encaminha o utilizador para o ecrã de registo/login.],

    [Instantes temporais inválidos ($t_(i n) >= t_(o u t)$ ou $t_(o u t) > "duração do vídeo"$, ou intervalo $< 1.0$ s)],
    [No Passo 3: o sistema bloqueia o pedido, assinala os campos com erro e apresenta mensagem explicativa. O fluxo regressa ao Passo 2 sem deduzir quota.],

    [Duração do excerto excede o limite do perfil de utilização ($> 180$ s em `free`)],
    [No Passo 3: o sistema recusa a submissão e sugere reduzir o intervalo ou efetuar upgrade para o plano `premium`.],

    [Quota diária de operações esgotada (`remainingOperations = 0`)],
    [No Passo 3: se o utilizador `free` já tiver consumido as 5 operações diárias gratuitas (`FREE_DAILY_OP = 5`), o sistema impede a submissão e exibe o alerta de limite atingido, sugerindo upgrade para `premium`.],

    [Quota de armazenamento em disco esgotada na biblioteca],
    [No Passo 3 ou 7: se o espaço restante na conta for insuficiente para acomodar o novo vídeo (ultrapassando 1 GB no perfil `free` ou 5 GB no perfil `premium`), o sistema bloqueia a operação, liberta a reserva de quota diária e notifica o utilizador da falta de espaço em disco.],

    [Ficheiro de vídeo com _codec_ ou fluxo corrompido / incompatível],
    [No Passo 6: o _worker_ deteta inconsistências severas nos pacotes de vídeo ou formato incompatível via FFprobe/FFmpeg. A tarefa é marcada como `FAILED`, a quota consumida é devolvida ao utilizador e é apresentada uma mensagem de erro descritiva.],

    [Falha do _worker_ ou _timeout_ no processamento assíncrono],
    [No Passo 6: se o nó de processamento falhar ou o _lease_ de execução expirar, o sistema tenta uma reexecução idempotente. Persistindo a falha, a tarefa passa a `FAILED`, a quota consumida é estornada e o utilizador é notificado.],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [
    - É gerado um novo ficheiro de vídeo MP4 contendo unicamente os fotogramas e áudio situados no intervalo $[t_(i n), t_(o u t)]$, com sincronização A/V preservada.
    - O vídeo de origem permanece rigorosamente intacto na biblioteca (não-destrutividade).
    - O novo vídeo é registado na biblioteca permanente do projeto com metadados descritivos (duração, resolução, proveniência `sourceVideoId` e `jobId`) e o espaço ocupado é somado à quota da conta.
    - A quota diária de operações do utilizador `free` é confirmada e debitada em 1 unidade.
    - É gerado o registo completo do job para auditoria e histórico de tarefas.
  ],
  [Garantia Mínima], [
    - O vídeo de origem não sofre qualquer modificação ou degradação.
    - Quaisquer ficheiros parciais ou temporários criados nos _workers_ são integralmente eliminados.
    - A quota diária de operações do utilizador não é debitada (ou é estornada se tinha sido previamente reservada).
    - A quota de armazenamento não é incrementada.
    - É apresentada ao utilizador uma mensagem compreensível com a causa da falha.
  ],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [
    *Contabilização de Quotas Diárias por Perfil (`userSchema`):*
    - Perfil `free`: Quota diária de 5 operações avançadas (`FREE_DAILY_OP = 5`). Cada recorte concluído com sucesso consome exatamente 1 operação. Caso o processamento falhe ou seja cancelado, a operação reservada é automaticamente estornada.
    - Perfil `premium`: Utilização ilimitada sem teto diário de operações.
  ],
  [RN2], [
    *Limites de Duração de Excerto por Perfil Autenticado:* A duração máxima do excerto $(t_(o u t) - t_(i n))$ é limitada por perfil: `free` $<= 180$ segundos (3 minutos); `premium` até à duração máxima de 60 minutos (1 hora).
  ],
  [RN3], [
    *Precisão e Duração Mínima:* Os instantes $t_(i n)$ e $t_(o u t)$ possuem precisão mínima de centésimos de segundo ($0.01$ s). O intervalo mínimo permitido é de 1.0 segundo ($(t_(o u t) - t_(i n)) >= 1.0$ s) para prevenir a geração de excertos vazios.
  ],
  [RN4], [
    *Formatos e Codecs Suportados no MVP (MP4):* No MVP da Fase 1, o sistema suporta exclusivamente ficheiros encapsulados em formato MP4 com codec de vídeo H.264 e áudio AAC, tanto para ingestão como para exportação, assegurando compatibilidade nativa com navegadores web HTML5.
  ],
  [RN5], [
    *Não Destrutividade:* A operação de recorte nunca substitui nem sobrescreve o ficheiro de vídeo original. Produz sempre um novo artefacto multimédia independente associado ao projeto.
  ],
  [RN6], [
    *Quotas de Armazenamento em Disco por Perfil:*
    - Perfil `free`: Quota máxima de armazenamento em disco de *1 GB* na conta.
    - Perfil `premium`: Quota alargada de armazenamento em disco de *5 GB* na conta.
    O sistema bloqueia novas submissões sempre que o total ocupado pelos vídeos do utilizador exceda o limite do seu perfil.
  ],
  [RN7], [
    *Autenticação Obrigatória para Ferramentas de Vídeo:* O acesso a ferramentas de vídeo é exclusivo a utilizadores autenticados (`free` ou `premium`). Utilizadores não autenticados (`anonymous`) estão limitados a ferramentas básicas de imagem, sendo direcionados para registo/login.
  ],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [O nó de execução (_worker_) possui acesso direto via rede ou _streaming_ ao armazenamento SeaweedFS onde o vídeo original reside, sem necessitar de carregar o ficheiro integralmente para a memória RAM.],
  [A2], [A infraestrutura dispõe de nós _worker_ com FFmpeg instalado e compilado para descodificação e recodificação dos codecs H.264 e AAC em contentor MP4 com desempenho adequado.],
  [A3], [O navegador web do utilizador suporta nativamente a reprodução de vídeo MP4 (H.264/AAC) em HTML5 com aceleração de hardware para pré-visualização local.],
  [A4], [A taxa de fotogramas (_frame rate_) mantém-se constante ao longo do vídeo de entrada (CFR - _Constant Frame Rate_), prevenindo problemas de dessincronização A/V após o corte.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 5.5cm),
  [ID], [Questão], [Resolução],
  [Q1],
  [Deve ser oferecida a opção de escolher entre "Recorte Preciso" (com recodificação, exato ao fotograma) e "Recorte Rápido" (sem recodificação, alinhado aos _keyframes_)?],
  [Resolvido: No MVP, utilizadores `premium` dispõem da opção de recorte rápido (FA2 / REQ-VID-TRIM-011), enquanto utilizadores `free` utilizam o recorte preciso por omissão.],

  [Q2],
  [Se o utilizador pretender substituir o vídeo original pelo excerto para poupar espaço em disco, o sistema deve disponibilizar essa opção destrutiva?],
  [Resolvido: Mantém-se o princípio da não-destrutividade estrita (RN5) no MVP para prevenir perdas acidentais de dados; a substituição destrutiva fica adiada para a Fase 2.],

  [Q3],
  [Deve ser disponibilizado aos utilizadores anónimos um vídeo de demonstração pré-carregado apenas para experimentação visual da interface?],
  [Resolvido: No MVP optou-se pela proteção estrita de recursos computacionais pesados (RN7), exigindo registo para qualquer interação com vídeo.],

  [Q4],
  [O suporte a contentores adicionais (WebM, MKV) e codecs modernos (VP9, AV1) deve ser introduzido no MVP?],
  [Resolvido: Excluído do MVP (limitado a MP4 H.264/AAC conforme RN4 e REQ-VID-TRIM-012); identificado como meta para o alvo de produção na ERS.],
)
