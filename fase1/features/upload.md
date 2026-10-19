# Exercícios 1 e 2 — Dossiê de Requisitos

### Casos de Uso · Fase 1: Suporte a Vídeo no PictuRAS

---

## 0. Identificação

| **Campo** | **Valor** |
| ----------- | ----------- |
| **Grupo / Equipa** | Por atribuir |
| **Autores** | Francisco Barbosa |
| **Data** | 2026-10-14 |
| **Versão do documento** | v2.0 |
| **Unidade Curricular** | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |

---

## 1. Funcionalidade de vídeo escolhida

| **Campo** | **Valor** |
|-----------|-----------|
| **Funcionalidade** | Upload de vídeo para um projeto |
| **Perfil(s) de utilizador abrangido(s)** | Utilizador autenticado com permissão para editar o projeto de destino. |

**Justificação no contexto do MVP** *(2–3 linhas)*  
O upload fornece aos serviços de processamento uma referência persistente para vídeos associados a projetos existentes. O PictuRAS já organiza imagens por utilizador e projeto; o MVP estende esta organização a um vídeo por envio, mantendo o funcionamento das imagens.

---

## 2. Caso de Uso

### 2.1 Cabeçalho

| **Secção** | **Detalhes** |
| ------------ | -------------- |
| **ID do Caso de Uso** | UC-VID-001 |
| **Nome** | Carregar vídeo para um projeto |
| **Versão** | v2.0 |
| **Autor** | Francisco Barbosa |
| **Data** | 2026-10-14 |
| **Objetivo** | Permitir que um utilizador carregue um vídeo para um projeto existente, ficando este associado ao projeto e disponível para processamento posterior. |
| **Âmbito** | Interface web do PictuRAS, API e serviço de armazenamento de ficheiros. |
| **Ator Principal** | Utilizador autenticado com permissão de edição no projeto. |
| **Stakeholders e Interesses** | - **Utilizador**: Pretende adicionar um vídeo ao projeto e receber a confirmação do carregamento.<br>- **Proprietário do sistema**: Pretende armazenar os vídeos de forma organizada e controlar a utilização de espaço e recursos.<br>- **Equipa de desenvolvimento/operações**: Pretende disponibilizar uma referência persistente aos serviços de processamento sem prejudicar o carregamento de imagens. |
| **Pré-condições** | - O utilizador tem sessão iniciada.<br>- O projeto de destino existe e o utilizador tem permissão para o editar. |
| **Trigger** | O utilizador escolhe a opção **Carregar vídeo** num projeto. |

### 2.2 Fluxo Principal

| **Passo** | **Ação do Ator** | **Resposta do Sistema** |
| ----------- | ------------------ | ------------------------- |
| 1 | O utilizador seleciona **Carregar vídeo** no projeto. | Apresenta a opção de selecionar um ficheiro. |
| 2 | O utilizador seleciona um único ficheiro através do seletor do navegador. | Apresenta o nome e o tamanho do ficheiro e verifica preliminarmente a extensão `.mp4` e, quando fornecido pelo navegador, o tipo declarado `video/mp4`. |
| 3 | O utilizador confirma o envio. | Verifica se a sessão continua válida, se o utilizador mantém permissão de edição no projeto, se a versão do projeto está atual, se o tamanho do ficheiro respeita o limite do seu plano e se não existe no projeto um vídeo associado com o mesmo nome completo. |
| 4 | — | Inicia a transferência do ficheiro e informa o utilizador de que a operação está em curso. |
| 5 | — | Após receber o ficheiro, valida definitivamente o conteúdo real, confirmando MP4 válido e codec de vídeo H.264; se a validação for bem-sucedida, armazena o vídeo. |
| 6 | — | Associa o vídeo ao utilizador e ao projeto existente, mantendo uma referência persistente que permite aos serviços de processamento obter o ficheiro. |
| 7 | — | Confirma a conclusão do carregamento e apresenta o vídeo associado na lista de ficheiros do projeto, com nome e tamanho. A referência persistente fica disponível para utilização posterior por serviços de processamento. |

### 2.3 Fluxos Alternativos

| **Fluxo** | **Descrição** |
| ----------- | --------------- |
| FA2 — Desistir antes de enviar | Antes de confirmar o envio no Passo 3, o utilizador decide não prosseguir. O sistema não inicia o envio e o caso de uso termina sem adicionar um vídeo ao projeto. |

### 2.4 Exceções

| **Condição** | **Comportamento do Sistema** |
| -------------- | ------------------------------ |
| No Passo 2, o tipo de ficheiro declarado não corresponde ao formato MP4. | O sistema recusa o ficheiro, informa o utilizador e não inicia o envio. |
| No Passo 3, o ficheiro excede 1 GB (1 000 000 000 bytes) para um utilizador do plano Free ou 5 GB (5 000 000 000 bytes) para um utilizador do plano Premium. | O sistema recusa o envio e informa o utilizador. |
| No Passo 3, a sessão expirou ou a autorização para editar o projeto deixou de ser válida. | O sistema recusa o pedido e informa o utilizador de que tem de iniciar sessão novamente ou obter acesso ao projeto. |
| No Passo 3, já existe no mesmo projeto um vídeo associado com o mesmo nome completo do ficheiro selecionado. | No fluxo normal da interface, o sistema recusa o novo carregamento na pré-validação, antes de iniciar o pedido de transferência do ficheiro, e informa o utilizador de que precisa de alterar o nome. O vídeo existente mantém-se associado ao projeto. |
| No Passo 3, a versão do projeto apresentada ao utilizador está desatualizada. | O sistema recusa o pedido, atualiza os dados do projeto e informa o utilizador de que deve repetir a operação; não associa um novo vídeo. |
| Durante o Passo 4, a ligação é interrompida. | O sistema informa o utilizador de que o envio não foi concluído e não associa nem disponibiliza o vídeo para processamento. Uma nova tentativa começa desde o início. |
| No Passo 5, a validação definitiva deteta que o conteúdo real do ficheiro não corresponde a um vídeo MP4 válido ou que o codec de vídeo não é H.264. | O sistema rejeita o ficheiro, informa o utilizador e não associa nem disponibiliza o vídeo no projeto. |
| No Passo 5, o armazenamento do vídeo falha ou o serviço de armazenamento fica indisponível. | O sistema informa o utilizador de que o carregamento falhou e não associa nem disponibiliza o vídeo para processamento. |
| No Passo 6, a associação ao projeto falha. | O sistema informa o utilizador de que o carregamento não foi concluído e não apresenta o vídeo como disponível para processamento. |

