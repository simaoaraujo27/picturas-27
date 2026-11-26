#import "../template.typ": *

#paisagem[
= Trade-offs, Medição e Preservação Funcional

== Matriz de efeitos

#tab([Matriz de efeitos da decisão],
  tabela(
    colunas: (1.5cm, 3.2cm, 3.7cm, 2.2cm, 3.8cm, 3.8cm, 1fr),
    tamanho: 8.5pt,
    [Decisão], [Desempenho], [Disponibilidade / Fiabilidade], [Segurança], [Manutenibilidade / Testabilidade], [Usabilidade / Operabilidade], [Justificação],
    [DA-1], [Imagem de efeitos menor; soma dos tamanhos maior], [↑ no isolamento], [Sem medição], [↑ separação; ↓ duplicação (EV-14)], [\= efeito direto; progresso entre estágios a preservar], [Imagem de efeitos de 1,70 GB para 1,09 GB e falha confinada a um domínio; o total de imagens sobe para 3,92 GB. O progresso agregado por estágio preserva a continuidade da informação que o worker monolítico emitia],
    [DA-2], [Custo de consultas e escritas por medir], [↑ no acompanhamento recuperável], [Reutiliza autorização; sem medição de segurança], [Mais estado e contratos a verificar], [↑ cartão não bloqueante e acompanhamento recuperado após F5], [Cartão não bloqueante e estado persistido já implementados. Relato manual confirma F5/saída-regresso; consulta de 2 s não é medição de latência. Validar a combinação com os estágios do DA-1.],
  ),
)
]

A soma dos tamanhos das imagens sobe de 1,70 GB para 3,92 GB. É um indicador de custo, não uma medição do espaço físico ocupado: camadas comuns podem ser partilhadas pelo Docker. A equipa aceita imagens separadas para isolar dependências e reconstruções; o tempo de build e o espaço físico adicional continuam por medir. A decisão mantém as fronteiras de autenticação e a configuração de segredos, sem demonstrar uma melhoria de segurança.

== Interação entre DA-1 e DA-2

#tab([Interação entre as decisões],
  tabela(
    colunas: (1.6cm, 1.6cm, 3.4cm, 1fr),
    [Decisão A], [Decisão B], [Efeito], [Razão / evidência],
    [DA-1], [DA-2], [Sinergia condicionada], [O encadeamento separa o trabalho em estágios; o cartão acompanha uma única execução. Token e progresso global têm de chegar ao estado persistido consultado após F5. O relato manual confirma os percursos usados, sem cobrir todos os pipelines.],
    [DA-1], [DA-2], [Risco de integração], [A monotonicidade dos eventos Socket.IO não prova persistência correta por todos os workers. O VF-10 da campanha EV-14 conta eventos de progresso como respostas finais. Exige-se distinguir mensagens no executor e validar o estado recuperado, sem concluir aprovação ou falha ponta a ponta a partir desse contrato isolado.],
  ),
)

== Plano de medição

O capítulo 6 fixa as escalas e distingue as componentes do CAND-2. A comparação do CAND-1 foi realizada nas duas variantes no mesmo host. No CAND-2, a medição visual de 14 de novembro e o relato manual de recuperação de 17 de novembro são evidências distintas: não formam uma campanha temporal de F5 antes/depois. Os comandos automáticos e os seus resultados constam de `docs/REGRESSION_CHECKLIST.md`.

