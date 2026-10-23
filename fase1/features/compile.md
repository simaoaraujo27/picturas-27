# 📝 Exercício 1,2 e 3

### Casos de Uso · Fase 1: Suporte a Vídeo no PictuRAS


## 0. Identificação

| **Campo** | **Valor** |
|-----------|-----------|
| **Grupo / Equipa** | PL3-G2 |
| **Autores** | Lara (pg63995) |
| **Data** | 2026-10-06 |
| **Versão do documento** | v2.0 |
| **Unidade Curricular** | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |

---

## 1. Funcionalidade de vídeo escolhida

| **Campo** | **Valor** |
|-----------|-----------|
| **Funcionalidade** | Compilar vídeos |
| **Perfil(s) de utilizador abrangido(s)** | utilizador autenticado (`free` ou `premium`) — é necessário ter sessão iniciada para aceder a vídeos na biblioteca e iniciar uma operação de compilação |

**Justificação no contexto do MVP** *(2–3 linhas)*
> Porque é que esta funcionalidade é das primeiras a valer a pena construir? Que valor entrega ao utilizador? Sem ela, que parte do suporte a vídeo fica por validar?

A funcionalidade permite juntar dois ou mais vídeos num único ficheiro, dando ao utilizador uma forma de criar uma sequência contínua. No MVP, valida a compilação de vídeos, a preservação dos originais, o armazenamento do resultado e o acompanhamento de uma operação assíncrona.

---

## 2. Caso de Uso

### 2.1 Cabeçalho

| **Secção** | **Detalhes** |
|------------|--------------|
| **ID do Caso de Uso** | UC-VID-004 |
| **Nome** | Compilar vídeos |
| **Versão** | v1.0 |
| **Autor** | Lara Lopes |
| **Data** | 2026-10-06 |
| **Objetivo** | Permitir ao utilizador criar um único vídeo a partir de dois ou mais trechos de vídeos |
| **Âmbito** | Módulo de vídeo do PictuRAS — ferramenta básica |
| **Ator Principal** | Utilizador registado |
| **Stakeholders e Interesses** | - **Utilizador**: Juntar vários vídeos em um único vídeo de forma simples<br>- **Proprietário do Sistema**: Pretende disponibilizar uma funcionalidade sem comprometer os recursos de armazenamento e processamento<br>- **Equipa de Desenvolvimento**: valida o processamento de vários vídeos e a gestão de operações demoradas |
| **Pré-condições** | - O utilizador tem sessão iniciada<br>- Os vídeos já foram submetidos com sucesso e estão disponíveis na biblioteca do utilizador<br>- Existem pelo menos dois vídeos disponíveis para selecionar |
| **Trigger** | O utilizador seleciona dois ou mais vídeos e escolhe a opção **Compilar vídeos** |

### 2.2 Fluxo Principal

| **Passo** | **Ação do Ator** | **Resposta do Sistema** |
|-----------|------------------|-------------------------|
| 1 | O utilizador abre a sua biblioteca de vídeos | Apresenta a lista de vídeos do utilizador |
| 2 | O utilizador seleciona dois ou mais vídeos e escolhe **Compilar vídeos** | Apresenta a lista de vídeos selecionados e permite escolher a ordem|
| 3 | Utilizador escolhe a ordem dos vídeos selecionados | Valida os vídeos selecionados e os parâmetros de operação |
| 4 | | Verifica se o utilizador possui espaço de armazenamento disponível e, no plano Free, quota diária, e reserva a operação |
| 5 | | Cria uma tarefa de processamento e adiciona-a na fila|
| 6 | | Inicia a compilação de vídeos e apresenta o estado "Em Processamento" |
| 7 | | Atualiza o estado enquanto os videos estão a ser processados|
| 8 | | Conclui a compilação e gera um vídeo com o resultado|
| 9 | | Reserva o espaço de armazenamento do resultado e armazena o vídeo na biblioteca do utilizador |
| 10 | | Apresenta o estado como "Concluído", mantendo os vídeos originais|


### 2.3 Fluxos Alternativos

| **Fluxo** | **Descrição** |
|-----------|---------------|
| FA1 – Alteração da ordem dos vídeos | O utilizador altera a ordem dos vídeos antes de confirmar → O sistema utiliza a nova sequência para proceder com o processamento |
| FA2 – Remoção de um vídeo selecionado | O utilizador remove um dos vídeos selecionados antes de confirmar → O sistema atualiza a seleção desde que respeite a regra de mínimo de dois vídeos  |
| FA3 – Vídeos com resolução ou frame rate diferentes | Os vídeos (todos MP4/H.264, conforme RNG-02) têm resolução, frame rate ou áudio diferentes → O sistema normaliza-os antes de os concatenar (resolução do primeiro vídeo, mantendo a proporção com barras, 30 fps, H.264 e áudio AAC estéreo; os vídeos sem áudio recebem silêncio) |


### 2.4 Exceções

| **Condição** | **Comportamento do Sistema** |
|--------------|------------------------------|
| Um dos vídeos selecionados não é legível ou está corrompido | Interrompe o processamento e apresenta o erro: *“Não foi possível ler um dos vídeos”* |
| O utilizador não possui quota de processamento suficiente |  Não inicia a operação e apresenta o erro: *“Não possui quota de processamento suficiente”* |
| Não existe espaço suficiente para armazenar o vídeo resultante (Passo 4 ou Passo 9) | Interrompe o processamento e apresenta o erro *"Não possui armazenamento suficiente"* |
| Ocorre uma falha durante o processamento | Interrompe o processamento e apresenta o erro *"Não foi possível concluir a compilação, tente novamente"* |
| O processamento excede o tempo limite permitido | Interrompe a operação e apresenta o erro *"O processamento excedeu o tempo limite permitido"* |
| O utilizador cancela a operação durante o processamento | Interrompe a operação e não guarda o vídeo incompleto |

### 2.5 Pós-condições

| **Tipo** | **Resultado** |
|----------|---------------|
| Garantia de Sucesso | É criado um vídeo novo com a compilação dos vídeos na respetiva ordem, este é armazenado na biblioteca. os vídeos originais mantêm-se inalterados  |
| Garantia Mínima | O processamento é interrompido, não guarda na biblioteca o vídeo incompleto e os vídeos originais mantêm-se inalterados |

### 2.6 Regras de Negócio e Restrições

