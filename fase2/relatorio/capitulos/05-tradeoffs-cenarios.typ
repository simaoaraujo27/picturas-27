#import "../template.typ": *

= Trade-offs, Cenários de Qualidade e Prioridades

Os cenários seguintes partem das fragilidades observadas na solução de base (commit `0523102`) e
das evidências registadas no capítulo 2. Mantêm os identificadores `EV-01` a `EV-06` e a hipótese
`H-01` já apresentados, sem os alterar.

== Cenários de qualidade para a extensão de vídeo

#paisagem[
#tab([Cenários de qualidade],
  tabela(
    colunas: (1.2cm, 3.4cm, 2.6cm, 2.2cm, 2.2cm, 2.4cm, 2.2cm, 2.6cm, 3cm),
    tamanho: 7.5pt,
    [ID], [Fragilidade na base (EV-nn)], [Característica (ISO/IEC 25010)], [Fonte do estímulo], [Estímulo], [Artefacto], [Ambiente], [Resposta], [Medida da resposta],
    [QS-01], [EV-01, EV-03: efeitos leves e inferência de IA partilham o mesmo processo e as mesmas dependências], [Manutenibilidade → Modularidade, Reutilizabilidade], [Desenvolvedor], [Adicionar ou alterar um efeito no pipeline de vídeo], [Subsistema de processamento de vídeo (`Tools/video/`, `video_tool`, `video_queue`)], [Manutenção normal, sem carga], [A alteração fica confinada ao módulo do domínio; só esse serviço é reconstruído], [Número de ficheiros e serviços tocados; tamanho e tempo de build da imagem reconstruída; índice de manutenibilidade (Radon MI)],
    [QS-02], [EV-09, EV-10, EV-11: o ecrã sobreposto cobre a área de conteúdo (83,3 % da janela) durante o processamento], [Usabilidade → Operabilidade], [Utilizador], [Inicia o processamento de um projeto e tenta continuar a usar a aplicação], [Ecrã de processamento do frontend (`frontend/app/dashboard/[pid]/page.tsx`)], [Processamento a decorrer num projeto com vídeos, carga normal], [A interface mantém-se utilizável durante o processamento; o progresso e o cancelamento continuam visíveis], [Percentagem da janela obstruída pelo elemento de processamento visível; medida de apoio: ações da interface utilizáveis durante o processamento],
    [QS-03], [EV-03: uma falha fatal na legendagem (OOM/SIGKILL) derruba o único worker e atrasa todos os vídeos], [Fiabilidade → Tolerância a falhas, Isolamento de falhas], [Falha de infraestrutura / worker], [O componente de legendagem termina anormalmente durante um lote], [Subsistema de processamento de vídeo], [Carga normal, vários vídeos na fila], [A falha afeta apenas o domínio da legendagem; os restantes trabalhos concluem], [Número de domínios parados (de 3); conclusão dos trabalhos dos outros domínios (sim/não)],
  ),
)
]

A medida do QS-01 é deliberadamente composta: isoladamente, "menos ficheiros tocados" poderia ser
obtido com uma alteração superficial. Exige-se também que a imagem reconstruída seja a do domínio
alterado e que o índice de manutenibilidade não diminua. A medição inicial é apresentada no
capítulo 10; os valores não são fixados aqui.
A medida do QS-02 é a percentagem da janela obstruída, porque a fragilidade é o espaço que o ecrã de processamento retira ao utilizador. A medida de apoio (ações utilizáveis durante o processamento) é observada manualmente e por isso não decide sozinha. 

== Priorização dos cenários

#tab([Priorização dos cenários],
  tabela(
    colunas: (1.6cm, 4.8cm, 4.8cm, 2cm),
    [ID], [Importância para os stakeholders], [Dificuldade / risco técnico], [Prioridade],
    [QS-01], [Alta — afeta diretamente o custo e o risco de cada alteração futura ao processamento de vídeo, e é um dos exemplos indicados pela docência para esta fase], [Média — exige extrair três serviços e adaptar o orquestrador, mas reutiliza o padrão já aplicado às ferramentas de imagem (EV-04)], [1],
    [QS-02], [Alta — durante o processamento o utilizador não pode editar, usar as ferramentas nem abrir o Import, e é uma das ideias indicativas da docência], [Baixa — a alteração fica confinada a classes CSS de um componente e não toca na lógica de processamento], [2],
    [QS-03], [Média — é um efeito colateral da fragmentação em processos distintos, não um objetivo autónomo da equipa], [Baixa — é obtida pela mesma decomposição do QS-01, sem trabalho adicional], [3],
  ),
)

