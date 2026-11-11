#set document(title: "Manutenibilidade — métricas e avaliação")
#set page(paper: "a4", margin: 2cm)
#set text(size: 11pt, lang: "pt")
#set heading(numbering: "1.")

= Manutenibilidade — métricas e avaliação

Documento de trabalho iniciado em 6 de novembro de 2026.

*Responsabilidade:* métricas, baseline, benchmarking e não-regressão.

*Objetivo:* demonstrar, com medições reproduzíveis, que o refactoring melhora a modularidade sem alterar o comportamento funcional.

*Estado:* baseline de código e testes do worker recolhida; benchmarking e integração entre serviços ainda pendentes. As tarefas estão organizadas no projeto Todoist "PictuRAS — Manutenibilidade e avaliação".

== Definir o que vai ser avaliado

*Âmbito acordado em 11 de novembro de 2026:* código de processamento de vídeo em `Tools/video/`. As dependências diretas com o orquestrador serão consideradas quando necessárias para avaliar o acoplamento ou um cenário de manutenção; não alargar a medição ao resto do sistema sem nova decisão.

*Dimensões escolhidas:* complexidade, duplicação, acoplamento, tamanho dos módulos e facilidade de alterar uma funcionalidade. Para a última, registar por cenário os módulos e serviços existentes que precisam de alteração e as dependências necessárias para testar o componente. As definições operacionais, instrumentos e critérios de comparação ainda têm de ser fixados antes da medição.

*Referência inicial:* branch `baseline`, atualmente no commit `ab3ae9cf8efcfa444e9599f8e291551c5930c289`. Usar o hash do commit nas medições para evitar ambiguidade se a branch avançar.

*Metas externas:* não foram indicados valores-alvo pelo docente nem pela equipa. Os critérios de sucesso serão definidos após a baseline, sem apresentar limiares arbitrários como exigências da norma.

*Não-regressão funcional:* todos os comportamentos existentes do processamento de vídeo devem manter-se iguais. O refactoring visa apenas melhorar requisitos não funcionais. A verificação deve abranger os fluxos e casos de erro já suportados, incluindo efeitos, áudio, pré-visualização, legendas e extração de fotogramas; estes exemplos não limitam o âmbito da preservação funcional.

*Classificação:* Manutenibilidade → Modularidade, segundo a ISO/IEC 25010:2011 indicada no enunciado. Complexidade, duplicação, acoplamento, tamanho e facilidade de alteração são indicadores operacionais escolhidos pela equipa, não métricas prescritas pela norma.

*Unidades de análise:* cada ficheiro Python de produção em `Tools/video/` é um módulo de código; `video_tool` é o serviço executável. Contar módulos e serviços separadamente. `projects` e outros serviços só entram na contagem de dependências ou nos cenários que os afetem; não entram nos agregados internos de `Tools/video/`.

*Fragilidades observáveis na baseline:* `video_processor.py` tem 369 linhas e concentra validação, ffprobe, processamento, codificação e gestão de erros; `video.py` tem 180 linhas e agrega a integração com RabbitMQ. `effects.py` replica operações PIL das ferramentas de imagem. Há acoplamento explícito ao ffmpeg/ffprobe e integração do worker com RabbitMQ e o volume partilhado. Estes são candidatos a melhoria, não prova de que uma mudança futura será mais fácil.

*Fichas de métricas:* em todas, guardar comando, versão, lista de ficheiros, resultado bruto, commit e data. A baseline e o valor final usam o mesmo procedimento.

*Métricas principais de modularidade:* (1) número de módulos de produção existentes alterados por cenário, (2) número de serviços executáveis existentes afetados por cenário e (3) número de dependências externas necessárias para testar cada componente isoladamente. Contar separadamente componentes novos, configuração e testes. Estas três métricas avaliam diretamente a facilidade de alteração e o acoplamento; os valores exigem a execução de cenários e o inventário de dependências.

