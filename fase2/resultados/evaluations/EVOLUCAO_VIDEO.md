# Evolução do processamento de vídeo

Campanha M2–M4 executada sobre quatro commits fixos em árvores de trabalho isoladas.
As métricas cobrem os módulos Python de produção dos workers de vídeo.
Foi usado o mesmo âmbito, Radon 6.0.1, jscpd 5.4.3 (mínimo de 5 linhas e 50 tokens) e a mesma suite M4.

| Marco | Commit | Relatório |
| --- | --- | --- |
| Baseline oficial | `052310226c51fa57a17101c7bd1ad795674aac95` | [Relatório](reports/evolucao-video-0523102.html) |
| Separação dos workers | `9976985af4990e398bbbc6fdbe5d4ec97e61e11e` | [Relatório](reports/evolucao-video-9976985.html) |
| Correção do encadeamento | `1fe42ba9d1a22535bc121e37125e5b5f713455a2` | [Relatório](reports/evolucao-video-1fe42ba.html) |
| Revisão final | `3df66ae1baa507d07db2c53dcde4d301232e428e` | [Relatório](reports/evolucao-video-3df66ae.html) |

## M2 — Métricas estáticas

| Métrica | 0523102 | 9976985 | 1fe42ba | 3df66ae |
| --- | ---: | ---: | ---: | ---: |
| Complexidade ciclomática média | 4,56 | 3,79 | 3,91 | 4,10 |
| Complexidade ciclomática máxima | 22 | 19 | 19 | 19 |
| Linhas físicas | 807 | 1135 | 1159 | 1219 |
| Linhas de código (SLOC) | 601 | 918 | 942 | 993 |
| Módulos de produção | 5 | 6 | 6 | 6 |
| Linhas no maior módulo | 369 | 316 | 316 | 368 |
| Linhas duplicadas internamente | 0 | 291 | 307 | 319 |
| Duplicação interna | 0,00% | 25,64% | 26,49% | 26,17% |

## M3 — Testes funcionais de cada revisão

Os totais de M3 descrevem as suites existentes no commit em causa.

| Commit | Suite | Aprovados | Falhados | Saltados |
| --- | --- | ---: | ---: | ---: |
| `0523102` | `video-original-pytest` | 74 | 0 | 0 |
| `0523102` | `projects-node-test` | 8 | 0 | 0 |
| `9976985` | `video-effects-pytest` | 29 | 0 | 0 |
| `9976985` | `video-subtitles-pytest` | 9 | 0 | 0 |
| `9976985` | `video-frames-pytest` | 15 | 0 | 0 |
| `9976985` | `projects-node-test` | 19 | 0 | 0 |
| `1fe42ba` | `video-effects-pytest` | 29 | 0 | 0 |
| `1fe42ba` | `video-subtitles-pytest` | 9 | 0 | 0 |
| `1fe42ba` | `video-frames-pytest` | 15 | 0 | 0 |
| `1fe42ba` | `projects-node-test` | 20 | 0 | 0 |
| `3df66ae` | `video-effects-pytest` | 30 | 0 | 0 |
| `3df66ae` | `video-subtitles-pytest` | 9 | 0 | 0 |
| `3df66ae` | `video-frames-pytest` | 15 | 0 | 0 |
| `3df66ae` | `projects-node-test` | 31 | 0 | 0 |

## M4 — Contratos partilhados

Cada célula apresenta os casos aprovados sobre os casos executados, incluindo a verificação complementar do VF-11.

| Contrato | 0523102 | 9976985 | 1fe42ba | 3df66ae |
| --- | ---: | ---: | ---: | ---: |
| VF-01 | 1/1 | 1/1 | 1/1 | 1/1 |
| VF-02 | 1/1 | 1/1 | 1/1 | 1/1 |
| VF-03 | 1/1 | 1/1 | 1/1 | 1/1 |
| VF-04 | 1/1 | 1/1 | 1/1 | 1/1 |
| VF-05 | 1/1 | 1/1 | 1/1 | 1/1 |
| VF-06 | 2/2 | 2/2 | 2/2 | 2/2 |
| VF-07 | 2/2 | **0/2** | **0/2** | **0/2** |
| VF-09 | 2/2 | 2/2 | 2/2 | 2/2 |
| VF-09X | 1/1 | 1/1 | 1/1 | 1/1 |
| VF-08 | 1/1 | 1/1 | 1/1 | 1/1 |
| VF-10 | 1/1 | 1/1 | 1/1 | **0/1** |
| VF-11 | 2/2 | 2/2 | 2/2 | 2/2 |

- **VF-07.** O executor fornece a pipeline completa ao processador escolhido pelo encaminhamento antigo. A aplicação com workers especializados usa etapas encadeadas pelo orquestrador. Os relatórios registam a duração e o brilho observados no ensaio direto.
- **VF-10.** Quando o worker publica progresso em `project_queue`, o teste conta esses eventos juntamente com a resposta final. Os resultados por revisão e as mensagens capturadas estão nos relatórios individuais.

## Comparações HTML

- [`0523102` → `9976985`](reports/evolucao-video-0523102-para-9976985.html)
- [`9976985` → `1fe42ba`](reports/evolucao-video-9976985-para-1fe42ba.html)
- [`1fe42ba` → `3df66ae`](reports/evolucao-video-1fe42ba-para-3df66ae.html)
- [`0523102` → `3df66ae`](reports/evolucao-video-0523102-para-3df66ae.html)

O [índice](INDEX.md) lista a campanha e as execuções M7 do framework.
A evidência arquivada inclui JSON, JUnit e logs. Os ficheiros multimédia gerados ficam na pasta da execução original.
