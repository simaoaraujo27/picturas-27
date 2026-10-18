# 📝 Dossiê de Requisitos do Sistema — Exercício 2
### Especificação de Requisitos do Sistema (ERS) · Fase 1: Suporte a Vídeo no PictuRAS

---

## 0. Identificação

| **Campo** | **Valor** |
|-----------|-----------|
| **Grupo / Equipa** | Por atribuir |
| **Autores** | Simão Araújo |
| **Data** | 2026-10-14 |
| **Versão do documento** | v2.0 |
| **Unidade Curricular** | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |

---

## 1. Funcionalidade de vídeo escolhida

| **Campo** | **Valor** |
|-----------|-----------|
| **Funcionalidade** | Recorte temporal de vídeo (*Trim*) |
| **Perfil(s) de utilizador abrangido(s)** | Funcionalidade exclusiva para utilizadores registados e autenticados no PictuRAS (`userSchema`):<br>- **`free` (Utilizador Registado Gratuito):** Quota diária de 5 operações avançadas (`FREE_DAILY_OP = 5`), limite de armazenamento em disco de **1 GB** na biblioteca e duração máxima de 180s por excerto.<br>- **`premium` (Subscritor Pago):** Operações diárias ilimitadas, limite alargado de armazenamento em disco de **5 GB** na biblioteca e duração de excerto até 60 minutos.<br>*Nota sobre o perfil Convidado (`anonymous`):* Utilizadores sem conta estão restritos exclusivamente a ferramentas básicas de edição de imagem; o acesso a ferramentas de vídeo é bloqueado a utilizadores anónimos, sendo-lhes solicitada a criação de conta gratuita (`free`) ou autenticação. |

**Justificação no contexto do MVP** *(2–3 linhas)*
O recorte temporal (*trim*) é a operação atómica e primordial na manipulação de vídeo digital, permitindo ao utilizador descartar segmentos irrelevantes e reduzir significativamente o volume de dados armazenados e transferidos. No contexto do MVP da Fase 1, esta funcionalidade é a mais crítica a construir porque valida de ponta a ponta o novo pipeline assíncrono do PictuRAS (ingestão de ficheiros pesados, parametrização temporal, enfileiramento de tarefas, execução em workers com FFmpeg e entrega do artefacto gerado), servindo de base arquitetural indispensável para qualquer ferramenta ou encadeamento posterior.

---

## 2. Caso de Uso

### 2.1 Cabeçalho

| **Secção** | **Detalhes** |
|------------|--------------|
| **ID do Caso de Uso** | UC-VID-001 |
| **Nome** | Recortar Intervalo Temporal de Vídeo (*Trim*) |
| **Versão** | v1.1 (atualizado na Aula 02) |
| **Autor** | Simão Araújo |
| **Data** | 2026-10-14 |
| **Objetivo** | Permitir ao utilizador isolar um excerto contínuo de um vídeo através da definição de instantes inicial e final, gerando um novo ficheiro de vídeo correspondente exclusivamente a esse intervalo. |
| **Âmbito** | Módulo de Processamento de Vídeo do PictuRAS — Serviço de Manipulação de Mídia e Gestão de Tarefas (*Video Worker*) |
| **Ator Principal** | Utilizador Registado Gratuito (tier: `free`), sendo igualmente aplicável a Subscritor Pago (tier: `premium`) com capacidades alargadas. Utilizadores não registados (tier: `anonymous`) são impedidos de aceder ao processamento de vídeo e encaminhados para a criação de conta. |
| **Stakeholders e Interesses** | - **Utilizador**: Pretende isolar rapidamente excertos de vídeo relevantes sem perda de qualidade e com controlo temporal preciso.<br>- **Proprietário do Sistema (SaaS)**: Quer rentabilizar a plataforma fazendo cumprir o modelo de negócio (quotas diárias de 5 operações e limite de 1 GB no nível gratuito `free`, incentivando a subscrição `premium` com 5 GB e operações ilimitadas), controlando os custos de computação e armazenamento na cloud e prevenindo o abuso de recursos pesados por utilizadores anónimos.<br>- **Equipa de Desenvolvimento/Operações**: Pretende validar a arquitetura assíncrona orientada a filas de mensagens para processamento demorado de vídeo sem bloquear a interface web nem degradar os serviços existentes de processamento de imagem. |
| **Pré-condições** | - O utilizador encontra-se autenticado com sessão ativa num dos perfis registados (`free` ou `premium`). Utilizadores não autenticados (`anonymous`) não têm acesso à funcionalidade.<br>- O utilizador dispõe de quota de operações diárias disponível (no perfil `free`, saldo > 0 da quota de 5 operações diárias; no perfil `premium`, ilimitado).<br>- O utilizador dispõe de espaço disponível na quota de armazenamento da sua conta (limite de 1 GB para `free` e 5 GB para `premium`).<br>- O vídeo de entrada foi carregado com sucesso ou já se encontra disponível na biblioteca do utilizador.<br>- O ficheiro de vídeo está no formato de contentor suportado no MVP (MP4 com codecs de vídeo H.264 e áudio AAC). |
| **Trigger** | O utilizador autenticado seleciona um vídeo na plataforma e escolhe a opção **Recortar vídeo (Trim)**. |

### 2.2 Fluxo Principal

| **Passo** | **Ação do Ator** | **Resposta do Sistema** |
|-----------|------------------|-------------------------|
| 1 | O utilizador autenticado seleciona um vídeo carregado na biblioteca e ativa a ferramenta **Recortar vídeo (Trim)** | Carrega os metadados do vídeo e apresenta a interface de recorte com reprodutor, linha temporal (*timeline*), duração total, indicador de espaço ocupado na biblioteca e controlos de início e fim ($t_{in}$ e $t_{out}$) |
| 2 | O utilizador ajusta os marcadores temporais definindo o instante inicial ($t_{in}$) e o instante final ($t_{out}$) do segmento | Atualiza a linha temporal destacando a área a preservar e atualiza em tempo real os campos numéricos e a duração resultante ($t_{out} - t_{in}$) |
| 3 | O utilizador confirma a operação clicando em **Confirmar Recorte** | Valida os parâmetros temporais ($0 \le t_{in} < t_{out} \le \text{duração}$), verifica o saldo de quota diária de operações (se perfil `free`), os limites de duração e a disponibilidade de espaço na quota de armazenamento da conta (1 GB para `free` e 5 GB para `premium`) |
| 4 | — | Deduz provisoriamente 1 operação da quota diária do utilizador (se perfil `free`) e submete uma tarefa assíncrona de processamento para a fila de execução |
| 5 | — | Gera e atribui um identificador único de tarefa (*Job ID*) e apresenta o ecrã de acompanhamento em estado "Em fila de espera" com botão de cancelamento disponível |
| 6 | — | O worker retira a tarefa da fila, inicia o recorte com recodificação de fotogramas e transmite atualizações periódicas de progresso percentual (0% a 100%) |
| 7 | — | O worker conclui a renderização do excerto, valida a integridade do ficheiro de saída e guarda o novo vídeo no armazenamento da biblioteca, somando o espaço em disco ocupado à quota da conta |
| 8 | — | Notifica o utilizador da conclusão com sucesso, disponibiliza a pré-visualização do vídeo recortado, a opção de descarregar (*download*) e adiciona o vídeo à biblioteca permanente |

### 2.3 Fluxos Alternativos

