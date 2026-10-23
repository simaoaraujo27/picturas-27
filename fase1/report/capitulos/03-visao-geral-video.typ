#import "../template.typ": *

= Visão Geral da Extensão de Vídeo

== Funcionalidades de vídeo do MVP

#orientacao[
  Listem *todas* as funcionalidades de vídeo tratadas no relatório, cada uma com o respetivo caso de uso.
  A especificação detalhada está na Parte II, organizada por artefacto (casos de uso, ERS, impacto, …).
  Não há um número mínimo: valoriza-se a *profundidade, coerência e complexidade adequada* de cada funcionalidade.
  Operações triviais (e.g., gerar uma miniatura a partir de um único fotograma) não são suficientes.
  Requisitos partilhados por várias funcionalidades (e.g., submeter vídeo, acompanhar o estado do processamento)
  devem ser especificados *uma só vez* (e.g., `REQ-VID-SUBMIT-001`, com origem em vários casos de uso).
]

#tab([Funcionalidades de vídeo do MVP],
  tabela(
    colunas: (1fr, 2.1cm, 2.4cm, 2cm, 2.4cm, 2.4cm),
    [Funcionalidade], [Caso de uso], [Prefixo(s) REQ], [Perfis], [Dependências], [Estado de implementação],

    [Carregar vídeo para um projeto],
    [UC-VID-001],
    [REQ-VID-UPL],
    [`free`, `premium`],
    [Nenhuma (Atómica)],
    [Implementada],

    [Recortar Intervalo Temporal (_Trim_)],
    [UC-VID-002],
    [REQ-VID-TRIM],
    [`free`, `premium`],
    [Upload de vídeo],
    [Implementada],
    
    [Remover Segmento de Vídeo],
    [UC-VID-003],
    [REQ-VID-REM],
    [`free`, `premium`],
    [Upload de vídeo],
    [Implementada],

    [Compilar vídeos (_Compile_)],
    [UC-VID-004],
    [REQ-VID-COMP],
    [`free`, `premium`],
    [Upload de vídeo],
    [Implementada],
    
    [Modificar velocidade por intervalos],
    [UC-VID-005],
    [REQ-VID-SPEED],
    [`free`, `premium`],
    [Upload de vídeo],
    [MVP implementado; acompanhamento futuro],

  ),
)


*Justificação no contexto do MVP:*
- *UC-VID-001 — Carregar vídeo para um projeto (_Upload_):* Permite adicionar a um projeto um vídeo MP4 com codec H.264, respeitando o limite de 1 GB no plano `free` e de 5 GB no plano `premium`. Depois de validado, o ficheiro é armazenado e associado ao projeto, ficando disponível para processamento posterior. O processamento do vídeo não faz parte deste caso de uso.


- *UC-VID-002 — Recortar Intervalo Temporal de Vídeo (_Trim_):* Permite selecionar e guardar apenas a parte de um vídeo que interessa ao utilizador. No MVP, esta funcionalidade demonstra o funcionamento conjunto da interface, da fila RabbitMQ e dos serviços de processamento com FFmpeg, desde o pedido de recorte até à disponibilização do resultado.

- *UC-VID-003 —  Remover Segmento de Vídeo:* A remoção de segmentos indesejados é uma operação elementar de montagem e edição de vídeo porque permite ao utilizador eliminar hesitações, pausas ou partes defeituosas de uma gravação sem recorrer a ferramentas externas.

- *UC-VID-004 — Compilar vídeos (_Compile_):* Permite juntar dois ou mais vídeos já carregados num único ficheiro, pela ordem escolhida pelo utilizador. No MVP, valida a compilação de vários vídeos, a preservação dos originais, o armazenamento do resultado e o acompanhamento de uma operação assíncrona.

- *UC-VID-005 — Modificar a velocidade de um vídeo:* Permite configurar vários intervalos a 0,5x, 1x ou 2x, sem sobreposição, mantendo as partes não selecionadas a 1x e ajustando o áudio existente. Produz um novo MP4/H.264 e reutiliza a quota de armazenamento do proprietário. Progresso, cancelamento após submissão e aviso terminal de erro não integram o MVP atual.


