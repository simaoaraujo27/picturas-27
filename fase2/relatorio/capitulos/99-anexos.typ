#import "../template.typ": *

#set heading(numbering: "A.1.")
#counter(heading).update(0)

= Instruções de execução

== Pré-requisitos e arranque

#tab([Pré-requisitos e arranque],
  tabela(
    colunas: (4cm, 1fr),
    [Passo], [Comando / observação],
    [Requisitos], [Docker com Compose (na campanha: Docker 29.10.0), Node.js 22.22.1 no cliente da campanha, Python 3.14 nos testes (com `.venv`), `ffmpeg`/`ffprobe` no `PATH`, `typst` para compilar o relatório; cerca de 15 GB de disco e 8 GB de RAM para o build inicial (15–30 min)],
    [Obter a base], [`git clone git@github.com:simaoaraujo27/picturas-27.git && cd picturas-27 && git checkout 0523102`],
    [Arrancar a stack], [`docker compose up -d --build` (na primeira execução; `docker compose up -d` nas seguintes)],
    [Aceder], [Abrir `https://localhost:8080` e aceitar o certificado autoassinado; RabbitMQ em `http://localhost:15672` (`user` / `password`)],
    [Parar e limpar], [`docker compose down` (parar) ou `docker compose down -v --remove-orphans` (parar e apagar volumes, incluindo dados S3 e MongoDB)],
    [Atenção], [Se a instalação anterior usar o esquema S3 antigo (um _bucket_ por utilizador), executar `docker compose down -v --remove-orphans` uma vez antes do primeiro arranque],
  ),
)

`users`, `subscriptions` e `apiGateway` usam _bind mount_ e recarregam com nodemon. O frontend é um build de produção e os serviços Python não têm _bind mount_: após alterações, reconstruir o serviço (`docker compose up -d --build <service>`). Em particular, uma alteração em `projects/` exige `docker compose up -d --build projects`; um `restart` não basta. Depois de reconstruir o frontend, `docker compose restart nginx`.

== Repetir os testes

#tab([Comandos e resultados históricos por campanha],
  tabela(
    colunas: (5cm, 1fr),
    [Suite], [Comando e observação],
    [Orquestrador (Node)], [`node --test projects/tests/` — na campanha M3 em `3df66ae`: 31/31],
    [Workers de vídeo (Python)], [`.venv/bin/python -m pytest Tools/video_effects/tests Tools/video_subtitles/tests Tools/video_frames/tests -q` — na campanha M3 em `3df66ae`: 54/54; exige `ffmpeg`/`ffprobe` no host, sem Docker],
    [Suite principal], [`make test-all` a partir de `25f4bd9` (referência funcional) e de `b8f44b3` (versão final com as alterações locais registadas na checklist). A tabela de preservação do capítulo 10 reúne os resultados.],
    [Integração], [`make test-integration` para executar a suite separadamente. Na campanha mais recente, passaram 30/31 na versão final. A remoção de fundo passou numa repetição isolada.],
    [Playwright na versão final], [Após executar `make test-fixtures`, executar `node_modules/.bin/playwright test accessibility.spec.ts authentication.spec.ts image-processing.spec.ts projects.spec.ts video-processing.spec.ts`. Na campanha passaram 9/11. Os dois casos restantes passaram na repetição isolada `R-20261126-143643-e2e-recheck`, cujo comando consta da checklist.],
    [Falhas conhecidas], [`make test-known-failures`. Os 13 casos falharam nas duas revisões, em execuções separadas da suite principal.],
    [Registo], [`docs/REGRESSION_CHECKLIST.md` e `tests/TEST_EXECUTION_PROTOCOL.md`. Os relatórios JUnit ficam em `tests/reports/`.],
  ),
)

O caso que cobre a regressão dos pipelines mistos é
`[VID-01,VID-04,PIPE-01] mixed border and subtitles preserve both effects`
em `tests/functional/integration/processing.test.js`. Usa `tests/fixtures/videos/speech.mp4` (320×240, 6 s, com fala e áudio AAC), aplica `border` de 4 px vermelho seguido de `subtitles` e verifica dimensão 328×248, `[245,2,2]` no canto, aumento do canal verde médio pelas legendas queimadas e presença da faixa de áudio. O vídeo adicional `samples/video/speech_mandela_177s_1080p.webm` é opcional para inspeção manual e não é necessário para a suíte.