#tab([Plano de medição],
  tabela(
    colunas: (1.6cm, 3.2cm, 3cm, 2.6cm, 2.4cm, 2.8cm),
    tamanho: 8pt,
    [Cenário], [Cenário de teste e carga], [Ambiente (máquina, recursos, versões)], [O que se regista], [Repetições e agregação], [Onde ficam os _scripts_ e os dados],
    [QS-01 — CAND-1], [Mudança de efeito: adicionar/alterar um efeito leve no caminho de efeitos; observação do âmbito da alteração, do tamanho da imagem reconstruída e das dependências carregadas; ensaio de isolamento com falha no worker de legendagem], [Mesmo host por comparação. Campanha de carga: Ryzen 7 5800HS, Docker 29.10.0 / Compose 5.5.1. Campanha M2–M4: ambiente arquivado nos respetivos relatórios; não misturar campanhas], [Serviços e filas envolvidos; ficheiros e importações no worker; tamanho da imagem (GB); Radon MI; domínios parados após falha; sequência de eventos `video-progress`], [Uma medição por variante para tamanhos e estrutura; ensaio de isolamento e de progresso repetidos no stack em execução], [`git worktree`, `git diff --stat`, `docker images`, `radon mi`; `fase2/plano_membro_a_modularidade_video.md`; registos na checklist],
    [QS-02 — CAND-2], [Processar o projeto `test1` (três vídeos) com a legendagem automática; selecionar o elemento de processamento no inspetor e anotar as dimensões visíveis; anotar as dimensões da janela; tentar usar as ações da interface], [Windows, Docker Desktop, Chrome ; janela de 1536 × 695,2 px; ambiente diferente do da campanha do CAND-1], [Dimensões do elemento e da janela; ações que respondem; capturas de ecrã], [Uma medição por variante], [`fase2/documentacao/usabilidade-notas.typ`],
    [QS-02 — recuperação], [Durante uma execução, fazer F5 e sair/regressar à aplicação para verificar o acompanhamento. Para uma repetição instrumentada, registar token, pedidos, controlos e tempo.], [Aplicação usada pelo utilizador; o relato não identifica projeto, ficheiros, perfil ou configuração detalhada], [Sucesso/falha manual; tempos, tokens e novos Apply só quando observados], [Refresh e saída/regresso comunicados com sucesso; número de repetições não registado], [Registo manual de 17/11 em `fase2/documentacao/usabilidade-notas.typ`; endpoint de estado e `projects/utils/processingStatus.js`],
  ),
)

*Instrumentos e critérios.* A métrica principal é o tamanho da imagem a
reconstruir ao alterar um efeito leve. O cenário está descrito em
`fase2/plano_membro_a_modularidade_video.md`. As contagens de serviços, filas e
domínios complementam a leitura da estrutura e do Radon MI. O ensaio de
isolamento conta os domínios que param. O teste de integração de `border`
seguido de `subtitles` usa `tests/fixtures/videos/speech.mp4` (320×240, 6 s,
H.264/AAC). A observação de `video-progress` no socket verifica a
monotonicidade e a emissão de 100 apenas no fim.

*Comparação antes/depois.* A campanha de carga comparou a aplicação `0523102` com `b8f44b3`. A campanha
funcional usou `25f4bd9` como referência, com os testes acrescentados à
aplicação inicial, e executou a versão final a partir de `b8f44b3`, com as
alterações locais registadas na checklist. O executor em `tests/performance/benchmark/` instrumenta a fila e o worker que recebem
`trim` em cada variante. Os ensaios correram sequencialmente no mesmo host (Ryzen 7 5800HS,
Docker 29.10.0, Compose 5.5.1, Node.js 22.22.1), em stacks isoladas, com volumes recriados
e quatro fluxos de aquecimento por repetição.

Foram feitas três repetições por perfil e revisão. Cada fluxo cria uma conta e
um projeto, carrega um MP4, corta de 0 a 2 s, consulta o resultado e descarrega-o.
A carga baixa usa 0,5 fluxos/s durante 6 s, também com vídeo a 720p. A carga
mista usa 2 fluxos/s durante 12 s. O pico tem 6 s a 2 fluxos/s, 6 s a 8 fluxos/s
e 45 ou 75 s de recuperação a 2 fluxos/s. Registaram-se latências, débito,
timeouts, descartes e integridade dos resultados. Os percentis são calculados
por repetição. Esta campanha complementa a medição do QS-01.

#paisagem[
== Resultados das medições

