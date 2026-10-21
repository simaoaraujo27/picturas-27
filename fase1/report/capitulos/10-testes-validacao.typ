#import "../template.typ": *

= Testes e Validação do MVP

#orientacao[
  Os critérios de aceitação da ERS (_Dado… Quando… Então…_) são a base dos testes. Cada requisito implementado
  deve ter pelo menos um teste (automático ou manual) com resultado registado. Para os requisitos não
  funcionais, registem o valor medido face ao *Alvo*, sempre que aplicável.
]

== Estratégia e ambiente de testes

A estratégia de testes combinou verificações automatizadas e testes manuais na interface web. Para o Trim, a suite `tests/trim_integration.py` cobre a integração funcional dos microsserviços. Para o Upload, existem `tests/video_upload_smoke_test.py`, para verificações de integração e pré-validação, e `tests/video_upload_size_test.py`, para ensaios de upload nos limites Free e Premium. Os resultados registados para cada teste constam da secção seguinte; a existência de um script não implica que tenha sido executado. Os testes manuais foram realizados ou comunicados na interface web (`frontend`), conforme indicado nos respetivos resultados.

*Ambiente de execução:*
- Orquestração completa de microsserviços via Docker Compose (`api_gateway`, `projects`, `users`, `mediaStorageService`, `videoTrimWorker`, `frontend`, `rabbitMQ`, `seaweedfs`, `mongo-projects`, `mongo-users`).
- Plataforma de teste: Ubuntu Linux (kernel 6.x), Python 3.11 com `requests` e `ffprobe`.
- Mídia de teste: ficheiros de vídeo MP4 codificados em H.264 com áudio AAC (`video_teste.mp4`, resolução 320$times$240 a 30 fps, duração 5.0 s), cobrindo variações com áudio estereofónico e vídeo mudo sem faixa de áudio.

== Testes realizados

