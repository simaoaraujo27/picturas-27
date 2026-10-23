#import "../template.typ": *

= Manutenção Corretiva da Solução de Base

#orientacao[
  Problemas encontrados na solução de base durante o estudo e a integração do vídeo (erros, incoerências com o
  documento de requisitos, dificuldades de execução). Indiquem se foram corrigidos nesta fase. Capítulo
  recomendado; removam-no se não houver nada a registar.
]

Durante o estudo da _baseline_ e a integração da extensão de vídeo, foram identificados e resolvidos diversos defeitos e constrangimentos na infraestrutura herdada:

#tab([Tarefas de manutenção corretiva da baseline],
  tabela(
    colunas: (1.2cm, 1fr, 2.4cm, 1.6cm, 2.5cm, 1.8cm),
    tamanho: 8.5pt,
    [ID], [Descrição do problema], [Impacto], [Prioridade], [Rel. Req.], [Estado],

    [T-01],
    [Mapeamento de volumes do frontend no Docker Compose gerava inconsistências de dependências e erros de compilação TypeScript no Next.js.],
    [Execução / Ambiente],
    [Alta],
    [REQ-VID-TRIM-001],
    [Corrigido],

    [T-02],
    [Presença de contentor de exemplo legado concorrendo pela mesma fila RabbitMQ com contrato de dados incompatível.],
    [Fiabilidade / Concorrência],
    [Alta],
    [REQ-VID-TRIM-008],
    [Corrigido],

    [T-03],
    [O `apiGateway` não encaminhava corretamente pedidos HTTP Range e cookies de autorização para o streaming de mídia em `/video/:videoId/play`.],
    [Funcional / Segurança],
    [Alta],
    [REQ-VID-UNI-002],
    [Corrigido],

    [T-04],
    [A gestão de quota `FREE_DAILY_OP` no serviço `users` não dispunha de reserva transacional atómica, suscetível a corridas críticas em pedidos paralelos.],
    [Integridade de Negócio],
    [Média],
    [REQ-VID-UNI-005, REQ-VID-UNI-006],
    [Corrigido],

    [T-05],
    [O serviço de projetos calculava apenas espaço ocupado por imagens, sem contabilização nem teto de armazenamento para ficheiros de vídeo.],
    [Gestão de Recursos],
    [Média],
    [REQ-VID-UNI-007, REQ-VID-TRIM-024],
    [Corrigido],
  ),
)
