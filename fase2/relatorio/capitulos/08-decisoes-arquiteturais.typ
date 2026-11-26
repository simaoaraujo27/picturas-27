#import "../template.typ": *

= Decisões Arquiteturais

== DA-1 — Decompor o processamento de vídeo por domínio e compor os estágios no orquestrador (cenário QS-01)

#tab([Decisão arquitetural DA-1],
  tabela-campos(
    [Contexto], [Na base (`0523102`) todos os efeitos de vídeo, a legendagem automática e a extração de fotogramas partilhavam o serviço `video_tool`, a fila `video_queue` e um `requirements.txt` que juntava Pillow/FFmpeg a `faster-whisper`/`torch` (EV-01, EV-02, EV-03). Qualquer alteração a um efeito obrigava a compreender e reconstruir o monólito, e uma falha na legendagem parava todos os vídeos. A fase é de refactoring: o comportamento funcional, incluindo a ordem dos efeitos e o progresso, tem de ser preservado.],
    [Tática(s) escolhida(s)], [TAT-01, TAT-02, TAT-03, TAT-05],
    [Estrutura / padrão que a realiza], [Três microserviços autónomos — `video_effects_tool`, `video_subtitles_tool`, `video_frames_tool` — com uma fila própria cada um no exchange `picturas` (`video_effects_queue`, `video_subtitles_queue`, `video_frames_queue`) e `requirements.txt` isolado. O orquestrador `projects` calcula `videoStages()` e encadeia a resposta de cada estágio na `project_queue`, avançando para o seguinte até esgotar o pipeline. Cada worker reporta a sua fatia do progresso com `base`/`span`.],
    [Alternativas consideradas e razão de rejeição], [ALT-1 (manter o monólito): rejeitada porque não resolve a fragilidade de acoplamento nem o ponto único de falha, apesar de ser a de menor risco imediato · ALT-3 (réplicas do monólito): rejeitada porque aumenta a capacidade sem aumentar a modularidade e mantém o rebuild monolítico e aumenta o consumo de RAM],
    [Consequências positivas], [Mudança confinada a um domínio; imagem de efeitos reduzida de 1,70 GB para 1,09 GB; falha de legendagem isolada nos outros dois workers; alinhamento com o padrão já usado pelas ferramentas de imagem (EV-04); progresso agregado com `base`/`span` por estágio],
    [Consequências negativas / riscos], [Espaço total em disco sobe de 1,70 GB para 3,92 GB; três imagens e três filas aumentam a complexidade operacional; o encadeamento no orquestrador é um novo ponto de coordenação e foi onde surgiu a regressão dos pipelines mistos, depois corrigida],
    [Elementos arquiteturais afetados], [`Tools/video_effects/`, `Tools/video_subtitles/`, `Tools/video_frames/`; `rabbitMQ/definitions.json`; `docker-compose.yaml`; `projects/utils/video.js`, `projects/utils/project_msg.js`, `projects/routes/projects.js`; remoção de `Tools/video/`, `video_tool` e `video_queue`],
    [Origem e âmbito do _refactoring_], [Padrão do vídeo, alinhado com o padrão global; risco de regressão médio no despacho e alto no encadeamento de pipelines mistos — foi exigida evidência de integração antes de aceitar a decisão],
    [Classe (A/B/C)], [A — a alteração é estrutural e preserva o comportamento funcional; a correção do encadeamento restaura o comportamento da base, não acrescenta funcionalidade],
    [Implementação (_commits_ / _pull requests_)], [Merge `9976985` (refactor/video-modularity); `00fac4d`, `b3d851b`, `b424d82` (extração e limpeza); `1fe42ba` (encadeamento de pipelines mistos e progresso agregado); `85b99d4` (teste de integração de pipeline misto)],
    [Desvios face à decisão], [A vista «depois» do capítulo 9 reflete a implementação final. O plano inicial previa apenas o despacho por domínio; a execução revelou que pipelines mistos (efeito seguido de legendagem) exigiam composição explícita no orquestrador, pelo que TAT-03 passou a ser parte integrante da decisão. O plano previa também que o monólito excedia 3,5 GB; a medição real deu 1,70 GB e o relatório usa o valor medido],
  ),
)