| **ID** | **Regra** |
|--------|-----------|
| RN1 | O utilizador deve selecionar no mínimo dois vídeos |
| RN2 | Os vídeos são compilados pela ordem definida pelo utilizador |
| RN3 | Os vídeos originais não sofrem alterações após a operação |
| RN4 | O vídeo resultante deve ser armazenado como um novo ficheiro na biblioteca do utilizador|
| RN5 | A operação só pode ser iniciada se o utilizador tiver quota de processamento suficiente (no plano Free, 5 operações diárias) |
| RN6 | A operação só pode ser concluída se o utilizador tiver armazenamento suficiente (1 GB no plano Free e 5 GB no Premium) |
| RN7 | Durante o processamento o sistema deve mostrar o estado da operação e o respetivo progresso |
| RN8 | Se a operação falhar ou for cancelada o sistema não deve disponibilizar o vídeo incompleto |
| RN9 | Os vídeos de entrada e o resultado têm contentor MP4 e codec de vídeo H.264 (RNG-02) |
| RN10 | A soma das durações dos vídeos selecionados não pode exceder 10 minutos no plano Free nem 1 hora no Premium (valores configuráveis) |
| RN11 | Uma compilação aceita no máximo 10 vídeos (valor configurável) |


### 2.7 Assunções

> Em contexto *brownfield*, assunções não documentadas são a principal fonte de retrabalho. Registe-as aqui.

| **ID** | **Assunção** |
|--------|--------------|
| A1 | Os vídeos estão integralmente armazenados e acessíveis ao serviço no momento do pedido |
| A2 | Os vídeos estão em MP4 com H.264, porque só entram na biblioteca depois de validados pelo carregamento (UC-VID-001) |
| A3 | O sistema possui os recursos necessários para processar os vídeos selecionados |
| A4 | Os vídeos selecionados pertencem ao mesmo projeto e o resultado é adicionado a esse projeto, tal como no recorte (UC-VID-002); o worker lê os vídeos de origem e grava o resultado no mesmo projeto |
| A5 | Cada compilação consome uma operação da quota diária (`FREE_DAILY_OP = 5` no plano Free; sem limite diário no Premium), como o recorte; o serviço `projects` usa o mesmo endpoint interno de quota do serviço `users` |
| A6 | A compilação é iniciada individualmente pelo utilizador e fica fora do encadeamento de ferramentas e do processamento em lote no MVP |


### 2.8 Questões em Aberto

| **ID** | **Questão** | **Estado / Resolução no Exercício 2** |
|--------|-------------|----------------------------------------|
| Q1 | O utilizador pode escolher o formato de vídeo resultante? | **Resolvida.** Não. A entrada e a saída são MP4 com H.264, conforme RNG-02. Ver REQ-VID-COMP-NF-005. |
| Q2 | Existe limite máximo de vídeos selecionados, duração, dimensão ou tamanho por perfil? | **Resolvida.** Máximo de 10 vídeos (RN11); duração total de 10 minutos (`free`) e 1 hora (`premium`) (RN10); sem limite de tamanho por vídeo além do armazenamento acumulado (1 GB e 5 GB). Ver REQ-VID-COMP-020. |
| Q3 | Qual é o prazo de retenção/expiração dos vídeos originais, resultados e ficheiros temporários? | **Em aberto.** Pendente de decisão da equipa. Ver REQ-VID-COMP-022. |
| Q4 | Como é contabilizada a quota: por operação, por vídeo ou pela duração total processada? | **Resolvida.** Por operação, como no recorte (5 por dia no `free`, sem limite diário no `premium`): reservada no pedido, confirmada na conclusão e estornada em falha definitiva ou cancelamento. Ver REQ-VID-COMP-021. |
| Q5 | A compilação pode ser usada em encadeamentos de ferramentas ou em processamento em lote? | **Resolvida para o MVP.** Fica fora do âmbito (assunção A6 e A7 do Exercício 4). |

---

## 3. Utilização de agentes de IA

> Obrigatório em todas as fases do projeto. A equipa é responsável pelo conteúdo entregue, incluindo o gerado por IA. Se não usou agentes de IA, escreva-o.

| **Ferramenta / *skill*** | **Tarefa apoiada** | **Validação realizada pela equipa** |
|--------------------------|--------------------|--------------------------------------|
| ChatGPT | Apoio à revisão e ao preenchimento da ERS, organização dos requisitos, critérios de aceitação e rastreabilidade | Foi tudo verificado para ficar coerente com o projeto |
| Claude | Apoio à implementação da compilação, incluindo a escrita e revisão de código para o frontend, backend e worker de processamento, bem como a integração dos componentes necessários à compilação assíncrona de vídeos. | Foi tudo revisto para ficar coerente|

---

## 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-004 — Compilar dois ou mais vídeos (*Compile*)   
**Versão do dossiê:** v2.0  
**Baseline do Exercício 2:** v2.0 — documento de 06-10-2026

### 4.1 Requisitos da ERS (refinados)

#### 4.1.1 Requisitos Funcionais

