# Dossiê de Requisitos do Sistema — Exercício 3

### Especificação de Requisitos do Sistema (ERS) · Fase 1: Suporte a Vídeo no PictuRAS

## 0. Identificação

| Campo | Valor |
| --- | --- |
| Grupo / Equipa | PL3-G2 |
| Autor responsável | Nuno Sá |
| Data da revisão | 2026-10-22 |
| Versão do documento | v3.0 |
| Unidade Curricular | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |
| Caso de uso | UC-VID-005 — Modificar a velocidade de um vídeo |
| Baseline | Origem: v1.0 de 2026-10-10, requisitos REQ-VID-SPEED-001 a REQ-VID-SPEED-021. Refinamento do Exercício 3: v2.0 de 2026-10-21, catálogo REQ-VID-SPEED-001 a REQ-VID-SPEED-038. |

Esta revisão altera apenas o dossiê da funcionalidade. Não altera a implementação nem integra automaticamente o conteúdo no relatório Typst. As questões sem decisão da equipa permanecem assinaladas; não se atribuem valores de desempenho, duração máxima ou quota diária sem fundamento.

## 1. Funcionalidade de vídeo escolhida

| Campo | Valor |
| --- | --- |
| Funcionalidade | Modificar a velocidade de um vídeo por intervalos temporais. |
| Perfis abrangidos | Utilizador registado Free ou Premium, proprietário do projeto ou com permissão de edição por partilha válida. |
| Entrada | Vídeo já associado ao projeto, em contentor MP4 com codec de vídeo H.264, com ou sem áudio. |
| Saída | Novo ficheiro MP4 com vídeo H.264 e áudio AAC quando a entrada possui áudio; o original é preservado. |
| Velocidades | 0,5x, 1x e 2x, configuradas independentemente para cada intervalo. |

**Justificação no contexto do MVP**

A alteração de velocidade permite acelerar ou abrandar partes de um vídeo sem alterar temporalmente as restantes. No PictuRAS, estende o processamento assíncrono existente, exercitando a validação de vários intervalos, a sincronização áudio/vídeo e a disponibilização de um novo resultado na biblioteca do projeto.

**Fronteira do caso de uso**

O carregamento do ficheiro pertence a UC-VID-001; o recorte pertence a UC-VID-002; a remoção de segmento pertence a UC-VID-003. UC-VID-005 recebe um vídeo já carregado e não elimina intervalos nem junta vídeos diferentes. Reprodução, download e eliminação do resultado reutilizam operações da biblioteca, sem criar aqui novos casos de uso para essas operações.

## 2. Caso de Uso

### 2.1 Cabeçalho

| Secção | Detalhes |
| --- | --- |
| ID do Caso de Uso | UC-VID-005 |
| Nome | Modificar a velocidade de um vídeo |
| Versão | v3.0; refinamento documental da v2.0 no Exercício 3, preservando a origem na v1.0. |
| Autor | Nuno Sá |
| Data | 2026-10-22 |
| Objetivo | Aplicar velocidades a um ou vários intervalos não sobrepostos do mesmo vídeo, conservar a ordem temporal e a velocidade das partes não selecionadas e ajustar o áudio, produzindo um novo vídeo. |
| Âmbito | Edição de vídeo no PictuRAS; interface do projeto, submissão assíncrona, processamento e registo do resultado. |
| Ator principal | Utilizador registado com permissão de edição no projeto. |
| Stakeholders e interesses | Utilizador: obter um resultado correto sem perder o original. Proprietário do projeto: controlar acesso e utilização do armazenamento. Equipa de desenvolvimento/operações: reutilizar os serviços existentes e identificar falhas sem expor resultados incompletos. |
| Pré-condições | Sessão válida; projeto acessível com edição; vídeo associado ao projeto e armazenado num formato suportado. A aceitação final do resultado depende da quota de armazenamento do proprietário; não pressupõe quota diária de operações para speed. |
| Trigger | O utilizador escolhe um vídeo e abre a ação **Modificar velocidade**. |

### 2.2 Fluxo Principal

| Passo | Ação do ator | Resposta do sistema |
| --- | --- | --- |
| 1 | Abre o projeto e seleciona um vídeo existente. | Apresenta o vídeo selecionado na biblioteca do projeto. |
| 2 | Escolhe **Modificar velocidade**. | Abre o diálogo com o vídeo original, obtém a duração e apresenta os controlos de início, fim e velocidade. |
| 3 | Define os instantes inicial e final de um intervalo. | Atualiza os campos e a seleção temporal; permite ajustar os valores antes de enviar. |
| 4 | Escolhe 0,5x, 1x ou 2x. | Associa a velocidade ao intervalo, sem gerar um preview do vídeo transformado. |
| 5 | Adiciona outros intervalos, se necessário, e edita ou remove os existentes. | Mantém uma lista dos intervalos configurados e das respetivas velocidades. |
| 6 | Revê a configuração. | Valida lista não vazia, números finitos, limites temporais, velocidades permitidas e ausência de sobreposição; sinaliza os erros. |
| 7 | Consulta o resumo visível no diálogo. | Apresenta os tempos e a velocidade de cada intervalo antes da submissão. Não exige uma segunda caixa de confirmação. |
| 8 | Clica em **Processar**. | Verifica sessão, permissão, versão do projeto e associação do vídeo; valida os parâmetros do pedido e encaminha a operação para processamento assíncrono. |
| 9 | — | Confirma a aceitação do pedido e informa que o novo vídeo aparecerá na biblioteca quando o processamento terminar. A aceitação não equivale à conclusão. |
| 10 | — | Obtém o vídeo original, confirma formato/codec e duração real e processa os intervalos por ordem temporal, mantendo as partes não selecionadas a 1x. |
| 11 | — | Ajusta o áudio existente proporcionalmente à velocidade de cada segmento e concatena os segmentos. Na ausência de áudio, processa apenas vídeo. |
| 12 | — | Produz e transfere o novo MP4 e comunica o resultado ao serviço responsável pelo projeto. Não apresenta progresso percentual no MVP. |
| 13 | — | Reserva o tamanho real do resultado na quota do proprietário, associa o vídeo se houver espaço, incrementa a versão do projeto, confirma a contabilização e atualiza a biblioteca. |

A validação é distribuída: a interface usa a duração obtida do vídeo; Projects valida estrutura, valores e sobreposição; o worker volta a validar e verifica os limites contra a duração real. Por isso, um pedido direto à API pode ser aceite para processamento e posteriormente rejeitado pelo worker por ultrapassar essa duração.

A transferência do output para o armazenamento antecede o processamento da mensagem de resultado em Projects. Se a quota impedir a associação, o output não é disponibilizado na biblioteca e é tentada a sua eliminação; o original não é removido.

### 2.3 Fluxos Alternativos

| Fluxo | Descrição e âmbito |
| --- | --- |
| FA1 — Vários intervalos | Nos passos 3 a 5, o utilizador configura várias alterações no mesmo vídeo. Cada intervalo conserva a sua velocidade; a ordem de introdução não altera a ordem temporal do resultado. |
| FA2 — Velocidade original | No passo 4, escolhe 1x. O segmento mantém a sua escala temporal e a velocidade do áudio. Isto não significa cópia binária dos streams: a saída pode ser recodificada. |
| FA3 — Edição e remoção da configuração | Antes do passo 8, o utilizador edita tempos ou velocidade ou remove um intervalo. A lista e a validação são recalculadas. Se remover todos, não pode submeter até adicionar um intervalo válido. |
| FA4 — Cancelamento de pedido em fila, evolução futura | A intenção da baseline é conservada, mas não integra o MVP implementado. Uma futura versão poderá impedir a execução de um pedido ainda em fila; o comportamento e a verificação dependem de uma decisão sobre gestão de tarefas. Não existe cancelamento de speed após submissão. |
| FA5 — Vídeo sem áudio | No passo 11, não existe stream de áudio. O resultado continua sem áudio; não é acrescentada uma faixa artificial. |
| FA6 — Desistência antes da submissão | Antes do passo 8, o utilizador fecha o diálogo ou escolhe **Cancelar**. Não é criada uma tarefa de processamento. |
| FA7 — Acesso por partilha com edição | Um utilizador diferente do proprietário abre o projeto através de uma partilha válida com edição. A autoria do resultado identifica o chamador; o armazenamento é contabilizado na conta do proprietário. |

### 2.4 Exceções

