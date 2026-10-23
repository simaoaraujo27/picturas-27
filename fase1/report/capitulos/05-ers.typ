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

A evolução dos requisitos, o estado do refinamento, as condições de medição e a comparação original/refinado constam dos dossiês em fase1/features/, sem repetir aqui o respetivo registo. A origem e os IDs identificam a funcionalidade no catálogo comum. Requisitos explicitamente futuros não são contabilizados como implementados.

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

    [REQ-VID-REM-001],
    [O sistema deve permitir ao utilizador com permissão de edição selecionar um vídeo num projeto para remoção de segmento.],
    [#must],
    [ALT],
    [UC-VID-003 — Passo 1; RN1],
    [Entrada do fluxo de edição no projeto.],
    [Dado um utilizador com acesso de edição a um projeto, quando seleciona um vídeo, então o editor carrega a linha temporal (_timeline_) e os metadados do ficheiro.],

    [REQ-VID-REM-002],
    [O sistema deve validar a consistência do intervalo marcado para eliminação ($0 "s" <= t_"início" < t_"fim" <= "duração"$) no diálogo do editor, com marcação temporal em passos de, no máximo, 0,01 s.],
    [#must],
    [NOVO],
    [UC-VID-003 — Passo 2; RN2; Exceção 2; A3],
    [Impede operações temporalmente inconsistentes; a precisão de centésimos alinha-se com o editor partilhado do Trim.],
    [Dado o diálogo de remoção aberto, quando o utilizador introduz um fim anterior ou igual ao início, ou superior à duração do vídeo, então o sistema bloqueia a confirmação, assinala os campos com erro e não regista a operação como pendente.],

    [REQ-VID-REM-003],
    [O sistema deve garantir que a duração combinada da(s) parte(s) restante(s) do vídeo é igual ou superior a 1,0 s.],
    [#must],
    [NOVO],
    [UC-VID-003 — Passo 2; RN3; Exceção 3],
    [Impede eliminar a quase totalidade do vídeo e produzir resultados nulos (alinhado com o mínimo de 1,0 s do UC-VID-002).],
    [Dado um corte cujo resultado deixe menos de 1,0 s de vídeo útil, quando o utilizador tenta confirmar, então o sistema rejeita a operação com a notificação «A duração resultante do vídeo deve ser igual ou superior a 1,0 s» e mantém o diálogo aberto.],

    [REQ-VID-REM-004],
    [O sistema deve submeter a operação pendente (_staged_) à fila de processamento assíncrono, criando um _job_ de render, quando o utilizador aciona o botão *Aplicar*.],
    [#must],
    [NOVO],
    [UC-VID-003 — Passo 3; RN5; DQ-001],
    [Desacopla a confirmação no editor da execução pesada no _worker_; a atribuição de Job ID (REQ-VID-REM-014) e a sinalização de estado (REQ-VID-REM-015) foram separadas.],
    [Dado um corte pendente validado no editor, quando o utilizador clica em «Aplicar», então existe exatamente uma tarefa correspondente na fila assíncrona de processamento de vídeo.],

    [REQ-VID-REM-005],
    [O sistema deve processar a tarefa removendo o segmento indicado, concatenando as partes restantes (ou extraindo a parte contínua quando o corte incide num extremo), preservando a taxa de fotogramas e a sincronização áudio/vídeo do ficheiro original.],
    [#must],
    [ALT],
    [UC-VID-003 — Passo 4; RN2; A2],
    [Executa o processamento nuclear com exatidão temporal; a restrição de formato de saída foi separada para REQ-VID-REM-026.],
    [Dado um _job_ de remoção válido na fila, quando o _worker_ conclui a tarefa, então é gerado um novo ficheiro de vídeo sem o trecho eliminado, com desfasamento áudio/vídeo nulo nas junções.],

    [REQ-VID-REM-006],
    [O sistema deve registar o novo vídeo no projeto após a conclusão bem-sucedida do render, com identificador e nome derivado próprios, mantendo o vídeo original intacto e acessível (edição não-destrutiva).],
    [#must],
    [ALT],
    [UC-VID-003 — Passos 5 e 7; RN4; A5; Pós-condição de sucesso],
    [Materializa o modelo não-destrutivo; o registo de metadados foi separado para REQ-VID-REM-016.],
    [Dado o término com sucesso do render, quando o projeto é atualizado, então a lista de vídeos passa a incluir o novo vídeo com nome derivado único no projeto e o vídeo original permanece disponível e reproduzível.],

    [REQ-VID-REM-008],
    [O sistema deve permitir ao utilizador pré-visualizar localmente, no cliente, a união das partes restantes antes de aplicar a operação, sem submeter render ao servidor nem consumir quota de operações.],
    [#should],
    [NOVO],
    [UC-VID-003 — FA1; A4; DQ-003],
    [Reduz submissões incorretas e poupa recursos do servidor e quotas do utilizador (alinhado com a FA1 do UC-VID-002).],
    [Dado um intervalo selecionado no editor, quando o utilizador aciona a pré-visualização, então o reprodutor simula a junção saltando o trecho marcado, sem pedidos de processamento ao servidor nem débito de quota.],

    [REQ-VID-REM-009],
    [O sistema deve manter a marcação confirmada no diálogo como operação pendente (_staged_) no editor até à sua submissão via «Aplicar» ou ao seu cancelamento.],
    [#should],
    [NOVO],
    [UC-VID-003 — Passo 2; RN5],
    [Suporta o ciclo de _staging_ de RN5 (definição pendente no cliente, submissão explícita); o cancelamento/reajuste foi separado para REQ-VID-REM-022.],
    [Dado um corte confirmado no diálogo, quando a confirmação é aceite, então a operação fica registada como pendente no editor e permanece visível até à submissão ou ao cancelamento.],

    [REQ-VID-REM-010],
    [O sistema deve validar a autenticação do utilizador e a permissão de edição no projeto para autorizar a remoção de segmentos, bloqueando o acesso à ferramenta a utilizadores anónimos.],
    [#must],
    [ALT],
    [UC-VID-003 — RN1; RNG-01],
    [Protege os recursos de processamento de vídeo e respeita o controlo de acessos do projeto (alinhado com a RN7 do UC-VID-002 e a RN1 do UC-VID-001).],
    [Dado um utilizador sem permissão de edição, com sessão expirada ou anónimo, quando tenta aceder à ferramenta de remoção ou aplicar a operação, então o sistema rejeita o pedido com o código de erro correspondente.],

    [REQ-VID-REM-011],
    [O sistema deve validar, ao abrir a ferramenta, que o vídeo selecionado está em contentor MP4 com codec de vídeo H.264, rejeitando o acesso com a notificação «Formato de vídeo não suportado para edição» e mantendo o projeto inalterado.],
    [#must],
    [ALT],
    [UC-VID-003 — Exceção 1; RNG-02],
    [Evita submissões incompatíveis com o _pipeline_ partilhado (RN4 do UC-VID-002 e RN2 do UC-VID-001); a decisão sobre codecs de áudio na entrada está pendente no registo de refinamento do dossiê.],
    [Dado um vídeo em formato ou codec de vídeo não suportado, quando o utilizador tenta aceder à ferramenta de remoção, então o sistema rejeita o pedido com a notificação «Formato de vídeo não suportado para edição» e mantém o projeto inalterado.],

    [REQ-VID-REM-012],
    [O sistema deve recusar a submissão da operação quando a versão do projeto apresentada no editor estiver desatualizada (controlo otimista `X-Project-Version`), assinalando erro de conflito de concorrência.],
    [#must],
    [ALT],
    [UC-VID-003 — Passo 3; Exceção 5; A1],
    [Preserva a consistência do projeto em edição concorrente (alinhado com a exceção de versão do UC-VID-001); a instrução ao utilizador foi separada para REQ-VID-REM-021.],
    [Dado um projeto cuja versão foi alterada concorrencialmente por outro utilizador, quando o utilizador clica em «Aplicar», então o sistema rejeita a operação com erro de conflito de concorrência e a tarefa não é enfileirada.],

    [REQ-VID-REM-013],
    [O sistema deve notificar o cliente em tempo real (_WebSocket_ / evento de projeto) da conclusão da tarefa, apresentando de imediato o novo vídeo na galeria do projeto com reprodução disponível, sem recarregar a página.],
    [#must],
    [NOVO],
    [UC-VID-003 — Passo 6; Pós-condição de sucesso; DQ-004],
    [Fecha o ciclo assíncrono com visibilidade imediata do resultado no editor.],
    [Dado um _job_ de render concluído com sucesso, quando o evento de conclusão é recebido no cliente, então a galeria do projeto apresenta de imediato o novo vídeo e permite a sua reprodução sem recarregar a página.],

    [REQ-VID-REM-014],
    [O sistema deve atribuir um identificador único (_Job ID_) a cada tarefa de remoção aceite.],
    [#must],
    [NOVO],
    [UC-VID-003 — Passo 3 (divisão de REQ-VID-REM-004); DQ-001],
    [Isola uma responsabilidade verificável do ciclo assíncrono (alinhado com REQ-VID-TRIM-029).],
    [Dado um pedido aceite, quando se consulta a resposta, então esta contém um Job ID distinto dos anteriores.],

    [REQ-VID-REM-015],
    [O sistema deve sinalizar no editor o estado *em processamento* desde a aceitação da tarefa até à notificação de conclusão (sucesso ou falha).],
    [#must],
    [NOVO],
    [UC-VID-003 — Passo 3 (divisão de REQ-VID-REM-004)],
    [Isola uma responsabilidade verificável; o progresso percentual pertence ao âmbito do UC-VID-002.],
    [Dada uma tarefa aceite, quando o utilizador consulta o editor, então o vídeo apresenta o estado em processamento até à chegada do evento de conclusão.],

    [REQ-VID-REM-016],
    [O sistema deve registar no novo vídeo os metadados de duração, tamanho em bytes, codec e miniatura na conclusão bem-sucedida do render.],
    [#must],
    [NOVO],
    [UC-VID-003 — Passo 5 (divisão de REQ-VID-REM-006); A6],
    [Torna o derivado inspecionável na galeria (alinhado com REQ-VID-TRIM-031); miniaturas específicas do ponto de corte ficam fora do MVP (Q3).],
    [Dado um vídeo concluído, quando se consultam os seus metadados, então constam duração, tamanho, codec e miniatura.],

    [REQ-VID-REM-017],
    [O sistema deve recusar a gravação do vídeo resultante quando o tamanho acumulado da biblioteca ultrapassaria 1 000 000 000 bytes no plano `free` ou 5 000 000 000 bytes no plano `premium`, aplicando a proposta de quota acumulada do UC-VID-002, sujeita a harmonização com o UC-VID-001 (Q1).],
    [#must],
    [ALT],
    [UC-VID-003 — Exceção: quota de armazenamento; harmonização com RN6 do UC-VID-002],
    [Aplica o modelo SaaS de capacidade ao novo recurso criado.],
    [Dado um vídeo resultante cujo tamanho faria ultrapassar 1 000 000 000 bytes (`free`) ou 5 000 000 000 bytes (`premium`), quando o sistema tenta gravá-lo, então a gravação é recusada; um total igual ao limite não é recusado por este motivo.],

    [REQ-VID-REM-018],
    [O sistema deve verificar o saldo da quota diária de operações do perfil `free` antes de aceitar a submissão, impedindo-a com mensagem de quota esgotada quando o limite de 5 operações diárias (`FREE_DAILY_OP = 5`) tiver sido atingido.],
    [#must],
    [ALT],
    [UC-VID-003 — Passo 3; RN6; A7],
    [Estende o modelo SaaS de operações avançadas à remoção de segmento no _pipeline_ partilhado (A2, A7).],
    [Dado um utilizador `free` com saldo de 0 operações no dia corrente, quando tenta aplicar uma remoção, então a operação é impedida com mensagem de quota esgotada e nenhuma tarefa é criada.],

    [REQ-VID-REM-019],
    [O sistema deve debitar provisoriamente 1 operação da quota diária do perfil `free` no momento em que a tarefa de remoção é aceite e enfileirada.],
    [#must],
    [ALT],
    [UC-VID-003 — Passo 3; RN6; A7],
    [Previne o esgotamento dos _workers_ por submissões concorrentes acima do saldo.],
    [Dado um utilizador `free` com saldo de 5 operações, quando submete uma tarefa válida de remoção, então o saldo diário é decrementado para 4 antes do arranque do processamento.],

    [REQ-VID-REM-020],
    [O sistema deve repor a operação diária debitada ao utilizador `free` quando a tarefa falha após a repetição, expira ou tem a gravação recusada por quota de armazenamento.],
    [#must],
    [NOVO],
    [UC-VID-003 — Exceção 4 e Exceção: quota de armazenamento; RN6; A7],
    [Garante justiça da contabilidade de quotas em falhas não imputáveis ao utilizador (o cancelamento ativo depende da questão em aberto Q5).],
    [Dado um débito provisório, quando a tarefa falha após a repetição, expira ou tem a gravação recusada por quota, então o saldo diário regressa ao valor anterior.],

    [REQ-VID-REM-021],
    [O sistema deve solicitar a atualização do projeto e a repetição da operação ao utilizador após recusar a submissão por conflito de versão.],
    [#must],
    [ALT],
    [UC-VID-003 — Exceção 5 (divisão de REQ-VID-REM-012); A1],
    [Separa a instrução ao utilizador da recusa (alinhado com REQ-VID-UPL-040/041).],
    [Dada a recusa por conflito de versão, quando o utilizador consulta o editor, então a interface indica que o projeto foi alterado por outro utilizador e que deve atualizar o projeto e repetir a operação.],

    [REQ-VID-REM-022],
    [O sistema deve permitir cancelar ou reajustar a operação pendente (_staged_) no editor antes de acionar «Aplicar», sem gerar tarefas, pedidos ou encargos no servidor.],
    [#could],
    [NOVO],
    [UC-VID-003 — FA2; RN5 (divisão de REQ-VID-REM-009)],
    [Concede controlo sobre a marcação antes de qualquer custo (o débito só ocorre na aceitação, REQ-VID-REM-019).],
    [Dado um corte pendente no editor, quando o utilizador cancela a ação, então a marcação é descartada da memória local sem pedidos ao servidor e sem consumo de quota.],

[REQ-VID-COMP-001],
    [O sistema deve apresentar, no diálogo de compilação, os vídeos do projeto a que o utilizador autenticado tem acesso.],
    [#must],
    [ALT],
    [UC-VID-004 — Passo 1],
    [Permite selecionar vídeos existentes sem expor vídeos não autorizados.],
    [Dado um utilizador autenticado, quando abre o diálogo de compilação, então são apresentados apenas os vídeos do projeto a que tem acesso.],

    [REQ-VID-COMP-002],
    [O sistema deve permitir selecionar pelo menos dois vídeos acessíveis para uma compilação.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 2; RN1; FA2],
    [Define o número mínimo de entradas da operação.],
    [Dada uma seleção com zero ou um vídeo, quando o utilizador tenta iniciar a compilação, então o sistema não cria uma tarefa e informa que são necessários pelo menos dois vídeos.],

    [REQ-VID-COMP-003],
    [O sistema deve permitir ao utilizador definir a ordem dos vídeos selecionados antes de submeter a compilação.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 3; FA1; RN2],
    [Permite definir a sequência pretendida para o resultado.],
    [Dada uma seleção de pelo menos dois vídeos, quando o utilizador altera a ordem antes da submissão, então a interface apresenta a nova sequência.],

    [REQ-VID-COMP-004],
    [O sistema deve verificar, antes de aceitar a tarefa, que cada vídeo selecionado existe no projeto e tem um formato suportado, e deve verificar a sua legibilidade antes de iniciar a conversão.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 3; Exceções 1 e 8],
    [Evita aceitar entradas inexistentes, inacessíveis ou ilegíveis.],
    [Dado um pedido que inclui um vídeo inexistente no projeto (`VIDEO_NOT_FOUND`) ou em formato não suportado (`UNSUPPORTED_VIDEO`), quando ocorre a validação, então a tarefa não é aceite e o utilizador é informado da causa. Um vídeo ilegível é detetado pelo _worker_ antes da conversão (`VIDEO_UNREADABLE`).],

    [REQ-VID-COMP-005],
    [O sistema deve verificar a quota aplicável ao utilizador antes de aceitar uma tarefa de compilação.],
    [#must],
    [ALT],
    [UC-VID-004 — Passo 4; RN5; Exceção 2],
    [Aplica as regras de utilização do plano do utilizador.],
    [Dado um utilizador sem quota disponível segundo a política vigente, quando submete uma compilação, então a tarefa não é aceite e a interface informa que a quota foi esgotada.],

    [REQ-VID-COMP-006],
    [O sistema deve verificar se existe espaço de armazenamento suficiente antes de publicar o vídeo resultante na biblioteca.],
    [#must],
    [ALT],
    [UC-VID-004 — Passos 4 e 9; RN6; Exceção 3],
    [Evita publicar resultados que excedam a capacidade permitida.],
    [Dado que o espaço disponível é inferior ao necessário para guardar o resultado, quando a compilação termina, então o resultado não é publicado na biblioteca e o utilizador é informado da falta de espaço. O pedido é recusado com `STORAGE_QUOTA_EXCEEDED` (HTTP 507) se a conta já estiver cheia, e o _worker_ reserva o espaço exato antes de enviar o resultado.],

    [REQ-VID-COMP-007],
    [O sistema deve criar uma tarefa identificável para cada pedido de compilação aceite.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 5],
    [Permite acompanhar cada pedido de forma individual.],
    [Dado um pedido válido, quando o sistema o aceita, então cria uma tarefa com um identificador único e um estado inicial definido.],

    [REQ-VID-COMP-008],
    [O sistema deve compilar os vídeos pela ordem confirmada pelo utilizador na submissão.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 6; RN2],
    [Garante que a sequência de saída corresponde à sequência solicitada.],
    [Dada uma tarefa aceite com uma sequência definida, quando a compilação termina com sucesso, então os segmentos surgem no resultado pela mesma ordem.],

    [REQ-VID-COMP-009],
    [O sistema deve disponibilizar ao utilizador o estado atual da tarefa de compilação.],
    [#must],
    [ALT],
    [UC-VID-004 — Passo 7; RN7],
    [Permite distinguir tarefas em espera, em execução e terminadas.],
    [Dada uma tarefa aceite, quando o utilizador consulta o acompanhamento, então é apresentado o estado registado mais recente.],

    [REQ-VID-COMP-010],
    [Quando a compilação termina com sucesso, o sistema deve produzir um ficheiro de vídeo de saída reproduzível.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 8; Pós-condição de sucesso],
    [Define o resultado principal da operação.],
    [Dada uma tarefa concluída com sucesso, quando o ficheiro resultante é aberto num leitor compatível com o formato de saída definido, então o vídeo pode ser reproduzido.],

    [REQ-VID-COMP-011],
    [O sistema deve registar o ficheiro resultante na biblioteca do utilizador que iniciou a tarefa após validar o resultado e concluir o armazenamento.],
    [#must],
    [ALT],
    [UC-VID-004 — Passo 9; RN4; Pós-condição de sucesso],
    [Torna o resultado disponível ao seu proprietário.],
    [Dado um resultado validado e armazenado, quando a tarefa é marcada como concluída, então o ficheiro aparece na biblioteca do utilizador que iniciou a compilação.],

    [REQ-VID-COMP-012],
    [A compilação não deve modificar nem eliminar os ficheiros de origem.],
    [#must],
    [ALT],
    [UC-VID-004 — Passo 10; RN3],
    [Preserva a integridade das entradas.],
    [Comparando cada ficheiro de origem antes e depois da tarefa, o conteúdo mantém-se igual e o ficheiro continua acessível ao utilizador autorizado.],

    [REQ-VID-COMP-013],
    [O sistema deve impedir a criação de uma tarefa quando estiver selecionado menos de dois vídeos.],
    [#must],
    [NOVO],
    [UC-VID-004 — RN1; FA2],
    [Explicita a validação do número mínimo de entradas.],
    [Com zero ou um vídeo selecionado, uma tentativa de submissão não cria qualquer tarefa de compilação.],

    [REQ-VID-COMP-014],
    [O sistema deve aceitar como entrada da compilação apenas vídeos do projeto em contentor MP4 com codec de vídeo H.264, conforme a regra transversal RNG-02, e recusar qualquer outro formato com uma mensagem de erro.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 3; Exceção 8; RN9; RNG-02],
    [Evita que “formatos suportados” seja interpretado de formas diferentes.],
    [Um vídeo MP4/H.264 do projeto é aceite; um vídeo noutro contentor ou codec é recusado no pedido com `UNSUPPORTED_VIDEO` (HTTP 415) e a tarefa não é criada, com base nos metadados guardados no projeto. Um vídeo ilegível faz a tarefa falhar mais tarde, no _worker_, com `VIDEO_UNREADABLE`.],

    [REQ-VID-COMP-015],
    [O sistema deve impedir o início do processamento quando não conseguir ler um dos vídeos selecionados.],
    [#must],
    [NOVO],
    [UC-VID-004 — Exceção 1],
    [Evita iniciar uma tarefa que não pode ser concluída com as entradas fornecidas.],
    [Dado que pelo menos um vídeo selecionado está corrompido ou ilegível, quando termina a validação, então a tarefa falha com `VIDEO_UNREADABLE` antes de iniciar a conversão e não cria resultado.],

    [REQ-VID-COMP-016],
    [Quando a validação detetar um vídeo corrompido ou ilegível, o sistema deve apresentar uma mensagem de erro (“One of the videos could not be read.”).],
    [#must],
    [NOVO],
    [UC-VID-004 — Exceção 1],
    [Explica ao utilizador por que motivo a tarefa não avançou.],
    [Num teste com um vídeo corrompido ou ilegível, a tarefa termina em «Failed» com `VIDEO_UNREADABLE`, a interface apresenta a mensagem especificada e nenhum vídeo resultante é criado.],

    [REQ-VID-COMP-017],
    [O sistema não deve publicar na biblioteca um ficheiro de saída incompleto após falha ou cancelamento da tarefa.],
    [#must],
    [ALT],
    [UC-VID-004 — RN8; Exceções 4 e 6; garantia mínima],
    [Evita expor resultados inválidos.],
    [Após uma falha ou cancelamento, o resultado parcial não aparece na biblioteca nem fica disponível para reprodução ou descarregamento; os ficheiros de origem continuam inalterados.],

    [REQ-VID-COMP-018],
    [Quando o processador disponibilizar informação de progresso, o sistema deve atualizar o progresso apresentado ao utilizador em intervalos não superiores a 5 s durante a execução.],
    [#should],
    [ALT],
    [UC-VID-004 — RN7],
    [Define uma frequência de atualização verificável sem presumir que existe progresso calculável em todas as fases.],
    [Num teste com uma tarefa suficientemente longa e dados de progresso disponíveis, o intervalo entre atualizações apresentadas não excede 5 s. O _worker_ comunica o progresso (0 a 99 %) ao serviço `projects` cerca de uma vez por segundo, quando este aumenta. A interface consulta o estado das tarefas de 3 em 3 segundos enquanto o diálogo está aberto.],

    [REQ-VID-COMP-019],
    [O sistema deve terminar uma tarefa que atinja o limite máximo de tempo de processamento configurado para o serviço.],
    [#should],
    [NOVO],
    [UC-VID-004 — Exceção 5],
    [Evita tarefas que permaneçam ativas indefinidamente.],
    [Num teste controlado, quando uma tarefa atinge o limite de tempo configurado, termina com estado de falha e não publica um resultado incompleto. O limite é de 30 minutos por omissão (`COMPILE_TIMEOUT_SECONDS`, configurável) e a falha por tempo limite é recuperável (`PROCESSING_TIMEOUT`).],

    [REQ-VID-COMP-020],
    [O sistema deve rejeitar, antes de criar a tarefa, pedidos que excedam qualquer limite de duração, tamanho ou número de vídeos definido para o perfil do utilizador.],
    [#must],
    [NOVO],
    [UC-VID-004 — Passo 3; RN10; RN11; Exceções 7 e 9],
    [Aplica limites de utilização de forma previsível.],
    [Para cada limite configurado, um pedido acima do limite é rejeitado antes do processamento e a interface identifica o limite excedido. Para o armazenamento acumulado aplicam-se 1 GB no perfil `free` e 5 GB no `premium` (UC-VID-002, RN6); a soma das durações dos vídeos está limitada a 10 minutos no perfil `free` e a 1 hora no `premium` (RN10, valores configuráveis), verificada no pedido (`COMPILE_TOO_LONG`, HTTP 422) e de novo pelo _worker_ (`TOTAL_TOO_LONG`); uma compilação aceita no máximo 10 vídeos (RN11, `TOO_MANY_VIDEOS`).],

    [REQ-VID-COMP-021],
    [O sistema deve registar o consumo de quota de cada compilação segundo a unidade e o momento de contabilização definidos para o serviço.],
    [#must],
    [ALT],
    [UC-VID-004 — Passo 4; RN5; Exceção 2],
    [Permite aplicar a mesma regra a pedidos equivalentes.],
    [Num teste de quota, o consumo registado corresponde à regra documentada para a compilação. Tal como no recorte (UC-VID-002), cada compilação consome uma operação da quota diária (5 por dia no perfil `free`, sem limite diário no `premium`), reservada na submissão e estornada em caso de falha ou cancelamento. O serviço `projects` usa o mesmo endpoint interno de quota do serviço `users` do recorte.],

    [REQ-VID-COMP-022],
    [O sistema deve aplicar aos vídeos de entrada, resultados e ficheiros temporários a política de retenção aprovada para o serviço.],
    [#should],
    [NOVO],
    [UC-VID-004 — decisão de persistência],
    [Define o ciclo de vida dos ficheiros e evita retenção indefinida não intencional.],
    [Num teste com ficheiros cuja retenção expirou, o sistema aplica a política aprovada. Prazos, exceções e tratamento de temporários ficam pendentes de decisão.],
    
    [#text(hyphenate: true, "REQ-VID-SPEED-001")], [#text(hyphenate: true, "O sistema deve permitir iniciar Modificar velocidade para um vídeo associado ao projeto acessível ao utilizador.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passos 1–2; A2")], [#text(hyphenate: true, "Contextualiza a operação no projeto existente.")], [#text(hyphenate: true, "Dado um vídeo associado e acesso de edição, quando o utilizador abre a ação, então o diálogo identifica esse vídeo.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-002")], [#text(hyphenate: true, "O sistema deve permitir indicar o início e o fim de cada intervalo em segundos.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 3; A4")], [#text(hyphenate: true, "Permite parametrização temporal.")], [#text(hyphenate: true, "Dado o diálogo com duração disponível, quando se alteram os campos ou a seleção temporal, então a configuração apresenta os valores escolhidos.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-003")], [#text(hyphenate: true, "O sistema deve aceitar apenas os fatores de velocidade 0,5x, 1x e 2x.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 4; RN1")], [#text(hyphenate: true, "Evita velocidades fora do âmbito.")], [#text(hyphenate: true, "Dado um intervalo, quando se escolhe uma opção, então apenas estes fatores estão disponíveis; um pedido com 0,25, 4 ou uma string em vez de número é rejeitado.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-004")], [#text(hyphenate: true, "O sistema deve manter a velocidade configurada independentemente para cada intervalo do mesmo vídeo.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 5; FA1; A7")], [#text(hyphenate: true, "Suporta várias alterações numa operação.")], [#text(hyphenate: true, "Dados dois intervalos válidos com velocidades distintas, quando o pedido é submetido, então ambos mantêm os respetivos parâmetros.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-005")], [#text(hyphenate: true, "O sistema deve rejeitar um intervalo cujo fim seja igual ou anterior ao início.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX2; RN2")], [#text(hyphenate: true, "Impede durações nulas ou negativas.")], [#text(hyphenate: true, "Dado início 4 e fim 4 ou 3, quando se valida, então o intervalo é rejeitado e não é processado como válido.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-006")], [#text(hyphenate: true, "O sistema deve rejeitar sobreposição entre intervalos, permitindo apenas fronteiras adjacentes.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX3; RN2")], [#text(hyphenate: true, "Evita atribuir duas velocidades ao mesmo trecho.")], [#text(hyphenate: true, "Dados [2,5] e [4,7], a configuração é rejeitada; dados [2,4] e [4,6], é aceite quanto à sobreposição, mesmo se introduzidos por ordem inversa.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-007")], [#text(hyphenate: true, "O sistema deve apresentar a lista/resumo dos intervalos e velocidades antes de submeter.")], [#should], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 7")], [#text(hyphenate: true, "Permite rever a configuração sem confirmação duplicada.")], [#text(hyphenate: true, "Dados intervalos configurados, quando o diálogo é consultado antes de Processar, então mostra início, fim e velocidade de cada um.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-008")], [#text(hyphenate: true, "O sistema deve aceitar a submissão de uma configuração válida para processamento assíncrono, atribuindo um identificador de pedido e um novo identificador de vídeo.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 8; RN8; DQ-001")], [#text(hyphenate: true, "Liga submissão, resultado e artefacto independente.")], [#text(hyphenate: true, "Dado um pedido autorizado e válido, quando é aceite, então devolve aceitação assíncrona e identificadores, sem substituir o identificador do original.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-009")], [#text(hyphenate: true, "O sistema deve confirmar a submissão aceite e informar que o novo vídeo ficará disponível após conclusão, sem apresentar essa aceitação como sucesso do processamento.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 9; RN9")], [#text(hyphenate: true, "Não confunde aceitação com sucesso final.")], [#text(hyphenate: true, "Dada uma resposta de aceitação, quando a interface a recebe, então apresenta a confirmação de submissão e não anuncia o vídeo como já produzido.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-010")], [#text(hyphenate: true, "O sistema deve transformar a duração de cada intervalo segundo o fator definido, conservando a sua ordem temporal.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 10; RN1")], [#text(hyphenate: true, "Define o significado verificável de velocidade.")], [#text(hyphenate: true, "Dados os casos A–C da tabela de duração no capítulo de testes, quando são processados, então as durações correspondem à fórmula, dentro da tolerância do ensaio.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-011")], [#text(hyphenate: true, "O sistema deve manter a velocidade temporal 1x das partes não selecionadas.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 10; RN3; RN5")], [#text(hyphenate: true, "Limita o efeito às seleções.")], [#text(hyphenate: true, "Dado um vídeo com trechos selecionados e não selecionados, quando se inspeciona o resultado, então os trechos não selecionados mantêm a sua escala temporal e ordem.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-012")], [#text(hyphenate: true, "O sistema deve ajustar a velocidade do áudio existente de acordo com o fator aplicado ao respetivo segmento.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 11; RN4")], [#text(hyphenate: true, "Mantém coerência temporal áudio/vídeo.")], [#text(hyphenate: true, "Dado um segmento com áudio a 2x ou 0,5x, quando se processa, então áudio e vídeo apresentam durações coerentes com o mesmo fator, segundo o ensaio definido.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-014")], [#text(hyphenate: true, "O sistema deve armazenar o vídeo resultante sob uma referência distinta da original.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 12; RN7")], [#text(hyphenate: true, "Evita substituição do conteúdo de origem.")], [#text(hyphenate: true, "Dado um output válido, quando é transferido, então usa um novo identificador e uma chave distinta da do original.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-015")], [#text(hyphenate: true, "O sistema deve disponibilizar na biblioteca do projeto apenas um resultado associado com sucesso.")], [#must], [#text(hyphenate: true, "ALT")], [#text(hyphenate: true, "UC-VID-005 — Passo 13; EX4; EX6")], [#text(hyphenate: true, "Evita anunciar ficheiros não associados.")], [#text(hyphenate: true, "Dada associação bem-sucedida, o novo vídeo surge após atualização do projeto; se quota ou associação falharem, não surge como resultado final.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-016")], [#text(hyphenate: true, "Numa evolução futura, o sistema deve permitir cancelar um pedido enquanto ainda aguarda execução.")], [#should], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — FA4; Q3")], [#text(hyphenate: true, "Preserva a intenção sem declarar suporte inexistente.")], [#text(hyphenate: true, "Dado um pedido ainda não executado numa versão futura, quando o cancelamento é confirmado, então não produz um resultado; o mecanismo e os testes ainda não estão implementados.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-017")], [#text(hyphenate: true, "O sistema deve processar uma entrada sem áudio sem acrescentar uma faixa artificial.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — FA5; RN11")], [#text(hyphenate: true, "Torna explícita a ausência de áudio na saída.")], [#text(hyphenate: true, "Dado um MP4/H.264 sem áudio, quando se processa, então a inspeção do output continua sem streams de áudio.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-018")], [#text(hyphenate: true, "O sistema deve rejeitar uma entrada que não seja MP4 com vídeo H.264 válido.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — EX1; RN11; A5")], [#text(hyphenate: true, "É uma condição funcional de aceitação, não uma medição de desempenho.")], [#text(hyphenate: true, "Dada uma entrada sem vídeo, com contentor diferente de MP4 ou codec de vídeo diferente de H.264, quando o worker a valida, então não produz um resultado associado.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-019")], [#text(hyphenate: true, "O sistema deve recusar a associação do resultado se os seus bytes reais fizerem ultrapassar a quota acumulada de armazenamento do proprietário.")], [#must], [#text(hyphenate: true, "ALT")], [#text(hyphenate: true, "UC-VID-005 — Passo 13; EX4; RN6; DQ-005")], [#text(hyphenate: true, "Reutiliza a quota existente sem inventar contagem diária.")], [#text(hyphenate: true, "Dada conta Free com 999 999 990 bytes e output de 20 bytes, a associação é recusada; com 999 999 980 bytes, o mesmo output é aceite.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-022")], [#text(hyphenate: true, "O sistema deve rejeitar tempos de início ou fim que não sejam números finitos.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX2; RN2")], [#text(hyphenate: true, "Evita coerções e parâmetros não representáveis.")], [#text(hyphenate: true, "Dados campos vazios na interface, ou null, strings e valores não finitos na API, quando se valida, então não são aceites como tempos válidos.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-023")], [#text(hyphenate: true, "O sistema deve rejeitar um início negativo.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX2; RN2")], [#text(hyphenate: true, "Impede referências anteriores à origem temporal.")], [#text(hyphenate: true, "Dado início -1 e fim 2, quando se valida, então o intervalo é rejeitado.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-024")], [#text(hyphenate: true, "O sistema deve rejeitar um fim que ultrapasse a duração real do vídeo.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passos 6 e 10; EX11; RN2")], [#text(hyphenate: true, "Impede selecionar conteúdo inexistente.")], [#text(hyphenate: true, "Dado vídeo de 10 s e fim 11 s, a interface bloqueia; se um pedido direto chegar ao worker, este rejeita-o após medir a duração, sem adicionar resultado.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-025")], [#text(hyphenate: true, "O sistema deve exigir pelo menos um intervalo válido.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX10; RN8")], [#text(hyphenate: true, "Evita operações sem configuração.")], [#text(hyphenate: true, "Dada uma lista vazia ou ausente, quando se tenta submeter, então a configuração não é aceite.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-026")], [#text(hyphenate: true, "O sistema deve permitir editar tempos e velocidade de um intervalo antes da submissão.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 5; FA3")], [#text(hyphenate: true, "Permite corrigir a seleção sem criar tarefas.")], [#text(hyphenate: true, "Dado um intervalo na lista, quando é editado, então a lista e os erros refletem a nova configuração antes de Processar.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-027")], [#text(hyphenate: true, "O sistema deve permitir remover um intervalo antes da submissão.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passo 5; FA3")], [#text(hyphenate: true, "Permite desistir de uma alteração específica.")], [#text(hyphenate: true, "Dados vários intervalos, quando um é removido, então deixa de integrar o pedido; removendo todos, aplica-se REQ-VID-SPEED-025.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-028")], [#text(hyphenate: true, "O sistema deve recusar a submissão sem sessão válida ou sem permissão de edição no projeto.")], [#must], [#text(hyphenate: true, "ALT")], [#text(hyphenate: true, "UC-VID-005 — Passo 8; FA7; EX8; RN10")], [#text(hyphenate: true, "Reutiliza autenticação e partilhas.")], [#text(hyphenate: true, "Dados pedidos sem JWT válido ou através de partilha só de leitura, quando são submetidos, então são recusados; uma partilha válida com edição permite a operação.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-029")], [#text(hyphenate: true, "O sistema deve recusar uma submissão sem versão válida ou cuja versão não coincida com a atual do projeto.")], [#must], [#text(hyphenate: true, "ALT")], [#text(hyphenate: true, "UC-VID-005 — Passo 8; EX9; DQ-003")], [#text(hyphenate: true, "Mantém o contrato de concorrência existente.")], [#text(hyphenate: true, "Dada versão inválida/ausente, a API responde 428; dada versão desatualizada, responde 409, sem enfileirar a operação.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-030")], [#text(hyphenate: true, "O sistema deve gerar MP4/H.264 com AAC quando existe áudio de entrada.")], [#must], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — Passos 11–12; RN11; DQ-004")], [#text(hyphenate: true, "Define a compatibilidade de saída.")], [#text(hyphenate: true, "Dado um input com áudio e transformação concluída, quando o output é inspecionado, então possui vídeo h264 e áudio aac em MP4; o caso sem áudio segue REQ-VID-SPEED-017.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-031")], [#text(hyphenate: true, "O sistema deve libertar a reserva de armazenamento quando uma falha controlada impede a associação do resultado.")], [#must], [#text(hyphenate: true, "ALT")], [#text(hyphenate: true, "UC-VID-005 — EX4; EX6; RN6; DQ-005")], [#text(hyphenate: true, "Evita reservas sem resultado associado.")], [#text(hyphenate: true, "Dada reserva de 20 bytes e falha de associação, quando o tratamento de erro termina com a infraestrutura disponível, então os bytes usados regressam ao valor anterior e nenhum add-video é emitido.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-032")], [#text(hyphenate: true, "O sistema deve incrementar a versão apenas na nova associação e evitar repetir essa associação e contabilização para o mesmo resultado.")], [#must], [#text(hyphenate: true, "ALT")], [#text(hyphenate: true, "UC-VID-005 — Passo 13; EX13; RN13")], [#text(hyphenate: true, "Evita duplicação por repetição de mensagens.")], [#text(hyphenate: true, "Dado o mesmo resultado entregue duas vezes sequencialmente, então existe apenas um novo vídeo, um incremento de versão e uma contabilização do output; não é apagado o vídeo associado.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-033")], [#text(hyphenate: true, "O sistema deve apresentar mensagens claras para erros de configuração e de submissão recebidos pela interface.")], [#must], [#text(hyphenate: true, "ALT")], [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX2–3; EX8–10")], [#text(hyphenate: true, "Permite corrigir erros antes de gerar novo pedido.")], [#text(hyphenate: true, "Dada configuração inválida ou resposta HTTP de autenticação, permissão ou versão, quando ocorre o erro, então a interface o identifica e não apresenta sucesso de processamento.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-038")], [#text(hyphenate: true, "Numa evolução futura, o sistema deve comunicar ao utilizador a falha terminal de um pedido já aceite, distinguindo-a de um erro de submissão.")], [#should], [#text(hyphenate: true, "NOVO")], [#text(hyphenate: true, "UC-VID-005 — EX1; EX4; EX6–7; RN9; DQ-006")], [#text(hyphenate: true, "Explicita uma intenção da garantia mínima ainda não implementada na interface.")], [#text(hyphenate: true, "Dado um pedido aceite que posteriormente falha numa versão futura, quando o estado final estiver disponível, então o utilizador pode identificar a falha e o pedido; mecanismo e validação ainda por definir.")],
    
  ),
)

#pagebreak(weak: true)

== Requisitos Não Funcionais e de Qualidade

A coluna *Alvo* resume apenas a meta do MVP. As condições de medição, as metas de produção e o estado da validação constam dos dossiês de Upload, Trim, Remoção de segmento e Modificar velocidade; um alvo especificado não equivale a uma medição concluída. N/D na prioridade indica que o respetivo dossiê não a especifica. Nos requisitos REQ-VID-TRIM-012 e REQ-VID-REM-026, AAC é exigido apenas quando existe faixa de áudio.

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

    [REQ-VID-REM-007],
    [O sistema deve manter o projeto e o vídeo original inalterados quando a tarefa de remoção falha ou excede o tempo limite de 600 s por tentativa, repetindo a tarefa uma única vez desde o início antes de a marcar como falhada e notificar o erro.],
    [Fiabilidade / Tolerância a Falhas e Recuperabilidade],
    [600 s por tentativa; 1 repetição],
    [N/D],
    [UC-VID-003 — Exceção 4; Pós-condição mínima; RN4; A2; DQ-001],
    [Dado um _timeout_ superior a 600 s ou uma falha do _worker_, quando a falha é detetada, então há exatamente uma repetição; se voltar a falhar, a tarefa fica falhada, o utilizador é notificado, o original mantém o hash idêntico e (se `free`) a operação é estornada (REQ-VID-REM-020).],

    [REQ-VID-REM-023],
    [O sistema deve eliminar integralmente os ficheiros e fragmentos temporários gerados nos nós de processamento sempre que uma tarefa de remoção finalize, com sucesso ou falha.],
    [Fiabilidade / Limpeza de Recursos Efémeros],
    [0 resíduos temporários],
    [N/D],
    [UC-VID-003 — Exceção 4; A2; DQ-001],
    [Dado o encerramento de um _job_ de remoção, quando o _worker_ finaliza, então a diretoria temporária do Job ID fica completamente purgada, sem resíduos em disco.],

    [REQ-VID-REM-024],
    [O sistema deve responder à submissão via «Aplicar» com a aceitação da tarefa e o respetivo Job ID em até 2 s no percentil 95.],
    [Eficiência de Desempenho / Comportamento Temporal],
    [p95 ≤ 2 s],
    [N/D],
    [UC-VID-003 — Passo 3; REQ-VID-REM-014; DQ-001],
    [Dado um conjunto de pelo menos 100 pedidos válidos nas condições fixadas, quando se ordenam os tempos de resposta, então o p95 é ≤ 2 s.],

    [REQ-VID-REM-025],
    [O sistema deve concluir o processamento (remoção, concatenação e recodificação) em tempo não superior a 1,5 vezes a duração do vídeo resultante em nós de execução de referência ($T_"proc" <= 1,5 times "duração resultante"$).],
    [Eficiência de Desempenho / Eficiência de Processamento],
    [≤ 1,5 × duração resultante],
    [N/D],
    [UC-VID-003 — Passo 4; A2; DQ-001],
    [Dado um vídeo 1080p a 30 fps cujo resultado tem 60 s, quando processado no _worker_ com FFmpeg, então o tempo entre a retirada da fila e a criação do ficheiro final é ≤ 90 s.],

    [REQ-VID-REM-026],
    [O vídeo resultante exportado deve usar contentor MP4, vídeo H.264 e, quando houver faixa de áudio, áudio AAC.],
    [Compatibilidade / Interoperabilidade Multimédia],
    [MP4 / H.264 / AAC quando existe áudio],
    [N/D],
    [UC-VID-003 — Passo 4 (divisão de REQ-VID-REM-005); A6; RNG-02],
    [Dado o término de uma remoção, quando o ficheiro gerado é inspecionado com `ffprobe`, então o contentor é MP4, o vídeo é H.264 e, se existir áudio, o respetivo codec é AAC.],

    [REQ-VID-REM-027],
    [O sistema deve impedir o acesso ao vídeo original e ao vídeo resultante por utilizadores sem permissão sobre o projeto, incluindo visitantes anónimos.],
    [Segurança / Confidencialidade e Controlo de Acesso],
    [Acesso autorizado],
    [N/D],
    [UC-VID-003 — Pré-condições; RN1; RNG-01],
    [Dado um vídeo pertencente a um projeto, quando um utilizador sem qualquer permissão ou um visitante anónimo tenta aceder ao URL do vídeo original ou resultante, então o acesso é recusado; quem tenha leitura do projeto pode consultar.],

    [REQ-VID-COMP-NF-001],
    [O sistema deve responder à submissão de um pedido válido em menos de 3 s, sem esperar pela conclusão da compilação.],
    [Eficiência de desempenho],
    [#must],
    [UC-VID-004 — Passo 5; DQ1],
    [Separa o tempo de aceitação do tempo total de processamento.],
    [Medir desde a submissão até à resposta de aceitação num ambiente de teste documentado. Alvo MVP proposto: menos de 3 s; produção proposta: menos de 1 s. Validar ambiente e carga com a equipa.],

    [REQ-VID-COMP-NF-002],
    [O sistema deve impedir a consulta ou o descarregamento dos vídeos de entrada e do resultado por utilizadores sem autorização.],
    [Segurança],
    [#must],
    [UC-VID-004 — Passos 1 e 9; DQ2],
    [Protege a confidencialidade dos ficheiros.],
    [Uma tentativa de consulta e outra de descarregamento com uma sessão sem autorização são recusadas.],

    [REQ-VID-COMP-NF-003],
    [Após falha ou cancelamento, o sistema deve manter um estado final consistente e não expor o resultado parcial.],
    [Fiabilidade],
    [#must],
    [UC-VID-004 — RN8; DQ3],
    [Mantém a biblioteca consistente após interrupções.],
    [Ao injetar uma falha ou cancelar uma tarefa, o estado final é Falhada ou Cancelada, conforme aplicável, e não existe resultado parcial acessível. A recuperação automática em produção fica por decidir.],

    [REQ-VID-COMP-NF-004],
    [O sistema deve permitir consultar o estado registado de uma tarefa depois de o utilizador sair da página e regressar à aplicação.],
    [Fiabilidade],
    [#must],
    [UC-VID-004 — Passo 7; DQ4],
    [Permite acompanhar tarefas que continuam depois de sair da página.],
    [Iniciar uma tarefa, sair da página e regressar; o estado apresentado corresponde ao estado mais recente registado pelo sistema.],

    [REQ-VID-COMP-NF-005],
    [O sistema deve produzir o vídeo compilado em contentor MP4 com codec de vídeo H.264, o mesmo formato exigido na entrada (RNG-02).],
    [Compatibilidade],
    [#must],
    [UC-VID-004 — FA3; DQ5; RN9; RNG-02],
    [Elimina a ambiguidade entre contentor, codec, entrada e saída.],
    [O ficheiro resultante de uma compilação bem-sucedida tem contentor MP4, vídeo H.264 e áudio AAC, verificável pela inspeção dos metadados do ficheiro (TST-COMP-01).],

    [REQ-VID-COMP-NF-006],
    [O sistema deve executar cada tarefa dentro dos limites de tempo e recursos configurados para o serviço.],
    [Eficiência de desempenho],
    [#should],
    [UC-VID-004 — Exceção 5; DQ6],
    [Reduz o risco de consumo ilimitado de recursos.],
    [Num teste de carga documentado, tarefas que atingem os limites configurados terminam de acordo com REQ-VID-COMP-019. Os valores de CPU, memória, concorrência e tempo ficam pendentes de validação.],

    [REQ-VID-COMP-NF-007],
    [A lógica de compilação deve estar separada das regras de autenticação e da gestão da biblioteca.],
    [Manutenibilidade],
    [#should],
    [UC-VID-004 — decisão de arquitetura; DQ7],
    [Facilita a alteração isolada do processamento de vídeo.],
    [Por inspeção arquitetural, a lógica de compilação pode ser alterada sem modificar a lógica de autenticação ou a listagem da biblioteca, salvo interfaces explicitamente documentadas. Validar com a arquitetura real.],

    [#text(hyphenate: true, "REQ-VID-SPEED-013")], [#text(hyphenate: true, "Numa evolução futura, o sistema deve disponibilizar acompanhamento do progresso após a aceitação do pedido.")], [#text(hyphenate: true, "Usabilidade / transparência de estado")], [#text(hyphenate: true, "Adiado; o MVP confirma submissão e atualiza a biblioteca no sucesso, sem consulta persistente ou percentagem.")], [N/D], [#text(hyphenate: true, "UC-VID-005 — Passo 9; RN9; Q7")], [#text(hyphenate: true, "Numa evolução futura, dado um pedido aceite, quando progride ou termina, então o estado consultado reflete essa evolução. Frequência e precisão não estão definidas nem validadas.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-020")], [#text(hyphenate: true, "O sistema deve preservar o conteúdo do vídeo original após a operação.")], [#text(hyphenate: true, "Fiabilidade / integridade")], [#text(hyphenate: true, "Original não sobrescrito, com identificador distinto para o resultado.")], [N/D], [#text(hyphenate: true, "UC-VID-005 — RN7; DQ-002")], [#text(hyphenate: true, "Dado o hash SHA-256 do original, quando uma transformação termina, então o original conserva o mesmo hash. Ensaiar sucesso e caminhos de erro aplicáveis.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-021")], [#text(hyphenate: true, "O sistema deve impedir que um output parcial ou cujo registo falhou seja apresentado na biblioteca como resultado final bem-sucedido.")], [#text(hyphenate: true, "Fiabilidade / consistência")], [#text(hyphenate: true, "Ausência de associação de resultado falhado ou parcial; preservação do original verificada em REQ-VID-SPEED-020.")], [N/D], [#text(hyphenate: true, "UC-VID-005 — EX1; EX6–7; garantia mínima; DQ-002")], [#text(hyphenate: true, "Dada falha controlada de processamento ou associação, quando se consulta o projeto, então o original continua associado e não há um novo resultado parcial apresentado como sucesso.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-034")], [#text(hyphenate: true, "O sistema deve limpar os ficheiros de trabalho locais nas saídas controladas do worker e, no tratamento de um resultado de sucesso cuja associação falha, tentar remover o output confirmado como não associado.")], [#text(hyphenate: true, "Fiabilidade / gestão de recursos")], [#text(hyphenate: true, "Limpeza local em sucesso/exceção controlada; tentativa de remoção remota apenas no rollback da associação de um resultado de sucesso, com confirmação de ausência de associação.")], [N/D], [#text(hyphenate: true, "UC-VID-005 — EX4; EX6–7; DQ-006")], [#text(hyphenate: true, "Dada conclusão ou exceção controlada, o diretório temporário é limpo. Dado um resultado de sucesso não associado, o rollback tenta remover o output e libertar a reserva; uma falha de DELETE não impede a tentativa de release. Resultados status error são apenas registados.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-035")], [#text(hyphenate: true, "O sistema deve manter os controlos de acesso existentes nas operações usadas para obter o original e publicar o resultado.")], [#text(hyphenate: true, "Segurança / controlo de acesso")], [#text(hyphenate: true, "Autorização do projeto na API e acesso interno ao storage pelo mecanismo existente, sem expor a chave interna no frontend.")], [N/D], [#text(hyphenate: true, "UC-VID-005 — RN10; DQ-003")], [#text(hyphenate: true, "Dado um pedido sem autorização ou sem chave interna válida, quando tenta usar o respetivo endpoint protegido, então não obtém acesso autorizado; complementar com ensaios de partilha e ausência de sessão.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-036")], [#text(hyphenate: true, "O sistema deve aceitar uma submissão válida sem aguardar a conclusão da transformação do vídeo.")], [#text(hyphenate: true, "Eficiência / interação assíncrona")], [#text(hyphenate: true, "Aceitação independente da conclusão do worker; nenhum tempo máximo numérico é assumido.")], [N/D], [#text(hyphenate: true, "UC-VID-005 — Passos 8–10; DQ-001")], [#text(hyphenate: true, "Dada uma tarefa cujo processamento ainda não terminou, quando a submissão é aceite, então o cliente recebe a aceitação sem ter de aguardar o resultado final.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-037")], [#text(hyphenate: true, "A extensão de speed deve preservar os fluxos existentes de upload, trim e biblioteca do projeto.")], [#text(hyphenate: true, "Compatibilidade / manutenibilidade")], [#text(hyphenate: true, "Integração nos serviços e contratos existentes, com regressão dos percursos abrangidos pelos testes.")], [N/D], [#text(hyphenate: true, "UC-VID-005 — Fronteira do UC; DQ-006")], [#text(hyphenate: true, "Dados os fluxos existentes, quando se executam os testes de regressão após integrar speed, então os cenários de upload, trim e navegação abrangidos continuam utilizáveis; não se presume cobertura de toda a aplicação.")],
    
  ),
)
]

== Verificação da completude e dos limites do âmbito

#orientacao[
  Cada tópico aparece uma vez e reúne os casos de uso a que se aplica. A coluna *Requisito(s)* aponta para os
  requisitos que sustentam a decisão; uma política ainda por decidir é assinalada no texto.
]

#tab([Verificação da completude],
  tabela(
    colunas: (4.2cm, 2cm, 1.5cm, 1fr, 4.2cm),
    tamanho: 8.5pt,
    [Tópico a verificar], [Caso(s) de uso], [Aplicável?], [Decisão / justificação], [Requisito(s)],

    [Formato, _codec_ e limites], [UC-VID-001–005], [Sim],
    [O upload valida MP4/H.264 e o tamanho por ficheiro. Trim limita o excerto a 180 s/60 min; remoção exige pelo menos 1 s de resultado e não herda esse limite de duração; compilação admite 2 a 10 vídeos e duração total de 10 min/1 h; speed aceita 0,5x, 1x ou 2x em intervalos válidos. A saída usa AAC quando há áudio, sem exigir AAC em toda a entrada.],
    [REQ-VID-UPL-009–013; REQ-VID-TRIM-004, REQ-VID-TRIM-006, REQ-VID-TRIM-012; REQ-VID-REM-002–003, REQ-VID-REM-011, REQ-VID-REM-026; REQ-VID-COMP-002, REQ-VID-COMP-014, REQ-VID-COMP-020; REQ-VID-SPEED-003, REQ-VID-SPEED-005–006, REQ-VID-SPEED-017–018, REQ-VID-SPEED-022–025, REQ-VID-SPEED-030],

    [Seleção, ordem e âmbito], [UC-VID-002–005], [Sim],
    [Trim e remoção selecionam um intervalo de um vídeo; compilação seleciona vídeos do mesmo projeto e respeita a ordem definida; speed admite vários intervalos de um só vídeo. Cada pedido inicia uma operação individual; não há encadeamento automático nem processamento em lote de pedidos.],
    [REQ-VID-TRIM-001–004; REQ-VID-REM-001–002, REQ-VID-REM-005; REQ-VID-COMP-001–003, REQ-VID-COMP-008, REQ-VID-COMP-013; REQ-VID-SPEED-002, REQ-VID-SPEED-004, REQ-VID-SPEED-026–027],

    [Estado, progresso e cancelamento], [UC-VID-001–005], [Parcialmente],
    [O upload mostra envio, sucesso ou falha, sem percentagem e sem cancelamento após iniciar a transferência. Trim e compilação permitem consultar estado/progresso e cancelar tarefas em fila ou execução. A interface de remoção também apresenta progresso e botão de cancelamento após a submissão, embora os seus requisitos atuais só descrevam desistência antes de «Aplicar». Speed confirma a aceitação assíncrona, mas ainda não oferece acompanhamento persistente nem cancelamento após submeter.],
    [REQ-VID-UPL-015, REQ-VID-UPL-018–019, REQ-VID-UPL-033, REQ-VID-UPL-036; REQ-VID-TRIM-008–009, REQ-VID-TRIM-022, REQ-VID-TRIM-029–030; REQ-VID-REM-013–015, REQ-VID-REM-022; REQ-VID-COMP-007, REQ-VID-COMP-009, REQ-VID-COMP-018; REQ-VID-SPEED-008–009, REQ-VID-SPEED-013, REQ-VID-SPEED-016],

    [Falhas e integridade do resultado], [UC-VID-001–005], [Sim],
    [Falhas no upload não tornam o vídeo disponível. As edições preservam os originais e não publicam resultados parciais. Trim, remoção e compilação estornam a operação reservada em falha definitiva; trim e compilação também a estornam ao cancelar. Speed tenta limpar saídas não associadas nas falhas controladas, sem garantir recuperação distribuída ou notificação terminal na interface.],
    [REQ-VID-UPL-025–029, REQ-VID-UPL-031, REQ-VID-UPL-037–038; REQ-VID-TRIM-013, REQ-VID-TRIM-016–018, REQ-VID-TRIM-034–035; REQ-VID-REM-006–007, REQ-VID-REM-020, REQ-VID-REM-023; REQ-VID-COMP-012, REQ-VID-COMP-015–017; REQ-VID-SPEED-020–021, REQ-VID-SPEED-031–034, REQ-VID-SPEED-038],

    [Persistência, armazenamento e retenção], [UC-VID-001–005], [Parcialmente],
    [O upload guarda o vídeo e a sua referência; as edições bem-sucedidas criam resultados no projeto sem substituir os originais. O tamanho real dos resultados conta para a quota acumulada do proprietário (1 GB Free; 5 GB Premium). Não há política geral aprovada de expiração automática; as propostas de retenção de trim, remoção e compilação continuam sujeitas a decisão.],
    [REQ-VID-UPL-012–013, REQ-VID-UPL-016–017; REQ-VID-TRIM-013–014, REQ-VID-TRIM-021, REQ-VID-TRIM-023; REQ-VID-REM-006, REQ-VID-REM-017; REQ-VID-COMP-006, REQ-VID-COMP-011, REQ-VID-COMP-022; REQ-VID-SPEED-014–015, REQ-VID-SPEED-019, REQ-VID-SPEED-031–032],

    [Perfis, permissões e quota diária], [UC-VID-001–005], [Parcialmente],
    [As operações exigem sessão e permissão de edição. O upload não tem quota diária por número de envios. Trim, remoção e compilação reservam uma operação por tarefa no perfil Free, com limite de 5 por dia; Premium não tem limite diário. Speed ainda não verifica nem consome operações diárias e essa política permanece por decidir.],
    [REQ-VID-UPL-007–008, REQ-VID-UPL-032; REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-019, REQ-VID-TRIM-034; REQ-VID-REM-010, REQ-VID-REM-018–020; REQ-VID-COMP-005, REQ-VID-COMP-021; REQ-VID-SPEED-028–029, REQ-VID-SPEED-035; UC-VID-005/Q2],
  ),
)
