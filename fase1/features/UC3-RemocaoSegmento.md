# 📝 Dossiê de Requisitos do Sistema — Exercício 3
### Especificação de Requisitos do Sistema (ERS) · Fase 1: Suporte a Vídeo no PictuRAS

---

## 0. Identificação

| **Campo** | **Valor** |
|-----------|-----------|
| **Grupo / Equipa** | PL3 G2 |
| **Autores** | PG63928; Carlos André Barroso Araújo |
| **Data** | 2026-10-22 |
| **Versão do documento** | v2.0 — v1.0 (2026-10-06): secções 0–3; v1.1 (2026-10-14): secção 4 (esboço); v1.2 (2026-10-17): resolução de contradições lógicas e refinamento (REQ-VID-REM-011 a 013); v2.0 (2026-10-22): ERS consolidada dos Exercícios 2 e 3 — segregação de requisitos funcionais (4.1.1) e de qualidade (4.1.2) com unidades, alvos e condições de medição, verificação de completude (4.1.3), registo de refinamento (4.4) e harmonização com UC-VID-001 e UC-VID-002 (quota diária de operações, precisão temporal, AAC condicional, quota acumulada de armazenamento e alvos do pipeline partilhado); normalização do identificador do caso de uso para UC-VID-003 |
| **Unidade Curricular** | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |

---

## 1. Funcionalidade de vídeo escolhida

| **Campo** | **Valor** |
|-----------|-----------|
| **Funcionalidade** | Remover segmento do vídeo (eliminação de intervalo temporal com união das partes restantes) |
| **Perfil(s) de utilizador abrangido(s)** | Registado e premium (com plano ativo Free ou Premium) — o caso de uso abrange todos os utilizadores autenticados com permissão de edição num projeto multimédia. |

**Justificação no contexto do MVP**
A remoção de segmentos indesejados é uma operação elementar de montagem e edição de vídeo porque permite ao utilizador eliminar hesitações, pausas ou partes defeituosas de uma gravação sem recorrer a ferramentas externas.

---

## 2. Caso de Uso

### 2.1 Cabeçalho

| **Secção** | **Detalhes** |
|------------|--------------|
| **ID do Caso de Uso** | UC-VID-003 |
| **Nome** | Remover segmento do vídeo |
| **Versão** | v1.3 (assunções, regras e questões em aberto atualizadas na ERS v2.0) |
| **Autor** | PG63928; Carlos André Barroso Araújo |
| **Data** | 2026-10-22 |
| **Objetivo** | Permitir ao utilizador eliminar um intervalo temporal indesejado de um vídeo existente num projeto, gerando um novo vídeo resultante da união das partes restantes (ou da parte contínua restante, caso o corte incida num dos extremos), preservando integralmente o ficheiro original. |
| **Âmbito** | Módulo de edição de vídeo do PictuRAS — editor no cliente e pipeline de processamento no servidor. |
| **Ator Principal** | Utilizador autenticado do PictuRAS (plano Free ou Premium), com papel de proprietário ou permissão de edição no projeto. |
| **Stakeholders e Interesses** | - **Proprietário / Editor do Projeto**: eliminar segmentos indesejados sem risco de perda de dados, mantendo o original bruto e obtendo um novo vídeo editado no projeto.<br>- **Visualizadores**: consumir vídeos finais coesos e sem pausas ou trechos desnecessários.<br>- **Proprietário do Sistema**: rentabilizar os planos de subscrição (através de quotas de armazenamento e priorização de tarefas de render) e gerir o esforço computacional dos workers. |
| **Pré-condições** | - O utilizador está autenticado e possui permissão de edição no projeto.<br>- O utilizador dispõe de saldo da quota diária de operações avançadas (perfil Free) e de espaço na quota de armazenamento da conta (harmonizado com o modelo do UC-VID-002).<br>- O vídeo de origem encontra-se carregado e registado na lista de vídeos do projeto.<br>- Os serviços de API, media storage e workers de vídeo estão operacionais. |
| **Trigger** | No editor do projeto, o utilizador seleciona a ferramenta **Remover segmento** sobre um vídeo específico. |

### 2.2 Fluxo Principal

| **Passo** | **Ação do Ator** | **Resposta do Sistema** |
|-----------|------------------|-------------------------|
| 1 | O utilizador abre o projeto e seleciona um vídeo para editar | Apresenta o editor com o reprodutor, metadados do vídeo (duração, dimensões, formato) e controlos de edição |
| 2 | O utilizador seleciona a ferramenta **Remover segmento**, marca na timeline o intervalo temporal a eliminar  e confirma a marcação no diálogo | Valida a consistência do corte, destaca visualmente o segmento a eliminar e regista a operação como pendente (*staged*) no editor |
| 3 | O utilizador clica no botão **Aplicar** (*Apply*) na barra de ferramentas do projeto | Valida o controlo de versões do projeto (`X-Project-Version`) e o saldo da quota diária de operações (perfil Free), cria um job de render assíncrono com a operação pendente, submete-o à fila de processamento, debita provisoriamente 1 operação da quota diária (perfil Free) e sinaliza visualmente o estado **em processamento** |
| 4 | — | O worker consome a tarefa: descarrega o vídeo original do armazenamento interno, extrai a(s) parte(s) restante(s) exterior(es) ao intervalo marcado e gera o novo ficheiro MP4 |
| 5 | — | Faz o upload do novo vídeo para o armazenamento de media (sujeito à quota acumulada da conta), associa o novo vídeo ao projeto (gerando um novo identificador e nome derivado), preservando o vídeo original, e atualiza a versão do projeto |
| 6 | — | Notifica a conclusão da operação (via WebSocket / evento de projeto), adiciona o novo vídeo à galeria do projeto e disponibiliza de imediato a sua reprodução |
| 7 | O utilizador revê o novo vídeo gerado e fecha o editor ou continua a trabalhar no projeto | Regista a conclusão da operação e mantém ambos os vídeos (original e editado) disponíveis no projeto |

### 2.3 Fluxos Alternativos

| **Fluxo** | **Descrição** |
|-----------|---------------|
| FA1 – Pré-visualizar resultado | Em qualquer momento antes do passo 3, o utilizador solicita a pré-visualização → o reprodutor no cliente simula a reprodução unindo as partes antes e depois do corte (ou saltando a parte inicial/final eliminada), sem requerer render no servidor nem consumir quota de operações; o utilizador pode reajustar as marcas (regressa ao passo 2) ou avançar para o passo 3 |
| FA2 – Cancelar ou alterar operação pendente (*staged*) | Antes de acionar o botão **Aplicar** (passo 3), o utilizador cancela a operação ou reabre a ferramenta → o sistema limpa ou atualiza o estado pendente no cliente, sem gerar encargos, débitos de quota nem tarefas no servidor |

### 2.4 Exceções

| **Condição** | **Comportamento do Sistema** |
|--------------|------------------------------|
| O formato/codec do vídeo não é compatível com o pipeline de edição (passo 1 / trigger) | Ao validar os parâmetros de entrada e metadados do vídeo, rejeita o pedido, apresenta a notificação «Formato de vídeo não suportado para edição» e mantém o projeto inalterado |
| Marcação temporal inconsistente ou inválida no diálogo (passo 2) | O sistema bloqueia a confirmação no diálogo, assinala os campos com erro e impede o registo da operação como pendente até correção dos valores ($0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração}$) |
| Duração útil restante inferior a 1,0 s no diálogo (passo 2) | O sistema rejeita a confirmação com a notificação «A duração resultante do vídeo deve ser igual ou superior a 1,0 s» e mantém o diálogo aberto para ajuste das marcas |
| O job de render falha ou excede o tempo limite de 600 s por tentativa no worker (passo 4) | Repete a tarefa uma única vez desde o início; persistindo a falha, notifica o erro («Não foi possível concluir a remoção do segmento»), limpa o estado de processamento e repõe a operação debitada na quota diária (perfil Free); o vídeo original e o projeto permanecem intactos, sem criação de ficheiros corrompidos |
| Conflito de versão no projeto (`X-Project-Version`) no momento de aplicar (passo 3) | Rejeita a submissão com erro de conflito de concorrência («O projeto foi alterado por outro utilizador») e solicita a atualização do projeto antes de submeter novamente a operação |
| Espaço acumulado na quota de armazenamento da conta insuficiente para o novo vídeo (passo 5) | Recusa a gravação do vídeo resultante, repõe a operação debitada na quota diária (perfil Free), notifica o utilizador do limite da quota (1 GB Free / 5 GB Premium) e mantém o vídeo original e o projeto inalterados |

### 2.5 Pós-condições