| **ID** | **Requisito (refinado)** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** | **Estado** |
|--------|--------------------------|----------------|--------------|--------------|--------------------------------|-----------------|----------------------------------------|-----------|
| REQ-VID-COMP-001 | O sistema deve apresentar os vídeos disponíveis na biblioteca do utilizador | F (funcional) | Deve ter | ALT | Passo 1 | Representação visual dos vídeos disponíveis do utilizador | Dado um utilizador autenticado, quando abre a biblioteca, então a lista dos seus vídeos é apresentada | Inalterado |
| REQ-VID-COMP-002 | O sistema deve permitir a seleção de dois ou mais vídeos para avançar com a compilação | F (funcional) | Deve ter | NOVO | Passo 2 | Fornece feedback visual contínuo |  Dado um utilizador na biblioteca, quando escolhe a operação *Compile*, é mostrada a interface apresentando o local de seleção dos vídeos, reordenar vídeos e iniciar operação | Inalterado |
| REQ-VID-COMP-003 | O sistema deve permitir ao utilizador escolher a ordem dos vídeos selecionados | F (funcional) | Deve ter | NOVO | Passo 2,FA1,RN2 | Fornece atualização contínua da escolha de ordem de vídeos | Dado um conjunto de vídeos selecionados quando o utilizador muda a ordem a nova sequência é registada | Inalterado |
| REQ-VID-COMP-004 | O sistema deve validar os vídeos selecionados pelo utilizador | F (funcional) | Deve ter | NOVO | Passo 3 | Processamento dos vídeos selecionados | Dado um pedido de compilação o sistema inicia a validação dos vídeos | Inalterado |
| REQ-VID-COMP-005 | O sistema deve verificar se o utilizador tem quota suficiente para avançar com a operação de compilação | F (funcional) | Deve ter | ALT | Passo 4,RN5,Exceção 2 | Assegura as regras dos respetivos planos do pictuRAS | Dado o pedido de compilação quando não existir quota suficiente não avança com o pedido | Inalterado |
| REQ-VID-COMP-006 | O sistema deve verificar se o utilizador tem armazenamento suficiente para guardar o vídeo resultante | F (funcional) | Deve ter | ALT | Passo 9, RN6, Exceção 3 | Evita ultrapassar a capacidade de armazenamento permitida ao utilizador | Dado um pedido de compilação, quando o espaço disponível não é suficiente, o sistema rejeita o pedido e informa o utilizador antes de disponibilizar o resultado | Refinado |
| REQ-VID-COMP-007 | O sistema deve criar uma tarefa de processamento para a compilação dos vídeos selecionados | F (funcional) | Deve ter | NOVO | Passo 5 | Organização de operações para não exceder recursos | Dado um pedido válido o sistema cria uma tarefa de processamento | Inalterado |
| REQ-VID-COMP-008 | O sistema deve avançar com a operação de compilação dos vídeos pela ordem escolhida | F (funcional) | Deve ter | NOVO | Passo 6,RN2 | Coerência com o pedido de operação | Dado uma sequência de vídeos o sistema compila para obter o resultado final | Inalterado |
| REQ-VID-COMP-009 | O sistema deve apresentar o estado da operação durante o processamento | F (funcional) | Deve ter | ALT | Passo 7,RN7 | O processamento não é instantâneo, o utilizador precisa de acompanhar | Dado um pedido em execução, quando o utilizador consulta o estado, o sistema mostra o estado atual | Inalterado |
| REQ-VID-COMP-010 | O sistema deve gerar o vídeo novo da compilação pedida | F (funcional) | Deve ter | NOVO | Passo 8,Pós-condição Sucesso | Resultado da operação final | Dado um processamento bem sucedido, quando termina a compilação é criado um vídeo novo | Inalterado |
| REQ-VID-COMP-011 | O sistema deve armazenar o vídeo na biblioteca do utilizador | F (funcional) | Deve ter | ALT | Passo 9,RN4,Pós-condição de sucesso | | Dado uma compilação concluída, quando o processamento termina, o vídeo é guardado na biblioteca | Inalterado |
| REQ-VID-COMP-012 | O sistema deve manter os vídeos originais inalterados | F (integridade) | Deve ter | ALT | Passo 10, RN3, pós-condição de sucesso | Evita perda ou alteração dos ficheiros de origem | Após uma compilação bem-sucedida ou falhada, os ficheiros originais continuam acessíveis e com o mesmo conteúdo | Inalterado |
| REQ-VID-COMP-013 | O sistema deve impedir o início da compilação quando estiver selecionado menos de dois vídeos | F (funcional) | Deve ter | NOVO | RN1, FA2 | Garante o número mínimo de entradas necessário à operação | Dada uma seleção com zero ou um vídeo, quando o utilizador tenta iniciar a compilação, o sistema impede a operação e informa que são necessários pelo menos dois vídeos | Resolvido |
| REQ-VID-COMP-014 | O sistema deve aceitar na compilação apenas vídeos do projeto em contentor MP4 com codec de vídeo H.264 (RNG-02), recusando com mensagem de erro qualquer outro formato | F (funcional) | Deve ter | NOVO | FA3, RN9 | Garante entradas compatíveis entre si | Dado um vídeo noutro contentor ou codec, quando se pede a compilação, o pedido é recusado com UNSUPPORTED_VIDEO (HTTP 415) e a tarefa não é criada | Resolvido |
| REQ-VID-COMP-015 | O sistema deve impedir o processamento se algum dos vídeos estiver corrompido ou ilegível | F (funcional) | Deve ter | NOVO | Exceção 1 | Evita iniciar uma tarefa que não pode ser concluída | Dado que pelo menos um vídeo está corrompido ou ilegível, quando ocorre a validação, o sistema não inicia a compilação | Resolvido |
| REQ-VID-COMP-016 | O sistema deve apresentar uma mensagem clara quando algum dos vídeos estiver corrompido ou ilegível | F (funcional) | Deve ter | NOVO | Exceção 1 | Ajuda o utilizador a compreender por que motivo a operação não avançou | Dado um vídeo corrompido ou ilegível, o sistema apresenta a mensagem “Não foi possível ler um dos vídeos” | Resolvido |
| REQ-VID-COMP-017 | O sistema não deve disponibilizar nem guardar na biblioteca o vídeo resultante incompleto após falha ou cancelamento | NF (Fiabilidade) | Deve ter | ALT | RN8, exceções 4 e 6, pós-condição mínima | Preserva a consistência da biblioteca e evita resultados inválidos | Dada uma tarefa que falha ou é cancelada, quando termina, não existe vídeo parcial acessível na biblioteca e os originais permanecem inalterados | Resolvido |
| REQ-VID-COMP-018 | O sistema deve atualizar o progresso da operação pelo menos a cada 5 segundos enquanto houver informação de progresso disponível | F (funcional) | Deveria ter | ALT | RN7 | Permite acompanhar uma operação demorada | Durante uma compilação em curso, o valor de progresso apresentado é atualizado em intervalos não superiores a 5 segundos, quando o processador disponibiliza essa informação | Resolvido |
| REQ-VID-COMP-019 | O sistema deve interromper a tarefa quando esta exceder o limite de tempo de processamento configurado | NF (Eficiência de Desempenho) | Deveria ter | NOVO | Exceção 5 | Evita tarefas indefinidamente ativas e consumo ilimitado de recursos | Dada uma tarefa que ultrapassa o limite configurado, o sistema interrompe-a, marca-a como falhada e informa o utilizador | Resolvido |
| REQ-VID-COMP-020 | O sistema deve aplicar os limites de duração, tamanho e número de vídeos definidos para o perfil do utilizador | F (funcional) | Deve ter | NOVO | Decisão de âmbito, perfis de utilização | Impede pedidos que excedam os limites do perfil | Dado um pedido que excede um limite configurado para o perfil, o sistema rejeita-o antes de iniciar o processamento e indica o motivo | Resolvido |
| REQ-VID-COMP-021 | O sistema deve contabilizar a utilização da quota de acordo com a regra de contabilização definida para o serviço | F (funcional) | Deve ter | NOVO | RN5, decisão de âmbito | Garante aplicação consistente das quotas | Após um pedido aceite e processado, a utilização registada corresponde à regra de quota documentada | Resolvido |
| REQ-VID-COMP-022 | O sistema deve aplicar a política de retenção definida aos vídeos originais, resultados e ficheiros temporários | F (funcional) | Deveria ter | NOVO | Decisão de âmbito, persistência | Evita retenção indefinida e clarifica o ciclo de vida dos ficheiros | Num teste com ficheiros cuja retenção expirou, o sistema aplica a política acordada; os prazos concretos devem ser definidos pela equipa | Pendente de decisão |


