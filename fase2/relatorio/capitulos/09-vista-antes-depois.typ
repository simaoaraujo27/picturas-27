#import "../template.typ": *

= Vista Arquitetural Antes e Depois

As duas vistas seguintes são diagramas de componentes simplificados, desenhados em Typst. Usam a mesma largura, disposição e nível de abstração: entrada, despacho, processamento, resposta/progresso e armazenamento. Os elementos introduzidos pelo DA-1 estão a verde. Os componentes e interfaces correspondem à base `0523102` e ao encadeamento implementado em `1fe42ba`, presente na revisão integrada. As vistas do DA-2 distinguem a apresentação visual do mecanismo de recuperação.

#let caixa-video(titulo, corpo, cor: rgb("#DCEAF7")) = block(
  width: 100%, inset: 7pt, fill: cor, stroke: 0.5pt + gray, radius: 2pt,
)[
  #set par(justify: false)
  #text(size: 9pt, weight: "bold", titulo)
  #linebreak()
  #text(size: 8pt, corpo)
]

#let vista-video(depois: false) = block(width: 100%, breakable: false)[
  #caixa-video("Entrada e coordenação", if depois {
    "Browser → nginx → API Gateway → projects; projects calcula videoStages() e encadeia cada resposta."
  } else {
    "Browser → nginx → API Gateway → projects; projects envia a pipeline completa ao worker único."
  })
  #v(3pt)
  #align(center)[#text(size: 8pt)[↓ Despacho AMQP no exchange picturas ↓]]
  #v(3pt)
  #block(width: 100%, height: 3.2cm)[
    #if depois {
      grid(
        columns: (1fr, 1fr, 1fr), gutter: 6pt,
        caixa-video("Efeitos", "video_effects_queue → video_effects_tool. Efeitos consecutivos partilham uma passada. Sem Whisper.", cor: rgb("#C8E6C9")),
        caixa-video("Legendagem", "video_subtitles_queue → video_subtitles_tool. Whisper e dependências próprias.", cor: rgb("#C8E6C9")),
        caixa-video("Fotogramas", "video_frames_queue → video_frames_tool. Extração e previews próprios.", cor: rgb("#C8E6C9")),
      )
    } else {
      caixa-video("video_queue → video_tool", "Um consumidor e uma imagem Docker para efeitos, legendagem e fotogramas. Dependências comuns incluem FFmpeg, Pillow e Whisper. A pipeline completa é processada dentro desta fronteira.", cor: rgb("#EEEEEE"))
    }
  ]
  #caixa-video("Resposta e acompanhamento", if depois {
    "project_queue → projects: resultado e avanço para o estágio seguinte. ws_queue → wsGateway → browser: progresso global por base/span."
  } else {
    "project_queue → projects: resposta do worker único. ws_queue → wsGateway → browser: progresso da execução no monólito."
  })
  #v(6pt)
  #caixa-video("Persistência e ficheiros — interfaces mantidas", "image_data: ficheiros de trabalho; img_storage / S3: originais e resultados; MongoDB: projetos; whisper_models: modelos de legendagem.", cor: rgb("#EEEEEE"))
]

== Antes

#figure(kind: image,
  vista-video(),
  caption: [Vista do subsistema de vídeo antes das decisões: um worker, uma fila, três domínios],
)

== Depois

#figure(kind: image,
  vista-video(depois: true),
  caption: [Vista do subsistema de vídeo depois do DA-1: uma fila e um worker por domínio; a verde, os elementos introduzidos],
)

== Legenda e notas