| ID | Condição | Comportamento e estado de implementação |
| --- | --- | --- |
| EX1 | MP4 inválido, codec de vídeo diferente de H.264, ausência de vídeo ou duração inválida. | O worker rejeita o processamento; não é associado um resultado final. A falha assíncrona é registada no backend. A notificação final desse erro na interface é evolução futura. |
| EX2 | Tempos não finitos, início negativo ou fim igual/anterior ao início. | A configuração é rejeitada na interface e no pedido; o utilizador corrige os valores antes de submeter. |
| EX3 | Intervalos sobrepostos. | A interface sinaliza os intervalos em conflito; a API e o worker rejeitam a configuração. Intervalos apenas adjacentes são permitidos. |
| EX4 | Espaço insuficiente para o tamanho real do output. | O resultado não é associado, a versão do projeto não muda e não é emitido add-video. São tentadas a limpeza do output não associado e a libertação da reserva. O erro de quota fica registado; não existe alerta terminal específico de speed na interface. |
| EX5 | Quota diária de operações alegadamente esgotada. | A baseline mencionava este bloqueio, mas a regra de contabilização de speed não foi decidida. Não é uma exceção ativa do MVP, nem se afirma verificação, débito ou estorno de operações diárias nesta funcionalidade. |
| EX6 | Falha de leitura, processamento, rede, upload do output ou associação ao projeto. | Não é apresentado um resultado parcial como sucesso. Quando Projects recebe um resultado com status error, apenas regista a falha; esse ramo não elimina outputs nem executa release. Quando recebe sucesso mas a quota ou a associação impedem o registo, tenta remover o output e libertar a reserva apenas após confirmar que o vídeo não está associado. Um vídeo já associado mantém os bytes contabilizados, mesmo se commit falhar. A falha na comunicação do resultado após o upload pode deixar um output órfão; não existe recolha automática garantida. Falhas persistentes exigem recuperação operacional. |
| EX7 | Falha no ajuste do áudio. | O processamento termina em erro, o original é preservado e não se associa um resultado parcial. A falha é registada no backend. |
| EX8 | Sessão ausente/expirada ou falta de permissão de edição. | O pedido é recusado; a interface apresenta uma mensagem de sessão/permissão. Uma partilha apenas de leitura não autoriza a operação. |
| EX9 | Versão do projeto ausente/inválida ou desatualizada. | A submissão é recusada, respetivamente com 428 ou 409. A interface permite atualizar/rever os dados e repetir o pedido. |
| EX10 | Lista vazia, campos inválidos ou velocidade não permitida. | O pedido é recusado; não é publicado um pedido válido de processamento. |
| EX11 | Intervalo ultrapassa a duração do vídeo. | A interface bloqueia a submissão. Num pedido direto que contorne essa verificação, o worker recusa o intervalo após obter a duração real. |
| EX12 | Projeto/vídeo inexistente ou referência de armazenamento inconsistente. | A API recusa a submissão. Se o projeto desaparecer depois de aceite o pedido, a associação do resultado falha e aplica-se a limpeza prevista em EX6. |
| EX13 | Resultado recebido novamente. | Um vídeo já associado não é adicionado outra vez, não incrementa novamente a versão nem duplica os bytes contabilizados. O resultado repetido não deve apagar o vídeo já associado. |

### 2.5 Pós-condições

| Tipo | Resultado |
| --- | --- |
| Garantia de sucesso | Novo MP4/H.264 associado ao projeto; áudio AAC quando existe áudio na entrada; intervalos transformados, partes não selecionadas a 1x e ordem preservada; original intacto e disponível; tamanho real do output contabilizado na conta do proprietário; versão incrementada e resultado disponível na biblioteca. |
| Garantia mínima | Original preservado. Um output não associado não é apresentado como resultado final. Uma reserva sem associação é libertada pelo tratamento de falhas controladas; falhas persistentes de infraestrutura são registadas e podem exigir recuperação. Erros de submissão são apresentados na interface; a notificação de falhas assíncronas ao utilizador ainda não está implementada. |

### 2.6 Regras de Negócio e Restrições

| ID | Regra |
| --- | --- |
| RN1 | As únicas velocidades permitidas são 0,5x, 1x e 2x. Velocidade 2x reduz a duração temporal do segmento a metade; 0,5x duplica-a. |
| RN2 | Para cada intervalo, os tempos são números finitos e cumprem 0 <= início < fim <= duração do vídeo. Os intervalos não se sobrepõem; fronteiras adjacentes são válidas. |
| RN3 | As partes não selecionadas mantêm velocidade temporal 1x e conservam a sua posição relativa no vídeo. |
| RN4 | Quando existe áudio, a sua velocidade acompanha a do respetivo segmento. O requisito não implica preservar o tom original nem manter o áudio binariamente idêntico. |
| RN5 | Um intervalo a 1x não muda de velocidade nem de escala temporal; o resultado continua sujeito à codificação de saída definida no MVP. |
| RN6 | O output respeita a quota de armazenamento existente do proprietário: 1 000 000 000 bytes para Free e 5 000 000 000 bytes para Premium. A contabilização usa o tamanho real do resultado; igualdade com o limite é aceite. Não existe nesta versão uma regra de quota diária de operações de speed. |
| RN7 | A operação nunca substitui o original; cria um ficheiro com identificador distinto. |
| RN8 | A submissão exige uma lista não vazia e configuração válida; as verificações dependentes do conteúdo são repetidas pelo worker antes da transformação. |
| RN9 | No MVP, o sistema confirma a aceitação assíncrona e disponibiliza o resultado final na biblioteca. Consulta persistente de estado, progresso contínuo e notificação de erro final permanecem evoluções futuras. |
| RN10 | O acesso à operação exige sessão válida e permissão de edição no projeto; ter apenas leitura não é suficiente. |
| RN11 | A entrada deve ser MP4/H.264; a saída é MP4/H.264, com áudio AAC se a entrada tiver áudio, ou sem áudio se não tiver. Não se exige AAC como codec de entrada do áudio. |
| RN12 | Não se impõem em speed os limites de duração ou o intervalo mínimo específicos de trim. A política de precisão para conteúdos gerais permanece em aberto; a seleção deve respeitar os limites temporais válidos. |
| RN13 | A associação bem-sucedida de um novo resultado incrementa a versão do projeto uma vez. Repetir a mesma mensagem não deve duplicar o vídeo nem a contabilização. |

### 2.7 Assunções e Decisões de Qualidade

| ID | Assunção |
| --- | --- |
| A1 | O âmbito de utilização considerado é o de utilizadores registados Free/Premium com sessão válida; as permissões do projeto continuam aplicáveis. |
| A2 | O vídeo de entrada já foi carregado e associado ao projeto; este UC não substitui a validação do upload. |
| A3 | Estão disponíveis a infraestrutura assíncrona, o armazenamento de media e a persistência do projeto. A indisponibilidade não equivale a processamento concluído. |
| A4 | É possível obter a duração de um stream de vídeo válido e endereçar segmentos em segundos. Uma precisão universal de corte não se considera demonstrada para todos os vídeos. |
| A5 | O ambiente de execução dispõe de suporte a MP4/H.264 e aos codecs de áudio aceites para descodificação; FFmpeg e ffprobe são dependências da implementação atual. |
| A6 | O ajuste temporal de áudio/vídeo é verificável nos conteúdos de teste; não se presume validação de toda a combinação possível de timestamps, taxas de fotogramas e durações de streams. |
| A7 | Os intervalos pertencem ao mesmo vídeo e podem ter velocidades diferentes. |

| ID | Decisão de qualidade | Justificação e relação |
| --- | --- | --- |
| DQ-001 | Submissão e execução desacopladas. | A chamada de submissão não aguarda a transformação pesada do vídeo; REQ-VID-SPEED-008 e REQ-VID-SPEED-036. |
| DQ-002 | Processamento não destrutivo e resultado independente. | Protege o original e permite comparar os artefactos; REQ-VID-SPEED-020 e REQ-VID-SPEED-021. |
| DQ-003 | Reutilização do controlo de acesso e versionamento existentes. | Evita uma autorização paralela e submissões sobre versões desatualizadas; REQ-VID-SPEED-028, REQ-VID-SPEED-029 e REQ-VID-SPEED-035. |
| DQ-004 | Saída compatível com a biblioteca existente. | MP4/H.264 e AAC quando aplicável, sem inventar áudio; REQ-VID-SPEED-017 e REQ-VID-SPEED-030. |
| DQ-005 | Contabilização de armazenamento pelo tamanho efetivo do output. | Reutiliza a reserva, confirmação e libertação existentes e trata resultados repetidos; REQ-VID-SPEED-019, REQ-VID-SPEED-031 e REQ-VID-SPEED-032. |
| DQ-006 | Evidência e limitações explícitas. | Distingue implementação, testes, objetivos futuros e limpeza em saídas controladas; REQ-VID-SPEED-034, REQ-VID-SPEED-037 e REQ-VID-SPEED-038. |

### 2.8 Questões em Aberto e Decisões

| ID | Questão original / refinada | Estado nesta revisão |
| --- | --- | --- |
| Q1 | Que limites de duração e tamanho se aplicam por perfil? | Parcialmente resolvida: a quota de armazenamento de RN6 é conhecida. Não se definiu um limite adicional de duração de speed; não se copiam os 180 s/60 min nem o mínimo de 1 s do trim. |
| Q2 | Um vídeo conta como uma operação diária, independentemente do número de intervalos? | Em aberto. Speed não consulta, debita nem repõe saldo diário de operações. Definir a política com a equipa antes de a especificar como comportamento ativo. |
| Q3 | Cancelamento apenas em fila ou também em execução? | No MVP apenas se desiste antes de enviar (FA6). O cancelamento de um pedido em fila é intenção futura preservada em REQ-VID-SPEED-016; o cancelamento em execução permanece sem decisão. |
| Q4 | Apresentar estimativa da duração do resultado antes de submeter? | Em aberto para evolução futura. A fórmula da secção 4.6 serve para verificação, não significa que exista uma estimativa na interface. |
| Q5 | Qual a precisão mínima da seleção temporal? | Parcialmente caracterizada: slider atual com passo de 0,1 s e campos numéricos sem passo fixo. Isto não garante precisão universal do output; falta definir uma tolerância por classe de conteúdo. |
| Q6 | Preview do vídeo transformado antes do processamento completo? | Fora do MVP atual. O diálogo reproduz o original, não o resultado transformado. |
| Q7 | Que metas de latência, tempo de processamento e concorrência devem ser exigidas? | Em aberto. Faltam ambiente de referência, resolução, duração, número de intervalos e carga; não se inventam percentis nem limites temporais. |
| Q8 | Como recuperar falhas persistentes e reconciliar contabilização histórica? | Em aberto para robustez operacional. Não há transação distribuída nem reconciliação automática dos resultados anteriores à correção de quota; não se presume entrega exatamente uma vez de ponta a ponta. |