| **Tipo** | **Resultado** |
|----------|---------------|
| Garantia de Sucesso | Um novo vídeo (sem o segmento removido) é criado e adicionado ao projeto com metadados próprios e nome derivado; o ficheiro original mantém-se intacto e acessível; a versão do projeto é incrementada |
| Garantia Mínima | O vídeo original permanece inalterado e reproduzível; nenhum ficheiro corrompido é associado ao projeto; o estado de processamento pendente é limpo; a operação debitada na quota diária é reposta (perfil Free); o utilizador é notificado da falha |

### 2.6 Regras de Negócio e Restrições

| **ID** | **Regra** |
|--------|-----------|
| RN1 | Apenas utilizadores autenticados (com plano Free ou Premium) com permissão de proprietário ou edição no projeto podem executar a remoção de segmentos em vídeos |
| RN2 | A marcação do segmento a eliminar deve ser consistente: $0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração do vídeo}$. Caso o corte seja intermédio ($0 < t_{\text{início}} < t_{\text{fim}} < \text{duração}$), o resultado une as partes anterior e posterior; caso o corte incida numa das extremidades ($t_{\text{início}} = 0$ ou $t_{\text{fim}} = \text{duração}$), o resultado corresponde à extração simples da parte restante contínua |
| RN3 | A duração combinada do vídeo resultante (soma da(s) parte(s) restante(s)) tem de ser igual ou superior a 1,0 s (não é permitido eliminar a quase totalidade do vídeo) |
| RN4 | A edição é não-destrutiva por omissão no MVP: o ficheiro original nunca é sobrescrito ou eliminado pelo fluxo normal da operação; o resultado da remoção é sempre gravado como um novo recurso multimédia no projeto |
| RN5 | A submissão do processamento ao servidor segue o ciclo de *staging* do editor: a definição do intervalo fica pendente (*staged*) no cliente após confirmação no diálogo e só é submetida ao servidor quando o utilizador aciona o botão **Aplicar** (*Apply*), sujeita à validação da versão do projeto |
| RN6 | A operação de remoção de segmento consome 1 operação da quota diária de operações avançadas no perfil Free (`FREE_DAILY_OP = 5`), debitada provisoriamente na aceitação da tarefa e reposta em caso de falha, expiração ou recusa por quota de armazenamento; o perfil Premium tem operações ilimitadas (harmonizado com a RN1 do UC-VID-002) |

### 2.7 Assunções

| **ID** | **Assunção** |
|--------|--------------|
| A1 | O PictuRAS organiza o conteúdo multimédia em torno de Projetos, com controlo de concorrência otimista (`X-Project-Version`) e partilha de acessos |
| A2 | O pipeline de processamento assíncrono (RabbitMQ e Workers com FFmpeg) é partilhado entre operações de vídeo (*Trim*, Remoção de Segmento, etc.) |
| A3 | O editor no cliente fornece uma timeline com precisão mínima de centésimos de segundo (0,01 s), harmonizada com a RN3 do UC-VID-002 |
| A4 | A pré-visualização (FA1) é simulada localmente no cliente através do controlo da posição de reprodução do vídeo original |
| A5 | O modelo de edição não-destrutiva é adotado uniformemente, salvaguardando as gravações originais do utilizador contra edições acidentais |
| A6 | Os metadados do novo vídeo (duração, tamanho em bytes, miniatura, codec H.264 — e AAC quando existir faixa de áudio) são calculados e registados na conclusão bem-sucedida do render |
| A7 | O modelo transacional de quotas diárias do UC-VID-002 (débito provisório na aceitação da tarefa e estorno automático em falha) aplica-se igualmente à remoção de segmento, por partilha do pipeline de processamento (A2) e do modelo SaaS do PictuRAS |

### 2.8 Questões em Aberto

| **ID** | **Questão** | **Estado / Resolução na ERS v2.0** |
|--------|-------------|-----------------------------------|
| Q1 | Como gerir as quotas globais de armazenamento do utilizador quando múltiplos vídeos derivados (cortes e *trims*) são acumulados no mesmo projeto? | Em curso: a proposta de quota acumulada de 1 GB (Free) / 5 GB (Premium) do UC-VID-002 (REQ-VID-TRIM-021/023) é adotada condicionalmente por REQ-VID-REM-017; aguarda decisão conjunta com o UC-VID-001 (ver 4.4.2) |
| Q2 | Deve ser disponibilizada uma opção opcional avançada de «Substituir original» caso o utilizador pretenda poupar espaço no seu plano de armazenamento? | Aberto para a Fase 2: mantém-se a edição não-destrutiva estrita (RN4), alinhado com a resolução de Q2 do UC-VID-002 |
| Q3 | Devem ser geradas miniaturas (*thumbnails*) específicas na transição do ponto de corte para permitir inspeção visual antes de aplicar o corte definitivo? | Aberto: os metadados incluem a miniatura genérica do novo vídeo (A6, REQ-VID-REM-016); miniaturas específicas do ponto de corte ficam fora do MVP |
| Q4 | A simulação da pré-visualização no cliente deve suportar transições suaves (ex.: pequeno *crossfade* de áudio) no ponto de junção das partes? | Aberto: fora do MVP; a concatenação preserva o áudio original sem transições suaves (REQ-VID-REM-005) |
| Q5 | O cancelamento cooperativo de tarefas em execução, especificado para o pipeline partilhado no UC-VID-002 (FA5; REQ-VID-TRIM-022, 036–038), deve ser estendido às tarefas de remoção de segmento, incluindo o estorno da quota debitada (REQ-VID-REM-020)? | Aberto: a remoção partilha a fila (A2), mas o UC-VID-003 só prevê o cancelamento da operação pendente antes de **Aplicar** (FA2); ver 4.4.2 |

---

## 3. Utilização de agentes de IA

| **Ferramenta / *skill*** | **Tarefa apoiada** | **Validação realizada pela equipa** |
|--------------------------|--------------------|--------------------------------------|
| OpenCode (agente de IA, modelo GLM) | Elicitação das decisões de desenho iniciais e primeira versão das secções 0–3 | Decisões revistas e discutidas pela equipa |
| OpenCode (agente de IA, modelo GLM) | Derivação inicial da secção 4 (requisitos, impacto e matriz de rastreabilidade) | Revisão manual da formulação e atomicidade dos requisitos |
| Antigravity (agente de IA, DeepMind) | Deteção e resolução de contradições lógicas, harmonização de rastreabilidade (REQ-011 a REQ-013) e correção de ciclo de vida de *staging* | Revisão e validação manual pela equipa |
| OpenCode (agente de IA, modelo GLM) | Consolidação dos Exercícios 2 e 3: estruturação da ERS (4.1.1–4.1.3), refinamento com unidades e condições de medição, harmonização com UC-VID-001/002 (quota diária, precisão temporal, AAC condicional, quota acumulada e alvos do pipeline partilhado) e registo de refinamento (4.4) | Revisão e validação manual pela equipa; decisões de harmonização confirmadas com o autor do dossiê |

---

## 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-003 — Remover segmento do vídeo  
**Versão do dossiê:** v2.0  
**Baseline do Exercício 2:** inexistente — o dossiê não produziu uma ERS autónoma no Exercício 2; a estrutura da ERS e o refinamento do Exercício 3 foram consolidados nesta versão a partir da baseline v1.2 do Exercício 1 (IDs `REQ-VID-REM-001` a `REQ-VID-REM-013`), sem alargamento do âmbito.

O catálogo 4.1 é a fonte única dos requisitos da ERS. **Evolução** regista a origem face à baseline v1.2: Mantido, Refinado, Dividido ou Novo (por divisão ou por harmonização com UC-VID-001/002). **Estado** regista o resultado do Exercício 3: Inalterado, Refinado, Dividido ou Novo. **NOVO/ALT** indica o impacto face ao PictuRAS anterior ao suporte a vídeo: NOVO designa comportamento específico de vídeo; ALT designa extensão de mecanismos existentes. Os requisitos REQ-VID-REM-010, 011 e 012, classificados como não funcionais na baseline v1.2, exprimem validações comportamentais do fluxo e transitam para 4.1.1, conservando ID e intenção.

### 4.1 Requisitos da ERS

#### 4.1.1 Requisitos Funcionais

