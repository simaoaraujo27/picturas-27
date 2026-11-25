#import "../template.typ": *

= Decisões Arquiteturais

== DA-1 — Decompor o processamento de vídeo por domínio e compor os estágios no orquestrador (cenário QS-01)

#tab([Decisão arquitetural DA-1],
  tabela-campos(
    [Contexto], [Na base (`0523102`) todos os efeitos de vídeo, a legendagem automática e a extração de fotogramas partilhavam o serviço `video_tool`, a fila `video_queue` e um `requirements.txt` que juntava Pillow/FFmpeg a `faster-whisper`/`torch` (EV-01, EV-02, EV-03). Qualquer alteração a um efeito obrigava a compreender e reconstruir o monólito, e uma falha na legendagem parava todos os vídeos. A fase é de refactoring: o comportamento funcional, incluindo a ordem dos efeitos e o progresso, tem de ser preservado.],
    [Tática(s) escolhida(s)], [TAT-01, TAT-02, TAT-03, TAT-05],
    [Estrutura / padrão que a realiza], [Três microserviços autónomos — `video_effects_tool`, `video_subtitles_tool`, `video_frames_tool` — com uma fila própria cada um no exchange `picturas` (`video_effects_queue`, `video_subtitles_queue`, `video_frames_queue`) e `requirements.txt` isolado. O orquestrador `projects` calcula `videoStages()` e encadeia a resposta de cada estágio na `project_queue`, avançando para o seguinte até esgotar o pipeline. Cada worker reporta a sua fatia do progresso com `base`/`span`.],
    [Alternativas consideradas e razão de rejeição], [ALT-1 (manter o monólito): rejeitada porque não resolve a fragilidade de acoplamento nem o ponto único de falha, apesar de ser a de menor risco imediato · ALT-3 (réplicas do monólito): rejeitada porque aumenta a capacidade sem aumentar a modularidade e multiplica o custo de build e disco de cada réplica],
    [Consequências positivas], [Mudança confinada a um domínio; imagem de efeitos reduzida de 1,70 GB para 1,09 GB; falha de legendagem isolada nos outros dois workers; alinhamento com o padrão já usado pelas ferramentas de imagem (EV-04); progresso agregado com `base`/`span` por estágio],
    [Consequências negativas / riscos], [Espaço total em disco sobe de 1,70 GB para 3,92 GB; três imagens e três filas aumentam a complexidade operacional; o encadeamento no orquestrador é um novo ponto de coordenação e foi onde surgiu a regressão dos pipelines mistos, depois corrigida],
    [Elementos arquiteturais afetados], [`Tools/video_effects/`, `Tools/video_subtitles/`, `Tools/video_frames/`; `rabbitMQ/definitions.json`; `docker-compose.yaml`; `projects/utils/video.js`, `projects/utils/project_msg.js`, `projects/routes/projects.js`; remoção de `Tools/video/`, `video_tool` e `video_queue`],
    [Origem e âmbito do _refactoring_], [Padrão do vídeo, alinhado com o padrão global; risco de regressão médio no despacho e alto no encadeamento de pipelines mistos — foi exigida evidência de integração antes de aceitar a decisão],
    [Classe (A/B/C)], [A — a alteração é estrutural e preserva o comportamento funcional; a correção do encadeamento restaura o comportamento da base, não acrescenta funcionalidade],
    [Implementação (_commits_ / _pull requests_)], [Merge `9976985` (refactor/video-modularity); `00fac4d`, `b3d851b`, `b424d82` (extração e limpeza); `cc53fac` (encadeamento de pipelines mistos e progresso agregado); `2ee32d7` (teste de integração de pipeline misto)],
    [Desvios face à decisão], [A vista «depois» do capítulo 9 reflete a implementação final. O plano inicial previa apenas o despacho por domínio; a execução revelou que pipelines mistos (efeito seguido de legendagem) exigiam composição explícita no orquestrador, pelo que TAT-03 passou a ser parte integrante da decisão. O plano previa também que o monólito excedia 3,5 GB; a medição real deu 1,70 GB e o relatório usa o valor medido],
  ),
)

== DA-2 — Substituir o ecrã de processamento bloqueante por um cartão de progresso não bloqueante (cenário QS-02)

#tab([Decisão arquitetural DA-2],
  tabela-campos(
    [Contexto], [Na base, o processamento de um projeto mostra um `div` com `absolute top-0 left-0 h-screen w-screen bg-black/70 z-50` que cobre a área de conteúdo (83,3 % da janela); durante o processamento só o botão Cancelar responde nessa área (EV-09, EV-10, EV-11). A fase é de _refactoring_: o processamento, o progresso e o cancelamento têm de se manter.],
    [Tática(s) escolhida(s)], [TAT-04],
    [Estrutura / padrão que a realiza], [O mesmo `Transition` e o mesmo conteúdo (barra de progresso, percentagem e botão Cancelar), com o `div` exterior a passar a `fixed bottom-4 right-4 z-50`, o `Card` sem `justify-center` e com `shadow-lg`, e a `Progress` de `w-96` para `w-64`. A lógica de `processing`, `displayedProgress`, `cancelProcess` e `handleCancel` não foi alterada.],
    [Alternativas consideradas e razão de rejeição], [TAT-06 (indicador global no layout): rejeitada nesta fase porque exige um estado partilhado novo e alterar o Apply, o progresso e o cancelamento, com maior risco de regressão, e aproxima-se de manter o progresso fora da página, que está fora do âmbito · TAT-07 (_toast_): rejeitada porque é pouco adequada a uma barra de progresso contínua e a um botão de cancelar · TAT-08 (pausar e retomar): rejeitada por ser classe C · manter o ecrã sobreposto: rejeitada porque não resolve a fragilidade],
    [Consequências positivas], [O elemento de processamento passa de 83,3 % para 4,6 % da janela (289,6 × 169,6 px); a interface responde durante o processamento; a lógica de processamento não foi tocada: o `git diff` mostra três linhas de `className` alteradas],
    [Elementos arquiteturais afetados], [`frontend/app/dashboard/[pid]/page.tsx` (três linhas de `className`: o `div` exterior, o `Card` e a `Progress`)],
    [Origem e âmbito do _refactoring_], [Interação no frontend, fora do padrão do vídeo; risco de regressão baixo, porque só muda a apresentação; a persistência do progresso e do cancelamento após recarregar a página não faz parte desta decisão],
    [Classe (A/B/C)], [B — muda a apresentação do estado do processamento apenas para melhorar a operabilidade; o utilizador não ganha nenhuma capacidade nova],
    [Implementação (_commits_ / _pull requests_)], [Branch `non-blocking-processing-overlay`],
    [Desvios face à decisão], [A estimativa inicial de que o elemento cobria 100 % da janela do projeto (`h-screen w-screen`) foi corrigida pela medição: o `overflow-hidden` do layout corta-o e a área visível é de 83,3 %. A estimativa inicial de cerca de 3 % para o cartão foi corrigida pela medição para 4,6 %],
  ),
)