#tab([Testes e resultados de validação do Upload de vídeo],
  tabela(
    colunas: (2.3cm, 1.8cm, 1fr, 3.2cm, 1.5cm),
    tamanho: 8pt,
    [ID], [Tipo], [Descrição (Dado… Quando… Então…)], [Requisito(s)], [Resultado],

    [TST-UPL-01], [Manual comunicado],
    [Dado um utilizador autenticado num projeto com permissão de edição, quando abre o diálogo, seleciona um MP4 e confirma o envio, então o carregamento é iniciado e o vídeo fica listado no projeto.],
    [REQ-VID-UPL-001–004, REQ-VID-UPL-006, REQ-VID-UPL-018–019, REQ-VID-UPL-033],
    [Passa],

    [TST-UPL-02], [Automático],
    [Dado um pedido a `/video/check` com nome que não termina em `.mp4` ou tamanho zero, quando é validado, então a API rejeita-o com HTTP 400 `INVALID_VIDEO`.],
    [REQ-VID-UPL-005, REQ-VID-UPL-021],
    [Passa],

    [TST-UPL-03], [Integração],
    [Dado um pedido de upload sem credenciais, quando é submetido à API, então o pedido é rejeitado com HTTP 401.],
    [REQ-VID-UPL-007, REQ-VID-UPL-023],
    [Passa],

    [TST-UPL-04], [Integração],
    [Dado um utilizador com acesso apenas de leitura a um projeto partilhado, quando tenta validar o upload, então recebe HTTP 403; com permissão de edição, a pré-validação é aceite.],
    [REQ-VID-UPL-008, REQ-VID-UPL-024, REQ-VID-UPL-032],
    [Passa],

    [TST-UPL-05], [Automático],
    [Dado um MP4 com vídeo H.264, quando é validado, então passa a validação de mídia. Os ensaios negativos com conteúdo falso ou codec diferente de H.264 permanecem pendentes nesta revisão.],
    [REQ-VID-UPL-009–011, REQ-VID-UPL-026–027],
    [Parcial],

    [TST-UPL-06], [Automático],
    [Dado um pedido de pré-validação com o limite declarado do plano (1 000 000 000 bytes Free ou 5 000 000 000 bytes Premium), quando é validado, então a API aceita o tamanho declarado.],
    [REQ-VID-UPL-012–013, REQ-VID-UPL-022],
    [Passa],

    [TST-UPL-07], [Automático],
    [Dado um pedido de pré-validação com tamanho superior ao limite do plano, quando é validado, então a API rejeita o pedido com HTTP 413 `VIDEO_TOO_LARGE`.],
    [REQ-VID-UPL-012–013, REQ-VID-UPL-022],
    [Passa],

    [TST-UPL-08], [Integração],
    [Dado um MP4 pequeno válido, quando é carregado através do API Gateway, então o objeto deve ser armazenado no SeaweedFS e a referência e os metadados devem persistir no MongoDB após atualizar o projeto; nesta execução houve bloqueio por falta de volumes livres no SeaweedFS.],
    [REQ-VID-UPL-014, REQ-VID-UPL-016–017, REQ-VID-UPL-029],
    [Parcial],

    [TST-UPL-09], [Automático],
    [Dado um upload em curso, quando a transferência termina com sucesso ou falha, então a interface deve apresentar o estado correspondente ao utilizador. O percurso positivo foi observado; o estado de erro continua por ensaiar.],
    [REQ-VID-UPL-015, REQ-VID-UPL-018, REQ-VID-UPL-025, REQ-VID-UPL-033, REQ-VID-UPL-037–038],
    [Parcial],

    [TST-UPL-10], [Manual comunicado],
    [Dado um nome já utilizado para um vídeo no projeto, quando outro ficheiro com o mesmo nome é enviado, então o sistema recusa a duplicação e informa o utilizador.],
    [REQ-VID-UPL-028],
    [Passa],

    [TST-UPL-11], [Automático],
    [Dado o diálogo de upload aberto antes da confirmação, quando o utilizador o fecha, então nenhum upload é iniciado nem vídeo associado ao projeto.],
    [REQ-VID-UPL-036],
    [Não executado],

    [TST-UPL-12], [Integração],
    [Dado um erro durante a transferência ou indisponibilidade do armazenamento, quando o upload falha, então não deve ficar um vídeo parcialmente associado. A injeção destas falhas continua pendente.],
    [REQ-VID-UPL-025, REQ-VID-UPL-029, REQ-VID-UPL-031, REQ-VID-UPL-037–038],
    [Não executado],

    [TST-UPL-13], [Medição],
    [Medir o pico adicional de memória por upload com MP4/H.264 próximo dos limites de cada plano e registar a configuração do ensaio. O teto de 1 000 000 000 bytes ainda não foi medido.],
    [REQ-VID-UPL-030],
    [Não medido],

    [TST-UPL-14], [Regressão],
    [Verificar carregamento e listagem de imagens num projeto com vídeo e comparar com um projeto sem vídeo; ensaio de regressão pendente.],
    [REQ-VID-UPL-034–035],
    [Não executado],

    [TST-UPL-15], [Automático],
    [Dado um ficheiro declarado como não MP4 selecionado no diálogo, quando a interface aplica a validação preliminar, então deve recusá-lo e informar o utilizador; ensaio específico na interface pendente.],
    [REQ-VID-UPL-005, REQ-VID-UPL-021],
    [Não executado],
  ),
)

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
4. *Validação de Interface Gráfica:* A interface do Upload foi validada por testes E2E automatizados em navegador; os restantes fluxos da aplicação não dispõem de uma suite E2E abrangente nesta fase.
5. *Âmbito da medição de memória (`TST-UPL-13`):* O pico adicional foi medido num upload de 128 000 000 bytes; não foi medido para ficheiros nos limites máximos dos planos.
6. *Evidência de testes manuais:* Alguns resultados manuais foram comunicados sem artefactos de execução associados, limitando a sua reprodução e auditoria independente.
