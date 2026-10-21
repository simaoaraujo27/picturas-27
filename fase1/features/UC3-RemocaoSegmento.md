# 📝 Exercício 1 — Caso de Uso: Remover Segmento de Vídeo
### Casos de Uso · Fase 1: Suporte a Vídeo no PictuRAS

---

## 0. Identificação

| **Campo** | **Valor** |
|-----------|-----------|
| **Grupo / Equipa** | PL3 G2 |
| **Autores** | PG63928; Carlos André Barroso Araújo |
| **Data** | 2026-10-17 |
| **Versão do documento** | v1.2 — v1.0 (2026-10-06): secções 0–3; v1.1 (2026-10-14): secção 4; v1.2 (2026-10-17): resolução de contradições lógicas, harmonização de rastreabilidade e refinamento de requisitos (REQ-VID-REM-011 a REQ-VID-REM-013); |
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
| **ID do Caso de Uso** | UC-VID-3 |
| **Nome** | Remover segmento do vídeo |
| **Versão** | v1.2 |
| **Autor** | PG63928; Carlos André Barroso Araújo |
| **Data** | 2026-10-17 |
| **Objetivo** | Permitir ao utilizador eliminar um intervalo temporal indesejado de um vídeo existente num projeto, gerando um novo vídeo resultante da união das partes restantes (ou da parte contínua restante, caso o corte incida num dos extremos), preservando integralmente o ficheiro original. |
| **Âmbito** | Módulo de edição de vídeo do PictuRAS — editor no cliente e pipeline de processamento no servidor. |
| **Ator Principal** | Utilizador autenticado do PictuRAS (plano Free ou Premium), com papel de proprietário ou permissão de edição no projeto. |
| **Stakeholders e Interesses** | - **Proprietário / Editor do Projeto**: eliminar segmentos indesejados sem risco de perda de dados, mantendo o original bruto e obtendo um novo vídeo editado no projeto.<br>- **Visualizadores**: consumir vídeos finais coesos e sem pausas ou trechos desnecessários.<br>- **Proprietário do Sistema**: rentabilizar os planos de subscrição (através de quotas de armazenamento e priorização de tarefas de render) e gerir o esforço computacional dos workers. |
| **Pré-condições** | - O utilizador está autenticado e possui permissão de edição no projeto.<br>- O vídeo de origem encontra-se carregado e registado na lista de vídeos do projeto.<br>- Os serviços de API, media storage e workers de vídeo estão operacionais. |
| **Trigger** | No editor do projeto, o utilizador seleciona a ferramenta **Remover segmento** sobre um vídeo específico. |

### 2.2 Fluxo Principal