*Métricas complementares:* complexidade ciclomática, duplicação e duração da suíte de testes. O tamanho dos módulos é também registado como indicador descritivo. A duração dos testes mede custo de validação, não modularidade por si só.

- Complexidade: complexidade ciclomática por função, com média, máximo e distribuição por classes; unidade: pontos por função; instrumento previsto: Radon `cc` em `Tools/video/*.py`. Alvo e mínimo aceitável: definir depois da medição inicial e antes do refactoring.
- Duplicação: blocos e percentagem de linhas duplicadas em `Tools/video/`, com uma medição adicional entre `Tools/video/effects.py` e as ferramentas PIL; instrumento previsto: jscpd com limiar, tokens e exclusões fixados. Alvo e mínimo: por definir após baseline.
- Acoplamento: dependências diretas entre os módulos de produção, imports externos e serviços necessários para testar cada componente; unidade: arestas e serviços por componente; instrumento: inventário de imports, chamadas de subprocesso e configuração Compose, revisto manualmente. Alvo e mínimo: por definir após baseline.
- Tamanho: linhas físicas e linhas de código por módulo, totais e máximo; instrumento: `wc -l` e Radon `raw`, com ficheiros gerados e testes excluídos da métrica de produção. Alvo e mínimo: por definir após baseline.
- Facilidade de alteração: por cenário com critérios de aceitação idênticos, contar módulos de produção existentes, serviços existentes e dependências de teste afetados; distinguir componentes novos e testes. Instrumento: `git diff --name-only` mais revisão manual. Alvo e mínimo: por definir após execução dos cenários na baseline.

*Campos de comparação das fichas:* para complexidade, baseline média 4,56 e máximo 22; para tamanho, baseline 807 LOC e 601 SLOC; para duplicação exata interna, baseline 0% com os limiares padrão de jscpd; para duração dos testes, baseline 31,44 s nesta máquina e ambiente. Para módulos/serviços alterados por cenário e dependências de teste, baseline por recolher durante o benchmarking. Os alvos e mínimos aceitáveis de todas as fichas estão *por aprovar após a baseline relevante e antes do refactoring*; a ausência de uma meta não significa que a meta seja zero ou igualdade com a baseline. Os resultados medidos são descritos abaixo e os ficheiros brutos são a fonte de evidência.


A norma fornece a classificação de qualidade. As métricas escolhidas são a operacionalização da equipa e devem ser justificadas, sem serem apresentadas como métricas impostas pela norma.

== Preparar e recolher a baseline

*Referência verificada em 11 de novembro de 2026:* `HEAD` e `baseline` apontam ambos para `ab3ae9cf8efcfa444e9599f8e291551c5930c289`. `git status --short` mostra apenas `?? fase2/documentacao/manutenibilidade-notas.typ`, este documento de trabalho ainda não rastreado. Nenhuma alteração rastreada foi observada.

*Ambiente inicial:* Linux 6.18.60-2-cachyos-lts x86_64; Python 3.14.9; ffmpeg n9.0.2. Completar o inventário de hardware, Docker e dependências antes de recolher métricas.

*Inventário parcial em 11 de novembro de 2026:* Intel Core i5-13500H, 16 CPUs lógicas, 15 GiB RAM, Node v26.13.0. `docker compose config --services` inclui `video_tool`, `projects`, `rabbitmq` e `img_storage`. Docker está instalado; versão e configuração completa ainda por guardar. No Python do host, `pytest` e `radon` não estão instalados; `jscpd` não está no PATH. As ferramentas e dependências devem ser fixadas antes de executar medições reproduzíveis.