#pagebreak()
== Diagrama de casos de uso (atualizado)

#align(center)[
  #figure(
    image("../images/picturas_usecases_video.svg", width: 96%),
    caption: [Diagrama de casos de uso atualizado do PictuRAS para a Fase 1 — Suporte a Vídeo.],
  )
]

O diagrama apresenta os casos de uso UC-VID-001, *Carregar vídeo para um projeto*, UC-VID-002, *Recortar intervalo temporal de vídeo*, UC-VID-003, *Remover segmento de vídeo*, UC-VID-004, *Compilar vídeos* e UC-VID-005, *Modificar a velocidade de um vídeo*. Os atores Utilizador Free e Utilizador Premium especializam o ator Utilizador autenticado e, por isso, herdam a associação aos cinco casos de uso. Estas operações exigem autenticação e permissão de edição no projeto. O utilizador não autenticado associa-se apenas ao registo e início de sessão.

O recorte, a remoção de segmento, a compilação e a alteração de velocidade pressupõem um vídeo já disponível, que pode ter sido carregado anteriormente. Esta dependência é uma pré-condição de UC-VID-002, UC-VID-003, UC-VID-004 e UC-VID-005, sem relação UML `<<include>>` com UC-VID-001, pois iniciar uma edição não implica efetuar um novo carregamento. O diagrama apresenta apenas os objetivos funcionais principais; os fluxos alternativos, as exceções e as operações internas constam da especificação detalhada dos casos de uso. A associação a UC-VID-005 não implica progresso percentual, cancelamento após submissão ou notificação terminal de erro, que continuam fora da implementação atual de speed.

#pagebreak()
#paisagem[
  == Modelo de domínio (atualizado)
  #align(center)[
    #figure(
      image("../images/picturas_modelo_dominio_video.svg", width: 94%),
      caption: [Modelo de domínio atualizado do PictuRAS para a Fase 1 — Suporte a Vídeo.],
    )
  ]
]

O modelo preserva os conceitos de *Utilizador*, *Projeto* e *Imagem* da solução existente. Utilizador e Projeto são estendidos para enquadrar os perfis, as quotas de vídeo e a associação de vídeos aos projetos. Os perfis são valores do Utilizador, sem constituírem entidades autónomas. Cada projeto tem um titular; a associação entre Utilizador e Vídeo identifica quem carregou o ficheiro ou solicitou o recorte, podendo essa pessoa ser diferente do titular do projeto.

*Vídeo* e *Tarefa de recorte* são conceitos novos. Cada tarefa tem exatamente um vídeo de origem; um vídeo pode ser usado em várias tarefas. Uma tarefa pode produzir, no máximo, um vídeo resultante, e cada resultado provém, no máximo, de uma tarefa. Original e resultado são instâncias da mesma entidade. O estado e o progresso descrevem a tarefa sem introduzir componentes técnicos no modelo.

Na implementação atual, tanto os vídeos carregados como os resultados do recorte são associados a um projeto; o resultado é adicionado ao mesmo projeto da origem. A biblioteca e a quota da conta agregam os vídeos guardados nos projetos do respetivo titular, sem exigir uma entidade de domínio adicional. O Upload aplica um limite de 1 GB (`free`) ou 5 GB (`premium`) por ficheiro, distinto da quota total de armazenamento da conta aplicada ao Trim.

O dossiê de UC-VID-002 descreve o resultado na biblioteca do utilizador, mas não explicita que tenha de pertencer ao projeto da origem. Essa obrigatoriedade corresponde ao código atual; a especificação conjunta dos dois casos de uso deve clarificar se a biblioteca poderá conter vídeos sem projeto.

#pagebreak()
== Regras de negócio transversais