| **Fluxo** | **Descrição** |
|-----------|---------------|
| FA1 – Pré-visualização local antes de submeter | No Passo 2, o utilizador clica em **Pré-visualizar Excerto**. O sistema reproduz diretamente no navegador apenas o intervalo entre $t_{in}$ e $t_{out}$ recorrendo aos controlos de reprodução do browser, sem submeter tarefa ao servidor nem consumir quota de operações. O utilizador pode reajustar os marcadores antes de prosseguir para o Passo 3. |
| FA2 – Recorte rápido sem recodificação (*Stream Copy*) | No Passo 3, caso o utilizador disponha de perfil `premium` e ative a opção "Recorte Rápido (em keyframes)", o sistema verifica a viabilidade de efetuar cópia direta de fluxos de vídeo/áudio sem transcodificação. A operação é concluída em poucos segundos no Passo 6 e o sistema transita de imediato para o Passo 8. |
| FA3 – Utilizador sai da página durante o processamento | No Passo 5 ou 6, o utilizador fecha o separador ou navega para outra secção da aplicação. O processamento assíncrono continua no servidor; aquando da conclusão, o sistema emite uma notificação interna na plataforma e adiciona automaticamente o vídeo final à biblioteca da conta do utilizador. |
| FA4 – Tentativa de acesso por utilizador não autenticado (*anonymous*) | No Passo 1, caso um utilizador não autenticado tente aceder à ferramenta de recorte de vídeo, o sistema impede a visualização da ferramenta, exibe uma mensagem informativa (*"O processamento de vídeo requer uma conta PictuRAS. Crie uma conta gratuita (free) com 5 operações diárias e 1 GB de armazenamento ou inicie sessão para continuar."*) e redireciona o utilizador para o formulário de registo/login. |
| FA5 – Cancelamento voluntário da tarefa pelo utilizador | No Passo 5 ou 6, o utilizador clica em **Cancelar Processamento** no ecrã de acompanhamento. O sistema envia um sinal de interrupção ao worker, cancela a tarefa, elimina de imediato quaisquer artefactos intermédios ou parciais, estorna a operação debitada na quota diária do utilizador (se tier `free`) e apresenta a confirmação de cancelamento bem-sucedido. |

### 2.4 Exceções

| **Condição** | **Comportamento do Sistema** |
|--------------|------------------------------|
| Utilizador não autenticado tenta executar operação de vídeo | No Passo 1 ou 3, o sistema rejeita a operação e apresenta a mensagem: *"Funcionalidade exclusiva para utilizadores registados. Por favor crie uma conta gratuita ou inicie sessão."*, encaminhando o utilizador para o ecrã de registo. |
| Instantes temporais inválidos ($t_{in} \ge t_{out}$ ou $t_{out} > \text{duração do vídeo}$) | No Passo 3, o sistema bloqueia o pedido, sinaliza os controlos com erro e apresenta a mensagem: *"O instante final deve ser estritamente superior ao inicial e não pode exceder a duração total do vídeo."* O fluxo regressa ao Passo 2 sem deduzir quota. |
| Duração do excerto excede o limite do perfil de utilização | No Passo 3, se o intervalo $(t_{out} - t_{in})$ exceder o limite do perfil (ex.: > 180s em `free`), o sistema recusa a submissão e apresenta a mensagem: *"A duração do excerto excede o limite de 3 minutos permitido para o seu perfil. Reduza o intervalo ou efetue upgrade para Premium."* |
| Quota diária de operações esgotada | No Passo 3, se o utilizador `free` já tiver consumido as 5 operações diárias gratuitas (`FREE_DAILY_OP = 5`), o sistema impede a submissão e exibe o alerta: *"Atingiu o limite diário de 5 operações gratuitas. Faça upgrade para Premium para utilização ilimitada ou tente novamente amanhã."* |
| Quota de armazenamento em disco esgotada na biblioteca | No Passo 3 ou 7, se o espaço restante na conta for insuficiente para acomodar o novo vídeo (ultrapassando 1 GB no perfil `free` ou 5 GB no perfil `premium`), o sistema bloqueia a operação, estorna a quota diária debitada e apresenta a mensagem: *"Espaço de armazenamento insuficiente: a sua biblioteca atingiu o limite de quota da conta (1 GB para free / 5 GB para Premium). Elimine vídeos existentes ou subscreva o plano Premium para obter 5 GB."* |
| Ficheiro de vídeo com codec ou fluxo corrompido | No Passo 6, o worker deteta inconsistências severas nos pacotes de vídeo ou um formato/codec não suportado. O sistema cancela a tarefa, estorna a operação deduzida da quota do utilizador e apresenta a mensagem: *"Não foi possível processar o vídeo: fluxo de dados ilegível ou formato incompatível."* |
| Falha do worker ou timeout no processamento assíncrono | No Passo 6, se o nó de processamento falhar ou o tempo de execução ultrapassar o tempo limite estabelecido (10 min), o sistema tenta reexecutar uma vez. Persistindo a falha, a tarefa passa a estado "Falhada", a quota consumida é devolvida ao utilizador e é apresentada a mensagem: *"Ocorreu um erro inesperado no processamento do vídeo. A sua quota diária foi restabelecida. Por favor tente novamente."* |

### 2.5 Pós-condições

| **Tipo** | **Resultado** |
|----------|---------------|
| Garantia de Sucesso | - É gerado um novo ficheiro de vídeo MP4 contendo unicamente os fotogramas e áudio situados no intervalo $[t_{in}, t_{out}]$, com sincronização A/V preservada.<br>- O vídeo de origem permanece rigorosamente intacto na biblioteca.<br>- O novo vídeo é registado na biblioteca permanente da conta com metadados descritivos (duração, resolução, data) e o espaço ocupado é somado à conta respeitando os limites de 1 GB (`free`) e 5 GB (`premium`).<br>- A quota diária de operações do utilizador `free` é efetivamente debitada em 1 unidade (saldo de `FREE_DAILY_OP` decrementado).<br>- É criado um registo de auditoria com os parâmetros de corte, tempos de processamento e identificador do utilizador. |
| Garantia Mínima | - O vídeo de origem não sofre qualquer modificação ou degradação.<br>- Quaisquer ficheiros parciais ou temporários criados nos workers são integralmente eliminados.<br>- As quotas de operações e de armazenamento do utilizador não são debitadas (ou são estornadas caso tenham sido provisionadas).<br>- É apresentada ao utilizador uma mensagem compreensível com a causa da falha e o estado da sua conta. |

### 2.6 Regras de Negócio e Restrições

| **ID** | **Regra** |
|--------|-----------|
| RN1 | **Contabilização de Quotas Diárias por Perfil (`userSchema`):** Alinhado com o modelo do PictuRAS (`["anonymous", "free", "premium"]`):<br>- Perfil `free`: Quota diária de 5 operações avançadas (`FREE_DAILY_OP = 5`). Cada recorte concluído com sucesso consome exatamente 1 operação. Se o processamento falhar por razões técnicas ou quota de disco excedida, a operação consumida é automaticamente reposta.<br>- Perfil `premium`: Utilização ilimitada sem teto diário de operações. |
| RN2 | **Limites de Duração de Excerto por Perfil Autenticado:** A duração máxima do vídeo resultante $(t_{out} - t_{in})$ está limitada por perfil: `free` $\le 180$ segundos (3 minutos); `premium` até à duração máxima suportada pela plataforma de 60 minutos (1 hora). |
| RN3 | **Precisão e Duração Mínima:** Os instantes $t_{in}$ e $t_{out}$ devem possuir precisão mínima de centésimos de segundo. O intervalo mínimo permitido é de 1.0 segundo ($(t_{out} - t_{in}) \ge 1.0$ s) para prevenir a criação de excertos nulos ou vazios. |
| RN4 | **Formatos e Codecs Suportados no MVP (MP4):** No âmbito do MVP da Fase 1, o sistema suporta exclusivamente ficheiros encapsulados em formato MP4 com codec de vídeo H.264 e codec de áudio AAC, tanto para ingestão como para exportação. Esta restrição assegura compatibilidade universal nativa de reprodução web em conformidade com as normas HTML5 e evita a sobrecarga de transcodificação ou remuxing no browser. |
| RN5 | **Não Destrutividade:** A operação de recorte nunca substitui nem sobrescreve o ficheiro de vídeo original. Produz sempre um novo artefacto multimédia independente. |
| RN6 | **Quotas de Armazenamento em Disco por Perfil:**<br>- Perfil `free`: Quota máxima de armazenamento em disco de **1 GB** associada à conta.<br>- Perfil `premium`: Quota alargada de armazenamento em disco de **5 GB** associada à conta.<br>O sistema bloqueia a submissão e gravação de novos ficheiros sempre que o somatório do tamanho dos vídeos armazenados na conta do utilizador exceda a respetiva quota máxima (1 GB ou 5 GB). Os ficheiros são mantidos na biblioteca por tempo indeterminado até serem explicitamente eliminados pelo utilizador. |
| RN7 | **Autenticação Obrigatória para Ferramentas de Vídeo:** O acesso a ferramentas de vídeo é exclusivo a utilizadores com conta registada (`free` ou `premium`). Utilizadores não autenticados (`anonymous`) apenas dispõem de ferramentas básicas de edição de imagem, sendo estritamente impedidos de executar tarefas de vídeo e direcionados para a criação de conta gratuita. |