*Complemento do inventário:* Docker 29.9.3, Compose 5.7.0, ffprobe n9.0.2. Dependências Python instaladas no ambiente temporário: `fase2/resultados/baseline/video-baseline-python-packages.txt`. A configuração do serviço `video_tool` está em `docker-compose.yaml`: build `Tools/video/Dockerfile`, RabbitMQ saudável como dependência, volume `image_data`, volume `whisper_models`, `VIDEO_PREVIEW_SECONDS=3`, `WHISPER_MODEL=small`, `WHISPER_CPU_THREADS=2`. A configuração Compose integral foi verificada localmente, mas não foi copiada para os artefactos por poder conter segredos.

*Tamanho preliminar, não medição formal:* `wc -l Tools/video/*.py` deu `effects.py` 79, `frame_extraction.py` 97, `subtitles.py` 82, `video.py` 180 e `video_processor.py` 369 linhas físicas; `__init__.py` 0. Total: 807 linhas. Esta contagem deve ser repetida pelo script formal com o commit e as exclusões fixadas.

*Recolha estática reproduzível:* executar `python3 fase2/scripts/collect_video_baseline.py > fase2/resultados/baseline/video-baseline-static.json` a partir da raiz. O script usa apenas a biblioteca padrão, inventaria os ficheiros Python de produção, linhas físicas, funções, classes e imports, e guarda o hash do commit. Exclui explicitamente `tests/`, ambientes virtuais, dependências e ficheiros gerados. Resultado inicial: `fase2/resultados/baseline/video-baseline-static.json`. Este inventário não substitui Radon ou jscpd.

*Dados de vídeo e pipelines fixados:* `fase2/documentacao/video-cases.json` define entradas, SHA-256, ordem e parâmetros dos efeitos, modo preview e resultado esperado. Inclui efeitos em sequência, trim com speed e áudio, extração de fotogramas em preview, legendas com fala real e ficheiro inválido. O caso de fala real exige Faster-Whisper e é separado da recolha leve. Não foi selecionada imagem porque o âmbito acordado é `Tools/video/`. O manifesto fixa os cenários; a execução comparativa dos cinco casos permanece para o benchmarking.

*Recolha automatizada completa:* `python3 fase2/scripts/collect_video_metrics.py DIRETORIO --python CAMINHO_PYTHON --jscpd CAMINHO_JSCPD`. O script verifica os hashes do manifesto, seleciona apenas `Tools/video/*.py`, exclui testes, ambientes virtuais, caches, dependências e ficheiros gerados, e grava inventário estático, Radon, jscpd e metadados dos comandos. A etapa pytest chama agora `fase2/scripts/test_video_docker.py`, que usa um container temporário da imagem `video_tool`. O diretório de saída pode ser diferente para baseline e versão final; não reutilizar a mesma pasta para evitar sobrescrita. Os resultados históricos em `fase2/resultados/baseline/` permanecem preservados.

*Medições recolhidas em 11 de novembro de 2026:* Radon 6.0.1, `radon cc Tools/video/*.py -j` → `fase2/resultados/baseline/video-baseline-radon-cc.json`: 41 funções/métodos, complexidade média 4,56, máximo 22. `radon raw Tools/video/*.py -j` → `fase2/resultados/baseline/video-baseline-radon-raw.json`: 807 linhas físicas, 601 linhas de código. jscpd 5.4.3, `jscpd Tools/video --pattern '**/*.py' --ignore '**/tests/**' --reporters json --output fase2/resultados/baseline --silent` → `fase2/resultados/baseline/jscpd-report.json`: 0 clones exatos nos 5 ficheiros de produção analisados. O resultado depende dos limiares padrão da ferramenta e não mede semelhança semântica com ferramentas de imagem.

*Testes da baseline:* `python -m pytest -q Tools/video/tests`, no ambiente temporário com Python 3.14.9, pytest 9.2.0 e Pillow 13.0.0: 74 passaram, 1 aviso de depreciação, 31,44 s. Saída em `fase2/resultados/baseline/video-baseline-pytest.txt`. Os testes geram vídeos de teste com ffmpeg; não dependem dos vídeos de `samples/video/`.