### 2.5 Pós-condições

| **Tipo** | **Resultado** |
|----------|---------------|
| Garantia de Sucesso | O vídeo recebido, validado e armazenado fica associado ao utilizador e ao projeto existente, com referência persistente para processamento posterior. O ficheiro de origem no dispositivo do utilizador não é alterado. |
| Garantia Mínima | Em caso de falha, o vídeo não fica associado como disponível para processamento. O ficheiro de origem no dispositivo do utilizador não é alterado. |

### 2.6 Regras de Negócio e Restrições

| **ID** | **Regra** |
| -------- | ----------- |
| RN1 | **Autorização:** Só um utilizador autenticado com permissão de edição no projeto pode carregar um vídeo para esse projeto. |
| RN2 | **Validação do ficheiro:** O sistema deve aceitar apenas ficheiros de vídeo no formato MP4 com codec de vídeo H.264. Após a receção do ficheiro, a validação definitiva deve verificar o conteúdo real, sem confiar apenas na extensão ou no tipo declarado. O tamanho máximo permitido por ficheiro é de 1 GB (1 000 000 000 bytes) para utilizadores do plano Free e de 5 GB (5 000 000 000 bytes) para utilizadores do plano Premium. |
| RN3 | **Organização:** Cada vídeo carregado com sucesso deve ficar associado ao utilizador e ao projeto de destino. |
| RN4 | **Integridade:** O sistema só deve indicar o vídeo como disponível para processamento depois de confirmar a transferência, validação, armazenamento e associação bem-sucedidos. |
| RN5 | **Eficiência na transferência:** O carregamento de cada vídeo deve ser realizado sem manter o conteúdo integral do ficheiro em memória e com um pico de memória atribuível à transferência não superior a 1 000 000 000 bytes (1 GB), incluindo ficheiros até ao limite máximo permitido pelo plano do utilizador. |
| RN6 | **Nome repetido no projeto:** Se já existir um vídeo associado ao projeto com o mesmo nome completo do ficheiro selecionado, o sistema deve, no fluxo normal do frontend, rejeitar o novo carregamento na pré-validação antes de iniciar o pedido de transferência do ficheiro e informar o utilizador de que precisa de alterar o nome. |

### 2.7 Assunções

| **ID** | **Assunção** |
| -------- | -------------- |
| A1 | A premissa de que o SeaweedFS pode armazenar vídeos e de que os projetos no MongoDB podem manter as respetivas referências foi confirmada pela implementação e por um teste de integração com um MP4 pequeno. |

A1 mantém-se como assunção registada na baseline v1.10, entretanto sustentada pela evidência descrita. As decisões DQ-001 a DQ-005, introduzidas para a qualidade, constam da secção 4.3; não representam decisões atribuídas ao docente ou à equipa.

### 2.8 Questões em Aberto

| **ID** | **Questão pendente** | **Impacto** |
| --- | --- | --- |
| QA-001 | Que valores quantitativos de tempo de resposta e disponibilidade devem ser aprovados para produção? | O limite de memória por upload fica definido em 1 000 000 000 bytes; a medição do pico por upload continua pendente. Os alvos de resposta e disponibilidade também ficam por fixar e medir. |
| QA-002 | Deve existir uma política de retenção ou expiração dos vídeos? Se sim, qual? | A ERS só exige persistência da referência; não define eliminação automática. |
| QA-003 | Qual o nível de concorrência de uploads a suportar em produção? | Alvo inicial: até 5 uploads simultâneos por instância do serviço `projects` e até 2 por utilizador. A capacidade deve ser confirmada por ensaios de carga antes da produção; o alvo ainda não foi validado. |

---

## 3. Utilização de agentes de IA

| **Ferramenta / *skill*** | **Tarefa apoiada** | **Validação realizada pela equipa** |
| -------------------------- | -------------------- | -------------------------------------- |
| GitHub Copilot | Apoio à revisão e redação inicial do caso de uso, registado nas versões anteriores deste documento. | A atribuição da redação inicial consta do documento anterior; a revisão final pelo autor e pela equipa permanece por confirmar. |
| Codex | Apoio à análise do código, à implementação do carregamento de vídeo e à revisão deste caso de uso e à redação e análise da ERS do Exercício 2. | **Verificações automáticas executadas com apoio do Codex:** build e TypeScript do frontend, verificações de sintaxe e integração com MP4 pequeno através do API Gateway, com confirmação da referência no MongoDB e do objeto no SeaweedFS. **Testes manuais comunicados pelo utilizador:** seleção de MP4, apresentação de nome e tamanho, upload bem-sucedido, listagem e persistência após atualização da página, recusa de nome duplicado e limpeza do formulário após erro. Download e Delete foram também testados pelo utilizador no browser como funcionalidades complementares. Os testes manuais não foram executados pelo Codex. Foram ainda comunicados testes de integração em projetos partilhados: com permissão de leitura, listagem e download permitidos e upload e Delete recusados com 403; com permissão de edição, as quatro operações permitidas. Estes testes não constituem validação manual completa da interface. A revisão humana da ERS e a validação pela equipa permanecem pendentes. |

---

## 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-001 — Carregar vídeo para um projeto  
**Versão do dossiê:** v2.0  
**Baseline do Exercício 1:** v1.10; REQ-VID-UPL-001 a REQ-VID-UPL-019 e REQ-VID-UPL-021 a REQ-VID-UPL-031. O REQ-VID-UPL-020 continua reservado e adiado (arrastar e largar). Os requisitos derivados da baseline mantêm o ID; os novos começam em REQ-VID-UPL-032.

O catálogo 4.1 é a fonte única dos requisitos da ERS. **Mantido** preserva a intenção e a formulação; **Refinado** clarifica ou torna verificável a intenção; **Novo** acrescenta uma exigência. **NOVO/ALT** indica o impacto face ao PictuRAS anterior ao suporte a vídeo: NOVO designa comportamento específico de vídeo; ALT designa extensão de mecanismos existentes. A classificação nesta ERS substitui a classificação provisória da baseline. A especificação, a implementação e a validação são estados distintos.

