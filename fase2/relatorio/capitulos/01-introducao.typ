#import "../template.typ": *

= Introdução

== Propósito e âmbito

Este relatório apresenta a melhoria de dois requisitos não funcionais do PictuRAS por _refactoring_, sem introdução de funcionalidade nova: *`CAND-1`: Manutenibilidade — modularidade do processamento de vídeo* e *`CAND-2`: Usabilidade — trabalho em segundo plano*. O *`CAND-1`* segue uma das ideias indicativas da docência: dividir o processamento de vídeo em vários microserviços, à semelhança do que já acontece com as ferramentas de imagem. Na solução de base, efeitos, legendagem automática e extração de fotogramas partilhavam um único serviço, uma única fila e um único `requirements.txt` com dependências de inteligência artificial. O *`CAND-2`* incide no frontend: na versão de base, durante o processamento de um projeto, um ecrã sobreposto escurecido bloqueia a interação na área de conteúdo, exceto pelo botão Cancelar; a barra lateral continua utilizável. O objetivo é permitir que o utilizador continue a usar a aplicação, mantendo o progresso e o cancelamento acessíveis. Se atualizar a página do projeto durante uma execução, o estado e o progresso devem ser recuperados, sem iniciar o processamento novamente.

O trabalho incide sobre a extensão de vídeo, mas é enquadrado no padrão global da solução: o objetivo não é criar um estilo novo, e sim alinhar o caminho do vídeo com a arquitetura de microserviços e filas já usada pelas imagens. A restrição da fase é preservar o comportamento funcional — ordem dos efeitos, áudio, pré-visualizações, resultados e correspondência com os projetos — e demonstrar a melhoria com medições repetíveis antes e depois.

No `CAND-2`, recuperar o acompanhamento após refresh faz parte da operabilidade: o utilizador volta a consultar e controlar uma execução que já existe. A persistência no backend é o mecanismo de suporte, com efeito positivo em recuperabilidade, e não um terceiro candidato a RNF. O âmbito inclui a reabertura da página do projeto; não inclui um indicador global sempre visível em todas as páginas nem pausar e retomar o trabalho do worker. O capítulo 10 distingue a medição visual da interface dos testes manuais de recuperação e dos testes automáticos, com os limites de cada evidência.

== _Baseline_ e repositório

#tab([Artefactos de partida],
  tabela(
    colunas: (5cm, 1fr),
    [Artefacto], [Versão / referência],
    [Documento de requisitos de base], [`doc-ext-requisitos-2627.pdf` (v27.1)],
    [Documento de solução arquitetural de base], [`doc-sol-arquitetural.pdf`, referido nos documentos de partida; cópia e versão não disponíveis no repositório],
    [Repositório de partida], [`git@github.com:simaoaraujo27/picturas-27.git` — `0523102`],
    [Repositório da revisão], [`git@github.com:simaoaraujo27/picturas-27.git` — código integrado `6924815`; revisão documental no branch `docs/cand2-report`. As revisões medidas são identificadas no capítulo 10],
    [Diretrizes da Fase 2], [`fase2/fase-2-guidelines.pdf`, novembro de 2026],
  ),
)

O commit de partida `0523102` é o mesmo em todos os capítulos e em todos os exercícios. Este relatório estende os documentos de base; não os reescreve.

== Exercícios e versões usadas

#tab([Exercícios que alimentam este relatório],
  tabela(
    colunas: (3.6cm, 2.2cm, 2cm, 2cm, 1fr),
    [Exercício], [Capítulos], [Enunciado], [Template], [Versão do documento da equipa],
    [Exercício 6, Bloco 1: padrões arquiteturais], [2, 3 e 4], [Não registada], [Não registada], [v1.0 — diagnóstico da base],
    [Exercício 6, Bloco 2: trade-offs, cenários e candidatos a RNF], [5 e 6], [Não registada], [Não registada], [v1.1 — cenários e candidatos],
    [Exercício 7: táticas arquiteturais], [7 a 10], [Não registada], [Não registada], [v1.2 — táticas, decisões e medição],
  ),
)

As versões dos enunciados e templates dos exercícios não foram registadas nas fontes locais consultadas; não se infere a sua versão a partir da versão dos requisitos de base.

Os identificadores `EV` e `H` (capítulo 2), `ALT` (capítulo 4), `QS` e `CAND` (capítulos 5 e 6), `TAT` (capítulo 7) e `DA` (capítulo 8) são mantidos entre exercícios: são eles que ligam as secções e permitem verificar que a decisão responde ao cenário que a originou.

== Organização do documento

A Parte II (capítulos 2 a 4) estabelece o ambiente, a vista da arquitetura e o diagnóstico dos padrões, com as evidências `EV`/`H` e as alternativas `ALT`. A Parte III (capítulos 5 e 6) caracteriza os cenários de qualidade `QS`, prioriza-os e fixa os candidatos `CAND-1` e `CAND-2` com a respetiva escala de medição. A Parte IV (capítulos 7 a 10) apresenta as táticas `TAT`, a decisão `DA`, as vistas antes/depois e os resultados medidos, incluindo a preservação funcional. A Parte V (capítulos 11 e 12) sintetiza as conclusões e documenta o uso de agentes de IA. Os anexos registam as instruções de execução e o glossário.
