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
  ),
)


*Justificação no contexto do MVP:*
- *UC-VID-001 — Carregar vídeo para um projeto (_Upload_):* Permite adicionar a um projeto um vídeo MP4 com codec H.264, respeitando o limite de 1 GB no plano `free` e de 5 GB no plano `premium`. Depois de validado, o ficheiro é armazenado e associado ao projeto, ficando disponível para processamento posterior. O processamento do vídeo não faz parte deste caso de uso.


- *UC-VID-002 — Recortar Intervalo Temporal de Vídeo (_Trim_):* Permite selecionar e guardar apenas a parte de um vídeo que interessa ao utilizador. No MVP, esta funcionalidade demonstra o funcionamento conjunto da interface, da fila RabbitMQ e dos serviços de processamento com FFmpeg, desde o pedido de recorte até à disponibilização do resultado.

- *UC-VID-003 —  Remover Segmento de Vídeo:* A remoção de segmentos indesejados é uma operação elementar de montagem e edição de vídeo porque permite ao utilizador eliminar hesitações, pausas ou partes defeituosas de uma gravação sem recorrer a ferramentas externas.

#pagebreak()
== Diagrama de casos de uso (atualizado)

#align(center)[
  #figure(
    image("../images/picturas_usecases_video.svg", width: 96%),
    caption: [Diagrama de casos de uso atualizado do PictuRAS para a Fase 1 — Suporte a Vídeo.],
  )
]

O diagrama introduz os casos de uso UC-VID-001, *Carregar vídeo para um projeto*, e UC-VID-002, *Recortar intervalo temporal de vídeo*. Os atores Utilizador Free e Utilizador Premium especializam o ator Utilizador autenticado e, por isso, herdam a associação aos dois casos de uso. A autenticação é necessária em ambos; o carregamento exige ainda permissão de edição no projeto de destino.

O recorte pressupõe um vídeo já disponível, que pode ter sido carregado anteriormente. Esta dependência é uma pré-condição do UC-VID-002 e do UC-VID-002, sem relação UML `<<include>>` com o UC-VID-001, pois iniciar um recorte não implica efetuar um novo carregamento. O diagrama apresenta apenas os objetivos funcionais principais; os fluxos alternativos, as exceções e as operações internas constam da especificação detalhada dos casos de uso.

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
    [O carregamento e o recorte de vídeo exigem um utilizador autenticado dos perfis `free` ou `premium`. Um utilizador não autenticado (`anonymous`) não pode executar nenhuma das operações.],
    [UC-VID-001; UC-VID-002],
    [REQ-VID-UPL-007; REQ-VID-TRIM-019],

    [RNG-02],
    [Os vídeos aceites nas duas funcionalidades devem estar em contentor MP4 e utilizar o codec de vídeo H.264.],
    [UC-VID-001; UC-VID-002],
    [REQ-VID-UPL-010–011; REQ-VID-TRIM-012],
  ),
)

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