| **ID** | **Requisito (refinado)** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** | **Estado** |
|--------|--------------------------|----------------|--------------|--------------|--------------------------------|-----------------|----------------------------------------|-----------|
| REQ-VID-REM-001 | O sistema deve permitir ao utilizador com permissão de edição selecionar um vídeo num projeto para remoção de segmento. | Deve ter | Mantido | ALT | UC-VID-003, Passo 1; RN1 | Entrada do fluxo de edição no projeto. | Dado um utilizador com acesso de edição a um projeto, quando seleciona um vídeo, então o editor carrega a timeline e os metadados do ficheiro. | Inalterado |
| REQ-VID-REM-002 | O sistema deve validar a consistência do intervalo marcado para eliminação ($0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração}$) no diálogo do editor, com marcação temporal em passos de, no máximo, 0,01 s. | Deve ter | Refinado | NOVO | UC-VID-003, Passo 2; RN2; Exceção 2; A3 (harmonizada com RN3 do UC-VID-002) | Impede operações temporalmente inconsistentes; a precisão de centésimos alinha-se com o editor partilhado do Trim. | Dado o diálogo de remoção aberto, quando o utilizador introduz um fim anterior ou igual ao início, ou superior à duração do vídeo, então o sistema bloqueia a confirmação, assinala os campos com erro e não regista a operação como pendente. | Refinado |
| REQ-VID-REM-003 | O sistema deve garantir que a duração combinada da(s) parte(s) restante(s) do vídeo é igual ou superior a 1,0 s. | Deve ter | Mantido | NOVO | UC-VID-003, Passo 2; RN3; Exceção 3 | Impede eliminar a quase totalidade do vídeo e produzir resultados nulos (alinhado com o mínimo de 1,0 s do UC-VID-002). | Dado um corte cujo resultado deixe menos de 1,0 s de vídeo útil, quando o utilizador tenta confirmar, então o sistema rejeita a operação com a notificação «A duração resultante do vídeo deve ser igual ou superior a 1,0 s» e mantém o diálogo aberto. | Inalterado |
| REQ-VID-REM-004 | O sistema deve submeter a operação pendente (*staged*) à fila de processamento assíncrono, criando um job de render, quando o utilizador aciona o botão **Aplicar**. | Deve ter | Dividido | NOVO | UC-VID-003, Passo 3; RN5; DQ-001 | Desacopla a confirmação no editor da execução pesada no worker; a atribuição de Job ID (REQ-VID-REM-014) e a sinalização de estado (REQ-VID-REM-015) foram separadas. | Dado um corte pendente validado no editor, quando o utilizador clica em «Aplicar», então existe exatamente uma tarefa correspondente na fila assíncrona de processamento de vídeo. | Dividido |
| REQ-VID-REM-005 | O sistema deve processar a tarefa removendo o segmento indicado, concatenando as partes restantes (ou extraindo a parte contínua quando o corte incide num extremo), preservando a taxa de fotogramas e a sincronização áudio/vídeo do ficheiro original. | Deve ter | Dividido | ALT | UC-VID-003, Passo 4; RN2; A2 | Executa o processamento nuclear com exatidão temporal; a restrição de formato de saída foi separada para REQ-VID-REM-026. | Dado um job de remoção válido na fila, quando o worker conclui a tarefa, então é gerado um novo ficheiro de vídeo sem o trecho eliminado, com desfasamento áudio/vídeo nulo nas junções. | Dividido |
| REQ-VID-REM-006 | O sistema deve registar o novo vídeo no projeto após a conclusão bem-sucedida do render, com identificador e nome derivado próprios, mantendo o vídeo original intacto e acessível (edição não-destrutiva). | Deve ter | Dividido | ALT | UC-VID-003, Passo 5, Passo 7; RN4; A5; Pós-condição de Sucesso | Materializa o modelo não-destrutivo; o registo de metadados foi separado para REQ-VID-REM-016. | Dado o término com sucesso do render, quando o projeto é atualizado, então a lista de vídeos passa a incluir o novo vídeo com nome derivado único no projeto e o vídeo original permanece disponível e reproduzível. | Dividido |
| REQ-VID-REM-008 | O sistema deve permitir ao utilizador pré-visualizar localmente, no cliente, a união das partes restantes antes de aplicar a operação, sem submeter render ao servidor nem consumir quota de operações. | Deveria ter | Refinado | NOVO | UC-VID-003, FA1; A4; DQ-003 | Reduz submissões incorretas e poupa recursos do servidor e quotas do utilizador (alinhado com FA1/REQ-VID-TRIM-003 do UC-VID-002). | Dado um intervalo selecionado no editor, quando o utilizador aciona a pré-visualização, então o reprodutor simula a junção saltando o trecho marcado, sem pedidos de processamento ao servidor nem débito de quota. | Refinado |
| REQ-VID-REM-009 | O sistema deve manter a marcação confirmada no diálogo como operação pendente (*staged*) no editor até à sua submissão via «Aplicar» ou ao seu cancelamento. | Deveria ter | Dividido | NOVO | UC-VID-003, Passo 2; RN5 | Suporta o ciclo de *staging* de RN5 (definição pendente no cliente, submissão explícita); o cancelamento/reajuste foi separado para REQ-VID-REM-022. | Dado um corte confirmado no diálogo, quando a confirmação é aceite, então a operação fica registada como pendente no editor e permanece visível até à submissão ou ao cancelamento. | Dividido |
| REQ-VID-REM-010 | O sistema deve validar a autenticação do utilizador e a permissão de edição no projeto para autorizar a remoção de segmentos, bloqueando o acesso à ferramenta a utilizadores anónimos. | Deve ter | Refinado | ALT | UC-VID-003, RN1; RNG-01 (estendida a UC-VID-003) | Protege os recursos de processamento de vídeo e respeita o controlo de acessos do projeto (alinhado com RN7 do UC-VID-002 e RN1 do UC-VID-001). | Dado um utilizador sem permissão de edição, com sessão expirada ou anónimo, quando tenta aceder à ferramenta de remoção ou aplicar a operação, então o sistema rejeita o pedido com o código de erro correspondente. | Refinado |
| REQ-VID-REM-011 | O sistema deve validar, ao abrir a ferramenta, que o vídeo selecionado está em contentor MP4 com codec de vídeo H.264, rejeitando o acesso com a notificação «Formato de vídeo não suportado para edição» e mantendo o projeto inalterado. | Deve ter | Refinado | ALT | UC-VID-003, Exceção 1; RNG-02 (estendida a UC-VID-003) | Evita submissões incompatíveis com o pipeline partilhado (RN4 do UC-VID-002 e RN2 do UC-VID-001); a decisão sobre codecs de áudio na entrada está pendente (ver 4.4.2). | Dado um vídeo em formato ou codec de vídeo não suportado, quando o utilizador tenta aceder à ferramenta de remoção, então o sistema rejeita o pedido com a notificação «Formato de vídeo não suportado para edição» e mantém o projeto inalterado. | Refinado |
| REQ-VID-REM-012 | O sistema deve recusar a submissão da operação quando a versão do projeto apresentada no editor estiver desatualizada (controlo otimista `X-Project-Version`), assinalando erro de conflito de concorrência. | Deve ter | Dividido | ALT | UC-VID-003, Passo 3; Exceção 5; A1 | Preserva a consistência do projeto em edição concorrente (alinhado com a exceção de versão do UC-VID-001); a instrução ao utilizador foi separada para REQ-VID-REM-021. | Dado um projeto cuja versão foi alterada concorrencialmente por outro utilizador, quando o utilizador clica em «Aplicar», então o sistema rejeita a operação com erro de conflito de concorrência e a tarefa não é enfileirada. | Dividido |
| REQ-VID-REM-013 | O sistema deve notificar o cliente em tempo real (WebSocket / evento de projeto) da conclusão da tarefa, apresentando de imediato o novo vídeo na galeria do projeto com reprodução disponível, sem recarregar a página. | Deve ter | Refinado | NOVO | UC-VID-003, Passo 6; Pós-condição de Sucesso; DQ-004 | Fecha o ciclo assíncrono com visibilidade imediata do resultado no editor. | Dado um job de render concluído com sucesso, quando o evento de conclusão é recebido no cliente, então a galeria do projeto apresenta de imediato o novo vídeo e permite a sua reprodução sem recarregar a página. | Refinado |
| REQ-VID-REM-014 | O sistema deve atribuir um identificador único (*Job ID*) a cada tarefa de remoção aceite. | Deve ter | Novo por divisão | NOVO | UC-VID-003, Passo 3 (divisão de REQ-VID-REM-004); DQ-001 | Isola uma responsabilidade verificável do ciclo assíncrono (alinhado com REQ-VID-TRIM-029 do UC-VID-002). | Dado um pedido aceite, quando se consulta a resposta, então esta contém um Job ID distinto dos anteriores. | Novo |
| REQ-VID-REM-015 | O sistema deve sinalizar no editor o estado **em processamento** desde a aceitação da tarefa até à notificação de conclusão (sucesso ou falha). | Deve ter | Novo por divisão | NOVO | UC-VID-003, Passo 3 (divisão de REQ-VID-REM-004) | Isola uma responsabilidade verificável; o progresso percentual pertence ao âmbito do UC-VID-002 (ver 4.1.3). | Dado uma tarefa aceite, quando o utilizador consulta o editor, então o vídeo apresenta o estado em processamento até à chegada do evento de conclusão. | Novo |
| REQ-VID-REM-016 | O sistema deve registar no novo vídeo os metadados de duração, tamanho em bytes, codec e miniatura na conclusão bem-sucedida do render. | Deve ter | Novo por divisão | NOVO | UC-VID-003, Passo 5 (divisão de REQ-VID-REM-006); A6 | Torna o derivado inspecionável na galeria (alinhado com REQ-VID-TRIM-031 do UC-VID-002); miniaturas específicas do ponto de corte ficam fora do MVP (Q3). | Dado um vídeo concluído, quando se consultam os seus metadados, então constam duração, tamanho, codec e miniatura. | Novo |
| REQ-VID-REM-017 | O sistema deve recusar a gravação do vídeo resultante quando o tamanho acumulado da biblioteca ultrapassaria 1 000 000 000 bytes no plano Free ou 5 000 000 000 bytes no plano Premium, aplicando a proposta de quota acumulada do UC-VID-002, sujeita a harmonização com o UC-VID-001 (Q1). | Deve ter | Novo por harmonização | ALT | Harmonização com REQ-VID-TRIM-021 / RN6 do UC-VID-002; Q1; Exceção (quota de armazenamento) | Aplica o modelo SaaS de capacidade ao novo recurso criado (ver 4.4.2 e 4.4.3). | Dado um vídeo resultante cujo tamanho faria ultrapassar 1 000 000 000 bytes (Free) ou 5 000 000 000 bytes (Premium), quando o sistema tenta gravá-lo, então a gravação é recusada; um total igual ao limite não é recusado por este motivo. | Novo |
| REQ-VID-REM-018 | O sistema deve verificar o saldo da quota diária de operações do perfil Free antes de aceitar a submissão, impedindo-a com mensagem de quota esgotada quando o limite de 5 operações diárias (`FREE_DAILY_OP = 5`) tiver sido atingido. | Deve ter | Novo por harmonização | ALT | UC-VID-003, Passo 3; RN6; A7; harmonização com RN1/REQ-VID-TRIM-005 do UC-VID-002 | Estende o modelo SaaS de operações avançadas à remoção de segmento no pipeline partilhado (A2, A7). | Dado um utilizador Free com saldo de 0 operações no dia corrente, quando tenta aplicar uma remoção, então a operação é impedida com mensagem de quota esgotada e nenhuma tarefa é criada. | Novo |
| REQ-VID-REM-019 | O sistema deve debitar provisoriamente 1 operação da quota diária do perfil Free no momento em que a tarefa de remoção é aceite e enfileirada. | Deve ter | Novo por harmonização | ALT | UC-VID-003, Passo 3; RN6; A7; harmonização com REQ-VID-TRIM-007 do UC-VID-002 | Previne o esgotamento dos workers por submissões concorrentes acima do saldo. | Dado um utilizador Free com saldo de 5 operações, quando submete uma tarefa válida de remoção, então o saldo diário é decrementado para 4 antes do arranque do processamento. | Novo |
| REQ-VID-REM-020 | O sistema deve repor a operação diária debitada ao utilizador Free quando a tarefa falha após a repetição, expira ou tem a gravação recusada por quota de armazenamento. | Deve ter | Novo por harmonização | NOVO | UC-VID-003, Exceção 4 e Exceção (quota de armazenamento); RN6; A7; harmonização com REQ-VID-TRIM-034 do UC-VID-002 | Garante justiça da contabilidade de quotas em falhas não imputáveis ao utilizador (o cancelamento ativo depende de Q5). | Dado um débito provisório, quando a tarefa falha após a repetição, expira ou tem a gravação recusada por quota, então o saldo diário regressa ao valor anterior. | Novo |
| REQ-VID-REM-021 | O sistema deve solicitar a atualização do projeto e a repetição da operação ao utilizador após recusar a submissão por conflito de versão. | Deve ter | Novo por divisão | ALT | UC-VID-003, Exceção 5 (divisão de REQ-VID-REM-012); A1 | Separa a instrução ao utilizador da recusa (alinhado com REQ-VID-UPL-040/041 do UC-VID-001). | Dada a recusa por conflito de versão, quando o utilizador consulta o editor, então a interface indica que o projeto foi alterado por outro utilizador e que deve atualizar o projeto e repetir a operação. | Novo |
| REQ-VID-REM-022 | O sistema deve permitir cancelar ou reajustar a operação pendente (*staged*) no editor antes de acionar «Aplicar», sem gerar tarefas, pedidos ou encargos no servidor. | Poderia ter | Novo por divisão | NOVO | UC-VID-003, FA2; RN5 (divisão de REQ-VID-REM-009) | Concede controlo sobre a marcação antes de qualquer custo (o débito só ocorre na aceitação, REQ-VID-REM-019). | Dado um corte pendente no editor, quando o utilizador cancela a ação, então a marcação é descartada da memória local sem pedidos ao servidor e sem consumo de quota. | Novo |