### 4.1 Requisitos da ERS

#### 4.1.1 Requisitos Funcionais

| **ID** | **Requisito** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-VID-UPL-001 | O sistema deve apresentar a opção de selecionar um ficheiro ao utilizador que escolhe **Carregar vídeo** num projeto. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 1; Trigger | Disponibiliza a entrada do fluxo. | Dado um projeto acessível, quando o utilizador escolhe **Carregar vídeo**, então a opção de selecionar um ficheiro é apresentada. |
| REQ-VID-UPL-002 | O sistema deve permitir ao utilizador selecionar um único ficheiro através do seletor do navegador para o carregar no projeto existente. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 2 | Limita cada envio a um ficheiro. | Dado o carregamento aberto, quando o utilizador seleciona um ficheiro no seletor, então esse ficheiro fica selecionado para o envio. |
| REQ-VID-UPL-003 | O sistema deve apresentar o nome do ficheiro selecionado antes da confirmação do envio. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 2 | Permite identificar o ficheiro antes de enviar. | Dado um ficheiro selecionado, então o nome apresentado coincide com o nome desse ficheiro. |
| REQ-VID-UPL-004 | O sistema deve apresentar o tamanho do ficheiro selecionado antes da confirmação do envio. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 2 | Permite conferir a dimensão antes de enviar. | Dado um ficheiro selecionado, então o tamanho apresentado coincide com o tamanho desse ficheiro. |
| REQ-VID-UPL-005 | O sistema deve recusar, na validação preliminar, um ficheiro cujo tipo/formato declarado não corresponda a MP4. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 2; Exceção: tipo/formato declarado | Evita transferências evidentemente incompatíveis. | Dado um ficheiro declarado com tipo/formato diferente de MP4, quando é selecionado, então é recusado antes do envio. |
| REQ-VID-UPL-006 | O sistema deve permitir ao utilizador confirmar o envio do ficheiro selecionado. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 3 | Exige confirmação explícita do utilizador. | Dado um ficheiro selecionado que passou a validação preliminar, então o utilizador consegue confirmar o envio. |
| REQ-VID-UPL-007 | O sistema deve recusar o envio quando a sessão do utilizador não estiver válida na confirmação. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 3; Exceção: sessão ou autorização; RN1 | Protege pedidos após expiração da sessão. | Dada uma sessão expirada, quando o utilizador confirma o envio, então o pedido é recusado. |
| REQ-VID-UPL-008 | O sistema deve recusar o envio quando o utilizador não tiver permissão de edição no projeto na confirmação. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 3; Exceção: sessão ou autorização; RN1 | Respeita permissões em projetos próprios e partilhados. | Dado um utilizador sem permissão de edição, quando confirma o envio, então o pedido é recusado. |
| REQ-VID-UPL-009 | O sistema deve realizar, após a receção do ficheiro, a validação definitiva com base no seu conteúdo real, sem confiar apenas na extensão ou no tipo/formato declarado. | Deve ter | Mantido | NOVO | UC-VID-001 — Passo 5; RN2 | Impede confiar apenas em metadados declarados. | Dado um ficheiro declarado como MP4 mas com conteúdo diferente, quando é recebido, então a validação definitiva avalia o conteúdo real. |
| REQ-VID-UPL-010 | O sistema deve aceitar, na validação definitiva após a receção do ficheiro, apenas ficheiros cujo conteúdo corresponda a um vídeo MP4 válido. | Deve ter | Refinado | NOVO | UC-VID-001 — Passo 5; Exceção: conteúdo inválido; RN2 | Concretiza a restrição de formato de RN2. | Dado um ficheiro renomeado para `.mp4` sem conteúdo MP4 válido, quando termina a receção e ocorre a validação definitiva, então o ficheiro é recusado e não é associado. |
| REQ-VID-UPL-011 | O sistema deve aceitar, na validação definitiva após a receção do ficheiro, apenas ficheiros cujo codec de vídeo seja H.264. | Deve ter | Refinado | NOVO | UC-VID-001 — Passo 5; Exceção: codec inválido; RN2 | Concretiza a restrição de codec de RN2. | Dado um MP4 com codec de vídeo diferente de H.264, quando ocorre a validação definitiva, então o ficheiro é recusado e não é associado. |
| REQ-VID-UPL-012 | O sistema deve recusar ficheiros com tamanho superior a 1 GB (1 000 000 000 bytes) para utilizadores do plano Free. | Deve ter | Refinado | ALT | UC-VID-001 — Passo 3; Exceção: limite de tamanho; RN2 | Aplica o limite Free de RN2. | Dado um utilizador Free, quando confirma um ficheiro acima de 1 000 000 000 bytes, então o envio é recusado; com esse tamanho exato, não é recusado por tamanho. |
| REQ-VID-UPL-013 | O sistema deve recusar ficheiros com tamanho superior a 5 GB (5 000 000 000 bytes) para utilizadores do plano Premium. | Deve ter | Refinado | ALT | UC-VID-001 — Passo 3; Exceção: limite de tamanho; RN2 | Aplica o limite Premium de RN2. | Dado um utilizador Premium, quando confirma um ficheiro acima de 5 000 000 000 bytes, então o envio é recusado; com esse tamanho exato, não é recusado por tamanho. |
| REQ-VID-UPL-014 | O sistema deve iniciar o envio do ficheiro após a confirmação e as verificações de autorização e tamanho, sem depender da validação definitiva do conteúdo. | Deve ter | Mantido | ALT | UC-VID-001 — Passos 3–4 | Ordena confirmação, verificações e transferência. | Dado um ficheiro que passou as verificações de autorização e tamanho, quando o utilizador confirma, então o envio é iniciado antes da validação definitiva. |
| REQ-VID-UPL-015 | O sistema deve indicar ao utilizador que o envio está em curso. | Deve ter | Mantido | NOVO | UC-VID-001 — Passo 4 | Torna visível uma transferência em curso. | Dado um envio iniciado e ainda não concluído, então a interface indica que a operação está em curso. |
| REQ-VID-UPL-016 | O sistema deve associar ao utilizador o vídeo apenas após a receção, validação definitiva e armazenamento bem-sucedidos. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 6; RN3; Garantia de Sucesso | Garante associação ao utilizador após sucesso. | Dado um vídeo recebido, validado e armazenado com sucesso, então fica associado ao utilizador que o carregou; se alguma destas operações falhar, não fica associado. |
| REQ-VID-UPL-017 | O sistema deve associar ao projeto existente uma referência persistente ao vídeo apenas após a receção, validação definitiva e armazenamento bem-sucedidos. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 6; RN3; Garantia de Sucesso | Fornece referência persistente no projeto. | Dado um vídeo recebido, validado e armazenado com sucesso, então o projeto mantém uma referência que permite aos serviços de processamento obter o ficheiro; se alguma destas operações falhar, a referência não fica associada. |
| REQ-VID-UPL-018 | O sistema deve confirmar ao utilizador a conclusão do carregamento apenas após a transferência, validação definitiva, armazenamento e associação bem-sucedidos. | Deve ter | Mantido | NOVO | UC-VID-001 — Passo 7 | Impede uma confirmação prematura. | Concluídas com sucesso as quatro operações, então o utilizador recebe a confirmação; se alguma falhar, não recebe confirmação de sucesso. |
| REQ-VID-UPL-019 | O sistema deve apresentar ao utilizador a identificação do vídeo associado ao projeto após a conclusão bem-sucedida do carregamento. | Deve ter | Mantido | ALT | UC-VID-001 — Passo 7; Garantia de Sucesso | Torna visível o resultado do upload. | Dado um carregamento concluído com sucesso, então o utilizador vê a identificação do vídeo associado ao projeto, sem necessidade de o reproduzir. |
| REQ-VID-UPL-020 | O sistema deve permitir ao utilizador desistir antes de confirmar o envio. | Deve ter | Mantido | ALT | UC-VID-001 — FA2 | Concretiza a desistência antes do envio. | Dado um ficheiro selecionado, quando o utilizador desiste antes da confirmação, então o envio não é iniciado. |
| REQ-VID-UPL-021 | O sistema deve informar o utilizador quando recusar um ficheiro por tipo/formato declarado diferente de MP4. | Deve ter | Mantido | ALT | UC-VID-001 — Exceção: tipo/formato declarado | Explica a recusa preliminar. | Dado um ficheiro declarado como não MP4, quando é selecionado, então o utilizador é informado da recusa. |
| REQ-VID-UPL-022 | O sistema deve informar o utilizador quando recusar um envio por exceder o limite de tamanho do seu plano. | Deve ter | Mantido | ALT | UC-VID-001 — Exceção: limite de tamanho | Explica a recusa por dimensão. | Dado um ficheiro acima do limite do plano, quando o envio é confirmado, então o utilizador é informado da recusa por tamanho. |
| REQ-VID-UPL-023 | O sistema deve informar o utilizador quando recusar o pedido por sessão expirada. | Deve ter | Mantido | ALT | UC-VID-001 — Exceção: sessão ou autorização | Orienta o utilizador após expiração. | Dada uma sessão expirada, quando o envio é confirmado, então o utilizador é informado de que necessita de iniciar sessão novamente. |
| REQ-VID-UPL-024 | O sistema deve informar o utilizador quando recusar o pedido por falta de permissão de edição no projeto. | Deve ter | Mantido | ALT | UC-VID-001 — Exceção: sessão ou autorização | Orienta o utilizador sem acesso de edição. | Dado um utilizador sem permissão de edição, quando confirma o envio, então é informado de que necessita de obter acesso ao projeto. |
| REQ-VID-UPL-025 | O sistema deve informar o utilizador quando o upload falhar por interrupção da transferência, falha no armazenamento ou na associação; perante versão desatualizada, deve atualizar os dados do projeto e indicar que a operação deve ser repetida. | Deve ter | Refinado | NOVO | UC-VID-001 — Exceções: interrupção do envio; armazenamento; associação; versão desatualizada | Comunica falhas e conflito de versão. | Dada uma falha de transferência, armazenamento ou associação, então o utilizador é informado de que o carregamento não foi concluído; perante um conflito de versão, os dados do projeto são atualizados e é indicada a necessidade de repetir a operação. |
| REQ-VID-UPL-026 | O sistema deve informar o utilizador quando recusar, na validação definitiva após a receção, um ficheiro cujo conteúdo não seja um vídeo MP4 válido. | Deve ter | Mantido | NOVO | UC-VID-001 — Passo 5; Exceção: conteúdo inválido | Explica a recusa de conteúdo inválido. | Dado um ficheiro cujo conteúdo não seja um vídeo MP4 válido, quando é validado no Passo 5 após a receção, então o utilizador é informado da recusa e o vídeo não fica associado nem disponível. |
| REQ-VID-UPL-027 | O sistema deve informar o utilizador quando recusar, na validação definitiva após a receção, um ficheiro cujo codec de vídeo não seja H.264. | Deve ter | Mantido | NOVO | UC-VID-001 — Passo 5; Exceção: codec inválido | Explica a recusa de codec não suportado. | Dado um vídeo MP4 com codec de vídeo diferente de H.264, quando é validado no Passo 5 após a receção, então o utilizador é informado da recusa e o vídeo não fica associado nem disponível. |
| REQ-VID-UPL-028 | O sistema deve, no fluxo normal do frontend, recusar o novo carregamento na pré-validação, antes de iniciar o pedido de transferência, quando já existir no mesmo projeto um vídeo associado com o mesmo nome completo do ficheiro selecionado, e informar o utilizador de que precisa de alterar o nome. | Deve ter | Refinado | NOVO | UC-VID-001 — Passo 3; Exceção: nome repetido; RN6 | Evita duplicar nomes no mesmo projeto. | Dado um projeto com um vídeo associado chamado `video.mp4`, quando o utilizador confirma na interface o carregamento de outro ficheiro chamado `video.mp4`, então o pedido de upload não é iniciado, é apresentada a indicação para alterar o nome e o vídeo existente mantém-se associado; noutro projeto, o mesmo nome não causa esta recusa. |
| REQ-VID-UPL-029 | O sistema deve indicar o vídeo como disponível para processamento apenas após a transferência, validação definitiva, armazenamento e associação bem-sucedidos. | Deve ter | Refinado | ALT | UC-VID-001 — Passo 7; RN4; Garantia Mínima | Concretiza a integridade de RN4 e a garantia mínima. | Dada uma falha na transferência, validação, armazenamento ou associação, quando o projeto é consultado, então o vídeo não é indicado como disponível para processamento; após sucesso em todas as etapas, é indicado como disponível. |

