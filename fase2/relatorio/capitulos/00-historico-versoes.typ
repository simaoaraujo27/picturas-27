#import "../template.typ": *

#heading(numbering: none, outlined: false)[Histórico de versões]

#tabela(
  colunas: (1.5cm, 2.3cm, 1fr, 3.5cm),
  [Versão], [Data], [Alterações], [Autores],
  [v1.0], [2026-11-06], [Diagnóstico arquitetural da solução de base: preparação, fontes, vista global, padrões e alternativas (Exercício 6, Bloco 1; capítulos 2 a 4)], [Equipa (CA, FB, LL, NS, SA)],
  [v1.1], [2026-11-13], [Cenários de qualidade, priorização, candidatos a RNF e escalas de medição (Exercício 6, Bloco 2; capítulos 5 e 6)], [Equipa (CA, FB, LL, NS, SA)],
  [v1.2], [2026-11-21], [Táticas, decisões arquiteturais, vistas antes/depois, resultados medidos e preservação funcional (Exercício 7; capítulos 7 a 10)], [Equipa (CA, FB, LL, NS, SA)],
  [v1.3], [2026-11-21], [Consolidação do relatório no template Typst: introdução, conclusões, utilização de IA e anexos; diagramas e compilação final], [Equipa (CA, FB, LL, NS, SA)],
  [v1.4], [2026-11-25], [Revisão documental do CAND-2: recuperação após refresh mantida no QS-02 e na DA-2; alinhamento das táticas, medições, limites da evidência e conclusão, sem alteração funcional], [Revisão assistida por Codex; validação da equipa pendente],
  [v1.5], [2026-11-26], [Integração das evidências publicadas em 25/11, referências Git verificadas, comparação com o template e revisão das tabelas e conclusões; sem novas execuções da aplicação], [Revisão assistida por Codex; validação final da equipa pendente],
  [v2.0 (prevista)], [2026-11-27], [Entrega prevista da Fase 2; referência final a confirmar no repositório], [Equipa (CA, FB, LL, NS, SA)],
)

Marcos de código correspondentes: `0523102` (baseline comum a todos os capítulos), `9976985` (decomposição do processamento de vídeo), `1fe42ba` (correção do encadeamento de pipelines mistos), `85b99d4` (teste de integração do pipeline misto), `75986e6` (cartão não bloqueante) e `e58c640` (recuperação do acompanhamento após refresh). A v1.4 atualiza a descrição do CAND-2, sem executar novo refactoring.

A v1.5 parte do código integrado em `6924815` e das evidências da campanha M2–M4 publicadas em `ca4253a`. Os resultados dessa campanha referem-se a commits fixos, não a uma nova execução desta revisão documental.