#### 4.1.2 Requisitos Não Funcionais e de Qualidade

Classificados segundo o modelo de qualidade da norma **ISO/IEC 25010**. Cada requisito distingue o limiar exigido para a aprovação funcional da Fase 1 (**Alvo MVP**) da meta de longo prazo de uma plataforma madura (**Alvo produção**); os valores não foram medidos (ver 4.4.3).

| **ID** | **Requisito (refinado)** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo produção** | **Condição de medição** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** | **Estado** |
|--------|--------------------------|----------------------------------|--------------|-------------------|--------------------------|--------------|----------------------|----------------------------------------|-----------|
| REQ-VID-REM-007 | O sistema deve manter o projeto e o vídeo original inalterados quando a tarefa de remoção falha ou excede o tempo limite de 600 s por tentativa, repetindo a tarefa uma única vez desde o início antes de a marcar como falhada e notificar o erro. | Fiabilidade / Tolerância a falhas e recuperabilidade | Timeout de 600 s por tentativa; uma repetição completa idempotente, sem retoma parcial (DQ-002 do UC-VID-002); alvo não medido. | Três tentativas com retoma parcial como possibilidade futura, fora do MVP; alvo não validado. | Injetar separadamente falha do worker e timeout superior a 600 s; contar uma única repetição; observar estado final, notificação, estorno (REQ-VID-REM-020) e comparar o SHA-256 do vídeo original antes e depois. | Refinado | UC-VID-003, Exceção 4; Pós-condição Mínima; RN4; A2; DQ-001 | Dado um timeout superior a 600 s ou uma falha do worker, quando a falha é detetada, então há exatamente uma repetição; se voltar a falhar, a tarefa fica falhada, o utilizador é notificado, o original mantém o hash idêntico e (se Free) a operação é estornada. | Refinado |
| REQ-VID-REM-023 | O sistema deve eliminar integralmente os ficheiros e fragmentos temporários gerados nos nós de processamento sempre que uma tarefa de remoção finalize, com sucesso ou falha. | Fiabilidade / Limpeza de recursos efémeros | Eliminação síncrona da diretoria temporária de trabalho associada ao Job ID no worker ao concluir a tarefa (DQ-005 do UC-VID-002); alvo não medido. | Eliminação síncrona combinada com processo autónomo de purga periódica de ficheiros órfãos. | Inspecionar a diretoria temporária associada ao Job ID após término com sucesso e com falha; repetir após interrupção do worker. | Novo | UC-VID-003, Exceção 4; A2; DQ-001 | Dado o encerramento de um job de remoção, quando o worker finaliza, então a diretoria temporária do Job ID fica completamente purgada, sem resíduos em disco. | Novo |
| REQ-VID-REM-024 | O sistema deve responder à submissão via «Aplicar» com a aceitação da tarefa e o respetivo Job ID em até 2 s no percentil 95. | Eficiência de desempenho / Comportamento temporal | p95 ≤ 2 s em pedidos válidos; alvo não medido. | p99 ≤ 0,5 s, objetivo futuro sem medição. | Medir no cliente do pedido até à resposta com Job ID, em pelo menos 100 pedidos válidos; calcular o p95; registar hardware, carga, latência de rede e tamanho do vídeo referenciado. | Novo | UC-VID-003, Passo 3; REQ-VID-REM-014; DQ-001 | Dado um conjunto de pelo menos 100 pedidos válidos nas condições fixadas, quando se ordenam os tempos de resposta, então o p95 é ≤ 2 s. | Novo |
| REQ-VID-REM-025 | O sistema deve concluir o processamento (remoção, concatenação e recodificação) em tempo não superior a 1,5 vezes a duração do vídeo resultante em nós de execução de referência ($T_{\text{proc}} \le 1,5 \times \text{duração resultante}$). | Eficiência de desempenho / Eficiência de processamento | Tempo de execução ≤ 1,5 × duração resultante (resultado de 60 s → ≤ 90 s) em worker de 2 vCPU; assunção de capacidade, não medida. | ≤ 0,3 × duração resultante, condicionado a GPU; não validado. | Medir desde o início da execução no worker até ao ficheiro validado, sem espera em fila; usar entrada MP4/H.264 1080p a 30 fps com resultado de 60 s e worker de 2 vCPU; registar preset, disco e carga. | Novo | UC-VID-003, Passo 4; A2; DQ-001 | Dado um vídeo 1080p a 30 fps cujo resultado tem 60 s, quando processado no worker com FFmpeg, então o tempo entre a retirada da fila e a criação do ficheiro final é ≤ 90 s. | Novo |
| REQ-VID-REM-026 | O vídeo resultante exportado deve usar contentor MP4, vídeo H.264 e, quando houver faixa de áudio, áudio AAC. | Compatibilidade / Interoperabilidade multimédia | Saída MP4/H.264 e AAC quando a origem contém áudio; ensaio específico pendente. | Formatos adicionais (VP9, AV1, MKV, WebM) são possibilidades futuras, fora do MVP. | Inspecionar com `ffprobe` o vídeo de entrada e de saída, com e sem faixa de áudio; confirmar MP4/H.264 e AAC quando existir áudio; verificar reprodução no navegador suportado. | Novo | UC-VID-003, Passo 4 (divisão de REQ-VID-REM-005); A6; RNG-02 | Dado o término de uma remoção, quando o ficheiro gerado é inspecionado com `ffprobe`, então o contentor é MP4, o vídeo é H.264 e, se existir áudio, o respetivo codec é AAC. | Novo |
| REQ-VID-REM-027 | O sistema deve impedir o acesso ao vídeo original e ao vídeo resultante por utilizadores sem permissão sobre o projeto, incluindo visitantes anónimos. | Segurança / Confidencialidade e controlo de acesso | Endpoints com autenticação e verificação da permissão sobre o projeto, incluindo partilhas de leitura (alinhado com REQ-VID-TRIM-027 e REQ-VID-UPL-032). | Evolução futura de acesso temporário a objetos privados; política de expiração por decidir. | Testar titular, utilizador com leitura, utilizador com edição, utilizador sem acesso e anónimo sobre o vídeo original e o derivado, incluindo projetos partilhados. | Novo | UC-VID-003, Pré-condições; RN1; DQ-003 (do UC-VID-002) | Dado um vídeo pertencente a um projeto, quando um utilizador sem qualquer permissão ou um visitante anónimo tenta aceder ao URL do vídeo original ou resultante, então o acesso é recusado; quem tenha leitura do projeto pode consultar. | Novo |

