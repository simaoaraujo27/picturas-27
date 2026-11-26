#import "../template.typ": *

// Capítulo inteiro na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Candidatos a Requisitos Não Funcionais

Os candidatos escolhidos correspondem aos cenários prioritários do capítulo 5. O `CAND-1` segue a sugestão indicativa da docência para o PictuRAS (guia da Fase 2, «Ideias (indicativas)»): dividir o processamento de vídeo em vários microserviços, à semelhança do que já acontece com as ferramentas de imagem. O `CAND-2` segue a ideia «Usabilidade — trabalho em segundo plano» da mesma secção: deixar de bloquear a interface e recuperar o acompanhamento e o acesso ao cancelamento depois de recarregar a página do projeto.

#tab([Candidato a requisito não funcional da Fase 2],
  tabela(
    colunas: (1.6cm, 2.6cm, 3cm, 2.4cm, 2.8cm, 2.6cm, 2cm, 3cm, 2.8cm),
    tamanho: 7.5pt,
    [\#], [Característica / subcaracterística (ISO/IEC 25010)], [Fragilidade na base (evidência)], [Origem (padrão global / vídeo / interação)], [Impacto nos stakeholders (pertinência)], [Exigência técnica (complexidade)], [Cenário (`QS-nn`, cap. 5)], [Escala e método de medição (esboço)], [Pré-requisitos / efeitos colaterais],
    [CAND-1], [Manutenibilidade → Modularidade e Reutilizabilidade], [EV-01, EV-03: um único serviço e uma única fila agrupam filtros leves, legendagem com Whisper e extração de fotogramas; `requirements.txt` combina Pillow/FFmpeg com `faster-whisper`/`torch`], [Padrão do vídeo, alinhado com o padrão global usado pelas imagens (EV-04)], [Alta — reduz o custo e o risco de cada alteração futura; é um exemplo explícito da docência], [Média — três serviços, três filas e composição de estágios no orquestrador; reutiliza estrutura existente], [QS-01], [Ficheiros e serviços tocados por uma mudança; tamanho e build da imagem afetada; Radon MI; isolamento de falhas], [Sinergia com fiabilidade e tempo de build; conflito com espaço total em disco],
    [CAND-2], [Usabilidade → Operabilidade], [EV-09 a EV-13: sobreposição de 83,3 % e perda do acompanhamento após F5], [Interação frontend / API / projects; suporte de estado durável], [Alta — manter acesso ao projeto e ao acompanhamento de trabalho já iniciado], [Média — apresentação, estado persistido, recuperação e cancelamento por token], [QS-02], [Área obstruída (%); ações utilizáveis; recuperação de estado/progresso e acesso ao cancelamento após F5], [Cartão limitado à página do projeto; consultas e escritas adicionais; compatibilidade com o progresso por estágios do DA-1],
  ),
)

== Quantificação

A escala e o método da comparação visual estão documentados nas notas de medição. O complemento de recuperação explicita os critérios e a evidência disponível; não reconstrói retroativamente tempos ou contagens que não foram recolhidos. O capítulo 10 apresenta os resultados e as suas origens.

#tab([Quantificação do requisito não funcional],
  tabela(
    colunas: (4.2cm, 1fr),
    [], [CAND-1],
    [Escala (o que se mede e em que unidade)], [Número de ficheiros de código e de serviços que uma mudança de efeito obriga a alterar e reconstruir; tamanho da imagem Docker (GB); tempo de build limpo (s); Radon MI por módulo],
    [Cenário de medição], [Adicionar um efeito simples ao caminho de efeitos de vídeo e medir o âmbito da alteração; medir o build limpo de cada variante; provocar falha no worker de legendagem],
    [Carga], [Um vídeo de teste curto; uma alteração de efeito por repetição; build sem cache],
    [Ambiente], [Mesmo host, Compose project isolado, revisão `0523102` (base) e revisão final; mesmas imagens e parâmetros],
    [Instrumento], [`git diff --stat`, `docker image inspect`, `time docker compose build`, `radon mi`, logs dos workers e contagem de domínios afetados],
    [Valor medido na base], [Ver capítulo 10: monólito de 1,70 GB; uma fila e um serviço para os três domínios; uma falha de legendagem parava o único worker],
    [Valor-alvo (e origem)], [Derivado da medição da base e da recomendação da docência: confinar a mudança a um domínio e reduzir a imagem reconstruída, sem perder a preservação funcional],
    [Valor mínimo aceitável (e origem)], [Critério da equipa: nenhuma regressão funcional e nenhuma degradação do índice de manutenibilidade. A preservação integral não está demonstrada: existem casos não aprovados e limitações do executor, discriminados no capítulo 10.],
    [Medições ainda em falta], [Não existe contagem reproduzível dos ficheiros alterados para acrescentar o mesmo efeito nem tempo de build limpo comparável. Não se deduzem esses valores a partir do tamanho das imagens. A campanha EV-14 acrescenta métricas estáticas e explicita os seus custos.],
  ),
)

