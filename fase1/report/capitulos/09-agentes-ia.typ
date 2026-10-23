#import "../template.typ": *

= Implementação Assistida por Agentes de IA

#orientacao[
  Obrigatório (enunciado): documentar as ferramentas e _skills_ utilizadas, enumerar as tarefas apoiadas e
  comprovar a validação realizada — tanto na especificação como no código
  e nos testes. A equipa é responsável por todo o conteúdo entregue, incluindo o gerado por IA.
  Valoriza-se evidência concreta (_commits_, _pull requests_, ficheiros de configuração dos agentes) e
  reflexão crítica (onde a IA errou e como isso foi detetado).
]

== Ferramentas, modelos e configuração

#tabela(
  colunas: (4cm, 1fr),
  [Ferramenta / modelo], [Configuração e utilização (_skills_, instruções de projeto, MCP, …)],

  [Antigravity CLI \ (Gemini 3.8 Flash)],
  [Ambiente de desenvolvimento agêntico integrado. Configurado com instruções de projeto baseadas no enunciado da UC, _guidelines_ da Fase 1 e acesso a ferramentas de terminal, análise estática e compilação Docker/Typst.],

  [GitHub Copilot],
  [Assistência contextual de autocomunicação e geração rápida de código repetitivo no editor de desenvolvimento.],

  [ChatGPT],
  [Utilizado pelo estudante como apoio ao desenvolvimento do UC-VID-001, conforme confirmação do próprio. Não estão disponíveis transcrições exportadas, nem informação sobre versão do modelo ou configuração.],

  [OpenAI Codex],
  [Utilizado nas interações documentadas para inspeção de código, edição de artefactos e execução de verificações. Não foi identificada uma configuração de projeto ou versão de modelo associada às alterações do Upload. Nesta revisão foi consultada a skill local `pdf` para extrair as diretrizes do professor.],
)

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas por agentes de IA e validação],
  tabela(
    colunas: (2.8cm, 2cm, 1fr, 1fr, 2.4cm),
    tamanho: 8pt,
    [Ferramenta / _skill_], [Caso de uso], [Tarefa apoiada], [Validação realizada pela equipa], [Evidência],

    [ChatGPT],
    [UC-VID-001],
    [Utilização confirmada pelo estudante para analisar o caso de uso e os requisitos, identificar inconsistências, preparar instruções para o Codex, rever capítulos e rastreabilidade, discutir decisões arquiteturais e rever diagramas e resultados do Codex.],
    [O estudante confirmou estas atividades. Sem transcrições, prompts ou resultados específicos, não se atribuem ficheiros ou decisões concretas ao ChatGPT.],
    [Confirmação do estudante; histórico ChatGPT não exportado para o repositório.],

    [OpenAI Codex],
    [UC-VID-001],
    [Revisão da UC/ERS, IDs e categorias NOVO/ALT; utilização do Codex para implementar e alterar o código do Upload e do streaming no Gateway, `projects` e `mediaStorageService`, incluindo `maxUploadMemoryBytes`.],
    [O estudante definiu alvo e âmbito; dossiê, ERS e código foram comparados. O limite especificado é 1 GB decimal; a medição experimental permanece pendente e a quota acumulada por harmonizar. Commits não foram atribuídos a ferramentas.],
    [`upload.md`, `UC-VID-001.typ`, `05-ers.typ`, `07-rastreabilidade.typ`, `apiGateway/routes/projects.js`, `projects/routes/videos.js`, `mediaStorageService/route/video.js`; conversa registada.],

    [OpenAI Codex],
    [UC-VID-001],
    [Preparação dos testes de Upload pedidos para a tabela de validação; scripts em `tests/video_upload_smoke_test.py` e `tests/video_upload_size_test.py`.],
    [Cap. 7/10: 03/04 passaram; 06/07: só pré-validação; 08: bloqueado por HTTP 502 (SeaweedFS sem volumes); 13 pendente. Scripts não executados nesta revisão.],
    [Scripts e resultados registados nos capítulos 7 e 10.],

    [Antigravity \ (Gemini)],
    [UC-VID-002],
    [Estruturação inicial do caso de uso de recorte (_Trim_), fluxos alternativos e identificação de exceções de vídeo.],
    [Revisão manual exaustiva; ajuste dos limites de duração (180s Free / 60 min Premium) e regras de negócio para compatibilização _brownfield_.],
    [Commit `a778167` \ `trim.md`],

    [Antigravity \ (Gemini)],
    [UC-VID-002],
    [Derivação da ERS (RF e RNF) segundo ISO/IEC 25010 e critérios _Dado… Quando… Então…_.],
    [Verificação da conformidade com os 5 critérios de qualidade de requisitos; garantia de ausência de requisitos órfãos na matriz.],
    [Commit `a778167` \ `05-ers.typ`],

    [Antigravity \ (Gemini)],
    [UC-VID-002],
    [Implementação do nó `videoTrimWorker` (Python/FFmpeg) e integração de fila RabbitMQ.],
    [Inspeção de código; correção de parâmetros FFmpeg para preservação de streams de áudio AAC; testes de execução com `py_compile`.],
    [Commit `52b66f7` \ `videoTrimWorker/`],

    [Antigravity \ (Gemini)],
    [UC-VID-002],
    [Desenvolvimento da suite de testes de integração automatizada em Python (`tests/trim_integration.py`).],
    [Execução completa em ambiente Docker Compose local com validação de invariância de hash SHA-256 e esgotamento de quota Free.],
    [Commit `52b66f7` \ `tests/`],

    [Antigravity \ (Gemini)],
    [UC-VID-002],
    [Conversão e estruturação dos artefactos para a sintaxe Typst do template oficial.],
    [Compilação do documento sem avisos; verificação de formatação e remoção de texto genérico.],
    [Commit `a778167` \ `report/`],

    [ChatGPT],
    [UC-VID-004],
    [Apoio à revisão e ao preenchimento da ERS do caso de uso de compilação: organização dos requisitos, critérios de aceitação e rastreabilidade.],
    [O dossiê (`compile.md`) foi comparado com o código real da compilação (_worker_, rotas do `projects`, modelos, filas e diálogo) e com o comportamento da aplicação, e corrigido em conformidade: limites por perfil, validação do formato MP4/H.264, verificação do armazenamento, quota diária e ordem dos passos. Sem transcrições, prompts ou resultados específicos, não se atribuem decisões concretas ao ChatGPT.],
    [`compile.md`, `UC-VID-004.typ`, `05-ers.typ`, `07-rastreabilidade.typ`],

    [Claude \ (Anthropic)],
    [UC-VID-004],
    [Auxílio na implementação da compilação de vídeos: diálogo de compilação, rotas e fila de tarefas no `projects`, _worker_ com FFmpeg, integração no Docker e testes.],
    [Testes automáticos do _worker_ (`test_worker.py`: 7 testes com FFmpeg real e serviços HTTP simulados, ver cap. 10) e verificação manual na aplicação: ficheiros que não são vídeo não são listados, botão desativado com um só vídeo e contador de operações diárias a descer uma unidade por compilação.],
    [Commits `3762b2d` (v1.4), `d388b72` e `3fd696b` (v2.5); `videoCompileWorker/`, `projects/routes/trim.js`, `frontend/components/project-page/compile-videos-dialog.tsx`, `test_worker.py`.],

    [Claude \ (Anthropic)],
    [UC-VID-004],
    [Alinhamento do relatório com o código da compilação (UC, ERS, impacto, rastreabilidade, arquitetura e testes), proposta de correção do `compileQueue.js` e escrita dos diagramas PlantUML da compilação.],
    [Texto comparado com o código real (_worker_, rotas, modelos, diálogo, `docker-compose.yaml`) e com a aplicação; os erros detetados foram corrigidos (ver análise crítica). Testes manuais TST-COMP-08 a 11 executados pela equipa na aplicação.],
    [`UC-VID-004.typ`, `05-ers.typ`, `06-impacto.typ`, `07-rastreabilidade.typ`, `08-arquitetura.typ`, `10-testes-validacao.typ`, `images/*.puml`],

    [#text(hyphenate: true, "ChatGPT")], [#text(hyphenate: true, "UC-VID-005")], [#text(hyphenate: true, "Refinamento do UC/ERS, comparação com os dossiês e instruções de implementação por fases.")], [#text(hyphenate: true, "Revisões discutidas com o autor; sem comprovação de ensaio manual de todos os cenários.")], [#text(hyphenate: true, "VideoSpeed.md; conversa de trabalho não exportada.")],

    [#text(hyphenate: true, "OpenAI Codex")], [#text(hyphenate: true, "UC-VID-005")], [#text(hyphenate: true, "Implementação e integração por fases, resolução de conflitos e correção da quota existente.")], [#text(hyphenate: true, "Testes históricos no capítulo 10 e E2E positivo comunicado pelo utilizador; sem cobertura exaustiva.")], [#text(hyphenate: true, "Commit 58d4414; testes dos quatro componentes.")],

    [#text(hyphenate: true, "OpenAI Codex / skill pdf")], [#text(hyphenate: true, "UC-VID-005")], [#text(hyphenate: true, "Integração documental v3.0 nos capítulos Typst, sem alterar os serviços.")], [#text(hyphenate: true, "Compilação e inspeção visual do PDF; suites funcionais não reexecutadas.")], [#text(hyphenate: true, "VideoSpeed.md; UC-VID-005.typ; capítulos do relatório.")],
  ),
)

#block(breakable: false)[
== Análise crítica

O recurso a agentes de inteligência artificial proporcionou ganhos significativos de produtividade na estruturação inicial de casos de uso e na formalização de critérios de aceitação rigorosos (_Given-When-Then_). Não obstante, a intervenção humana crítica foi indispensável em vários pontos fulcrais:
- *Segurança de reprodução (DA-03):* O modelo propôs inicialmente passar o token JWT via parâmetro de consulta (_query string_) no URL do player de vídeo. A equipa detetou o risco de exposição de credenciais em registos de acesso e histórico do navegador, reformulando a arquitetura para utilizar cookies temporários HttpOnly assinados com validade restrita de 5 minutos.
- *Preservação de fluxos no FFmpeg:* Em cenários com vídeos sem áudio ou com formatos AAC específicos, os comandos sugeridos inicialmente pela IA falhavam ou descartavam canais. A equipa corrigiu as opções de mapeamento explícito (`-map 0:v:0 -map 0:a?`) e parâmetros de cópia direta de fotogramas.
- *Práticas de validação:* Adotou-se o princípio de que nenhuma linha de código ou requisito gerado é integrado sem verificação manual e execução comprovada pela suite de testes `tests/trim_integration.py`.
- *Formato na compilação:* A IA concluiu primeiro que o pedido de compilação não validava o formato e que a garantia vinha apenas do carregamento. A leitura da rota mostrou que o pedido recusa vídeos que não sejam MP4/H.264 (`UNSUPPORTED_VIDEO`, HTTP 415); o REQ-VID-COMP-014 e o caso de uso foram corrigidos.
- *Verificação do armazenamento:* Assumiu-se, por analogia com o diagrama do recorte, que o espaço só era verificado depois da conversão. A rota verifica também no pedido (HTTP 507) e o _worker_ reserva depois o espaço exato; o UC-VID-004 e o ERS foram corrigidos.
- *Atualização da interface:* A IA afirmou que a compilação ficava atrás do recorte por não notificar os outros colaboradores. A leitura do `page.tsx` mostrou que o recorte só atualiza o browser que iniciou a tarefa; a diferença real é que o diálogo da compilação só consulta o estado enquanto está aberto.

- *Quota e âmbito das garantias:* A auditoria de speed levou à integração de reserve/commit/release com bytes reais. A revisão de EX6 restringiu a promessa de limpeza ao ramo efetivamente implementado. Estas correções mostram que geração não equivale a validação.
]

#pagebreak()