| **Passo** | **Ação do Ator** | **Resposta do Sistema** |
|-----------|------------------|-------------------------|
| 1 | O utilizador abre o projeto e seleciona um vídeo para editar | Apresenta o editor com o reprodutor, metadados do vídeo (duração, dimensões, formato) e controlos de edição |
| 2 | O utilizador seleciona a ferramenta **Remover segmento**, marca na timeline o intervalo temporal a eliminar  e confirma a marcação no diálogo | Valida a consistência do corte, destaca visualmente o segmento a eliminar e regista a operação como pendente (*staged*) no editor |
| 3 | O utilizador clica no botão **Aplicar** (*Apply*) na barra de ferramentas do projeto | Valida o controlo de versões do projeto (`X-Project-Version`), cria um job de render assíncrono com a operação pendente, submete-o à fila de processamento e sinaliza visualmente o estado **em processamento** |
| 4 | — | O worker consome a tarefa: descarrega o vídeo original do armazenamento interno, extrai a(s) parte(s) restante(s) exterior(es) ao intervalo marcado e gera o novo ficheiro MP4 |
| 5 | — | Faz o upload do novo vídeo para o armazenamento de media, associa o novo vídeo ao projeto (gerando um novo identificador e nome derivado, preservando o vídeo original, e atualiza a versão do projeto |
| 6 | — | Notifica a conclusão da operação (via WebSocket / evento de projeto), adiciona o novo vídeo à galeria do projeto e disponibiliza de imediato a sua reprodução |
| 7 | O utilizador revê o novo vídeo gerado e fecha o editor ou continua a trabalhar no projeto | Regista a conclusão da operação e mantém ambos os vídeos (original e editado) disponíveis no projeto |

### 2.3 Fluxos Alternativos

| **Fluxo** | **Descrição** |
|-----------|---------------|
| FA1 – Pré-visualizar resultado | Em qualquer momento antes do passo 3, o utilizador solicita a pré-visualização → o reprodutor no cliente simula a reprodução unindo as partes antes e depois do corte (ou saltando a parte inicial/final eliminada), sem requerer render no servidor; o utilizador pode reajustar as marcas (regressa ao passo 2) ou avançar para o passo 3 |
| FA2 – Cancelar ou alterar operação pendente (*staged*) | Antes de acionar o botão **Aplicar** (passo 3), o utilizador cancela a operação ou reabre a ferramenta → o sistema limpa ou atualiza o estado pendente no cliente, sem gerar encargos nem tarefas no servidor |

### 2.4 Exceções

| **Condição** | **Comportamento do Sistema** |
|--------------|------------------------------|
| O formato/codec do vídeo não é compatível com o pipeline de edição (passo 1 / trigger) | Ao validar os parâmetros de entrada e metadados do vídeo, rejeita o pedido, apresenta a notificação «Formato de vídeo não suportado para edição» e mantém o projeto inalterado |
| Marcação temporal inconsistente ou inválida no diálogo (passo 2) | O sistema bloqueia a confirmação no diálogo, assinala os campos com erro e impede o registo da operação como pendente até correção dos valores ($0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração}$) |
| Duração útil restante inferior a 1,0 s no diálogo (passo 2) | O sistema rejeita a confirmação com a notificação «A duração resultante do vídeo deve ser igual ou superior a 1,0 s» e mantém o diálogo aberto para ajuste das marcas |
| O job de render falha ou excede o tempo limite no worker (passo 4) | Notifica o erro («Não foi possível concluir a remoção do segmento»), limpa o estado de processamento; o vídeo original e o projeto permanecem intactos, sem criação de ficheiros corrompidos |
| Conflito de versão no projeto (`X-Project-Version`) no momento de aplicar (passo 3) | Rejeita a submissão com erro de conflito de concorrência («O projeto foi alterado por outro utilizador») e solicita a atualização do projeto antes de submeter novamente a operação |

### 2.5 Pós-condições

| **Tipo** | **Resultado** |
|----------|---------------|
| Garantia de Sucesso | Um novo vídeo (sem o segmento removido) é criado e adicionado ao projeto com metadados próprios e nome derivado; o ficheiro original mantém-se intacto e acessível; a versão do projeto é incrementada |
| Garantia Mínima | O vídeo original permanece inalterado e reproduzível; nenhum ficheiro corrompido é associado ao projeto; o estado de processamento pendente é limpo; o utilizador é notificado da falha |

### 2.6 Regras de Negócio e Restrições

| **ID** | **Regra** |
|--------|-----------|
| RN1 | Apenas utilizadores autenticados (com plano Free ou Premium) com permissão de proprietário ou edição no projeto podem executar a remoção de segmentos em vídeos |
| RN2 | A marcação do segmento a eliminar deve ser consistente: $0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração do vídeo}$. Caso o corte seja intermédio ($0 < t_{\text{início}} < t_{\text{fim}} < \text{duração}$), o resultado une as partes anterior e posterior; caso o corte incida numa das extremidades ($t_{\text{início}} = 0$ ou $t_{\text{fim}} = \text{duração}$), o resultado corresponde à extração simples da parte restante contínua |
| RN3 | A duração combinada do vídeo resultante (soma da(s) parte(s) restante(s)) tem de ser igual ou superior a 1,0 s (não é permitido eliminar a quase totalidade do vídeo) |
| RN4 | A edição é não-destrutiva por omissão no MVP: o ficheiro original nunca é sobrescrito ou eliminado pelo fluxo normal da operação; o resultado da remoção é sempre gravado como um novo recurso multimédia no projeto |
| RN5 | A submissão do processamento ao servidor segue o ciclo de *staging* do editor: a definição do intervalo fica pendente (*staged*) no cliente após confirmação no diálogo e só é submetida ao servidor quando o utilizador aciona o botão **Aplicar** (*Apply*), sujeita à validação da versão do projeto |

### 2.7 Assunções

