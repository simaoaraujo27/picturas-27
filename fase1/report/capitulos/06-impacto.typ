#import "../template.typ": *

= Impacto no Sistema Existente

#orientacao[
  Que elementos do PictuRAS existente (perfis, quotas, armazenamento, biblioteca, encadeamento, lote,
  exportação, …) e do documento de requisitos de base (UCnn, RFnn, RNFnn) são afetados pelas funcionalidades
  de vídeo. Para cada elemento: *Manter* (fica igual), *Estender* (passa a fazer mais) ou *Alterar* (muda o
  comportamento atual). Incluam todos os requisitos ALT e os NOVO que interagem com mecanismos existentes.
  Se duas funcionalidades afetam o mesmo elemento de forma diferente, há uma inconsistência a resolver aqui.
]

#tab([Impacto no sistema existente],
  tabela(
    colunas: (3.6cm, 1.8cm, 1fr, 2.2cm, 3.2cm),
    tamanho: 8.5pt,
    [Elemento existente afetado], [Impacto], [Descrição do impacto], [Caso(s) de uso], [Requisitos],

    [Quota diária de operações (Tier `free`: `FREE_DAILY_OP`) (RF05)],
    [Alterar],
    [No PictuRAS existente (`users`), o saldo de 5 operações diárias aplicava-se exclusivamente a imagens síncronas. Com o vídeo, 1 operação de recorte consome 1 unidade de `FREE_DAILY_OP` com mecanismo transacional assíncrono: reserva provisória na submissão e estorno automático em caso de falha de processamento, quota de disco excedida ou cancelamento pelo utilizador.],
    [UC-VID-001],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-021, REQ-VID-TRIM-022],

    [Sistema de Perfis e Controlo de Acessos (`userSchema`) (RF01)],
    [Estender],
    [O modelo `["anonymous", "free", "premium"]` é estendido para bloquear ferramentas de vídeo a utilizadores anónimos, aplicar tetos de duração de excerto por perfil autenticado (180s para `free`, 60 min para `premium`), autorizar _stream copy_ a clientes `premium` e fiscalizar limites de armazenamento em disco.],
    [UC-VID-001],
    [REQ-VID-TRIM-006, REQ-VID-TRIM-011, REQ-VID-TRIM-019, REQ-VID-TRIM-021, REQ-VID-TRIM-024, REQ-VID-TRIM-027],

    [Serviço de Armazenamento e Biblioteca (`mediaStorageService` / SeaweedFS) (RF06)],
    [Alterar],
    [Evolução para suportar contentores MP4 pesados e contabilização ativa de quota em disco por conta: teto de 1 GB para `free` e 5 GB para `premium`. Rejeição de novas gravações quando o limite é excedido e suporte à eliminação permanente de vídeos pelo utilizador para libertação de espaço.],
    [UC-VID-001],
    [REQ-VID-TRIM-012, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024],

    [Infraestrutura de Mensajeria e Filas (`rabbitMQ`)],
    [Estender],
    [Criação de canal e fila dedicados ao processamento assíncrono de vídeo (`video_trim_queue`), isolando o tráfego pesado dos workers de imagem existentes, com garantia de entrega e suporte a cancelamento cooperativo.],
    [UC-VID-001],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-010, REQ-VID-TRIM-017, REQ-VID-TRIM-022, REQ-VID-TRIM-025],

    [Interface Gráfica Web (`frontend`) (UC02, UC03)],
    [Estender],
    [Integração de reprodutor de vídeo HTML5, linha temporal interativa com seleção de $t_(i n)$/$t_(o u t)$, pré-visualização local no cliente, barra de quota de armazenamento em disco, ecrã de acompanhamento de jobs assíncronos com botão de cancelamento e modal de encaminhamento para login/registo.],
    [UC-VID-001],
    [REQ-VID-TRIM-001, REQ-VID-TRIM-002, REQ-VID-TRIM-003, REQ-VID-TRIM-009, REQ-VID-TRIM-019, REQ-VID-TRIM-022, REQ-VID-TRIM-024],

    [Nós de Execução e _Workers_ de Processamento],
    [Estender],
    [Implementação do novo microsserviço `videoTrimWorker` em Python com binário nativo FFmpeg, contentorizado de forma autónoma via Docker, com isolamento em diretoria de trabalho efémera e purga garantida de fragmentos temporários pós-execução.],
    [UC-VID-001],
    [REQ-VID-TRIM-010, REQ-VID-TRIM-012, REQ-VID-TRIM-018, REQ-VID-TRIM-026, REQ-VID-TRIM-028],

    [Encadeamento de Ferramentas (_Pipelines_) e Lote (UC06, UC07)],
    [Manter],
    [O subsistema de encadeamento e processamento em lote via ficheiro `.zip` permanece inalterado no MVP, mantendo-se restrito a imagens e sem interferência com o pipeline atómico de recorte de vídeo.],
    [UC-VID-001],
    [Fora do âmbito do MVP],
  ),
)
