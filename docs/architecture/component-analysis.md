# Arquitetura de componentes do PictuRAS

**Base analisada:** commit `0523102` do repositório `picturas-27`, em 2026-11-04. Diagramas: [global](component-diagram-global.puml) ([SVG](component-diagram-global.svg)) e [vídeo](component-diagram-video.puml) ([SVG](component-diagram-video.svg)). São vistas da implementação, não propostas de refatorização.

## Visão global

Nginx é a entrada HTTPS: encaminha `/` para o frontend, `/api-gateway/` para o API Gateway, `/socket.io` para `wsGateway` e `/s3/` para SeaweedFS (`nginx/nginx.conf`). O API Gateway encaminha pedidos REST para `projects`, `users` e `subscriptions` (`apiGateway/app.js`, `apiGateway/routes/`). Cada serviço de domínio tem a sua MongoDB (`docker-compose.yaml`). `projects` gere projetos, media, pipelines e Process/Result; `users` suporta contas e quota; `subscriptions` gere planos e pagamentos simulados. `img_storage` oferece upload, URLs e cópia através de SeaweedFS (`projects/utils/imageStorage.js`, `imageStorageService/server.js`).

RabbitMQ liga a orquestração aos processadores. A exchange direta `picturas` tem filas para ferramentas de imagem, `video_queue`, `project_queue` e `ws_queue` (`rabbitMQ/definitions.json`, `projects/utils/project_msg.js`). Os workers recebem **referências a caminhos**; os ficheiros de trabalho ficam no volume `image_data`, montado em `projects` e nos workers (`docker-compose.yaml`). A linha para SeaweedFS representa armazenamento persistente e obtenção por URL; não implica acesso S3 direto do worker.

O diagrama global agrupa os workers de imagem para preservar a legibilidade. `generative-mock` aparece porque o serviço `expand_ai` o consulta por HTTP (`docker-compose.yaml`, `Tools/expand_ai/expand_ai.py`). O backup `mongo-backup` existe no Compose, mas é um serviço operacional fora do percurso interativo; ELK está comentado e não integra a arquitetura ativa (`docker-compose.yaml`).

**Convenções visuais da revisão:** azul claro indica entrada/interface, lilás serviços de negócio, verde-azulado vídeo, verde claro imagem e cinzento infraestrutura. Ligações contínuas representam interfaces HTTP, Socket.IO ou acesso a dados, identificadas pela etiqueta; ligações tracejadas representam AMQP. No diagrama global, um nó `MongoDB` agrega graficamente **três instâncias independentes**, sem sugerir uma base partilhada. As ligações AMQP são dependências estruturais; a sequência temporal está descrita abaixo e não deve ser inferida da posição dos nós. O detalhe interno do worker fica apenas na segunda vista.

## Percurso do vídeo

1. O frontend envia o vídeo por Nginx e API Gateway para `projects`. Este valida tipo, codec e limites com `ffprobe`, regista metadados e envia o ficheiro original ao `img_storage`, que o guarda em SeaweedFS (`projects/routes/projects.js`, `projects/utils/video.js`, `projects/utils/imageStorage.js`).
2. Após definir o pipeline e pedir *Apply*, `projects` consulta o original por URL assinada, descarrega-o para `image_data`, cria os registos `Process` do lote e publica **uma mensagem por vídeo com o pipeline completo** em `video_queue` (`projects/routes/projects.js`, `projects/utils/processBatch.js`, `projects/utils/project_msg.js`).
3. `video_tool` consome a mensagem com `prefetch_count=1` e confirmação manual. `video.py` chama `video_processor.process_video()`. O processador usa `ffprobe`/`ffmpeg`, `effects.py` para efeitos por fotograma, `subtitles.py` para legendagem e `frame_extraction.py` para extração terminal. Estes ficheiros são **módulos do mesmo serviço**, não microserviços (`Tools/video/`). A legendagem pode dividir o trabalho em etapas com ficheiros temporários; a extração usa o vídeo editado quando há passos anteriores (`Tools/video/video_processor.py`).
4. O worker escreve no volume partilhado, publica percentagens em `ws_queue` e conclusão/erro em `project_queue`. `projects` associa a resposta ao `Process`, envia o output a `img_storage` para `out` ou `preview` e publica notificações em `ws_queue`. `wsGateway` envia eventos Socket.IO ao frontend, que obtém o resultado por URL (`Tools/video/video.py`, `projects/routes/projects.js`, `wsGateway/index.js`).