Os requisitos REQ-VID-UPL-010 a 013 são restrições funcionais de aceitação, codec e tamanho derivadas de RN2. O REQ-VID-UPL-029, anteriormente apresentado como fiabilidade, exprime igualmente uma condição funcional de disponibilidade; fica nesta tabela, conservando ID e intenção.

#### 4.1.2 Requisitos Não Funcionais e de Qualidade

Os alvos de produção orientam a Fase 2 e carecem de validação própria. Onde não existe valor quantitativo aprovado, o alvo é verificável qualitativamente ou fica explicitamente pendente; não se presume um resultado de teste.

| **ID** | **Requisito** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo produção** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-VID-UPL-030 | O sistema deve transferir vídeos até ao limite do plano sem manter simultaneamente em memória o conteúdo integral do ficheiro. | Eficiência de Desempenho | Transferência progressiva no backend, incluindo para os limites de RN2, sem cópia integral em RAM; pico atribuível a cada upload ≤1 000 000 000 bytes. | Manter o limite por upload sob a concorrência-alvo de QA-003; medir o pico em ensaio próprio. | Refinado | RN5; DQ-001 | Dado um ficheiro próximo do limite do plano, quando é enviado isoladamente, então a medição do pico de memória atribuível ao upload não excede 1 000 000 000 bytes e confirma ausência de cópia integral em memória; validar também sob a concorrência de QA-003. |
| REQ-VID-UPL-031 | O sistema deve impedir que uma falha de transferência ou armazenamento exponha no projeto um vídeo incompleto como carregado com sucesso. | Fiabilidade | Após falha, o vídeo não consta como disponível na listagem nem na referência para processamento. | Além do alvo MVP, definir e verificar a recuperação e limpeza de artefactos temporários; política de recuperação e limpeza ainda por definir. | Novo | UC-VID-001, exceções de transferência e armazenamento; RN4; DQ-002 | Dada uma falha provocada durante transferência ou armazenamento, quando o projeto é consultado, então não há vídeo disponível nem confirmação de sucesso. |
| REQ-VID-UPL-032 | O sistema deve restringir o upload e o acesso à referência do vídeo às permissões do projeto, incluindo projetos partilhados. | Segurança | Upload permitido apenas com edição; a referência segue o controlo de acesso do projeto. | Manter a regra em todos os pontos de acesso, com testes automatizados de autorização para leitura, edição e ausência de sessão. | Novo | RN1; DQ-003 | Dado um projeto partilhado só com leitura, quando o utilizador tenta carregar, então recebe 403; com edição, o upload é autorizado. Um utilizador sem acesso não obtém a referência. |
| REQ-VID-UPL-033 | O sistema deve comunicar de modo distinguível ao utilizador o estado de envio em curso, a conclusão e a falha do upload. | Usabilidade | Indicar que o upload está em curso e comunicar o sucesso ou a falha da operação; não exige percentagem de progresso. | Apresentar também a percentagem de progresso do upload entre 0% e 100%; implementação e critérios de aceitação específicos desta evolução ainda por definir. | Novo | UC-VID-001, passos 4 e 7 e exceções; DQ-004 | MVP: dado um upload iniciado, quando está em curso, então a interface indica esse estado; perante conclusão ou falha, apresenta a respetiva mensagem sem anunciar sucesso indevido. A percentagem de progresso requer critérios e validação futuros; não foi implementada nem validada. |
| REQ-VID-UPL-034 | O sistema deve manter o fluxo de carregamento de imagens utilizável após a introdução do upload de vídeo. | Compatibilidade | O carregamento e a listagem de imagens existentes continuam operacionais. | Manter a compatibilidade nas versões futuras mediante testes de regressão do fluxo de imagens. | Novo | DQ-005; decisão MVP de preservar imagens | Dado um projeto que aceita imagens, quando é carregada e listada uma imagem após a introdução de vídeo, então essas operações continuam a concluir-se. |
| REQ-VID-UPL-035 | O sistema deve manter separadas as referências de vídeos e imagens nos dados do projeto, permitindo alterar o fluxo de vídeo sem modificar a estrutura das imagens existentes. | Manutenibilidade | Metadados de vídeo em `videos`, preservando `imgs`. | Manter a separação e verificar em revisão de esquema e testes de regressão ao evoluir o suporte a vídeo. | Novo | DQ-005; decisão de arquitetura de armazenamento | Dado um projeto com imagens, quando se adiciona um vídeo, então `imgs` conserva as referências existentes e `videos` contém a referência de vídeo. |