### 2.7 Assunções e Decisões de Qualidade

| **ID** | **Assunção / Decisão de Qualidade** |
|--------|------------------------------------|
| A1 | O nó de execução (*worker*) possui acesso direto ou via streaming de alta velocidade ao armazenamento onde o vídeo original reside, sem necessitar de carregar o ficheiro integralmente para a memória RAM. |
| A2 | A infraestrutura dispõe de workers com suporte a FFmpeg compilado para descodificação e recodificação dos codecs H.264 e AAC em contentor MP4 com desempenho aceitável. |
| A3 | O navegador do utilizador suporta nativamente a reprodução de vídeo MP4 (H.264/AAC) em HTML5 com aceleração de hardware para a funcionalidade de pré-visualização local. |
| A4 | A taxa de fotogramas (*frame rate*) mantém-se constante ao longo do vídeo de entrada (CFR - *Constant Frame Rate*), evitando problemas de dessincronização de áudio e vídeo após o corte. |
| DQ-001 | **Desacoplamento Assíncrono com Filas Dedicadas:** O processamento de vídeo é executado de forma estritamente assíncrona através de filas dedicadas no RabbitMQ, isolando o tráfego pesado de vídeo das operações leves de imagem existentes e garantindo a responsividade da API. |
| DQ-002 | **Resiliência e Idempotência sem Retoma Parcial no MVP:** Em caso de quebra do worker ou timeout de execução (10 min), o sistema tolera a falha através de uma reexecução idempotente do job do início. A retoma a partir de checkpoints parciais é diferida para a Fase 2 (produção). |
| DQ-003 | **Segurança e Acesso Restrito a Artefactos Multimédia:** Os vídeos carregados e recortados estão protegidos por regras de autorização no backend; nenhum recurso multimédia é servido através de URLs públicos ou enumeráveis sem autenticação de sessão do proprietário. |
| DQ-004 | **Modularidade e Isolamento via Contentorização:** O microsserviço de recorte e as dependências nativas (FFmpeg) são isolados num contentor Docker autónomo, garantindo portabilidade entre ambientes de desenvolvimento e produção sem impactar os nós de imagem. |
| DQ-005 | **Retenção Efêmera em Workers e Quotas Persistentes na Biblioteca:** Nós de computação operam sobre volumes temporários purgados após cada tarefa; na biblioteca, os ficheiros persistem indefinidamente dentro dos tetos estritos de 1 GB (`free`) e 5 GB (`premium`). |
| DQ-006 | **Cancelamento Ativo pelo Utilizador:** É disponibilizado um mecanismo de cancelamento cooperativo que sinaliza o worker para terminar o processo FFmpeg, libertar recursos intermédios e repor a quota debitada. |

### 2.8 Questões em Aberto

| **ID** | **Questão** | **Estado / Resolução no Exercício 2** |
|--------|-------------|----------------------------------------|
| Q1 | Deve ser oferecida ao utilizador a opção explícita de escolher entre "Recorte Preciso" (com recodificação, *frame-accurate*, mais lento) e "Recorte Rápido" (sem recodificação, alinhado aos *keyframes*, quase instantâneo mas menos exato)? | **Resolvido:** No MVP, o utilizador `premium` dispõe da opção de recorte rápido (FA2 / REQ-VID-TRIM-011), enquanto o utilizador `free` utiliza o recorte preciso por defeito. |
| Q2 | Se o utilizador pretender substituir o vídeo original pelo excerto recortado para economizar a sua quota de espaço em disco, o sistema deve disponibilizar essa opção destrutiva com dupla confirmação? | **Aberto para Fase 2:** Mantém-se o princípio da não-destrutividade estrita (RN5) no MVP para prevenir perda acidental de dados; a substituição destrutiva poderá ser avaliada como melhoria futura. |
| Q3 | Deve ser disponibilizado aos utilizadores não autenticados um vídeo de exemplo pré-carregado apenas para experimentação visual da interface antes de exigirem o registo de conta? | **Aberto para Fase 2:** No MVP optou-se pela proteção estrita de recursos computacionais (RN7), exigindo registo para qualquer interação com vídeo. |
| Q4 | O suporte a contentores adicionais (ex.: MKV, WebM) e codecs modernos (VP9, AV1) deve ser introduzido em fases posteriores ao MVP? | **Resolvido para o MVP:** Excluído do MVP (limitado a MP4 H.264/AAC conforme RN4 e REQ-VID-TRIM-012); identificado como meta explícita para o alvo de produção na ERS. |

---

## 3. Utilização de agentes de IA

| **Ferramenta / *skill*** | **Tarefa apoiada** | **Validação realizada pela equipa** |
|--------------------------|--------------------|--------------------------------------|
| Antigravity (Gemini 3.8 Flash) | **Exercício 1:** Estruturação e redação inicial do caso de uso de recorte de vídeo (*Trim*), estruturação do fluxo assíncrono, identificação de exceções específicas de vídeo e definição de regras de negócio para compatibilização *brownfield*. | Revisão e validação manual por parte de Simão Araújo; ajuste dos limites de quota e tempos de duração para garantir coerência com as restrições da Fase 1 e modelo SaaS do PictuRAS; verificação da consistência entre pré-condições, exceções e pós-condições. |
| Antigravity (Gemini 3.8 Flash) | **Exercício 1:** Derivação sistemática dos Requisitos de Sistema (Tabela 4.1), análise de impacto na arquitetura existente do PictuRAS (Tabela 4.2), construção da Matriz de Rastreabilidade (Tabela 4.3), refinamento de formato (MP4/H.264/AAC), harmonização com os tiers da base de dados (`userSchema`: `["anonymous", "free", "premium"]`), limites de `FREE_DAILY_OP = 5`, quotas de armazenamento em disco de 1 GB (`free`) e 5 GB (`premium`), e aplicação de controlo de acessos estrito bloqueando utilizadores convidados (`anonymous`) de ferramentas de vídeo com exigência de autenticação (RN7). | Verificação manual da conformidade de cada requisito com os 5 testes de qualidade (atomicidade, verificabilidade, inequívoco, sem solução técnica, rastreabilidade); validação da integridade de quotas de operações diárias e de espaço em disco (1 GB / 5 GB); garantia de autenticação obrigatória para vídeo com encaminhamento de anónimos para registo gratuito; verificação de ausência de requisitos órfãos e cobertura de 100% dos elementos do caso de uso. |
| Antigravity (Gemini 3.8 Flash) | **Exercício 2:** Estruturação completa da Especificação de Requisitos do Sistema (ERS): segregação estrita entre requisitos funcionais (4.1.1) e de qualidade (4.1.2), classificação ISO/IEC 25010 com metas numéricas mensuráveis distinguindo Alvo MVP e Alvo Produção, especificação de requisitos de cancelamento (REQ-VID-TRIM-022) e gestão de armazenamento (REQ-VID-TRIM-023 e 024), verificação formal dos limites do âmbito (4.1.3), formalização das decisões de qualidade (DQ-001 a DQ-006) e expansão da matriz de rastreabilidade (4.3). | Revisão manual exaustiva por Simão Araújo; confirmação da preservação de todos os IDs da baseline v1.5; validação dos limiares de desempenho e usabilidade com base na capacidade de CPU em ambiente de desenvolvimento; verificação da ausência de ambiguidades nos critérios de aceitação Given-When-Then. |

---

## 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-001 — Recortar Intervalo Temporal de Vídeo (*Trim*)  
**Versão do dossiê:** v2.0  
**Baseline do Exercício 1:** Dossiê v1.5 (IDs: `REQ-VID-TRIM-001` a `REQ-VID-TRIM-021`)

---

### 4.1 Requisitos da ERS