Não se define aqui requisito de progresso percentual nem de cancelamento ativo de tarefas em execução: pertencem ao âmbito do UC-VID-002 para o pipeline partilhado; a extensão do cancelamento à remoção é a questão em aberto Q5 (ver 4.1.3 e 4.4.2).

#### 4.1.3 Verificação da completude e dos limites do âmbito

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
|-----------------------|---------------|----------------------------|--------------------------------|
| Formato, codec, duração e dimensão do vídeo | Sim | Entrada limitada a contentor MP4 com vídeo H.264 (REQ-VID-REM-011); saída MP4/H.264 com AAC quando existir faixa de áudio (REQ-VID-REM-026); duração resultante ≥ 1,0 s (REQ-VID-REM-003); resolução e taxa de fotogramas preservadas da origem (REQ-VID-REM-005). Por decisão da equipa, não se aplica à remoção o limite de duração por perfil do UC-VID-002 (180 s Free / 60 min Premium): a remoção apenas encurta o vídeo e o custo computacional é limitado pela quota diária (REQ-VID-REM-018 a 020) e pela quota de armazenamento (REQ-VID-REM-017) — ver 4.4.2. | REQ-VID-REM-003, REQ-VID-REM-005, REQ-VID-REM-011, REQ-VID-REM-026 |
| Estado, progresso, cancelamento e resultado | Parcialmente | O editor sinaliza o estado em processamento (REQ-VID-REM-015) e a conclusão é notificada em tempo real com o novo vídeo disponível (REQ-VID-REM-013). O progresso percentual pertence ao UC-VID-002 e não é introduzido aqui. O cancelamento cobre apenas a operação pendente antes de «Aplicar» (REQ-VID-REM-022, FA2); o cancelamento ativo de tarefa em execução é a questão em aberto Q5. | REQ-VID-REM-013, REQ-VID-REM-015, REQ-VID-REM-022 |
| Falhas durante o processamento | Sim | Falha ou timeout de 600 s no worker implicam uma repetição idempotente e, persistindo a falha, estado falhado com notificação, original e projeto intactos (REQ-VID-REM-007), purga de temporários (REQ-VID-REM-023) e estorno da quota Free (REQ-VID-REM-020). | REQ-VID-REM-007, REQ-VID-REM-020, REQ-VID-REM-023 |
| Persistência e expiração dos ficheiros | Sim | Edição não-destrutiva: o original permanece e o resultado é gravado como novo recurso no projeto (REQ-VID-REM-006), sujeito à quota acumulada proposta (REQ-VID-REM-017, pendente de harmonização com UC-VID-001/002 — Q1); ficheiros temporários purgados (REQ-VID-REM-023). A retenção por eliminação explícita segue a proposta do UC-VID-002 (REQ-VID-TRIM-023), sujeita à mesma harmonização. | REQ-VID-REM-006, REQ-VID-REM-017, REQ-VID-REM-023 |
| Perfis e contagem de operações | Sim | Free: 5 operações diárias (`FREE_DAILY_OP = 5`) com verificação de saldo, débito provisório e estorno (REQ-VID-REM-018 a 020); Premium: ilimitado. Anónimos bloqueados (RN1, RNG-01). Permissão de edição exigida (REQ-VID-REM-010). | REQ-VID-REM-010, REQ-VID-REM-018, REQ-VID-REM-019, REQ-VID-REM-020 |
| Encadeamento de ferramentas e processamento em lote | Não | A remoção opera sobre um único vídeo como ação atómica; o encadeamento sequencial de ferramentas e o processamento em lote ficam formalmente diferidos para fases posteriores (alinhado com a exclusão do UC-VID-002). | — (exclusão explícita fundamentada no âmbito do MVP) |

### 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
|--------------------------------|-------------------------------------------|--------------------------|--------------------------------|
| Pipeline de processamento assíncrono de vídeo (RabbitMQ, workers FFmpeg) | Estender | A infraestrutura assíncrona passa a suportar tarefas de remoção e concatenação de segmentos em paralelo com o *Trim*, partilhando a fila dedicada de vídeo, o timeout de 600 s com repetição idempotente única, a purga de temporários e a emissão de eventos de conclusão (DQ-002/DQ-005 do UC-VID-002). | REQ-VID-REM-004, REQ-VID-REM-005, REQ-VID-REM-007, REQ-VID-REM-014, REQ-VID-REM-023, REQ-VID-REM-024, REQ-VID-REM-025 |
| Gestão de projetos e multimédia (MongoDB, coleção `videos`, `X-Project-Version`) | Manter / Estender | Preserva o modelo de projetos e o controlo de versões otimista, estendendo a inserção não-destrutiva de vídeos derivados com metadados próprios e a deteção de conflitos de concorrência. | REQ-VID-REM-006, REQ-VID-REM-012, REQ-VID-REM-013, REQ-VID-REM-016, REQ-VID-REM-017, REQ-VID-REM-021 |
| Editor multimédia no cliente | Estender | Integração do diálogo de marcação temporal (precisão de 0,01 s), pré-visualização no reprodutor, validação de formatos suportados, sinalização do estado em processamento, gestão da galeria em tempo real e articulação com o botão «Aplicar» (*staging*). | REQ-VID-REM-001, REQ-VID-REM-002, REQ-VID-REM-003, REQ-VID-REM-008, REQ-VID-REM-009, REQ-VID-REM-011, REQ-VID-REM-015, REQ-VID-REM-022 |
| Controlo de acesso e autorização | Manter | Reutiliza a autenticação JWT, a verificação de planos e as permissões de edição partilhada; estende-as ao acesso ao vídeo derivado, incluindo projetos partilhados. | REQ-VID-REM-010, REQ-VID-REM-027 |
| Quota diária de operações (`FREE_DAILY_OP`, `users`) | Alterar | O saldo de 5 operações diárias, hoje aplicado a transformações de imagem e ao *Trim*, passa a ser debitado por cada remoção de segmento no perfil Free, com débito provisório na aceitação e estorno em falha (modelo transacional do UC-VID-002). | REQ-VID-REM-018, REQ-VID-REM-019, REQ-VID-REM-020 |
| Armazenamento de media (SeaweedFS) e quotas de disco | Estender | Gravação do vídeo resultante como novo objeto, sujeita à quota acumulada proposta de 1 GB (Free) / 5 GB (Premium), pendente de harmonização com UC-VID-001/002; purga de temporários nos workers. | REQ-VID-REM-006, REQ-VID-REM-017, REQ-VID-REM-023 |
| Fluxo de imagens e processamento em lote | Manter | O fluxo de imagens e o lote via `.zip` permanecem inalterados; a remoção opera como ação atómica sobre um único vídeo, sem interferência com o subsistema existente. | — (manutenção do comportamento existente) |