#tab([Legenda das duas vistas],
  tabela(
    colunas: (5cm, 1fr),
    [Elemento (cor, forma ou estilo)], [Significado],
    [Caixas azuis `#DCEAF7`], [Interface e serviços de entrada e fronteira: frontend/nginx, API Gateway, `projects`, `wsGateway` — sem novos componentes na comparação estrutural do DA-1; as alterações de estado e API do DA-2 são descritas na vista própria],
    [Caixas cinzentas claras], [Serviços e infraestrutura de negócio: `img_storage`, MongoDB, SeaweedFS/S3, volume partilhado `image_data` — inalterados],
    [Caixas verdes `#C8E6C9` na vista «depois»], [«tática: separar por domínio» (TAT-01/TAT-02) — filas e workers novos: `video_effects_queue`/`video_effects_tool`, `video_subtitles_queue`/`video_subtitles_tool`, `video_frames_queue`/`video_frames_tool`],
    [Setas e etiquetas AMQP], [Despacho no exchange `picturas`; resposta em `project_queue`; progresso em `ws_queue`. As etiquetas distinguem os dois caminhos],
    [Bloco cinzento inferior], [Armazenamento e interfaces mantidos: volume partilhado, S3 e projetos MongoDB],
  ),
)

#tab([Diferenças entre as vistas],
  tabela(
    colunas: (3.4cm, 4.2cm, 4.2cm, 1fr),
    tamanho: 8.5pt,
    [Aspeto], [Antes], [Depois], [Decisão / tática],
    [Fila de despacho de vídeo], [`video_queue`, única para os três domínios], [`video_effects_queue`, `video_subtitles_queue`, `video_frames_queue`], [DA-1 / TAT-01, TAT-02],
    [Contentores de processamento], [`video_tool`, um processo com Pillow, FFmpeg, Faster-Whisper e `torch`], [Três serviços com `requirements.txt` próprio; `torch`/Whisper só no de legendas], [DA-1 / TAT-02],
    [Composição do pipeline], [`projects` enviava a pipeline inteira num único envio], [`projects` calcula `videoStages()` e encadeia a resposta de cada estágio em `project_queue`], [DA-1 / TAT-03],
    [Progresso], [Publicado pelo worker monolítico, sem separação por estágio], [Publicado pelos três workers com `base`/`span`, agregado pelo orquestrador], [DA-1 / TAT-05],
    [Isolamento de falhas], [Uma falha na legendagem parava o único worker], [Falha confinada ao worker de legendas; os outros dois continuam], [DA-1 / TAT-02],
  ),
)

O que permanece igual é tão importante como o que muda: o pedido continua a entrar pelo mesmo gateway, o orquestrador `projects` continua a ser o único coordenador do lote, os ficheiros continuam a não viajar nas mensagens e os resultados continuam nos mesmos estágios S3. A alteração é, portanto, de granularidade e de composição — precisamente o tipo de mudança que uma fase de _refactoring_ permite — e não de comportamento funcional. A vista «antes» mostra a sequência completa num único bloco de processamento; a vista «depois» mostra os três blocos ligados por `project_queue`, que é onde a regressão dos pipelines mistos ocorreu e foi corrigida (`1fe42ba`), com a cobertura de integração correspondente (`85b99d4`).

== Ecrã de processamento antes e depois (DA-2)

O DA-2 reúne duas alterações complementares: cartão não bloqueante e recuperação do acompanhamento após F5. As capturas seguintes mostram apenas a primeira, medida na mesma janela e com o mesmo projeto. O suporte de estado e API no backend é descrito na tabela e na sequência de recuperação; estas capturas não são apresentadas como prova de refresh.

#figure(kind: image,
  image(width: 100%, "../images/ui_antes.png"),
  caption: [Ecrã de processamento antes do DA-2: o elemento cobre a área de conteúdo (83,3 % da janela)],
)

#figure(kind: image,
  image(width: 100%, "../images/ui_depois.png"),
  caption: [Ecrã de processamento depois do DA-2: cartão fixo no canto (4,6 % da janela)],
)

