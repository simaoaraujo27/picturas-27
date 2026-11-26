#import "../template.typ": *

// Capítulo inteiro na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Cenários de Entrada e Táticas Candidatas

Os cenários e os candidatos são os dos capítulos 5 e 6. A revisão documental completa o QS-02 com a recuperação após refresh já implementada, mantendo o mesmo identificador e distinguindo esse percurso da medição visual inicial.

== Candidatos e cenários de entrada

#tab([Candidatos e cenários de entrada],
  tabela(
    colunas: (1.8cm, 2.2cm, 3cm, 1.8cm, 2.8cm, 3cm, 3.4cm, 3.4cm),
    tamanho: 8pt,
    [Candidato], [Cenário (`QS-nn`)], [Característica / subcaracterística (ISO/IEC 25010)], [Evidência], [Origem (padrão global / vídeo / interação)], [Estímulo a que a tática reage], [Resposta e medida (resumo)], [Escala e método (cap. 6)],
    [CAND-1], [QS-01], [Manutenibilidade → Modularidade, Reutilizabilidade], [EV-01, EV-03, EV-04], [Padrão do vídeo, alinhado com o global], [Pedido para adicionar ou alterar um efeito de vídeo; falha de um worker], [Mudança confinada a um módulo; rebuild de uma imagem; falha isolada], [Ficheiros/serviços tocados; tamanho e build da imagem; Radon MI; isolamento],
    [CAND-2], [QS-02], [Usabilidade → Operabilidade], [EV-09 a EV-13], [Frontend / API / projects], [Continuar a usar a aplicação; fazer F5 ou reabrir o projeto durante uma execução], [Interface utilizável; recuperar o acompanhamento da execução existente e o acesso autorizado ao cancelamento], [Área obstruída; sucesso/falha da recuperação; tempos e pedidos apenas quando medidos (cap. 6)],
  ),
)

== Alterações feitas ao capítulo 5 (se existirem)

O QS-02 foi completado para incluir a recuperação após F5, já prevista na introdução e na ideia das diretrizes (EV-12). Mantêm-se os IDs e os valores da comparação visual. Acrescenta-se a tática TAT-09 para documentar o mecanismo de recuperação existente, sem alegar novas medições nem uma funcionalidade de pausa/retoma.

== Táticas candidatas

#tab([Táticas candidatas],
  tabela(
    colunas: (1.6cm, 1.8cm, 3.6cm, 3.4cm, 5cm, 3.4cm, 1.8cm),
    tamanho: 8pt,
    [ID], [Cenário], [Atributo → categoria], [Tática], [Como produz a resposta (estímulo → tática → resposta)], [Já existe na base? (evidência)], [Classe (A/B/C)],
    [TAT-01], [QS-01], [Manutenibilidade → modularizar], [Separar por domínio funcional], [Adicionar um efeito deixa de exigir compreender o código de legendagem e de extração: o domínio afetado é identificado pelo módulo que o contém], [Parcial — o global já separa ferramentas de imagem (EV-04); o vídeo é um monólito (EV-01)], [A],
    [TAT-02], [QS-01], [Manutenibilidade → reduzir acoplamento; Eficiência → gerir recursos], [Fila e contentor por domínio, com dependências isoladas], [Cada domínio tem o seu `requirements.txt` e a sua imagem: alterar um efeito leve reconstrói 1,09 GB em vez do monólito de 1,70 GB, e uma falha não arrasta os outros], [Parcial — uma fila e uma imagem para os três domínios (EV-02, EV-03)], [A],
    [TAT-03], [QS-01], [Manutenibilidade → controlar mudança; Fiabilidade → coordenar], [Compor os estágios no orquestrador, encadeando cada resposta em `project_queue`], [O orquestrador calcula os estágios do pipeline e despacha o seguinte quando o anterior responde; preserva a ordem dos efeitos mesmo quando pertencem a workers distintos], [Parcial — o despacho era feito num único envio ao worker monolítico (EV-05)], [A],
    [TAT-04], [QS-02], [Usabilidade → apoiar a iniciativa do sistema (indicar progresso e estado)], [Indicador de progresso não bloqueante, fixo no canto da página], [O estado e a barra de progresso continuam visíveis, mas deixam de cobrir a área de conteúdo: o utilizador mantém o controlo da aplicação durante o processamento], [Parcial — há barra de progresso e botão Cancelar, mas dentro de um ecrã sobreposto (EV-09)], [B],
    [TAT-05], [QS-01], [Manutenibilidade → preservar comportamento; Fiabilidade → observar], [Eventos de progresso agregados por estágio], [Cada worker reporta a sua fatia com `base`/`span`, preservando a continuidade do progresso que o worker monolítico emitia quando vários estágios passam a ser executados por serviços diferentes], [Parcial — o monólito emitia progresso, mas não agregado por estágio (EV-05)], [A],
    [TAT-06], [QS-02], [Usabilidade → apoiar a iniciativa do sistema (indicar progresso e estado)], [Indicador global no layout, com o estado do processamento partilhado], [O indicador acompanha o utilizador entre páginas, porque o estado deixa de pertencer à página do projeto], [Não — o `ProjectProvider` não guarda o estado de processamento e o indicador vive na página (EV-09)], [B],
    [TAT-07], [QS-02], [Usabilidade → apoiar a iniciativa do sistema (indicar progresso e estado)], [Notificação discreta (_toast_) com o estado], [A interface fica livre e o estado aparece como aviso temporário], [Parcial — o frontend já usa `useToast` para erros de sincronização (`frontend/providers/project-provider.tsx`)], [B],
    [TAT-09], [QS-02], [Usabilidade → manter acesso ao estado; suporte de recuperabilidade], [Persistir o estado da execução e reconstruir a interface por consulta ao backend], [F5/reabertura → GET de estado → recuperar token, progresso e permissão; o cancelamento valida a versão e `X-Process-Token`, sem novo Apply], [Não na base: estado local (EV-13). Implementada com `processingState` e `useGetProcessingStatus`], [B, com suporte interno de persistência],
  ),
)

As táticas do `CAND-1` são todas de classe A: não alteram o comportamento funcional, apenas a estrutura do processamento e a forma de coordenar os seus estágios. No `CAND-2`, TAT-04 e TAT-09 são escolhidas como alterações visíveis de classe B destinadas à operabilidade. O suporte de persistência permite voltar a observar e controlar a mesma execução; não acrescenta efeitos, pausa ou retoma do worker. TAT-06 e TAT-07 continuam como alternativas: manter um cartão em todas as páginas é diferente de recuperar o cartão quando a página do projeto volta a montar.
]