## 3. Utilização de agentes de IA

| Ferramenta | Tarefa apoiada | Validação / limites da evidência |
| --- | --- | --- |
| ChatGPT | Estruturação inicial do caso de uso e distinção face a upload, trim, remoção de segmento e junção. | Revisão do enunciado, regras e fronteiras funcionais; a baseline continha intenções que não coincidem integralmente com o MVP implementado. |
| Codex | Implementação por fases, leitura do repositório, integração de frontend/backend/worker, resolução combinada de conflitos e correção da quota de armazenamento. | Testes automatizados e verificações de código registados durante o trabalho; teste funcional com Docker comunicado pelo utilizador. Não equivale a validação manual de todos os cenários. |
| Codex | Revisão deste dossiê em comparação com trim.md, upload.md e o código atual. | Conferência de IDs, rastreabilidade, âmbito e afirmações de implementação. A revisão documental não reexecuta os testes funcionais nem aprova novas regras de negócio em nome da equipa. |

## 4. Especificação de Requisitos do Sistema (ERS)

**Baseline:** REQ-VID-SPEED-001 a REQ-VID-SPEED-021 preservados. Os novos IDs são acrescentados a partir de REQ-VID-SPEED-022.

**Evolução:** Mantido conserva a intenção; Refinado esclarece condições/âmbito; Reclassificado altera a classificação, não a obrigação; Adiado conserva a intenção como evolução futura; Novo acrescenta cobertura. A classificação Novo/Alt descreve o impacto no PictuRAS, não o estado de implementação.

**Refinamentos relevantes da baseline:** REQ-VID-SPEED-009 concretiza no MVP a confirmação de submissão; o acompanhamento posterior não está implementado. REQ-VID-SPEED-013 e REQ-VID-SPEED-016 são adiados, sem eliminar IDs. REQ-VID-SPEED-018 passa a restrição funcional de aceitação. REQ-VID-SPEED-019 é esclarecido como quota de armazenamento; a contagem diária permanece em Q2. A preservação do original de REQ-VID-SPEED-021 mantém-se, enquanto a comunicação terminal de erro é explicitada como evolução em REQ-VID-SPEED-038.

**Revisão do Exercício 3:** v3.0, sobre o texto v2.0 disponível neste ficheiro antes da presente edição. Essa v2.0 estava untracked, pelo que não é atribuída a um commit de documentação. A comparação literal das formulações alteradas consta da secção 4.4.1; os 38 IDs são preservados, sem renumeração nem novos requisitos.

**Evolução** conserva a classificação histórica face à baseline v1.0 (Mantido, Refinado, Novo ou Adiado). **Estado** indica exclusivamente o resultado desta revisão v2.0 → v3.0: Inalterado ou Refinado, considerando a formulação e as condições de verificação. Nenhuma destas colunas significa «implementado» ou «testado»: esses estados e a evidência histórica são tratados na secção 4.5. Um requisito futuro pode estar documentalmente inalterado e continuar não implementado.

### 4.1 Requisitos da ERS

#### 4.1.1 Requisitos Funcionais

