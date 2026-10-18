#import "../template.typ": *

// 5.1 e 5.2 em páginas na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Especificação de Requisitos do Sistema (ERS)

#orientacao[
  Catálogo único dos requisitos de todas as funcionalidades de vídeo, ordenado por ID. A coluna *Origem* indica o
  caso de uso e o elemento de onde vem cada requisito (e.g., `UC-VID-001, passo 3`, `UC-VID-001/RN1`); um requisito comum a vários casos de uso (e.g.,
  `REQ-VID-SUBMIT-001`) aparece uma só vez, com todas as origens.
  Padrão: _O sistema deve [ação] [objeto] [condição/limite]_. Cada requisito é atómico, verificável,
  inequívoco, sem solução técnica e rastreável. Prioridade segundo MoSCoW (_Must_ / _Should_ / _Could_ / _Won't_).
  *Justificação*: porque é que o requisito é necessário. *Novo/Alt*: NOVO = não existia no PictuRAS;
  ALT = altera algo existente — nesse caso indiquem o elemento de base afetado (e.g., RF13, RNF48, UC04).
]

== Requisitos Funcionais

#tab([Requisitos funcionais],
  tabela(
    colunas: (3.2cm, 1fr, 1.5cm, 1.5cm, 2.6cm, 3.5cm, 4.2cm),
    tamanho: 8pt,
    [ID], [Requisito], [Prioridade], [Novo/ Alt], [Origem], [Justificação], [Critério de aceitação],

    [REQ-VID-TRIM-001],
    [O sistema deve carregar a interface de recorte de vídeo, apresentando o reprodutor multimédia, a linha temporal com a duração total do vídeo e os seletores de início e fim ($t_(i n)$ e $t_(o u t)$).],
    [#must], [NOVO], [UC-VID-001, Passo 1],
    [Interface primordial de interação para parametrização do intervalo temporal a recortar.],
    [Dado um vídeo válido na biblioteca, quando o utilizador seleciona a ferramenta de recorte, então a interface é carregada apresentando o reprodutor HTML5, a linha temporal e os seletores $t_(i n)$ e $t_(o u t)$.],

    [REQ-VID-TRIM-002],
    [O sistema deve atualizar dinamicamente a área selecionada na linha temporal e recalcular a duração resultante ($t_(o u t) - t_(i n)$) em tempo real à medida que os marcadores temporais são manipulados.],
    [#must], [NOVO], [UC-VID-001, Passo 2; RN3],
    [Fornece feedback visual contínuo e garante controlo temporal exato antes da submissão.],
    [Dado que os seletores temporais são deslocados na linha temporal, quando o utilizador altera $t_(i n)$ ou $t_(o u t)$, então a área destacada e o campo de duração são atualizados instantaneamente.],

    [REQ-VID-TRIM-003],
    [O sistema deve permitir ao utilizador reproduzir localmente no navegador exclusivamente o segmento compreendido entre $t_(i n)$ e $t_(o u t)$ antes de confirmar a operação, sem consumir quota de operações nem gerar pedidos de processamento ao servidor.],
    [#should], [NOVO], [UC-VID-001, FA1],
    [Reduz pedidos incorretos ao backend e poupa recursos computacionais e quotas do utilizador.],
    [Dado um intervalo $[t_(i n), t_(o u t)]$ parametrizado, quando o utilizador clica em "Pré-visualizar Excerto", então o reprodutor executa apenas esse intervalo sem chamadas de rede de transcodificação.],

    [REQ-VID-TRIM-004],
    [O sistema deve validar os instantes temporais submetidos, assegurando que $0 <= t_(i n) < t_(o u t) <= "duração do vídeo"$ e que a duração mínima do excerto $(t_(o u t) - t_(i n))$ é igual ou superior a 1.0 segundo.],
    [#must], [NOVO], [UC-VID-001, Passo 3; Exceção 2; RN3],
    [Impede o enfileiramento de operações temporalmente inconsistentes ou nulas.],
    [Dado um pedido de recorte com $t_(i n) >= t_(o u t)$ ou intervalo $< 1.0$ s, quando o utilizador submete a operação, então a submissão é bloqueada com mensagem de erro explícita e nenhuma quota é deduzida.],

    [REQ-VID-TRIM-005],
    [O sistema deve verificar o saldo da quota diária de operações do utilizador do perfil `free` antes de permitir a submissão, impedindo o enfileiramento se o limite de 5 operações diárias gratuitas (`FREE_DAILY_OP = 5`) tiver sido atingido.],
    [#must], [ALT (RF05)], [UC-VID-001, Passo 3; Exceção 4; RN1],
    [Assegura a aplicação das regras do modelo SaaS do PictuRAS para o nível gratuito.],
    [Dado um utilizador `free` com saldo de 0 operações no dia corrente, quando tenta submeter um recorte, então a operação é impedida com mensagem de quota esgotada e convite a upgrade para `premium`.],

    [REQ-VID-TRIM-006],
    [O sistema deve validar a duração máxima do excerto $(t_(o u t) - t_(i n))$ em função do perfil do utilizador, rejeitando pedidos com duração superior a 180 segundos para o perfil `free` ou superior a 60 minutos para o perfil `premium`.],
    [#must], [NOVO], [UC-VID-001, Passo 3; Exceção 3; RN2],
    [Limita o consumo excessivo de recursos de computação e diferencia o valor do plano pago.],
    [Dado um utilizador do perfil `free` que submete um excerto de 181 segundos, quando clica em confirmar, então o sistema recusa o pedido indicando o limite de 3 minutos para contas gratuitas.],

    [REQ-VID-TRIM-007],
    [O sistema deve debitar provisoriamente 1 operação da quota diária do utilizador do perfil `free` no momento exato em que a tarefa de recorte é aceite e enfileirada no backend.],
    [#must], [ALT (RF05)], [UC-VID-001, Passo 4; RN1],
    [Previne ataques de esgotamento de workers através de submissões simultâneas concorrentes acima do saldo.],
    [Dado um utilizador `free` com saldo de 5 operações, quando submete uma tarefa válida de recorte, então o seu saldo diário é imediatamente decrementado para 4 operações antes do arranque do processamento.],

    [REQ-VID-TRIM-008],
    [O sistema deve submeter a tarefa de recorte para a fila de mensagens assíncronas do backend, gerar e atribuir um identificador único de tarefa (_Job ID_) e direcionar a interface para o ecrã de acompanhamento.],
    [#must], [NOVO], [UC-VID-001, Passo 4, Passo 5; DQ-001],
    [Desacopla a requisição HTTP da execução pesada de transcodificação de vídeo.],
    [Dado um pedido de recorte validado com sucesso, quando a operação é confirmada, então a tarefa é publicada na fila RabbitMQ, um Job ID é retornado e o utilizador vê o estado "Em fila de espera".],

    [REQ-VID-TRIM-010],
    [O sistema deve extrair e recodificar os fotogramas e fluxos de áudio correspondentes estritamente ao intervalo $[t_(i n), t_(o u t)]$ do vídeo de entrada, preservando a taxa de fotogramas e a sincronização áudio/vídeo no ficheiro resultante.],
    [#must], [NOVO], [UC-VID-001, Passo 6; Pós-condição de sucesso],
    [Executa o processamento nuclear de recorte com exatidão temporal e integridade de mídia.],
    [Dado um vídeo válido de entrada, quando o worker conclui o recorte, então o vídeo gerado contém unicamente os fotogramas entre $t_(i n)$ e $t_(o u t)$ com desfasamento áudio/vídeo nulo.],

    [REQ-VID-TRIM-011],
    [O sistema deve disponibilizar ao utilizador com perfil `premium` a opção de "Recorte Rápido" (_stream copy_ sem recodificação), executando o corte quase instantaneamente quando os pontos selecionados coincidirem com fotogramas-chave (_keyframes_).],
    [#could], [NOVO], [UC-VID-001, FA2],
    [Reduz drasticamente o tempo de processamento para subscritores pagos em cenários compatíveis.],
    [Dado um utilizador `premium` com a opção "Recorte Rápido" ativada, quando o corte é submetido em keyframes viáveis, então o ficheiro é gerado por cópia direta de fluxos em poucos segundos.],

    [REQ-VID-TRIM-014],
    [O sistema deve registar o novo vídeo recortado na biblioteca permanente da conta do utilizador com os respetivos metadados (duração, resolução, proveniência e data) e disponibilizar ações de reprodução e descarregamento (_download_).],
    [#must], [NOVO], [UC-VID-001, Passo 7, Passo 8; Pós-condição de sucesso],
    [Entrega o valor da operação ao utilizador, permitindo a reutilização ou exportação do vídeo gerado.],
    [Dado o término com sucesso da renderização, quando a biblioteca é consultada, então o novo vídeo aparece catalogado na conta do utilizador com botão de download e reprodução funcionais.],

    [REQ-VID-TRIM-015],
    [O sistema deve assegurar a persistência e continuidade da tarefa assíncrona mesmo que o utilizador encerre a sessão ou feche o navegador, disponibilizando o vídeo final na biblioteca aquando da conclusão.],
    [#should], [NOVO], [UC-VID-001, FA3],
    [Garante que operações demoradas de vídeo não são abortadas por eventos acidentais no cliente.],
    [Dado uma tarefa em processamento no worker, quando o utilizador fecha o browser e regressa mais tarde, então visualiza o vídeo gravado com sucesso na biblioteca do projeto.],

    [REQ-VID-TRIM-016],
    [O sistema deve abortar o processamento, restabelecer a operação diária debitada (se perfil `free`) e apresentar mensagem de erro amigável caso o ficheiro de entrada apresente fluxos corrompidos ou formato incompatível.],
    [#must], [NOVO], [UC-VID-001, Exceção 6; Pós-condição garantia mínima; RN1],
    [Garante tratamento de falhas sem penalização indevida da quota do utilizador.],
    [Dado um ficheiro com pacotes danificados que originam erro no FFmpeg, quando o worker deteta a anomalia, então a tarefa passa a "Falhada", a quota diária é estornada e a mensagem de erro é exibida.],

    [REQ-VID-TRIM-019],
    [O sistema deve bloquear o acesso a ferramentas e operações de processamento de vídeo a utilizadores não autenticados (`anonymous`), exibindo mensagem de autenticação obrigatória e redirecionando para registo ou login.],
    [#must], [NOVO], [UC-VID-001, Pré-condições; FA4; RN7],
    [Protege os recursos dispendiosos de processamento de vídeo contra abusos por tráfego não identificado.],
    [Dado um utilizador sem sessão iniciada, quando tenta aceder ao endpoint ou interface de recorte de vídeo, então o acesso é barrado com código HTTP 401/403 e aviso de funcionalidade restrita.],

    [REQ-VID-TRIM-020],
    [O sistema deve gerar um registo de auditoria para cada tarefa de recorte finalizada (com sucesso, falha ou cancelamento), contendo o identificador do utilizador, Job ID, parâmetros $t_(i n)$/$t_(o u t)$, tempo de execução e estado final.],
    [#should], [NOVO], [UC-VID-001, Pós-condição de sucesso; DQ-003],
    [Permite rastreabilidade operacional, resolução de incidentes e contabilidade de uso na plataforma.],
    [Dado o término de uma tarefa de vídeo, quando o registo de log é persistido, então constam gravados o ID de utilizador, Job ID, carimbos temporais, parâmetros e código de terminação.],

    [REQ-VID-TRIM-021],
    [O sistema deve validar a quota de armazenamento da conta antes de persistir o novo vídeo na biblioteca, rejeitando a gravação e estornando a operação diária debitada caso o espaço total acumulado exceda 1 GB para `free` ou 5 GB para `premium`.],
    [#must], [ALT (RF06)], [UC-VID-001, Passo 3, Passo 7; Exceção 5; RN6],
    [Aplica as restrições de capacidade em disco do modelo de negócio SaaS da plataforma.],
    [Dado um utilizador `free` cuja gravação do novo excerto elevaria a sua biblioteca acima de 1 GB, quando a persistência é tentada, então a gravação é recusada com alerta de disco cheio e a operação diária é reposta.],

    [REQ-VID-TRIM-022],
    [O sistema deve permitir ao utilizador cancelar voluntariamente uma tarefa de recorte enquanto esta se encontrar em fila de espera ou em execução ativa, abortando o processamento no worker, estornando a quota diária debitada e eliminando artefactos intermédios.],
    [#must], [NOVO], [UC-VID-001, FA5; DQ-006],
    [Permite ao utilizador desistir de operações longas ou submetidas por engano sem perda de quota.],
    [Dado uma tarefa em fila ou em processamento, quando o utilizador clica em "Cancelar Processamento", então a tarefa passa a "Cancelada", o worker cessa a execução, ficheiros temporários são purgados e a quota é estornada.],

    [REQ-VID-TRIM-023],
    [O sistema deve reter os vídeos recortados na biblioteca do utilizador por tempo indeterminado enquanto o limite de quota de armazenamento da conta for respeitado, disponibilizando ao utilizador a funcionalidade de eliminação permanente de vídeos para libertação de espaço em disco.],
    [#must], [NOVO], [UC-VID-001, RN6; DQ-005],
    [Clarifica a política de persistência e expiração e concede ao utilizador o controlo sobre a sua quota.],
    [Dado um vídeo guardado na biblioteca do utilizador, quando o utilizador confirma a sua eliminação, então o ficheiro é permanentemente apagado e o espaço ocupado é subtraído ao total da sua conta.],

    [REQ-VID-TRIM-024],
    [O sistema deve apresentar na interface do utilizador autenticado a percentagem e o volume de espaço em disco atualmente ocupado na sua biblioteca em relação ao limite do seu perfil (1 GB em `free` / 5 GB em `premium`), atualizando o indicador após cada adição ou remoção de vídeo.],
    [#should], [NOVO], [UC-VID-001, Passo 1, Passo 7; RN6],
    [Oferece transparência sobre o consumo de capacidade da conta e previne bloqueios inesperados por excesso de quota.],
    [Dado um utilizador autenticado na aplicação, quando visualiza a biblioteca ou o diálogo de recorte, então a interface exibe uma barra de quota com os MB/GB utilizados e o limite máximo aplicável ao seu perfil.],
  ),
)

== Requisitos Não Funcionais e de Qualidade

#orientacao[
  Classifiquem segundo a ISO/IEC 25010 (Adequação Funcional, Eficiência de Desempenho, Compatibilidade,
  Usabilidade, Fiabilidade, Segurança, Manutenibilidade, Portabilidade). Indiquem o *Alvo*: o valor mensurável
  exigido a uma solução em produção. Prioridade segundo MoSCoW.
]

#tab([Requisitos não funcionais],
  tabela(
    colunas: (3.2cm, 1fr, 2.7cm, 2.8cm, 1.4cm, 2.2cm, 4.2cm),
    tamanho: 8pt,
    [ID], [Requisito], [ISO/IEC 25010], [Alvo], [Prioridade], [Origem], [Critério de aceitação],

    [REQ-VID-TRIM-009],
    [O sistema deve transmitir e atualizar no ecrã de acompanhamento o progresso percentual (0% a 100%) da tarefa de recorte durante o processamento ativo no worker.],
    [Usabilidade (Transparência de Estado)],
    [MVP: Consulta periódica (_polling_) a cada $<= 4$ s. \ Produção: WebSockets a cada $<= 1$ s com tempo estimado restante (ETA).],
    [#should], [UC-VID-001, Passo 5, Passo 6; DQ-001],
    [Dado uma tarefa em execução ativa no worker, quando o recorte progride, então o ecrã atualiza a percentagem de progresso com intervalo $<= 4$ s.],

    [REQ-VID-TRIM-012],
    [O sistema deve gerar o ficheiro resultante e garantir a aceitação de vídeos codificados estritamente em contentor MP4 com codecs de vídeo H.264 e de áudio AAC.],
    [Compatibilidade (Interoperabilidade)],
    [MVP: Exclusivo MP4 (H.264 / AAC) para ingestão e exportação. \ Produção: Suporte a WebM, MKV e MOV com transcodificação automática.],
    [#must], [UC-VID-001, Passo 7; RN4; DQ-004],
    [Dado o término de uma operação de recorte, quando o ficheiro gerado é inspecionado com `ffprobe`, então o formato é MP4 com streams `h264` e `aac`.],

    [REQ-VID-TRIM-013],
    [O sistema deve assegurar que o ficheiro de vídeo de entrada permanece rigorosamente inalterado em conteúdo, metadados e integridade na biblioteca após a execução do recorte.],
    [Fiabilidade (Integridade de Dados)],
    [MVP: Ficheiro original montado com permissões de apenas-leitura; verificação de integridade pós-execução. \ Produção: Object Storage imutável com versionamento.],
    [#must], [UC-VID-001, Passo 7; RN5; Pós-condições],
    [Dado um vídeo de origem com hash SHA-256 conhecido, quando a tarefa de recorte termina, então o hash do ficheiro original na biblioteca permanece rigorosamente idêntico.],

    [REQ-VID-TRIM-017],
    [O sistema deve reexecutar automaticamente a tarefa de recorte uma única vez caso ocorra terminação anómala do worker ou o tempo de execução ultrapasse o tempo limite de 10 minutos, marcando a tarefa como falhada e estornando a quota caso a falha persista.],
    [Fiabilidade (Recuperabilidade)],
    [MVP: 1 tentativa de repetição automática em timeout (> 10 min) ou falha de nó; após isso estado `FAILED` e estorno de quota. \ Produção: 3 tentativas com exponential backoff.],
    [#must], [UC-VID-001, Exceção 7; DQ-002],
    [Dado um worker deliberadamente terminado a meio do processamento, quando o monitor deteta a quebra, então a tarefa é reescalonada uma vez; persistindo a falha, o job passa a `FAILED` e a quota é reposta.],

    [REQ-VID-TRIM-018],
    [O sistema deve eliminar integralmente todos os fragmentos e ficheiros temporários gerados nos nós de processamento sempre que uma tarefa finalize com sucesso, falha ou cancelamento.],
    [Fiabilidade (Limpeza de Recursos)],
    [MVP: Eliminação síncrona da diretoria temporária `picturas-trim-*` no worker ao concluir a tarefa. \ Produção: Eliminação síncrona combinada com Garbage Collector autónomo.],
    [#must], [UC-VID-001, Pós-condição garantia mínima; DQ-005],
    [Dado o encerramento de um job de recorte, quando o worker finaliza, então o diretório temporário correspondente é integralmente purgado sem ficheiros residuais em disco.],

    [REQ-VID-TRIM-025],
    [O sistema deve confirmar a aceitação e o enfileiramento de um pedido de recorte de vídeo, retornando o Job ID à interface, em tempo não superior a 2.0 segundos, independentemente do tamanho do vídeo.],
    [Eficiência de Desempenho (Comportamento Temporal)],
    [MVP: Tempo de resposta HTTP da API de submissão $<= 2.0$ segundos no percentil 95 (p95). \ Produção: Tempo de resposta $<= 0.5$ s no p99.],
    [#should], [UC-VID-001, Passo 4, Passo 5; DQ-001],
    [Dado um pedido de recorte válido submetido via API, quando a chamada HTTP é disparada, então a resposta com o Job ID é recebida pelo cliente em menos de 2.0 s.],

    [REQ-VID-TRIM-026],
    [O sistema deve assegurar que o tempo total de processamento e recodificação de um excerto de vídeo não exceda 1.5 vezes a duração do excerto em nós de execução de referência ($T_("proc") <= 1.5 times (t_(o u t) - t_(i n))$).],
    [Eficiência de Desempenho (Eficiência de Processamento)],
    [MVP: Duração do processamento $<= 1.5 times$ tempo real do excerto em CPU padrão de 2 vCPUs (excerto de 60s em $<= 90$s). \ Produção: $<= 0.3 times$ com aceleração GPU (NVENC).],
    [#should], [UC-VID-001, Passo 6; DQ-002],
    [Dado um vídeo 1080p a 30 fps e um recorte de 60 segundos, quando processado no worker com FFmpeg, então o tempo entre a retirada da fila e o ficheiro final é $<= 90$ segundos.],

    [REQ-VID-TRIM-027],
    [O sistema deve restringir o acesso e reprodução dos vídeos carregados e recortados exclusivamente aos utilizadores autorizados do projeto, impedindo acesso anónimo ou enumeração pública de URLs.],
    [Segurança (Confidencialidade e Controlo de Acesso)],
    [MVP: Endpoints de reprodução protegidos por validação JWT e cookie HTTP-only temporário de 5 minutos com HTTP Range requests. \ Produção: URLs pré-assinados de curta duração em Object Storage privado.],
    [#must], [UC-VID-001, Pré-condições, Passo 8; DQ-003],
    [Dado um vídeo de um projeto privado, quando um utilizador sem permissões (ou visitante anónimo) tenta aceder ao URL de reprodução, então o sistema devolve o código HTTP 403 Forbidden.],

    [REQ-VID-TRIM-028],
    [O ambiente de execução do nó de processamento de vídeo deve encapsular as dependências externas e o binário de execução do FFmpeg de forma modular e isolada, sem dependência do sistema operativo anfitrião.],
    [Portabilidade (Isolamento Modular)],
    [MVP: Contentor Docker autónomo baseado em imagem Linux oficial com FFmpeg e Python pré-instalados. \ Produção: Orquestração Kubernetes com escalamento elétrico (KEDA).],
    [#must], [UC-VID-001, Âmbito; DQ-004],
    [Dado o arranque da plataforma via Docker Compose num nó de infraestrutura limpo, quando o contentor `video_trim_worker` é iniciado, então processa recortes sem configuração adicional no host.],
  ),
)
]

== Verificação da completude e dos limites do âmbito

#orientacao[
  Para cada caso de uso, avaliem os tópicos abaixo. "Não aplicável" ou "fora do âmbito" é aceitável quando
  justificado; isso não obriga a introduzir funcionalidades alheias ao caso de uso.
]

#tab([Verificação da completude],
  tabela(
    colunas: (4.2cm, 2cm, 1.5cm, 1fr, 2.8cm),
    tamanho: 8.5pt,
    [Tópico a verificar], [Caso de uso], [Aplicável?], [Decisão / justificação], [Requisito(s)],

    [Formato, _codec_, duração e dimensão do vídeo],
    [UC-VID-001],
    [Sim],
    [No MVP da Fase 1, o sistema suporta exclusivamente contentor MP4 com vídeo H.264 e áudio AAC, garantindo compatibilidade universal de reprodução em browsers HTML5 sem necessidade de remuxing no cliente. A duração do excerto está delimitada pelo perfil do utilizador (180s para `free` e 60 min para `premium`), e a dimensão máxima é governada pela quota global de armazenamento da biblioteca (1 GB para `free` e 5 GB para `premium`).],
    [REQ-VID-TRIM-004, REQ-VID-TRIM-006, REQ-VID-TRIM-012, REQ-VID-TRIM-016, REQ-VID-TRIM-021],

    [Estado, progresso, cancelamento e resultado],
    [UC-VID-001],
    [Sim],
    [O processamento de vídeo é demorado e assíncrono. O sistema gere o ciclo de vida completo da tarefa através dos estados formais: "Em fila de espera" (`QUEUED`), "A processar" (`PROCESSING`), "Concluído" (`COMPLETED`), "Falhado" (`FAILED`) e "Cancelado" (`CANCELLED`). A interface apresenta progresso percentual periódico, permite o cancelamento cooperativo pelo utilizador em qualquer instante antes do término e disponibiliza reprodução segura e download imediatos após o sucesso.],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-014, REQ-VID-TRIM-015, REQ-VID-TRIM-022, REQ-VID-TRIM-025],

    [Falhas durante o processamento],
    [UC-VID-001],
    [Sim],
    [Em caso de deteção de ficheiro danificado, codecs incompatíveis, término inesperado do worker ou timeout de execução (10 min), o sistema efetua uma reexecução automática idempotente; persistindo a falha, o job transita para estado `FAILED`, a quota de operações diárias provisoriamente debitada é estornada ao utilizador e todos os ficheiros residuais nos workers são eliminados.],
    [REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-018],

    [Persistência e expiração dos ficheiros],
    [UC-VID-001],
    [Sim],
    [Os ficheiros de vídeo de origem e de saída persistem na biblioteca do projeto por tempo indeterminado enquanto a sua quota de disco acumulada (1 GB em `free` / 5 GB em `premium`) não for excedida, cabendo ao utilizador a eliminação deliberada para libertação de espaço. Os ficheiros temporários intermédios em nós de processamento são purgados imediatamente após cada tarefa.],
    [REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024],

    [Perfis e contagem de operações],
    [UC-VID-001],
    [Sim],
    [Articulação estrita com o esquema de utilizadores do PictuRAS (`["anonymous", "free", "premium"]`): utilizadores anónimos estão totalmente bloqueados de aceder a ferramentas de vídeo; utilizadores `free` dispõem de 5 operações diárias gratuitas (`FREE_DAILY_OP = 5`), limite de 180s por recorte e 1 GB de disco; utilizadores `premium` dispõem de operações ilimitadas, recortes até 60 min, suporte a _stream copy_ e 5 GB de disco.],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-006, REQ-VID-TRIM-007, REQ-VID-TRIM-011, REQ-VID-TRIM-019, REQ-VID-TRIM-021],

    [Encadeamento de ferramentas e processamento em lote],
    [UC-VID-001],
    [Não],
    [No MVP da Fase 1, a ferramenta de recorte opera estritamente como uma ação atómica e individual sobre um único vídeo. O encadeamento sequencial de filtros de vídeo com transformações de imagem existentes e o processamento de múltiplos vídeos em lote (via `.zip`) introduziriam elevada sobrecarga de orquestração assíncrona que desvirtuaria a validação funcional do MVP, ficando formalmente diferidos para fases posteriores.],
    [Fora do âmbito do MVP],
  ),
)
