#import "../template.typ": *

// 5.1 e 5.2 em páginas na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Especificação de Requisitos do Sistema (ERS)

#orientacao[
  Catálogo único dos requisitos de todas as funcionalidades de vídeo, ordenado por ID. A coluna *Origem* indica o
  caso de uso e o elemento de onde vem cada requisito (e.g., `UC-VID-002, passo 3`, `UC-VID-002/RN1`); um requisito comum a vários casos de uso (e.g.,
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


    [REQ-VID-UPL-001],
    [O sistema deve apresentar a opção de selecionar um ficheiro ao utilizador que escolhe *Carregar vídeo* num projeto.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 1; Trigger],
    [Disponibiliza a entrada do fluxo.],
    [Dado um projeto acessível, quando o utilizador escolhe *Carregar vídeo*, então a opção de selecionar um ficheiro é apresentada.],

    [REQ-VID-UPL-002],
    [O sistema deve permitir ao utilizador selecionar um único ficheiro através do seletor do navegador para o carregar no projeto existente.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 2],
    [Limita cada envio a um ficheiro.],
    [Dado o carregamento aberto, quando o utilizador seleciona um ficheiro no seletor, então esse ficheiro fica selecionado para o envio.],

    [REQ-VID-UPL-003],
    [O sistema deve apresentar o nome do ficheiro selecionado antes da confirmação do envio.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 2],
    [Permite identificar o ficheiro antes de enviar.],
    [Dado um ficheiro selecionado, então o nome apresentado coincide com o nome desse ficheiro.],

    [REQ-VID-UPL-004],
    [O sistema deve apresentar o tamanho do ficheiro selecionado antes da confirmação do envio.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 2],
    [Permite conferir a dimensão antes de enviar.],
    [Dado um ficheiro selecionado, então o tamanho apresentado coincide com o tamanho desse ficheiro.],

    [REQ-VID-UPL-005],
    [O sistema deve recusar, na validação preliminar, um ficheiro cujo tipo/formato declarado não corresponda a MP4.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 2; Exceção: tipo/formato declarado],
    [Evita transferências evidentemente incompatíveis.],
    [Dado um ficheiro declarado com tipo/formato diferente de MP4, quando é selecionado, então é recusado antes do envio.],

    [REQ-VID-UPL-006],
    [O sistema deve permitir ao utilizador confirmar o envio do ficheiro selecionado.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 3],
    [Exige confirmação explícita do utilizador.],
    [Dado um ficheiro selecionado que passou a validação preliminar, então o utilizador consegue confirmar o envio.],

    [REQ-VID-UPL-007],
    [O sistema deve recusar o envio quando a sessão do utilizador não estiver válida na confirmação.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 3; Exceção: sessão ou autorização; RN1; RNG-01],
    [Protege pedidos após expiração da sessão.],
    [Dada uma sessão expirada, quando o utilizador confirma o envio, então o pedido é recusado.],

    [REQ-VID-UPL-008],
    [O sistema deve recusar o envio quando o utilizador não tiver permissão de edição no projeto na confirmação.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 3; Exceção: sessão ou autorização; RN1; RNG-01],
    [Respeita permissões em projetos próprios e partilhados.],
    [Dado um utilizador sem permissão de edição, quando confirma o envio, então o pedido é recusado.],

    [REQ-VID-UPL-009],
    [O sistema deve realizar, após a receção do ficheiro, a validação definitiva com base no seu conteúdo real, sem confiar apenas na extensão ou no tipo/formato declarado.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 5; RN2],
    [Impede confiar apenas em metadados declarados.],
    [Dado um ficheiro declarado como MP4 mas com conteúdo diferente, quando é recebido, então a validação definitiva avalia o conteúdo real.],

    [REQ-VID-UPL-010],
    [O sistema deve aceitar, na validação definitiva após a receção do ficheiro, apenas ficheiros cujo conteúdo corresponda a um vídeo MP4 válido.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 5; Exceção: conteúdo inválido; RN2; RNG-02],
    [Concretiza a restrição de formato de RN2.],
    [Dado um ficheiro renomeado para #raw(".mp4") sem conteúdo MP4 válido, quando termina a receção e ocorre a validação definitiva, então o ficheiro é recusado e não é associado.],

    [REQ-VID-UPL-011],
    [O sistema deve aceitar, na validação definitiva após a receção do ficheiro, apenas ficheiros cujo codec de vídeo seja H.264.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 5; Exceção: codec inválido; RN2; RNG-02],
    [Concretiza a restrição de codec de RN2.],
    [Dado um MP4 com codec de vídeo diferente de H.264, quando ocorre a validação definitiva, então o ficheiro é recusado e não é associado.],

    [REQ-VID-UPL-012],
    [O sistema deve recusar ficheiros com tamanho superior a 1 GB (1 000 000 000 bytes) para utilizadores do plano Free.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 3; Exceção: limite de tamanho; RN2],
    [Aplica o limite Free de RN2.],
    [Dado um utilizador Free, quando confirma um ficheiro acima de 1 000 000 000 bytes, então o envio é recusado; com esse tamanho exato, não é recusado por tamanho.],

    [REQ-VID-UPL-013],
    [O sistema deve recusar ficheiros com tamanho superior a 5 GB (5 000 000 000 bytes) para utilizadores do plano Premium.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 3; Exceção: limite de tamanho; RN2],
    [Aplica o limite Premium de RN2.],
    [Dado um utilizador Premium, quando confirma um ficheiro acima de 5 000 000 000 bytes, então o envio é recusado; com esse tamanho exato, não é recusado por tamanho.],

    [REQ-VID-UPL-014],
    [O sistema deve iniciar o envio do ficheiro após a confirmação e as verificações de autorização e tamanho, sem depender da validação definitiva do conteúdo.],
    [#must],
    [ALT],
    [UC-VID-001 — Passos 3–4],
    [Ordena confirmação, verificações e transferência.],
    [Dado um ficheiro que passou as verificações de autorização e tamanho, quando o utilizador confirma, então o envio é iniciado antes da validação definitiva.],

    [REQ-VID-UPL-015],
    [O sistema deve indicar ao utilizador que o envio está em curso.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 4],
    [Torna visível uma transferência em curso.],
    [Dado um envio iniciado e ainda não concluído, então a interface indica que a operação está em curso.],

    [REQ-VID-UPL-016],
    [O sistema deve associar ao utilizador o vídeo apenas após a receção, validação definitiva e armazenamento bem-sucedidos.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 6; RN3; Garantia de Sucesso],
    [Garante associação ao utilizador após sucesso.],
    [Dado um vídeo recebido, validado e armazenado com sucesso, então fica associado ao utilizador que o carregou; se alguma destas operações falhar, não fica associado.],

    [REQ-VID-UPL-017],
    [O sistema deve associar ao projeto existente uma referência persistente ao vídeo apenas após a receção, validação definitiva e armazenamento bem-sucedidos.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 6; RN3; Garantia de Sucesso],
    [Fornece referência persistente no projeto.],
    [Dado um vídeo recebido, validado e armazenado com sucesso, então o projeto mantém uma referência que permite aos serviços de processamento obter o ficheiro; se alguma destas operações falhar, a referência não fica associada.],

    [REQ-VID-UPL-018],
    [O sistema deve confirmar ao utilizador a conclusão do carregamento apenas após a transferência, validação definitiva, armazenamento e associação bem-sucedidos.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 7],
    [Impede uma confirmação prematura.],
    [Concluídas com sucesso as quatro operações, então o utilizador recebe a confirmação; se alguma falhar, não recebe confirmação de sucesso.],

    [REQ-VID-UPL-019],
    [O sistema deve apresentar ao utilizador a identificação do vídeo associado ao projeto após a conclusão bem-sucedida do carregamento.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 7; Garantia de Sucesso],
    [Torna visível o resultado do upload.],
    [Dado um carregamento concluído com sucesso, então o utilizador vê a identificação do vídeo associado ao projeto, sem necessidade de o reproduzir.],

    [REQ-VID-UPL-021],
    [O sistema deve informar o utilizador quando recusar um ficheiro por tipo/formato declarado diferente de MP4.],
    [#must],
    [ALT],
    [UC-VID-001 — Exceção: tipo/formato declarado],
    [Explica a recusa preliminar.],
    [Dado um ficheiro declarado como não MP4, quando é selecionado, então o utilizador é informado da recusa.],

    [REQ-VID-UPL-022],
    [O sistema deve informar o utilizador quando recusar um envio por exceder o limite de tamanho do seu plano.],
    [#must],
    [ALT],
    [UC-VID-001 — Exceção: limite de tamanho],
    [Explica a recusa por dimensão.],
    [Dado um ficheiro acima do limite do plano, quando o envio é confirmado, então o utilizador é informado da recusa por tamanho.],

    [REQ-VID-UPL-023],
    [O sistema deve informar o utilizador quando recusar o pedido por sessão expirada.],
    [#must],
    [ALT],
    [UC-VID-001 — Exceção: sessão ou autorização],
    [Orienta o utilizador após expiração.],
    [Dada uma sessão expirada, quando o envio é confirmado, então o utilizador é informado de que necessita de iniciar sessão novamente.],

    [REQ-VID-UPL-024],
    [O sistema deve informar o utilizador quando recusar o pedido por falta de permissão de edição no projeto.],
    [#must],
    [ALT],
    [UC-VID-001 — Exceção: sessão ou autorização],
    [Orienta o utilizador sem acesso de edição.],
    [Dado um utilizador sem permissão de edição, quando confirma o envio, então é informado de que necessita de obter acesso ao projeto.],

    [REQ-VID-UPL-025],
    [O sistema deve informar o utilizador de que o carregamento não foi concluído quando a transferência do ficheiro for interrompida.],
    [#must],
    [NOVO],
    [UC-VID-001 — Exceção: interrupção do envio],
    [Separa a falha de transferência das restantes exceções do antigo requisito composto.],
    [Dada uma interrupção durante a transferência, quando o pedido termina sem sucesso, então a interface informa que o carregamento não foi concluído.],

    [REQ-VID-UPL-026],
    [O sistema deve informar o utilizador quando recusar, na validação definitiva após a receção, um ficheiro cujo conteúdo não seja um vídeo MP4 válido.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 5; Exceção: conteúdo inválido],
    [Explica a recusa de conteúdo inválido.],
    [Dado um ficheiro cujo conteúdo não seja um vídeo MP4 válido, quando é validado no Passo 5 após a receção, então o utilizador é informado da recusa e o vídeo não fica associado nem disponível.],

    [REQ-VID-UPL-027],
    [O sistema deve informar o utilizador quando recusar, na validação definitiva após a receção, um ficheiro cujo codec de vídeo não seja H.264.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 5; Exceção: codec inválido],
    [Explica a recusa de codec não suportado.],
    [Dado um vídeo MP4 com codec de vídeo diferente de H.264, quando é validado no Passo 5 após a receção, então o utilizador é informado da recusa e o vídeo não fica associado nem disponível.],

    [REQ-VID-UPL-028],
    [O sistema deve, no fluxo normal do frontend, recusar o novo carregamento na pré-validação, antes de iniciar o pedido de transferência, quando já existir no mesmo projeto um vídeo associado com o mesmo nome completo do ficheiro selecionado, e informar o utilizador de que precisa de alterar o nome.],
    [#must],
    [NOVO],
    [UC-VID-001 — Passo 3; Exceção: nome repetido; RN6],
    [Evita duplicar nomes no mesmo projeto.],
    [Dado um projeto com um vídeo associado chamado #raw("video.mp4"), quando o utilizador confirma na interface o carregamento de outro ficheiro chamado #raw("video.mp4"), então o pedido de upload não é iniciado, é apresentada a indicação para alterar o nome e o vídeo existente mantém-se associado; noutro projeto, o mesmo nome não causa esta recusa.],

    [REQ-VID-UPL-029],
    [O sistema deve indicar o vídeo como disponível para processamento apenas após a transferência, validação definitiva, armazenamento e associação bem-sucedidos.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 7; RN4; Garantia Mínima],
    [Concretiza a integridade de RN4 e a garantia mínima.],
    [Dada uma falha na transferência, validação, armazenamento ou associação, quando o projeto é consultado, então o vídeo não é indicado como disponível para processamento; após sucesso em todas as etapas, é indicado como disponível.],

    [REQ-VID-UPL-036],
    [O sistema deve permitir ao utilizador desistir antes de confirmar o envio.],
    [#must],
    [ALT],
    [UC-VID-001 — FA2],
    [Renumerado porque o ID 020 está reservado para arrastar e largar.],
    [Dado um ficheiro selecionado, quando o utilizador desiste antes da confirmação, então o envio não é iniciado.],

    [REQ-VID-UPL-037],
    [O sistema deve informar o utilizador de que o carregamento falhou quando o armazenamento do vídeo falhar.],
    [#must],
    [NOVO],
    [UC-VID-001 — Exceção: falha no armazenamento],
    [Separa a falha de armazenamento do antigo requisito 025.],
    [Dada uma falha do SeaweedFS durante o armazenamento, quando o pedido termina, então a interface informa que o carregamento falhou.],

    [REQ-VID-UPL-038],
    [O sistema deve informar o utilizador de que o carregamento não foi concluído quando a associação do vídeo ao projeto falhar.],
    [#must],
    [NOVO],
    [UC-VID-001 — Exceção: falha na associação],
    [Separa a falha de associação do antigo requisito 025.],
    [Dada uma falha na associação ao projeto, quando o pedido termina, então a interface informa que o carregamento não foi concluído.],

    [REQ-VID-UPL-039],
    [O sistema deve recusar o envio quando a versão do projeto apresentada ao utilizador estiver desatualizada.],
    [#must],
    [ALT],
    [UC-VID-001 — Passo 3; Exceção: versão desatualizada],
    [Separa a deteção do conflito de versão.],
    [Dada uma versão desatualizada do projeto, quando o utilizador confirma o envio, então o pedido é recusado e não é associado um novo vídeo.],

    [REQ-VID-UPL-040],
    [O sistema deve atualizar os dados do projeto apresentados ao utilizador após recusar o envio por versão desatualizada.],
    [#must],
    [ALT],
    [UC-VID-001 — Exceção: versão desatualizada],
    [Separa a atualização dos dados após o conflito.],
    [Dada a recusa por versão desatualizada, quando o projeto é novamente apresentado, então os seus dados refletem a versão atual.],

    [REQ-VID-UPL-041],
    [O sistema deve informar o utilizador, após a recusa por versão desatualizada, de que deve repetir a operação.],
    [#must],
    [ALT],
    [UC-VID-001 — Exceção: versão desatualizada],
    [Separa a instrução ao utilizador da atualização dos dados.],
    [Dada a recusa por versão desatualizada, então a interface indica ao utilizador que deve repetir o carregamento.],

    [REQ-VID-TRIM-001], [O sistema deve carregar a interface de recorte de vídeo, apresentando o reprodutor multimédia, a linha temporal com a duração total do vídeo e os seletores de início e fim (t_in e t_out).], [#must], [NOVO], [UC-VID-002, Passo 1], [Interface primordial de interação para parametrização do intervalo a recortar.], [Dado um vídeo válido na biblioteca, quando o utilizador seleciona a ferramenta de recorte, então a interface é carregada apresentando o reprodutor HTML5, a linha temporal e os seletores t_in e t_out.],

    [REQ-VID-TRIM-002], [O sistema deve atualizar dinamicamente a área selecionada na linha temporal e recalcular a duração resultante (t{out - t{in) em tempo real à medida que os marcadores temporais são manipulados.], [#must], [NOVO], [UC-VID-002, Passo 2; RN3], [Fornece feedback visual contínuo e garante controlo temporal exato antes da submissão.], [Dado que os seletores temporais são deslocados na linha temporal, quando o utilizador altera a posição de t_in ou t_out, então a área destacada e o campo de duração resultante são atualizados instantaneamente com precisão de centésimos de segundo.],

    [REQ-VID-TRIM-003], [O sistema deve permitir ao utilizador reproduzir localmente no navegador exclusivamente o segmento compreendido entre t_in e t_out antes de confirmar a operação, sem consumir quota de operações nem gerar pedidos de processamento ao servidor.], [#should], [NOVO], [UC-VID-002, FA1], [Reduz pedidos incorretos ao backend e poupa recursos computacionais e quotas do utilizador.], [Dado um intervalo intervalo t_in–t_out parametrizado, quando o utilizador clica em "Pré-visualizar Excerto", então o reprodutor local executa apenas esse intervalo sem emitir chamadas de rede ao worker nem debitar quota diária.],

    [REQ-VID-TRIM-004], [O sistema deve validar os instantes temporais submetidos, assegurando que 0 ≤ t_in < t_out ≤ duração do vídeo e que a duração mínima do excerto (t_out − t_in) é igual ou superior a 1.0 segundo.], [#must], [NOVO], [UC-VID-002, Passo 3; Exceção 1; RN3], [Impede o enfileiramento de operações temporalmente inconsistentes ou nulas.], [Dado um pedido de recorte com t_in ≥ t_out ou (t{out - t{in) < 1.0 s, quando o utilizador submete a operação, então a submissão é bloqueada com mensagem de erro explícita e nenhuma quota é deduzida.],

    [REQ-VID-TRIM-005], [O sistema deve verificar o saldo da quota diária de operações do utilizador do perfil #raw("free") antes de permitir a submissão, impedindo o enfileiramento se o limite de 5 operações diárias gratuitas (#raw("FREE_DAILY_OP = 5")) tiver sido atingido.], [#must], [ALT], [UC-VID-002, Passo 3; Exceção 3; RN1], [Assegura a aplicação das regras do modelo SaaS do PictuRAS para o nível gratuito.], [Dado um utilizador #raw("free") com saldo de 0 operações no dia corrente, quando tenta submeter um recorte, então a operação é impedida com mensagem de quota esgotada e convite a upgrade para #raw("premium").],

    [REQ-VID-TRIM-006], [O sistema deve validar a duração máxima do excerto (t_out − t_in) em função do perfil do utilizador, rejeitando pedidos com duração superior a 180 segundos para o perfil #raw("free") ou superior a 60 minutos para o perfil #raw("premium").], [#must], [NOVO], [UC-VID-002, Passo 3; Exceção 2; RN2], [Limita o consumo excessivo de recursos de computação e diferencia o valor do plano pago.], [Dado um utilizador do perfil #raw("free") que submete um excerto de 181 segundos, quando clica em confirmar, então o sistema recusa o pedido indicando o limite de 3 minutos para contas gratuitas.],

    [REQ-VID-TRIM-007], [O sistema deve debitar provisoriamente 1 operação da quota diária do utilizador do perfil #raw("free") no momento exato em que a tarefa de recorte é aceite e enfileirada no backend.], [#must], [ALT], [UC-VID-002, Passo 4; RN1], [Previne ataques de esgotamento de workers através de submissões simultâneas concorrentes acima do saldo.], [Dado um utilizador #raw("free") com saldo de 5 operações, quando submete uma tarefa válida de recorte, então o seu saldo diário é imediatamente decrementado para 4 operações antes do arranque do processamento.],

    [REQ-VID-TRIM-008], [O sistema deve submeter cada tarefa de recorte validada à fila assíncrona de processamento de vídeo.], [#must], [NOVO], [UC-VID-002, Passo 4, Passo 5; DQ-001], [Desacopla a requisição HTTP da execução pesada de transcodificação de vídeo.], [Dado um pedido de recorte validado, quando o sistema aceita a submissão, então existe exatamente uma tarefa correspondente na fila assíncrona de processamento de vídeo.],

    [REQ-VID-TRIM-010], [O sistema deve extrair e recodificar os fotogramas e fluxos de áudio correspondentes estritamente ao intervalo intervalo t_in–t_out do vídeo de entrada, preservando a taxa de fotogramas e a sincronização áudio/vídeo no ficheiro resultante.], [#must], [NOVO], [UC-VID-002, Passo 6; Pós-condição de sucesso], [Executa o processamento nuclear de recorte com exatidão temporal e integridade de mídia.], [Dado um vídeo válido de entrada, quando o worker conclui o recorte, então o vídeo gerado contém unicamente os fotogramas entre t_in e t_out com desfasamento de áudio/vídeo nulo.],

    [REQ-VID-TRIM-011], [O sistema deve disponibilizar ao utilizador com perfil #raw("premium") a opção de "Recorte Rápido" (stream copy sem recodificação), executando o corte instantaneamente quando os pontos selecionados coincidirem com fotogramas-chave (keyframes).], [#could], [NOVO], [UC-VID-002, FA2], [Reduz drasticamente o tempo de processamento para subscritores pagos em cenários compatíveis.], [Dado um utilizador #raw("premium") com a opção "Recorte Rápido" ativada, quando o corte é submetido em keyframes viáveis, então o ficheiro é gerado por cópia direta de fluxos em poucos segundos.],

    [REQ-VID-TRIM-014], [O sistema deve registar o vídeo recortado na biblioteca após a conclusão e validação do ficheiro de saída.], [#must], [NOVO], [UC-VID-002, Passo 7, Passo 8; Pós-condição de sucesso], [Entrega o valor da operação ao utilizador, permitindo a reutilização ou exportação do vídeo gerado.], [Dado um ficheiro de saída concluído e validado, quando a conclusão da tarefa é registada, então o vídeo recortado consta da biblioteca do projeto; não há registo antes da validação.],

    [REQ-VID-TRIM-015], [O sistema deve assegurar a persistência e continuidade da tarefa assíncrona mesmo que o utilizador encerre a sessão ou feche o navegador, emitindo uma notificação na plataforma aquando da conclusão.], [#should], [NOVO], [UC-VID-002, FA3], [Garante que operações demoradas de vídeo não são abortadas por eventos acidentais no frontend.], [Dado uma tarefa em processamento no worker, quando o utilizador fecha o browser e reabre a aplicação após a conclusão, então visualiza a notificação de sucesso e o vídeo gravado na sua biblioteca.],

    [REQ-VID-TRIM-016], [O sistema deve terminar a tarefa com estado "Falhada" quando detetar um fluxo de entrada corrompido ou incompatível durante o processamento.], [#must], [NOVO], [UC-VID-002, Exceção 4a; Pós-condição garantia mínima; RN1], [Garante tratamento de falhas sem penalização indevida da quota do utilizador.], [Dado um fluxo de entrada corrompido ou incompatível detetado durante o processamento, quando o worker comunica o erro, então a tarefa passa ao estado "Falhada".],

    [REQ-VID-TRIM-019], [O sistema deve bloquear o acesso a ferramentas e operações de processamento de vídeo a utilizadores não autenticados (#raw("anonymous")), exibindo mensagem de autenticação obrigatória e redirecionando para registo ou login.], [#must], [NOVO], [UC-VID-002, Pré-condições; FA4; RN7], [Protege os recursos dispendiosos de processamento de vídeo contra abusos por tráfego não identificado.], [Dado um utilizador sem sessão iniciada, quando tenta aceder ao endpoint ou interface de recorte de vídeo, então o acesso é barrado com aviso de funcionalidade restrita e link para criação de conta gratuita.],

    [REQ-VID-TRIM-020], [O sistema deve gerar um registo de auditoria para cada tarefa de recorte finalizada (com sucesso, falha ou cancelamento), contendo o identificador do utilizador, Job ID, parâmetros t_in/t_out, tempo de execução e estado final.], [#should], [NOVO], [UC-VID-002, Pós-condição de sucesso; DQ-003], [Permite rastreabilidade operacional, resolução de incidentes e contabilidade de uso na plataforma.], [Dado o término de uma tarefa de vídeo, quando o registo de log é persistido, então constam gravados o ID de utilizador, Job ID, carimbos temporais, parâmetros e código de terminação.],

    [REQ-VID-TRIM-021], [O sistema deve recusar a persistência do vídeo resultante quando o tamanho acumulado da biblioteca ultrapassaria 1 000 000 000 bytes no plano #raw("free") ou 5 000 000 000 bytes no plano #raw("premium").], [#must], [ALT], [UC-VID-002, Passo 3, Passo 7; Exceção 4b; RN6], [Aplica as restrições de capacidade em disco do modelo de negócio SaaS da plataforma.], [Dado um vídeo resultante cujo tamanho faria ultrapassar 1 000 000 000 bytes no plano #raw("free") ou 5 000 000 000 bytes no plano #raw("premium"), quando o sistema tenta persistir o vídeo, então a persistência é recusada; um total igual ao limite não é recusado por este motivo.],

    [REQ-VID-TRIM-022], [O sistema deve aceitar o pedido de cancelamento de uma tarefa em fila ou em execução, impedindo a conclusão normal dessa tarefa.], [#must], [NOVO], [UC-VID-002, FA5; DQ-006], [Permite ao utilizador desistir de operações longas ou submetidas por engano sem perda de quota.], [Dado uma tarefa em estado "Em fila de espera" ou "A processar", quando o utilizador autorizado pede o cancelamento, então o pedido é aceite e a tarefa deixa de poder transitar para "Concluído".],

    [REQ-VID-TRIM-023], [Segundo a proposta de retenção do Trim, o sistema deve manter os vídeos recortados na biblioteca até à sua eliminação explícita pelo utilizador; a aplicação desta política depende de harmonização com UC-VID-001 e de decisão da equipa.], [#must], [NOVO], [UC-VID-002, RN6; DQ-005], [Clarifica a política de persistência e expiração e concede ao utilizador o controlo sobre a sua quota.], [Dado um vídeo recortado guardado na biblioteca e ainda não eliminado explicitamente pelo utilizador, quando a biblioteca é consultada, então o vídeo permanece disponível segundo a proposta de retenção do Trim, sujeita à decisão de harmonização com UC-VID-001.],

    [REQ-VID-TRIM-024], [O sistema deve apresentar na interface do utilizador autenticado a percentagem e o volume de espaço em disco atualmente ocupado na sua biblioteca em relação ao limite do seu perfil (1 GB em #raw("free") / 5 GB em #raw("premium")), atualizando o indicador após cada adição ou remoção de vídeo.], [#should], [NOVO], [UC-VID-002, Passo 1, Passo 7; RN6], [Oferece transparência sobre o consumo de capacidade da conta e previne bloqueios inesperados por excesso de quota.], [Dado um utilizador autenticado na aplicação, quando visualiza a biblioteca ou o diálogo de recorte, então a interface exibe uma barra de quota com os MB/GB utilizados e o limite máximo aplicável ao seu perfil.],

    [REQ-VID-TRIM-029], [O sistema deve atribuir um identificador único (Job ID) a cada tarefa de recorte aceite.], [#must], [NOVO], [UC-VID-002, Passo 5; DQ-001], [Isola uma responsabilidade verificável.], [Dado um pedido aceite, quando se consulta a resposta, então esta contém um Job ID distinto dos anteriores.],

    [REQ-VID-TRIM-030], [O sistema deve apresentar o acompanhamento da tarefa aceite com o estado inicial "Em fila de espera".], [#must], [NOVO], [UC-VID-002, Passo 5], [Isola uma responsabilidade verificável.], [Dado um Job ID atribuído, quando o utilizador abre o acompanhamento, então visualiza o estado inicial da tarefa.],

    [REQ-VID-TRIM-031], [O sistema deve registar no vídeo recortado os metadados de duração, resolução, tamanho e data.], [#must], [NOVO], [UC-VID-002, Passo 7; Pós-condição de sucesso], [Isola uma responsabilidade verificável.], [Dado um vídeo concluído, quando se consultam os seus metadados, então constam duração, resolução, tamanho e data.],

    [REQ-VID-TRIM-032], [O sistema deve permitir a reprodução do vídeo recortado disponível na biblioteca.], [#must], [NOVO], [UC-VID-002, Passo 8], [Isola uma responsabilidade verificável.], [Dado um vídeo concluído, quando o utilizador inicia a reprodução autorizada, então o vídeo é reproduzido.],

    [REQ-VID-TRIM-033], [O sistema deve permitir o descarregamento do vídeo recortado disponível na biblioteca por utilizador autorizado.], [#must], [NOVO], [UC-VID-002, Passo 8; DQ-003], [Isola uma responsabilidade verificável.], [Dado um vídeo concluído, quando o utilizador autorizado pede o descarregamento, então recebe o ficheiro resultante.],

    [REQ-VID-TRIM-034], [O sistema deve repor a operação diária debitada provisoriamente ao utilizador #raw("free") quando a tarefa falha, é cancelada ou a gravação é recusada por quota de armazenamento.], [#must], [NOVO], [UC-VID-002, RN1; Exceções de processamento e armazenamento; FA5], [Isola uma responsabilidade verificável.], [Dado um débito provisório, quando a tarefa falha ou é cancelada, então o saldo regressa ao valor anterior.],

    [REQ-VID-TRIM-035], [O sistema deve apresentar ao utilizador a causa conhecida da falha da tarefa de recorte.], [#must], [NOVO], [UC-VID-002, Exceções; Garantia Mínima], [Isola uma responsabilidade verificável.], [Dada uma tarefa falhada, quando o utilizador consulta o acompanhamento, então vê uma mensagem sobre a causa conhecida.],

    [REQ-VID-TRIM-036], [O sistema deve interromper a execução de uma tarefa cancelada que já esteja a ser processada.], [#must], [NOVO], [UC-VID-002, FA5; DQ-006], [Isola uma responsabilidade verificável.], [Dada uma tarefa em execução, quando o cancelamento é aceite, então o processamento termina sem publicar resultado.],

    [REQ-VID-TRIM-037], [O sistema deve eliminar os artefactos temporários de uma tarefa cancelada.], [#must], [NOVO], [UC-VID-002, FA5; DQ-005], [Isola uma responsabilidade verificável.], [Dado o cancelamento, quando a tarefa termina, então não restam artefactos temporários associados ao Job ID.],

    [REQ-VID-TRIM-038], [O sistema deve confirmar ao utilizador a conclusão do cancelamento da tarefa.], [#must], [NOVO], [UC-VID-002, FA5], [Isola uma responsabilidade verificável.], [Dado um cancelamento concluído, quando o utilizador consulta a tarefa, então vê o estado "Cancelada".],

    [REQ-VID-TRIM-039], [O sistema deve permitir ao utilizador autorizado eliminar explicitamente um vídeo recortado da biblioteca.], [#must], [NOVO], [UC-VID-002, RN6; DQ-005], [Isola uma responsabilidade verificável.], [Dado um vídeo da sua biblioteca, quando o utilizador confirma a eliminação, então o vídeo deixa de estar disponível.],

    [REQ-VID-TRIM-040], [O sistema deve atualizar o espaço ocupado da biblioteca após a eliminação de um vídeo recortado.], [#must], [NOVO], [UC-VID-002, RN6; DQ-005], [Isola uma responsabilidade verificável.], [Dado um vídeo eliminado, quando se consulta a ocupação da biblioteca, então o tamanho desse vídeo deixa de contar.],
  ),
)

== Requisitos Não Funcionais e de Qualidade

A coluna *Alvo* resume apenas a meta do MVP. As condições de medição, as metas de produção e o estado da validação constam dos dossiês de Upload e Trim; um alvo especificado não equivale a uma medição concluída. N/D na prioridade indica que o dossiê do Upload não a especifica. No requisito REQ-VID-TRIM-012, AAC é exigido apenas quando existe faixa de áudio.

#orientacao[
  Classifiquem segundo a ISO/IEC 25010 (Adequação Funcional, Eficiência de Desempenho, Compatibilidade,
  Usabilidade, Fiabilidade, Segurança, Manutenibilidade, Portabilidade). Indiquem o *Alvo*: o valor mensurável
  exigido a uma solução em produção. Prioridade segundo MoSCoW.
]

#tab([Requisitos não funcionais],
  tabela(
    colunas: (3.2cm, 1fr, 2.7cm, 2.3cm, 1.4cm, 2.2cm, 4.2cm),
    tamanho: 8pt,
    [ID], [Requisito], [ISO/IEC 25010], [Alvo], [Prioridade], [Origem], [Critério de aceitação],


    [REQ-VID-UPL-030],
    [O sistema deve transferir progressivamente cada vídeo sem manter o ficheiro integral em RAM, com pico de memória adicional atribuível a cada upload ≤ 1 000 000 000 bytes.],
    [Eficiência de desempenho],
    [≤ 1 000 000 000 bytes],
    [N/D],
    [RN5; DQ-001],
    [Dado um upload dentro do limite do plano, quando decorre o ensaio isolado e o ensaio concorrente, então não existe cópia integral do ficheiro em RAM e o pico adicional por upload não excede 1 000 000 000 bytes.],

    [REQ-VID-UPL-031],
    [O sistema deve impedir que um vídeo incompleto fique disponível no projeto após falha de transferência ou armazenamento.],
    [Fiabilidade],
    [0 vídeos incompletos],
    [N/D],
    [UC-VID-001 — exceções de transferência e armazenamento; RN4; DQ-002],
    [Dada cada falha provocada, quando o projeto é consultado, então não há referência disponível para processamento nem confirmação de sucesso.],

    [REQ-VID-UPL-032],
    [O sistema deve aplicar as permissões do projeto ao upload e ao acesso à referência do vídeo, incluindo projetos partilhados.],
    [Segurança],
    [Acesso autorizado],
    [N/D],
    [RN1; DQ-003; RNG-01],
    [Dada apenas permissão de leitura, quando se tenta upload, então o pedido é recusado com 403; com edição, é permitido. Sem acesso ao projeto, a referência do vídeo não é devolvida.],

    [REQ-VID-UPL-033],
    [O sistema deve apresentar estados distinguíveis de envio em curso, conclusão e falha do upload.],
    [Usabilidade],
    [3 estados distintos],
    [N/D],
    [UC-VID-001 — passos 4 e 7 e exceções; DQ-004],
    [Durante o envio aparece estado em curso; após sucesso aparece conclusão; após falha aparece erro, sem mensagem de sucesso indevida.],

    [REQ-VID-UPL-034],
    [O sistema deve conservar operacionais o carregamento e a listagem de imagens após a introdução do upload de vídeo.],
    [Compatibilidade],
    [2 fluxos operacionais],
    [N/D],
    [DQ-005; preservação do fluxo de imagens],
    [Dado um projeto com vídeo, quando se carrega e lista uma imagem, então a imagem é guardada e apresentada.],

    [REQ-VID-UPL-035],
    [O sistema deve guardar as referências de vídeo em #raw("videos") sem alterar as referências de imagem já existentes em #raw("imgs").],
    [Manutenibilidade],
    [#raw("videos") / #raw("imgs")],
    [N/D],
    [DQ-005; arquitetura de armazenamento],
    [Dado um projeto com imagens, quando se carrega um vídeo válido, então #raw("videos") contém a nova referência e #raw("imgs") conserva as referências anteriores.],

    [REQ-VID-TRIM-009], [O sistema deve transmitir e atualizar no ecrã de acompanhamento o progresso percentual (0% a 100%) da tarefa de recorte durante o processamento ativo no worker.], [Usabilidade / Transparência de Estado], [Intervalo ≤ 5 s], [#should], [UC-VID-002, Passo 5, Passo 6; DQ-001], [Dado uma tarefa em execução ativa no worker, quando o recorte de fotogramas progride, então a barra de progresso no navegador atualiza o seu valor com intervalo não superior a 5 s.],

    [REQ-VID-TRIM-012], [O vídeo recortado exportado deve usar contentor MP4, vídeo H.264 e, quando houver faixa de áudio, áudio AAC.], [Compatibilidade / Interoperabilidade Multimédia], [MP4 / H.264 / AAC], [#must], [UC-VID-002, Passo 7; RN4; DQ-004], [Dado o término de uma operação de recorte, quando o ficheiro gerado é inspecionado com utilitário #raw("ffprobe"), então o contentor é MP4, o vídeo é H.264 e, se existir áudio, o respetivo codec é AAC.],

    [REQ-VID-TRIM-013], [O sistema deve assegurar que o ficheiro de vídeo de entrada permanece rigorosamente inalterado em conteúdo, metadados e integridade na biblioteca do utilizador após a execução do recorte.], [Fiabilidade / Integridade de Dados], [Original inalterado], [#must], [UC-VID-002, Passo 7; RN5; Pós-condições], [Dado um vídeo de origem com hash SHA-256 conhecido, quando a tarefa de recorte termina (com êxito ou erro), então o hash do ficheiro original na biblioteca permanece rigorosamente idêntico.],

    [REQ-VID-TRIM-017], [O sistema deve repetir uma única vez uma tarefa que exceda 600 s de execução ou cujo worker termine anormalmente.], [Fiabilidade / Tolerância a Falhas e Recuperabilidade], [600 s; 1 repetição], [#must], [UC-VID-002, Exceção 5; DQ-002], [Dado um timeout superior a 600 s ou falha do worker, quando a falha é detetada, então há exatamente uma repetição; se voltar a falhar, a tarefa fica "Falhada" (estorno em REQ-VID-TRIM-034).],

    [REQ-VID-TRIM-018], [O sistema deve eliminar integralmente todos os fragmentos e ficheiros temporários gerados nos nós de processamento sempre que uma tarefa finalize com sucesso, falha ou cancelamento.], [Fiabilidade / Limpeza de Recursos Efémeros], [0 resíduos temporários], [#must], [UC-VID-002, Pós-condição garantia mínima; DQ-005], [Dado o encerramento de um job de recorte, quando o worker finaliza, então a diretoria temporária #raw("/tmp/picturas-jobs/<jobId>") encontra-se completamente purgada sem resíduos em disco.],

    [REQ-VID-TRIM-025], [O sistema deve devolver o Job ID do pedido de recorte aceite em até 2 s no percentil 95 do tempo de resposta da API.], [Eficiência de Desempenho / Comportamento Temporal], [p95 ≤ 2 s], [#must], [UC-VID-002, Passo 4, Passo 5; DQ-001], [Dado um conjunto de pelo menos 100 pedidos válidos nas condições fixadas, quando se ordenam os tempos de resposta, então o p95 é ≤ 2 s.],

    [REQ-VID-TRIM-026], [O sistema deve assegurar que o tempo total de processamento e recodificação de um excerto de vídeo não exceda 1.5 vezes a duração do excerto em nós de execução de referência (T_proc ≤ 1,5 × (t_out − t_in)).], [Eficiência de Desempenho / Eficiência de Processamento], [≤ 1,5 × duração], [#must], [UC-VID-002, Passo 6; DQ-002], [Dado um vídeo 1080p a 30 fps e um recorte de 60 segundos, quando processado no worker com FFmpeg, então o tempo entre a retirada da fila e a criação do ficheiro final é ≤ 90 segundos.],

    [REQ-VID-TRIM-027], [O sistema deve impedir o acesso a vídeos carregados e recortados por utilizadores sem permissão sobre o projeto, incluindo visitantes anónimos.], [Segurança / Confidencialidade e Controlo de Acesso], [Acesso autorizado], [#must], [UC-VID-002, Pré-condições, Passo 8; DQ-003], [Dado um vídeo pertencente ao Utilizador A, quando o Utilizador B (ou visitante anónimo) tenta aceder ao URL do vídeo, então o acesso é permitido a quem tenha leitura do projeto e recusado a quem não tenha acesso, incluindo visitantes anónimos.],

    [REQ-VID-TRIM-028], [O ambiente de execução do nó de processamento de vídeo deve encapsular as dependências externas e o binário de execução do FFmpeg de forma modular e isolada, sem dependência do sistema operativo anfitrião.], [Portabilidade e Manutenibilidade / Isolamento Modular], [Contentor autónomo], [#must], [UC-VID-002, Âmbito; DQ-004], [Dado a implantação do sistema num novo nó de infraestrutura, quando se inicia o contentor Docker do worker de vídeo, então o serviço arranca e processa recortes sem configuração prévia no host.],
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

    [Formato, codec, duração e dimensão do vídeo],
    [UC-VID-001],
    [Sim],
    [O upload aceita apenas MP4 com codec H.264 e aplica os limites de tamanho do ficheiro de 1 GB (Free) e 5 GB (Premium). A duração do vídeo não é critério de aceitação neste caso de uso; não se define nem verifica um limite de duração.],
    [REQ-VID-UPL-005, REQ-VID-UPL-009–013, REQ-VID-UPL-021–022, REQ-VID-UPL-026–027],

    [Estado, progresso, cancelamento e resultado],
    [UC-VID-001],
    [Parcialmente],
    [A indicação de *upload em curso* e as mensagens de conclusão ou falha integram o MVP. A percentagem de progresso do *upload* (0–100%) é melhoria futura, posterior ao MVP, ainda não implementada. FA2 permite desistir antes da confirmação; o cancelamento após o início do upload está fora do MVP, sem decisão de o implementar. O progresso e os resultados do *processamento* estão fora do âmbito de UC-VID-001.],
    [REQ-VID-UPL-015, REQ-VID-UPL-018–019, REQ-VID-UPL-025, REQ-VID-UPL-033, REQ-VID-UPL-036–038],

    [Falhas durante o processamento],
    [UC-VID-001],
    [Não],
    [Falhas de ferramentas de processamento não pertencem ao upload; falhas de rede, armazenamento, validação e associação durante o *upload* são tratadas nas exceções. O exemplo de consumidor Python/RabbitMQ não integra vídeo no fluxo #raw("/process").],
    [REQ-VID-UPL-025–027, REQ-VID-UPL-029, REQ-VID-UPL-031, REQ-VID-UPL-037–038],

    [Persistência e expiração dos ficheiros],
    [UC-VID-001],
    [Parcialmente],
    [Vídeo no SeaweedFS e referência/metadados persistentes no MongoDB. Não há política decidida de expiração ou retenção (QA-002); não se cria uma.],
    [REQ-VID-UPL-016–017],

    [Perfis e contagem de operações],
    [UC-VID-001],
    [Parcialmente],
    [Aplicam-se Free/Premium e permissões de edição, inclusive em projetos partilhados. Não existe regra de contagem de operações definida neste caso; não se introduz quota por número de uploads.],
    [REQ-VID-UPL-007–008, REQ-VID-UPL-012–013, REQ-VID-UPL-022–024, REQ-VID-UPL-032],

    [Encadeamento de ferramentas e processamento em lote],
    [UC-VID-001],
    [Não],
    [O caso termina com o vídeo carregado e disponível por referência. Encadeamento e lote são funções de processamento e exigiriam outro caso de uso; não são requisitos desta ERS.],
    [N/A; fronteira do UC-VID-001, passo 7],

    [Formato, _codec_, duração e dimensão do vídeo],
    [UC-VID-002],
    [Sim],
    [No MVP da Fase 1, o sistema suporta exclusivamente contentor MP4 com vídeo H.264 e áudio AAC, garantindo compatibilidade universal de reprodução em browsers HTML5 sem necessidade de remuxing no cliente. A duração do excerto está delimitada pelo perfil do utilizador (180s para `free` e 60 min para `premium`), e a dimensão máxima é governada pela quota global de armazenamento da biblioteca (1 GB para `free` e 5 GB para `premium`).],
    [REQ-VID-TRIM-004, REQ-VID-TRIM-006, REQ-VID-TRIM-012, REQ-VID-TRIM-016, REQ-VID-TRIM-021],

    [Estado, progresso, cancelamento e resultado],
    [UC-VID-002],
    [Sim],
    [O processamento de vídeo é demorado e assíncrono. O sistema gere o ciclo de vida completo da tarefa através dos estados formais: "Em fila de espera", "A processar", "Concluído", "Falhado" e "Cancelado". A interface apresenta progresso percentual periódico, permite o cancelamento cooperativo pelo utilizador em qualquer instante antes do término e disponibiliza pré-visualização e download imediatos após o sucesso.],
    [REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-009, REQ-VID-TRIM-014, REQ-VID-TRIM-031–033, REQ-VID-TRIM-015, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038, REQ-VID-TRIM-025],

    [Falhas durante o processamento],
    [UC-VID-002],
    [Sim],
    [Em caso de deteção de ficheiro danificado, codecs incompatíveis, término inesperado do worker ou timeout de execução (10 min), o sistema efetua uma reexecução automática idempotente; persistindo a falha, o job transita para estado "Falhado", a quota de operações diárias provisoriamente debitada é estornada ao utilizador e todos os ficheiros residuais nos workers são eliminados.],
    [REQ-VID-TRIM-016, REQ-VID-TRIM-034–035, REQ-VID-TRIM-017, REQ-VID-TRIM-018],

    [Persistência e expiração dos ficheiros],
    [UC-VID-002],
    [Sim],
    [O Trim propõe manter os vídeos de origem e de saída na biblioteca até à eliminação explícita pelo utilizador. A retenção e a quota acumulada proposta (1 GB em #raw("free") / 5 GB em #raw("premium")) ainda exigem harmonização com UC-VID-001 e decisão da equipa; não constituem política global aprovada. Os ficheiros temporários intermédios em nós de processamento são purgados após cada tarefa.],
    [REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-031–033, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-034, REQ-VID-TRIM-023, REQ-VID-TRIM-039–040, REQ-VID-TRIM-024],

    [Perfis e contagem de operações],
    [UC-VID-002],
    [Sim],
    [Articulação estrita com o esquema de utilizadores do PictuRAS (#raw("(\"anonymous\", \"free\", \"premium\")")): utilizadores anónimos estão totalmente bloqueados de aceder a ferramentas de vídeo; utilizadores #raw("free") dispõem de 5 operações diárias gratuitas (#raw("FREE_DAILY_OP = 5")), limite de 180s por recorte e 1 GB de disco; utilizadores #raw("premium") dispõem de operações ilimitadas, recortes até 60 min, suporte a stream copy e 5 GB de disco.],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-006, REQ-VID-TRIM-007, REQ-VID-TRIM-011, REQ-VID-TRIM-019, REQ-VID-TRIM-021, REQ-VID-TRIM-034],

    [Encadeamento de ferramentas e processamento em lote],
    [UC-VID-002],
    [Não],
    [No MVP da Fase 1, a ferramenta de recorte opera estritamente como uma ação atómica e individual sobre um único vídeo. O encadeamento sequencial de filtros de vídeo com transformações de imagem existentes e o processamento de múltiplos vídeos em lote (via `.zip`) introduziriam elevada sobrecarga de orquestração assíncrona que desvirtuaria a validação funcional do MVP, ficando formalmente diferidos para fases posteriores.],
    [Fora do âmbito do MVP],
  ),
)
