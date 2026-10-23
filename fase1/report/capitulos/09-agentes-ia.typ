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

  [OpenCode \ (GLM)],
  [Agente de IA (CLI) usado na elicitação das decisões de desenho, na derivação e na consolidação da ERS da remoção de segmento (UC-VID-003) e na respetiva integração documental no relatório, conforme o dossiê; sessões locais, sem ficheiros de configuração no repositório.],
)

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas por agentes de IA e validação],
  tabela(
    colunas: (2.8cm, 2cm, 1fr, 1fr, 2.4cm),
    tamanho: 8pt,
    [Ferramenta / _skill_], [Caso de uso], [Tarefa apoiada], [Validação realizada pela equipa], [Evidência],

    [ChatGPT], [UC-VID-001],
    [Análise do caso de uso e dos requisitos, identificação de inconsistências, preparação de instruções para o Codex e revisão de capítulos, rastreabilidade, arquitetura, diagramas e resultados.],
    [Atividades confirmadas pelo estudante; sem transcrições ou resultados específicos, não se atribuem ficheiros ou decisões concretas ao ChatGPT.],
    [Confirmação do estudante; histórico não exportado.],

    [OpenAI Codex], [UC-VID-001],
    [Revisão da UC/ERS e dos IDs NOVO/ALT; implementação do Upload e do streaming no Gateway, `projects` e `mediaStorageService`; preparação dos testes de upload e tamanho.],
    [Dossiê, ERS e código comparados com o âmbito definido pelo estudante. TST-UPL-03/04 passaram; 06/07 cobriram apenas pré-validação; 08 foi bloqueado por HTTP 502 no SeaweedFS; 13 e medição do pico de memória permanecem pendentes. Os scripts não foram reexecutados nesta revisão.],
    [`upload.md`; capítulos 4, 5 e 7; rotas de vídeo; `tests/video_upload_smoke_test.py` e `tests/video_upload_size_test.py`; conversa registada.],

    [Antigravity (Gemini)], [UC-VID-002],
    [Estruturação do Trim e dos seus fluxos; derivação da ERS e rastreabilidade; implementação do `videoTrimWorker` e da fila RabbitMQ; criação de `tests/trim_integration.py`; conversão dos artefactos para Typst.],
    [Revisão dos limites Free/Premium e requisitos; inspeção e correção dos parâmetros FFmpeg; `py_compile`, testes de integração em Docker Compose com hash SHA-256 e quota Free, e compilação do relatório.],
    [Commits `a778167` e `52b66f7`; `trim.md`, `videoTrimWorker/`, `tests/` e `report/`.],

    [OpenCode (GLM)], [UC-VID-003],
    [Elicitação do desenho e primeiras secções do dossiê; derivação dos requisitos, impacto e rastreabilidade; consolidação da ERS e harmonização de quota, precisão temporal e AAC; integração nos capítulos do relatório.],
    [Revisão manual das decisões, atomicidade e condições de medição; harmonização confirmada com o autor do dossiê; documento compilado e revisto pelo autor.],
    [`UC3-RemocaoSegmento.md`; `UC-VID-003.typ`; capítulos 5 a 8 e 10.],

    [Antigravity (Gemini)], [UC-VID-003],
    [Deteção e resolução de contradições, harmonização da rastreabilidade REQ-VID-REM-011 a 013 e correção do ciclo de _staging_.],
    [Revisão e validação manual pela equipa.],
    [`UC3-RemocaoSegmento.md`],

    [ChatGPT], [UC-VID-004],
    [Apoio à revisão da ERS da compilação, dos critérios de aceitação e da rastreabilidade.],
    [O dossiê foi comparado com o código e o comportamento da aplicação e corrigido quanto a limites, formato MP4/H.264, armazenamento, quota e ordem dos passos; sem transcrições, não se atribuem decisões concretas ao ChatGPT.],
    [`compile.md`; `UC-VID-004.typ`; capítulos 5 e 7.],

    [Claude (Anthropic)], [UC-VID-004],
    [Implementação do diálogo, rotas, fila, _worker_ FFmpeg, integração Docker e testes; alinhamento do relatório com o código e criação dos diagramas PlantUML da compilação.],
    [Sete testes automáticos do _worker_ com FFmpeg e serviços simulados; verificação manual na aplicação e TST-COMP-08 a 11. O texto foi comparado com rotas, modelos, _worker_, diálogo e Compose, e os erros encontrados foram corrigidos.],
    [Commits `3762b2d`, `d388b72` e `3fd696b`; `videoCompileWorker/`, `projects/routes/trim.js`, diálogo de compilação, `test_worker.py`, capítulos 4 a 8 e 10, `images/*.puml`.],

    [ChatGPT], [UC-VID-005],
    [Refinamento do UC/ERS, comparação com os dossiês e instruções de implementação por fases.],
    [Revisões discutidas com o autor; sem comprovação de ensaio manual de todos os cenários.],
    [`VideoSpeed.md`; conversa de trabalho não exportada.],

    [OpenAI Codex / skill pdf], [UC-VID-005],
    [Implementação e integração por fases, resolução de conflitos e correção da quota; integração documental v3.0 nos capítulos Typst com consulta à _skill_ `pdf`.],
    [Testes históricos no capítulo 10 e E2E positivo comunicado pelo utilizador; compilação e inspeção visual do PDF. As suites funcionais não foram reexecutadas nesta revisão e a cobertura não é exaustiva.],
    [Commit `58d4414`; testes dos quatro componentes; `VideoSpeed.md`, `UC-VID-005.typ` e capítulos do relatório.],
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
- *Harmonização entre dossiês (remoção de segmento):* A IA propôs inicialmente exigir AAC incondicional na saída da remoção, o que contradizia vídeos sem faixa de áudio aceites no carregamento; a revisão conjunta com os dossiês do Upload e do Trim levou ao AAC condicional (REQ-VID-UNI-001), à precisão de centésimos (REQ-VID-REM-002) e à extensão do modelo transacional de quotas (RN6 do UC-VID-003). A reclassificação das validações comportamentais (REQ-VID-REM-010 a 012) de não funcionais para funcionais foi confirmada manualmente contra os dossiês vizinhos.
]

#pagebreak()