Não se define aqui requisito de processamento, portabilidade de ferramentas ou produção de formatos de saída. A classificação **Compatibilidade** em REQ-VID-UPL-034 refere-se à coexistência com o fluxo de imagens; MP4, H.264 e limites de bytes são restrições funcionais em REQ-VID-UPL-010 a 013.

#### 4.1.3 Verificação da completude e dos limites do âmbito

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
| --- | --- | --- | --- |
| Formato, codec, duração e dimensão do vídeo | Sim | O upload aceita apenas MP4 com codec H.264 e aplica os limites de tamanho do ficheiro de 1 GB (Free) e 5 GB (Premium). A duração do vídeo não é critério de aceitação neste caso de uso; não se define nem verifica um limite de duração. | REQ-VID-UPL-005, REQ-VID-UPL-009–013, REQ-VID-UPL-021–022, REQ-VID-UPL-026–027 |
| Estado, progresso, cancelamento e resultado | Parcialmente | A indicação de **upload em curso** e as mensagens de conclusão ou falha integram o MVP. A percentagem de progresso do **upload** (0–100%) é melhoria futura, posterior ao MVP, ainda não implementada. FA2 permite desistir antes da confirmação; o cancelamento após o início do upload está fora do MVP, sem decisão de o implementar. O progresso e os resultados do **processamento** estão fora do âmbito de UC-VID-001. | REQ-VID-UPL-015, REQ-VID-UPL-018–019, REQ-VID-UPL-020, REQ-VID-UPL-024, REQ-VID-UPL-032 |
| Falhas durante o processamento | Não | Falhas de ferramentas de processamento não pertencem ao upload; falhas de rede, armazenamento, validação e associação durante o **upload** são tratadas nas exceções. O exemplo de consumidor Python/RabbitMQ não integra vídeo no fluxo `/process`. | REQ-VID-UPL-025–027, REQ-VID-UPL-029, REQ-VID-UPL-031 |
| Persistência e expiração dos ficheiros | Parcialmente | Vídeo no SeaweedFS e referência/metadados persistentes no MongoDB. Não há política decidida de expiração ou retenção (QA-002); não se cria uma. | REQ-VID-UPL-016–017 |
| Perfis e contagem de operações | Parcialmente | Aplicam-se Free/Premium e permissões de edição, inclusive em projetos partilhados. Não existe regra de contagem de operações definida neste caso; não se introduz quota por número de uploads. | REQ-VID-UPL-007–008, REQ-VID-UPL-012–013, REQ-VID-UPL-022–024, REQ-VID-UPL-032 |
| Encadeamento de ferramentas e processamento em lote | Não | O caso termina com o vídeo carregado e disponível por referência. Encadeamento e lote são funções de processamento e exigiriam outro caso de uso; não são requisitos desta ERS. | N/A; fronteira do UC-VID-001, passo 7 |