#### 4.1.2 Requisitos Não Funcionais e de Qualidade

| **ID** | **Requisito (refinado)** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo produção** | **Condição de medição** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** | **Estado** |
|--------|--------------------------|----------------------------------|--------------|------------------|--------------------------|--------------|----------------------|----------------------------------------|-----------|
| REQ-VID-COMP-NF-001 | O sistema deve confirmar a receção de um pedido válido sem esperar pela conclusão da compilação, colocando o trabalho em processamento assíncrono. | Eficiência de Desempenho | Confirmação em menos de 3 s, em condições normais | Confirmação em menos de 1 s | Medir o tempo entre a submissão do pedido e a resposta de aceitação, com vários tamanhos de vídeo | Deve ter | Decisão de qualidade (DQ1), REQ-VID-COMP-007 | Em testes repetidos, o pedido é aceite ou rejeitado rapidamente e o utilizador pode continuar a usar a aplicação | Proposto |
| REQ-VID-COMP-NF-002 | O sistema deve manter os ficheiros de entrada e o resultado inacessíveis a utilizadores que não sejam o proprietário autorizado. | Segurança | Obrigatório | Obrigatório | Tentar consultar ou descarregar os vídeos com uma sessão de outro utilizador | Deve ter | Decisão de qualidade (DQ2), REQ-VID-COMP-001, REQ-VID-COMP-011 | O acesso não autorizado é recusado | Proposto |
| REQ-VID-COMP-NF-003 | O sistema deve garantir que uma falha ou cancelamento não deixa um vídeo parcial disponível na biblioteca. | Fiabilidade | Estado final “Falhado” ou “Cancelado”, sem resultado parcial acessível | Recuperação ou repetição controlada, sem duplicar resultados | Interromper um trabalho durante o processamento e verificar a biblioteca e os ficheiros temporários | Deve ter | DQ3, RN8, REQ-VID-COMP-017 | Não existe resultado incompleto acessível ao utilizador e os originais permanecem inalterados | Proposto |
| REQ-VID-COMP-NF-004 | O sistema deve apresentar o estado da tarefa e atualizar o progresso durante o processamento, sem exigir que o utilizador mantenha a página aberta. | Usabilidade / Eficiência de Desempenho | Atualização do progresso pelo menos a cada 5 s quando o progresso estiver disponível | Atualização contínua ou por eventos, sem pedidos excessivos | Acompanhar uma tarefa de compilação e comparar o estado apresentado com o estado real | Deveria ter | DQ4, RN7, REQ-VID-COMP-009, REQ-VID-COMP-018 | O estado é coerente e o utilizador consegue consultar o resultado após regressar à aplicação | Proposto |
| REQ-VID-COMP-NF-005 | O sistema deve verificar a legibilidade dos vídeos antes de iniciar a compilação e produzir o resultado em MP4 com H.264 e áudio AAC (RNG-02). | Adequação Funcional / Compatibilidade | MP4/H.264 na entrada e na saída (RNG-02) | MP4/H.264, com outros perfis só por decisão explícita | Testar ficheiros válidos, corrompidos e de formato não suportado | Deve ter | DQ5, REQ-VID-COMP-004, REQ-VID-COMP-014, REQ-VID-COMP-015 | Vídeos ilegíveis fazem a tarefa falhar sem gerar resultado; o resultado é MP4 com H.264 e AAC | Proposto |
| REQ-VID-COMP-NF-006 | O sistema deve isolar a execução de cada tarefa de compilação e limitar os recursos consumidos para evitar afetar outras operações. | Fiabilidade / Eficiência de Desempenho | Limite de tempo e recursos configurado; sem bloqueio da interface | Limites configuráveis, monitorização e controlo de concorrência | Executar tarefas concorrentes e verificar que os limites são respeitados | Deveria ter | DQ6, RN5, REQ-VID-COMP-007, REQ-VID-COMP-019 | Uma tarefa não impede a utilização normal da aplicação e termina quando excede o limite configurado | Proposto |
| REQ-VID-COMP-NF-007 | O sistema deve permitir alterar ou acrescentar o mecanismo de processamento de vídeo sem exigir alterações às funcionalidades de biblioteca e autenticação. | Manutenibilidade | Separação básica entre pedido, processamento e armazenamento | Componentes substituíveis e testáveis de forma independente | Verificar a separação entre a gestão da tarefa e a execução da compilação | Deveria ter | DQ7, REQ-VID-COMP-007, REQ-VID-COMP-008 | A lógica de processamento pode ser alterada sem reescrever a biblioteca ou a autenticação | Proposto |

#### 4.1.3 Verificação da completude e dos limites do âmbito

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
|-----------------------|---------------|----------------------------|--------------------------------|
| Validação do formato, codec e legibilidade | Sim | O sistema valida se os vídeos são legíveis; a entrada em MP4 com H.264 é garantida pelo carregamento (RNG-02) e a saída é produzida nesse formato. | REQ-VID-COMP-004, REQ-VID-COMP-014, REQ-VID-COMP-015, REQ-VID-COMP-NF-005 |
| Duração, dimensão e número máximo de vídeos | Sim | São limites relevantes para capacidade e quotas, mas os valores concretos não estão definidos no material fornecido; ficam como questão em aberto. | REQ-VID-COMP-005, REQ-VID-COMP-006; Q2 |
| Estado, progresso e cancelamento | Sim | A tarefa deve ter estado consultável; o cancelamento deve impedir a publicação do resultado parcial. | REQ-VID-COMP-009, REQ-VID-COMP-017, REQ-VID-COMP-018 |
| Falha e consistência dos ficheiros | Sim | Em caso de falha, não deve ficar um resultado parcial acessível; o tratamento de temporários deve ser validado na implementação. | REQ-VID-COMP-017, REQ-VID-COMP-NF-003 |
| Persistência e expiração de ficheiros | Sim | O resultado deve persistir na biblioteca. O prazo de retenção/expiração dos originais, temporários e resultados não está definido e deve ser decidido. | REQ-VID-COMP-011; questão em aberto Q3 |
| Perfis, quotas e contagem de operações | Sim | A operação depende da quota do utilizador; a regra exata de contabilização (por pedido, por vídeo ou por duração) necessita de confirmação. | REQ-VID-COMP-005, RN5; questão em aberto Q4 |
| Encadeamento de ferramentas e processamento em lote | Sim | O âmbito descrito cobre uma compilação pedida pelo utilizador. Integração com encadeamento de ferramentas ou lote não está especificada e fica excluída do MVP até decisão explícita. | Decisão de âmbito DQ8 |
| Segurança e autorização | Sim | Apenas o proprietário autorizado deve consultar os vídeos de entrada e o resultado. | REQ-VID-COMP-NF-002 |
| Portabilidade do processamento | Sim | A dependência de ferramentas externas (por exemplo, FFmpeg) e o seu isolamento devem ser documentados quando a arquitetura for confirmada. | REQ-VID-COMP-NF-006, REQ-VID-COMP-NF-007 |

