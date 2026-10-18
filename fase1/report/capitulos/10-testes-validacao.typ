#import "../template.typ": *

= Testes e Validação do MVP

#orientacao[
  Os critérios de aceitação da ERS (_Dado… Quando… Então…_) são a base dos testes. Cada requisito implementado
  deve ter pelo menos um teste (automático ou manual) com resultado registado. Para os requisitos não
  funcionais, registem o valor medido face ao *Alvo*, sempre que aplicável.
]

== Estratégia e ambiente de testes

A estratégia de testes do MVP de vídeo assentou na validação funcional ponta a ponta (_end-to-end_) e de integração dos microsserviços através da suite automatizada desenvolvida em Python (`tests/trim_integration.py`), complementada por testes manuais na interface gráfica web (`frontend`).

*Ambiente de execução:*
- Orquestração completa de microsserviços via Docker Compose (`api_gateway`, `projects`, `users`, `mediaStorageService`, `videoTrimWorker`, `frontend`, `rabbitMQ`, `seaweedfs`, `mongo-projects`, `mongo-users`).
- Plataforma de teste: Ubuntu Linux (kernel 6.x), Python 3.11 com `requests` e `ffprobe`.
- Mídia de teste: ficheiros de vídeo MP4 codificados em H.264 com áudio AAC (`video_teste.mp4`, resolução 320$times$240 a 30 fps, duração 5.0 s), cobrindo variações com áudio estereofónico e vídeo mudo sem faixa de áudio.

== Testes realizados

#tab([Testes e resultados de validação do Trim],
  tabela(
    colunas: (2.3cm, 1.8cm, 1fr, 3.2cm, 1.5cm),
    tamanho: 8pt,
    [ID], [Tipo], [Descrição (Dado… Quando… Então…)], [Requisito(s)], [Resultado],

    [TST-TRIM-01],
    [Manual],
    [Dado um vídeo carregado, quando a ferramenta de recorte é aberta, então a interface exibe o player, marcadores temporais e duração resultante dinâmica.],
    [REQ-VID-TRIM-001, REQ-VID-TRIM-002],
    [Passa],

    [TST-TRIM-02],
    [Manual],
    [Dado um intervalo parametrizado, quando o utilizador clica em pré-visualizar, então o browser executa apenas o intervalo sem gerar pedidos ao servidor.],
    [REQ-VID-TRIM-003],
    [Passa],

    [TST-TRIM-03],
    [Automático],
    [Dado um pedido com $t_(i n) >= t_(o u t)$ ou intervalo $< 1.0$ s, quando submetido a `POST /trim`, então a API devolve HTTP 400 com código `INVALID_INTERVAL`.],
    [REQ-VID-TRIM-004, REQ-VID-TRIM-006],
    [Passa],

    [TST-TRIM-04],
    [Automático],
    [Dado um utilizador `free`, quando submete 5 operações de recorte, então a quota decrementa até 0 e a 6.ª tentativa é bloqueada com `DAILY_QUOTA_EXHAUSTED`.],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-007],
    [Passa],

    [TST-TRIM-05],
    [Automático],
    [Dado um pedido válido, quando submetido, então recebe HTTP 202 com Job ID e o polling reflete as transições `QUEUED` $->$ `PROCESSING` $->$ `COMPLETED`.],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-020, REQ-VID-TRIM-025],
    [Passa],

    [TST-TRIM-06],
    [Automático],
    [Dado um pedido de corte de 1.25s a 3.75s (duração 2.5s), quando concluído, então o MP4 gerado tem 2.52s, codecs H.264/AAC e metadados no projeto.],
    [REQ-VID-TRIM-010, REQ-VID-TRIM-012, REQ-VID-TRIM-014, REQ-VID-TRIM-026],
    [Passa],

    [TST-TRIM-07],
    [Automático],
    [Dado um corte rápido Premium, quando os pontos coincidem com keyframes, então conclui com sucesso; quando desalinhados, rejeita com erro explícito.],
    [REQ-VID-TRIM-011],
    [Passa],

    [TST-TRIM-08],
    [Automático],
    [Dado um vídeo de entrada com hash SHA-256 medido, quando o recorte é finalizado, então o hash do vídeo original na biblioteca permanece rigorosamente idêntico.],
    [REQ-VID-TRIM-013],
    [Passa],

    [TST-TRIM-09],
    [Automático],
    [Dado um erro simulado no worker, quando o processamento falha, então a tarefa passa a `FAILED` e a operação diária Free é atomicamente estornada.],
    [REQ-VID-TRIM-016, REQ-VID-TRIM-017],
    [Passa],

    [TST-TRIM-10],
    [Automático],
    [Dado o término de uma tarefa, quando o worker finaliza, então a pasta temporária `/tmp/picturas-trim-*` é confirmada vazia sem ficheiros residuais.],
    [REQ-VID-TRIM-018],
    [Passa],

    [TST-TRIM-11],
    [Automático],
    [Dado um utilizador não autenticado ou com permissão apenas de leitura (`read`), quando tenta aceder a `/trim`, então a API devolve HTTP 401 ou 403 `EDIT_REQUIRED`.],
    [REQ-VID-TRIM-019, REQ-VID-TRIM-027],
    [Passa],

    [TST-TRIM-12],
    [Automático],
    [Dado um vídeo recortado adicionado, quando o endpoint `/storage` é consultado e o vídeo é eliminado via `DELETE`, então o espaço ocupado é subtraído da quota.],
    [REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024],
    [Passa],

    [TST-TRIM-13],
    [Automático],
    [Dado um job em fila de espera (`QUEUED`), quando o utilizador emite `DELETE /jobs/:jobId`, então passa a `CANCELLED` e a quota debitada é reposta.],
    [REQ-VID-TRIM-022],
    [Passa],

    [TST-TRIM-14],
    [Automático],
    [Dado um vídeo privado, quando acedido com cookie temporário via `GET /play`, então responde com HTTP 206 Partial Content (Range bytes=0-99).],
    [REQ-VID-TRIM-027],
    [Passa],

    [TST-TRIM-15],
    [Automático],
    [Dado o comando `docker compose build video_trim_worker`, quando o contentor arranca na rede do Compose, então consome mensagens sem erros no host.],
    [REQ-VID-TRIM-028],
    [Passa],
  ),
)

== Limitações e defeitos conhecidos

No âmbito da validação do MVP da Fase 1, assumem-se de forma transparente as seguintes limitações técnicas:
1. *Notificações fora de página (`REQ-VID-TRIM-015` parcial):* Se o utilizador fechar o navegador durante o processamento, o vídeo é guardado com sucesso na biblioteca do projeto, mas não existe ainda um mecanismo de notificação global na plataforma (push notification) que alerte o utilizador no regresso.
2. *Métricas quantitativas de desempenho em carga (`REQ-VID-TRIM-025` e `026` parciais):* O tempo de resposta da submissão é inferior a 200 ms em testes locais e um recorte de 2.5s demora cerca de 1.2s ($0.48 times$ tempo real). Contudo, não foram realizados testes sistemáticos de percentil p95 sob concorrência nem medições formais com ficheiros pesados de 1080p a 60 fps e duração de 60 minutos.
3. *Identificador de Job:* O sistema utiliza atualmente identificadores nativos `ObjectId` do MongoDB em vez de identificadores `UUIDv4` estritos.
4. *Validação de Interface Gráfica:* A interface web foi validada manualmente e a compilação do Next.js passou com sucesso; não foi implementada uma suite automatizada de testes E2E de interface (e.g., Cypress/Playwright) nesta fase.
