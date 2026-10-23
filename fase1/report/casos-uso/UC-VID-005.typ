#import "../template.typ": *

#pagebreak(weak: true)

== UC-VID-005 — Modificar a velocidade de um vídeo

O utilizador aplica 0,5x, 1x ou 2x a intervalos não sobrepostos de um vídeo já associado ao projeto. As partes não selecionadas mantêm a escala temporal 1x; o resultado é independente do original. O carregamento, o recorte e a remoção de segmento pertencem aos respetivos casos de uso.

=== Cabeçalho

#tab([#text(hyphenate: true, "UC-VID-005 — Cabeçalho")],
  tabela(
    colunas: (3.4cm, 1fr),
    tamanho: 8.5pt,
    [#text(hyphenate: true, "Secção")], [#text(hyphenate: true, "Detalhes")],

    [#text(hyphenate: true, "ID do Caso de Uso")], [#text(hyphenate: true, "UC-VID-005")],

    [#text(hyphenate: true, "Nome")], [#text(hyphenate: true, "Modificar a velocidade de um vídeo")],

    [#text(hyphenate: true, "Versão")], [#text(hyphenate: true, "v3.0;")],

    [#text(hyphenate: true, "Autor")], [#text(hyphenate: true, "Nuno Sá")],

    [#text(hyphenate: true, "Data")], [#text(hyphenate: true, "2026-10-22")],

    [#text(hyphenate: true, "Objetivo")], [#text(hyphenate: true, "Aplicar velocidades a um ou vários intervalos não sobrepostos do mesmo vídeo, conservar a ordem temporal e a velocidade das partes não selecionadas e ajustar o áudio, produzindo um novo vídeo.")],

    [#text(hyphenate: true, "Âmbito")], [#text(hyphenate: true, "Edição de vídeo no PictuRAS; interface do projeto, submissão assíncrona, processamento e registo do resultado.")],

    [#text(hyphenate: true, "Ator principal")], [#text(hyphenate: true, "Utilizador registado com permissão de edição no projeto.")],

    [#text(hyphenate: true, "Stakeholders e interesses")], [#text(hyphenate: true, "Utilizador: obter um resultado correto sem perder o original. Proprietário do projeto: controlar acesso e utilização do armazenamento. Equipa de desenvolvimento/operações: reutilizar os serviços existentes e identificar falhas sem expor resultados incompletos.")],

    [#text(hyphenate: true, "Pré-condições")], [#text(hyphenate: true, "Sessão válida; projeto acessível com edição; vídeo associado ao projeto e armazenado num formato suportado. A aceitação final do resultado depende da quota de armazenamento do proprietário; não pressupõe quota diária de operações para speed.")],

    [#text(hyphenate: true, "Trigger")], [#text(hyphenate: true, "O utilizador escolhe um vídeo e abre a ação Modificar velocidade.")],
  ),
)

=== Fluxo principal

#tab([#text(hyphenate: true, "UC-VID-005 — Fluxo principal")],
  tabela(
    colunas: (1cm, 1fr, 1fr),
    tamanho: 8.5pt,
    [#text(hyphenate: true, "Passo")], [#text(hyphenate: true, "Ação do ator")], [#text(hyphenate: true, "Resposta do sistema")],

    [#text(hyphenate: true, "1")], [#text(hyphenate: true, "Abre o projeto e seleciona um vídeo existente.")], [#text(hyphenate: true, "Apresenta o vídeo selecionado na biblioteca do projeto.")],

    [#text(hyphenate: true, "2")], [#text(hyphenate: true, "Escolhe Modificar velocidade.")], [#text(hyphenate: true, "Abre o diálogo com o vídeo original, obtém a duração e apresenta os controlos de início, fim e velocidade.")],

    [#text(hyphenate: true, "3")], [#text(hyphenate: true, "Define os instantes inicial e final de um intervalo.")], [#text(hyphenate: true, "Atualiza os campos e a seleção temporal; permite ajustar os valores antes de enviar.")],

    [#text(hyphenate: true, "4")], [#text(hyphenate: true, "Escolhe 0,5x, 1x ou 2x.")], [#text(hyphenate: true, "Associa a velocidade ao intervalo, sem gerar um preview do vídeo transformado.")],

    [#text(hyphenate: true, "5")], [#text(hyphenate: true, "Adiciona outros intervalos, se necessário, e edita ou remove os existentes.")], [#text(hyphenate: true, "Mantém uma lista dos intervalos configurados e das respetivas velocidades.")],

    [#text(hyphenate: true, "6")], [#text(hyphenate: true, "Revê a configuração.")], [#text(hyphenate: true, "Valida lista não vazia, números finitos, limites temporais, velocidades permitidas e ausência de sobreposição; sinaliza os erros.")],

    [#text(hyphenate: true, "7")], [#text(hyphenate: true, "Consulta o resumo visível no diálogo.")], [#text(hyphenate: true, "Apresenta os tempos e a velocidade de cada intervalo antes da submissão. Não exige uma segunda caixa de confirmação.")],

    [#text(hyphenate: true, "8")], [#text(hyphenate: true, "Clica em Processar.")], [#text(hyphenate: true, "Verifica sessão, permissão, versão do projeto e associação do vídeo; valida os parâmetros do pedido e encaminha a operação para processamento assíncrono.")],

    [#text(hyphenate: true, "9")], [#text(hyphenate: true, "—")], [#text(hyphenate: true, "Confirma a aceitação do pedido e informa que o novo vídeo aparecerá na biblioteca quando o processamento terminar. A aceitação não equivale à conclusão.")],

    [#text(hyphenate: true, "10")], [#text(hyphenate: true, "—")], [#text(hyphenate: true, "Obtém o vídeo original, confirma formato/codec e duração real e processa os intervalos por ordem temporal, mantendo as partes não selecionadas a 1x.")],

    [#text(hyphenate: true, "11")], [#text(hyphenate: true, "—")], [#text(hyphenate: true, "Ajusta o áudio existente proporcionalmente à velocidade de cada segmento e concatena os segmentos. Na ausência de áudio, processa apenas vídeo.")],

    [#text(hyphenate: true, "12")], [#text(hyphenate: true, "—")], [#text(hyphenate: true, "Produz e transfere o novo MP4 e comunica o resultado ao serviço responsável pelo projeto. Não apresenta progresso percentual no MVP.")],

    [#text(hyphenate: true, "13")], [#text(hyphenate: true, "—")], [#text(hyphenate: true, "Reserva o tamanho real do resultado na quota do proprietário, associa o vídeo se houver espaço, incrementa a versão do projeto, confirma a contabilização e atualiza a biblioteca.")],
  ),
)

A validação é distribuída: a interface usa a duração do vídeo, Projects valida a estrutura, os valores e a sobreposição, e o worker verifica a duração real. Um pedido direto pode receber HTTP 202 e ser rejeitado mais tarde pelo worker por ultrapassar essa duração.

O output é enviado ao armazenamento antes da reserva da quota em Projects. Se a quota impedir a associação, o resultado não entra na biblioteca e é tentada a eliminação do output; o original não é removido.

=== Fluxos alternativos

#tab([#text(hyphenate: true, "UC-VID-005 — Fluxos alternativos")],
  tabela(
    colunas: (4.2cm, 1fr),
    tamanho: 8.5pt,
    [#text(hyphenate: true, "Fluxo")], [#text(hyphenate: true, "Descrição e âmbito")],

    [#text(hyphenate: true, "FA1 — Vários intervalos")], [#text(hyphenate: true, "Nos passos 3 a 5, o utilizador configura várias alterações no mesmo vídeo. Cada intervalo conserva a sua velocidade; a ordem de introdução não altera a ordem temporal do resultado.")],

    [#text(hyphenate: true, "FA2 — Velocidade original")], [#text(hyphenate: true, "No passo 4, escolhe 1x. O segmento mantém a sua escala temporal e a velocidade do áudio. Isto não significa cópia binária dos streams: a saída pode ser recodificada.")],

    [#text(hyphenate: true, "FA3 — Edição e remoção da configuração")], [#text(hyphenate: true, "Antes do passo 8, o utilizador edita tempos ou velocidade ou remove um intervalo. A lista e a validação são recalculadas. Se remover todos, não pode submeter até adicionar um intervalo válido.")],

    [#text(hyphenate: true, "FA4 — Cancelamento de pedido em fila, evolução futura")], [#text(hyphenate: true, "A intenção da baseline é conservada, mas não integra o MVP implementado. Uma futura versão poderá impedir a execução de um pedido ainda em fila; o comportamento e a verificação dependem de uma decisão sobre gestão de tarefas. Não existe cancelamento de speed após submissão.")],

    [#text(hyphenate: true, "FA5 — Vídeo sem áudio")], [#text(hyphenate: true, "No passo 11, não existe stream de áudio. O resultado continua sem áudio; não é acrescentada uma faixa artificial.")],

    [#text(hyphenate: true, "FA6 — Desistência antes da submissão")], [#text(hyphenate: true, "Antes do passo 8, o utilizador fecha o diálogo ou escolhe Cancelar. Não é criada uma tarefa de processamento.")],

    [#text(hyphenate: true, "FA7 — Acesso por partilha com edição")], [#text(hyphenate: true, "Um utilizador diferente do proprietário abre o projeto através de uma partilha válida com edição. A autoria do resultado identifica o chamador; o armazenamento é contabilizado na conta do proprietário.")],
  ),
)

#pagebreak(weak: true)

=== Exceções

#tab([#text(hyphenate: true, "UC-VID-005 — Exceções")],
  tabela(
    colunas: (1.1cm, 4.2cm, 1fr),
    tamanho: 8.5pt,
    [#text(hyphenate: true, "ID")], [#text(hyphenate: true, "Condição")], [#text(hyphenate: true, "Comportamento e estado de implementação")],

    [#text(hyphenate: true, "EX1")], [#text(hyphenate: true, "MP4 inválido, codec de vídeo diferente de H.264, ausência de vídeo ou duração inválida.")], [#text(hyphenate: true, "O worker rejeita o processamento; não é associado um resultado final. A falha assíncrona é registada no backend. A notificação final desse erro na interface é evolução futura.")],

    [#text(hyphenate: true, "EX2")], [#text(hyphenate: true, "Tempos não finitos, início negativo ou fim igual/anterior ao início.")], [#text(hyphenate: true, "A configuração é rejeitada na interface e no pedido; o utilizador corrige os valores antes de submeter.")],

    [#text(hyphenate: true, "EX3")], [#text(hyphenate: true, "Intervalos sobrepostos.")], [#text(hyphenate: true, "A interface sinaliza os intervalos em conflito; a API e o worker rejeitam a configuração. Intervalos apenas adjacentes são permitidos.")],

    [#text(hyphenate: true, "EX4")], [#text(hyphenate: true, "Espaço insuficiente para o tamanho real do output.")], [#text(hyphenate: true, "O resultado não é associado, a versão do projeto não muda e não é emitido add-video. São tentadas a limpeza do output não associado e a libertação da reserva. O erro de quota fica registado; não existe alerta terminal específico de speed na interface.")],

    [#text(hyphenate: true, "EX5")], [#text(hyphenate: true, "Quota diária de operações alegadamente esgotada.")], [#text(hyphenate: true, "A baseline mencionava este bloqueio, mas a regra de contabilização de speed não foi decidida. Não é uma exceção ativa do MVP, nem se afirma verificação, débito ou estorno de operações diárias nesta funcionalidade.")],

    [#text(hyphenate: true, "EX6")], [#text(hyphenate: true, "Falha de leitura, processamento, rede, upload do output ou associação ao projeto.")], [#text(hyphenate: true, "Não é apresentado um resultado parcial como sucesso. Quando Projects recebe um resultado com status error, apenas regista a falha; esse ramo não elimina outputs nem executa release. Quando recebe sucesso mas a quota ou a associação impedem o registo, tenta remover o output e libertar a reserva apenas após confirmar que o vídeo não está associado. Um vídeo já associado mantém os bytes contabilizados, mesmo se commit falhar. A falha na comunicação do resultado após o upload pode deixar um output órfão; não existe recolha automática garantida. Falhas persistentes exigem recuperação operacional.")],

    [#text(hyphenate: true, "EX7")], [#text(hyphenate: true, "Falha no ajuste do áudio.")], [#text(hyphenate: true, "O processamento termina em erro, o original é preservado e não se associa um resultado parcial. A falha é registada no backend.")],

    [#text(hyphenate: true, "EX8")], [#text(hyphenate: true, "Sessão ausente/expirada ou falta de permissão de edição.")], [#text(hyphenate: true, "O pedido é recusado; a interface apresenta uma mensagem de sessão/permissão. Uma partilha apenas de leitura não autoriza a operação.")],

    [#text(hyphenate: true, "EX9")], [#text(hyphenate: true, "Versão do projeto ausente/inválida ou desatualizada.")], [#text(hyphenate: true, "A submissão é recusada, respetivamente com 428 ou 409. A interface permite atualizar/rever os dados e repetir o pedido.")],

    [#text(hyphenate: true, "EX10")], [#text(hyphenate: true, "Lista vazia, campos inválidos ou velocidade não permitida.")], [#text(hyphenate: true, "O pedido é recusado; não é publicado um pedido válido de processamento.")],

    [#text(hyphenate: true, "EX11")], [#text(hyphenate: true, "Intervalo ultrapassa a duração do vídeo.")], [#text(hyphenate: true, "A interface bloqueia a submissão. Num pedido direto que contorne essa verificação, o worker recusa o intervalo após obter a duração real.")],

    [#text(hyphenate: true, "EX12")], [#text(hyphenate: true, "Projeto/vídeo inexistente ou referência de armazenamento inconsistente.")], [#text(hyphenate: true, "A API recusa a submissão. Se o projeto desaparecer depois de aceite o pedido, a associação do resultado falha e aplica-se a limpeza prevista em EX6.")],

    [#text(hyphenate: true, "EX13")], [#text(hyphenate: true, "Resultado recebido novamente.")], [#text(hyphenate: true, "Um vídeo já associado não é adicionado outra vez, não incrementa novamente a versão nem duplica os bytes contabilizados. O resultado repetido não deve apagar o vídeo já associado.")],
  ),
)

=== Pós-condições

#tabela(
  colunas: (3.2cm, 1fr),
  tamanho: 8.5pt,
  [#text(hyphenate: true, "Tipo")], [#text(hyphenate: true, "Resultado")],

  [#text(hyphenate: true, "Garantia de sucesso")], [#text(hyphenate: true, "Novo MP4/H.264 associado ao projeto; áudio AAC quando existe áudio na entrada; intervalos transformados, partes não selecionadas a 1x e ordem preservada; original intacto e disponível; tamanho real do output contabilizado na conta do proprietário; versão incrementada e resultado disponível na biblioteca.")],

  [#text(hyphenate: true, "Garantia mínima")], [#text(hyphenate: true, "Original preservado. Um output não associado não é apresentado como resultado final. Uma reserva sem associação é libertada pelo tratamento de falhas controladas; falhas persistentes de infraestrutura são registadas e podem exigir recuperação. Erros de submissão são apresentados na interface; a notificação de falhas assíncronas ao utilizador ainda não está implementada.")],
)

=== Regras de negócio e restrições

#tabela(
  colunas: (1.2cm, 1fr),
  tamanho: 8.5pt,
  [#text(hyphenate: true, "ID")], [#text(hyphenate: true, "Regra")],

  [#text(hyphenate: true, "RN1")], [#text(hyphenate: true, "As únicas velocidades permitidas são 0,5x, 1x e 2x. Velocidade 2x reduz a duração temporal do segmento a metade; 0,5x duplica-a.")],

  [#text(hyphenate: true, "RN2")], [#text(hyphenate: true, "Para cada intervalo, os tempos são números finitos e cumprem 0 <= início < fim <= duração do vídeo. Os intervalos não se sobrepõem; fronteiras adjacentes são válidas.")],

  [#text(hyphenate: true, "RN3")], [#text(hyphenate: true, "As partes não selecionadas mantêm velocidade temporal 1x e conservam a sua posição relativa no vídeo.")],

  [#text(hyphenate: true, "RN4")], [#text(hyphenate: true, "Quando existe áudio, a sua velocidade acompanha a do respetivo segmento. O requisito não implica preservar o tom original nem manter o áudio binariamente idêntico.")],

  [#text(hyphenate: true, "RN5")], [#text(hyphenate: true, "Um intervalo a 1x não muda de velocidade nem de escala temporal; o resultado continua sujeito à codificação de saída definida no MVP.")],

  [#text(hyphenate: true, "RN6")], [#text(hyphenate: true, "O output respeita a quota de armazenamento existente do proprietário: 1 000 000 000 bytes para Free e 5 000 000 000 bytes para Premium. A contabilização usa o tamanho real do resultado; igualdade com o limite é aceite. Não existe nesta versão uma regra de quota diária de operações de speed.")],

  [#text(hyphenate: true, "RN7")], [#text(hyphenate: true, "A operação nunca substitui o original; cria um ficheiro com identificador distinto.")],

  [#text(hyphenate: true, "RN8")], [#text(hyphenate: true, "A submissão exige uma lista não vazia e configuração válida; as verificações dependentes do conteúdo são repetidas pelo worker antes da transformação.")],

  [#text(hyphenate: true, "RN9")], [#text(hyphenate: true, "No MVP, o sistema confirma a aceitação assíncrona e disponibiliza o resultado final na biblioteca. Consulta persistente de estado, progresso contínuo e notificação de erro final permanecem evoluções futuras.")],

  [#text(hyphenate: true, "RN10")], [#text(hyphenate: true, "O acesso à operação exige sessão válida e permissão de edição no projeto; ter apenas leitura não é suficiente.")],

  [#text(hyphenate: true, "RN11")], [#text(hyphenate: true, "A entrada deve ser MP4/H.264; a saída é MP4/H.264, com áudio AAC se a entrada tiver áudio, ou sem áudio se não tiver. Não se exige AAC como codec de entrada do áudio.")],

  [#text(hyphenate: true, "RN12")], [#text(hyphenate: true, "Não se impõem em speed os limites de duração ou o intervalo mínimo específicos de trim. A política de precisão para conteúdos gerais permanece em aberto; a seleção deve respeitar os limites temporais válidos.")],

  [#text(hyphenate: true, "RN13")], [#text(hyphenate: true, "A associação bem-sucedida de um novo resultado incrementa a versão do projeto uma vez. Repetir a mesma mensagem não deve duplicar o vídeo nem a contabilização.")],
)

=== Assunções

#tabela(
  colunas: (1.2cm, 1fr),
  tamanho: 8.5pt,
  [#text(hyphenate: true, "ID")], [#text(hyphenate: true, "Assunção")],

  [#text(hyphenate: true, "A1")], [#text(hyphenate: true, "O âmbito de utilização considerado é o de utilizadores registados Free/Premium com sessão válida; as permissões do projeto continuam aplicáveis.")],

  [#text(hyphenate: true, "A2")], [#text(hyphenate: true, "O vídeo de entrada já foi carregado e associado ao projeto; este UC não substitui a validação do upload.")],

  [#text(hyphenate: true, "A3")], [#text(hyphenate: true, "Estão disponíveis a infraestrutura assíncrona, o armazenamento de media e a persistência do projeto. A indisponibilidade não equivale a processamento concluído.")],

  [#text(hyphenate: true, "A4")], [#text(hyphenate: true, "É possível obter a duração de um stream de vídeo válido e endereçar segmentos em segundos. Uma precisão universal de corte não se considera demonstrada para todos os vídeos.")],

  [#text(hyphenate: true, "A5")], [#text(hyphenate: true, "O ambiente de execução dispõe de suporte a MP4/H.264 e aos codecs de áudio aceites para descodificação; FFmpeg e ffprobe são dependências da implementação atual.")],

  [#text(hyphenate: true, "A6")], [#text(hyphenate: true, "O ajuste temporal de áudio/vídeo é verificável nos conteúdos de teste; não se presume validação de toda a combinação possível de timestamps, taxas de fotogramas e durações de streams.")],

  [#text(hyphenate: true, "A7")], [#text(hyphenate: true, "Os intervalos pertencem ao mesmo vídeo e podem ter velocidades diferentes.")],
)

#pagebreak(weak: true)

=== Questões em aberto e decisões

#tabela(
  colunas: (1.1cm, 5cm, 1fr),
  tamanho: 8.5pt,
  [#text(hyphenate: true, "ID")], [#text(hyphenate: true, "Questão original / refinada")], [#text(hyphenate: true, "Estado nesta revisão")],

  [#text(hyphenate: true, "Q1")], [#text(hyphenate: true, "Que limites de duração e tamanho se aplicam por perfil?")], [#text(hyphenate: true, "Parcialmente resolvida: a quota de armazenamento de RN6 é conhecida. Não se definiu um limite adicional de duração de speed; não se copiam os 180 s/60 min nem o mínimo de 1 s do trim.")],

  [#text(hyphenate: true, "Q2")], [#text(hyphenate: true, "Um vídeo conta como uma operação diária, independentemente do número de intervalos?")], [#text(hyphenate: true, "Em aberto. Speed não consulta, debita nem repõe saldo diário de operações. Definir a política com a equipa antes de a especificar como comportamento ativo.")],

  [#text(hyphenate: true, "Q3")], [#text(hyphenate: true, "Cancelamento apenas em fila ou também em execução?")], [#text(hyphenate: true, "No MVP apenas se desiste antes de enviar (FA6). O cancelamento de um pedido em fila é intenção futura preservada em REQ-VID-SPEED-016; o cancelamento em execução permanece sem decisão.")],

  [#text(hyphenate: true, "Q4")], [#text(hyphenate: true, "Apresentar estimativa da duração do resultado antes de submeter?")], [#text(hyphenate: true, "Em aberto para evolução futura. A fórmula da tabela de duração de UC-VID-005 no capítulo de testes serve para verificação, não significa que exista uma estimativa na interface.")],

  [#text(hyphenate: true, "Q5")], [#text(hyphenate: true, "Qual a precisão mínima da seleção temporal?")], [#text(hyphenate: true, "Parcialmente caracterizada: slider atual com passo de 0,1 s e campos numéricos sem passo fixo. Isto não garante precisão universal do output; falta definir uma tolerância por classe de conteúdo.")],

  [#text(hyphenate: true, "Q6")], [#text(hyphenate: true, "Preview do vídeo transformado antes do processamento completo?")], [#text(hyphenate: true, "Fora do MVP atual. O diálogo reproduz o original, não o resultado transformado.")],

  [#text(hyphenate: true, "Q7")], [#text(hyphenate: true, "Que metas de latência, tempo de processamento e concorrência devem ser exigidas?")], [#text(hyphenate: true, "Em aberto. Faltam ambiente de referência, resolução, duração, número de intervalos e carga; não se inventam percentis nem limites temporais.")],

  [#text(hyphenate: true, "Q8")], [#text(hyphenate: true, "Como recuperar falhas persistentes e reconciliar contabilização histórica?")], [#text(hyphenate: true, "Em aberto para robustez operacional. Não há transação distribuída nem reconciliação automática dos resultados anteriores à correção de quota; não se presume entrega exatamente uma vez de ponta a ponta.")],
)