== Repetir as medições (antes e depois)

#tab([Passos para repetir as medições do CAND-1],
  tabela(
    colunas: (4cm, 1fr),
    [Medição], [Procedimento],
    [Variantes], [Base: worktree destacado em `0523102` (`git worktree add --detach /tmp/opencode/base-radon 0523102`). Depois: escolher explicitamente o commit da campanha (`b8f44b3` na carga; `3df66ae` em M2–M4). Mesmo host, mesmos comandos],
    [Tamanho das imagens], [`docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}'`; na base, `video_tool` = 1,70 GB; na variante final, `video_effects_tool` = 1,09 GB, `video_subtitles_tool` = 1,74 GB, `video_frames_tool` = 1,09 GB],
    [Estrutura e dependências], [`git ls-tree -r --name-only 0523102 Tools/video/`; `ls Tools/video_effects Tools/video_subtitles Tools/video_frames`; comparar os quatro `requirements.txt` e as filas em `rabbitMQ/definitions.json`],
    [Manutenibilidade], [`radon mi` (instalado no `.venv`) sobre `Tools/video/` na base e sobre os três diretórios na variante final. Todas as classificações são `A`, pelo que a métrica não distingue as variantes],
    [Progresso e isolamento], [Executar o caso de pipeline misto e recolher os eventos `video-progress` no socket (8, 16, 25, 33, 42, 50, 50, 90, 100); provocar falha no worker de legendas e verificar que os outros dois domínios concluem],
    [Benchmark de regressão system-wide], [`tests/performance/benchmark/executar.sh <commit> <directório-de-saída>` cria um worktree isolado, deteta automaticamente `video.py`/`video_queue` na base ou `video_effects.py`/`video_effects_queue` na variante final e grava ambiente, imagens, latências, débito, falhas e utilização de recursos. Usar `PERF_SCENARIOS`, `PERF_REPETITIONS` e `PERF_VIDEO` para escolher cenários, repetições e entrada. O worktree é removido no `trap` de saída],
    [Limpeza], [`git worktree remove /tmp/opencode/base-radon` quando as medições terminarem],
  ),
)

A campanha mais recente está documentada em `resultados-desempenho-inicial.md` e
`resultados-regressao-atual.md`, com dados brutos locais em `tests/reports/comparacao-final/`.
O executor usa as portas de loopback 18443 (HTTPS) e 18672 (gestão RabbitMQ), volumes
recriados e tolerância de 90 s para o arranque do broker nesta campanha. Os dados
históricos permanecem em `tests/performance/resultados-desempenho-inicial/`.

*Campanha M2–M4 arquivada.* O framework passou para `evaluation/`; a utilização está em `evaluation/README.md`. Com Python, Radon 6.0.1, jscpd 5.4.3 e Docker preparados, executar, para cada um dos quatro commits de EV-14, `python -m evaluation run <commit> --all --jscpd <executável> --results-root <diretório-novo> --run-id <identificador>`. O executor cria worktrees e stacks isolados. Não confundir o exit 1 dos contratos VF-07/VF-10 com uma medição aprovada; consultar os relatórios por caso. As versões e os resultados acima são históricos, não garantias para qualquer checkout atual. Os comandos com `.venv/bin/` e variáveis de ambiente no prefixo assumem shell POSIX (Linux/WSL).

== Repetir a verificação de recuperação do CAND-2

O percurso de F5 está implementado; o procedimento abaixo permite completar a evidência sem alterar funcionalidades. Nas notas de 17 de novembro consta sucesso manual de refresh e saída/regresso, sem tempos, tokens ou gravação. A configuração, as repetições e os resultados desta verificação devem ser registados quando o procedimento for executado.