| **ID** | **Assunção** |
|--------|--------------|
| A1 | O PictuRAS organiza o conteúdo multimédia em torno de Projetos, com controlo de concorrência otimista (`X-Project-Version`) e partilha de acessos |
| A2 | O pipeline de processamento assíncrono (RabbitMQ e Workers com FFmpeg) é partilhado entre operações de vídeo (*Trim*, Remoção de Segmento, etc.) |
| A3 | O editor no cliente fornece uma timeline com precisão mínima de 0,1 s para marcação temporal |
| A4 | A pré-visualização (FA1) é simulada localmente no cliente através do controlo da posição de reprodução do vídeo original |
| A5 | O modelo de edição não-destrutiva é adotado uniformemente, salvaguardando as gravações originais do utilizador contra edições acidentais |
| A6 | Os metadados do novo vídeo (duração, tamanho, miniatura, codec H.264/AAC) são calculados e registados na conclusão bem-sucedida do render |

### 2.8 Questões em Aberto

| **ID** | **Questão** |
|--------|-------------|
| Q1 | Como gerir as quotas globais de armazenamento do utilizador quando múltiplos vídeos derivados (cortes e *trims*) são acumulados no mesmo projeto? |
| Q2 | Deve ser disponibilizada uma opção opcional avançada de «Substituir original» caso o utilizador pretenda poupar espaço no seu plano de armazenamento? |
| Q3 | Devem ser geradas miniaturas (*thumbnails*) específicas na transição do ponto de corte para permitir inspeção visual antes de aplicar o corte definitivo? |
| Q4 | A simulação da pré-visualização no cliente deve suportar transições suaves (ex.: pequeno *crossfade* de áudio) no ponto de junção das partes? |

---

## 3. Utilização de agentes de IA

| **Ferramenta / *skill*** | **Tarefa apoiada** | **Validação realizada pela equipa** |
|--------------------------|--------------------|--------------------------------------|
| OpenCode (agente de IA, modelo GLM) | Elicitação das decisões de desenho iniciais e primeira versão das secções 0–3 | Decisões revistas e discutidas pela equipa |
| OpenCode (agente de IA, modelo GLM) | Derivação inicial da secção 4 (requisitos, impacto e matriz de rastreabilidade) | Revisão manual da formulação e atomicidade dos requisitos |
| Antigravity (agente de IA, DeepMind) | Deteção e resolução de contradições lógicas, harmonização de rastreabilidade (REQ-011 a REQ-013) e correção de ciclo de vida de *staging* | Revisão e validação manual pela equipa |

---
---

## 4. Esboço de requisitos derivados

### 4.1 Requisitos de Sistema