#tab([Quantificação do requisito não funcional CAND-2],
  tabela(
    colunas: (4.2cm, 1fr),
    [], [CAND-2],
    [Escala (o que se mede e em que unidade)], [Percentagem da área da janela (_viewport_) coberta pelo elemento de processamento visível: largura × altura visíveis ÷ (`innerWidth` × `innerHeight`) × 100. Medida de apoio: ações da interface utilizáveis durante o processamento],
    [Cenário de medição], [Processar o projeto `test1` (três vídeos de 6,0 s, 10,0 s e 176,6 s) com a legendagem automática e medir o elemento de processamento enquanto o processamento decorre],
    [Carga], [Um processamento por variante, com a mesma ferramenta, o mesmo projeto e a mesma janela],
    [Ambiente], [Windows, Docker Desktop e Chrome; ecrã de 1920 × 1080 px com escala de 125 %; janela de 1536 × 695,2 px (CSS); base `c98fd47` (equivalente a `0523102` nos ficheiros do frontend do CAND-2)],
    [Instrumento], [Inspetor do browser (Ctrl+Shift+C) para as dimensões visíveis do elemento; `innerWidth` e `innerHeight` na consola; capturas de ecrã],
    [Valor medido na base], [83,3 % (1280 × 695 px visíveis numa janela de 1536 × 695,2 px); na área de conteúdo só o Cancelar respondeu; a barra lateral ficou utilizável],
    [Valor-alvo e mínimo visual], [Área obstruída inferior a 10 % da janela, critério adotado pela equipa; manter navegação e acesso ao acompanhamento. O resultado medido é 4,6 % (cap. 10). Abrir um diálogo não implica autorizar alterações incompatíveis com uma execução ativa.],
    [Complemento do cenário: recuperação], [Recarregar ou sair e voltar à página durante uma execução. A resposta esperada é recuperar estado/progresso e acesso autorizado ao cancelamento, sem voltar a submeter Apply.],
    [Escala e método da recuperação], [Sucesso/falha observado manualmente após F5 e saída/regresso; comparar estado e token via API e contar novos Apply quando houver inspeção de rede. Tempo até recuperar os controlos em segundos, se cronometrado.],
    [Baseline da recuperação], [Análise do código de `0523102` (EV-13): estado local sem consulta de recuperação. Não foi registada uma medição manual ou temporal de F5 na base.],
    [Alvo e mínimo da recuperação], [Recuperar o acompanhamento nos percursos definidos e não criar nova execução por causa do refresh. O token e a permissão devem limitar o cancelamento à execução ativa. O intervalo de consulta de 2 s é uma configuração; não foi definido nem medido um limite temporal de F5.],
    [Evidência final e limites], [F5 e saída/regresso com sucesso segundo relato manual de 17 de novembro em `usabilidade-notas.typ`. Sem contagem de repetições, tempos, capturas ou inspeção de tokens; não calcular taxa de sucesso nem apresentar estes percursos como teste automatizado aprovado.],
  ),
)

== Efeitos colaterais do candidato

O `CAND-1` é interno (estrutura do processamento de vídeo). Afeta sobretudo a manutenibilidade,
mas tem dois efeitos colaterais diretos medidos no capítulo 10: melhora o isolamento de falhas
(fiabilidade) e o tamanho da imagem reconstruída (eficiência), ao custo de um maior espaço total
em disco. A continuidade do progresso entre estágios é tratada como requisito de preservação
funcional da própria decomposição — com três workers em vez de um, a agregação com `base`/`span`
passa a ser necessária para não perder a informação que o worker monolítico emitia. Não foi
introduzida nenhuma funcionalidade nova.

O `CAND-2` combina apresentação não bloqueante com recuperação do acompanhamento a partir do backend. O cartão pode sobrepor-se a controlos do vídeo e continua limitado à página do projeto. O estado persistido melhora a recuperabilidade, ao custo de consultas e escritas adicionais, ainda sem custo medido. A navegação não autoriza alterar a pipeline de uma execução ativa: essas escritas e um novo Apply são recusados. A compatibilidade do estado persistido com pipelines de vários workers deve ser verificada na revisão integrada, sem generalizar o relato manual a todos os estágios.

== Evidência exploratória (se existir)

#tab([Evidência exploratória],
  tabela(
    colunas: (4cm, 5cm, 1fr),
    [Descrição], [Localização (_scripts_, dados, resultados)], [Como repetir],
    [Tamanho das imagens e tempo de build dos workers], [`docker images --format '{{.Repository}}\t{{.Size}}'`; `fase2/plano_membro_a_modularidade_video.md`], [Listar as imagens no mesmo host e comparar `video_tool` com os três workers],
    [Divisão do pipeline em estágios], [`projects/utils/video.js` (`videoStages()`), `projects/tests/video-pipeline.test.js`], [`node --test projects/tests/video-pipeline.test.js`],
    [Progresso agregado dos estágios], [`Tools/video_effects/video_effects.py`, `Tools/video_subtitles/video_subtitles.py`, `Tools/video_frames/video_frames.py` (parâmetros `base`/`span`); eventos `video-progress` observados na integração], [Executar um pipeline misto e recolher os eventos no socket; ver capítulo 10],
  ),
)
]