== DA-2 — Cartão não bloqueante e recuperação do acompanhamento após refresh (cenário QS-02)

#tab([Decisão arquitetural DA-2],
  tabela-campos(
    [Contexto], [A sobreposição cobre 83,3 % da janela e bloqueia a área de conteúdo (EV-09 a EV-11). O acompanhamento é local à página e perde-se após F5, embora o processamento continue no servidor (EV-13). O QS-02 e a introdução exigem manter a operabilidade e recuperar o acesso à execução existente, em coerência com EV-12.],
    [Tática(s) escolhida(s)], [TAT-04 e TAT-09],
    [Estrutura / padrão que a realiza], [Cartão `fixed bottom-4 right-4` com barra em `w-64`. O projeto MongoDB guarda `processingState` com token, estado, passos e progresso por vídeo. `GET /:user/:project/process/status`, através do API Gateway, devolve estado, progresso, versão e `canCancel`, sem cache. `useGetProcessingStatus` consulta ao montar a página e a cada 2 s; o frontend reconstitui o cartão em vez de depender dos eventos perdidos durante F5. O cancelamento consulta a versão atual e envia `X-Process-Token`.],
    [Alternativas consideradas e razão de rejeição], [TAT-06 (cartão global no layout): não escolhida; exigiria acompanhamento permanente entre páginas, enquanto esta decisão recupera o cartão quando o projeto é reaberto. Essa limitação não exclui a persistência após F5 · TAT-07 (_toast_): aviso temporário pouco adequado a progresso contínuo e cancelamento · estado apenas em localStorage ou apenas por WebSocket: não confirma o estado atual no servidor após uma ausência · pausar e retomar o worker: rejeitado por introduzir capacidade nova, de classe C · manter a sobreposição: não resolve a operabilidade.],
    [Consequências positivas], [Área obstruída de 83,3 % para 4,6 % na medição visual; recuperação após F5 e saída/regresso confirmada por relato manual; progresso e acesso autorizado ao cancelamento reconstruídos a partir do estado persistido. O refresh consulta a execução existente, sem iniciar Apply.],
    [Consequências negativas / riscos], [Consultas periódicas e escritas de progresso acrescentam custo não medido. O cartão mantém-se na página do projeto e pode sobrepor controlos. É necessário preservar token, permissões e estados terminais e verificar a integração do progresso persistido com os estágios do DA-1. Tempo de recuperação e cenários completos de erro/concorrência ainda sem medição de browser.],
    [Elementos arquiteturais afetados], [Página do projeto e bibliotecas de consultas/mutações do frontend; rotas do API Gateway; modelo, controlador e rotas de `projects`; `projects/utils/processingStatus.js`; publicação de progresso para persistência no caminho de vídeo. Reutilizam-se MongoDB, autenticação e execução existentes.],
    [Origem e âmbito do _refactoring_], [Interação frontend/backend. A recuperação do acompanhamento e do acesso ao cancelamento após recarregar ou reabrir o projeto está incluída no CAND-2. Ficam fora o cartão global sempre visível e a pausa/retoma física do worker. Risco médio, pois a decisão completa já não se limita a CSS.],
    [Classe (A/B/C)], [B — melhora a operabilidade de processamento, acompanhamento e cancelamento existentes; a persistência é suporte interno da recuperação, não uma nova ferramenta de edição.],
    [Implementação (_commits_ / _pull requests_)], [`75986e6` (cartão não bloqueante), `e58c640` (recuperação após refresh e testes), `c1c98da` (documentação); trabalho do branch `non-blocking-processing-overlay`, integrado na revisão atual. Esta revisão altera apenas o relatório.],
    [Desvios face à decisão], [A redação inicial documentava apenas três alterações de classes CSS e excluía F5. Foi atualizada para refletir a recuperação já implementada, preservando o QS-02. As dimensões 83,3 % e 4,6 % continuam a ser medições visuais; não provam recuperação nem latência de F5. A rejeição do cartão global não é rejeição do estado persistido.],
  ),
)