#tab([Resultados das medições do QS-01 (CAND-1)],
  tabela(
    colunas: (1.2cm, 4.5cm, 3.4cm, 3.4cm, 3.1cm, 3.5cm, 1fr),
    tamanho: 8pt,
    [Cenário], [Medição (unidade)], [Antes], [Depois], [Valor-alvo], [Mínimo aceitável], [Atingido?],
    [QS-01], [Serviços e filas de despacho (número)], [1 serviço, 1 fila], [3 serviços, 3 filas], [1 por domínio], [Preservar as capacidades de edição], [Alvo estrutural atingido; preservação tem lacunas],
    [QS-01], [Imagem a reconstruir ao alterar um efeito (GB)], [1,70], [1,09], [Inferior à base], [Critérios comuns do cap. 6], [Alvo: sim, redução de 36 %],
    [QS-01], [Soma dos tamanhos das imagens (GB)], [1,70], [3,92: 1,09 + 1,74 + 1,09], [Efeito colateral a registar], [Não fixado para esta medida de custo], [Soma maior; espaço físico adicional por medir],
    [QS-01], [Faster-Whisper no caminho de efeitos], [Sim], [Não], [Removidas deste domínio], [Manter os efeitos existentes], [Alvo atingido],
    [QS-01], [Domínios no worker de efeitos (número)], [3], [1], [1], [Preservar os três domínios na solução], [Alvo estrutural atingido],
    [QS-01], [Radon MI (classe)], [A em todos os módulos], [A em todos os módulos], [Não degradar], [Não degradar], [Sim; classe não discriminativa],
    [QS-01], [Âmbito da falha de legendagem (qualitativo)], [Worker único para os três domínios], [Falha confinada ao worker de legendas no ensaio relatado], [Confinar ao domínio], [Efeitos e fotogramas disponíveis], [Sucesso relatado no ensaio de isolamento; não generalizar a reinício do broker],
    [QS-01], [Progresso em pipeline misto (%)], [Sem agregação entre workers], [8, 16, 25, 33, 42, 50, 50, 90, 100], [Monotónico; 100 no fim], [Preservar acompanhamento], [Observado no socket; persistência integrada por validar],
    [QS-01], [Ficheiros alterados; build limpo (s)], [Não medidos de forma comparável], [Não medidos de forma comparável], [Mudança confinada; menor custo], [Não fixado numericamente], [Não avaliado],
  ),
)
]

#paisagem[
#tab([Resultados das medições do QS-02 (CAND-2)],
  tabela(
    colunas: (1.2cm, 3.8cm, 3.5cm, 3.5cm, 3.8cm, 3.8cm, 1fr),
    tamanho: 8pt,
    [Cenário], [Medição (unidade)], [Antes], [Depois], [Valor-alvo], [Mínimo aceitável], [Atingido?],
    [QS-02], [Área obstruída (%)], [83,3], [4,6], [Inferior a 10 %], [Inferior a 10 %, critério da equipa], [Sim],
    [QS-02], [Elemento visível (px)], [1280 × 695], [289,6 × 169,6], [Medida auxiliar], [Não fixado separadamente], [Apoia o cálculo da área],
    [QS-02], [Ações utilizáveis na área de conteúdo], [Só Cancelar], [Grelha, editor, ferramentas, Import e Cancelar], [Interface utilizável], [Navegação e acesso ao acompanhamento], [Sim, observação manual],
    [QS-02], [Recuperação após F5], [Estado local perdido (EV-13, análise de código)], [Sucesso manual comunicado em 17/11], [Recuperar a execução existente], [Acompanhamento recuperado, sem novo Apply], [Sucesso relatado; pedidos e token não registados],
    [QS-02], [Saída e regresso ao projeto], [Dependente da página aberta], [Sucesso manual comunicado em 17/11], [Recuperar ao reabrir], [Acompanhamento acessível no projeto], [Sucesso relatado; não demonstra logout/login ou cartão global],
    [QS-02], [Acesso ao cancelamento após F5], [Controlo dependente do estado local], [Reconstruído por canCancel e versão/token], [Controlar a execução autorizada], [Cancelar só a execução ativa autorizada], [Implementado e testado isoladamente; ação após F5 não detalhada no relato manual],
    [QS-02], [Tempo de recuperação (s)], [Não medido], [Não medido], [Não definido numericamente], [Não definido numericamente], [Não avaliado; 2 s é intervalo de consulta],
  ),
)
]

*Análise dos resultados.* Na métrica principal do QS-01, a imagem associada ao caminho de efeitos
passou de 1,70 GB para 1,09 GB. O ficheiro de dependências dos efeitos deixou de incluir
Faster-Whisper. A estrutura passou a ter uma fila e um contentor por
domínio, alinhada com o padrão global das ferramentas de imagem (EV-04). O ensaio de isolamento
confirmou a hipótese H-01 na base e a sua mitigação na variante final: uma falha de legendagem já
não impede os domínios de efeitos e de fotogramas. O progresso agregado manteve-se contínuo entre
estágios e com o valor final apenas no fim.

A medição arquitetural registou a soma de 3,92 GB para as três imagens.
A imagem do worker de efeitos mede 1,09 GB. Estes valores pertencem à medição do
QS-01. A reconstrução da referência para a última campanha de carga registou 1,66 GB
para o monólito. O Radon MI deu classe A nas duas variantes. O tempo de build limpo
e o âmbito de uma alteração controlada a um efeito ficam por medir.