#### 4.1.1 Requisitos Funcionais

A tabela seguinte inclui os requisitos funcionais derivados no Exercício 1 (preservando os IDs originais e clarificando a sua evolução) e os novos requisitos acrescentados para cobrir integralmente o serviço dentro do âmbito do recorte de vídeo (cancelamento, gestão e retenção de armazenamento).

| **ID** | **Requisito** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **REQ-VID-TRIM-001** | O sistema deve carregar a interface de recorte de vídeo, apresentando o reprodutor multimédia, a linha temporal com a duração total do vídeo e os seletores de início e fim ($t_{in}$ e $t_{out}$). | Deve ter | Mantido | NOVO | UC-VID-001, Passo 1 | Interface primordial de interação para parametrização do intervalo a recortar. | **Dado** um vídeo válido na biblioteca, **quando** o utilizador seleciona a ferramenta de recorte, **então** a interface é carregada apresentando o reprodutor HTML5, a linha temporal e os seletores $t_{in}$ e $t_{out}$. |
| **REQ-VID-TRIM-002** | O sistema deve atualizar dinamicamente a área selecionada na linha temporal e recalcular a duração resultante ($t_{out} - t_{in}$) em tempo real à medida que os marcadores temporais são manipulados. | Deve ter | Mantido | NOVO | UC-VID-001, Passo 2; RN3 | Fornece feedback visual contínuo e garante controlo temporal exato antes da submissão. | **Dado** que os seletores temporais são deslocados na linha temporal, **quando** o utilizador altera a posição de $t_{in}$ ou $t_{out}$, **então** a área destacada e o campo de duração resultante são atualizados instantaneamente com precisão de centésimos de segundo. |
| **REQ-VID-TRIM-003** | O sistema deve permitir ao utilizador reproduzir localmente no navegador exclusivamente o segmento compreendido entre $t_{in}$ e $t_{out}$ antes de confirmar a operação, sem consumir quota de operações nem gerar pedidos de processamento ao servidor. | Deveria ter | Mantido | NOVO | UC-VID-001, FA1 | Reduz pedidos incorretos ao backend e poupa recursos computacionais e quotas do utilizador. | **Dado** um intervalo $[t_{in}, t_{out}]$ parametrizado, **quando** o utilizador clica em "Pré-visualizar Excerto", **então** o reprodutor local executa apenas esse intervalo sem emitir chamadas de rede ao worker nem debitar quota diária. |
| **REQ-VID-TRIM-004** | O sistema deve validar os instantes temporais submetidos, assegurando que $0 \le t_{in} < t_{out} \le \text{duração do vídeo}$ e que a duração mínima do excerto $(t_{out} - t_{in})$ é igual ou superior a 1.0 segundo. | Deve ter | Mantido | NOVO | UC-VID-001, Passo 3; Exceção 1; RN3 | Impede o enfileiramento de operações temporalmente inconsistentes ou nulas. | **Dado** um pedido de recorte com $t_{in} \ge t_{out}$ ou $(t_{out} - t_{in}) < 1.0$ s, **quando** o utilizador submete a operação, **então** a submissão é bloqueada com mensagem de erro explícita e nenhuma quota é deduzida. |
| **REQ-VID-TRIM-005** | O sistema deve verificar o saldo da quota diária de operações do utilizador do perfil `free` antes de permitir a submissão, impedindo o enfileiramento se o limite de 5 operações diárias gratuitas (`FREE_DAILY_OP = 5`) tiver sido atingido. | Deve ter | Mantido | ALT | UC-VID-001, Passo 3; Exceção 3; RN1 | Assegura a aplicação das regras do modelo SaaS do PictuRAS para o nível gratuito. | **Dado** um utilizador `free` com saldo de 0 operações no dia corrente, **quando** tenta submeter um recorte, **então** a operação é impedida com mensagem de quota esgotada e convite a upgrade para `premium`. |
| **REQ-VID-TRIM-006** | O sistema deve validar a duração máxima do excerto $(t_{out} - t_{in})$ em função do perfil do utilizador, rejeitando pedidos com duração superior a 180 segundos para o perfil `free` ou superior a 60 minutos para o perfil `premium`. | Deve ter | Mantido | NOVO | UC-VID-001, Passo 3; Exceção 2; RN2 | Limita o consumo excessivo de recursos de computação e diferencia o valor do plano pago. | **Dado** um utilizador do perfil `free` que submete um excerto de 181 segundos, **quando** clica em confirmar, **então** o sistema recusa o pedido indicando o limite de 3 minutos para contas gratuitas. |
| **REQ-VID-TRIM-007** | O sistema deve debitar provisoriamente 1 operação da quota diária do utilizador do perfil `free` no momento exato em que a tarefa de recorte é aceite e enfileirada no backend. | Deve ter | Mantido | ALT | UC-VID-001, Passo 4; RN1 | Previne ataques de esgotamento de workers através de submissões simultâneas concorrentes acima do saldo. | **Dado** um utilizador `free` com saldo de 5 operações, **quando** submete uma tarefa válida de recorte, **então** o seu saldo diário é imediatamente decrementado para 4 operações antes do arranque do processamento. |
| **REQ-VID-TRIM-008** | O sistema deve submeter a tarefa de recorte para a fila de mensagens assíncronas do backend, gerar e atribuir um identificador único de tarefa (*Job ID*) e direcionar a interface para o ecrã de acompanhamento. | Deve ter | Refinado | NOVO | UC-VID-001, Passo 4, Passo 5; DQ-001 | Desacopla a requisição HTTP da execução pesada de transcodificação de vídeo. | **Dado** um pedido de recorte validado com sucesso, **quando** a operação é confirmada, **então** a tarefa é publicada na fila RabbitMQ, um *Job ID* UUID é retornado e o utilizador vê o estado "Em fila de espera". |
| **REQ-VID-TRIM-010** | O sistema deve extrair e recodificar os fotogramas e fluxos de áudio correspondentes estritamente ao intervalo $[t_{in}, t_{out}]$ do vídeo de entrada, preservando a taxa de fotogramas e a sincronização áudio/vídeo no ficheiro resultante. | Deve ter | Mantido | NOVO | UC-VID-001, Passo 6; Pós-condição de sucesso | Executa o processamento nuclear de recorte com exatidão temporal e integridade de mídia. | **Dado** um vídeo válido de entrada, **quando** o worker conclui o recorte, **então** o vídeo gerado contém unicamente os fotogramas entre $t_{in}$ e $t_{out}$ com desfasamento de áudio/vídeo nulo. |
| **REQ-VID-TRIM-011** | O sistema deve disponibilizar ao utilizador com perfil `premium` a opção de "Recorte Rápido" (*stream copy* sem recodificação), executando o corte instantaneamente quando os pontos selecionados coincidirem com fotogramas-chave (*keyframes*). | Poderia ter | Mantido | NOVO | UC-VID-001, FA2 | Reduz drasticamente o tempo de processamento para subscritores pagos em cenários compatíveis. | **Dado** um utilizador `premium` com a opção "Recorte Rápido" ativada, **quando** o corte é submetido em keyframes viáveis, **então** o ficheiro é gerado por cópia direta de fluxos em poucos segundos. |
| **REQ-VID-TRIM-014** | O sistema deve registar o novo vídeo recortado na biblioteca permanente da conta do utilizador com os respetivos metadados (duração, resolução, tamanho e data) e disponibilizar ações de reprodução e descarregamento (*download*). | Deve ter | Mantido | NOVO | UC-VID-001, Passo 7, Passo 8; Pós-condição de sucesso | Entrega o valor da operação ao utilizador, permitindo a reutilização ou exportação do vídeo gerado. | **Dado** o término com sucesso da renderização, **quando** a biblioteca é consultada, **então** o novo vídeo aparece catalogado na conta do utilizador com botão de download e pré-visualização funcionais. |
| **REQ-VID-TRIM-015** | O sistema deve assegurar a persistência e continuidade da tarefa assíncrona mesmo que o utilizador encerre a sessão ou feche o navegador, emitindo uma notificação na plataforma aquando da conclusão. | Deveria ter | Mantido | NOVO | UC-VID-001, FA3 | Garante que operações demoradas de vídeo não são abortadas por eventos acidentais no frontend. | **Dado** uma tarefa em processamento no worker, **quando** o utilizador fecha o browser e reabre a aplicação após a conclusão, **então** visualiza a notificação de sucesso e o vídeo gravado na sua biblioteca. |
| **REQ-VID-TRIM-016** | O sistema deve abortar o processamento, restabelecer a operação diária debitada (se perfil `free`) e apresentar mensagem de erro amigável caso o ficheiro de entrada apresente fluxos corrompidos ou formato incompatível. | Deve ter | Mantido | NOVO | UC-VID-001, Exceção 4a; Pós-condição garantia mínima; RN1 | Garante tratamento de falhas sem penalização indevida da quota do utilizador. | **Dado** um ficheiro com pacotes danificados que originam erro no FFmpeg, **quando** o worker deteta a anomalia, **então** a tarefa transita para "Falhada", a quota diária é estornada e a mensagem de erro é exibida. |
| **REQ-VID-TRIM-019** | O sistema deve bloquear o acesso a ferramentas e operações de processamento de vídeo a utilizadores não autenticados (`anonymous`), exibindo mensagem de autenticação obrigatória e redirecionando para registo ou login. | Deve ter | Mantido | NOVO | UC-VID-001, Pré-condições; FA4; RN7 | Protege os recursos dispendiosos de processamento de vídeo contra abusos por tráfego não identificado. | **Dado** um utilizador sem sessão iniciada, **quando** tenta aceder ao endpoint ou interface de recorte de vídeo, **então** o acesso é barrado com aviso de funcionalidade restrita e link para criação de conta gratuita. |
| **REQ-VID-TRIM-020** | O sistema deve gerar um registo de auditoria para cada tarefa de recorte finalizada (com sucesso, falha ou cancelamento), contendo o identificador do utilizador, *Job ID*, parâmetros $t_{in}$/$t_{out}$, tempo de execução e estado final. | Deveria ter | Mantido | NOVO | UC-VID-001, Pós-condição de sucesso; DQ-003 | Permite rastreabilidade operacional, resolução de incidentes e contabilidade de uso na plataforma. | **Dado** o término de uma tarefa de vídeo, **quando** o registo de log é persistido, **então** constam gravados o ID de utilizador, *Job ID*, carimbos temporais, parâmetros e código de terminação. |
| **REQ-VID-TRIM-021** | O sistema deve validar a quota de armazenamento da conta antes de persistir o novo vídeo na biblioteca, rejeitando a gravação e estornando a operação diária debitada caso o espaço total acumulado exceda 1 GB para `free` ou 5 GB para `premium`. | Deve ter | Mantido | ALT | UC-VID-001, Passo 3, Passo 7; Exceção 4b; RN6 | Aplica as restrições de capacidade em disco do modelo de negócio SaaS da plataforma. | **Dado** um utilizador `free` cuja gravação do novo excerto elevaria a sua biblioteca acima de 1 GB, **quando** a persistência é tentada, **então** a gravação é recusada com alerta de disco cheio e a operação diária é reposta. |
| **REQ-VID-TRIM-022** | O sistema deve permitir ao utilizador cancelar voluntariamente uma tarefa de recorte enquanto esta se encontrar em fila de espera ou em execução ativa, abortando o processamento no worker, estornando a quota diária debitada e eliminando artefactos intermédios. | Deve ter | Novo | NOVO | UC-VID-001, FA5; DQ-006 | Permite ao utilizador desistir de operações longas ou submetidas por engano sem perda de quota. | **Dado** uma tarefa em estado "Em fila de espera" ou "A processar", **quando** o utilizador clica em "Cancelar Processamento", **então** a tarefa passa a "Cancelada", o worker cessa a execução, ficheiros temporários são apagados e a quota é estornada. |
| **REQ-VID-TRIM-023** | O sistema deve reter os vídeos recortados na biblioteca do utilizador por tempo indeterminado enquanto o limite de quota de armazenamento da conta for respeitado, disponibilizando ao utilizador a funcionalidade de eliminação permanente de vídeos para libertação de espaço em disco. | Deve ter | Novo | NOVO | UC-VID-001, RN6; DQ-005 | Clarifica a política de persistência e expiração e concede ao utilizador o controlo sobre a sua quota. | **Dado** um vídeo guardado na biblioteca do utilizador, **quando** o utilizador clica em "Eliminar Vídeo" e confirma, **então** o ficheiro é permanentemente apagado e o espaço ocupado é subtraído ao total da sua conta. |
| **REQ-VID-TRIM-024** | O sistema deve apresentar na interface do utilizador autenticado a percentagem e o volume de espaço em disco atualmente ocupado na sua biblioteca em relação ao limite do seu perfil (1 GB em `free` / 5 GB em `premium`), atualizando o indicador após cada adição ou remoção de vídeo. | Deveria ter | Novo | NOVO | UC-VID-001, Passo 1, Passo 7; RN6 | Oferece transparência sobre o consumo de capacidade da conta e previne bloqueios inesperados por excesso de quota. | **Dado** um utilizador autenticado na aplicação, **quando** visualiza a biblioteca ou o diálogo de recorte, **então** a interface exibe uma barra de quota com os MB/GB utilizados e o limite máximo aplicável ao seu perfil. |