### 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
| --- | --- | --- | --- |
| Frontend | Estender | Seleção de um MP4, apresentação de nome/tamanho, pré-validação, conflito de nome, estado e resultado do upload; mantém a interface de imagens. | REQ-VID-UPL-001–006, REQ-VID-UPL-015, REQ-VID-UPL-018–021, REQ-VID-UPL-030, REQ-VID-UPL-032–033 |
| API Gateway | Estender | Verifica sessão, permissão, versão, plano, dimensão e nome antes de encaminhar o corpo; encaminha a transferência progressivamente. | REQ-VID-UPL-007–008, REQ-VID-UPL-012–014, REQ-VID-UPL-022–024, REQ-VID-UPL-029–030, REQ-VID-UPL-031 |
| Serviço `projects` | Estender | Recebe o stream, valida conteúdo e codec após receção, guarda temporariamente, associa a referência apenas após sucesso e trata falhas. | REQ-VID-UPL-009–011, REQ-VID-UPL-016–018, REQ-VID-UPL-025–027, REQ-VID-UPL-029–030, REQ-VID-UPL-031 |
| Nginx | Estender | Encaminha o corpo de upload sem exigir cópia integral em memória da aplicação; configuração de tamanho coerente com os planos. | REQ-VID-UPL-012–014, REQ-VID-UPL-030 |
| SeaweedFS | Estender | Armazena o MP4 validado; falha impede disponibilidade e confirmação de sucesso. | REQ-VID-UPL-016–018, REQ-VID-UPL-029, REQ-VID-UPL-031 |
| MongoDB | Estender | Mantém chave, identificador e metadados persistentes em `videos` no projeto, preservando `imgs`. | REQ-VID-UPL-016–017, REQ-VID-UPL-029, REQ-VID-UPL-034–035 |
| Perfis Free e Premium | Estender | Aplica limites por ficheiro de RN2 sem criar contagem de operações. | REQ-VID-UPL-012–013, REQ-VID-UPL-022 |
| Permissões de projetos partilhados | Estender | Aplica a permissão de edição ao upload; leitura permite operações de consulta autorizadas. | REQ-VID-UPL-007–008, REQ-VID-UPL-023–024, REQ-VID-UPL-032 |
| Fluxo de imagens | Manter | Preserva carregamento, listagem e campo `imgs`; verificar regressão com vídeo presente. | REQ-VID-UPL-034–035 |

O RabbitMQ destina-se à comunicação assíncrona com microserviços de processamento, não à comunicação com MongoDB ou SeaweedFS. Existe um exemplo de consumidor Python, mas o processamento de vídeo não está integrado no fluxo `/process`. Download e Delete são operações complementares, sem novos requisitos neste UC.