| ID | Requisito | Prioridade | Evolução | Novo/Alt | Origem | Justificação | Critério de aceitação / verificação | Estado |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-VID-SPEED-001 | O sistema deve permitir iniciar Modificar velocidade para um vídeo associado ao projeto acessível ao utilizador. | Deve ter | Refinado | NOVO | Passos 1–2; A2 | Contextualiza a operação no projeto existente. | Dado um vídeo associado e acesso de edição, quando o utilizador abre a ação, então o diálogo identifica esse vídeo. | Inalterado |
| REQ-VID-SPEED-002 | O sistema deve permitir indicar o início e o fim de cada intervalo em segundos. | Deve ter | Mantido | NOVO | Passo 3; A4 | Permite parametrização temporal. | Dado o diálogo com duração disponível, quando se alteram os campos ou a seleção temporal, então a configuração apresenta os valores escolhidos. | Inalterado |
| REQ-VID-SPEED-003 | O sistema deve aceitar apenas os fatores de velocidade 0,5x, 1x e 2x. | Deve ter | Mantido | NOVO | Passo 4; RN1 | Evita velocidades fora do âmbito. | Dado um intervalo, quando se escolhe uma opção, então apenas estes fatores estão disponíveis; um pedido com 0,25, 4 ou uma string em vez de número é rejeitado. | Inalterado |
| REQ-VID-SPEED-004 | O sistema deve manter a velocidade configurada independentemente para cada intervalo do mesmo vídeo. | Deve ter | Mantido | NOVO | Passo 5; FA1; A7 | Suporta várias alterações numa operação. | Dados dois intervalos válidos com velocidades distintas, quando o pedido é submetido, então ambos mantêm os respetivos parâmetros. | Inalterado |
| REQ-VID-SPEED-005 | O sistema deve rejeitar um intervalo cujo fim seja igual ou anterior ao início. | Deve ter | Mantido | NOVO | Passo 6; EX2; RN2 | Impede durações nulas ou negativas. | Dado início 4 e fim 4 ou 3, quando se valida, então o intervalo é rejeitado e não é processado como válido. | Inalterado |
| REQ-VID-SPEED-006 | O sistema deve rejeitar sobreposição entre intervalos, permitindo apenas fronteiras adjacentes. | Deve ter | Refinado | NOVO | Passo 6; EX3; RN2 | Evita atribuir duas velocidades ao mesmo trecho. | Dados [2,5] e [4,7], a configuração é rejeitada; dados [2,4] e [4,6], é aceite quanto à sobreposição, mesmo se introduzidos por ordem inversa. | Inalterado |
| REQ-VID-SPEED-007 | O sistema deve apresentar a lista/resumo dos intervalos e velocidades antes de submeter. | Deveria ter | Refinado | NOVO | Passo 7 | Permite rever a configuração sem confirmação duplicada. | Dados intervalos configurados, quando o diálogo é consultado antes de Processar, então mostra início, fim e velocidade de cada um. | Inalterado |
| REQ-VID-SPEED-008 | O sistema deve aceitar a submissão de uma configuração válida para processamento assíncrono, atribuindo um identificador de pedido e um novo identificador de vídeo. | Deve ter | Refinado | NOVO | Passo 8; RN8; DQ-001 | Liga submissão, resultado e artefacto independente. | Dado um pedido autorizado e válido, quando é aceite, então devolve aceitação assíncrona e identificadores, sem substituir o identificador do original. | Inalterado |
| REQ-VID-SPEED-009 | O sistema deve confirmar a submissão aceite e informar que o novo vídeo ficará disponível após conclusão, sem apresentar essa aceitação como sucesso do processamento. | Deve ter | Refinado; acompanhamento persistente adiado | NOVO | Passo 9; RN9 | Não confunde aceitação com sucesso final. | Dada uma resposta de aceitação, quando a interface a recebe, então apresenta a confirmação de submissão e não anuncia o vídeo como já produzido. | Refinado |
| REQ-VID-SPEED-010 | O sistema deve transformar a duração de cada intervalo segundo o fator definido, conservando a sua ordem temporal. | Deve ter | Refinado | NOVO | Passo 10; RN1 | Define o significado verificável de velocidade. | Dados os casos A–C da secção 4.6, quando são processados, então as durações correspondem à fórmula, dentro da tolerância do ensaio. | Inalterado |
| REQ-VID-SPEED-011 | O sistema deve manter a velocidade temporal 1x das partes não selecionadas. | Deve ter | Mantido | NOVO | Passo 10; RN3; RN5 | Limita o efeito às seleções. | Dado um vídeo com trechos selecionados e não selecionados, quando se inspeciona o resultado, então os trechos não selecionados mantêm a sua escala temporal e ordem. | Inalterado |
| REQ-VID-SPEED-012 | O sistema deve ajustar a velocidade do áudio existente de acordo com o fator aplicado ao respetivo segmento. | Deve ter | Mantido | NOVO | Passo 11; RN4 | Mantém coerência temporal áudio/vídeo. | Dado um segmento com áudio a 2x ou 0,5x, quando se processa, então áudio e vídeo apresentam durações coerentes com o mesmo fator, segundo o ensaio definido. | Inalterado |
| REQ-VID-SPEED-014 | O sistema deve armazenar o vídeo resultante sob uma referência distinta da original. | Deve ter | Refinado | NOVO | Passo 12; RN7 | Evita substituição do conteúdo de origem. | Dado um output válido, quando é transferido, então usa um novo identificador e uma chave distinta da do original. | Inalterado |
| REQ-VID-SPEED-015 | O sistema deve disponibilizar na biblioteca do projeto apenas um resultado associado com sucesso. | Deve ter | Refinado | ALT | Passo 13; EX4; EX6 | Evita anunciar ficheiros não associados. | Dada associação bem-sucedida, o novo vídeo surge após atualização do projeto; se quota ou associação falharem, não surge como resultado final. | Inalterado |
| REQ-VID-SPEED-016 | Numa evolução futura, o sistema deve permitir cancelar um pedido enquanto ainda aguarda execução. | Deveria ter | Adiado | NOVO | FA4; Q3 | Preserva a intenção sem declarar suporte inexistente. | Dado um pedido ainda não executado numa versão futura, quando o cancelamento é confirmado, então não produz um resultado; o mecanismo e os testes ainda não estão implementados. | Inalterado |
| REQ-VID-SPEED-017 | O sistema deve processar uma entrada sem áudio sem acrescentar uma faixa artificial. | Deve ter | Refinado; prioridade promovida | NOVO | FA5; RN11 | Torna explícita a ausência de áudio na saída. | Dado um MP4/H.264 sem áudio, quando se processa, então a inspeção do output continua sem streams de áudio. | Inalterado |
| REQ-VID-SPEED-018 | O sistema deve rejeitar uma entrada que não seja MP4 com vídeo H.264 válido. | Deve ter | Reclassificado como funcional | NOVO | EX1; RN11; A5 | É uma condição funcional de aceitação, não uma medição de desempenho. | Dada uma entrada sem vídeo, com contentor diferente de MP4 ou codec de vídeo diferente de H.264, quando o worker a valida, então não produz um resultado associado. | Inalterado |
| REQ-VID-SPEED-019 | O sistema deve recusar a associação do resultado se os seus bytes reais fizerem ultrapassar a quota acumulada de armazenamento do proprietário. | Deve ter | Refinado | ALT | Passo 13; EX4; RN6; DQ-005 | Reutiliza a quota existente sem inventar contagem diária. | Dada conta Free com 999 999 990 bytes e output de 20 bytes, a associação é recusada; com 999 999 980 bytes, o mesmo output é aceite. | Refinado |
| REQ-VID-SPEED-022 | O sistema deve rejeitar tempos de início ou fim que não sejam números finitos. | Deve ter | Novo | NOVO | Passo 6; EX2; RN2 | Evita coerções e parâmetros não representáveis. | Dados campos vazios na interface, ou null, strings e valores não finitos na API, quando se valida, então não são aceites como tempos válidos. | Inalterado |
| REQ-VID-SPEED-023 | O sistema deve rejeitar um início negativo. | Deve ter | Novo | NOVO | Passo 6; EX2; RN2 | Impede referências anteriores à origem temporal. | Dado início -1 e fim 2, quando se valida, então o intervalo é rejeitado. | Inalterado |
| REQ-VID-SPEED-024 | O sistema deve rejeitar um fim que ultrapasse a duração real do vídeo. | Deve ter | Novo | NOVO | Passos 6 e 10; EX11; RN2 | Impede selecionar conteúdo inexistente. | Dado vídeo de 10 s e fim 11 s, a interface bloqueia; se um pedido direto chegar ao worker, este rejeita-o após medir a duração, sem adicionar resultado. | Inalterado |
| REQ-VID-SPEED-025 | O sistema deve exigir pelo menos um intervalo válido. | Deve ter | Novo | NOVO | Passo 6; EX10; RN8 | Evita operações sem configuração. | Dada uma lista vazia ou ausente, quando se tenta submeter, então a configuração não é aceite. | Inalterado |
| REQ-VID-SPEED-026 | O sistema deve permitir editar tempos e velocidade de um intervalo antes da submissão. | Deve ter | Novo | NOVO | Passo 5; FA3 | Permite corrigir a seleção sem criar tarefas. | Dado um intervalo na lista, quando é editado, então a lista e os erros refletem a nova configuração antes de Processar. | Inalterado |
| REQ-VID-SPEED-027 | O sistema deve permitir remover um intervalo antes da submissão. | Deve ter | Novo | NOVO | Passo 5; FA3 | Permite desistir de uma alteração específica. | Dados vários intervalos, quando um é removido, então deixa de integrar o pedido; removendo todos, aplica-se REQ-VID-SPEED-025. | Inalterado |
| REQ-VID-SPEED-028 | O sistema deve recusar a submissão sem sessão válida ou sem permissão de edição no projeto. | Deve ter | Novo | ALT | Passo 8; FA7; EX8; RN10 | Reutiliza autenticação e partilhas. | Dados pedidos sem JWT válido ou através de partilha só de leitura, quando são submetidos, então são recusados; uma partilha válida com edição permite a operação. | Inalterado |
| REQ-VID-SPEED-029 | O sistema deve recusar uma submissão sem versão válida ou cuja versão não coincida com a atual do projeto. | Deve ter | Novo | ALT | Passo 8; EX9; DQ-003 | Mantém o contrato de concorrência existente. | Dada versão inválida/ausente, a API responde 428; dada versão desatualizada, responde 409, sem enfileirar a operação. | Inalterado |
| REQ-VID-SPEED-030 | O sistema deve gerar MP4/H.264 com AAC quando existe áudio de entrada. | Deve ter | Novo | NOVO | Passos 11–12; RN11; DQ-004 | Define a compatibilidade de saída. | Dado um input com áudio e transformação concluída, quando o output é inspecionado, então possui vídeo h264 e áudio aac em MP4; o caso sem áudio segue REQ-VID-SPEED-017. | Inalterado |
| REQ-VID-SPEED-031 | O sistema deve libertar a reserva de armazenamento quando uma falha controlada impede a associação do resultado. | Deve ter | Novo | ALT | EX4; EX6; RN6; DQ-005 | Evita reservas sem resultado associado. | Dada reserva de 20 bytes e falha de associação, quando o tratamento de erro termina com a infraestrutura disponível, então os bytes usados regressam ao valor anterior e nenhum add-video é emitido. | Inalterado |
| REQ-VID-SPEED-032 | O sistema deve incrementar a versão apenas na nova associação e evitar repetir essa associação e contabilização para o mesmo resultado. | Deve ter | Novo | ALT | Passo 13; EX13; RN13 | Evita duplicação por repetição de mensagens. | Dado o mesmo resultado entregue duas vezes sequencialmente, então existe apenas um novo vídeo, um incremento de versão e uma contabilização do output; não é apagado o vídeo associado. | Inalterado |
| REQ-VID-SPEED-033 | O sistema deve apresentar mensagens claras para erros de configuração e de submissão recebidos pela interface. | Deve ter | Novo | ALT | Passo 6; EX2–3; EX8–10 | Permite corrigir erros antes de gerar novo pedido. | Dada configuração inválida ou resposta HTTP de autenticação, permissão ou versão, quando ocorre o erro, então a interface o identifica e não apresenta sucesso de processamento. | Inalterado |
| REQ-VID-SPEED-038 | Numa evolução futura, o sistema deve comunicar ao utilizador a falha terminal de um pedido já aceite, distinguindo-a de um erro de submissão. | Deveria ter | Novo; adiado | NOVO | EX1; EX4; EX6–7; RN9; DQ-006 | Explicita uma intenção da garantia mínima ainda não implementada na interface. | Dado um pedido aceite que posteriormente falha numa versão futura, quando o estado final estiver disponível, então o utilizador pode identificar a falha e o pedido; mecanismo e validação ainda por definir. | Inalterado |

Não existe requisito de débito diário de speed enquanto Q2 não for decidida. Em REQ-VID-SPEED-032, a cobertura atual é de repetição sequencial; não se afirma uma garantia global de execução exatamente uma vez sob entregas concorrentes ou falhas de rede.

#### 4.1.2 Requisitos Não Funcionais e de Qualidade

As características seguem a organização dos outros dossiês. Um alvo de produção não é uma funcionalidade implementada. Onde faltam valores aprovados ou medições, estes ficam pendentes; não se copiam metas de trim para speed.