### 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
|--------------------------------|-------------------------------------------|--------------------------|--------------------------------|
| Biblioteca do Utilizador | Estender | Além dos vídeos originais também armazena o resultado da operação | REQ-VID-COMP-011 |
| Sistema de quotas | Alterar | A quota deve ser verificada antes de começar o processamento do pedido | REQ-VID-COMP-005 |
| Armazenamento | Alterar | Deve validar o espaço disponível para guardar o vídeo resultante | REQ-VID-COMP-006 |
| Sistema de processamento | Estender | Deve suportar as tarefas de compilação de vários vídeos | REQ-VID-COMP-007, REQ-VID-COMP-008 |
| Monitorização de tarefas | Estender | Deve apresentar o estado e o progresso da compilação | REQ-VID-COMP-009, REQ-VID-COMP-018 |
| Gestão de vídeos | Alterar | Deve preservar os vídeos originais | REQ-VID-COMP-012 |
| Gestão de falhas | Estender | Deve impedir a disponibilidade de vídeos incompletos | REQ-VID-COMP-017 |

### 4.3 Matriz de Rastreabilidade Atualizada

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
|------------------------|-------------------------|--------------------------------|
| Passo 1 | Apresentar lista de vídeos | REQ-VID-COMP-001 |
| Passo 2 | Selecionar vídeos para compilação | REQ-VID-COMP-002 |
| Passo 2 | Definir ordem dos vídeos | REQ-VID-COMP-003 |
| Passo 3 | Validar vídeos e parâmetros | REQ-VID-COMP-004 |
| Passo 4 | Verificar quota disponível | REQ-VID-COMP-005 |
| Passo 9 | Reservar espaço de armazenamento | REQ-VID-COMP-006 |
| Passo 5 | Criar tarefa de processamento | REQ-VID-COMP-007 |
| Passo 6 | Iniciar compilação | REQ-VID-COMP-008 |
| Passo 7 | Atualizar estado e progresso | REQ-VID-COMP-009, REQ-VID-COMP-018 |
| Passo 8 | Gerar vídeo resultante | REQ-VID-COMP-010 |
| Passo 9 | Guardar vídeo resultante | REQ-VID-COMP-011 |
| Passo 10 | Manter vídeos originais | REQ-VID-COMP-012 |
| FA1 | Alteração da ordem dos vídeos | REQ-VID-COMP-003 |
| FA2 | Remoção de vídeo da seleção | REQ-VID-COMP-013 |
| FA3 | Conversão de formatos diferentes | REQ-VID-COMP-014 |
| Exceção 1 | Vídeo corrompido ou ilegível | REQ-VID-COMP-015, REQ-VID-COMP-016 |
| Exceção 2 | Quota insuficiente | REQ-VID-COMP-005 |
| Exceção 3 | Espaço insuficiente | REQ-VID-COMP-006 |
| Exceção 4 | Falha durante processamento | REQ-VID-COMP-017 |
| Exceção 5 | Tempo limite excedido | REQ-VID-COMP-019 |
| Perfis de utilização | Aplicar limites do perfil | REQ-VID-COMP-020 |
| Regra de quota | Contabilizar a utilização | REQ-VID-COMP-021 |
| Persistência/expiração | Aplicar política de retenção | REQ-VID-COMP-022 |
| Exceção 6 | Cancelamento da operação | REQ-VID-COMP-017 |
| RN1 | Mínimo de dois vídeos | REQ-VID-COMP-002, REQ-VID-COMP-013 |
| RN2 | Ordem definida pelo utilizador | REQ-VID-COMP-003, REQ-VID-COMP-008 |
| RN3 | Vídeos originais inalterados | REQ-VID-COMP-012 |
| RN4 | Novo vídeo na biblioteca | REQ-VID-COMP-011 |
| RN5 | Quota necessária | REQ-VID-COMP-005 |
| RN6 | Armazenamento necessário | REQ-VID-COMP-006 |
| RN7 | Mostrar estado e progresso | REQ-VID-COMP-009, REQ-VID-COMP-018 |
| RN8 | Não disponibilizar vídeo incompleto | REQ-VID-COMP-017 |
| Pós-condição Sucesso | Vídeo criado e armazenado | REQ-VID-COMP-010, REQ-VID-COMP-011, REQ-VID-COMP-012 |
| Pós-condição Mínima | Não guardar vídeo incompleto | REQ-VID-COMP-017, REQ-VID-COMP-NF-003 |
| DQ1 | Aceitação rápida e processamento assíncrono | REQ-VID-COMP-NF-001 |
| DQ2 | Acesso apenas pelo proprietário autorizado | REQ-VID-COMP-NF-002 |
| DQ3 | Consistência após falha/cancelamento | REQ-VID-COMP-NF-003 |
| DQ4 | Acompanhamento sem bloquear a interface | REQ-VID-COMP-NF-004 |
| DQ5 | Compatibilidade e validação de formatos | REQ-VID-COMP-NF-005 |
| DQ6 | Isolamento e limites de recursos | REQ-VID-COMP-NF-006 |
| DQ7 | Separação dos componentes para manutenção | REQ-VID-COMP-NF-007 |
| DQ8 | Encadeamento e lote fora do MVP até decisão | N/A — decisão de âmbito documentada |

---

## 5. Exercício 3 — Refinamento dos requisitos para clareza e precisão

**Objetivo:** tornar os requisitos claros, atómicos, mensuráveis quando exista um valor definido e verificáveis por teste ou inspeção. Este exercício não acrescenta funcionalidades ao âmbito; explicita as condições e assinala os valores que a equipa ainda tem de decidir.