### 4.3 Matriz de Rastreabilidade Atualizada

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
| --- | --- | --- |
| Objetivo; Pré-condições; Trigger | Contexto do carregamento e acesso ao projeto; as obrigações operacionais estão nos passos e em RN1. | REQ-VID-UPL-001, REQ-VID-UPL-007, REQ-VID-UPL-008, REQ-VID-UPL-019 |
| Passo 1 | Abrir a opção de seleção. | REQ-VID-UPL-001 |
| Passo 2 | Selecionar um único ficheiro pelo seletor, mostrar nome e tamanho, validar tipo declarado. | REQ-VID-UPL-002, REQ-VID-UPL-003, REQ-VID-UPL-004, REQ-VID-UPL-005 |
| Passo 3 | Confirmar, validar sessão e autorização, verificar o limite de tamanho e a ausência de vídeo com o mesmo nome completo no projeto. | REQ-VID-UPL-006, REQ-VID-UPL-007, REQ-VID-UPL-008, REQ-VID-UPL-012, REQ-VID-UPL-013, REQ-VID-UPL-014, REQ-VID-UPL-028 |
| Passo 4 | Transferir o ficheiro e indicar operação em curso. | REQ-VID-UPL-014, REQ-VID-UPL-015, REQ-VID-UPL-030 |
| Passo 5 | Após a receção, validar definitivamente conteúdo MP4 e codec H.264; armazenar o vídeo validado. | REQ-VID-UPL-009, REQ-VID-UPL-010, REQ-VID-UPL-011, REQ-VID-UPL-016, REQ-VID-UPL-017, REQ-VID-UPL-018, REQ-VID-UPL-026, REQ-VID-UPL-027 |
| Passo 6 | Associar vídeo ao utilizador e referência persistente ao projeto existente. | REQ-VID-UPL-016, REQ-VID-UPL-017 |
| Passo 7 | Confirmar conclusão e identificar vídeo disponível para processamento após transferência, validação, armazenamento e associação bem-sucedidos. | REQ-VID-UPL-018, REQ-VID-UPL-019, REQ-VID-UPL-029 |
| FA2 | Desistir antes de confirmar. | REQ-VID-UPL-020 |
| Exceção: tipo/formato declarado | Recusa preliminar e informação ao utilizador. | REQ-VID-UPL-005, REQ-VID-UPL-021 |
| Exceção: limite de tamanho | Recusa e informação segundo o plano. | REQ-VID-UPL-012, REQ-VID-UPL-013, REQ-VID-UPL-022 |
| Exceção: sessão ou autorização | Recusa e informação sobre o acesso. | REQ-VID-UPL-007, REQ-VID-UPL-008, REQ-VID-UPL-023, REQ-VID-UPL-024 |
| Exceção: nome repetido | No fluxo normal da interface, recusa na pré-validação antes do pedido de upload e indicação para alterar o nome do ficheiro. | REQ-VID-UPL-028 |
| Exceção: versão desatualizada | Recusa do pedido, atualização dos dados do projeto e indicação para repetir a operação. | REQ-VID-UPL-017, REQ-VID-UPL-018, REQ-VID-UPL-025 |
| Exceção: interrupção do envio | Informação sobre a falha; vídeo não associado nem disponível. | REQ-VID-UPL-025, REQ-VID-UPL-029 |
| Exceção: conteúdo inválido ou codec diferente de H.264 | Recusa após a receção, informação ao utilizador e ausência de associação e disponibilidade. | REQ-VID-UPL-009, REQ-VID-UPL-010, REQ-VID-UPL-011, REQ-VID-UPL-016, REQ-VID-UPL-017, REQ-VID-UPL-026, REQ-VID-UPL-027, REQ-VID-UPL-029 |
| Exceção: falha no armazenamento | Informação sobre a falha; vídeo não associado nem disponível. | REQ-VID-UPL-016, REQ-VID-UPL-017, REQ-VID-UPL-018, REQ-VID-UPL-025, REQ-VID-UPL-029 |
| Exceção: falha na associação | Informação sobre a falha; vídeo não apresentado como disponível. | REQ-VID-UPL-017, REQ-VID-UPL-018, REQ-VID-UPL-025, REQ-VID-UPL-029 |
| Garantia de Sucesso | Vídeo armazenado, associado e disponível para processamento por referência persistente; o ficheiro de origem não é alterado. | REQ-VID-UPL-016, REQ-VID-UPL-017, REQ-VID-UPL-018, REQ-VID-UPL-019, REQ-VID-UPL-029 |
| Garantia Mínima | Após falha, o vídeo não fica associado como disponível; o ficheiro de origem não é alterado. | REQ-VID-UPL-025, REQ-VID-UPL-029 |
| RN1 | Autorização para carregar. | REQ-VID-UPL-007, REQ-VID-UPL-008 |
| RN2 | Formato, codec, conteúdo real e limites por plano. | REQ-VID-UPL-005, REQ-VID-UPL-009, REQ-VID-UPL-010, REQ-VID-UPL-011, REQ-VID-UPL-012, REQ-VID-UPL-013 |
| RN3 | Associação ao utilizador e ao projeto. | REQ-VID-UPL-016, REQ-VID-UPL-017 |
| RN4 | Disponibilidade só após transferência, validação, armazenamento e associação bem-sucedidos. | REQ-VID-UPL-029 |
| RN5 | Eficiência de memória durante a transferência de vídeos. | REQ-VID-UPL-030 |
| RN6 | Recusa de novo carregamento quando já existe no projeto um vídeo com o mesmo nome completo. | REQ-VID-UPL-028 |
| RNG-01 | Autenticação obrigatória para UC-VID-001 e UC-VID-002. | REQ-VID-UPL-007, REQ-VID-TRIM-019 |
| RNG-02 | Contentor MP4 e codec de vídeo H.264 em UC-VID-001 e UC-VID-002. | REQ-VID-UPL-010–011, REQ-VID-TRIM-012 |
| A1 | Premissa confirmada: SeaweedFS armazena o MP4 e MongoDB mantém a referência no projeto; não estabelece comportamento adicional a exigir. | Não origina requisito autónomo; relacionada com REQ-VID-UPL-016, REQ-VID-UPL-017. |
| DQ-001 | Transferência progressiva sem cópia integral em RAM e com pico máximo de 1 000 000 000 bytes por upload. | REQ-VID-UPL-030 |
| DQ-002 | Falha de upload não expõe vídeo incompleto. | REQ-VID-UPL-031 |
| DQ-003 | Permissões do projeto abrangem vídeos e projetos partilhados. | REQ-VID-UPL-032 |
| DQ-004 | Estados de envio, sucesso e falha no MVP; percentagem do upload numa evolução futura. | REQ-VID-UPL-033 |
| DQ-005 | Convivência e separação estrutural de imagens e vídeos. | REQ-VID-UPL-034, REQ-VID-UPL-035 |

**Decisões de qualidade introduzidas nesta aula**

| **ID** | **Decisão de qualidade** | **Justificação** | **Requisito(s) relacionado(s)** |
| --- | --- | --- | --- |
| DQ-001 | Preservar transferência progressiva de vídeo, sem cópia integral em RAM e com pico ≤1 000 000 000 bytes por upload. | RN5 e os limites de 1/5 GB tornam a cópia integral inadequada; os buffers de transferência devem permanecer limitados e o teto por upload deve ser verificado em ensaio de memória. O alvo de concorrência é 5 uploads por instância e 2 por utilizador, sujeito a ensaio de carga. | REQ-VID-UPL-030 |
| DQ-002 | Não expor como concluído um upload interrompido ou com falha de armazenamento. | Concretiza a garantia mínima do caso de uso e protege a consistência do projeto. | REQ-VID-UPL-031 |
| DQ-003 | Aplicar controlo de acesso do projeto à operação de upload e à referência do vídeo, inclusive em projetos partilhados. | Evita contornar RN1 e respeita a partilha já existente. | REQ-VID-UPL-032 |
| DQ-004 | Distinguir visualmente envio em curso, conclusão e falha do upload no MVP; acrescentar a percentagem de progresso do upload (0–100%) numa evolução futura posterior ao MVP. | O utilizador precisa de saber se pode usar o vídeo. A antiga QA-003 foi encerrada: a decisão de acrescentar a percentagem está tomada, mas a funcionalidade não está implementada e os seus detalhes técnicos e critérios de aceitação ainda não foram definidos. | REQ-VID-UPL-033 |
| DQ-005 | Preservar o fluxo de imagens e separar referências de imagem e vídeo no projeto. | Evita regressões e permite evolução independente do suporte a vídeo. | REQ-VID-UPL-034–035 |