#tab([Diferenças entre as vistas do ecrã de processamento],
  tabela(
    colunas: (3.4cm, 4.6cm, 4.6cm, 1fr),
    tamanho: 8.5pt,
    [Aspeto], [Antes], [Depois], [Decisão / tática],
    [Posição e tamanho], [`absolute top-0 left-0 h-screen w-screen`; 1280 × 695 px visíveis (83,3 %)], [`fixed bottom-4 right-4`; 289,6 × 169,6 px (4,6 %)], [DA-2 / TAT-04],
    [Fundo], [`bg-black/70` escurece a área de conteúdo], [Sem fundo escurecido; `shadow-lg` no cartão], [DA-2 / TAT-04],
    [Interação durante o processamento], [Só o Cancelar responde na área de conteúdo], [A interface responde], [DA-2 / TAT-04],
    [Conteúdo do cartão], [Barra de progresso (`w-96`), percentagem e Cancelar], [Os mesmos, com a barra em `w-64`], [—],
    [Âmbito do indicador], [Página do projeto], [Página do projeto (limitação)], [TAT-06 rejeitada],
    [Origem do acompanhamento], [Estado React e eventos recebidos pela página aberta], [`processingState` no MongoDB e consulta de estado via API Gateway], [DA-2 / TAT-09],
    [Refresh ou reabertura], [Perda do acompanhamento local; trabalho pode continuar no servidor], [`useGetProcessingStatus` reconstrói o cartão a partir da execução persistida], [DA-2 / TAT-09],
    [Cancelamento recuperado], [Botão dependente do estado local perdido em F5], [API devolve `canCancel`; pedido usa versão atual e token da execução], [DA-2 / TAT-09],
  ),
)

O resultado da edição e a execução iniciada por Apply devem permanecer os mesmos. O que muda é a origem e a reconstrução do acompanhamento: a alteração inicial de CSS manteve a lógica local, mas a recuperação posterior acrescentou persistência e consulta de estado. Não é correto descrever o DA-2 completo como uma alteração apenas de classes CSS.

*Sequência após F5 ou reabertura do projeto:*
+ O browser monta a página e consulta `GET /:user/:project/process/status` através do API Gateway.
+ `projects` lê o projeto MongoDB e devolve token, estado, progresso, versão e permissão de cancelamento.
+ O frontend apresenta o acompanhamento de uma execução ativa ou reconhece o estado terminal. Mantém consultas periódicas de 2 s; não submete novamente Apply.
+ Ao cancelar, o frontend obtém a versão atual e envia `X-Process-Token`. O backend aceita apenas a execução ativa autorizada e persiste `cancelled`.

Esta sequência está implementada. O sucesso manual de F5 e saída/regresso está registado no capítulo 10; a identidade do token, os tempos e o cancelamento concorrente não foram medidos nesse relato.


#figure(kind: image,
  grid(
    columns: (1fr, 1fr), gutter: 8pt,
    [*Antes — estado apenas na página*], [*Depois — recuperação pelo backend*],
    caixa-video("Durante a execução", "React e eventos WebSocket mantêm o cartão na página aberta."),
    caixa-video("Durante a execução", "projects mantém processingState no MongoDB; a página consulta a API.", cor: rgb("#C8E6C9")),
    align(center)[↓ F5 ou reabertura ↓], align(center)[↓ F5 ou reabertura ↓],
    caixa-video("Página novamente montada", "O estado local inicial não identifica a execução que continua no servidor.", cor: rgb("#EEEEEE")),
    caixa-video("Página novamente montada", "GET process/status → projects → MongoDB; resposta com token, progresso, versão e canCancel.", cor: rgb("#C8E6C9")),
    caixa-video("Acompanhamento", "Cartão e controlo de cancelamento não são reconstruídos a partir da execução ativa.", cor: rgb("#EEEEEE")),
    caixa-video("Acompanhamento", "Reconstruir o cartão; manter consultas; cancelar com versão e X-Process-Token. Não reenviar Apply.", cor: rgb("#C8E6C9")),
  ),
  caption: [Mecanismo de acompanhamento antes e depois do DA-2; verde identifica o suporte de recuperação introduzido],
)