*Campanha adicional publicada em 25/11 (EV-14).* A comparação usa os commits fixos `0523102` e `3df66ae`, com os marcos intermédios `9976985` e `1fe42ba`. Não substitui a campanha de regressão de `b8f44b3` nem os testes manuais do CAND-2.

#tab([Evidência adicional M2–M4, por campanha],
  tabela(
    colunas: (4.4cm, 2.1cm, 2.1cm, 1fr),
    tamanho: 8.5pt,
    [Métrica / suite], [0523102], [3df66ae], [Interpretação],
    [Complexidade ciclomática média], [4,56], [4,10], [Menor média no mesmo âmbito Python],
    [Complexidade ciclomática máxima], [22], [19], [Menor máximo; não prova isoladamente menor esforço],
    [Duplicação interna (jscpd)], [0,00 %], [26,17 %], [Custo da separação: 319 linhas duplicadas na revisão final],
    [M3: suites próprias da revisão], [82 aprovados], [85 aprovados], [Casos e totais diferentes; não é comparação emparelhada],
    [M4: contratos partilhados], [16 aprovados, 0 falhados], [13 aprovados, 3 falhados], [VF-07 ×2 e VF-10 ×1; analisar os limites do executor],
  ),
)

No VF-07, o executor entrega a pipeline completa ao processador escolhido pelo encaminhamento antigo, enquanto a aplicação especializada encadeia estágios no orquestrador. No VF-10, eventos de progresso em `project_queue` são contados como respostas finais. Os resultados continuam registados como falhas; estas limitações impedem classificá-los automaticamente como regressão da aplicação ou como preservação aprovada. JSON, JUnit, logs e HTML estão referenciados em `fase2/resultados/evaluations/EVOLUCAO_VIDEO.md`. Os mínimos funcionais do CAND-1 ainda não estão integralmente demonstrados.

*Análise do QS-02.* O elemento passou de 83,3 % para 4,6 % da janela na medição visual de 14 de novembro. As capturas mostram acesso à grelha, ao editor e ao diálogo Import durante o processamento; não demonstram que uma alteração de pipeline deva ser aceite numa execução ativa. A recuperação após refresh também está implementada e pertence ao CAND-2: a API lê `processingState` e a página reconstrói o acompanhamento em vez de reenviar Apply.

*Validação manual da recuperação.* Nuno Sá comunicou em 17 de novembro que fez refresh, saiu e voltou à aplicação e que os testes tiveram sucesso. Regista-se como «Passa — manual comunicado», com proveniência em `fase2/documentacao/usabilidade-notas.typ`, sem repetição pelo assistente nesta revisão. Não existem capturas ou vídeo desse percurso, tempos cronometrados, contagem de repetições ou inspeção dos tokens/pedidos. O relato não permite calcular uma taxa de sucesso nem afirmar que houve ensaio de logout/login, perda de rede ou cancelamento efetivo após F5. A ausência de gravação é um limite da evidência, não ausência da implementação.

*Evidência automática e integração.* Os 14 testes Node e 2 Python de 16 de novembro pertencem à implementação anterior à decomposição dos workers. Na campanha posterior, a checklist regista aprovação de `UI-04.1` na execução mais recente (`R-20261125-154940-evaluation-regression`, M3), falha de preparação dos casos Python que procuram o worker antigo e bloqueio da descoberta do Playwright por importação. Estes resultados são mantidos como tal: não apagam o sucesso manual nem provam a recuperação em todos os pipelines de vários estágios. Os eventos Socket.IO com `base`/`span` do DA-1 não são, por si só, evidência de persistência recuperável em todos os workers.

=== Regressão de desempenho

#block(breakable: false)[
#tab([Desempenho local — API e processamento de imagem],
  tabela(
    colunas: (1fr, 2.4cm, 2.4cm, 2.4cm),
    [Medição], [Referência], [Final], [Limite],
    [Leitura de projeto, p95], [35,42 ms], [22,40 ms], [2 000 ms],
    [Redimensionamento até ao resultado], [258,84 ms], [247,69 ms], [30 000 ms],
  ),
)
]

O teste local ficou dentro dos dois limites nas duas revisões, com uma execução por revisão.