#tab([Regras de negócio transversais],
  tabela(
    colunas: (1.6cm, 1fr, 2.5cm, 3.7cm),
    tamanho: 8.5pt,
    [ID], [Regra], [Casos de uso], [Requisitos relacionados],

    [RNG-01],
    [O carregamento, o recorte de vídeo, a remoção de segmento e a compilação exigem um utilizador autenticado dos perfis `free` ou `premium`. Um utilizador não autenticado (`anonymous`) não pode executar nenhuma das operações.],
    [UC-VID-001; UC-VID-002; UC-VID-003; UC-VID-004],
    [REQ-VID-UPL-007; REQ-VID-TRIM-019; REQ-VID-REM-010, REQ-VID-REM-027; REQ-VID-COMP-001; REQ-VID-COMP-NF-002],

    [RNG-02],
    [Os vídeos aceites no carregamento, no recorte e na remoção de segmento (entrada e saída), bem como os vídeos de entrada e o resultado da compilação, devem estar em contentor MP4 e utilizar o codec de vídeo H.264.],
    [UC-VID-001; UC-VID-002; UC-VID-003; UC-VID-004],
    [REQ-VID-UPL-010–011; REQ-VID-TRIM-012; REQ-VID-REM-011, REQ-VID-REM-026; REQ-VID-COMP-004; REQ-VID-COMP-NF-005],

    [RNG-03],
    [Uma operação de compilação só é aceite se o utilizador tiver quota de processamento suficiente e respeitar os limites do seu perfil: no perfil `free` aplicam-se a quota de 5 operações diárias (`FREE_DAILY_OP`) e o armazenamento acumulado de 1 GB; no perfil `premium` não há limite diário de operações e o armazenamento é de 5 GB. O resultado só é publicado na biblioteca se existir espaço de armazenamento suficiente. Cada compilação consome uma operação da quota diária, tal como o recorte.],
    [UC-VID-004],
    [REQ-VID-COMP-005; REQ-VID-COMP-006; REQ-VID-COMP-020; REQ-VID-COMP-021],

    [RNG-04],
    [Os vídeos originais nunca são alterados nem eliminados pela operação. O resultado é guardado como um novo ficheiro na biblioteca do utilizador que a iniciou e não é acessível a outros utilizadores.],
    [UC-VID-004],
    [REQ-VID-COMP-011; REQ-VID-COMP-012; REQ-VID-COMP-NF-002],

    [RNG-05],
    [A compilação é executada de forma assíncrona, com estado consultável durante o processamento. Se a tarefa falhar, for cancelada ou exceder o tempo limite, o vídeo incompleto não é guardado nem disponibilizado.],
    [UC-VID-004],
    [REQ-VID-COMP-007; REQ-VID-COMP-009; REQ-VID-COMP-017; REQ-VID-COMP-019; REQ-VID-COMP-NF-003],
  ),
)

*Aplicação das regras transversais ao UC-VID-005:* A autenticação de RNG-01 e o formato MP4/H.264 de RNG-02 também se aplicam a speed (REQ-VID-SPEED-028, REQ-VID-SPEED-018 e REQ-VID-SPEED-030). É necessária permissão de edição. A operação gera um resultado no mesmo projeto e contabiliza os seus bytes na conta do proprietário, mesmo em partilhas. Não cria uma entidade persistente de tarefa de speed no modelo atual; os estados/progresso da Tarefa de recorte representada na figura não devem ser atribuídos a esta operação.

== Convenções de identificação

#tabela(
  colunas: (4.2cm, 1fr),
  [Identificador], [Utilização],
  [UC-VID-nnn], [Caso de uso de vídeo (numeração única no relatório, a partir de UC-VID-001)],
  [REQ-VID-{FUNC}-nnn], [Requisito (funcional ou não funcional); {FUNC} identifica a funcionalidade ou a área do serviço (e.g., TRIM, SUBMIT, STATUS); IDs nunca se reutilizam],
  [RN#emph[k], A#emph[k], Q#emph[k], FA#emph[k]], [Regra, assunção, questão em aberto e fluxo alternativo de um caso de uso (locais ao caso de uso; qualificados, e.g. `UC-VID-001/RN2`, nas tabelas partilhadas)],
  [RNG-nn / DQ-nnn], [Regra de negócio transversal / decisão de qualidade (globais)],
  [DA-nn], [Decisão arquitetural (Capítulo de Arquitetura)],
  [TST-{FUNC}-nn], [Teste (automático ou manual)],
  [T-nn], [Tarefa de manutenção corretiva da solução de base],
  [UCnn, RFnn, RNFnn], [Elementos do documento de requisitos de base (referidos quando são alterados — ALT)],
)