> **Convenção:** os limites numéricos que já aparecem no documento (por exemplo, atualização do progresso a cada 5 s e confirmação de submissão em menos de 3 s) são tratados como propostas para o MVP, não como factos confirmados sobre o sistema existente. Devem ser validados pela equipa. Não se fixa um limite de duração, tamanho, resolução, número máximo de vídeos ou tempo máximo de processamento sem informação que o sustente.

### 5.1 Lista de requisitos refinados

A tabela seguinte complementa a ERS da secção 4. Os IDs existentes são preservados quando o significado não muda. Os critérios são formulados para permitir a preparação de testes; os valores assinalados como **por decidir** são dependências explícitas e não devem ser apresentados como requisitos já aprovados.

| ID | Requisito refinado | Condição / critério de aceitação | Estado / decisão pendente |
|---|---|---|---|
| REQ-VID-COMP-001 | O sistema deve apresentar, na biblioteca, apenas os vídeos aos quais o utilizador autenticado tem autorização de acesso. | Com a sessão do utilizador A, a biblioteca não apresenta vídeos privados do utilizador B. | Refinado; validar com as regras de autorização existentes. |
| REQ-VID-COMP-002 | O sistema deve permitir selecionar pelo menos dois vídeos elegíveis para uma tarefa de compilação. | Com zero ou um vídeo selecionado, a ação de iniciar a compilação fica indisponível ou é rejeitada; com dois ou mais vídeos elegíveis, a seleção pode avançar. | Refinado; número máximo por operação por decidir. |
| REQ-VID-COMP-003 | O sistema deve guardar a sequência escolhida pelo utilizador para os vídeos selecionados. | Ao alterar a ordem antes da confirmação, a sequência apresentada e a sequência enviada para processamento são iguais. | Refinado. |
| REQ-VID-COMP-004 | Antes de criar a tarefa, o sistema deve verificar se cada vídeo selecionado existe, é acessível ao utilizador e pode ser lido pelo processador. | Um vídeo inexistente, sem autorização ou ilegível impede a criação/início da tarefa e gera uma mensagem de erro identificável. | Refinado; regras concretas de formato e codec por decidir. |
| REQ-VID-COMP-005 | Antes de aceitar a tarefa, o sistema deve verificar a quota de processamento disponível para o perfil do utilizador. | Se a quota disponível não cumprir a regra configurada para a operação, a tarefa não é colocada em processamento e é apresentada uma mensagem de quota insuficiente. | Refinado; fórmula de contabilização da quota por decidir. |
| REQ-VID-COMP-006 | Antes de publicar o resultado na biblioteca, o sistema deve verificar se existe espaço de armazenamento para o ficheiro resultante. | Se o espaço disponível for inferior ao necessário para guardar o resultado, este não é publicado e o utilizador recebe uma mensagem explícita. | Refinado; estratégia para estimar o tamanho do resultado por decidir. |
| REQ-VID-COMP-007 | Para cada pedido válido, o sistema deve criar um identificador único de tarefa e registar o estado inicial da tarefa. | Um pedido válido devolve um identificador consultável e um estado inicial definido; pedidos inválidos não iniciam processamento. | Refinado; nome exato do estado inicial deve coincidir com o modelo de estados do sistema. |
| REQ-VID-COMP-008 | O processador deve concatenar os vídeos na sequência registada na tarefa. | Num teste com vídeos de referência identificáveis, a ordem dos segmentos na saída corresponde à ordem selecionada. | Refinado; regras de normalização de resolução, frame rate e áudio por decidir. |
| REQ-VID-COMP-009 | O sistema deve permitir consultar o estado atual de cada tarefa de compilação. | A consulta devolve um dos estados definidos para a tarefa, incluindo em fila, em processamento, concluído, falhado ou cancelado, conforme aplicável. | Refinado; confirmar nomenclatura final dos estados. |
| REQ-VID-COMP-010 | Quando a compilação termina com sucesso, o sistema deve produzir um ficheiro de vídeo de saída reproduzível. | Um teste de reprodução confirma que o ficheiro de saída pode ser aberto por um leitor compatível e contém os segmentos na ordem solicitada. | Refinado; contentor, codec e parâmetros de saída por decidir. |
| REQ-VID-COMP-011 | Após a conclusão com sucesso e a validação do armazenamento, o sistema deve registar o ficheiro resultante na biblioteca do utilizador que iniciou a tarefa. | O resultado aparece na biblioteca desse utilizador e não aparece na biblioteca de outro utilizador não autorizado. | Refinado. |
| REQ-VID-COMP-012 | A compilação não deve modificar nem eliminar os ficheiros de origem. | Comparar os ficheiros originais antes e depois da operação; permanecem acessíveis e com o mesmo conteúdo. | Refinado; usar hash ou comparação equivalente durante o teste. |
| REQ-VID-COMP-013 | O sistema deve rejeitar a tentativa de iniciar uma compilação com menos de dois vídeos selecionados. | A tentativa com zero ou um vídeo não cria uma tarefa de processamento. | Refinado; evitar duplicação funcional com REQ-VID-COMP-002 na implementação, mantendo este requisito como regra explícita de validação. |
| REQ-VID-COMP-014 | O sistema deve aceitar na compilação apenas vídeos do projeto em contentor MP4 com codec de vídeo H.264 (RNG-02) e recusar qualquer outro formato. | Um vídeo MP4/H.264 do projeto é aceite; um vídeo noutro contentor ou codec é recusado no pedido com UNSUPPORTED_VIDEO (HTTP 415), com base nos metadados guardados no projeto. | Resolvido; formato fixado por RNG-02. |
| REQ-VID-COMP-015 | O sistema deve interromper a preparação da tarefa quando não conseguir ler um dos vídeos selecionados. | Um vídeo de teste corrompido impede o início da compilação. | Refinado. |
| REQ-VID-COMP-016 | Quando um vídeo não pode ser lido, o sistema deve apresentar a mensagem “Não foi possível ler um dos vídeos”. | O teste com um ficheiro corrompido confirma que a mensagem é apresentada ao utilizador. | Refinado; mensagem mantida do caso de uso. |
| REQ-VID-COMP-017 | Se uma tarefa falhar ou for cancelada, o sistema não deve publicar um ficheiro de saída incompleto na biblioteca. | Interromper uma tarefa durante o processamento; não existe resultado parcial visível ou descarregável na biblioteca. | Refinado; política de limpeza dos ficheiros temporários por decidir. |
| REQ-VID-COMP-018 | Quando o processador disponibiliza informação de progresso, o sistema deve atualizar o progresso apresentado ao utilizador pelo menos a cada 5 s durante a execução. | Num teste de tarefa suficientemente longa, o intervalo entre atualizações apresentadas não excede 5 s, desde que o processador disponibilize novos dados. | Proposto; confirmar viabilidade técnica e se o progresso pode ser medido de forma fiável. |
| REQ-VID-COMP-019 | O sistema deve terminar uma tarefa quando esta atingir o limite máximo de duração de processamento configurado. | Num teste controlado, uma tarefa que ultrapassa o limite configurado termina com estado de falha e não publica saída incompleta. | Refinado; valor do limite e comportamento após timeout por decidir. |
| REQ-VID-COMP-NF-001 | O sistema deve responder à submissão de um pedido válido em menos de 3 s, sem esperar pela conclusão da compilação. | Medir do envio do pedido de compilação à resposta de aceitação, em condições de teste documentadas. | Alvo MVP proposto; confirmar ambiente e carga de teste. Alvo de produção proposto: menos de 1 s. |
| REQ-VID-COMP-NF-002 | O sistema deve impedir o acesso aos vídeos de entrada e ao resultado por utilizadores sem autorização. | Uma tentativa com uma sessão de outro utilizador é recusada para consulta e transferência. | Obrigatório; validar com autenticação/autorização existentes. |
| REQ-VID-COMP-NF-003 | Após falha ou cancelamento, o sistema deve manter um estado final consistente e não expor o resultado parcial. | Injetar falha ou cancelar a tarefa; confirmar estado final, ausência de saída parcial na biblioteca e preservação dos originais. | Alvo MVP: estado falhado/cancelado sem retoma automática. Produção: retoma/repetição controlada, sem duplicar resultados. |
| REQ-VID-COMP-NF-004 | O utilizador deve conseguir consultar o estado da tarefa depois de sair e regressar à página da aplicação. | Iniciar tarefa, sair da página e voltar; o estado consultado corresponde ao estado registado pelo sistema. | Refinado; a frequência de atualização é especificada em REQ-VID-COMP-018. |
| REQ-VID-COMP-NF-005 | O sistema deve verificar a legibilidade dos vídeos de entrada e produzir a saída em MP4 com H.264 e áudio AAC (RNG-02). | Testar vídeos legíveis e ilegíveis; a saída de uma compilação bem-sucedida é MP4/H.264/AAC. | Resolvido; formato fixado por RNG-02. |
| REQ-VID-COMP-NF-006 | O sistema deve executar cada tarefa dentro dos limites configurados de tempo e recursos e sem bloquear a interação normal com a aplicação. | Durante um teste de compilação, a interface continua utilizável e uma tarefa que excede o limite é terminada de acordo com REQ-VID-COMP-019. | Limites de CPU, memória e concorrência por decidir com base na infraestrutura disponível. |
| REQ-VID-COMP-NF-007 | A lógica de compilação deve estar separada da lógica de autenticação e da gestão da biblioteca. | Por inspeção arquitetural ou teste, uma alteração isolada no processador de compilação não exige alterar a lógica de autenticação ou a listagem da biblioteca. | Objetivo de manutenibilidade; validar com a arquitetura real do projeto. |