*Limites:* os testes Docker executam funções do worker num container temporário; não exercitam o consumidor RabbitMQ, o volume partilhado nem o fluxo via `projects`. Os cenários de vídeo estão fixados, mas ainda não foram executados como comparação antes/depois; os alvos de melhoria ainda não foram fixados.

*Verificação Docker posterior:* após disponibilização do daemon, executar `python3 fase2/scripts/test_video_docker.py fase2/resultados/baseline/video-baseline-docker-pytest.txt --build` a partir da raiz. O script reconstrói a imagem, cria um container descartável com `Tools/video/tests` montado em leitura, instala pytest 9.2.0 apenas nesse container e guarda o log. Resultado final em 11 de novembro de 2026: Python 3.11.16, ffmpeg 7.1.5, 74 testes passaram em 39,58 s. A imagem e as dependências são as do Dockerfile. O container de produção não foi alterado nem reiniciado.

*Dependências por nível de teste:* funções PIL em `effects.py`: Python e Pillow, sem serviço externo. `video_processor.py` e `frame_extraction.py`: Python, Pillow, ffmpeg e ffprobe; os testes existentes geram media localmente e não exigem Docker. `subtitles.py`: para testes com modelo simulado, Python, Pillow, ffmpeg/ffprobe; para transcrição real, Faster-Whisper e modelo persistido em `whisper_models`. `video.py` como consumidor integrado: RabbitMQ e volume `image_data`; fluxos de progresso e resultado também exigem o orquestrador `projects`. O serviço `video_tool` depende de RabbitMQ saudável no Compose. Estas dependências serão contadas por componente na comparação final.


== Preparar o benchmarking de manutenção

*Procedimento executado antes do refactoring:* `fase2/scripts/benchmark_maintenance.py` obtém quatro ficheiros diretamente do commit `ab3ae9c` através de `git show`, cria duas cópias temporárias por cenário, aplica uma alteração pequena à cópia de trabalho, verifica o critério de aceitação e usa `git diff --no-index` para contar módulos modificados. Não cria commits nem altera o código da aplicação. Resultado bruto: `fase2/resultados/baseline/maintenance-scenarios.json`. A execução usa Python com Pillow instalado; para repetir: `CAMINHO_DO_PYTHON fase2/scripts/benchmark_maintenance.py > fase2/resultados/baseline/maintenance-scenarios.json`.

- Cenário 1, legendas: mudar `FontSize=20` para `FontSize=22` no estilo aplicado pelo ffmpeg. Aceitação: o filtro de legendas usa `FontSize=22` e os testes de renderização continuam a passar. Baseline da alteração: 1 módulo existente (`subtitles.py`), 1 serviço (`video_tool`).
- Cenário 2, extração: reduzir o limite de `count` de 100 para 80. Aceitação: `count=80` é aceite, `count=81` é rejeitado no worker e no orquestrador; mensagens coerentes. Baseline do protótipo: 2 módulos existentes (`frame_extraction.py`, `projects/utils/video.js`), 2 serviços (`video_tool`, `projects`). O protótipo atualizou as mensagens, mas não os testes; o custo total da implementação deve ser reavaliado quando o cenário for repetido.
- Cenário 3, efeito comum: aplicar fator 0,9 ao brilho tanto na imagem como no vídeo. Aceitação: o mesmo fator produz o mesmo resultado PIL nos dois caminhos. Baseline do protótipo: 2 módulos existentes (`Tools/brightness/brightness.py`, `Tools/video/effects.py`), 2 serviços (`brightness_tool`, `video_tool`). A verificação automática do protótipo confirma o resultado do vídeo e a expressão equivalente no código da imagem; uma implementação completa deve testar também o serviço de imagem.

*Contagem:* ficheiros Python de produção existentes modificados são módulos; serviços são os executáveis que precisam de reconstrução para incorporar esses módulos. Não contar testes, configuração, componentes novos nem `__pycache__` como módulos existentes. Os três protótipos alteraram 0 componentes novos, 0 ficheiros de configuração e 0 ficheiros de testes. Tempo de esforço humano não medido: a execução foi assistida por Codex e uma repetição pela mesma pessoa estaria sujeita a aprendizagem.

