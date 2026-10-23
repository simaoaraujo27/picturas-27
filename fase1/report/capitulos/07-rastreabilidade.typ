#import "../template.typ": *

= Rastreabilidade

== Casos de uso $->$ requisitos

#orientacao[
  Cada elemento relevante de cada caso de uso (passos, FA, exceções, RN, pós-condições) tem pelo menos um
  requisito, ou justificação para não ter; nenhum requisito da ERS fica órfão. Requisitos de qualidade podem
  apontar para uma decisão de qualidade (DQ). Indiquem sempre o caso de uso no elemento de origem.
]

#tab([Matriz de rastreabilidade: casos de uso $->$ requisitos],
  tabela(
    colunas: (4.2cm, 1fr, 4.2cm),
    tamanho: 8.5pt,
    [Elemento de origem], [Descrição abreviada], [Requisito(s)],

    [UC-VID-001, Objetivo; Pré-condições; Trigger], [Contexto do carregamento e acesso ao projeto; as obrigações operacionais estão nos passos e em RN1.], [REQ-VID-UPL-001, REQ-VID-UPL-007, REQ-VID-UPL-008, REQ-VID-UPL-019],
    [UC-VID-001, Passo 1], [Abrir a opção de seleção.], [REQ-VID-UPL-001],
    [UC-VID-001, Passo 2], [Selecionar um único ficheiro pelo seletor, mostrar nome e tamanho, validar tipo declarado.], [REQ-VID-UPL-002, REQ-VID-UPL-003, REQ-VID-UPL-004, REQ-VID-UPL-005],
    [UC-VID-001, Passo 3], [Confirmar, validar sessão e autorização, verificar o limite de tamanho e a ausência de vídeo com o mesmo nome completo no projeto.], [REQ-VID-UPL-006, REQ-VID-UPL-007, REQ-VID-UPL-008, REQ-VID-UPL-012, REQ-VID-UPL-013, REQ-VID-UPL-014, REQ-VID-UPL-028, REQ-VID-UPL-039],
    [UC-VID-001, Passo 4], [Transferir o ficheiro e indicar operação em curso.], [REQ-VID-UPL-014, REQ-VID-UPL-015, REQ-VID-UPL-030],
    [UC-VID-001, Passo 5], [Após a receção, validar definitivamente conteúdo MP4 e codec H.264; armazenar o vídeo validado.], [REQ-VID-UPL-009, REQ-VID-UPL-010, REQ-VID-UPL-011, REQ-VID-UPL-016, REQ-VID-UPL-017, REQ-VID-UPL-018, REQ-VID-UPL-026, REQ-VID-UPL-027],
    [UC-VID-001, Passo 6], [Associar vídeo ao utilizador e referência persistente ao projeto existente.], [REQ-VID-UPL-016, REQ-VID-UPL-017],
    [UC-VID-001, Passo 7], [Confirmar conclusão e identificar vídeo disponível para processamento após transferência, validação, armazenamento e associação bem-sucedidos.], [REQ-VID-UPL-018, REQ-VID-UPL-019, REQ-VID-UPL-029],
    [UC-VID-001, FA2], [Desistir antes de confirmar.], [REQ-VID-UPL-036],
    [UC-VID-001, Exceção: tipo/formato declarado], [Recusa preliminar e informação ao utilizador.], [REQ-VID-UPL-005, REQ-VID-UPL-021],
    [UC-VID-001, Exceção: limite de tamanho], [Recusa e informação segundo o plano.], [REQ-VID-UPL-012, REQ-VID-UPL-013, REQ-VID-UPL-022],
    [UC-VID-001, Exceção: sessão ou autorização], [Recusa e informação sobre o acesso.], [REQ-VID-UPL-007, REQ-VID-UPL-008, REQ-VID-UPL-023, REQ-VID-UPL-024],
    [UC-VID-001, Exceção: nome repetido], [No fluxo normal da interface, recusa na pré-validação antes do pedido de upload e indicação para alterar o nome do ficheiro.], [REQ-VID-UPL-028],
    [UC-VID-001, Exceção: versão desatualizada], [Recusa do pedido, atualização dos dados do projeto e indicação para repetir a operação.], [REQ-VID-UPL-017–018, REQ-VID-UPL-039–041],
    [UC-VID-001, Exceção: interrupção do envio], [Informação sobre a falha; vídeo não associado nem disponível.], [REQ-VID-UPL-025, REQ-VID-UPL-029, REQ-VID-UPL-031],
    [UC-VID-001, Exceção: conteúdo inválido ou codec diferente de H.264], [Recusa após a receção, informação ao utilizador e ausência de associação e disponibilidade.], [REQ-VID-UPL-009, REQ-VID-UPL-010, REQ-VID-UPL-011, REQ-VID-UPL-016, REQ-VID-UPL-017, REQ-VID-UPL-026, REQ-VID-UPL-027, REQ-VID-UPL-029],
    [UC-VID-001, Exceção: falha no armazenamento], [Informação sobre a falha; vídeo não associado nem disponível.], [REQ-VID-UPL-016–018, REQ-VID-UPL-029, REQ-VID-UPL-031, REQ-VID-UPL-037],
    [UC-VID-001, Exceção: falha na associação], [Informação sobre a falha; vídeo não apresentado como disponível.], [REQ-VID-UPL-017–018, REQ-VID-UPL-029, REQ-VID-UPL-038],
    [UC-VID-001, Garantia de Sucesso], [Vídeo armazenado, associado e disponível para processamento por referência persistente; o ficheiro de origem não é alterado.], [REQ-VID-UPL-016, REQ-VID-UPL-017, REQ-VID-UPL-018, REQ-VID-UPL-019, REQ-VID-UPL-029],
    [UC-VID-001, Garantia Mínima], [Após falha, o vídeo não fica associado como disponível; o ficheiro de origem não é alterado.], [REQ-VID-UPL-025, REQ-VID-UPL-029, REQ-VID-UPL-037–038],
    [UC-VID-001, RN1], [Autorização para carregar.], [REQ-VID-UPL-007, REQ-VID-UPL-008],
    [UC-VID-001, RN2], [Formato, codec, conteúdo real e limites por plano.], [REQ-VID-UPL-005, REQ-VID-UPL-009, REQ-VID-UPL-010, REQ-VID-UPL-011, REQ-VID-UPL-012, REQ-VID-UPL-013],
    [UC-VID-001, RN3], [Associação ao utilizador e ao projeto.], [REQ-VID-UPL-016, REQ-VID-UPL-017],
    [UC-VID-001, RN4], [Disponibilidade só após transferência, validação, armazenamento e associação bem-sucedidos.], [REQ-VID-UPL-029],
    [UC-VID-001, RN5], [Eficiência de memória durante a transferência de vídeos.], [REQ-VID-UPL-030],
    [UC-VID-001, RN6], [Recusa de novo carregamento quando já existe no projeto um vídeo com o mesmo nome completo.], [REQ-VID-UPL-028],
    [RNG-01], [Autenticação obrigatória para UC-VID-001 e UC-VID-002.], [REQ-VID-UPL-007, REQ-VID-TRIM-019],
    [RNG-02], [Contentor MP4 e codec de vídeo H.264 em UC-VID-001 e UC-VID-002.], [REQ-VID-UPL-010–011, REQ-VID-TRIM-012],
    [UC-VID-001, A1], [Premissa confirmada: SeaweedFS armazena o MP4 e MongoDB mantém a referência no projeto; não estabelece comportamento adicional a exigir.], [Não origina requisito autónomo; relacionada com REQ-VID-UPL-016, REQ-VID-UPL-017.],
    [UC-VID-001 / DQ-001], [Transferência progressiva sem cópia integral em RAM e com pico máximo de 1 000 000 000 bytes por upload.], [REQ-VID-UPL-030],
    [UC-VID-001 / DQ-002], [Falha de upload não expõe vídeo incompleto.], [REQ-VID-UPL-031],
    [UC-VID-001 / DQ-003], [Permissões do projeto abrangem vídeos e projetos partilhados.], [REQ-VID-UPL-032],
    [UC-VID-001 / DQ-004], [Estados de envio, sucesso e falha no MVP; percentagem do upload numa evolução futura.], [REQ-VID-UPL-033],
    [UC-VID-001 / DQ-005], [Convivência e separação estrutural de imagens e vídeos.], [REQ-VID-UPL-034, REQ-VID-UPL-035],
    [UC-VID-002, Âmbito], [Módulo de processamento de vídeo assíncrono em nós isolados], [REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-028],
    [UC-VID-002, Pré-condições], [Autenticação obrigatória, quotas diárias e de disco, formato MP4 e vídeo carregado], [REQ-VID-TRIM-005, REQ-VID-TRIM-012, REQ-VID-TRIM-019, REQ-VID-TRIM-021, REQ-VID-TRIM-034, REQ-VID-TRIM-027],
    [UC-VID-002, Passo 1], [Seleção do vídeo na biblioteca e abertura da ferramenta de recorte], [REQ-VID-TRIM-001, REQ-VID-TRIM-024],
    [UC-VID-002, Passo 2], [Ajuste interativo dos marcadores temporais t_in e t_out na linha temporal], [REQ-VID-TRIM-002],
    [UC-VID-002, Passo 3], [Confirmação da operação e validação de parâmetros, limites e quotas de disco/operações], [REQ-VID-TRIM-004, REQ-VID-TRIM-005, REQ-VID-TRIM-006, REQ-VID-TRIM-021, REQ-VID-TRIM-034],
    [UC-VID-002, Passo 4], [Dedução provisória de quota diária (#raw("free")) e publicação assíncrona na fila], [REQ-VID-TRIM-007, REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-025],
    [UC-VID-002, Passo 5], [Atribuição de Job ID, estado em fila e ecrã de acompanhamento], [REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-009, REQ-VID-TRIM-025],
    [UC-VID-002, Passo 6], [Execução do recorte no worker com FFmpeg e difusão de progresso], [REQ-VID-TRIM-009, REQ-VID-TRIM-010, REQ-VID-TRIM-026],
    [UC-VID-002, Passo 7], [Conclusão do processamento, validação de integridade e guarda com controlo de quota], [REQ-VID-TRIM-012, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-031–033, REQ-VID-TRIM-021, REQ-VID-TRIM-034, REQ-VID-TRIM-024],
    [UC-VID-002, Passo 8], [Notificação de sucesso, download e registo na biblioteca permanente], [REQ-VID-TRIM-014, REQ-VID-TRIM-031–033, REQ-VID-TRIM-027],
    [UC-VID-002, FA1], [Pré-visualização local no browser antes de submeter a tarefa], [REQ-VID-TRIM-003],
    [UC-VID-002, FA2], [Recorte rápido sem recodificação (Stream Copy) para perfil #raw("premium")], [REQ-VID-TRIM-011],
    [UC-VID-002, FA3], [Continuidade do processamento em segundo plano ao fechar o browser], [REQ-VID-TRIM-015],
    [UC-VID-002, FA4], [Bloqueio de utilizadores não autenticados (#raw("anonymous")) com convite a registo], [REQ-VID-TRIM-019],
    [UC-VID-002, FA5], [Cancelamento voluntário da tarefa pelo utilizador em fila ou execução], [REQ-VID-TRIM-022, REQ-VID-TRIM-036–038],
    [UC-VID-002, Exceção 1], [Instantes temporais inválidos (t_in ≥ t_out ou intervalo < 1,0 s)], [REQ-VID-TRIM-004],
    [UC-VID-002, Exceção 2], [Duração do excerto excede o limite do perfil (180s em #raw("free") / 60 min em #raw("premium"))], [REQ-VID-TRIM-006],
    [UC-VID-002, Exceção 3], [Quota diária de operações esgotada no perfil #raw("free") (#raw("FREE_DAILY_OP = 5"))], [REQ-VID-TRIM-005],
    [UC-VID-002, Exceção 4a], [Fluxo incompatível ou corrompido; tarefa falhada e causa apresentada], [REQ-VID-TRIM-016, REQ-VID-TRIM-034–035],
    [UC-VID-002, Exceção 4b], [Quota de armazenamento em disco da conta excedida (1 GB #raw("free") / 5 GB #raw("premium"))], [REQ-VID-TRIM-021, REQ-VID-TRIM-034],
    [UC-VID-002, Exceção 5], [Falha de nó de processamento ou timeout de execução de 10 minutos], [REQ-VID-TRIM-017],
    [UC-VID-002, Pós-condição: Sucesso], [Excerto gerado com sincronismo A/V, original intacto, na biblioteca e auditado], [REQ-VID-TRIM-010, REQ-VID-TRIM-013, REQ-VID-TRIM-014, REQ-VID-TRIM-031–033, REQ-VID-TRIM-020, REQ-VID-TRIM-021],
    [UC-VID-002, Pós-condição: Mínima], [Original intacto, ficheiros temporários purgados e quotas estornadas], [REQ-VID-TRIM-013, REQ-VID-TRIM-016, REQ-VID-TRIM-034–035, REQ-VID-TRIM-017, REQ-VID-TRIM-018, REQ-VID-TRIM-021, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038],
    [UC-VID-002, RN1], [Gestão transacional de quotas diárias de operações (#raw("FREE_DAILY_OP = 5"))], [REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-034–035, REQ-VID-TRIM-017, REQ-VID-TRIM-021, REQ-VID-TRIM-022, REQ-VID-TRIM-036–038],
    [UC-VID-002, RN2], [Limites de duração de excerto por perfil autenticado (180s em #raw("free"), 60 min em #raw("premium"))], [REQ-VID-TRIM-006],
    [UC-VID-002, RN3], [Precisão temporal ao centésimo de segundo e duração mínima de 1.0 s], [REQ-VID-TRIM-002, REQ-VID-TRIM-004],
    [UC-VID-002, RN4], [Formatos e codecs suportados no MVP (contentor MP4 com H.264 e AAC)], [REQ-VID-TRIM-012],
    [UC-VID-002, RN5], [Princípio da não destrutividade do vídeo de origem na biblioteca], [REQ-VID-TRIM-013],
    [UC-VID-002, RN6], [Quotas de armazenamento em disco por perfil (1 GB #raw("free"), 5 GB #raw("premium")) e retenção], [REQ-VID-TRIM-021, REQ-VID-TRIM-034, REQ-VID-TRIM-023, REQ-VID-TRIM-039–040, REQ-VID-TRIM-024],
    [UC-VID-002, RN7], [Autenticação obrigatória para ferramentas de vídeo e bloqueio a anónimos], [REQ-VID-TRIM-019],
    [RNG-01], [Autenticação obrigatória para UC-VID-001 e UC-VID-002], [REQ-VID-UPL-007, REQ-VID-TRIM-019],
    [RNG-02], [Contentor MP4 e codec de vídeo H.264 em UC-VID-001 e UC-VID-002], [REQ-VID-UPL-010–011, REQ-VID-TRIM-012],
    [UC-VID-002, DQ-001], [Desacoplamento assíncrono via filas dedicadas de mensagens e WebSockets], [REQ-VID-TRIM-008, REQ-VID-TRIM-029–030, REQ-VID-TRIM-009, REQ-VID-TRIM-025],
    [UC-VID-002, DQ-002], [Resiliência com repetição idempotente e métricas de débito de processamento], [REQ-VID-TRIM-017, REQ-VID-TRIM-026],
    [UC-VID-002, DQ-003], [Proteção de acesso aos artefactos multimédia e registo de auditoria], [REQ-VID-TRIM-020, REQ-VID-TRIM-027],
    [UC-VID-002, DQ-004], [Isolamento do motor FFmpeg em contentor Docker], [REQ-VID-TRIM-012, REQ-VID-TRIM-028],
    [UC-VID-002, DQ-005], [Retenção efêmera em workers e política de persistência na biblioteca], [REQ-VID-TRIM-018, REQ-VID-TRIM-023, REQ-VID-TRIM-037, REQ-VID-TRIM-039–040],
    [UC-VID-002, DQ-006], [Mecanismo cooperativo de cancelamento ativo pelo utilizador], [REQ-VID-TRIM-022, REQ-VID-TRIM-036–038],

    [UC-VID-004, Objetivo; Pré-condições; Trigger], [Contexto da compilação: sessão iniciada e pelo menos dois vídeos disponíveis na biblioteca.], [REQ-VID-COMP-001, REQ-VID-COMP-002],
    [UC-VID-004, Passo 1], [Apresentar a lista de vídeos.], [REQ-VID-COMP-001],
    [UC-VID-004, Passo 2], [Adicionar dois ou mais vídeos à compilação.], [REQ-VID-COMP-002],
    [UC-VID-004, Passo 3], [Definir a ordem e validar os vídeos selecionados e os limites do perfil.], [REQ-VID-COMP-003, REQ-VID-COMP-004, REQ-VID-COMP-014, REQ-VID-COMP-020],
    [UC-VID-004, Passo 4], [Verificar o espaço de armazenamento e reservar a quota diária.], [REQ-VID-COMP-005, REQ-VID-COMP-006, REQ-VID-COMP-021],
    [UC-VID-004, Passo 5], [Criar a tarefa de processamento.], [REQ-VID-COMP-007],
    [UC-VID-004, Passo 6], [Iniciar a compilação pela ordem escolhida.], [REQ-VID-COMP-008],
    [UC-VID-004, Passo 7], [Atualizar o estado e o progresso.], [REQ-VID-COMP-009, REQ-VID-COMP-018],
    [UC-VID-004, Passo 8], [Gerar o vídeo resultante.], [REQ-VID-COMP-010],
    [UC-VID-004, Passos 9–10], [Reservar armazenamento, guardar o resultado e manter os originais.], [REQ-VID-COMP-006, REQ-VID-COMP-011, REQ-VID-COMP-012],
    [UC-VID-004, FA1], [Alteração da ordem dos vídeos.], [REQ-VID-COMP-003],
    [UC-VID-004, FA2], [Remoção de um vídeo da seleção.], [REQ-VID-COMP-013],
    [UC-VID-004, FA3], [Vídeos com resolução ou _frame rate_ diferentes (normalização).], [REQ-VID-COMP-008, REQ-VID-COMP-NF-005],
    [UC-VID-004, Exceção 1], [Vídeo corrompido ou ilegível.], [REQ-VID-COMP-004, REQ-VID-COMP-015, REQ-VID-COMP-016],
    [UC-VID-004, Exceção 2], [Quota insuficiente.], [REQ-VID-COMP-005],
    [UC-VID-004, Exceção 3], [Armazenamento insuficiente.], [REQ-VID-COMP-006],
    [UC-VID-004, Exceção 4], [Falha durante o processamento.], [REQ-VID-COMP-017],
    [UC-VID-004, Exceção 5], [Tempo limite excedido.], [REQ-VID-COMP-019],
    [UC-VID-004, Exceção 6], [Cancelamento pelo utilizador.], [REQ-VID-COMP-017],
    [UC-VID-004, Exceção 7], [Duração total excedida.], [REQ-VID-COMP-020],
    [UC-VID-004, Exceção 8], [Vídeo que não é MP4/H.264.], [REQ-VID-COMP-014],
    [UC-VID-004, Exceção 9], [Mais de 10 vídeos selecionados.], [REQ-VID-COMP-020],
    [UC-VID-004, Pós-condições], [Vídeo criado e armazenado; sem vídeo incompleto após falha.], [REQ-VID-COMP-010, REQ-VID-COMP-011, REQ-VID-COMP-012, REQ-VID-COMP-017, REQ-VID-COMP-NF-003],
    [UC-VID-004, RN1], [Mínimo de dois vídeos.], [REQ-VID-COMP-002, REQ-VID-COMP-013],
    [UC-VID-004, RN2], [Ordem definida pelo utilizador.], [REQ-VID-COMP-003, REQ-VID-COMP-008],
    [UC-VID-004, RN3], [Vídeos originais inalterados.], [REQ-VID-COMP-012],
    [UC-VID-004, RN4], [Resultado como novo ficheiro na biblioteca.], [REQ-VID-COMP-011],
    [UC-VID-004, RN5], [Quota de processamento necessária (5 operações diárias no `free`).], [REQ-VID-COMP-005, REQ-VID-COMP-021],
    [UC-VID-004, RN6], [Armazenamento necessário (1 GB `free`, 5 GB `premium`).], [REQ-VID-COMP-006],
    [UC-VID-004, RN7], [Mostrar estado e progresso.], [REQ-VID-COMP-009, REQ-VID-COMP-018],
    [UC-VID-004, RN8], [Não disponibilizar vídeo incompleto.], [REQ-VID-COMP-017],
    [UC-VID-004, RN9], [Contentor MP4 e codec H.264 na entrada e na saída.], [REQ-VID-COMP-014, REQ-VID-COMP-NF-005],
    [UC-VID-004, RN10], [Duração total máxima: 10 minutos (`free`) ou 1 hora (`premium`).], [REQ-VID-COMP-020],
    [UC-VID-004, RN11], [Máximo de 10 vídeos por compilação.], [REQ-VID-COMP-020],
    [RNG-03], [Quota, limites de perfil e armazenamento para a compilação.], [REQ-VID-COMP-005, REQ-VID-COMP-006, REQ-VID-COMP-020, REQ-VID-COMP-021],
    [RNG-04], [Originais inalterados; resultado como novo ficheiro, acessível apenas ao proprietário.], [REQ-VID-COMP-011, REQ-VID-COMP-012, REQ-VID-COMP-NF-002],
    [RNG-05], [Compilação assíncrona, com estado consultável e sem resultado incompleto.], [REQ-VID-COMP-007, REQ-VID-COMP-009, REQ-VID-COMP-017, REQ-VID-COMP-019, REQ-VID-COMP-NF-003],
    
    [#text(hyphenate: true, "UC-VID-005 — Objetivo, pré-condições e passos 1–2")], [#text(hyphenate: true, "Abrir a ferramenta sobre um vídeo associado e autorizado.")], [#text(hyphenate: true, "REQ-VID-SPEED-001, REQ-VID-SPEED-028")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 3")], [#text(hyphenate: true, "Parametrizar o intervalo.")], [#text(hyphenate: true, "REQ-VID-SPEED-002")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 4; RN1 e RN5")], [#text(hyphenate: true, "Escolher uma velocidade válida.")], [#text(hyphenate: true, "REQ-VID-SPEED-003")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 5; FA1, FA3 e A7")], [#text(hyphenate: true, "Vários intervalos, edição e remoção.")], [#text(hyphenate: true, "REQ-VID-SPEED-004, REQ-VID-SPEED-026, REQ-VID-SPEED-027")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX2–3, EX10–11; RN2 e RN8")], [#text(hyphenate: true, "Validar configuração e duração.")], [#text(hyphenate: true, "REQ-VID-SPEED-005, REQ-VID-SPEED-006, REQ-VID-SPEED-022, REQ-VID-SPEED-023, REQ-VID-SPEED-024, REQ-VID-SPEED-025")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 7")], [#text(hyphenate: true, "Rever a lista antes de Processar.")], [#text(hyphenate: true, "REQ-VID-SPEED-007")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 8; EX9; DQ-001 e DQ-003")], [#text(hyphenate: true, "Submeter assincronamente com versão e identificadores.")], [#text(hyphenate: true, "REQ-VID-SPEED-008, REQ-VID-SPEED-029, REQ-VID-SPEED-036")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 9; RN9")], [#text(hyphenate: true, "Confirmar aceitação, distinguindo-a da conclusão.")], [#text(hyphenate: true, "REQ-VID-SPEED-009")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 10; FA2; RN1, RN3 e RN5")], [#text(hyphenate: true, "Aplicar velocidades, conservar ordem e partes a 1x.")], [#text(hyphenate: true, "REQ-VID-SPEED-010, REQ-VID-SPEED-011")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 11; FA5; EX7; RN4")], [#text(hyphenate: true, "Ajustar áudio ou manter ausência de áudio.")], [#text(hyphenate: true, "REQ-VID-SPEED-012, REQ-VID-SPEED-017")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 12; RN7 e RN11; DQ-004")], [#text(hyphenate: true, "Guardar um artefacto distinto e compatível.")], [#text(hyphenate: true, "REQ-VID-SPEED-014, REQ-VID-SPEED-030")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 13; EX4 e EX13; RN6 e RN13")], [#text(hyphenate: true, "Associar, contabilizar e atualizar a biblioteca.")], [#text(hyphenate: true, "REQ-VID-SPEED-015, REQ-VID-SPEED-019, REQ-VID-SPEED-031, REQ-VID-SPEED-032")],

    [#text(hyphenate: true, "UC-VID-005 — EX1; RN11; A5")], [#text(hyphenate: true, "Validar a entrada.")], [#text(hyphenate: true, "REQ-VID-SPEED-018")],

    [#text(hyphenate: true, "UC-VID-005 — EX6–7; pós-condições; RN7; DQ-002")], [#text(hyphenate: true, "Preservar original e impedir resultado parcial final.")], [#text(hyphenate: true, "REQ-VID-SPEED-020, REQ-VID-SPEED-021")],

    [#text(hyphenate: true, "UC-VID-005 — EX8; FA7; RN10; DQ-003")], [#text(hyphenate: true, "Respeitar acesso e partilhas.")], [#text(hyphenate: true, "REQ-VID-SPEED-028, REQ-VID-SPEED-035")],

    [#text(hyphenate: true, "UC-VID-005 — Passo 6; EX2–3 e EX8–10")], [#text(hyphenate: true, "Apresentar erros síncronos úteis.")], [#text(hyphenate: true, "REQ-VID-SPEED-033")],

    [#text(hyphenate: true, "UC-VID-005 — EX4, EX6–7; DQ-005 e DQ-006")], [#text(hyphenate: true, "Libertar reservas e limpar recursos nas saídas controladas.")], [#text(hyphenate: true, "REQ-VID-SPEED-031, REQ-VID-SPEED-034")],

    [#text(hyphenate: true, "UC-VID-005 — Fronteira do UC; DQ-006")], [#text(hyphenate: true, "Evitar regressões nas funcionalidades existentes.")], [#text(hyphenate: true, "REQ-VID-SPEED-037")],

    [#text(hyphenate: true, "UC-VID-005 — Intenção de acompanhamento da baseline; RN9")], [#text(hyphenate: true, "Progresso consultável futuro.")], [#text(hyphenate: true, "REQ-VID-SPEED-013")],

    [#text(hyphenate: true, "UC-VID-005 — FA4; Q3")], [#text(hyphenate: true, "Cancelamento de tarefa em fila futuro.")], [#text(hyphenate: true, "REQ-VID-SPEED-016")],

    [#text(hyphenate: true, "UC-VID-005 — Garantia mínima da baseline; EX1, EX4 e EX6–7; DQ-006")], [#text(hyphenate: true, "Notificação terminal de erro futura.")], [#text(hyphenate: true, "REQ-VID-SPEED-038")],

    [#text(hyphenate: true, "UC-VID-005 — FA6")], [#text(hyphenate: true, "Desistir antes de enviar não cria uma tarefa.")], [#text(hyphenate: true, "Fronteira dos REQ-VID-SPEED-008 e REQ-VID-SPEED-016; verificação manual pendente.")],

    [#text(hyphenate: true, "UC-VID-005 — EX5; Q2")], [#text(hyphenate: true, "Quota diária não decidida.")], [#text(hyphenate: true, "Não cria um requisito ativo nem transforma REQ-VID-SPEED-019 em quota de operações.")],

    [#text(hyphenate: true, "UC-VID-005 — A1–A3")], [#text(hyphenate: true, "Contexto de acesso, vídeo previamente associado e infraestrutura disponível.")], [#text(hyphenate: true, "Suportam REQ-VID-SPEED-001, REQ-VID-SPEED-008 e REQ-VID-SPEED-028; não substituem as respetivas verificações.")],

    [#text(hyphenate: true, "UC-VID-005 — A4–A7")], [#text(hyphenate: true, "Medição temporal, suporte técnico, sincronização e intervalos do mesmo vídeo.")], [#text(hyphenate: true, "Relacionam-se com REQ-VID-SPEED-002, REQ-VID-SPEED-004, REQ-VID-SPEED-012, REQ-VID-SPEED-018 e REQ-VID-SPEED-024.")],

    [#text(hyphenate: true, "UC-VID-005 — Q1, Q4–Q8")], [#text(hyphenate: true, "Limites, estimativa, precisão, preview, desempenho e recuperação por decidir.")], [#text(hyphenate: true, "Não introduzem requisitos ativos sem decisão; ver as questões em aberto e a verificação de completude de UC-VID-005.")],
  ),
)

== Decisões de qualidade

#tab([Decisões de qualidade],
  tabela(
    colunas: (1.6cm, 3.8cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [ID], [Decisão de qualidade], [Justificação], [Requisitos],

    [UC-VID-001 / DQ-001],
    [Transferência progressiva sem cópia integral em RAM e pico ≤1 000 000 000 bytes por upload],
    [O corpo é encaminhado com backpressure, escrito temporariamente em disco e enviado ao SeaweedFS em blocos limitados a 2 × 16 MiB. A validação do teto de memória nos limites dos planos e sob concorrência continua pendente; o capítulo de testes menciona apenas um ensaio com 128 000 000 bytes, sem resultados quantitativos registados.],
    [REQ-VID-UPL-030],

    [UC-VID-001 / DQ-002],
    [Não expor como concluído um envio interrompido ou com falha de armazenamento],
    [Concretiza a garantia mínima do caso de uso; os cenários de falha forçada não foram validados nesta revisão.],
    [REQ-VID-UPL-031],

    [UC-VID-001 / DQ-003],
    [Aplicar permissões do projeto ao upload e à referência do vídeo],
    [Mantém o controlo de acesso em projetos próprios e partilhados; existem resultados de integração comunicados para leitura e edição.],
    [REQ-VID-UPL-032],

    [UC-VID-001 / DQ-004],
    [Comunicar os estados em curso, conclusão e falha; percentagem numa evolução futura],
    [O MVP exige estados distinguíveis; percentagem de progresso ainda não implementada.],
    [REQ-VID-UPL-033],

    [UC-VID-001 / DQ-005],
    [Preservar o fluxo de imagens e separar as referências de imagens e vídeos],
    [A separação em `imgs` e `videos` protege a compatibilidade estrutural; falta ensaio de regressão explícito do fluxo de imagens.],
    [REQ-VID-UPL-034, REQ-VID-UPL-035],

    [DQ-001],
    [Processamento assíncrono desacoplado via RabbitMQ e polling leve],
    [Previne o bloqueio do servidor HTTP da API durante operações demoradas de vídeo e assegura a responsividade contínua da interface do utilizador com atualizações periódicas de estado.],
    [REQ-VID-TRIM-008–009, REQ-VID-TRIM-025, REQ-VID-TRIM-029–030],

    [DQ-002],
    [Resiliência baseada em reexecução idempotente do início],
    [Simplifica a arquitetura da Fase 1 evitando a complexidade de persistir _checkpoints_ parciais de fotogramas, tolerando quebras pontuais de workers com repetição automática garantida.],
    [REQ-VID-TRIM-017, REQ-VID-TRIM-026],

    [DQ-003],
    [Acesso seguro com autenticação de sessão, cookies temporários e auditoria],
    [Assegura a confidencialidade dos ficheiros de vídeo, evitando a exposição de credenciais ou JWT em URLs de streaming e prevenindo acessos ilegítimos por enumeração.],
    [REQ-VID-TRIM-020, REQ-VID-TRIM-027],

    [DQ-004],
    [Encapsulamento do motor FFmpeg e dependências em imagem Docker autónoma],
    [Garante portabilidade total e reprodutibilidade do ambiente de execução do worker entre desenvolvimento e produção, sem requerer instalação de binários nativos no sistema operativo anfitrião.],
    [REQ-VID-TRIM-012, REQ-VID-TRIM-028],

    [DQ-005],
    [Retenção efêmera em workers e eliminação explícita na biblioteca permanente],
    [Previne o esgotamento do disco dos nós de computação através da purga imediata de diretórios temporários e capacita o utilizador a gerir o volume ocupado na sua conta.],
    [REQ-VID-TRIM-018, REQ-VID-TRIM-023, REQ-VID-TRIM-037, REQ-VID-TRIM-039–040],

    [DQ-006],
    [Cancelamento cooperativo de tarefas com estorno imediato de quota],
    [Evita o desperdício de tempo de computação em tarefas submetidas por engano e garante justiça na contabilidade de quotas para utilizadores do plano gratuito.],
    [REQ-VID-TRIM-022, REQ-VID-TRIM-034, REQ-VID-TRIM-036–038],

    [UC-VID-004 / DQ-001],
    [Processamento assíncrono],
    [O pedido de compilação deve ser aceite sem esperar pela conclusão do processamento, permitindo ao utilizador continuar a utilizar a aplicação.],
    [REQ-VID-COMP-007, REQ-VID-COMP-NF-001],

    [UC-VID-004 / DQ-002],
    [Segurança e controlo de acesso],
    [Os vídeos de entrada e os resultados devem estar protegidos contra acessos não autorizados, garantindo que apenas o proprietário autorizado lhes pode aceder.],
    [REQ-VID-COMP-001, REQ-VID-COMP-011, REQ-VID-COMP-NF-002],

    [UC-VID-004 / DQ-003],
    [Integridade perante falhas e cancelamentos],
    [Uma falha ou cancelamento não deve disponibilizar resultados incompletos, e os vídeos originais devem permanecer inalterados.],
    [REQ-VID-COMP-012, REQ-VID-COMP-017, REQ-VID-COMP-NF-003],

    [UC-VID-004 / DQ-004],
    [Acompanhamento do estado e progresso],
    [O utilizador deve conseguir acompanhar o estado da compilação e consultar a sua evolução sem ter de manter a página aberta.],
    [REQ-VID-COMP-009, REQ-VID-COMP-018, REQ-VID-COMP-NF-004],

    [UC-VID-004 / DQ-005],
    [Validação e compatibilidade dos vídeos],
    [Os vídeos devem ser validados antes do processamento, com tratamento explícito de ficheiros corrompidos, ilegíveis ou incompatíveis com os formatos suportados.],
    [REQ-VID-COMP-004, REQ-VID-COMP-014, REQ-VID-COMP-015, REQ-VID-COMP-NF-005],

    [UC-VID-004 / DQ-006],
    [Isolamento e controlo de recursos],
    [As tarefas de compilação devem respeitar limites de tempo e recursos, evitando que uma operação afete indevidamente as restantes operações do sistema.],
    [REQ-VID-COMP-007, REQ-VID-COMP-019, REQ-VID-COMP-NF-006],

    [UC-VID-004 / DQ-007],
    [Separação de responsabilidades e manutenibilidade],
    [A gestão dos pedidos, o processamento de vídeo e o armazenamento devem estar separados de forma a permitir a evolução do mecanismo de compilação sem alterações desnecessárias à biblioteca ou à autenticação.],
    [REQ-VID-COMP-007, REQ-VID-COMP-008, REQ-VID-COMP-NF-007],

    [#text(hyphenate: true, "UC-VID-005 / DQ-001")], [#text(hyphenate: true, "Submissão e execução desacopladas.")], [#text(hyphenate: true, "A chamada de submissão não aguarda a transformação pesada do vídeo.")], [#text(hyphenate: true, "REQ-VID-SPEED-008 e REQ-VID-SPEED-036")],

    [#text(hyphenate: true, "UC-VID-005 / DQ-002")], [#text(hyphenate: true, "Processamento não destrutivo e resultado independente.")], [#text(hyphenate: true, "Protege o original e permite comparar os artefactos.")], [#text(hyphenate: true, "REQ-VID-SPEED-020 e REQ-VID-SPEED-021")],

    [#text(hyphenate: true, "UC-VID-005 / DQ-003")], [#text(hyphenate: true, "Reutilização do controlo de acesso e versionamento existentes.")], [#text(hyphenate: true, "Evita uma autorização paralela e submissões sobre versões desatualizadas.")], [#text(hyphenate: true, "REQ-VID-SPEED-028, REQ-VID-SPEED-029 e REQ-VID-SPEED-035")],

    [#text(hyphenate: true, "UC-VID-005 / DQ-004")], [#text(hyphenate: true, "Saída compatível com a biblioteca existente.")], [#text(hyphenate: true, "MP4/H.264 e AAC quando aplicável, sem inventar áudio.")], [#text(hyphenate: true, "REQ-VID-SPEED-017 e REQ-VID-SPEED-030")],

    [#text(hyphenate: true, "UC-VID-005 / DQ-005")], [#text(hyphenate: true, "Contabilização de armazenamento pelo tamanho efetivo do output.")], [#text(hyphenate: true, "Reutiliza a reserva, confirmação e libertação existentes e trata resultados repetidos.")], [#text(hyphenate: true, "REQ-VID-SPEED-019, REQ-VID-SPEED-031 e REQ-VID-SPEED-032")],

    [#text(hyphenate: true, "UC-VID-005 / DQ-006")], [#text(hyphenate: true, "Evidência e limitações explícitas.")], [#text(hyphenate: true, "Distingue implementação, testes, objetivos futuros e limpeza em saídas controladas.")], [#text(hyphenate: true, "REQ-VID-SPEED-034, REQ-VID-SPEED-037 e REQ-VID-SPEED-038")],
  ),
)

== Realização e verificação dos requisitos

A evidência de speed refere-se à implementação 58d4414 e aos ensaios históricos TST-SPEED-01 a TST-SPEED-07, detalhados no capítulo de testes. Esta edição documental não reexecuta as suites nem o E2E e não demonstra concorrência real.

#orientacao[
  Fecha o ciclo *requisito → componente → teste → estado*. Uma linha por requisito da ERS (podem agrupar
  requisitos com o mesmo destino). Deve ser possível responder a: "que requisitos estão implementados e
  verificados?" e "que componentes foram tocados por cada funcionalidade?". Requisitos não implementados não se
  apagam: ficam com estado "Não implementado" e justificação. Os detalhes estão nos capítulos de Arquitetura e de Testes.
]

#tab([Realização e verificação dos requisitos],
  tabela(
    colunas: (2.8cm, 3.2cm, 2.2cm, 2.2cm, 1fr),
    tamanho: 8pt,
    [Requisito], [Componente(s)], [Estado], [Teste(s)], [Resultado / observações],

    [REQ-VID-UPL-001], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-01], [Percurso positivo no browser comunicado; seleção e entrada do fluxo.],
    [REQ-VID-UPL-002], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-01], [Seleção de MP4 no browser comunicada.],
    [REQ-VID-UPL-003], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-01], [Nome apresentado no percurso positivo comunicado.],
    [REQ-VID-UPL-004], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-01], [Tamanho apresentado no percurso positivo comunicado.],
    [REQ-VID-UPL-005], [Frontend (`AddVideoDialog`), API Gateway, `projects`], [Implementado], [TST-UPL-02, TST-UPL-15], [A pré-validação da API rejeita nome inválido com HTTP 400; a validação e mensagem na interface continuam por testar.],
    [REQ-VID-UPL-006], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-01], [Confirmação do envio comunicada no percurso positivo.],
    [REQ-VID-UPL-007], [API Gateway, `projects`], [Implementado], [TST-UPL-03 (`tests/video_upload_smoke_test.py`)], [Passa: pedido de pré-validação sem JWT rejeitado com HTTP 401.],
    [REQ-VID-UPL-008], [API Gateway, `projects`], [Implementado], [TST-UPL-04 (`tests/video_upload_smoke_test.py`)], [Passa: permissão `read` rejeitada com HTTP 403; permissão `edit` aceite na pré-validação.],
    [REQ-VID-UPL-009], [`projects` (`ffprobe`)], [Implementado], [TST-UPL-05 (`tests/video_upload_smoke_test.py`)], [Conteúdo falso com extensão MP4 rejeitado com HTTP 415; o envio do MP4/H.264 passou a inspeção, mas falhou depois no armazenamento.],
    [REQ-VID-UPL-010], [`projects` (`ffprobe`)], [Implementado], [TST-UPL-05 (`tests/video_upload_smoke_test.py`)], [MP4/H.264 pequeno passou à validação de mídia; upload integral bloqueado pela falha do SeaweedFS.],
    [REQ-VID-UPL-011], [`projects` (`ffprobe`)], [Implementado], [TST-UPL-05 (`tests/video_upload_smoke_test.py`)], [Passa: MP4 com codec MPEG-4 rejeitado com HTTP 415; H.264 passou a inspeção antes da falha de armazenamento.],
    [REQ-VID-UPL-012], [Frontend, API Gateway, Nginx, `projects`], [Implementado], [TST-UPL-06, TST-UPL-07 (`tests/video_upload_smoke_test.py`)], [Pré-validação aceita o limite Free e rejeita +1 byte com HTTP 413; não foi transferido um ficheiro de 1 GB.],
    [REQ-VID-UPL-013], [Frontend, API Gateway, Nginx, `projects`], [Implementado], [TST-UPL-06, TST-UPL-07 (`tests/video_upload_smoke_test.py`)], [Pré-validação aceita o limite Premium e rejeita +1 byte com HTTP 413; não foi transferido um ficheiro de 5 GB.],
    [REQ-VID-UPL-014], [Frontend, API Gateway, `projects`], [Implementado], [TST-UPL-08 (`tests/video_upload_smoke_test.py`)], [Pedido de upload pequeno percorreu o gateway, mas terminou em HTTP 502 por falta de volumes livres no SeaweedFS.],
    [REQ-VID-UPL-015], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-09], [Indicação de envio em curso presente; ensaio manual específico não comunicado.],
    [REQ-VID-UPL-016], [`projects`, MongoDB, SeaweedFS], [Implementado], [TST-UPL-08 (`tests/video_upload_smoke_test.py`)], [Não verificado nesta execução: SeaweedFS não atribuiu volume; não foi possível confirmar a criação do objeto.],
    [REQ-VID-UPL-017], [`projects`, MongoDB, SeaweedFS], [Implementado], [TST-UPL-08 (`tests/video_upload_smoke_test.py`)], [Não verificado nesta execução: o upload falhou antes da persistência dos metadados e da referência.],
    [REQ-VID-UPL-018], [Frontend, `projects`], [Implementado], [TST-UPL-01, TST-UPL-09], [Conclusão positiva comunicada; mensagens após falhas não cobertas por este percurso.],
    [REQ-VID-UPL-019], [Frontend, `projects`], [Implementado], [TST-UPL-01], [Vídeo listado no browser após upload comunicado.],
    [REQ-VID-UPL-021], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-02, TST-UPL-15], [API rejeita a extensão inválida; apresentação da mensagem pela interface continua por testar.],
    [REQ-VID-UPL-022], [Frontend, `projects`], [Implementado], [TST-UPL-06, TST-UPL-07], [A API aceitou os limites declarados e rejeitou +1 byte; a mensagem apresentada na interface continua por testar.],
    [REQ-VID-UPL-023], [API Gateway, `projects`, Frontend], [Implementado], [TST-UPL-03 (`tests/video_upload_smoke_test.py`)], [Passa: pré-validação sem JWT rejeitada com HTTP 401; mensagem da interface não foi validada.],
    [REQ-VID-UPL-024], [API Gateway, `projects`, Frontend], [Implementado], [TST-UPL-04 (`tests/video_upload_smoke_test.py`)], [Passa: partilha `read` recebeu HTTP 403; partilha `edit` foi aceite na pré-validação.],
    [REQ-VID-UPL-025], [Frontend, API Gateway, `projects`], [Parcial], [TST-UPL-09, TST-UPL-12], [Comunicação da interrupção prevista nos caminhos de erro; interrupção forçada não ensaiada.],
    [REQ-VID-UPL-026], [`projects` (`ffprobe`), Frontend], [Implementado], [TST-UPL-05], [MP4 válido testado; conteúdo inválido e respetiva mensagem não ensaiados.],
    [REQ-VID-UPL-027], [`projects` (`ffprobe`), Frontend], [Implementado], [TST-UPL-05], [H.264 válido testado; codec diferente e respetiva mensagem não ensaiados.],
    [REQ-VID-UPL-028], [Frontend, API Gateway, `projects`], [Implementado], [TST-UPL-10], [Recusa de nome duplicado no browser foi comunicada; teste API ficou ignorado porque o upload positivo falhou no SeaweedFS.],
    [REQ-VID-UPL-029], [`projects`, MongoDB, SeaweedFS], [Implementado], [TST-UPL-08 (`tests/video_upload_smoke_test.py`), TST-UPL-12], [Upload integral não confirmado nesta execução: falha por falta de volumes livres no SeaweedFS; ensaio de falha/limpeza continua pendente.],
    [REQ-VID-UPL-030], [Nginx, API Gateway, `projects`, SeaweedFS], [Implementado], [TST-UPL-13], [Transferência progressiva e buffers multipart limitados (2 × 16 MiB). É referido um ensaio com ficheiro de 128 000 000 bytes, sem pico quantitativo ou configuração registados; o teto de 1 000 000 000 bytes nos limites dos planos e sob concorrência continua por validar.],
    [REQ-VID-UPL-031], [API Gateway, `projects`, SeaweedFS], [Implementado], [TST-UPL-12], [Caminhos e limpeza inspecionados; não houve injeção de falha de rede/armazenamento.],
    [REQ-VID-UPL-032], [API Gateway, `projects`, Frontend], [Implementado], [TST-UPL-04], [Resultados de integração de permissões em projeto partilhado comunicados; validação automatizada completa pendente.],
    [REQ-VID-UPL-033], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-01, TST-UPL-09], [Percurso positivo observado; estados de erro não foram ensaiados. Percentagem de progresso não está implementada e fica fora do MVP.],
    [REQ-VID-UPL-034], [Frontend, fluxo de imagens], [Implementado], [TST-UPL-14], [Compatibilidade prevista; não foi identificado ensaio de regressão de imagens após esta alteração.],
    [REQ-VID-UPL-035], [`projects` (`Project.videos`, `Project.imgs`), MongoDB], [Implementado], [TST-UPL-14], [Campos separados no modelo e persistência observados; não foi identificado teste de regressão explícito.],
    [REQ-VID-UPL-036], [Frontend (`AddVideoDialog`)], [Implementado], [TST-UPL-11], [Fecho do diálogo antes de enviar implementado; cenário específico não ensaiado.],
    [REQ-VID-UPL-037], [Frontend, `projects`, SeaweedFS], [Parcial], [TST-UPL-12], [Comunicação da falha de armazenamento prevista; falha provocada não ensaiada.],
    [REQ-VID-UPL-038], [Frontend, `projects`, MongoDB], [Parcial], [TST-UPL-12], [Comunicação da falha de associação prevista; falha provocada não ensaiada.],
    [REQ-VID-UPL-039], [API Gateway, `projects`], [Especificado], [Não executado], [Recusa por versão desatualizada não validada especificamente nesta revisão.],
    [REQ-VID-UPL-040], [Frontend, `projects`], [Especificado], [Não executado], [Atualização dos dados do projeto após conflito não validada especificamente nesta revisão.],
    [REQ-VID-UPL-041], [Frontend], [Especificado], [Não executado], [Mensagem para repetir a operação após conflito não validada especificamente nesta revisão.],

    [REQ-VID-TRIM-001], [Frontend (VideoWorkspace)], [Implementado], [TST-TRIM-01], [Passa. Player HTML5 e seletores temporais carregados com sucesso.],
    [REQ-VID-TRIM-002], [Frontend (VideoWorkspace)], [Implementado], [TST-TRIM-01], [Passa. Marcadores atualizam dinamicamente os tempos e duração resultante.],
    [REQ-VID-TRIM-003], [Frontend (VideoWorkspace)], [Implementado], [TST-TRIM-02], [Passa. Pré-visualização local no browser sem chamadas de rede ao worker.],
    [REQ-VID-TRIM-004], [Projects (`/trim`), Frontend], [Implementado], [TST-TRIM-03], [Passa. Rejeita $t_(i n) >= t_(o u t)$ e intervalo $< 1.0$ s com HTTP 400.],
    [REQ-VID-TRIM-005], [Users (`/quota`), Projects], [Implementado], [TST-TRIM-04], [Passa. Bloqueia submissão com HTTP 403 após 5 operações Free no teste.],
    [REQ-VID-TRIM-006], [Projects (`/trim`)], [Implementado], [TST-TRIM-03], [Passa. Rejeita intervalos superiores a 180s no perfil Free.],
    [REQ-VID-TRIM-007], [Users, Projects], [Implementado], [TST-TRIM-04], [Passa. Débito provisório imediato da quota Free ao submeter para fila.],
    [REQ-VID-TRIM-008], [Projects, RabbitMQ], [Implementado], [TST-TRIM-05], [Publicação na fila descrita no TST-TRIM-05; unicidade sob repetição não demonstrada.],
    [REQ-VID-TRIM-009], [Projects, VideoTrimWorker, UI], [Implementado], [TST-TRIM-05], [Passa. Polling a cada 4s reflete progressão de QUEUED a COMPLETED.],
    [REQ-VID-TRIM-010], [VideoTrimWorker (FFmpeg)], [Implementado], [TST-TRIM-06], [Passa. Excerto recortado gerado com sincronismo áudio/vídeo preservado.],
    [REQ-VID-TRIM-011], [VideoTrimWorker, Projects], [Implementado], [TST-TRIM-07], [Passa. Modo rápido Premium aceita corte em keyframes e rejeita se desalinhado.],
    [REQ-VID-TRIM-012], [MediaStorageService, Worker], [Implementado], [TST-TRIM-06], [Passa. Ingestão e exportação validadas em contentor MP4 com codecs H.264/AAC.],
    [REQ-VID-TRIM-013], [Projects, SeaweedFS], [Implementado], [TST-TRIM-08], [Passa. Hash SHA-256 do vídeo original permanece idêntico após recorte.],
    [REQ-VID-TRIM-014], [Projects, SeaweedFS], [Implementado], [TST-TRIM-06], [Vídeo resultante registado no projeto; ausência de registo antes da validação não demonstrada isoladamente.],
    [REQ-VID-TRIM-015], [Projects, Worker], [Parcial], [TST-TRIM-05], [Parcial. Job conclui assincronamente em background; notificação global fora de página pendente.],
    [REQ-VID-TRIM-016], [VideoTrimWorker], [Implementado], [TST-TRIM-09], [Transição para FAILED comunicada; ensaio específico com fluxo corrompido não identificado.],
    [REQ-VID-TRIM-017], [VideoTrimWorker, Projects], [Implementado], [TST-TRIM-09], [Passa. Mecanismo de repetição para jobs com lease expirado implementado no worker.],
    [REQ-VID-TRIM-018], [VideoTrimWorker], [Implementado], [TST-TRIM-10], [Passa. Verificado no teste que `/tmp/picturas-trim-*` é purgado sem resíduos em disco.],
    [REQ-VID-TRIM-019], [ApiGateway, Projects], [Implementado], [TST-TRIM-11], [Passa. Pedidos não autenticados rejeitados com HTTP 401/403.],
    [REQ-VID-TRIM-020], [Projects, Logs], [Implementado], [TST-TRIM-05], [Passa. Registo em base de dados com parâmetros, tempos de processamento e utilizador.],
    [REQ-VID-TRIM-021], [Projects (`storage.js`)], [Implementado], [TST-TRIM-12], [Mecanismo de quota acumulada descrito; fronteiras exatas em bytes não demonstradas e política com Upload pendente.],
    [REQ-VID-TRIM-022], [Projects, Worker], [Parcial], [TST-TRIM-13], [Cancelamento de job em fila comunicado; cancelamento em execução e ausência de conclusão tardia não demonstrados.],
    [REQ-VID-TRIM-023], [Projects, biblioteca], [Especificado], [Não executado], [Retenção até eliminação explícita é proposta do Trim; harmonização com UC-VID-001 pendente.],
    [REQ-VID-TRIM-024], [Projects, Frontend], [Implementado], [TST-TRIM-12], [Passa. Endpoint de storage devolve bytes ocupados e limite da conta.],
    [REQ-VID-TRIM-025], [Projects, ApiGateway], [Parcial], [TST-TRIM-05], [Parcial. Resposta HTTP 202 rápida em testes locais; benchmark formal de p95 pendente.],
    [REQ-VID-TRIM-026], [VideoTrimWorker], [Parcial], [TST-TRIM-06], [Parcial. Excerto de 2.5s processado em ~1.2s; medição sistemática em 1080p/60s pendente.],
    [REQ-VID-TRIM-027], [Projects (`/playback`), Gateway], [Implementado], [TST-TRIM-14], [Passa. Stream via HTTP Range e cookie de 5 min; partilhas read/edit validadas.],
    [REQ-VID-TRIM-028], [Docker Compose, Worker], [Implementado], [TST-TRIM-15], [Passa. Contentor `video_trim_worker` arranca e executa FFmpeg isolado sem dependências no host.],
    [REQ-VID-TRIM-029], [Projects], [Parcial], [TST-TRIM-05], [Job ID devolvido segundo o teste existente; unicidade entre jobs não demonstrada isoladamente.],
    [REQ-VID-TRIM-030], [Frontend], [Parcial], [TST-TRIM-05], [Estado inicial QUEUED referido; verificação da interface específica não documentada.],
    [REQ-VID-TRIM-031], [Projects, MongoDB], [Parcial], [TST-TRIM-06], [Metadados observados no teste; todos os campos do requisito não confirmados isoladamente.],
    [REQ-VID-TRIM-032], [Frontend, playback], [Parcial], [TST-TRIM-14], [Playback por HTTP Range descrito; ensaio da ação na biblioteca não documentado.],
    [REQ-VID-TRIM-033], [Frontend, Projects], [Parcial], [TST-TRIM-06], [Download funcional referido; autorização em partilha requer ensaio específico.],
    [REQ-VID-TRIM-034], [Users, Projects], [Parcial], [TST-TRIM-09, TST-TRIM-13], [Estorno em falha e cancelamento em fila referido; recusa por quota de disco não coberta.],
    [REQ-VID-TRIM-035], [Frontend, Projects], [Especificado], [Não executado], [Mensagem com causa conhecida não validada nos testes descritos.],
    [REQ-VID-TRIM-036], [VideoTrimWorker], [Não verificado], [Não executado], [Interrupção de tarefa já em execução não demonstrada pelo teste de cancelamento em fila.],
    [REQ-VID-TRIM-037], [VideoTrimWorker], [Parcial], [TST-TRIM-10], [Limpeza após tarefa indicada; caso específico de cancelamento não demonstrado.],
    [REQ-VID-TRIM-038], [Frontend, Projects], [Parcial], [TST-TRIM-13], [Estado CANCELLED no backend indicado; confirmação na interface não documentada.],
    [REQ-VID-TRIM-039], [Projects], [Parcial], [TST-TRIM-12], [DELETE referido; autorização e âmbito da política de retenção ainda por harmonizar.],
    [REQ-VID-TRIM-040], [Projects, videoQuota], [Parcial], [TST-TRIM-12], [Redução de bytes ocupados após DELETE indicada; política de agregação ainda pendente.],

    [REQ-VID-COMP-001–003, REQ-VID-COMP-009, REQ-VID-COMP-013, REQ-VID-COMP-016, REQ-VID-COMP-018], [Frontend (`compile-videos-dialog.tsx`)], [Implementado], [Não executado], [Seleção e ordem dos vídeos (subir, descer, remover), mínimo de dois, nome opcional, estado e progresso com consulta de 3 em 3 s, cancelamento e mensagens de erro por código; sem testes automáticos.],
    [REQ-VID-COMP-004, REQ-VID-COMP-014, REQ-VID-COMP-015, REQ-VID-COMP-NF-005], [`projects` (`trim.js`), `videoCompileWorker` (`probe` com FFprobe)], [Implementado], [TST-COMP-01, TST-COMP-03, TST-COMP-04], [O pedido recusa vídeos que não existem no projeto (`VIDEO_NOT_FOUND`) ou que não são MP4/H.264 (`UNSUPPORTED_VIDEO`, HTTP 415); o _worker_ falha vídeos ilegíveis com `VIDEO_UNREADABLE` e produz H.264/AAC (TST-COMP-01). A validação do pedido não tem teste automático.],
    [REQ-VID-COMP-005, REQ-VID-COMP-021], [`projects` (`trim.js`, `compileQuota`), `users`], [Implementado], [TST-COMP-08], [No perfil `free`, a operação diária é reservada no pedido (HTTP 429, `DAILY_QUOTA_EXHAUSTED`, se esgotada), confirmada na conclusão e estornada em falha definitiva ou cancelamento; o `premium` não consome quota diária. O contador desce uma unidade por compilação (verificado manualmente); sem teste automático.],
    [REQ-VID-COMP-006], [`projects` (`trim.js`, `videoQuota`), `videoCompileWorker`], [Implementado], [TST-COMP-01], [Limites de 1 GB (`free`) e 5 GB (`premium`). O pedido é recusado com `STORAGE_QUOTA_EXCEEDED` (HTTP 507) se a conta já estiver cheia; a reserva exata é pedida pelo _worker_ depois da conversão e antes do envio e é libertada se a tarefa for cancelada ou a conclusão falhar; a libertação não é testada.],
    [REQ-VID-COMP-020], [`projects` (`trim.js`), `videoCompileWorker`], [Implementado], [TST-COMP-07], [O pedido recusa mais de 10 vídeos (`TOO_MANY_VIDEOS`) e somas de durações acima de 10 minutos (`free`) ou 1 hora (`premium`) (`COMPILE_TOO_LONG`, HTTP 422); o _worker_ volta a verificar o limite de 1 hora (`TOTAL_TOO_LONG`, TST-COMP-07). A validação do pedido não tem teste automático.],
    [REQ-VID-COMP-007, REQ-VID-COMP-NF-001, REQ-VID-COMP-NF-006], [`projects` (`trim.js`, `compileQueue`), RabbitMQ (`video_compile_queue`)], [Implementado], [Não executado], [O pedido é aceite com HTTP 202 e o identificador da tarefa, e esta é publicada em `video_compile_queue`; se a publicação falhar, a tarefa passa a `FAILED` (`QUEUE_UNAVAILABLE`) e a quota é estornada. Sem testes automáticos nem teste de carga.],
    [REQ-VID-COMP-019], [Worker], [Implementado], [Não executado], [Tempo limite de 30 minutos por omissão (`COMPILE_TIMEOUT_SECONDS`), com falha recuperável `PROCESSING_TIMEOUT`; sem teste.],
    [REQ-VID-COMP-008, REQ-VID-COMP-010], [Worker (FFmpeg)], [Implementado], [TST-COMP-01, TST-COMP-02], [Normalização para a resolução do primeiro vídeo, 30 fps e H.264/AAC; ordem e repetição de vídeos verificadas; duração do resultado validada com tolerância de 5 %.],
    [REQ-VID-COMP-011, REQ-VID-COMP-012], [Worker, `mediaStorageService`], [Implementado], [TST-COMP-01], [O resultado é enviado como novo vídeo para o mesmo projeto e os originais só são lidos; a invariância dos originais não é testada por _hash_.],
    [REQ-VID-COMP-022], [Worker (ficheiros temporários)], [Parcial], [Não executado], [Os ficheiros temporários são apagados no fim de cada tarefa; a retenção de originais e resultados está por decidir.],
    [REQ-VID-COMP-017, REQ-VID-COMP-NF-003], [Worker], [Implementado], [TST-COMP-03, TST-COMP-04, TST-COMP-05], [Em vídeo ilegível ou em falta, ou em cancelamento, não é enviado resultado; o cancelamento (`DELETE`) estorna a quota diária e liberta o armazenamento reservado e, durante a conversão, termina o FFmpeg (não testado). Falhas recuperáveis voltam à fila até duas tentativas.],
    [REQ-VID-COMP-NF-004], [Frontend (`compile-videos-dialog.tsx`), `projects`], [Parcial], [Não executado], [O estado é guardado no servidor e recuperado ao reabrir o diálogo (lista de tarefas); com o diálogo fechado não há consulta nem aviso ao utilizador.],
    [REQ-VID-COMP-NF-002, REQ-VID-COMP-NF-007], [`projects` (`trim.js`, `compileJob`, `compileQueue`, `compileQuota`, `compileRecovery`)], [Implementado], [Não executado], [Os pedidos exigem sessão válida e acesso ao projeto (proprietário ou ligação partilhada); criar e cancelar exigem permissão de edição e os endpoints do _worker_ exigem a chave interna. A rota está no mesmo ficheiro que a do recorte, mas a lógica de compilação está em módulos próprios.],

    [#text(hyphenate: true, "REQ-VID-SPEED-001, REQ-VID-SPEED-002, REQ-VID-SPEED-003, REQ-VID-SPEED-004, REQ-VID-SPEED-007, REQ-VID-SPEED-026, REQ-VID-SPEED-027")], [#text(hyphenate: true, "Frontend (SpeedVideoDialog)")], [#text(hyphenate: true, "UI implementada; percurso positivo comunicado pelo utilizador.")], [#text(hyphenate: true, "TST-SPEED-03, TST-SPEED-05")], [#text(hyphenate: true, "SpeedVideoDialog contém seleção, lista, edição e remoção. Os 28 testes frontend cobrem a validação, não cliques/renderização do diálogo; não se afirma que cada controlo tenha sido ensaiado manualmente.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-005, REQ-VID-SPEED-006, REQ-VID-SPEED-022, REQ-VID-SPEED-023, REQ-VID-SPEED-024, REQ-VID-SPEED-025")], [#text(hyphenate: true, "Frontend, Projects, videoSpeedWorker")], [#text(hyphenate: true, "Implementados; cobertos parcialmente em camadas diferentes.")], [#text(hyphenate: true, "TST-SPEED-01, TST-SPEED-03–04")], [#text(hyphenate: true, "Validação frontend, API e worker; duração real é verificada no worker. Os testes cobrem limites inválidos, finitude, sobreposição, adjacência e duração; não constituem uma medição universal de precisão temporal.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-008, REQ-VID-SPEED-009, REQ-VID-SPEED-014, REQ-VID-SPEED-015, REQ-VID-SPEED-030")], [#text(hyphenate: true, "API Gateway, Projects, RabbitMQ, worker, Storage, wsGateway")], [#text(hyphenate: true, "Implementados; contratos automatizados e percurso real positivo comunicados.")], [#text(hyphenate: true, "TST-SPEED-01–02, TST-SPEED-04–05")], [#text(hyphenate: true, "Testes Projects/API Gateway/worker e teste de upload/Modificar velocidade na stack Docker. A aceitação HTTP é 202; o resultado aparece após associação.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-010, REQ-VID-SPEED-011, REQ-VID-SPEED-012, REQ-VID-SPEED-017, REQ-VID-SPEED-018, REQ-VID-SPEED-020")], [#text(hyphenate: true, "videoSpeedWorker (FFmpeg/ffprobe)")], [#text(hyphenate: true, "Implementados; testes sintéticos com FFmpeg e ffprobe.")], [#text(hyphenate: true, "TST-SPEED-04")], [#text(hyphenate: true, "Os 18 testes do worker incluem durações, vários intervalos/ordem temporal, 1x, áudio/ausência de áudio, validação e hash do original. A evidência aplica-se aos conteúdos de teste, não a todos os vídeos possíveis.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-019, REQ-VID-SPEED-031, REQ-VID-SPEED-032")], [#text(hyphenate: true, "Projects (videoQuota), VideoStorageAccount")], [#text(hyphenate: true, "Implementados; testes isolados com utilitário real de quota e MongoDB simulado.")], [#text(hyphenate: true, "TST-SPEED-01")], [#text(hyphenate: true, "A suite Projects de 66 testes cobre espaço suficiente/insuficiente, igualdade com limites Free/Premium, bytes do output, rollback, repetição sequencial e falha de commit. Não valida concorrência real nem reconcilia dados históricos.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-021, REQ-VID-SPEED-034")], [#text(hyphenate: true, "videoSpeedWorker, Projects, Media Storage")], [#text(hyphenate: true, "Mecanismos de integridade e limpeza presentes, com âmbito limitado.")], [#text(hyphenate: true, "TST-SPEED-01, TST-SPEED-04")], [#text(hyphenate: true, "Limpeza local no worker; tentativa de limpeza remota e release em Projects no ramo de sucesso cuja associação falha. Uma falha simulada de DELETE não impede release. O ramo status error apenas regista a falha; não há limpeza remota geral nem recolha de órfãos demonstrada.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-028, REQ-VID-SPEED-029, REQ-VID-SPEED-033")], [#text(hyphenate: true, "API Gateway, Projects, Frontend")], [#text(hyphenate: true, "Implementados; testes backend e mensagens frontend identificados.")], [#text(hyphenate: true, "TST-SPEED-01–03")], [#text(hyphenate: true, "Cobertura de autenticação, partilha de leitura/edição/revogada e versão no backend. Falta ensaio manual completo dos erros na interface.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-035, REQ-VID-SPEED-036, REQ-VID-SPEED-037")], [#text(hyphenate: true, "API Gateway, Projects, worker, frontend")], [#text(hyphenate: true, "Arquitetura e controlos reutilizados; validação parcial.")], [#text(hyphenate: true, "TST-SPEED-01–02, TST-SPEED-06")], [#text(hyphenate: true, "Gateway e worker verificam contratos internos; testes de regressão de trim e upload; TypeScript/build/sintaxe passaram nas verificações anteriores. Não há benchmark de carga nem prova de regressão completa de imagens e partilhas em todos os serviços.")],

    [#text(hyphenate: true, "REQ-VID-SPEED-013, REQ-VID-SPEED-016, REQ-VID-SPEED-038")], [#text(hyphenate: true, "Frontend, Projects, worker")], [#text(hyphenate: true, "Especificados como evolução futura; não implementados.")], [#text(hyphenate: true, "Não executado")], [#text(hyphenate: true, "Não há acompanhamento persistente/progresso, cancelamento pós-submissão ou notificação terminal de erro específica de speed. Não os contabilizar como funcionalidades validadas do MVP.")],
  ),
)