### 5.2 Registo de reformulações: original → refinado

| ID | Requisito original / problema identificado | Reformulação aplicada | Ambiguidade resolvida |
|---|---|---|---|
| REQ-VID-COMP-001 | “Apresentar os vídeos disponíveis na biblioteca.” | Restringir a lista aos vídeos a que o utilizador autenticado tem acesso. | “Disponíveis” passa a incluir autorização e propriedade. |
| REQ-VID-COMP-002 / 013 | “Selecionar dois ou mais vídeos”; a regra de mínimo também surgia noutro requisito. | Definir o comportamento para zero, um e pelo menos dois vídeos; explicitar que a tentativa inválida não cria tarefa. | Condição de entrada verificável e sobreposição entre requisitos documentada. |
| REQ-VID-COMP-003 / 008 | “Escolher a ordem” e “compilar pela ordem escolhida”. | Verificar que a sequência registada é a mesma da saída. | Liga a escolha da interface ao resultado observável. |
| REQ-VID-COMP-004 / 014 / 015 | “Validar vídeos” e “formatos compatíveis”. | Separar existência/acesso/legibilidade da política de conversão e dos formatos aceites. | “Válido” e “compatível” deixam de ser termos sem definição. |
| REQ-VID-COMP-005 | “Quota suficiente”. | Verificar a quota antes de aceitar a tarefa e assinalar a regra de contabilização como decisão pendente. | “Suficiente” depende de uma política de quota explícita. |
| REQ-VID-COMP-006 | “Armazenamento suficiente”. | Verificar espaço antes de publicar o resultado e indicar o comportamento quando falta espaço. | Define o momento da verificação e o resultado esperado. |
| REQ-VID-COMP-007 | “Criar uma tarefa”. | Criar identificador único e registar estado inicial. | Torna a tarefa identificável e consultável. |
| REQ-VID-COMP-009 / 018 | “Apresentar estado” e “atualizar progresso”. | Separar consulta do estado da frequência de atualização do progresso, mantendo 5 s como alvo proposto. | Distingue estado categórico de percentagem/progresso e identifica uma condição mensurável. |
| REQ-VID-COMP-010 / 011 | “Gerar e guardar o vídeo”. | Separar a criação de uma saída reproduzível do registo dessa saída na biblioteca. | Separa produção do ficheiro de persistência/publicação. |
| REQ-VID-COMP-012 | “Manter os originais inalterados”. | Comparar conteúdo antes e depois do processamento. | Define uma verificação concreta de integridade. |
| REQ-VID-COMP-016 | Mensagem de erro para vídeo ilegível. | Manter texto explícito e associá-lo ao teste com ficheiro corrompido. | Mensagem e condição de apresentação ficam ligadas. |
| REQ-VID-COMP-017 / NF-003 | “Não armazenar ficheiros incompletos”. | Verificar que a saída parcial não fica visível nem descarregável após falha/cancelamento. | Distingue ficheiro temporário interno de resultado publicado ao utilizador. |
| REQ-VID-COMP-019 / NF-006 | “Tempo limite permitido” e “limitar recursos”. | Referir limites configurados e exigir estado final e ausência de saída parcial. | Evita um limite implícito; o valor tem de ser decidido/configurado. |
| REQ-VID-COMP-NF-001 | “Confirmação rápida” / operação assíncrona. | Propor menos de 3 s para o MVP e menos de 1 s para produção, medidos desde o envio do pedido até à resposta. | Separa o tempo de aceitação do tempo total de compilação. Os alvos carecem de validação. |
| REQ-VID-COMP-NF-002 | “Acesso seguro”. | Testar consulta e transferência com uma sessão sem autorização. | Define o ator e o resultado do teste de acesso. |
| REQ-VID-COMP-NF-005 | “Formatos suportados”. | Fixar MP4 com H.264 na entrada e na saída (RNG-02) e verificar o codec real do ficheiro. | Distingue contentor de codec e entrada de saída, com o formato já aprovado pela equipa. |
| REQ-VID-COMP-NF-007 | “Fácil de manter / extensível”. | Definir separação entre processador, autenticação e biblioteca e verificar por inspeção arquitetural. | Substitui um adjetivo subjetivo por uma propriedade inspecionável. |