*Critérios propostos antes do refactoring:* para legendas, manter no máximo 1 módulo e 1 serviço existente afetado; para extração, não exceder 2 módulos e 2 serviços; para o efeito comum, reduzir de 2 para no máximo 1 módulo existente, sem exceder 2 serviços. Não aumentar a complexidade média (4,56), o máximo (22) nem a duplicação interna exata (0%); objetivo de melhoria: máximo de complexidade ≤ 20 e maior módulo ≤ 300 linhas físicas, face às 369 atuais. Estes limiares são escolhas operacionais da equipa para reduzir concentração e propagação de alterações; carecem de validação humana e não provêm da ISO. A aceitação funcional completa é obrigatória mesmo que a contagem de módulos melhore.

== Criar a verificação de não-regressão

*Inventário:* `Tools/video/tests/test_video_processor.py` cobre efeitos, ordem, trim, speed, áudio, formatos, dimensões, preview, progresso e falhas; `test_subtitles.py` cobre legendas com reconhecimento simulado, ausência de fala, ordem, preview e falhas; `test_frame_extraction.py` cobre contagem/intervalo, formatos, contact sheet, ordem e falhas. `projects/tests/video-pipeline.test.js`, `process-batch.test.js` e `frame-extraction.test.js` cobrem encaminhamento de media mistos, registo de lotes e resultados de frames. Acrescentado `mixed project preserves ordered video stages...` a `video-pipeline.test.js` para verificar numa sequência única imagem, dois vídeos, trim/speed direcionados, legendas e extração terminal.

*Lacunas conhecidas:* os testes Python simulam o reconhecimento de fala, sem carregar o modelo real; a suíte não testa o consumidor RabbitMQ, S3/volume partilhado, quota/API/UI nem o fluxo ponta a ponta. O manifesto `fase2/documentacao/video-cases.json` reserva um caso com fala real. Estes limites não são prova de regressão; exigem testes de integração separados.

*Comparação funcional:* exigir igualdade exata para ordem e número de operações, tipos de resultado, nomes/IDs, erros de validação, ausência de output parcial, codec H.264/AAC, dimensões e quantidade de fotogramas. Exigir SHA-256 idêntico para as entradas originais, não para o MP4 recodificado. Para duração e timestamps, usar as tolerâncias dos testes existentes (tipicamente ±0,15 s ou ±0,05 s para amostras de frames); para conteúdo visual recodificado, comparar propriedades e medidas de imagem com limiares declarados por teste, não bytes do vídeo. Progresso deve ser monótono e terminar em 100%.

*Referência de testes:* a suíte do `video_tool` no Docker passou 74/74, log `fase2/resultados/baseline/video-baseline-docker-pytest.txt`. Os três ficheiros de testes do `projects` no Docker passaram 9/9, incluindo o novo caso misto, log `fase2/resultados/baseline/projects-node-tests.txt`. Ambos os resultados são anteriores ao refactoring.

*Tempos de pipeline no Docker:* `fase2/scripts/measure_video_cases.py` usa os vídeos do manifesto, valida SHA-256 e executa três vezes cada caso leve no container `video_tool`; resultados em `fase2/resultados/baseline/video-case-times.json`. Medianas: efeitos ordenados 0,738 s, trim/speed com áudio 0,664 s, preview da extração 1,347 s, entrada inválida 0,058 s. O caso de fala real fica separado por exigir modelo. Estes tempos medem a função do worker sem tráfego RabbitMQ; servem para detetar custos locais, não latência ponta a ponta. Na versão final, repetir na mesma máquina/imagem base, com três repetições; investigar qualquer mediana acima de 120% da referência, sem tratar essa margem como norma.