| **ID** | **Requisito** | **Tipo** | **Prioridade** | **Novo/Alt** | **Origem** | **Como verificar** |
|--------|---------------|----------|----------------|--------------|------------|--------------------|
| REQ-VID-REM-001 | O sistema deve permitir ao utilizador com permissão de edição selecionar um vídeo num projeto para remoção de segmento. | F | Deve ter | ALT | Passo 1, RN1 | Dado um utilizador com acesso de edição a um projeto, quando seleciona um vídeo, então o editor carrega a timeline e os metadados do ficheiro. |
| REQ-VID-REM-002 | O sistema deve validar a consistência do intervalo marcado para eliminação ($0\text{ s} \le t_{\text{início}} < t_{\text{fim}} \le \text{duração}$) no diálogo do editor. | F | Deve ter | NOVO | Passo 2, RN2, Exceção 2 (Marcação inválida) | Dado o diálogo de remoção aberto, quando o utilizador introduz um fim anterior ao início ou superior à duração, então o sistema bloqueia a confirmação e assinala o erro. |
| REQ-VID-REM-003 | O sistema deve garantir que a duração combinada da(s) parte(s) restante(s) do vídeo é igual ou superior a 1,0 s. | F | Deve ter | NOVO | Passo 2, RN3, Exceção 3 (Duração insuficiente) | Dado um corte cujo resultado deixe menos de 1,0 s de vídeo útil, quando o utilizador tenta confirmar, então o sistema rejeita a operação com mensagem explicativa. |
| REQ-VID-REM-004 | O sistema deve submeter a operação pendente (*staged*) e criar um job de render assíncrono associado à versão do projeto quando o utilizador aciona o botão **Aplicar**. | F | Deve ter | NOVO | Passo 3, RN5 | Dado um corte pendente no editor, quando o utilizador clica em «Aplicar», então o sistema submete a tarefa à fila de processamento e sinaliza o estado de processamento. |
| REQ-VID-REM-005 | O sistema deve processar o job removendo o segmento indicado, concatenando as partes restantes (ou preservando a parte contínua se o corte for num extremo) e codificando o resultado num novo ficheiro MP4 (H.264 / AAC). | F | Deve ter | ALT | Passo 4, RN2 | Dado um job de remoção válido na fila, quando o worker conclui a tarefa, então é gerado um novo ficheiro de vídeo sem o trecho eliminado. |
| REQ-VID-REM-006 | O sistema deve associar o novo vídeo gerado ao projeto (edição não-destrutiva), com nome derivado e novos metadados, mantendo o vídeo original intacto. | F | Deve ter | ALT | Passo 5, Passo 7, RN4, A5 | Dado o término com sucesso do render, quando o projeto é atualizado, então a lista de vídeos passa a incluir o novo vídeo e o vídeo original permanece disponível. |
| REQ-VID-REM-007 | O sistema deve manter o projeto e o vídeo original intactos caso o job de render falhe ou expire o tempo limite. | NF (Fiabilidade) | Deve ter | ALT | Exceção 4 (Falha render), Pós-condição (Mínima) | Dado um erro simulado no worker, quando a operação falha, então o estado de processamento é limpo e nenhum vídeo inconsistente é adicionado ao projeto. |
| REQ-VID-REM-008 | O sistema deve permitir ao utilizador pré-visualizar localmente a união dos segmentos no cliente antes de aplicar a operação. | F | Deveria ter | NOVO | FA1, A4 | Dado um intervalo selecionado no editor, quando o utilizador aciona a pré-visualização, então o reprodutor simula a junção saltando o trecho marcado sem submeter render. |
| REQ-VID-REM-009 | O sistema deve permitir registar, cancelar ou reajustar a operação pendente (*staged*) no editor antes de a submeter via «Aplicar». | F | Poderia ter | NOVO | Passo 2, FA2, RN5 | Dado um corte pendente no editor, quando o utilizador cancela a ação, então a marcação é descartada da memória local sem impactar o servidor. |
| REQ-VID-REM-010 | O sistema deve validar a autenticação do utilizador e a permissão de edição no projeto para autorizar a remoção de segmentos. | NF (Segurança) | Deve ter | ALT | RN1 | Dado um utilizador sem permissão de edição ou token expirado, quando tenta aplicar a operação, então o sistema rejeita o pedido com código de erro correspondente. |
| REQ-VID-REM-011 | O sistema deve validar a compatibilidade do formato e codec do vídeo selecionado com o pipeline de edição, rejeitando a operação caso o formato não seja suportado. | NF (Compatibilidade) | Deve ter | ALT | Exceção 1 (Formato inválido) | Dado um vídeo em formato ou codec não suportado pelo pipeline de edição, quando o utilizador tenta aceder à ferramenta de remoção, então o sistema rejeita o pedido com a notificação «Formato de vídeo não suportado para edição» e mantém o projeto inalterado. |
| REQ-VID-REM-012 | O sistema deve validar o controlo de versões otimista do projeto (`X-Project-Version`) no momento de aplicar e rejeitar a submissão em caso de conflito de concorrência. | NF (Fiabilidade) | Deve ter | ALT | Passo 3, Exceção 5 (Conflito de versão), A1 | Dado um projeto cuja versão foi alterada concorrencialmente por outro utilizador, quando o utilizador clica em «Aplicar», então o sistema rejeita a operação com erro de conflito e solicita a atualização do projeto. |
| REQ-VID-REM-013 | O sistema deve notificar o cliente via WebSocket / evento de projeto após a conclusão do processamento assíncrono, adicionando o novo vídeo à galeria e disponibilizando a sua reprodução. | F | Deve ter | NOVO | Passo 6, Pós-condição (Sucesso) | Dado um job de render concluído com sucesso, quando o evento de conclusão é recebido no cliente, então a galeria do projeto apresenta de imediato o novo vídeo e permite a sua reprodução sem recarregar a página. |

### 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisitos relacionados** |
|--------------------------------|-------------------------------------------|--------------------------|------------------------------|
| Pipeline de processamento assíncrono de vídeo | Estender | A infraestrutura assíncrona (RabbitMQ e workers FFmpeg) passa a suportar tarefas de remoção e concatenação de segmentos em paralelo com o *Trim*, bem como a emissão de eventos de conclusão. | `REQ-VID-REM-004`, `REQ-VID-REM-005`, `REQ-VID-REM-013` |
| Gestão de projetos e multimédia | Manter / Estender | Preserva o modelo de projetos e controlo de versões (`X-Project-Version`), estendendo a deteção de conflitos de concorrência e a inserção não-destrutiva de novos vídeos derivados na coleção `videos` do projeto. | `REQ-VID-REM-006`, `REQ-VID-REM-007`, `REQ-VID-REM-012` |
| Editor multimédia no cliente | Estender | Integração do diálogo de marcação temporal na timeline, pré-visualização no reprodutor, validação de formatos suportados, gestão da galeria em tempo real e articulação com o botão «Aplicar» (*staging*) do projeto. | `REQ-VID-REM-001`, `REQ-VID-REM-002`, `REQ-VID-REM-003`, `REQ-VID-REM-008`, `REQ-VID-REM-009`, `REQ-VID-REM-011`, `REQ-VID-REM-013` |
| Controlo de acesso e autorização | Manter | Reutiliza os mecanismos existentes de autenticação JWT, verificação de planos de subscrição e permissões de edição partilhada no projeto. | `REQ-VID-REM-010` |

