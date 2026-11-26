#import "../template.typ": *

= Conclusões e Recomendações

== Adequação do padrão atual (global e do vídeo)

O padrão global do PictuRAS — microserviços, comunicação assíncrona por filas duráveis e ficheiros em volume partilhado/S3 — mostrou-se adequado para a extensão de vídeo: é ele que permite evoluir ferramentas de imagem e de vídeo sem reescrever o orquestrador (EV-04). O problema não estava no padrão, mas no desvio do caminho de vídeo em relação a ele (capítulo 3). Ao concentrar efeitos, legendagem e extração de fotogramas num único serviço, uma fila e um `requirements.txt` com IA (EV-01, EV-02, EV-03), a solução de base sacrificou modularidade e isolamento de falhas sem ganho equivalente. A ALT-2 (capítulo 4) aproximou o vídeo do padrão global sem o alterar e foi a decisão implementada.

A decomposição por domínio atingiu o objetivo do CAND-1 na métrica principal: o caminho de efeitos deixou de carregar Faster-Whisper e a imagem a reconstruir passou de 1,70 GB para 1,09 GB. Ficou claro, porém, que separar os workers não basta: a coordenação das etapas teve de passar para o orquestrador, e foi nessa fronteira que a regressão dos pipelines mistos apareceu. A correção (`1fe42ba`) e a sua cobertura de integração (`85b99d4`) são parte da decisão, não acessórios dela — a lição é que o _refactoring_ de uma arquitetura orientada a eventos tem de ser avaliado pelo comportamento ponta a ponta, não apenas pela estrutura resultante.

== Sugestões de otimização

#tab([Sugestões de otimização resultantes da experiência],
  tabela(
    colunas: (3.4cm, 4cm, 1fr, 2.6cm),
    tamanho: 8.5pt,
    [Sugestão], [Atributo favorecido], [Razão / evidência nesta fase], [Prioridade sugerida],
    [Medir o tempo de build limpo por worker de forma sistemática], [Eficiência → Comportamento temporal; Manutenibilidade], [O tamanho da imagem é uma boa aproximação do custo de manutenção; o tempo de build fecha a medição, mas não foi recolhido de forma comparável nas duas variantes], [Média],
    [Especificar contratos de mensagem versionados entre o orquestrador e os três workers], [Manutenibilidade → Modificabilidade; Fiabilidade], [O bug dos pipelines mistos mostrou que a composição de etapas é um ponto de coordenação frágil; um contrato explícito reduz o risco de nova regressão], [Média],
    [Adicionar ensaios de caos por domínio ao conjunto de regressão], [Fiabilidade → Tolerância a falhas], [O isolamento da legendagem foi verificado uma vez; repeti-lo por worker e com o broker a reiniciar cobre os cenários de recuperação já identificados como risco conhecido], [Baixa],
    [Partilhar uma imagem base entre os três workers, mantendo `requirements.txt` separados], [Eficiência → Utilização de recursos; Manutenibilidade], [A partilha de camadas comuns pode reduzir o espaço físico ocupado pelas três imagens], [Baixa],
  ),
)

== Considerações para evolução futura

A separação permite escalar a legendagem e atualizar o modelo do Whisper sem
reconstruir o worker de efeitos. O contrato do lote, o esquema de resultados e o
progresso entre estágios são fronteiras a verificar quando se alterar a
coordenação.

A campanha mais recente comparou a aplicação de base `0523102` com `b8f44b3`.
Em carga mista, ambas entregaram 115 cortes/min na janela. No pico de 45 s, o p95
até ao resultado baixou de 15,64–17,27 s para 8,64–9,30 s. O pico de 75 s também
foi executado e o p95 baixou de 13,42–13,68 s para 9,56–10,26 s. Os dois perfis de
pico tiveram zero timeouts e um resultado íntegro por pedido aceite. A comparação
abrange as revisões completas.

Dos 158 casos funcionais comparáveis, 155 passaram nas duas versões na primeira
execução. Os dois casos Playwright que falharam, edição e descarga de imagem e
partilha de leitura, passaram na repetição isolada de 26 de novembro. O caso de
remoção de fundo também passou numa repetição isolada. Os testes
automáticos de recuperação apresentaram falhas de preparação e de descoberta.
Assim, o objetivo estrutural do CAND-1 está sustentado, com o critério funcional
estrito ainda por demonstrar na totalidade.

== Trabalho futuro

O ensaio de isolamento de legendagem cobre a falha de um worker específico. O
ensaio de reinício do broker voltou a registar falta de recuperação do consumo
dentro do prazo de 90 s. Ficam por concluir os testes automáticos de recuperação
e a medição comparável do tempo de build
limpo. A implementação e a avaliação do segundo RNF estão em curso pela equipa.