| ID | Requisito | Característica de qualidade | Alvo MVP | Alvo produção | Condição de medição | Evolução | Origem | Critério de aceitação / verificação | Estado |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-VID-SPEED-013 | Numa evolução futura, o sistema deve disponibilizar acompanhamento do progresso após a aceitação do pedido. | Usabilidade / transparência de estado | Adiado; o MVP confirma submissão e atualiza a biblioteca no sucesso, sem consulta persistente ou percentagem. | Proporcionar acompanhamento consultável e progresso, após definir semântica, frequência e critérios; sem implementação atual. | Apenas numa evolução futura, após definir estados, frequência e precisão: observar um pedido aceite durante espera, execução e término, relacionando as atualizações com o pedido. Funcionalidade e ensaio pendentes; não medir percentagem na UI atual. | Adiado e reclassificado | Passo 9; RN9; Q7 | Numa evolução futura, dado um pedido aceite, quando progride ou termina, então o estado consultado reflete essa evolução. Frequência e precisão não estão definidas nem validadas. | Refinado |
| REQ-VID-SPEED-020 | O sistema deve preservar o conteúdo do vídeo original após a operação. | Fiabilidade / integridade | Original não sobrescrito, com identificador distinto para o resultado. | Manter a garantia perante as falhas adicionais que vierem a ser definidas. | Calcular SHA-256 do mesmo original antes e depois de um processamento bem-sucedido e de falhas controladas de FFmpeg e associação. Comparar também a referência do original no projeto; usar os mesmos bytes de entrada. | Mantido | RN7; DQ-002 | Dado o hash SHA-256 do original, quando uma transformação termina, então o original conserva o mesmo hash. Ensaiar sucesso e caminhos de erro aplicáveis. | Refinado |
| REQ-VID-SPEED-021 | O sistema deve impedir que um output parcial ou cujo registo falhou seja apresentado na biblioteca como resultado final bem-sucedido. | Fiabilidade / consistência | Ausência de associação de resultado falhado ou parcial; preservação do original verificada em REQ-VID-SPEED-020. | Definir recuperação automática para falhas persistentes; não se presume que já exista. | Injetar separadamente erro de FFmpeg, resultado status error, recusa de quota e falha controlada de associação. Consultar project.videos após cada cenário e verificar ausência de novo resultado final; não confundir um objeto órfão no storage com um vídeo disponível na biblioteca. | Refinado | EX1; EX6–7; garantia mínima; DQ-002 | Dada falha controlada de processamento ou associação, quando se consulta o projeto, então o original continua associado e não há um novo resultado parcial apresentado como sucesso. | Refinado |
| REQ-VID-SPEED-034 | O sistema deve limpar os ficheiros de trabalho locais nas saídas controladas do worker e, no tratamento de um resultado de sucesso cuja associação falha, tentar remover o output confirmado como não associado. | Fiabilidade / gestão de recursos | Limpeza local em sucesso/exceção controlada; tentativa de remoção remota apenas no rollback da associação de um resultado de sucesso, com confirmação de ausência de associação. | Definir recolha de órfãos e recuperação após terminação abrupta do processo; Q8 em aberto. | Observar a existência do diretório temporário após sucesso e exceção controlada. Para um resultado de sucesso não associado, simular recusa de quota/falha de associação e verificar tentativas de DELETE e release. Testar falha de DELETE com release ainda tentado. No ramo status error, verificar apenas o registo; não exigir limpeza remota inexistente. Infraestrutura disponível para a verificação da associação. | Novo | EX4; EX6–7; DQ-006 | Dada conclusão ou exceção controlada, o diretório temporário é limpo. Dado um resultado de sucesso não associado, o rollback tenta remover o output e libertar a reserva; uma falha de DELETE não impede a tentativa de release. Resultados status error são apenas registados. | Refinado |
| REQ-VID-SPEED-035 | O sistema deve manter os controlos de acesso existentes nas operações usadas para obter o original e publicar o resultado. | Segurança / controlo de acesso | Autorização do projeto na API e acesso interno ao storage pelo mecanismo existente, sem expor a chave interna no frontend. | Rever os controlos e cenários de acesso a cada evolução; não se acrescenta um requisito de infraestrutura não decidido. | Ensaiar submissões sem JWT, com sessão inválida, partilha read, partilha edit válida e acesso revogado; ensaiar endpoints internos sem chave e com chave inválida. Observar respostas de recusa sem expor a chave no browser; testar separadamente acesso autorizado. | Novo | RN10; DQ-003 | Dado um pedido sem autorização ou sem chave interna válida, quando tenta usar o respetivo endpoint protegido, então não obtém acesso autorizado; complementar com ensaios de partilha e ausência de sessão. | Refinado |
| REQ-VID-SPEED-036 | O sistema deve aceitar uma submissão válida sem aguardar a conclusão da transformação do vídeo. | Eficiência / interação assíncrona | Aceitação independente da conclusão do worker; nenhum tempo máximo numérico é assumido. | Definir e medir latência e capacidade num ambiente de referência; Q7 em aberto. | Manter o worker controladamente sem concluir a transformação, submeter um pedido válido e verificar receção de HTTP 202 enquanto o output ainda não está disponível. Para medir latência, registar instantes de envio/resposta, hardware, rede, carga, resolução, duração e número de intervalos; limiar e amostragem por aprovar. | Novo | Passos 8–10; DQ-001 | Dada uma tarefa cujo processamento ainda não terminou, quando a submissão é aceite, então o cliente recebe a aceitação sem ter de aguardar o resultado final. | Refinado |
| REQ-VID-SPEED-037 | A extensão de speed deve preservar os fluxos existentes de upload, trim e biblioteca do projeto. | Compatibilidade / manutenibilidade | Integração nos serviços e contratos existentes, com regressão dos percursos abrangidos pelos testes. | Ampliar a matriz de regressão, incluindo imagens e operações concorrentes. | Com versões e ambiente registados, executar upload/listagem de MP4 e imagem, trim e navegação da biblioteca antes/depois da integração; verificar original, novos resultados e erros. Executar suites dos serviços e complementar com browser/Docker; matriz completa, partilhas e concorrência ainda pendentes. | Novo | Fronteira do UC; DQ-006 | Dados os fluxos existentes, quando se executam os testes de regressão após integrar speed, então os cenários de upload, trim e navegação abrangidos continuam utilizáveis; não se presume cobertura de toda a aplicação. | Refinado |

#### 4.1.3 Verificação de completude e limites do âmbito

| Tópico | Decisão de âmbito | Requisitos / questões |
| --- | --- | --- |
| Formato e áudio | MP4/H.264; saída AAC se existir áudio; sem faixa artificial caso contrário. | REQ-VID-SPEED-012, REQ-VID-SPEED-017, REQ-VID-SPEED-018, REQ-VID-SPEED-030 |
| Tempos e intervalos | Lista não vazia, números finitos, limites válidos, adjacência aceite e sobreposição recusada. Sem duração mínima/máxima adicional de speed. | REQ-VID-SPEED-005, REQ-VID-SPEED-006, REQ-VID-SPEED-022, REQ-VID-SPEED-023, REQ-VID-SPEED-024, REQ-VID-SPEED-025; Q1 e Q5 |
| Configuração e preview | Adicionar/editar/remover e consultar resumo antes de Processar. O reprodutor mostra o original, não uma simulação do output. | REQ-VID-SPEED-002, REQ-VID-SPEED-003, REQ-VID-SPEED-004, REQ-VID-SPEED-007, REQ-VID-SPEED-026, REQ-VID-SPEED-027; Q4 e Q6 |
| Quotas | Armazenamento real do output na conta do proprietário; não define custo diário por operação ou intervalo. | REQ-VID-SPEED-019, REQ-VID-SPEED-031; Q2 |
| Estado e cancelamento | Aceitação no MVP; acompanhamento persistente, progresso e cancelamento após submissão são futuros. Desistir antes de enviar não cancela uma tarefa já aceite. | REQ-VID-SPEED-009, REQ-VID-SPEED-013, REQ-VID-SPEED-016; FA6 e Q3 |
| Falhas e recuperação | Validação e erros HTTP visíveis; falhas assíncronas registadas. Rollback no tratamento de sucesso cuja associação falha; status error apenas registado. Recuperação distribuída não garantida. | REQ-VID-SPEED-021, REQ-VID-SPEED-031, REQ-VID-SPEED-034, REQ-VID-SPEED-038; Q8 |
| Preservação e repetição | Novo artefacto, original intacto, associação/versionamento sem duplicação no cenário sequencial coberto. | REQ-VID-SPEED-014, REQ-VID-SPEED-020, REQ-VID-SPEED-032 |
| Retenção, lote e encadeamento | Reutiliza a biblioteca. Não define expiração de ficheiros, lote entre vídeos nem cadeia de ferramentas. | Fora do âmbito deste UC; exigem decisões próprias. |

### 4.2 Impacto no sistema existente

| Elemento | Impacto | Descrição | Requisitos relacionados |
| --- | --- | --- | --- |
| Frontend do projeto | Estender | Ação, diálogo, lista editável, validação, submissão e mensagens de erro HTTP, sem alterar os controlos próprios de trim. | REQ-VID-SPEED-001, REQ-VID-SPEED-002, REQ-VID-SPEED-003, REQ-VID-SPEED-004, REQ-VID-SPEED-007, REQ-VID-SPEED-009, REQ-VID-SPEED-026, REQ-VID-SPEED-027, REQ-VID-SPEED-033 |
| API Gateway | Estender | Proxy POST /projects/:user/:project/video/:videoId/speed, preservando token, contexto de partilha e versão. | REQ-VID-SPEED-008, REQ-VID-SPEED-028, REQ-VID-SPEED-029 |
| Projects | Estender | Valida e publica a operação; consome resultados, contabiliza bytes, associa o novo vídeo e incrementa a versão. | REQ-VID-SPEED-008, REQ-VID-SPEED-015, REQ-VID-SPEED-019, REQ-VID-SPEED-031, REQ-VID-SPEED-032 |
| RabbitMQ | Estender | Reutiliza a infraestrutura e o contrato de resultados; pedido em video_speed_queue e resultado em video_results_queue. As filas são declaradas pelo worker. | REQ-VID-SPEED-008, REQ-VID-SPEED-036 |
| videoSpeedWorker | Estender | Novo worker independente com ffprobe/FFmpeg, diretório temporário, transformação dos segmentos e resultado de sucesso/erro. | REQ-VID-SPEED-010, REQ-VID-SPEED-011, REQ-VID-SPEED-012, REQ-VID-SPEED-017, REQ-VID-SPEED-018, REQ-VID-SPEED-030, REQ-VID-SPEED-034 |
| Media Storage / SeaweedFS | Reutilizar | URL interna para o original e gravação do novo MP4 por referência distinta; tentativa de limpeza no rollback de um resultado de sucesso não associado. | REQ-VID-SPEED-014, REQ-VID-SPEED-020, REQ-VID-SPEED-034, REQ-VID-SPEED-035 |
| MongoDB / quota existente | Reutilizar e estender o chamador | Usa videos/version do projeto e VideoStorageAccount através de reserve, commit e release; sem duplicar limites nem criar coleção de jobs de speed. | REQ-VID-SPEED-015, REQ-VID-SPEED-019, REQ-VID-SPEED-031, REQ-VID-SPEED-032 |
| WebSocket existente | Reutilizar | Publica add-video em ws_queue/project-op para atualização da biblioteca. Não cria acompanhamento específico de progresso/erro de speed. | REQ-VID-SPEED-015, REQ-VID-SPEED-032 |
| Docker Compose | Estender | Serviço video_speed com as dependências de RabbitMQ, media storage e FFmpeg no contentor do worker. | REQ-VID-SPEED-008, REQ-VID-SPEED-036, REQ-VID-SPEED-037 |
| Upload, trim e imagens | Manter | Preserva os fluxos dos colegas. Os limites e decisões específicos de trim não são herdados automaticamente por speed. | REQ-VID-SPEED-037 |