### 4.3 Matriz de Rastreabilidade

| **Elemento do Caso de Uso** | **Descrição abreviada** | **Requisito(s) de Sistema** |
|------------------------------|-------------------------|------------------------------|
| Passo 1 | Seleção de vídeo no projeto | `REQ-VID-REM-001` |
| Passo 2 | Marcação temporal, validação do corte e registo pendente (*staging*) | `REQ-VID-REM-002`, `REQ-VID-REM-003`, `REQ-VID-REM-009` |
| Passo 3 | Confirmação e submissão assíncrona via «Aplicar» com validação de versão | `REQ-VID-REM-004`, `REQ-VID-REM-010`, `REQ-VID-REM-012` |
| Passo 4 | Processamento assíncrono e concatenação no worker | `REQ-VID-REM-005` |
| Passo 5 | Armazenamento e adição não-destrutiva ao projeto | `REQ-VID-REM-006` |
| Passo 6 | Notificação de sucesso e disponibilização no editor | `REQ-VID-REM-013` |
| Passo 7 | Revisão do novo vídeo e preservação do original | `REQ-VID-REM-006` |
| FA1 | Pré-visualização simulada no cliente | `REQ-VID-REM-008` |
| FA2 | Cancelamento / ajuste de operação pendente (*staged*) | `REQ-VID-REM-009` |
| Exceção 1 (Formato inválido) | Rejeição por formato ou codec incompatível | `REQ-VID-REM-011` |
| Exceção 2 (Marcação inválida) | Bloqueio de intervalo temporal inconsistente no diálogo | `REQ-VID-REM-002` |
| Exceção 3 (Duração insuficiente) | Rejeição de corte que resulte em menos de 1,0 s de vídeo útil | `REQ-VID-REM-003` |
| Exceção 4 (Falha no render) | Salvaguarda do original e notificação de erro no worker | `REQ-VID-REM-007` |
| Exceção 5 (Conflito de versão) | Deteção de concorrência no projeto (`X-Project-Version`) | `REQ-VID-REM-012` |
| Pós-condição: Sucesso | Novo vídeo no projeto com metadados e original preservado | `REQ-VID-REM-006`, `REQ-VID-REM-013` |
| Pós-condição: Mínima | Projeto e vídeo original intactos em caso de falha | `REQ-VID-REM-007` |
| RN1 | Autenticação e permissão no projeto | `REQ-VID-REM-001`, `REQ-VID-REM-010` |
| RN2 | Consistência do intervalo temporal e tratamento de extremos | `REQ-VID-REM-002`, `REQ-VID-REM-005` |
| RN3 | Duração útil resultante $\ge 1,0\text{ s}$ | `REQ-VID-REM-003` |
| RN4 | Edição não-destrutiva por omissão no MVP (novo ficheiro) | `REQ-VID-REM-006` |
| RN5 | Submissão via ciclo de *staging* / «Aplicar» | `REQ-VID-REM-004`, `REQ-VID-REM-009` |

---

## ✅ Lista de verificação antes de entregar (Exercício 1)

- [x] Secções 0 a 4 preenchidas e texto de ajuda (`>` e `{…}`) removido.
- [x] Funcionalidade de vídeo escolhida **e justificada** no contexto do MVP.
- [x] Ator principal identificado, com o respetivo perfil.
- [x] Caso de uso com fluxo principal, **≥1 fluxo alternativo** e **≥1 exceção específica de vídeo**.
- [x] Pós-condições com garantia de sucesso **e** garantia mínima.
- [x] Regras de negócio e restrições preenchidas.
- [x] Assunções e questões em aberto registadas.
- [x] Utilização de agentes de IA documentada.
- [x] Esboço de requisitos derivados (Secção 4) totalmente integrado, rastreável e atualizado.