---

#### 4.1.2 Requisitos Não Funcionais e de Qualidade

Classificados segundo o modelo de qualidade da norma **ISO/IEC 25010**. Cada requisito quantifica e distingue o limiar estritamente exigido para a aprovação funcional da Fase 1 (**Alvo MVP**) da meta de longo prazo de uma plataforma madura em escala comercial (**Alvo Produção**).

| **ID** | **Requisito** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo Produção** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **REQ-VID-TRIM-009** | O sistema deve transmitir e atualizar no ecrã de acompanhamento o progresso percentual (0% a 100%) da tarefa de recorte durante o processamento ativo no worker. | Usabilidade / Transparência de Estado | Atualização de progresso a cada $\le 5$ segundos através de mecanismo de consulta periódica (*polling*) ou WebSockets. | Atualização contínua a cada $\le 1$ segundo via WebSockets push com estimativa em tempo real de tempo restante (*ETA*). | Refinado | UC-VID-001, Passo 5, Passo 6; DQ-001 | **Dado** uma tarefa em execução ativa no worker, **quando** o recorte de fotogramas progride, **então** a barra de progresso no navegador atualiza o seu valor com intervalo não superior a 5 s. |
| **REQ-VID-TRIM-012** | O sistema deve gerar o ficheiro resultante e garantir a aceitação de vídeos codificados estritamente em contentor MP4 com codecs de vídeo H.264 e de áudio AAC. | Compatibilidade / Interoperabilidade Multimédia | Suporte exclusivo a MP4 (H.264 / AAC) na ingestão e exportação, garantindo reprodução universal direta em navegadores HTML5. | Suporte alargado na ingestão a MP4, WebM, MKV e MOV (H.264, H.265, VP9, AV1) com transcodificação automática sob demanda para entrega web. | Mantido | UC-VID-001, Passo 7; RN4; DQ-004 | **Dado** o término de uma operação de recorte, **quando** o ficheiro gerado é inspecionado com utilitário `ffprobe`, **então** o formato é `format_name=mov,mp4` com stream de vídeo `h264` e áudio `aac`. |
| **REQ-VID-TRIM-013** | O sistema deve assegurar que o ficheiro de vídeo de entrada permanece rigorosamente inalterado em conteúdo, metadados e integridade na biblioteca do utilizador após a execução do recorte. | Fiabilidade / Integridade de Dados | Ficheiro original montado com permissões de apenas-leitura (*read-only*) no worker; verificação de integridade pós-execução. | Idempotência e proteção contra escrita garantidas ao nível do sistema de ficheiros ou *Object Storage* imutável com versionamento ativo. | Mantido | UC-VID-001, Passo 7; RN5; Pós-condições | **Dado** um vídeo de origem com hash SHA-256 conhecido, **quando** a tarefa de recorte termina (com êxito ou erro), **então** o hash do ficheiro original na biblioteca permanece rigorosamente idêntico. |
| **REQ-VID-TRIM-017** | O sistema deve reexecutar automaticamente a tarefa de recorte uma única vez caso ocorra terminação anómala do worker ou o tempo de execução ultrapasse o tempo limite de 10 minutos, marcando a tarefa como falhada e estornando a quota caso a falha persista. | Fiabilidade / Tolerância a Falhas e Recuperabilidade | 1 tentativa de repetição automática em timeout (> 10 min) ou falha de nó; após isso estado "Falhada" e reposição de quota. | 3 tentativas de reexecução com *exponential backoff* e retoma a partir do último *keyframe* processado (processamento em blocos/chunks). | Mantido | UC-VID-001, Exceção 5; DQ-002 | **Dado** um worker deliberadamente terminado a meio do processamento, **quando** o monitor deteta a quebra, **então** a tarefa é reescalonada uma vez; persistindo a falha, o job passa a "Falhada" e a quota é reposta. |
| **REQ-VID-TRIM-018** | O sistema deve eliminar integralmente todos os fragmentos e ficheiros temporários gerados nos nós de processamento sempre que uma tarefa finalize com sucesso, falha ou cancelamento. | Fiabilidade / Limpeza de Recursos Efémeros | Eliminação síncrona da diretoria temporária de trabalho associada ao *Job ID* no worker ao concluir a tarefa. | Eliminação síncrona combinada com processo autónomo em segundo plano (*Garbage Collector*) para expurgação periódica de ficheiros órfãos. | Mantido | UC-VID-001, Pós-condição garantia mínima; DQ-005 | **Dado** o encerramento de um job de recorte, **quando** o worker finaliza, **então** a diretoria temporária `/tmp/picturas-jobs/<jobId>` encontra-se completamente purgada sem resíduos em disco. |
| **REQ-VID-TRIM-025** | O sistema deve confirmar a aceitação e o enfileiramento de um pedido de recorte de vídeo, retornando o *Job ID* à interface, em tempo não superior a 2.0 segundos, independentemente do tamanho do vídeo. | Eficiência de Desempenho / Comportamento Temporal | Tempo de resposta HTTP da API de submissão $\le 2.0$ segundos no percentil 95 (p95). | Tempo de resposta da submissão $\le 0.5$ segundos no percentil 99 (p99) através de confirmações de receção (*ACK*) assíncronas. | Novo | UC-VID-001, Passo 4, Passo 5; DQ-001 | **Dado** um pedido de recorte válido submetido via API/interface, **quando** a chamada HTTP é disparada, **então** a resposta com o *Job ID* é recebida pelo cliente em menos de 2.0 s medidos no cronómetro. |
| **REQ-VID-TRIM-026** | O sistema deve assegurar que o tempo total de processamento e recodificação de um excerto de vídeo não exceda 1.5 vezes a duração do excerto em nós de execução de referência ($T_{\text{proc}} \le 1.5 \times (t_{out} - t_{in})$). | Eficiência de Desempenho / Eficiência de Processamento | Duração do processamento $\le 1.5\times$ tempo real do excerto em nós de computação padrão de 2 vCPUs (ex.: excerto de 60s gerado em $\le 90$s). | Duração do processamento $\le 0.3\times$ tempo real recorrendo a aceleração gráfica por hardware (GPU/NVENC) e divisão em blocos paralelos. | Novo | UC-VID-001, Passo 6; DQ-002 | **Dado** um vídeo 1080p a 30 fps e um recorte de 60 segundos, **quando** processado no worker com FFmpeg, **então** o tempo entre a retirada da fila e a criação do ficheiro final é $\le 90$ segundos. |
| **REQ-VID-TRIM-027** | O sistema deve restringir o acesso e descarregamento dos vídeos carregados e recortados exclusivamente ao utilizador titular da conta que os submeteu, impedindo acesso anónimo ou enumeração de URLs. | Segurança / Confidencialidade e Controlo de Acesso | Endpoints de acesso a mídia mediados por validação do token JWT de autenticação do utilizador e verificação do `userId` no backend. | Ficheiros armazenados em *Object Storage* privado acessíveis exclusivamente através de URLs pré-assinados com tempo de expiração curto ($\le 15$ minutos). | Novo | UC-VID-001, Pré-condições, Passo 8; DQ-003 | **Dado** um vídeo pertencente ao Utilizador A, **quando** o Utilizador B (ou visitante anónimo) tenta aceder ao URL do vídeo, **então** o sistema devolve o código de erro HTTP 403 Forbidden. |
| **REQ-VID-TRIM-028** | O ambiente de execução do nó de processamento de vídeo deve encapsular as dependências externas e o binário de execução do FFmpeg de forma modular e isolada, sem dependência do sistema operativo anfitrião. | Portabilidade e Manutenibilidade / Isolamento Modular | Empacotamento do microsserviço de recorte em contentor Docker autónomo baseado em imagem Linux oficial com FFmpeg instalado. | Orquestração em nós Kubernetes de computação elástica com escalamento automático baseado no tamanho da fila RabbitMQ (*KEDA*). | Novo | UC-VID-001, Âmbito; DQ-004 | **Dado** a implantação do sistema num novo nó de infraestrutura, **quando** se inicia o contentor Docker do worker de vídeo, **então** o serviço arranca e processa recortes sem configuração prévia no host. |