### 4.3 Matriz de Rastreabilidade Atualizada

A matriz assegura a rastreabilidade bidirecional entre os elementos do caso de uso, as regras globais, as decisões de qualidade e os requisitos da ERS:

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
|------------------------|-------------------------|--------------------------------|
| UC-VID-003, Âmbito | Editor no cliente e pipeline de processamento assíncrono no servidor | REQ-VID-REM-004, REQ-VID-REM-005, REQ-VID-REM-007, REQ-VID-REM-023 a REQ-VID-REM-025 |
| UC-VID-003, Pré-condições | Autenticação, permissão de edição, saldo de quotas e serviços operacionais | REQ-VID-REM-010, REQ-VID-REM-018, REQ-VID-REM-027 |
| Passo 1 | Seleção de vídeo no projeto e abertura do editor | REQ-VID-REM-001 |
| Passo 2 | Marcação temporal (0,01 s), validação do corte, duração ≥ 1,0 s e registo pendente (*staging*) | REQ-VID-REM-002, REQ-VID-REM-003, REQ-VID-REM-009 |
| Passo 3 | Submissão assíncrona via «Aplicar» com validação de versão, quota, Job ID e sinalização de estado | REQ-VID-REM-004, REQ-VID-REM-010, REQ-VID-REM-012, REQ-VID-REM-014, REQ-VID-REM-015, REQ-VID-REM-018, REQ-VID-REM-019, REQ-VID-REM-024 |
| Passo 4 | Processamento no worker: remoção, concatenação e recodificação | REQ-VID-REM-005, REQ-VID-REM-007, REQ-VID-REM-023, REQ-VID-REM-025, REQ-VID-REM-026 |
| Passo 5 | Gravação não-destrutiva, quota de armazenamento e metadados | REQ-VID-REM-006, REQ-VID-REM-016, REQ-VID-REM-017 |
| Passo 6 | Notificação de sucesso e disponibilização na galeria | REQ-VID-REM-013 |
| Passo 7 | Revisão do novo vídeo e preservação do original | REQ-VID-REM-006 |
| FA1 | Pré-visualização simulada no cliente, sem render nem quota | REQ-VID-REM-008 |
| FA2 | Cancelamento / ajuste de operação pendente (*staged*) | REQ-VID-REM-022 |
| Exceção 1 (Formato inválido) | Rejeição por formato ou codec incompatível (MP4/H.264) | REQ-VID-REM-011 |
| Exceção 2 (Marcação inválida) | Bloqueio de intervalo temporal inconsistente no diálogo | REQ-VID-REM-002 |
| Exceção 3 (Duração insuficiente) | Rejeição de corte que resulte em menos de 1,0 s de vídeo útil | REQ-VID-REM-003 |
| Exceção 4 (Falha no render) | Repetição única, salvaguarda do original, purga e estorno | REQ-VID-REM-007, REQ-VID-REM-020, REQ-VID-REM-023 |
| Exceção 5 (Conflito de versão) | Deteção de concorrência (`X-Project-Version`) e instrução ao utilizador | REQ-VID-REM-012, REQ-VID-REM-021 |
| Exceção (quota de armazenamento) | Recusa da gravação por quota acumulada e estorno | REQ-VID-REM-017, REQ-VID-REM-020 |
| Pós-condição: Sucesso | Novo vídeo no projeto com metadados e original preservado | REQ-VID-REM-006, REQ-VID-REM-013, REQ-VID-REM-016 |
| Pós-condição: Mínima | Projeto e vídeo original intactos, temporários purgados e quota estornada | REQ-VID-REM-007, REQ-VID-REM-020, REQ-VID-REM-023 |
| RN1 | Autenticação e permissão de edição no projeto | REQ-VID-REM-001, REQ-VID-REM-010, REQ-VID-REM-027 |
| RN2 | Consistência do intervalo temporal e tratamento de extremos | REQ-VID-REM-002, REQ-VID-REM-005 |
| RN3 | Duração útil resultante $\ge 1,0\text{ s}$ | REQ-VID-REM-003 |
| RN4 | Edição não-destrutiva por omissão no MVP (novo ficheiro) | REQ-VID-REM-006 |
| RN5 | Submissão via ciclo de *staging* / «Aplicar» | REQ-VID-REM-004, REQ-VID-REM-009, REQ-VID-REM-022 |
| RN6 | Consumo da quota diária de operações (Free: débito provisório e estorno; Premium: ilimitado) | REQ-VID-REM-018, REQ-VID-REM-019, REQ-VID-REM-020 |
| RNG-01 (estendida a UC-VID-003) | Autenticação obrigatória para ferramentas de vídeo (UC-VID-001/002/003) | REQ-VID-REM-010, REQ-VID-REM-027 |
| RNG-02 (estendida a UC-VID-003) | Contentor MP4 e codec de vídeo H.264 na entrada e na saída | REQ-VID-REM-011, REQ-VID-REM-026 |
| A1 | Projetos com controlo de concorrência otimista (`X-Project-Version`) | REQ-VID-REM-012, REQ-VID-REM-021 |
| A2 | Pipeline assíncrono partilhado com o *Trim* (RabbitMQ/FFmpeg) | REQ-VID-REM-007, REQ-VID-REM-023, REQ-VID-REM-024, REQ-VID-REM-025 |
| A3 (harmonizada) | Timeline com precisão de centésimos de segundo | REQ-VID-REM-002 |
| A4 | Pré-visualização simulada localmente no cliente | REQ-VID-REM-008 |
| A5 | Modelo de edição não-destrutiva uniforme | REQ-VID-REM-006 |
| A6 (harmonizada) | Metadados e codecs do novo vídeo na conclusão | REQ-VID-REM-016, REQ-VID-REM-026 |
| A7 (nova) | Modelo transacional de quotas diárias do UC-VID-002 aplicado à remoção | REQ-VID-REM-018, REQ-VID-REM-019, REQ-VID-REM-020 |
| Q1, Q5 | Questões em aberto com impacto na ERS | REQ-VID-REM-017 (Q1); REQ-VID-REM-020 (Q5); restantes sem requisito ativo |

**Decisões de qualidade introduzidas nesta aula**

| **ID** | **Decisão de qualidade** | **Justificação** | **Requisito(s) relacionado(s)** |
|--------|--------------------------|------------------|--------------------------------|
| DQ-001 | Reutilização do pipeline assíncrono partilhado do UC-VID-002 (fila dedicada de vídeo, timeout de 600 s, repetição idempotente única, purga de temporários e eventos de conclusão) | A partilha do pipeline (A2) evita a duplicação de infraestrutura e herda as mesmas garantias de resiliência já especificadas para o *Trim*. | REQ-VID-REM-004, REQ-VID-REM-007, REQ-VID-REM-013, REQ-VID-REM-023 a REQ-VID-REM-025 |
| DQ-002 | Extensão do modelo transacional de quotas diárias (débito provisório na aceitação, estorno em falha) à remoção de segmento | Preserva o modelo SaaS e a justiça da contabilidade entre perfis (RN6, A7), evitando que a remoção contorne o teto diário do Free. | REQ-VID-REM-018, REQ-VID-REM-019, REQ-VID-REM-020 |
| DQ-003 | Pré-visualização local sem custo de servidor nem de quota | Valida a marcação sem encargos, alinhado com FA1 do UC-VID-002 e com o ciclo de *staging* (RN5). | REQ-VID-REM-008 |
| DQ-004 | Notificação de conclusão em tempo real via WebSocket / eventos de projeto | Fecha o ciclo assíncrono sem *polling* nem recarregamento da página. | REQ-VID-REM-013, REQ-VID-REM-015 |

**Verificações de cobertura**

- [x] Todos os requisitos ativos da secção 4.1 (REQ-VID-REM-001 a 027) aparecem na matriz; não há requisitos órfãos nem IDs duplicados.
- [x] Os passos 1 a 7, FA1, FA2, exceções, pós-condições, RN1 a RN6 e assunções A1 a A7 têm cobertura.
- [x] As regras globais RNG-01/RNG-02, estendidas a UC-VID-003 por harmonização, estão registadas com os requisitos correspondentes.
- [x] As exclusões da secção 4.1.3 (progresso percentual, cancelamento ativo, encadeamento e lote) estão fundamentadas.
- [x] O impacto nos componentes existentes (4.2) está ligado aos requisitos atualizados.