O percurso implementado é: frontend → API Gateway → Projects → video_speed_queue → worker/FFmpeg → Media Storage → video_results_queue → Projects → ws_queue/project-op/add-video → biblioteca.

O pedido usa procedure video_speed e parâmetros ownerId, projectId, videoId, newVideoId, newVideoName, intervals, callerId e projectVersion. O resultado inclui correlationId e o tamanho real do output em size. Estes são detalhes do contrato atual, não novas regras de negócio.

### 4.3 Matriz de Rastreabilidade Atualizada

| Origem | Obrigação / fronteira | Requisitos relacionados |
| --- | --- | --- |
| Objetivo, pré-condições e passos 1–2 | Abrir a ferramenta sobre um vídeo associado e autorizado. | REQ-VID-SPEED-001, REQ-VID-SPEED-028 |
| Passo 3 | Parametrizar o intervalo. | REQ-VID-SPEED-002 |
| Passo 4; RN1 e RN5 | Escolher uma velocidade válida. | REQ-VID-SPEED-003 |
| Passo 5; FA1, FA3 e A7 | Vários intervalos, edição e remoção. | REQ-VID-SPEED-004, REQ-VID-SPEED-026, REQ-VID-SPEED-027 |
| Passo 6; EX2–3, EX10–11; RN2 e RN8 | Validar configuração e duração. | REQ-VID-SPEED-005, REQ-VID-SPEED-006, REQ-VID-SPEED-022, REQ-VID-SPEED-023, REQ-VID-SPEED-024, REQ-VID-SPEED-025 |
| Passo 7 | Rever a lista antes de Processar. | REQ-VID-SPEED-007 |
| Passo 8; EX9; DQ-001 e DQ-003 | Submeter assincronamente com versão e identificadores. | REQ-VID-SPEED-008, REQ-VID-SPEED-029, REQ-VID-SPEED-036 |
| Passo 9; RN9 | Confirmar aceitação, distinguindo-a da conclusão. | REQ-VID-SPEED-009 |
| Passo 10; FA2; RN1, RN3 e RN5 | Aplicar velocidades, conservar ordem e partes a 1x. | REQ-VID-SPEED-010, REQ-VID-SPEED-011 |
| Passo 11; FA5; EX7; RN4 | Ajustar áudio ou manter ausência de áudio. | REQ-VID-SPEED-012, REQ-VID-SPEED-017 |
| Passo 12; RN7 e RN11; DQ-004 | Guardar um artefacto distinto e compatível. | REQ-VID-SPEED-014, REQ-VID-SPEED-030 |
| Passo 13; EX4 e EX13; RN6 e RN13 | Associar, contabilizar e atualizar a biblioteca. | REQ-VID-SPEED-015, REQ-VID-SPEED-019, REQ-VID-SPEED-031, REQ-VID-SPEED-032 |
| EX1; RN11; A5 | Validar a entrada. | REQ-VID-SPEED-018 |
| EX6–7; pós-condições; RN7; DQ-002 | Preservar original e impedir resultado parcial final. | REQ-VID-SPEED-020, REQ-VID-SPEED-021 |
| EX8; FA7; RN10; DQ-003 | Respeitar acesso e partilhas. | REQ-VID-SPEED-028, REQ-VID-SPEED-035 |
| Passo 6; EX2–3 e EX8–10 | Apresentar erros síncronos úteis. | REQ-VID-SPEED-033 |
| EX4, EX6–7; DQ-005 e DQ-006 | Libertar reservas e limpar recursos nas saídas controladas. | REQ-VID-SPEED-031, REQ-VID-SPEED-034 |
| Fronteira do UC; DQ-006 | Evitar regressões nas funcionalidades existentes. | REQ-VID-SPEED-037 |
| Intenção de acompanhamento da baseline; RN9 | Progresso consultável futuro. | REQ-VID-SPEED-013 |
| FA4; Q3 | Cancelamento de tarefa em fila futuro. | REQ-VID-SPEED-016 |
| Garantia mínima da baseline; EX1, EX4 e EX6–7; DQ-006 | Notificação terminal de erro futura. | REQ-VID-SPEED-038 |
| FA6 | Desistir antes de enviar não cria uma tarefa. | Fronteira dos REQ-VID-SPEED-008 e REQ-VID-SPEED-016; verificação manual pendente. |
| EX5; Q2 | Quota diária não decidida. | Não cria um requisito ativo nem transforma REQ-VID-SPEED-019 em quota de operações. |
| A1–A3 | Contexto de acesso, vídeo previamente associado e infraestrutura disponível. | Suportam REQ-VID-SPEED-001, REQ-VID-SPEED-008 e REQ-VID-SPEED-028; não substituem as respetivas verificações. |
| A4–A7 | Medição temporal, suporte técnico, sincronização e intervalos do mesmo vídeo. | Relacionam-se com REQ-VID-SPEED-002, REQ-VID-SPEED-004, REQ-VID-SPEED-012, REQ-VID-SPEED-018 e REQ-VID-SPEED-024. |
| Q1, Q4–Q8 | Limites, estimativa, precisão, preview, desempenho e recuperação por decidir. | Não introduzem requisitos ativos sem decisão; ver secções 2.8 e 4.1.3. |

### 4.4 Registo de Refinamento

#### 4.4.1 Comparação original → refinado

A baseline usada é o texto v2.0 deste ficheiro lido antes da presente edição, não um commit de documentação. A coluna «Original v2.0» transcreve a formulação ou o critério de aceitação anterior, conforme o campo indicado. A versão v1.0 mantém-se como origem histórica dos IDs 001–021; não se reconstrói aqui um texto dessa versão que não foi consultado nesta revisão.

| Requisito | Campo refinado | Original v2.0 | Refinado v3.0 | Problema detetado / justificação |
| --- | --- | --- | --- | --- |
| REQ-VID-SPEED-009 | Formulação | O sistema deve informar que o pedido foi submetido e que o novo vídeo será disponibilizado após conclusão. | O sistema deve confirmar a submissão aceite e informar que o novo vídeo ficará disponível após conclusão, sem apresentar essa aceitação como sucesso do processamento. | A aceitação HTTP 202 podia ser confundida com conclusão; explicita a distinção já usada no diálogo. |
| REQ-VID-SPEED-013 | Formulação | O sistema deve disponibilizar acompanhamento do progresso após a aceitação do pedido. | Numa evolução futura, o sistema deve disponibilizar acompanhamento do progresso após a aceitação do pedido. | A frase isolada parecia exigir progresso atual; explicita a natureza futura já indicada no alvo MVP. |
| REQ-VID-SPEED-019 | Formulação | O sistema deve recusar a associação do resultado se os seus bytes reais ultrapassarem a quota de armazenamento do proprietário. | O sistema deve recusar a associação do resultado se os seus bytes reais fizerem ultrapassar a quota acumulada de armazenamento do proprietário. | «Quota» podia ser interpretada como limite por ficheiro ou quota diária; identifica armazenamento acumulado e bytes reais do output. |
| REQ-VID-SPEED-021 | Formulação | O sistema deve manter o original disponível e não expor um output parcial como resultado final em caso de falha. | O sistema deve impedir que um output parcial ou cujo registo falhou seja apresentado na biblioteca como resultado final bem-sucedido. | A frase reunia preservação do original e ausência de resultado parcial. A preservação continua em 020; 021 concentra a condição de exposição na biblioteca. |
| REQ-VID-SPEED-034 | Formulação | O sistema deve limpar os ficheiros de trabalho locais nas saídas controladas do processamento e tentar remover outputs não associados. | O sistema deve limpar os ficheiros de trabalho locais nas saídas controladas do worker e, no tratamento de um resultado de sucesso cuja associação falha, tentar remover o output confirmado como não associado. | A formulação genérica podia prometer limpeza para qualquer erro. Limita a limpeza remota ao ramo de sucesso cuja associação falha; distingue diretório temporário, storage e reserva. |
| REQ-VID-SPEED-036 | Formulação | A submissão não deve ficar bloqueada à espera da transformação completa do vídeo. | O sistema deve aceitar uma submissão válida sem aguardar a conclusão da transformação do vídeo. | «Não ficar bloqueada» não indicava uma observação concreta; explicita a aceitação independente do fim da transformação. |
| REQ-VID-SPEED-020 | Condição de verificação | Dado o hash SHA-256 do original, quando uma transformação termina, então o original conserva o mesmo hash. Ensaiar sucesso e caminhos de erro aplicáveis. | Calcular SHA-256 do mesmo original antes e depois de um processamento bem-sucedido e de falhas controladas de FFmpeg e associação. Comparar também a referência do original no projeto; usar os mesmos bytes de entrada. | A formulação mantém-se; acrescenta-se a condição de medição para tornar a verificação reproduzível. O ensaio completo continua pendente. |
| REQ-VID-SPEED-035 | Condição de verificação | Dado um pedido sem autorização ou sem chave interna válida, quando tenta usar o respetivo endpoint protegido, então não obtém acesso autorizado; complementar com ensaios de partilha e ausência de sessão. | Ensaiar submissões sem JWT, com sessão inválida, partilha read, partilha edit válida e acesso revogado; ensaiar endpoints internos sem chave e com chave inválida. Observar respostas de recusa sem expor a chave no browser; testar separadamente acesso autorizado. | A formulação mantém-se; acrescenta-se a condição de medição para tornar a verificação reproduzível. O ensaio completo continua pendente. |
| REQ-VID-SPEED-037 | Condição de verificação | Dados os fluxos existentes, quando se executam os testes de regressão após integrar speed, então os cenários de upload, trim e navegação abrangidos continuam utilizáveis; não se presume cobertura de toda a aplicação. | Com versões e ambiente registados, executar upload/listagem de MP4 e imagem, trim e navegação da biblioteca antes/depois da integração; verificar original, novos resultados e erros. Executar suites dos serviços e complementar com browser/Docker; matriz completa, partilhas e concorrência ainda pendentes. | A formulação mantém-se; acrescenta-se a condição de medição para tornar a verificação reproduzível. O ensaio completo continua pendente. |
| EX6; REQ-VID-SPEED-034 | Comportamento de erro | Se não tiver sido associado, Projects tenta limpar o output e libertar a reserva. | Projects apenas regista resultados status error. A tentativa de limpeza remota e release pertence ao tratamento de um resultado de sucesso cuja associação falha, após confirmar que o vídeo não está associado. | A redação anterior estendia o rollback a ramos que não o executam; um upload concluído seguido de falha na comunicação pode deixar um objeto órfão. |