#tab([Verificação do acompanhamento após refresh — QS-02 / DA-2],
  tabela(
    colunas: (4cm, 1fr),
    [Passo], [Procedimento e resultado a registar],
    [Preparar a revisão], [Usar a revisão integrada com `processingState` e API de estado; a base `0523102` serve apenas para comparação. Reconstruir os serviços alterados da revisão atual; os workers especializados são os do Compose. Após reconstruir frontend, reiniciar nginx. Não apagar volumes com uma execução ativa.],
    [Iniciar e identificar], [Iniciar Apply num projeto e registar perfil, ficheiros, pipeline, estado e token devolvidos por `GET /:user/:project/process/status`. O projeto usado na medição visual não é automaticamente o do relato de F5.],
    [Recarregar], [Fazer F5 durante o trabalho. Confirmar o regresso do acompanhamento da mesma execução e os controlos permitidos. A percentagem pode ter avançado. Registar o tempo se houver cronómetro e verificar que F5 não originou novo Apply.],
    [Sair e regressar], [Navegar para fora e reabrir o projeto; verificar a recuperação a partir do backend. Não exigir que o cartão esteja sempre visível noutras páginas: essa é a alternativa de indicador global não escolhida.],
    [Cancelar e estados terminais], [Cancelar após a recuperação; registar a versão/token e o estado `cancelled`. Repetir F5 e verificar que a execução não reaparece ativa. Ensaiar separadamente conclusão, falha e permissões.],
    [Integração com DA-1], [Repetir com efeitos, legendas e extração, incluindo pipeline misto. Verificar no estado persistido a coerência com o progresso por estágio; eventos Socket.IO, isoladamente, não demonstram recuperação após refresh.],
    [Evidência], [Registar procedimento, executor, revisão, resultado e limites. Capturas ou vídeo, se recolhidos, complementam o registo; não declarar latências, percentagens de sucesso ou casos de falha sem medição/ensaio correspondente.],
  ),
)

== Compilar o relatório

Na pasta `fase2/relatorio/`: `typst compile --font-path fonts main.typ main.pdf`. Para rever alterações enquanto se escreve: `typst watch --font-path fonts main.typ`. Antes de entregar, `main.typ` deve ter `#mostrar-orientacoes.update(false)` e não podem restar marcadores de preenchimento.

= Glossário

#tabela(
  colunas: (4cm, 1fr),
  [Termo], [Definição],
  [Cenário de qualidade (`QS-nn`)], [Descrição verificável de um estímulo, do artefacto afetado, do ambiente, da resposta esperada e da respetiva medida; é a entrada das táticas e das decisões],
  [Evidência (`EV-nn`)], [Facto observável no código, na configuração ou num documento, com localização no commit de partida],
  [Hipótese (`H-nn`)], [Afirmação plausível ainda sem evidência direta, que deve ser confirmada por uma medição ou ensaio],
  [Candidato a RNF (`CAND-n`)], [Requisito não funcional escolhido para melhorar nesta fase, classificado segundo a ISO/IEC 25010],
  [Tática (`TAT-n`)], [Decisão de desenho que produz a resposta pretendida perante um estímulo; nesta fase, apenas de classe A (refactoring) ou B (alteração visível pretendida)],
  [Decisão arquitetural (`DA-n`)], [Registo ao estilo ADR com contexto, tática escolhida, estrutura, alternativas rejeitadas, consequências e implementação],
  [Radon MI], [Índice de manutenibilidade calculado pelo pacote Python `radon`; classes de `A` (melhor) a `C` (pior)],
  [Pipeline], [Lista ordenada de efeitos guardada no projeto e aplicada em lote a todos os media desse projeto],
  [Estágio], [Grupo de etapas consecutivas do pipeline executado por um worker; etapas de um mesmo estágio partilham uma descodificação/codificação],
  [`videoStages()`], [Função em `projects/utils/video.js` que converte o pipeline do projeto na sequência de estágios e determina o worker destinatário de cada um],
  [`project_queue`], [Fila de resposta dos workers para o orquestrador; é também usada para encadear o estágio seguinte com o resultado intermédio],
  [`ws_queue`], [Fila de eventos de progresso consumida pelo `wsGateway` e entregue ao browser por Socket.IO],
  [`base`/`span`], [Parâmetros que indicam a que parte da execução global corresponde o progresso de um estágio, permitindo agregação entre workers],
  [`Process`], [Registo de uma unidade de trabalho (media × efeito ou estágio) criado antes do despacho e concluído quando o resultado é publicado],
  [`processingState`], [Estado durável do acompanhamento de uma execução no projeto MongoDB: token, estado, passos, progresso e datas; consultado pela página após F5 ou reabertura, no âmbito do DA-2],
  [Estágios S3], [`src` (original), `out` (resultado), `preview` e `preview_cache`; os ficheiros não trafegam nas mensagens do RabbitMQ],
  [Pré-visualização], [Renderização parcial — para vídeo, apenas os primeiros `VIDEO_PREVIEW_SECONDS` (3 s) — usada para mostrar o resultado antes da execução completa],
)
