#import "../template.typ": *

// =============================================================================
//  CASO DE USO — UC-VID-004: Compilar vídeos
// =============================================================================

== UC-VID-004 — Compilar vídeos

=== Cabeçalho

#tab([Caso de uso UC-VID-004 — Compilar vídeos],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-004],
    [Nome], [Compilar vídeos],
    [Versão], [v1.1],
    [Autor], [PG63995; Lara Lopes],
    [Data], [2026-10-21],
    [Objetivo], [Permitir ao utilizador criar um único vídeo a partir de dois ou mais vídeos já carregados, concatenados na ordem que escolher, preservando integralmente os ficheiros originais.],
    [Âmbito], [Módulo de vídeo do PictuRAS — ferramenta básica de edição, com processamento assíncrono no servidor.],
    [Ator Principal], [Utilizador autenticado do PictuRAS (plano Free ou Premium).],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: juntar vários vídeos num só de forma simples.
      - *Proprietário do Sistema*: disponibilizar a funcionalidade sem comprometer os recursos de armazenamento e de processamento.
      - *Equipa de Desenvolvimento*: validar o processamento de vários vídeos e a gestão de operações demoradas.
    ],
    [Pré-condições], [
      - O utilizador tem sessão iniciada.
      - O utilizador tem permissão de edição no projeto (proprietário ou ligação partilhada com edição).
      - Os vídeos (MP4 com H.264, conforme RNG-02) foram carregados com sucesso (UC-VID-001) e estão disponíveis na biblioteca do utilizador.
      - Existem pelo menos dois vídeos disponíveis para selecionar.
    ],
    [_Trigger_], [O utilizador escolhe a opção *Compile* na barra de ferramentas de um projeto.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-004 — Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1],
    [O utilizador abre um projeto com vídeos e escolhe *Compile* na barra de ferramentas.],
    [Abre o diálogo de compilação com a lista de vídeos do projeto (nome e duração).],

    [2],
    [O utilizador adiciona dois ou mais vídeos à compilação (*Add*).],
    [Apresenta os vídeos adicionados, numerados pela ordem, e indica que são necessários pelo menos dois enquanto não houver dois.],

    [3],
    [O utilizador define a ordem (subir, descer ou remover), dá opcionalmente um nome ao novo vídeo e carrega em *Compile videos*.],
    [Valida os vídeos selecionados (existem no projeto, são MP4/H.264 e no máximo 10) e os limites de duração do perfil do utilizador.],

    [4],
    [—],
    [Verifica se o utilizador tem espaço de armazenamento disponível e, no plano Free, quota diária de operações, e reserva essa operação.],

    [5],
    [—],
    [Cria uma tarefa de processamento com identificador único e coloca-a na fila.],

    [6],
    [—],
    [Inicia a compilação e apresenta o estado «Processing».],

    [7],
    [—],
    [Atualiza o estado e o progresso enquanto os vídeos são processados.],

    [8],
    [—],
    [Conclui a compilação e gera o vídeo resultante (MP4 com H.264).],

    [9],
    [—],
    [Reserva o espaço de armazenamento exato do resultado e armazena o vídeo na biblioteca do utilizador.],

    [10],
    [—],
    [Apresenta o estado «Completed» e o vídeo novo na lista de vídeos do projeto, mantendo os vídeos originais.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-004 — Fluxos alternativos],
  tabela(
    colunas: (4.2cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição $->$ comportamento $->$ retorno)],
    [FA1 – Alteração da ordem dos vídeos],
    [Antes de confirmar, o utilizador altera a ordem dos vídeos $->$ o sistema regista a nova sequência e utiliza-a no processamento $->$ regressa ao Passo 3.],

    [FA2 – Remoção de um vídeo selecionado],
    [Antes de confirmar, o utilizador remove um dos vídeos selecionados $->$ o sistema atualiza a seleção, desde que se mantenham pelo menos dois vídeos; caso contrário, impede o avanço e informa que são necessários pelo menos dois vídeos.],

    [FA3 – Vídeos com resolução ou _frame rate_ diferentes],
    [Os vídeos selecionados, todos MP4 com H.264 (RNG-02), têm resolução, _frame rate_ ou áudio diferentes $->$ o sistema normaliza-os antes de os concatenar (resolução do primeiro vídeo, mantendo a proporção com barras, 30 _fps_, H.264 e áudio AAC; os vídeos sem áudio recebem silêncio) $->$ prossegue no Passo 4.],
  ),
)

=== Exceções