**Verificações de cobertura**

- [x] Todos os requisitos ativos da secção 4.1 aparecem na matriz; não há requisitos órfãos nem IDs duplicados.
- [x] Os passos 1 a 7, FA2, exceções, pós-condições e RN1 a RN6 têm cobertura.
- [x] As exclusões de processamento, lote, contagem de operações e expiração estão justificadas em 4.1.3.
- [x] O impacto nos componentes existentes está ligado aos requisitos em 4.2.
- [x] REQ-VID-UPL-020 (desistência antes da confirmação) está incluído na matriz ativa.

### 4.4 Estado de implementação e validação (informação complementar ao template)

| Requisito(s) | Estado observado | Evidência e validação ainda necessária |
| --- | --- | --- |
| REQ-VID-UPL-001–004, REQ-VID-UPL-006, REQ-VID-UPL-018–019 | Implementados; percurso positivo testado manualmente no browser pelo utilizador. | Foram comunicados a seleção de um MP4, a apresentação do nome e tamanho, a confirmação e conclusão do upload, a apresentação do vídeo na lista e a persistência após atualizar a página. Os testes automáticos de integração também confirmaram a associação e o armazenamento de um MP4 pequeno. |
| REQ-VID-UPL-005, REQ-VID-UPL-015, REQ-VID-UPL-020–021 | Implementados; validação manual específica não comunicada. | O código contém a recusa preliminar de ficheiros não MP4, a indicação de operação em curso e a possibilidade de fechar o diálogo antes do envio. Permanecem por ensaiar especificamente estes cenários na interface. |
| REQ-VID-UPL-007–008, REQ-VID-UPL-023–024 | Implementados; pré-validação sem sessão e upload sem permissão de edição ensaiados em integração; validação manual completa pendente. | JWT e permissão de edição são verificados no API Gateway e em `projects`; um pedido de pré-validação sem JWT devolveu `401`. Testes de integração comunicados para projeto partilhado só de leitura devolveram `403` no upload e no Delete; listagem e download foram permitidos. Para edição, as quatro operações foram permitidas. Falta validação manual completa da interface. |
| REQ-VID-UPL-009–011, REQ-VID-UPL-026–027 | Implementados; validação positiva testada, negativas pendentes. | Um MP4 pequeno com H.264 passou na validação e foi armazenado. Não há nesta revisão ensaio registado com conteúdo falsamente declarado MP4 ou codec diferente de H.264. |
| REQ-VID-UPL-012–013, REQ-VID-UPL-022 | Implementados; limites exatos ainda não validados. | O backend consulta o plano e compara bytes com 1 000 000 000 (Free) ou 5 000 000 000 (Premium), comunicando excesso. Não foram ensaiados ficheiros nos valores exatos e imediatamente acima deles. |
| REQ-VID-UPL-014, REQ-VID-UPL-016–017 | Implementados; testados com ficheiro pequeno e observados no browser. | O envio de MP4 válido pelo API Gateway foi concluído; a referência surgiu no MongoDB e o objeto foi confirmado no SeaweedFS. A chave e os metadados ficaram no campo `videos`, mantendo `imgs`. O utilizador confirmou a persistência do vídeo na interface após atualizar a página. |
| REQ-VID-UPL-025, REQ-VID-UPL-029 | Implementados no fluxo normal; cenários de falha parcialmente por validar. | A confirmação sucede à validação, ao armazenamento e à associação; foram inspecionados os caminhos de erro e a limpeza do ficheiro temporário. Falhas forçadas de rede, armazenamento e associação não foram ensaiadas nesta revisão. |
| REQ-VID-UPL-030 | Implementado por transferência progressiva e buffers limitados; teto quantitativo definido, medição pendente. | O Nginx encaminha sem buffering do corpo; o API Gateway usa stream com backpressure, `projects` recebe para ficheiro temporário e o SeaweedFS usa multipart com dois blocos de 16 MiB. O limite de pico é 1 000 000 000 bytes por upload; não foi medido em ensaio, isolado ou concorrente. |
| REQ-VID-UPL-028 | Implementado; recusa no browser testada pelo utilizador, restantes cenários pendentes. | O utilizador comunicou a rejeição de um segundo ficheiro com o mesmo nome no projeto e a limpeza do formulário após o erro, permitindo nova seleção. A pré-validação ocorre antes do pedido de upload no fluxo normal do frontend; o API Gateway repete a verificação antes de encaminhar o corpo para `projects`. Não foram registados testes com o mesmo nome em projetos distintos nem medição do tráfego num pedido direto à API. |

Os testes manuais de **Download** e **Delete** no browser foram comunicados pelo utilizador; estas operações permanecem complementares e fora do fluxo principal de UC-VID-001. A pré-validação de RN6 e REQ-VID-UPL-028 antecede o pedido de upload no fluxo normal do frontend. Num pedido direto à API, o cliente pode começar a transmitir bytes até ao Nginx/API Gateway enquanto a verificação decorre; não se afirma ausência absoluta desse tráfego. Continuam pendentes os testes dos limites exatos Free/Premium, de codecs inválidos e conteúdo falso, de falhas provocadas e da medição do pico máximo de memória (1 000 000 000 bytes por upload) com ficheiros próximos dos limites. A listagem do vídeo comprova a associação e a referência para processamento posterior, mas não constitui integração de uma ferramenta de processamento de vídeo.

Os novos requisitos de qualidade REQ-VID-UPL-031 a 035 estão **especificados**; a existência de mecanismos ou testes parciais relacionados não equivale a validação completa dos respetivos alvos. Para REQ-VID-UPL-032 há evidência dos testes de integração de permissões acima. Para REQ-VID-UPL-034–035 há indícios na persistência separada de `videos` e `imgs`, mas falta ensaio de regressão explícito do fluxo de imagens. Para REQ-VID-UPL-033 há observação parcial do percurso positivo, sem ensaio completo dos estados de erro.