### 5.3 Ambiguidades do domínio do vídeo e decisões pendentes

| Tema | Decisão/estado atual | Ação necessária |
|---|---|---|
| Tamanho do vídeo | Armazenamento acumulado: 1 GB (`free`) e 5 GB (`premium`). Não existe limite confirmado por vídeo na compilação. | Definir o tamanho máximo de entrada por perfil e documentar a unidade MB ou MiB. |
| Duração | A soma das durações está limitada a 10 minutos no `free` e a 1 hora no `premium` (`COMPILE_MAX_SECONDS_FREE` e `COMPILE_MAX_SECONDS_PREMIUM`); o worker volta a verificar o limite de 1 hora. | Decidido; documentar como política do MVP. |
| Resolução e frame rate | O worker normaliza os vídeos para a resolução do primeiro (mantendo a proporção com barras) e 30 fps. | Decidido; documentar como política do MVP. |
| Contentor e codec | Decidido: entrada e saída em MP4 com H.264, conforme RNG-02. | Validar o codec real do ficheiro, e não só a extensão, antes de compilar; ficheiros que não cumpram são rejeitados com mensagem explícita. |
| Qualidade da saída | MP4 com H.264 (`libx264`, preset `veryfast`), áudio AAC estéreo a 44,1 kHz, yuv420p, resolução do primeiro vídeo e 30 fps; o bitrate não é definido explicitamente. | Documentar esta política de saída no MVP e decidir se é necessário controlar o bitrate. |
| Tempo de processamento | O limite é de 30 minutos por omissão (`COMPILE_TIMEOUT_SECONDS`, configurável); a falha por tempo limite é recuperável. | Confirmar o valor e as condições de medição; manter o tempo de submissão separado do tempo de compilação. |
| Concorrência | Cada worker processa uma tarefa de cada vez (`prefetch_count = 1`); não há limite confirmado por utilizador nem global. | Definir limites por utilizador e globais com base na capacidade da infraestrutura, ou registar a ausência de limite no MVP. |
| Progresso | O worker calcula o progresso (0 a 99 %) a partir do tempo de saída do FFmpeg e envia-o ao serviço `projects` cerca de uma vez por segundo; a interface consulta o estado de 3 em 3 segundos enquanto o diálogo está aberto. | Decidido; documentar como política do MVP. |
| Notificação | O requisito atual cobre apresentação do estado na aplicação, não envio de email/push. | Manter a atualização no painel no MVP; notificações externas ficam fora do âmbito salvo decisão explícita. |
| Cancelamento | O worker verifica o estado da tarefa durante a descarga e a conversão e, se for cancelada, termina o FFmpeg e não envia resultado. | Confirmar o prazo de resposta ao cancelamento na interface. |
| Retenção e expiração | O prazo de retenção dos originais, resultados e temporários não está definido. | Documentar política de retenção ou registar a decisão como pendente; não prometer expiração automática sem suporte do sistema. |
| Número de vídeos | O mínimo é dois (RN1) e o máximo é 10 (`COMPILE_MAX_VIDEOS`). | Decidido; documentar como política do MVP. |
| Áudio | O REQ-VID-COMP-008 refere a normalização de áudio, mas não há regra para vídeos sem faixa de áudio ou com áudio diferente. | Definir o comportamento: manter o áudio, silenciar ou rejeitar. |
| Nome do resultado | Por omissão `compilation.mp4`; o utilizador pode escolher o nome (acrescenta-se `.mp4` se faltar) e, se já existir, acrescenta-se um sufixo numérico. | Decidido. |
| Quotas | O perfil `free` tem 5 operações diárias (`FREE_DAILY_OP = 5`) e o `premium` não tem limite diário. A compilação usa o mesmo endpoint interno de quota do serviço `users` que o recorte: reserva no pedido (só `free`), confirmação na conclusão e estorno em falha definitiva ou cancelamento. | Decidido; documentar como política do MVP. |

### 5.4 Conflitos com o sistema existente e resolução

| Elemento existente | Conflito ou risco identificado | Resolução proposta para a Fase 1 | Estado |
|---|---|---|---|
| Perfis e quotas existentes para imagem | Os limites definidos para imagem podem não corresponder ao custo de compilar vários vídeos. | Reutilizar o mecanismo de perfis/quotas existente, mas não assumir a mesma unidade de consumo; definir a regra de vídeo com a equipa. | Pendente de validação. |
| Biblioteca e autorização | O resultado é um novo ficheiro e não deve ficar acessível a outros utilizadores. | Reutilizar as regras de propriedade/autorização da biblioteca para o resultado. | Proposta coerente com REQ-VID-COMP-NF-002. |
| Armazenamento | O tamanho do resultado não é necessariamente conhecido antes da compilação. | Verificar espaço antes de publicar o resultado e tratar falta de espaço sem expor saída parcial; definir se existe estimativa prévia. | Pendente de decisão técnica. |
| Fila/processamento existente | O processamento síncrono poderia bloquear a interação e dificultar o acompanhamento. | Executar a tarefa de forma assíncrona, reutilizando a infraestrutura de tarefas existente se disponível. | Validar com a arquitetura existente. |
| Formatos usados por ferramentas de imagem | Não se pode inferir que os mesmos formatos ou políticas de imagem se aplicam a vídeo. | Os formatos de vídeo estão definidos por RNG-02: MP4 com H.264 na entrada e na saída. | Resolvido. |
| Encadeamento de ferramentas e processamento em lote | O caso de uso descreve uma operação de compilação iniciada pelo utilizador, não uma pipeline nem um lote. | Excluir do MVP até existir uma decisão de âmbito; não alterar requisitos existentes para incluir essas capacidades. | Exclusão proposta e documentada. |