---

### 4.4 Registo de Refinamento

#### 4.4.1 Comparação original → refinado

Os textos da coluna «Requisito original» provêm da baseline v1.2 do Exercício 1. Incluem-se apenas os requisitos alterados; REQ-VID-REM-001 e REQ-VID-REM-003 mantêm a formulação e o significado da baseline.

| **ID** | **Requisito original** | **Requisito refinado** | **Problema detetado** | **Ambiguidade resolvida / justificação** |
|--------|------------------------|------------------------|-----------------------|-------------------------------------------|
| REQ-VID-REM-002 | O sistema deve validar a consistência do intervalo marcado para eliminação ($0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração}$) no diálogo do editor. | O sistema deve validar a consistência do intervalo marcado para eliminação ($0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração}$) no diálogo do editor, com marcação temporal em passos de, no máximo, 0,01 s. | Precisão da marcação não quantificada na frase do requisito (apenas na assunção A3, em décimos de segundo). | Adota-se a precisão de centésimos de segundo, harmonizada com a RN3 do UC-VID-002 e com o editor partilhado; a assunção A3 foi atualizada em conformidade. |
| REQ-VID-REM-004 | O sistema deve submeter a operação pendente (*staged*) e criar um job de render assíncrono associado à versão do projeto quando o utilizador aciona o botão **Aplicar**. | O sistema deve submeter a operação pendente (*staged*) à fila de processamento assíncrono, criando um job de render, quando o utilizador aciona o botão **Aplicar**. Separações: REQ-VID-REM-014 (Job ID) e REQ-VID-REM-015 (sinalização de estado). | Requisito composto: submissão, identificação da tarefa e sinalização de estado no editor. | Mantém-se o ID principal; as restantes obrigações passam a 014/015 (a validação de versão já estava isolada em 012). |
| REQ-VID-REM-005 | O sistema deve processar o job removendo o segmento indicado, concatenando as partes restantes (ou preservando a parte contínua se o corte for num extremo) e codificando o resultado num novo ficheiro MP4 (H.264 / AAC). | O sistema deve processar a tarefa removendo o segmento indicado, concatenando as partes restantes (ou extraindo a parte contínua quando o corte incide num extremo), preservando a taxa de fotogramas e a sincronização áudio/vídeo do ficheiro original. Separação: REQ-VID-REM-026 (formato de saída, com AAC apenas quando existir faixa de áudio). | Requisito composto e restrição rígida: exigir AAC incondicional contradiria vídeos de origem sem faixa de áudio (conflito registado também no UC-VID-002). | Mantém-se o ID principal com o processamento nuclear; o formato de saída passa a 026 com AAC condicional, alinhado com REQ-VID-TRIM-012. |
| REQ-VID-REM-006 | O sistema deve associar o novo vídeo gerado ao projeto (edição não-destrutiva), com nome derivado e novos metadados, mantendo o vídeo original intacto. | O sistema deve registar o novo vídeo no projeto após a conclusão bem-sucedida do render, com identificador e nome derivado próprios, mantendo o vídeo original intacto e acessível (edição não-destrutiva). Separação: REQ-VID-REM-016 (metadados). | Requisito composto: registo no projeto e cálculo/escrita de metadados são responsabilidades distintas. | Mantém-se o ID principal; os metadados passam a 016; acrescenta-se a unicidade do nome derivado no projeto, coerente com a RN6 do UC-VID-001. |
| REQ-VID-REM-007 | O sistema deve manter o projeto e o vídeo original intactos caso o job de render falhe ou expire o tempo limite. | O sistema deve manter o projeto e o vídeo original inalterados quando a tarefa de remoção falha ou excede o tempo limite de 600 s por tentativa, repetindo a tarefa uma única vez desde o início antes de a marcar como falhada e notificar o erro. | «Tempo limite» sem valor nem unidade; política de repetição ausente. | Fixa-se 600 s por tentativa e uma repetição idempotente, adotando os alvos do pipeline partilhado (DQ-002/REQ-VID-TRIM-017 do UC-VID-002); a exceção 4 do caso de uso foi explicitada em conformidade. |
| REQ-VID-REM-008 | O sistema deve permitir ao utilizador pré-visualizar localmente a união dos segmentos no cliente antes de aplicar a operação. | O sistema deve permitir ao utilizador pré-visualizar localmente, no cliente, a união das partes restantes antes de aplicar a operação, sem submeter render ao servidor nem consumir quota de operações. | Não excluía expressamente encargos de servidor ou de quota. | Explicita-se a ausência de render e de débito, alinhado com REQ-VID-TRIM-003 e com o ciclo de *staging* (RN5). |
| REQ-VID-REM-009 | O sistema deve permitir registar, cancelar ou reajustar a operação pendente (*staged*) no editor antes de a submeter via «Aplicar». | O sistema deve manter a marcação confirmada no diálogo como operação pendente (*staged*) no editor até à sua submissão via «Aplicar» ou ao seu cancelamento. Separação: REQ-VID-REM-022 (cancelar/reajustar). | Requisito composto (registar + cancelar + reajustar) com prioridade única para comportamentos distintos. | Mantém-se o ID principal com a pendência, elevada para «Deveria ter» por suportar RN5; cancelamento/reajuste passam a 022 como «Poderia ter», preservando a prioridade original de FA2. |
| REQ-VID-REM-010 | O sistema deve validar a autenticação do utilizador e a permissão de edição no projeto para autorizar a remoção de segmentos. *(NF — Segurança)* | O sistema deve validar a autenticação do utilizador e a permissão de edição no projeto para autorizar a remoção de segmentos, bloqueando o acesso à ferramenta a utilizadores anónimos. *(F)* | Classificação não funcional para uma validação comportamental do fluxo; bloqueio de anónimos apenas implícito. | Reclassificado como funcional, conservando ID e intenção (a exemplo das validações de sessão/autorização do UC-VID-001); explicita-se a RNG-01, estendida a UC-VID-003. |
| REQ-VID-REM-011 | O sistema deve validar a compatibilidade do formato e codec do vídeo selecionado com o pipeline de edição, rejeitando a operação caso o formato não seja suportado. *(NF — Compatibilidade)* | O sistema deve validar, ao abrir a ferramenta, que o vídeo selecionado está em contentor MP4 com codec de vídeo H.264, rejeitando o acesso com a notificação «Formato de vídeo não suportado para edição» e mantendo o projeto inalterado. *(F)* | «Formato e codec» vago: não indicava o conjunto suportado nem o momento da validação. | Reclassificado como funcional e quantificado (MP4/H.264), alinhado com a RNG-02 e com a RN4 do UC-VID-002; o tratamento de codecs de áudio na entrada fica registado em 4.4.2. |
| REQ-VID-REM-012 | O sistema deve validar o controlo de versões otimista do projeto (`X-Project-Version`) no momento de aplicar e rejeitar a submissão em caso de conflito de concorrência. *(NF — Fiabilidade)* | O sistema deve recusar a submissão da operação quando a versão do projeto apresentada no editor estiver desatualizada (controlo otimista `X-Project-Version`), assinalando erro de conflito de concorrência. Separação: REQ-VID-REM-021 (instrução ao utilizador). *(F)* | Classificação não funcional para uma validação comportamental; recusa e instrução ao utilizador misturadas. | Reclassificado como funcional (como REQ-VID-UPL-039 do UC-VID-001); a instrução de atualizar e repetir passa a 021 (espelho de REQ-VID-UPL-040/041). |
| REQ-VID-REM-013 | O sistema deve notificar o cliente via WebSocket / evento de projeto após a conclusão do processamento assíncrono, adicionando o novo vídeo à galeria e disponibilizando a sua reprodução. | O sistema deve notificar o cliente em tempo real (WebSocket / evento de projeto) da conclusão da tarefa, apresentando de imediato o novo vídeo na galeria do projeto com reprodução disponível, sem recarregar a página. | «Adicionando à galeria» sobrepõe-se ao registo no projeto (REQ-VID-REM-006); condição de recarregamento implícita. | Clarifica-se que a notificação apresenta o derivado já registado (006) e explicita-se a condição «sem recarregar a página» no critério de aceitação. |

#### 4.4.2 Conflitos com o sistema existente

Confronto com as regras já em vigor para imagem e com as especificações dos UC-VID-001 e UC-VID-002 (limites, quotas, formatos e pipeline partilhado):