#block(breakable: false)[
#tab([Carga de vídeo — intervalo observado nas três repetições],
  tabela(
    colunas: (1fr, 3.2cm, 3.2cm),
    [Tempo até ao resultado], [Referência], [Final],
    [Carga baixa, p50], [449–453 ms], [452–461 ms],
    [Carga mista, p95], [670–674 ms], [460–678 ms],
    [Pico, recuperação de 45 s (p95)], [15,64–17,27 s], [8,64–9,30 s],
    [Pico, recuperação de 75 s (p95)], [13,42–13,68 s], [9,56–10,26 s],
    [Carga baixa a 720p, p50], [1,108–1,118 s], [0,688–0,709 s],
  ),
)
]

Na carga mista, as duas revisões concluíram 72 fluxos e mantiveram 115 cortes/min na janela.
No pico de 45 s, os fluxos concluídos passaram de 381 para 423 e os descartes antes do início
de 69 para 27. No pico de 75 s, os fluxos concluídos passaram de 576 para 597 e os descartes
de 54 para 33. Em ambas as variantes de pico houve zero timeouts e a auditoria confirmou um
resultado íntegro por pedido aceite. A comparação mede revisões completas. A reconstrução das
imagens e a variação da carga do host limitam a atribuição dos ganhos a uma só alteração.
Os valores por repetição constam de `resultados-desempenho-inicial.md` e `resultados-regressao-atual.md`.

== Preservação funcional

*Primeira execução.* Passaram nas duas versões 155 dos 158 casos emparelhados por nome no JUnit. A versão final registou 174 aprovações em 179 casos. Os resultados originais permanecem visíveis, incluindo as falhas de preparação Python e os casos repetidos posteriormente.

#block(breakable: false)[
#tab([Primeira execução — casos aprovados / executados],
  tabela(
    colunas: (1fr, 2.5cm, 2.5cm, 2.8cm),
    [Suite], [Referência], [Final], [Casos comuns],
    [Unitários Node / Python], [101/101], [94/96], [76/76],
    [API], [36/36], [36/36], [36/36],
    [Integração], [30/30], [30/31], [29/30],
    [Browser (Playwright)], [11/11], [9/11], [9/11],
    [Segurança, restauro e orçamento local], [5/5], [5/5], [5/5],
    [*Total*], [*183/183*], [*174/179*], [*155/158*],
  ),
)
]

*Síntese posterior por seleção e repetição.* A tabela seguinte apresenta o conjunto da síntese posterior registada em `20550d1`: exclui o caso de integração que falhou na primeira passagem e os dois testes Python que falharam na preparação. A linha Playwright reúne os nove casos aprovados inicialmente e os dois aprovados na repetição isolada de 26/11. Os 157 casos comuns deste conjunto não são o mesmo denominador dos 158 casos da primeira tabela. Não se trata de uma nova execução integral de 176 testes sem falhas.

#block(breakable: false)[
#tab([Conjunto selecionado — inclui repetições isoladas],
  tabela(
    colunas: (1fr, 2.5cm, 2.5cm, 2.8cm),
    [Suite], [Referência], [Final], [Casos comuns],
    [Unitários Node / Python], [101/101], [94/94], [76/76],
    [API], [36/36], [36/36], [36/36],
    [Integração], [30/30], [30/30], [29/29],
    [Browser (Playwright)], [11/11], [11/11], [11/11],
    [Segurança, restauro e orçamento local], [5/5], [5/5], [5/5],
    [*Total*], [*183/183*], [*176/176*], [*157/157*],
  ),
)
]

Os testes Node cobrem a validação de vídeo, o encaminhamento de estágios e o
registo e publicação de lotes. Os testes Python cobrem filtros de imagem e
vídeo, legendagem e extração de fotogramas. A API cobre contas, quotas,
projetos, partilha, carregamentos e pedidos de processamento. No browser,
Playwright cobre autenticação, projetos, acessibilidade, edição de imagem e
controlos de vídeo. A edição e descarga de vídeo ponta a ponta são verificadas
ao nível da integração com a API e os workers.

Na primeira execução final, o Playwright registou 9/11. A edição e descarga de
imagem excedeu o prazo e o teste da partilha de leitura não encontrou o botão
«Apply». Na repetição isolada de 26 de novembro (`R-20261126-143643-e2e-recheck`),
os dois casos passaram em 3,0 s e 1,2 s, respetivamente. Na integração, o caso de
remoção de fundo passou numa repetição isolada após exceder o prazo.

