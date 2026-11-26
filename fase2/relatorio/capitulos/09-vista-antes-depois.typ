#import "../template.typ": *

= Vista Arquitetural Antes e Depois

As duas vistas usam o mesmo tipo de diagrama de componentes UML, a mesma orientação (esquerda → direita), os mesmos grupos de contexto e uma legenda com as mesmas cores. O que muda é o número de filas e de contentores de processamento de vídeo e a forma como o orquestrador compõe os estágios. A vista «antes» é o diagrama `docs/architecture/component-diagram-video.puml` da solução de base (`0523102`); a vista «depois» é o desenho da implementação final, com os elementos introduzidos pelo DA-1 a verde.

== Antes

#figure(kind: image,
  image(width: 100%, "../images/vista_antes.png"),
  caption: [Vista do subsistema de vídeo antes das decisões: um worker, uma fila, três domínios],
)

== Depois

#figure(kind: image,
  image(width: 100%, "../images/vista_depois.png"),
  caption: [Vista do subsistema de vídeo depois do DA-1: uma fila e um worker por domínio; a verde, os elementos introduzidos],
)

== Legenda e notas

#tab([Legenda das duas vistas],
  tabela(
    colunas: (5cm, 1fr),
    [Elemento (cor, forma ou estilo)], [Significado],
    [Caixas azuis `#DCEAF7`], [Interface e serviços de entrada e fronteira: frontend/nginx, API Gateway, `projects`, `wsGateway` — inalterados entre as duas vistas],
    [Caixas cinzentas claras], [Serviços e infraestrutura de negócio: `img_storage`, MongoDB, SeaweedFS/S3, volume partilhado `image_data` — inalterados],
    [Caixas verdes `#C8E6C9` na vista «depois»], [«tática: separar por domínio» (TAT-01/TAT-02) — filas e workers novos: `video_effects_queue`/`video_effects_tool`, `video_subtitles_queue`/`video_subtitles_tool`, `video_frames_queue`/`video_frames_tool`],
    [Setas a tracejado], [Mensagens AMQP no exchange `picturas` (despacho, resposta em `project_queue`, eventos `video-progress` em `ws_queue`)],
    [Setas contínuas cinzentas], [Acesso a ficheiros no volume partilhado ou no S3],
  ),
)

#tab([Diferenças entre as vistas],
  tabela(
    colunas: (3.4cm, 4.2cm, 4.2cm, 1fr),
    tamanho: 8.5pt,
    [Aspeto], [Antes], [Depois], [Decisão / tática],
    [Fila de despacho de vídeo], [`video_queue`, única para os três domínios], [`video_effects_queue`, `video_subtitles_queue`, `video_frames_queue`], [DA-1 / TAT-01, TAT-02],
    [Contentores de processamento], [`video_tool`, um processo com Pillow, FFmpeg e Faster-Whisper], [Três serviços com dependências próprias. Faster-Whisper fica no de legendas.], [DA-1 / TAT-02],
    [Composição do pipeline], [`projects` enviava a pipeline inteira num único envio], [`projects` calcula `videoStages()` e encadeia a resposta de cada estágio em `project_queue`], [DA-1 / TAT-03],
    [Progresso], [Publicado pelo worker monolítico, sem separação por estágio], [Percentagens calculadas pelos workers por estágio com `base`/`span` e publicadas em `ws_queue`], [DA-1 / TAT-05],
    [Isolamento de falhas], [Uma falha na legendagem parava o único worker], [Falha confinada ao worker de legendas; os outros dois continuam], [DA-1 / TAT-02],
  ),
)


Em `b8f44b3`, um estágio formado apenas por operações `trim` executa o corte e a codificação
num único processo FFmpeg (`Tools/video_effects/effects.py`). Os estágios com efeitos sobre os
fotogramas usam o percurso que aplica os efeitos em Python.

Os três workers publicam eventos de progresso por WebSocket. Na implementação da recuperação
após F5, o worker de efeitos também envia progresso intermédio ao orquestrador, que o persiste.
O frontend consulta `/process/status` para apresentar o estado persistido. A legendagem e a
extração enviam progresso intermédio por WebSocket, pelo que esse percurso deve ser avaliado
separadamente da recuperação. O encadeamento de pipelines mistos foi corrigido em `1fe42ba`,
com o caso de integração acrescentado em `85b99d4`.

O que permanece igual é tão importante como o que muda: o pedido continua a entrar pelo mesmo gateway, o orquestrador `projects` continua a ser o único coordenador do lote, os ficheiros continuam a não viajar nas mensagens e os resultados continuam nos mesmos estágios S3. A alteração é, portanto, de granularidade e de composição — precisamente o tipo de mudança que uma fase de _refactoring_ permite — e não de comportamento funcional. A vista «antes» mostra a sequência completa num único bloco de processamento; a vista «depois» mostra os três blocos ligados por `project_queue`, que é onde a regressão dos pipelines mistos ocorreu e foi corrigida (`cc53fac`), com a cobertura de integração correspondente (`2ee32d7`).

== Ecrã de processamento antes e depois (DA-2)

O DA-2 altera a interface e não os componentes do backend, por isso a vista usa capturas do mesmo ecrã, com o elemento de processamento destacado pelo inspetor do browser, na mesma janela e com o mesmo projeto.

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
  ),
)

O que permanece igual é a lógica: o estado `processing`, o progresso mostrado, o cancelamento e o resultado do processamento não foram alterados. A alteração é, portanto, de apresentação e de interação, e não de comportamento funcional.