---

#### 4.1.3 Verificação da completude e dos limites do âmbito

Avaliação sistemática dos tópicos críticos levantados pelo enunciado relativamente ao suporte a vídeo, explicitando as decisões de inclusão e de exclusão do âmbito no contexto do MVP:

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
|:---|:---:|:---|:---|
| **Formato, codec, duração e dimensão do vídeo** | **Sim** | No MVP da Fase 1, o sistema suporta exclusivamente contentor MP4 com vídeo H.264 e áudio AAC, garantindo compatibilidade universal de reprodução em browsers HTML5 sem necessidade de remuxing ou transcodificação no cliente. A duração do excerto está delimitada pelo perfil do utilizador (180s para `free` e 60 min para `premium`), e a dimensão máxima é governada pela quota global de armazenamento da biblioteca (1 GB para `free` e 5 GB para `premium`). | REQ-VID-TRIM-004, REQ-VID-TRIM-006, REQ-VID-TRIM-012, REQ-VID-TRIM-016, REQ-VID-TRIM-021 |
| **Estado, progresso, cancelamento e resultado** | **Sim** | O processamento de vídeo é demorado e assíncrono. O sistema gere o ciclo de vida completo da tarefa através dos estados formais: *"Em fila de espera"*, *"A processar"*, *"Concluído"*, *"Falhado"* e *"Cancelado"*. A interface apresenta progresso percentual periódico, permite o cancelamento cooperativo pelo utilizador em qualquer instante antes do término e disponibiliza pré-visualização e download imediatos após o sucesso. | REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-014, REQ-VID-TRIM-015, REQ-VID-TRIM-022, REQ-VID-TRIM-025 |
| **Falhas durante o processamento** | **Sim** | Em caso de deteção de ficheiro danificado, codecs incompatíveis, término inesperado do worker ou timeout de execução (10 min), o sistema efetua uma reexecução automática idempotente; persistindo a falha, o job transita para estado "Falhado", a quota de operações diárias provisoriamente debitada é estornada ao utilizador e todos os ficheiros residuais nos workers são eliminados. | REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-018 |
| **Persistência e expiração dos ficheiros** | **Sim** | Os ficheiros de vídeo de origem e de saída persistem na biblioteca do utilizador por tempo indeterminado enquanto a sua quota de disco acumulada (1 GB em `free` / 5 GB em `premium`) não for excedida, cabendo ao utilizador a eliminação deliberada para libertação de espaço. Os ficheiros temporários intermédios em nós de processamento são purgados imediatamente após cada tarefa. | REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024 |
| **Perfis e contagem de operações** | **Sim** | Articulação estrita com o esquema de utilizadores do PictuRAS (`["anonymous", "free", "premium"]`): utilizadores anónimos estão totalmente bloqueados de aceder a ferramentas de vídeo; utilizadores `free` dispõem de 5 operações diárias gratuitas (`FREE_DAILY_OP = 5`), limite de 180s por recorte e 1 GB de disco; utilizadores `premium` dispõem de operações ilimitadas, recortes até 60 min, suporte a *stream copy* e 5 GB de disco. | REQ-VID-TRIM-005, REQ-VID-TRIM-006, REQ-VID-TRIM-007, REQ-VID-TRIM-011, REQ-VID-TRIM-019, REQ-VID-TRIM-021 |
| **Encadeamento de ferramentas e processamento em lote** | **Não** *(Fora do âmbito do MVP)* | **Decisão de exclusão justificada:** No MVP da Fase 1, a ferramenta de recorte opera estritamente como uma ação atómica e individual sobre um único vídeo. O encadeamento sequencial de filtros de vídeo com transformações de imagem existentes e o processamento de múltiplos vídeos em lote (via `.zip`) introduziriam elevada sobrecarga de orquestração assíncrona e consumo excessivo de recursos de infraestrutura que desvirtuam o propósito de validação funcional do MVP. A expansão para encadeamento e processamento em lote fica formalmente diferida para fases posteriores. | — *(Exclusão explícita fundamentada no âmbito do MVP)* |