A descoberta do Playwright completo ficou bloqueada por uma importação no ficheiro de recuperação.
A tabela usa a execução separada dos cinco ficheiros existentes na referência. Os 13 casos de
falha conhecida voltaram a falhar nas duas versões e são contabilizados à parte.
Os registos constam de `resultados-regressao-atual.md` e `docs/REGRESSION_CHECKLIST.md`.

#block(breakable: false)[
#tab([Preservação funcional e testes de regressão],
  tabela(
    colunas: (2.4cm, 3.8cm, 2.8cm, 3.2cm, 1fr),
    tamanho: 8.5pt,
    [Zona alterada], [Testes de regressão existentes], [Lacunas de teste], [Testes acrescentados], [Resultado (imagem e vídeo)],
    [Despacho e encadeamento de etapas de vídeo em `projects/` e workers especializados — DA-1], [`video-pipeline.test.js`, `process-batch.test.js` e integração de processamento, incluindo projetos mistos e extração após edição], [Isolamento entre filas com indisponibilidade de um worker; fluxo completo de vídeo no navegador], [Caso de encaminhamento para os três workers; caso de integração de pipeline misto `border` + `subtitles`; verificação do progresso agregado], [30/31 na primeira passagem; 30/30 no conjunto selecionado que exclui esse caso. O pipeline misto passou; a remoção de fundo passou numa repetição isolada.],
    [Acompanhamento e recuperação — DA-2], [`projects/tests/processing-recovery.test.js` e `process-batch.test.js`; `UI-04.1`], [F5 instrumentado, cancelamento efetivo após F5, falhas de rede e integração da persistência em pipelines de vários estágios], [Consulta de estado, progresso idempotente, estados terminais, permissões e cancelamento por token; ficheiros de recuperação Python e Playwright], [Node aprovado no registo citado; F5/saída-regresso com sucesso manual. Python não chegou às asserções na campanha integrada e a descoberta Playwright ficou bloqueada. Não há prova de toda a edição de vídeo pelo browser.],
  ),
)
]

A evidência demonstra a melhoria estrutural do CAND-1 e a aprovação dos 157 casos
comparáveis incluídos na tabela. O critério funcional estrito do capítulo 6 fica por demonstrar na
totalidade. Os eventos de progresso da tabela seguinte foram observados no socket.
A recuperação após F5 é um percurso distinto, com validação automática pendente.

#block(breakable: false)[
A tabela regista riscos da separação de filas e do encadeamento de etapas
do DA-1, com a cobertura existente para cada mitigação.

#tab([Riscos para a preservação funcional e mitigação],
  tabela(
    colunas: (3.4cm, 3.2cm, 4cm, 3.2cm),
    tamanho: 8.5pt,
    [Risco], [Funcionalidade afetada (imagem / vídeo)], [Mitigação], [Teste de regressão],
    [Encaminhar um pedido para a fila errada ou perder a ordem das etapas ao encadear workers], [Vídeo com efeitos, legendas ou extração de fotogramas após edição], [Encaminhar por tipo de etapa (`videoStages()`) e avançar após a resposta da etapa anterior, usando o resultado intermédio como entrada], [`video-pipeline.test.js` verifica o encaminhamento; `processing.test.js` verifica o pipeline misto, os fotogramas da linha temporal editada e a exportação ZIP],
    [Publicar um resultado incompleto se uma etapa terminar antes do registo integral do lote ou se uma etapa falhar], [Aplicação em lote em projetos de vídeo ou mistos e preservação do resultado anterior], [Registar todos os processos antes do primeiro despacho e condicionar a publicação do lote à conclusão das etapas], [`process-batch.test.js` verifica o registo e a publicação; `RUN-02` verifica a preservação do resultado anterior em caso de falha],
    [Perder o progresso entre estágios de workers diferentes], [Feedback de progresso no browser], [Propagar `base`/`span` por estágio e agregar no orquestrador], [Eventos `video-progress` observados: 8, 16, 25, 33, 42, 50, 50, 90, 100],
  ),
)
]

*Riscos específicos do DA-2.* Reconstruir o estado errado ou cancelar uma execução posterior é mitigado pela identidade da execução, permissões e escrita condicional; os testes isolados cobrem esses casos. A indisponibilidade da consulta não deve ser interpretada como conclusão: conserva-se o último estado conhecido e mostra-se erro de ligação. Novos Apply e escritas incompatíveis na pipeline são bloqueados durante uma execução. A validação destes percursos na revisão integrada, incluindo a interação com o DA-1, continua a ser uma lacuna de teste, não uma funcionalidade a implementar nesta revisão documental.