Nos requisitos de qualidade 013, 021, 034 e 036, a formulação e as condições de medição foram refinadas em conjunto; as condições completas constam da tabela 4.1.2. Os restantes requisitos assinalados como Inalterado mantêm formulação e critério da v2.0. Não existem requisitos divididos, eliminados ou renumerados nesta revisão.

A EX6 e a evidência de limpeza deixam de pressupor remoção remota em qualquer falha do worker. Esta correção descreve o código existente; não implementa recolha de órfãos. A desistência antes de enviar continua distinta do cancelamento de uma tarefa aceite. Os requisitos 013, 016 e 038 continuam futuros, não passando a obrigações implementadas pelo facto de o dossiê evoluir para v3.0.

#### 4.4.2 Conflitos com o sistema existente e decisões

«Conflito» designa uma diferença entre a especificação, as propostas de outros casos de uso ou o comportamento dos componentes reutilizados. As decisões documentais descrevem a integração atual; propostas de negócio e garantias futuras continuam dependentes de aprovação da equipa.

| Requisito(s) / origem | Sistema ou regra existente | Conflito / risco | Decisão nesta revisão | Estado |
| --- | --- | --- | --- | --- |
| 019, 031; RN6; Q2 | videoQuota usa VideoStorageAccount e reserve/commit/release, com limites acumulados de 1/5 GB decimais para Free/Premium. Há também quotas diárias noutras operações. | Confundir limite por ficheiro, armazenamento acumulado e contagem de operações introduziria uma regra nova. Os dossiês de upload/trim ainda apresentam diferenças na política descrita. | Speed reutiliza a quota acumulada existente do proprietário com bytes reais do output; não debita operações diárias. Harmonizar a descrição entre casos de uso sem alterar os limites do código. | Integração implementada; harmonização documental e decisão de quota diária pendentes. |
| 005, 024; RN12; Q1 | Trim possui regras próprias de duração mínima/máxima. | Copiar a estrutura do trim poderia importar limites não decididos para speed. | Exigir tempos válidos e dentro da duração real, sem acrescentar limites específicos do trim. | Decisão de âmbito mantida; limites adicionais de speed por decidir. |
| 008, 009, 013, 016, 038; RN9 | A rota devolve 202 e o resultado bem-sucedido gera project-op/add-video. Speed não usa um ciclo persistente de jobs com progresso/cancelamento/erro terminal na UI. | Equiparar aceitação a conclusão ou herdar capacidades de jobs de outros fluxos documentaria funcionalidades inexistentes. | Confirmar submissão e atualizar a biblioteca no sucesso. Manter progresso, cancelamento pós-submissão e alerta de falha final como futuros. Cancelar no diálogo apenas desiste antes de enviar. | MVP implementado; evoluções adiadas. |
| 024; EX11 | Projects valida parâmetros sem medir o ficheiro; o worker mede a duração real com ffprobe. | Um pedido direto pode receber 202 e falhar mais tarde por ultrapassar a duração. | Descrever validação distribuída e distinguir erro de submissão de falha assíncrona; não prometer recusa síncrona universal. | Implementado; comunicação terminal à UI pendente. |
| 028, 029, 035; FA7 | Autorização distingue proprietário, partilha read/edit e versão atual do projeto. | Aceitar leitura como edição ou usar a quota do chamador numa partilha mudaria as regras existentes. | Exigir edição e versão válida na submissão; autoria pelo callerId e armazenamento contabilizado no ownerId. | Mecanismos reutilizados; matriz E2E completa por validar. |
| 019, 031, 034; EX4, EX6; Q8 | O upload do output precede a reserva em Projects; MongoDB, storage e RabbitMQ não formam uma transação única. | Pode haver output não associado; um resultado status error é apenas registado. Uma falha de commit após associação não pode libertar os bytes do vídeo. | No ramo de sucesso, reservar bytes reais, associar e confirmar; em associação falhada, tentar DELETE/release após verificar ausência de associação. Manter contabilização de vídeo associado. Não prometer limpeza remota em status error. | Rollback controlado implementado; recuperação distribuída/recolha de órfãos pendentes. |
| 032; EX13 | Existe verificação de associação prévia e contabilização por newVideoId. | Idempotência sequencial não prova entrega exatamente uma vez nem todos os cenários concorrentes. | Manter a garantia e a evidência do cenário sequencial; registar concorrência e falhas ambíguas em Q8. | Cobertura sequencial histórica; validação concorrente pendente. |
| 020, 037; DQ-002 | Upload, trim e biblioteca já existem; FFmpeg recodifica o output. | Reutilizar padrões não deve sobrescrever o original nem implicar cópia binária dos trechos a 1x ou prova de regressão total. | Preservar o original e a escala temporal dos trechos a 1x; manter regressões explícitas e distinguir cobertura parcial de garantia geral. | Implementado; ensaios abrangentes ainda necessários. |

Os números abreviados da primeira coluna referem-se a REQ-VID-SPEED com o respetivo sufixo de três algarismos.

#### 4.4.3 Assunções, valores e condições de medição

A tabela distingue regras existentes, características da implementação, tolerâncias dos ensaios e metas ainda não aprovadas. Não acrescenta limites de desempenho ou de negócio.

| Valor / propriedade | Requisitos / origem | Base / assunção | Condição de medição / verificação | Estado da validação |
| --- | --- | --- | --- | --- |
| 0,5x, 1x e 2x | 003, 010, 012; RN1 | Fatores permitidos pelo UC, não metas de desempenho. | Usar os casos A–E da secção 4.6; medir vídeo e áudio com ffprobe e verificar posição/ordem dos segmentos. Rejeitar 0,25x, 4x e valores não numéricos. | Evidência sintética histórica; matriz de conteúdos reais pendente. |
| Free: 1 000 000 000 bytes; Premium: 5 000 000 000 bytes acumulados | 019, 031; RN6 | Limites existentes em projects/utils/videoQuota.js, não uma regra nova de speed. | Para output de tamanho S, ensaiar espaço disponível S-1, S e S+1; verificar used, estado da reserva, associação e versão. Usar bytes reais do output e testar ambos os planos. | Testes isolados históricos; fronteiras com serviços reais por validar. |
| Tolerância de 0,2 s nos ensaios sintéticos | 010, 012, 017, 030; A4, A6 | Tolerância de videoSpeedWorker/test_worker.py; não uma garantia universal de precisão. | Gerar os conteúdos de teste, calcular a duração esperada e inspecionar duração total e streams com ffprobe, quando existentes. Registar taxa de fotogramas, timestamps, duração e configuração dos intervalos. | Evidência histórica limitada aos conteúdos testados; tolerância geral por decidir. |
| Slider: 0,1 s; campos: step any | 002, 024; Q5 | Característica atual da seleção, não precisão garantida de codificação. | Observar valores enviados ao mover o slider e ao introduzir decimais nos campos; comparar com os parâmetros recebidos. Não inferir precisão de fotograma deste passo. | Código inspecionado; ensaio completo da UI pendente. |
| Latência de aceitação, tempo de processamento e concorrência | 036; Q7 | Não há p95, timeout funcional ou capacidade aprovados para speed. | Definir hardware, rede, resolução, codec, duração, número de intervalos, carga e amostra; medir envio→202, espera e execução separadamente. Aprovar métricas e limiares antes de avaliar conformidade quantitativa. | Metas e benchmark pendentes; não usar metas do trim por analogia. |
| Frequência/precisão de progresso e notificação terminal | 013, 038; Q3, Q7 | Funcionalidades futuras, sem frequência aprovada; não há percentagem real na UI atual. | Após definir o contrato de estados e implementar a evolução, correlacionar eventos de espera/execução/sucesso/falha com o pedido e observar a interface. | Não implementado nem ensaiado. |
| Integridade, acesso, limpeza e regressões | 020, 021, 034, 035, 037 | Invariantes verificáveis, sem necessidade de inventar alvos numéricos. | Aplicar as condições específicas de 4.1.2; registar versões dos serviços, dados de entrada, permissões e falha injetada. Distinguir testes isolados de ensaios Docker/browser. | Cobertura histórica parcial; falhas persistentes e regressão completa pendentes. |