#tab([UC-VID-004 — Exceções],
  tabela(
    colunas: (1fr, 1fr),
    [Condição], [Comportamento do Sistema],
    [Um dos vídeos selecionados não pode ser lido ou está corrompido (Passos 3 a 8)],
    [A tarefa falha com `VIDEO_UNREADABLE` e apresenta a mensagem «One of the videos could not be read.».],

    [O utilizador `free` não tem quota diária de operações (Passo 4)],
    [Não cria a tarefa (HTTP 429, `DAILY_QUOTA_EXHAUSTED`) e apresenta a mensagem «You have reached your daily operations limit.».],

    [Não existe espaço suficiente para guardar o vídeo resultante (Passo 4 ou Passo 9)],
    [Não cria a tarefa (verificação no pedido) ou falha a tarefa sem guardar o resultado (reserva exata no Passo 9) e apresenta a mensagem «You do not have enough storage space.».],

    [Ocorre uma falha durante o processamento (Passos 6 a 8)],
    [Repete a tarefa automaticamente se a falha for recuperável (até duas tentativas); caso contrário, falha, não guarda resultado e apresenta a mensagem «The compilation could not be completed, please try again.».],

    [O processamento excede o tempo limite permitido, 30 minutos por omissão (Passos 6 a 8)],
    [A tarefa falha com `PROCESSING_TIMEOUT` e apresenta a mensagem «Processing exceeded the allowed time limit.».],

    [O utilizador cancela a operação durante o processamento (Passos 6 a 8)],
    [A tarefa passa a «Cancelled», não guarda nem disponibiliza o vídeo incompleto e estorna a operação diária e o espaço reservado.],

    [A soma das durações dos vídeos selecionados excede o limite do perfil (Passo 3)],
    [Não cria a tarefa (HTTP 422, `COMPILE_TOO_LONG`) e apresenta a mensagem «The total duration exceeds the limit allowed by your plan.». O _worker_ volta a verificar o limite (`TOTAL_TOO_LONG`).],

    [Um dos vídeos não está em MP4 com H.264 (Passo 3)],
    [Não cria a tarefa (HTTP 415, `UNSUPPORTED_VIDEO`) e apresenta a mensagem «One of the selected videos is not supported.».],

    [São selecionados mais de 10 vídeos (Passo 3)],
    [Não cria a tarefa (`TOO_MANY_VIDEOS`) e apresenta a mensagem «You selected too many videos for a single compilation.».],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [
    - É criado um novo vídeo com a compilação dos vídeos selecionados, pela ordem escolhida, e é armazenado na biblioteca do utilizador.
    - Os vídeos originais mantêm-se inalterados.
  ],
  [Garantia Mínima], [
    - O processamento é interrompido e o vídeo incompleto não é guardado nem disponibilizado.
    - Os vídeos originais mantêm-se inalterados.
  ],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [*Mínimo de vídeos:* O utilizador deve selecionar pelo menos dois vídeos.],
  [RN2], [*Ordem:* Os vídeos são compilados pela ordem definida pelo utilizador.],
  [RN3], [*Não-destrutividade:* Os vídeos originais não sofrem alterações após a operação.],
  [RN4], [*Resultado:* O vídeo resultante é armazenado como um novo ficheiro na biblioteca do utilizador.],
  [RN5], [*Quota:* A operação só pode ser iniciada se o utilizador tiver quota de processamento suficiente (no plano Free, 5 operações diárias).],
  [RN6], [*Armazenamento:* A operação só pode ser concluída se o utilizador tiver armazenamento suficiente (1 GB no plano Free e 5 GB no Premium).],
  [RN7], [*Estado:* Durante o processamento, o sistema mostra o estado da operação e o respetivo progresso.],
  [RN8], [*Integridade:* Se a operação falhar ou for cancelada, o sistema não disponibiliza o vídeo incompleto.],
  [RN9], [*Formato:* Os vídeos de entrada e o resultado têm contentor MP4 e codec de vídeo H.264 (RNG-02).],
  [RN10], [*Duração total máxima:* A soma das durações dos vídeos selecionados não pode exceder 10 minutos no plano Free nem 1 hora no Premium (valores configuráveis).],
  [RN11], [*Número máximo de vídeos:* Uma compilação aceita no máximo 10 vídeos (valor configurável).],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [Os vídeos estão integralmente armazenados e acessíveis ao serviço no momento do pedido.],
  [A2], [Os vídeos estão em MP4 com H.264, porque só entram na biblioteca depois de validados pelo carregamento (UC-VID-001); o pedido de compilação valida-o de novo com os metadados guardados no projeto.],
  [A3], [O sistema dispõe dos recursos necessários para processar os vídeos selecionados.],
  [A4], [Os vídeos selecionados pertencem ao mesmo projeto e o resultado é adicionado a esse projeto, tal como no recorte (UC-VID-002): o _worker_ lê os vídeos de origem e grava o resultado no mesmo projeto.],
  [A5], [Cada compilação consome uma operação da quota diária (`FREE_DAILY_OP = 5` no plano Free; sem limite diário no Premium), como o recorte; o serviço `projects` usa o mesmo endpoint interno de quota do serviço `users`.],
  [A6], [A compilação é iniciada individualmente pelo utilizador e fica fora do encadeamento de ferramentas e do processamento em lote no MVP.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 1fr),
  [ID], [Questão], [Estado / resolução],
  [Q1], [O utilizador pode escolher o formato do vídeo resultante?], [*Resolvida.* Não: a entrada e a saída são sempre MP4 com H.264 (RNG-02).],
  [Q2], [Existe limite máximo de vídeos selecionados, de duração total, de dimensão ou de tamanho por perfil?], [*Resolvida.* Máximo de 10 vídeos por compilação (RN11); duração total de 10 minutos no Free e 1 hora no Premium (RN10); sem limite de tamanho por vídeo além do armazenamento acumulado (1 GB no Free e 5 GB no Premium).],
  [Q3], [Como é contabilizada a quota: por operação, por vídeo ou pela duração total processada?], [*Resolvida.* Por operação, como no recorte (5 por dia no plano Free): a operação é reservada no pedido, confirmada na conclusão e estornada em falha definitiva ou cancelamento.],
  [Q4], [A compilação pode ser usada em encadeamentos de ferramentas ou em processamento em lote?], [*Resolvida para o MVP.* Fica fora do âmbito (A6).],
)