**Diferença face às imagens:** as imagens avançam por filas e workers de efeito individuais, com retorno por passo a `project_queue`; o vídeo concentra os passos num `video_tool` e numa mensagem por vídeo (`projects/routes/projects.js`, `projects/utils/project_msg.js`). Esta descrição abrange também projetos mistos.

## Padrões observados e consequências

| Padrão | Evidência | Consequência arquitetural |
|---|---|---|
| Serviços independentes com API Gateway | Serviços e bases separadas em `docker-compose.yaml`; rotas em `apiGateway/routes/` | Responsabilidades e persistência separadas; chamadas de `projects` a `users` e `img_storage` criam dependências síncronas. |
| Processamento orientado a mensagens | Exchange/filas em `rabbitMQ/definitions.json`; produtores/consumidores em `projects/utils/project_msg.js` e `Tools/video/video.py` | O processamento é desacoplado do pedido HTTP; resultado e progresso dependem do broker e da correlação de mensagens. |
| Pipeline sequencial de efeitos | `projects/routes/projects.js` e `Tools/video/video_processor.py` | Imagens percorrem workers por passo; vídeo executa internamente uma sequência ordenada num serviço. |
| Worker de vídeo concentrado | `Tools/video/video.py`, `video_processor.py`, `effects.py`, `subtitles.py`, `frame_extraction.py`; um serviço `video_tool` em `docker-compose.yaml` | Corte, velocidade, efeitos, legendagem e fotogramas partilham processo e recursos; a implementação atual tem um único worker configurado. |

## Pontos de atenção para a Fase 2

- **Capacidade:** `video_tool` usa `prefetch_count=1`; existe uma instância declarada no Compose. Trabalhos longos competem pela mesma capacidade de processamento (`Tools/video/video.py`, `docker-compose.yaml`).
- **Recuperação:** a confirmação ocorre no fim; uma interrupção pode causar reentrega. A análise de idempotência dos efeitos e da persistência dos resultados merece medição própria (`Tools/video/video.py`, `projects/routes/projects.js`).
- **Modificabilidade:** `projects` bifurca explicitamente imagem/vídeo e `effects.py` reproduz operações dos workers de imagem. Mudanças de filtros podem exigir manutenção em dois percursos (`projects/routes/projects.js`, `Tools/video/effects.py`).
- **Desempenho:** legendagem pode introduzir várias passagens e ficheiros temporários, enquanto os efeitos comuns partilham uma passagem; a diferença está implementada em `video_processor.py`. O impacto quantitativo exige medição.
- **Dependências críticas:** o lote depende do RabbitMQ, do volume `image_data`, do serviço de armazenamento e da base de projetos. O diagrama não representa alta disponibilidade porque não está configurada no Compose.

## Âmbito e validação

O PDF `doc-ext-requisitos-2627.pdf` na raiz da área de trabalho (Fase 1) foi usado como contexto histórico; a fonte de verdade para o estado atual é o código. O enunciado autónomo da Fase 2 não foi localizado nos ficheiros disponíveis; o template `RAS-exercicio_6_bloco1_SWdesign_template_PT.md` pede a vista global com o vídeo destacado. Não se inferiram componentes futuros. Os ficheiros `.puml` foram renderizados em SVG com o PlantUML existente no ambiente e não foram alterados ficheiros funcionais.

## Registo da atividade

**2026-11-04, 14:58 WET · base `0523102`.** Analisados `AGENTS.md`, Compose, Nginx, API Gateway, `projects`, armazenamento, worker de vídeo, RabbitMQ, WebSocket e os materiais de RAS disponíveis. Criados os dois `.puml`, os dois `.svg` e este documento. Validação: PlantUML renderizou os SVGs sem erro; sem alterações funcionais ou commit.

**2026-11-04, 15:07 WET · revisão visual · base `0523102`.** Revistos os dois PlantUML existentes. Reagrupados os componentes por responsabilidade, separada a paleta por categoria arquitetural, concentrado o detalhe dos módulos no diagrama de vídeo e agregadas as dependências AMQP repetidas na vista global. As ligações foram novamente confrontadas com `nginx/nginx.conf`, `docker-compose.yaml`, `projects/utils/project_msg.js`, `projects/routes/projects.js`, `Tools/video/video.py` e `wsGateway/index.js`. Gerados SVGs e PNGs temporários com PlantUML; as pré-visualizações foram abertas e inspecionadas. A versão global continua larga devido às dependências entre fronteiras, mas os nós e etiquetas são legíveis e não se sobrepõem. Não foram alterados ficheiros funcionais; o estado Git final é registado na resposta de entrega.