== Medir a versão final e entregar evidência


*Prioridade imediata:* fixar o commit inicial, acordar as métricas e guardar a baseline antes de a equipa começar a alterar o código.

== Registo de trabalho

=== 11 de novembro de 2026 — Definição inicial da avaliação

- Respostas do responsável: âmbito `/video`; complexidade, duplicação, acoplamento, tamanho dos módulos e facilidade de alterar uma funcionalidade; referência na branch `baseline`; sem metas impostas.
- Verificação local: `baseline` aponta para `ab3ae9cf8efcfa444e9599f8e291551c5930c289` nesta data.
- Decisão posterior do responsável: preservar todos os comportamentos funcionais do vídeo; melhorar apenas requisitos não funcionais.
- Falta operacionalizar cada métrica e definir o procedimento de verificação de não-regressão.
- Iniciada a tarefa seguinte, preparação da baseline: commit e estado local verificados; dados do ambiente inicial registados acima. A recolha de métricas ainda não começou.
- Classificação, unidades de análise e fragilidades documentadas nesta secção; respetivas subtarefas concluídas no Todoist. Fichas de métricas iniciadas, sem resultados ou metas inventados.
- Escolha das métricas principais e complementares e fichas de definição concluídas no Todoist; tarefa principal "Definir o que vai ser avaliado" concluída. Os campos de baseline ainda não medidos e as metas por aprovar estão identificados explicitamente, não preenchidos com valores presumidos.
- Tarefa concluída movida para a coluna "Concluído". A preparação da baseline passou para "Em curso". Inventário do ambiente, mapa de dependências e conservação dos resultados brutos concluídos; evidência nesta secção e nos ficheiros `fase2/resultados/baseline/video-baseline-*`.
- Após o utilizador iniciar os containers, a suíte do worker foi repetida numa imagem `video_tool` reconstruída; 74 testes passaram. Log e comando acima. Isto ainda não constitui teste de integração dos serviços.
- Preparação do benchmarking e verificação de não-regressão concluídas antes do refactoring; respetivas tarefas principais movidas para "Concluído" após todas as subtarefas. A execução final dos mesmos procedimentos continua dependente da versão refatorada. Os alvos definidos são propostas operacionais para validação humana.
- Manifesto dos cenários e script completo de recolha criados e validados; as duas últimas subtarefas da baseline foram concluídas. A tarefa principal "Preparar e recolher a baseline" foi concluída e movida para "Concluído". A execução comparativa dos cenários e os testes de integração permanecem nas fases de benchmarking e não-regressão.

Ao concluir uma tarefa no Todoist, acrescentar a data e a referência da evidência neste registo. Atualizar este registo com decisões e resultados reais.

=== 6 de novembro de 2026 — Preparação da documentação

- Tarefas da avaliação da modularidade transferidas para o Todoist em 11 de novembro de 2026.
- Ferramentas propostas: Git, Radon, jscpd, pytest e coverage.py.
- Apoio de IA: Codex ajudou a estruturar a lista e a criar este documento; validação humana pendente.
- Baseline, valores-alvo e resultados finais: por recolher ou definir.

=== Modelo de entrada futura

- *Data e responsável:* por preencher.
- *Tarefa e objetivo:* por preencher.
- *Commit e ambiente:* por preencher.
- *Procedimento e comandos:* por preencher.
- *Resultados e localização da evidência:* por preencher.
- *Decisão, limitações e próximo passo:* por preencher.
- *Apoio de IA e validação humana:* por preencher.

== Referências de trabalho

- Diretrizes da Fase 2, versão 1: ficheiro `fase2/referencias/fase-2-guidelines.pdf`, sobretudo páginas 2 e 3.
- Orientações do repositório: `AGENTS.md`.
- Referência normativa indicada pelo enunciado: ISO/IEC 25010:2011. A consulta da norma e a fundamentação detalhada devem ser registadas pela equipa.