== Atributos de qualidade por ordem de prioridade

+ Manutenibilidade → Modularidade (QS-01) — é o objetivo explícito do refactoring e condiciona a
  capacidade de responder ao outro cenário sem introduzir regressões.
+ Usabilidade → Operabilidade (QS-02) — é o segundo requisito da equipa: durante o processamento a área de trabalho fica tapada, e a alteração para o desbloquear é de baixo risco.
+ Fiabilidade → Tolerância a falhas (QS-03) — resulta da separação de processos e é registada como consequência positiva, não como candidato a RNF.

A ordem é coerente com a priorização: o primeiro atributo dá origem a `CAND-1` e o segundo a `CAND-2` no capítulo 6; o terceiro é acompanhado como efeito colateral.

== Pré-requisitos e efeitos colaterais entre atributos

#tab([Pré-requisitos e efeitos colaterais entre atributos],
  tabela(
    colunas: (2.8cm, 2.8cm, 4cm, 1fr),
    [Atributo A], [Atributo B], [Efeito (pré-requisito, sinergia ou conflito)], [Razão / evidência],
    [Manutenibilidade (modularidade)], [Fiabilidade (isolamento de falhas)], [Sinergia], [Processos e filas distintos impedem que uma falha na legendagem interrompa os efeitos; ver EV-03 e a medição de isolamento no capítulo 10],
    [Manutenibilidade (modularidade)], [Tamanho da imagem de efeitos], [Sinergia], [A imagem de efeitos deixa de incluir Faster-Whisper e passa de 1,70 GB para 1,09 GB na medição do QS-01],
    [Manutenibilidade (modularidade)], [Soma dos tamanhos das imagens], [Conflito], [A soma cresce de 1,70 GB para 3,92 GB. O espaço físico adicional depende das camadas partilhadas e fica por medir],
    [Manutenibilidade (modularidade)], [Fiabilidade (observabilidade do progresso)], [Pré-requisito], [Com vários workers, o progresso global só é coerente se cada estágio reportar a sua fatia com `base`/`span`],
    [Usabilidade (operabilidade)], [Manutenibilidade (modularidade)], [Sinergia], [O cartão mostra o progresso persistido no estado de processamento; o DA-1 mantém a continuidade do progresso entre estágios com `base`/`span`, pelo que o indicador continua coerente. O frontend obtém `displayedProgress` através de `useGetProcessingStatus` a partir da API de estado, atualizada a cada 2 segundos e alimentada pelos eventos `video-progress`],
    [Usabilidade (operabilidade)], [Fiabilidade (consistência do resultado)], [Conflito potencial], [Com a interface livre, o utilizador pode alterar o projeto durante o processamento.],
    [Usabilidade (operabilidade)], [Eficiência de desempenho], [Neutro], [A alteração só muda classes CSS; a lógica de processamento não foi tocada (EV-09)],
  ),
)

== Recomendações de melhoria à solução atual

#tab([Recomendações de melhoria],
  tabela(
    colunas: (1fr, 2.6cm, 3cm, 1.8cm, 2.2cm),
    tamanho: 8.5pt,
    [Recomendação], [Atributo(s)], [Padrão a que se refere (global / vídeo)], [Esforço], [Risco de regressão],
    [Separar os domínios de efeitos, legendagem e extração de fotogramas em serviços e filas próprios], [Manutenibilidade, Fiabilidade], [Padrão do vídeo, alinhado com o global (EV-04)], [Médio], [Médio],
    [Isolar as dependências em `requirements.txt` por serviço, removendo IA do caminho de efeitos], [Manutenibilidade, Eficiência], [Padrão do vídeo], [Baixo], [Baixo],
    [Fazer o orquestrador compor os estágios, encadeando a resposta de cada worker na fila `project_queue`], [Manutenibilidade, Fiabilidade], [Interação (orquestrador ↔ workers)], [Médio], [Alto],
    [Propagar `base`/`span` no progresso de cada estágio para preservar a continuidade entre workers], [Fiabilidade, Manutenibilidade], [Interação (orquestrador ↔ workers)], [Baixo], [Médio],
    [Substituir o ecrã sobreposto por um indicador de progresso fixo no canto, sem alterar a lógica de processamento], [Usabilidade], [Padrão global (frontend)], [Baixo], [Baixo],
  ),
)

A terceira recomendação é a que apresenta maior risco e foi efetivamente onde a implementação
encontrou uma regressão: a separação dos workers, por si só, não preserva o comportamento dos
pipelines mistos. O detetado e a correção são descritos nos capítulos 8 e 10.