Os sufixos de requisitos nesta tabela usam o prefixo REQ-VID-SPEED. Os procedimentos descritos são condições propostas de verificação, não ensaios executados nesta revisão. As contagens de testes e a confirmação manual mantêm-se como evidência histórica na secção 4.5.

### 4.5 Estado de implementação e validação

**Esta revisão v3.0 não reexecuta as suites, o build nem a stack Docker.** As verificações desta edição limitam-se à consistência documental e à leitura do código relevante.

**Leitura da evidência:** implementado significa que o mecanismo foi identificado no código; testado significa que existe um ensaio identificado. Os resultados abaixo são os registados durante a implementação do commit 58d4414, não uma reexecução de toda a stack nesta revisão documental. Os testes isolados não comprovam por si só comportamento sob carga ou todas as falhas reais.

| Requisitos | Estado observado | Evidência / validação em falta |
| --- | --- | --- |
| REQ-VID-SPEED-001, REQ-VID-SPEED-002, REQ-VID-SPEED-003, REQ-VID-SPEED-004, REQ-VID-SPEED-007, REQ-VID-SPEED-026, REQ-VID-SPEED-027 | UI implementada; percurso positivo comunicado pelo utilizador. | SpeedVideoDialog contém seleção, lista, edição e remoção. Os 28 testes frontend cobrem a validação, não cliques/renderização do diálogo; não se afirma que cada controlo tenha sido ensaiado manualmente. |
| REQ-VID-SPEED-005, REQ-VID-SPEED-006, REQ-VID-SPEED-022, REQ-VID-SPEED-023, REQ-VID-SPEED-024, REQ-VID-SPEED-025 | Implementados; cobertos parcialmente em camadas diferentes. | Validação frontend, API e worker; duração real é verificada no worker. Os testes cobrem limites inválidos, finitude, sobreposição, adjacência e duração; não constituem uma medição universal de precisão temporal. |
| REQ-VID-SPEED-008, REQ-VID-SPEED-009, REQ-VID-SPEED-014, REQ-VID-SPEED-015, REQ-VID-SPEED-030 | Implementados; contratos automatizados e percurso real positivo comunicados. | Testes Projects/API Gateway/worker e teste de upload/Modificar velocidade na stack Docker. A aceitação HTTP é 202; o resultado aparece após associação. |
| REQ-VID-SPEED-010, REQ-VID-SPEED-011, REQ-VID-SPEED-012, REQ-VID-SPEED-017, REQ-VID-SPEED-018, REQ-VID-SPEED-020 | Implementados; testes sintéticos com FFmpeg e ffprobe. | Os 18 testes do worker incluem durações, vários intervalos/ordem temporal, 1x, áudio/ausência de áudio, validação e hash do original. A evidência aplica-se aos conteúdos de teste, não a todos os vídeos possíveis. |
| REQ-VID-SPEED-019, REQ-VID-SPEED-031, REQ-VID-SPEED-032 | Implementados; testes isolados com utilitário real de quota e MongoDB simulado. | A suite Projects de 66 testes cobre espaço suficiente/insuficiente, igualdade com limites Free/Premium, bytes do output, rollback, repetição sequencial e falha de commit. Não valida concorrência real nem reconcilia dados históricos. |
| REQ-VID-SPEED-021, REQ-VID-SPEED-034 | Mecanismos de integridade e limpeza presentes, com âmbito limitado. | Limpeza local no worker; tentativa de limpeza remota e release em Projects no ramo de sucesso cuja associação falha. Uma falha simulada de DELETE não impede release. O ramo status error apenas regista a falha; não há limpeza remota geral nem recolha de órfãos demonstrada. |
| REQ-VID-SPEED-028, REQ-VID-SPEED-029, REQ-VID-SPEED-033 | Implementados; testes backend e mensagens frontend identificados. | Cobertura de autenticação, partilha de leitura/edição/revogada e versão no backend. Falta ensaio manual completo dos erros na interface. |
| REQ-VID-SPEED-035, REQ-VID-SPEED-036, REQ-VID-SPEED-037 | Arquitetura e controlos reutilizados; validação parcial. | Gateway e worker verificam contratos internos; testes de regressão de trim e upload; TypeScript/build/sintaxe passaram nas verificações anteriores. Não há benchmark de carga nem prova de regressão completa de imagens e partilhas em todos os serviços. |
| REQ-VID-SPEED-013, REQ-VID-SPEED-016, REQ-VID-SPEED-038 | Especificados como evolução futura; não implementados. | Não há acompanhamento persistente/progresso, cancelamento pós-submissão ou notificação terminal de erro específica de speed. Não os contabilizar como funcionalidades validadas do MVP. |

**Ensaios e fontes de evidência**

| Fonte | Resultado registado | Alcance |
| --- | --- | --- |
| projects/test/video-speed.test.js | 66/66 passaram após a correção da quota. | Router real, dependências externas simuladas, funções reais de quota com modelos MongoDB simulados; regressão de upload com MP4/H.264 sintético e FFmpeg/ffprobe. |
| apiGateway/test/video-speed.test.js | 6/6 passaram. | Proxy HTTP, autenticação, headers, partilha e erros; Projects simulado. |
| frontend/test/video-speed.test.mjs | 28/28 passaram. | Parsing e validação dos intervalos; não é teste automatizado da UI no browser. |
| videoSpeedWorker/test_worker.py | 18/18 passaram. | FFmpeg/ffprobe reais com vídeos sintéticos; acesso HTTP e RabbitMQ simulados nos testes de contrato. |
| Teste manual com Docker | Utilizador confirmou upload e Modificar velocidade funcionais, incluindo nova tentativa após a correção da quota. | Confirma o percurso positivo real comunicado. Não identifica todos os fatores, intervalos, codecs e cenários negativos executados; não prova o limite de quota com storage real. |
| Revisões e compilação anteriores | TypeScript, build, sintaxe e verificações de whitespace passaram. | Evidência de compilabilidade na revisão da implementação, não substitui teste funcional. |

A falha inicial de upload observada na integração foi atribuída a uma imagem antiga de img_storage sem as rotas de vídeo; o utilizador confirmou sucesso após reconstrução. É uma ocorrência de configuração/deployment, não uma funcionalidade implementada por este dossiê.

**Validação ainda necessária:** ensaiar manualmente todos os fatores e vários intervalos, vídeo sem áudio, partilhas com leitura/edição, falhas assíncronas, limites de armazenamento reais, diferentes taxas de fotogramas/timestamps e comportamentos perante indisponibilidade. Para acompanhar a versão atual do main, reexecutar as suites e o E2E; não se presume que os resultados históricos substituem essa validação.

### 4.6 Exemplos verificáveis de duração

Para um vídeo com duração D, intervalos não sobrepostos de comprimentos L_i e fatores s_i:

**D_resultado = D - soma(L_i) + soma(L_i / s_i)**

A fórmula desconta a duração original dos intervalos e soma as durações transformadas. A ordem é sempre a do vídeo de origem. A duração em bytes não se deduz desta fórmula: a quota usa o tamanho efetivo do ficheiro codificado.

| Caso | Entrada e configuração | Duração esperada |
| --- | --- | --- |
| A | 10 s; [2,4] a 2x. | 10 - 2 + 1 = 9 s. |
| B | 10 s; [2,4] a 0,5x. | 10 - 2 + 4 = 12 s. |
| C | 10 s; [2,4] a 2x e [6,8] a 0,5x. | 10 - 4 + 1 + 4 = 11 s. |
| D | 10 s; [2,4] a 1x. | 10 s. |
| E | 10 s; [1,3] a 2x e [5,7] a 0,5x. | 11 s; também é necessário verificar a posição e ordem de ambos os trechos. |

Os testes sintéticos do worker usam tolerância de 0,2 s nas durações total, de vídeo e de áudio, quando existente. Esta é a tolerância desses ensaios, não uma garantia aprovada para todos os conteúdos ou uma precisão de seleção. A verificação deve incluir os codecs e a existência/ausência de áudio; a duração total isolada não prova que os intervalos corretos foram transformados.

## 5. Lista de verificação documental

- [x] Os IDs REQ-VID-SPEED-001 a REQ-VID-SPEED-021 da baseline foram preservados.
- [x] Requisitos funcionais e de qualidade estão separados, com origem, evolução e critérios de aceitação.
- [x] Novos requisitos completam validação, edição/remoção, permissões, versionamento, quota e consistência.
- [x] A matriz referencia todos os requisitos, incluindo os explicitamente adiados.
- [x] Quota diária está separada de armazenamento; não se importam limites específicos de trim.
- [x] Não se declaram progresso, cancelamento pós-submissão, preview transformado ou alerta terminal de erro como implementados.
- [x] Evidência automática, teste manual comunicado e validações pendentes estão distinguidos.
- [x] Grupo PL3-G2 confirmado no relatório existente.
- [x] Versão v3.0 identifica a baseline v2.0 e regista original → refinado com justificação.
- [x] Estado do Exercício 3 separado de Evolução histórica e de implementação/validação.
- [x] Conflitos com os mecanismos existentes e decisões pendentes reunidos em 4.4.2.
- [x] Condições de medição explicitadas sem inventar metas; valores e assunções classificados em 4.4.3.
- [x] EX6 distingue status error de rollback de um resultado de sucesso não associado.
- [ ] Obter revisão final do autor/equipa.
- [ ] Resolver as questões de negócio em aberto antes de as converter em obrigações ativas.
- [ ] Integrar o conteúdo aprovado no relatório Typst e validar a composição do documento final.