---

### 4.2 Impacto no sistema existente

Análise atualizada da interação entre a ERS da funcionalidade de recorte de vídeo e os subsistemas existentes da plataforma PictuRAS (*brownfield*):

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
|:---|:---:|:---|:---|
| **Quota diária de operações (Tier `free`: `FREE_DAILY_OP`)** | **Alterar** | No PictuRAS existente (`users.js`), o saldo de 5 operações diárias aplica-se apenas a transformações síncronas de imagens. Com o vídeo, 1 operação de recorte consome 1 unidade de `FREE_DAILY_OP` com mecanismo transacional assíncrono: débito provisório na submissão e estorno automático em caso de falha de processamento, quota de disco excedida ou cancelamento pelo utilizador. | REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-021, REQ-VID-TRIM-022 |
| **Sistema de Perfis de Utilizador e Controlo de Acesso (`userSchema`)** | **Estender** | O modelo de permissões `["anonymous", "free", "premium"]` é estendido para impor bloqueio de ferramentas de vídeo a utilizadores anónimos, aplicar limites de duração de excerto por perfil autenticado (180s para `free`, 60 min para `premium`), autorizar *stream copy* a subscritores `premium` e validar quotas de armazenamento em disco. | REQ-VID-TRIM-006, REQ-VID-TRIM-011, REQ-VID-TRIM-019, REQ-VID-TRIM-021, REQ-VID-TRIM-024, REQ-VID-TRIM-027 |
| **Serviço de Armazenamento e Biblioteca (`imageStorageService`)** | **Alterar** | O serviço é evoluído para gerir ficheiros multimédia em contentor MP4 e passa a contabilizar e governar ativamente o volume total em disco por conta: teto de **1 GB** para `free` e **5 GB** para `premium`, rejeitando persistências quando o limite é atingido e suportando a eliminação explícita de vídeos pelo utilizador para libertação de espaço. | REQ-VID-TRIM-012, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024 |
| **Infraestrutura de Mensajeria e Filas (`rabbitMQ`)** | **Estender** | Criação de canais e filas dedicadas a tarefas de vídeo (ex.: `video_tasks_queue`), isoladas das filas de imagem existentes, com suporte a mensagens de controlo para transmissão de comandos de cancelamento voluntário aos workers. | REQ-VID-TRIM-008, REQ-VID-TRIM-010, REQ-VID-TRIM-017, REQ-VID-TRIM-022, REQ-VID-TRIM-025 |
| **Gateway de Comunicação em Tempo Real (`wsGateway`)** | **Estender** | O serviço WebSocket é alargado para emitir eventos de ciclo de vida de jobs de vídeo indexados por *Job ID*, transmitindo progresso percentual (0% a 100%), transições de estado ("Em fila", "A processar", "Concluído", "Falhado", "Cancelado") e alertas aos utilizadores mesmo quando navegam entre vistas. | REQ-VID-TRIM-009, REQ-VID-TRIM-015, REQ-VID-TRIM-022 |
| **Interface Gráfica Web (`frontend`)** | **Estender** | Introdução de reprodutor de vídeo HTML5, linha temporal com seleção interativa de $t_{in}$/$t_{out}$, pré-visualização local no browser, indicador visual de consumo de armazenamento em disco (barra de quota), ecrã de acompanhamento de tarefas assíncronas com botão de cancelamento e modal de encaminhamento para registo de anónimos. | REQ-VID-TRIM-001, REQ-VID-TRIM-002, REQ-VID-TRIM-003, REQ-VID-TRIM-009, REQ-VID-TRIM-019, REQ-VID-TRIM-022, REQ-VID-TRIM-024 |
| **Orquestração de Nós de Execução (*Workers*)** | **Estender** | Implementação de novo microsserviço de processamento de vídeo baseado em Python e FFmpeg, empacotado em contentor Docker isolado, concebido para operar em diretoria efémera temporária com purga garantida de fragmentos. | REQ-VID-TRIM-010, REQ-VID-TRIM-012, REQ-VID-TRIM-018, REQ-VID-TRIM-026, REQ-VID-TRIM-028 |
| **Encadeamento de Ferramentas (*Pipelines*) e Processamento em Lote** | **Manter** | O subsistema de encadeamento e processamento em lote via ficheiro `.zip` permanece rigorosamente inalterado no MVP, mantendo-se restrito a imagens e sem interferência da ferramenta de recorte de vídeo. | — *(Manutenção do comportamento existente)* |

---

### 4.3 Matriz de Rastreabilidade Atualizada

