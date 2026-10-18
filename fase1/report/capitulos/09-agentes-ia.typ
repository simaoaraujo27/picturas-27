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
)

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas por agentes de IA e validação],
  tabela(
    colunas: (2.8cm, 2cm, 1fr, 1fr, 2.4cm),
    tamanho: 8pt,
    [Ferramenta / _skill_], [Caso de uso], [Tarefa apoiada], [Validação realizada pela equipa], [Evidência],

    [Antigravity \ (Gemini)],
    [UC-VID-001],
    [Estruturação inicial do caso de uso de recorte (_Trim_), fluxos alternativos e identificação de exceções de vídeo.],
    [Revisão manual exaustiva; ajuste dos limites de duração (180s Free / 60 min Premium) e regras de negócio para compatibilização _brownfield_.],
    [Commit `a778167` \ `trim.md`],

    [Antigravity \ (Gemini)],
    [UC-VID-001],
    [Derivação da ERS (RF e RNF) segundo ISO/IEC 25010 e critérios _Dado… Quando… Então…_.],
    [Verificação da conformidade com os 5 critérios de qualidade de requisitos; garantia de ausência de requisitos órfãos na matriz.],
    [Commit `a778167` \ `05-ers.typ`],

    [Antigravity \ (Gemini)],
    [UC-VID-001],
    [Implementação do nó `videoTrimWorker` (Python/FFmpeg) e integração de fila RabbitMQ.],
    [Inspeção de código; correção de parâmetros FFmpeg para preservação de streams de áudio AAC; testes de execução com `py_compile`.],
    [Commit `52b66f7` \ `videoTrimWorker/`],

    [Antigravity \ (Gemini)],
    [UC-VID-001],
    [Desenvolvimento da suite de testes de integração automatizada em Python (`tests/trim_integration.py`).],
    [Execução completa em ambiente Docker Compose local com validação de invariância de hash SHA-256 e esgotamento de quota Free.],
    [Commit `52b66f7` \ `tests/`],

    [Antigravity \ (Gemini)],
    [UC-VID-001],
    [Conversão e estruturação dos artefactos para a sintaxe Typst do template oficial.],
    [Compilação do documento sem avisos; verificação de formatação e remoção de texto genérico.],
    [Commit `a778167` \ `report/`],
  ),
)

== Análise crítica

O recurso a agentes de inteligência artificial proporcionou ganhos significativos de produtividade na estruturação inicial de casos de uso e na formalização de critérios de aceitação rigorosos (_Given-When-Then_). Não obstante, a intervenção humana crítica foi indispensável em vários pontos fulcrais:
- *Segurança de reprodução (DA-03):* O modelo propôs inicialmente passar o token JWT via parâmetro de consulta (_query string_) no URL do player de vídeo. A equipa detetou o risco de exposição de credenciais em registos de acesso e histórico do navegador, reformulando a arquitetura para utilizar cookies temporários HttpOnly assinados com validade restrita de 5 minutos.
- *Preservação de fluxos no FFmpeg:* Em cenários com vídeos sem áudio ou com formatos AAC específicos, os comandos sugeridos inicialmente pela IA falhavam ou descartavam canais. A equipa corrigiu as opções de mapeamento explícito (`-map 0:v:0 -map 0:a?`) e parâmetros de cópia direta de fotogramas.
- *Práticas de validação:* Adotou-se o princípio de que nenhuma linha de código ou requisito gerado é integrado sem verificação manual e execução comprovada pela suite de testes `tests/trim_integration.py`.