| **Requisito(s)** | **Regra existente em conflito** | **Conflito** | **Decisão tomada** |
|------------------|---------------------------------|--------------|--------------------|
| REQ-VID-REM-018 a 020 | A baseline v1.2 do UC-VID-003 não previa contagem de operações; o UC-VID-002 (RN1) debita 1 operação diária (`FREE_DAILY_OP = 5`) por tarefa de vídeo no perfil Free, e a quota já se aplica a transformações de imagem. | Sem contagem na remoção, o perfil Free poderia contornar o teto diário do modelo SaaS usando a remoção em vez do recorte. | Harmonizar: a remoção passa a debitar 1 operação com débito provisório na aceitação e estorno em falha (RN6, A7), replicando o modelo transacional do UC-VID-002. |
| REQ-VID-REM-017 | O UC-VID-001 define 1 GB (Free) / 5 GB (Premium) por ficheiro e deixa a quota acumulada em aberto (QA-002); o UC-VID-002 propõe a acumulação com os mesmos valores (REQ-VID-TRIM-021), pendente de harmonização. | Cada derivado da remoção acresce espaço; sem regra comum, os limites por ficheiro e acumulados divergem entre casos de uso. | Aceitar a proposta acumulada do UC-VID-002 condicionada à decisão conjunta com o UC-VID-001 (Q1); o requisito 017 fica sujeito a essa harmonização. |
| REQ-VID-REM-002, A3 | A RN3 do UC-VID-002 exige precisão de centésimos de segundo nos instantes temporais; a baseline do UC-VID-003 assumia 0,1 s. | O editor partilhado teria de exibir duas precisões diferentes consoante a ferramenta. | Alterar a regra deste dossiê: A3 e REQ-VID-REM-002 passam a centésimos de segundo (0,01 s). |
| REQ-VID-REM-026 | O UC-VID-001 exige MP4/H.264 e não estabelece AAC como condição de aceitação na entrada; a baseline do UC-VID-003 exigia H.264/AAC incondicional na saída. | Um vídeo de origem sem faixa de áudio (aceite no upload) faria falhar uma exigência de AAC incondicional. | Ajustar o requisito: a saída usa AAC apenas quando existir faixa de áudio (alinhado com REQ-VID-TRIM-012); a decisão sobre áudio não-AAC na entrada (transcodificação vs. rejeição) fica pendente, como no UC-VID-002. |
| REQ-VID-REM-005, 018 a 020 | A RN2 do UC-VID-002 limita o vídeo resultante a 180 s (Free) / 60 min (Premium). | Aplicar o mesmo limite à remoção impediria o perfil Free de remover segmentos de vídeos longos já carregados. | Aceitar exceção: sem limite de duração para o resultado da remoção (a operação apenas encurta o vídeo); o custo é limitado pela quota diária e pela quota de armazenamento (ver 4.1.3). |
| REQ-VID-REM-022, Q5 | A FA5 do UC-VID-002 especifica cancelamento cooperativo de tarefas do pipeline partilhado, em fila ou execução (REQ-VID-TRIM-022, 036–038), com estorno. | A remoção partilha a fila (A2), mas o UC-VID-003 só prevê o cancelamento da operação pendente antes de «Aplicar» (FA2). | Registada como questão em aberto Q5: extensão do cancelamento cooperativo e do estorno às tarefas de remoção; sem decisão, não se especifica o comportamento. |
| REQ-VID-REM-004, 007, 023 a 025 | O UC-VID-001 documenta que o processamento de vídeo ainda não está integrado no fluxo `/process` (existe apenas um exemplo de consumidor Python/RabbitMQ). | Publicação de jobs, repetição idempotente, purga e alvos temporais estão especificados sem integração comprovada. | Implementar sobre os componentes existentes e validar estados, deduplicação e limpeza; não inferir garantias do RabbitMQ por si só (como registado no UC-VID-002). |
| REQ-VID-REM-027 | O UC-VID-001 permite leitura e download em projetos partilhados com permissão `read`; a arquitetura serve objetos por autorização de projeto. | Restringir o acesso ao titular contraria a autorização por projeto já demonstrada no UC-VID-001 e adotada no UC-VID-002. | Aplicar as permissões do projeto: a leitura permite consultar o original e o derivado; a remoção exige edição (REQ-VID-REM-010). |

#### 4.4.3 Assunções dos valores fixados

Cada número introduzido ou alterado assenta em dados ou numa assunção. As assunções passam ao Exercício 4.

| **Valor fixado** | **Requisito(s)** | **Base** | **Assunção / fonte** | **Risco se estiver errada** |
|------------------|------------------|----------|----------------------|-----------------------------|
| Timeout de 600 s por tentativa e uma repetição | REQ-VID-REM-007 | Assunção | DQ-002/REQ-VID-TRIM-017 do UC-VID-002 (pipeline partilhado); sem *benchmark* próprio. | Jobs longos podem ser repetidos desnecessariamente ou tarefas úteis abortadas; ensaio de falha pendente. |
| p95 ≤ 2 s na resposta de aceitação (Job ID) | REQ-VID-REM-024 | Assunção | Objetivo do UC-VID-002 (REQ-VID-TRIM-025), dependente de carga e rede; ≥ 100 pedidos válidos. | Espera percebida no botão «Aplicar» acima do alvo sob carga. |
| Processamento ≤ 1,5 × duração resultante (worker 2 vCPU, 1080p/30 fps) | REQ-VID-REM-025 | Assunção | Capacidade presumida no UC-VID-002 (REQ-VID-TRIM-026); *preset*, disco e carga influenciam o resultado. | SLA de processamento descumprido; o alvo de produção (≤ 0,3×) está condicionado a GPU. |
| Quota acumulada de 1 000 000 000 / 5 000 000 000 bytes | REQ-VID-REM-017 | Regra proposta (pendente) | REQ-VID-TRIM-021 / RN6 do UC-VID-002; mesmos números do limite por ficheiro do UC-VID-001; fronteiras da agregação por fixar (Q1). | Vídeos perto do limite aceites ou recusados incorretamente; política global inconsistente. |
| `FREE_DAILY_OP = 5` operações diárias (Free) | REQ-VID-REM-018 a 020 | Regra existente | Modelo `userSchema` do PictuRAS e RN1 do UC-VID-002; débito provisório/estorno conforme REQ-VID-TRIM-007/034. | Se a contagem não for estendida ao worker de vídeo, o teto diário é contornável pela remoção. |
| Precisão de 0,01 s na marcação temporal | REQ-VID-REM-002; A3 | Decisão de harmonização | RN3 do UC-VID-002; editor partilhado. | Se o editor não suportar centésimos, a validação rejeita marcações legítimas ou a precisão efetiva é menor. |
| Duração mínima resultante de 1,0 s | REQ-VID-REM-003 | Dado | RN3 do UC-VID-003, alinhado com o mínimo de 1,0 s do UC-VID-002. | Cortes quase totais gerariam vídeos nulos se o valor estivesse errado. |

**Reflexão:** As ambiguidades mais frequentes neste dossiê foram: (i) termos sem unidade («tempo limite», «formato»), resolvidos com valores e conjuntos explícitos herdados do pipeline partilhado; (ii) classificações F/NF trocadas em validações comportamentais (010, 011, 012), corrigidas por alinhamento com os dossiês do Upload e do Trim; (iii) requisitos compostos que misturavam submissão, identificação de tarefa, sinalização de estado e metadados (004, 006), resolvidos por divisão em IDs novos; (iv) restrições incondicionais que colidiam entre casos de uso (AAC sempre vs. AAC apenas quando existe áudio), resolvidas por harmonização explícita; e (v) valores numéricos adotados de outro dossiê sem medição própria (600 s, p95 ≤ 2 s, ≤ 1,5×), ficando por isso classificados como assunções a passar ao Exercício 4.

---

## ✅ Lista de verificação antes de entregar (Exercício 3)

- [x] As secções 0 a 3 foram preservadas; assunções (A3, A6 e nova A7) e utilização de IA foram atualizadas.
- [x] O âmbito não foi alargado; funcionalidade, caso de uso e perfil mantêm-se (as adições limitam-se à harmonização com regras já em vigor nos UC-VID-001/002, registadas em 4.4.2).
- [x] Não restam termos vagos («tempo limite» → 600 s; «formato» → MP4/H.264; precisão → 0,01 s).
- [x] Cada requisito é atómico; os compostos foram divididos (004 → 014/015; 005 → 026; 006 → 016; 009 → 022; 012 → 021).
- [x] Todos os números têm unidade e condição de medição.
- [x] Cada requisito pode ser testado só a partir da sua frase (critérios *Given/When/Then*).
- [x] Os IDs foram preservados quando a intenção não mudou; nenhum ID eliminado foi reutilizado.
- [x] A tabela 4.4.1 cobre todos os requisitos alterados.
- [x] Os conflitos com o sistema existente estão registados com decisão (4.4.2).
- [x] Cada valor fixado está classificado como dado ou assunção (4.4.3).
- [x] A matriz de rastreabilidade (4.3) reflete os IDs atuais.