A matriz assegura a rastreabilidade bidirecional completa entre todos os elementos do caso de uso, as decisões de qualidade tomadas e os requisitos funcionais e não funcionais da ERS:

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
|:---|:---|:---|
| **UC-VID-001, Âmbito** | Módulo de processamento de vídeo assíncrono em nós isolados | REQ-VID-TRIM-008, REQ-VID-TRIM-028 |
| **UC-VID-001, Pré-condições** | Autenticação obrigatória, quotas diárias e de disco, formato MP4 e vídeo carregado | REQ-VID-TRIM-005, REQ-VID-TRIM-012, REQ-VID-TRIM-019, REQ-VID-TRIM-021, REQ-VID-TRIM-027 |
| **UC-VID-001, Passo 1** | Seleção do vídeo na biblioteca e abertura da ferramenta de recorte | REQ-VID-TRIM-001, REQ-VID-TRIM-024 |
| **UC-VID-001, Passo 2** | Ajuste interativo dos marcadores temporais $t_{in}$ e $t_{out}$ na linha temporal | REQ-VID-TRIM-002 |
| **UC-VID-001, Passo 3** | Confirmação da operação e validação de parâmetros, limites e quotas de disco/operações | REQ-VID-TRIM-004, REQ-VID-TRIM-005, REQ-VID-TRIM-006, REQ-VID-TRIM-021 |
| **UC-VID-001, Passo 4** | Dedução provisória de quota diária (`free`) e publicação assíncrona na fila | REQ-VID-TRIM-007, REQ-VID-TRIM-008, REQ-VID-TRIM-025 |
| **UC-VID-001, Passo 5** | Atribuição de *Job ID*, estado em fila e ecrã de acompanhamento | REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-025 |
| **UC-VID-001, Passo 6** | Execução do recorte no worker com FFmpeg e difusão de progresso | REQ-VID-TRIM-009, REQ-VID-TRIM-010, REQ-VID-TRIM-026 |
| **UC-VID-001, Passo 7** | Conclusão do processamento, validação de integridade e guarda com controlo de quota | REQ-VID-TRIM-012, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-021, REQ-VID-TRIM-024 |
| **UC-VID-001, Passo 8** | Notificação de sucesso, download e registo na biblioteca permanente | REQ-VID-TRIM-014, REQ-VID-TRIM-027 |
| **UC-VID-001, FA1** | Pré-visualização local no browser antes de submeter a tarefa | REQ-VID-TRIM-003 |
| **UC-VID-001, FA2** | Recorte rápido sem recodificação (*Stream Copy*) para perfil `premium` | REQ-VID-TRIM-011 |
| **UC-VID-001, FA3** | Continuidade do processamento em segundo plano ao fechar o browser | REQ-VID-TRIM-015 |
| **UC-VID-001, FA4** | Bloqueio de utilizadores não autenticados (`anonymous`) com convite a registo | REQ-VID-TRIM-019 |
| **UC-VID-001, FA5** | Cancelamento voluntário da tarefa pelo utilizador em fila ou execução | REQ-VID-TRIM-022 |
| **UC-VID-001, Exceção 1** | Instantes temporais inválidos ($t_{in} \ge t_{out}$ ou intervalo $< 1.0$ s) | REQ-VID-TRIM-004 |
| **UC-VID-001, Exceção 2** | Duração do excerto excede o limite do perfil (180s em `free` / 60 min em `premium`) | REQ-VID-TRIM-006 |
| **UC-VID-001, Exceção 3** | Quota diária de operações esgotada no perfil `free` (`FREE_DAILY_OP = 5`) | REQ-VID-TRIM-005 |
| **UC-VID-001, Exceção 4a** | Ficheiro de vídeo com formato não suportado ou pacotes corrompidos | REQ-VID-TRIM-016 |
| **UC-VID-001, Exceção 4b** | Quota de armazenamento em disco da conta excedida (1 GB `free` / 5 GB `premium`) | REQ-VID-TRIM-021 |
| **UC-VID-001, Exceção 5** | Falha de nó de processamento ou timeout de execução de 10 minutos | REQ-VID-TRIM-017 |
| **UC-VID-001, Pós-condição: Sucesso** | Excerto gerado com sincronismo A/V, original intacto, na biblioteca e auditado | REQ-VID-TRIM-010, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-020, REQ-VID-TRIM-021 |
| **UC-VID-001, Pós-condição: Mínima** | Original intacto, ficheiros temporários purgados e quotas estornadas | REQ-VID-TRIM-013, REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-022 |
| **RN1** | Gestão transacional de quotas diárias de operações (`FREE_DAILY_OP = 5`) | REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-017, REQ-VID-TRIM-021, REQ-VID-TRIM-022 |
| **RN2** | Limites de duração de excerto por perfil autenticado (180s em `free`, 60 min em `premium`) | REQ-VID-TRIM-006 |
| **RN3** | Precisão temporal ao centésimo de segundo e duração mínima de 1.0 s | REQ-VID-TRIM-002, REQ-VID-TRIM-004 |
| **RN4** | Formatos e codecs suportados no MVP (contentor MP4 com H.264 e AAC) | REQ-VID-TRIM-012 |
| **RN5** | Princípio da não destrutividade do vídeo de origem na biblioteca | REQ-VID-TRIM-013 |
| **RN6** | Quotas de armazenamento em disco por perfil (1 GB `free`, 5 GB `premium`) e retenção | REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024 |
| **RN7** | Autenticação obrigatória para ferramentas de vídeo e bloqueio a anónimos | REQ-VID-TRIM-019 |
| **DQ-001** | Desacoplamento assíncrono via filas dedicadas de mensagens e WebSockets | REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-025 |
| **DQ-002** | Resiliência com repetição idempotente e métricas de débito de processamento | REQ-VID-TRIM-017, REQ-VID-TRIM-026 |
| **DQ-003** | Proteção de acesso aos artefactos multimédia e registo de auditoria | REQ-VID-TRIM-020, REQ-VID-TRIM-027 |
| **DQ-004** | Isolamento do motor FFmpeg em contentor Docker | REQ-VID-TRIM-012, REQ-VID-TRIM-028 |
| **DQ-005** | Retenção efêmera em workers e política de persistência na biblioteca | REQ-VID-TRIM-018, REQ-VID-TRIM-023 |
| **DQ-006** | Mecanismo cooperativo de cancelamento ativo pelo utilizador | REQ-VID-TRIM-022 |

---

**Decisões de qualidade introduzidas nesta aula**

| **ID** | **Decisão de qualidade** | **Justificação** | **Requisito(s) relacionado(s)** |
|:---|:---|:---|:---|
| **DQ-001** | Processamento assíncrono desacoplado via RabbitMQ e monitorização via WebSockets / Polling | Previne o bloqueio do servidor HTTP da API durante operações longas de vídeo e mantém a interface do utilizador responsiva com atualizações contínuas de progresso. | REQ-VID-TRIM-008, REQ-VID-TRIM-009, REQ-VID-TRIM-025 |
| **DQ-002** | Resiliência baseada em reexecução idempotente do início sem retoma parcial no MVP | Simplifica a arquitetura da Fase 1 evitando a complexidade de persistir checkpoints de fotogramas, tolerando quebras pontuais de workers com repetição automática garantida. | REQ-VID-TRIM-017, REQ-VID-TRIM-026 |
| **DQ-003** | Acesso estrito a URLs de vídeo condicionado por autenticação e auditoria de jobs | Assegura a privacidade dos dados multimédia do utilizador e previne que terceiros acedam aos vídeos através de enumeração ou adivinhação de identificadores. | REQ-VID-TRIM-020, REQ-VID-TRIM-027 |
| **DQ-004** | Encapsulamento do motor FFmpeg e dependências nativas em imagem Docker dedicada | Garante portabilidade total e reprodutibilidade do ambiente de execução de vídeo entre desenvolvimento e produção, sem instalar binários ad-hoc no sistema anfitrião. | REQ-VID-TRIM-012, REQ-VID-TRIM-028 |
| **DQ-005** | Gestão de retenção efêmera em workers e eliminação explícita na biblioteca permanente | Previne o esgotamento do disco dos nós de computação através de purga imediata de fragmentos intermédios e capacita o utilizador a gerir a quota da sua conta. | REQ-VID-TRIM-018, REQ-VID-TRIM-023 |
| **DQ-006** | Cancelamento cooperativo de tarefas em curso com estorno de quota | Evita o desperdício de tempo de computação em tarefas submetidas erradamente e garante justiça na contabilidade de quotas para utilizadores do plano gratuito. | REQ-VID-TRIM-022 |

---

**Verificações de cobertura**
- [x] Cada requisito funcional e não funcional aparece na matriz de rastreabilidade.
- [x] Cada requisito tem origem claramente identificada: passo do caso de uso, fluxo alternativo, exceção, regra de negócio ou decisão de qualidade.
- [x] Todos os elementos relevantes do caso de uso e regras de negócio possuem requisitos associados.
- [x] Os tópicos excluídos na secção 4.1.3 (encadeamento e processamento em lote) estão explicitamente fundamentados.
- [x] O impacto nos subsistemas existentes do PictuRAS encontra-se completamente atualizado e ligado aos respetivos requisitos.

---

## ✅ Lista de verificação antes de entregar (Exercício 2)

- [x] As secções 0 a 3 do dossiê foram integralmente preservadas; as assunções, questões em aberto e utilização de IA foram devidamente atualizadas.
- [x] A funcionalidade (Recorte temporal de vídeo - *Trim*), o caso de uso (`UC-VID-001`) e os perfis do Exercício 1 foram mantidos.
- [x] Os requisitos funcionais (4.1.1) cobrem o serviço com critérios de aceitação verificáveis no formato *Given-When-Then*.
- [x] Os requisitos de qualidade (4.1.2) estão classificados segundo a norma **ISO/IEC 25010** e distinguem expressamente o **Alvo MVP** do **Alvo Produção** com métricas mensuráveis.
- [x] Todos os IDs existentes da baseline do Exercício 1 (`REQ-VID-TRIM-001` a `021`) foram preservados e identificados quanto à sua evolução (Mantido / Refinado).
- [x] A análise de completude (4.1.3) avalia os 6 tópicos do enunciado e fundamenta a exclusão de lote e encadeamento no MVP sem alargar o âmbito indevidamente.
- [x] A matriz de rastreabilidade atualizada (4.3) não possui requisitos órfãos nem elementos do caso de uso por cobrir (100% de cobertura bidirecional).
- [x] As decisões de qualidade (`DQ-001` a `DQ-006`) e o impacto nos componentes existentes (4.2) estão documentados com rigor.
