#import "../template.typ": *

= Trade-offs, Cenários de Qualidade e Prioridades

Os cenários seguintes partem das fragilidades observadas na solução de base (commit `0523102`) e
das evidências registadas no capítulo 2. Mantêm os identificadores `EV-01` a `EV-14` e a hipótese
`H-01` já apresentados, sem os alterar.

== Cenários de qualidade para a extensão de vídeo

#paisagem[
#tab([Cenários de qualidade],
  tabela(
    colunas: (1.2cm, 3.4cm, 2.6cm, 2.2cm, 2.2cm, 2.4cm, 2.2cm, 2.6cm, 3cm),
    tamanho: 7.5pt,
    [ID], [Fragilidade na base (EV-nn)], [Característica (ISO/IEC 25010)], [Fonte do estímulo], [Estímulo], [Artefacto], [Ambiente], [Resposta], [Medida da resposta],
    [QS-01], [EV-01, EV-03: efeitos leves e inferência de IA partilham o mesmo processo e as mesmas dependências], [Manutenibilidade → Modularidade, Reutilizabilidade], [Desenvolvedor], [Adicionar ou alterar um efeito no pipeline de vídeo], [Subsistema de processamento de vídeo (`Tools/video/`, `video_tool`, `video_queue`)], [Manutenção normal, sem carga], [A alteração fica confinada ao módulo do domínio; só esse serviço é reconstruído], [Número de ficheiros e serviços tocados; tamanho e tempo de build da imagem reconstruída; índice de manutenibilidade (Radon MI)],
    [QS-02], [EV-09 a EV-13: sobreposição ocupa 83,3 % da janela e F5 perde o acompanhamento local], [Usabilidade → Operabilidade], [Utilizador], [Inicia Apply, continua a navegar e recarrega ou reabre a página do projeto durante a execução], [Página do projeto e API de estado de processamento], [Execução ativa, utilizador autenticado com acesso ao projeto], [Interface utilizável; ao regressar, recuperar estado e progresso da execução existente e disponibilizar cancelamento a quem tem edição, sem novo Apply], [Área obstruída (%); recuperação após F5/saída-regresso (sucesso ou falha); acesso ao cancelamento; tempo de recuperação e pedidos adicionais, quando medidos],
    [QS-03], [EV-03: uma falha fatal na legendagem (OOM/SIGKILL) derruba o único worker e atrasa todos os vídeos], [Fiabilidade → Tolerância a falhas, Isolamento de falhas], [Falha de infraestrutura / worker], [O componente de legendagem termina anormalmente durante um lote], [Subsistema de processamento de vídeo], [Carga normal, vários vídeos na fila], [A falha afeta apenas o domínio da legendagem; os restantes trabalhos concluem], [Número de domínios parados (de 3); conclusão dos trabalhos dos outros domínios (sim/não)],
  ),
)
]

A medida do QS-01 é deliberadamente composta: isoladamente, "menos ficheiros tocados" poderia ser
obtido com uma alteração superficial. Exige-se também que a imagem reconstruída seja a do domínio
alterado e que o índice de manutenibilidade não diminua. A medição inicial é apresentada no
capítulo 10; os valores não são fixados aqui.
A percentagem da janela obstruída mede a componente visual do QS-02. A recuperação após F5 é um critério complementar do mesmo cenário: verificar o regresso do acompanhamento de uma execução existente. As ações utilizáveis e o sucesso da recuperação são observações manuais; não se confundem com uma medição de latência ou uma taxa de sucesso calculada sobre repetições. O capítulo 10 apresenta a proveniência e o limite de cada resultado.

== Priorização dos cenários

#tab([Priorização dos cenários],
  tabela(
    colunas: (1.6cm, 4.8cm, 4.8cm, 2cm),
    [ID], [Importância para os stakeholders], [Dificuldade / risco técnico], [Prioridade],
    [QS-01], [Alta — afeta diretamente o custo e o risco de cada alteração futura ao processamento de vídeo, e é um dos exemplos indicados pela docência para esta fase], [Média — exige extrair três serviços e adaptar o orquestrador, mas reutiliza o padrão já aplicado às ferramentas de imagem (EV-04)], [1],
    [QS-02], [Alta — a sobreposição dificulta a interação e F5 faz perder o acompanhamento e o acesso ao cancelamento; ideia indicativa da docência], [Média — além do cartão não bloqueante, exige estado persistido, consulta de recuperação, permissões e proteção do token de execução], [2],
    [QS-03], [Média — é um efeito colateral da fragmentação em processos distintos, não um objetivo autónomo da equipa], [Baixa — é obtida pela mesma decomposição do QS-01, sem trabalho adicional], [3],
  ),
)

== Atributos de qualidade por ordem de prioridade

+ Manutenibilidade → Modularidade (QS-01) — é o objetivo explícito do refactoring e condiciona a
  capacidade de responder ao outro cenário sem introduzir regressões.
+ Usabilidade → Operabilidade (QS-02) — é o segundo requisito da equipa: manter a interface utilizável e recuperar o acompanhamento após F5, com suporte de estado persistido no backend.
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
    [Usabilidade (operabilidade)], [Manutenibilidade (modularidade)], [Sinergia], [O DA-1 distribui a execução por estágios e o DA-2 reconstrói o acompanhamento a partir da API de estado. A sinergia depende de os eventos persistidos manterem token e progresso global coerentes. Os eventos Socket.IO, isoladamente, não validam essa integração; ver capítulo 10],
    [Usabilidade (operabilidade)], [Fiabilidade (recuperabilidade)], [Sinergia], [O estado durável permite reconstruir o acompanhamento após F5. A recuperação continua no CAND-2, sem criar outro candidato.],
    [Usabilidade (operabilidade)], [Fiabilidade (consistência do resultado)], [Conflito potencial mitigado], [A navegação fica livre, mas novas submissões e alterações de media/pipeline são recusadas durante a execução; o cancelamento valida o token ativo.],
    [Usabilidade (operabilidade)], [Eficiência de desempenho], [Custo adicional por avaliar], [A consulta de estado a cada 2 s e a persistência de progresso acrescentam pedidos e escritas. Não existe medição que permita classificá-los como custo nulo.],
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
    [Substituir a sobreposição por um cartão e recuperar o acompanhamento após F5 a partir do estado persistido da execução], [Usabilidade; suporte de recuperabilidade], [Interação frontend / API / projects], [Médio], [Médio — estados, permissões e cancelamento],
  ),
)

A terceira recomendação é a que apresenta maior risco e foi efetivamente onde a implementação
encontrou uma regressão: a separação dos workers, por si só, não preserva o comportamento dos
pipelines mistos. O detetado e a correção são descritos nos capítulos 8 e 10.
