#import "../template.typ": *

= Visão Geral da Extensão de Vídeo

== Funcionalidades de vídeo do MVP

#orientacao[
  Listem *todas* as funcionalidades de vídeo tratadas no relatório, cada uma com o respetivo caso de uso.
  A especificação detalhada está na Parte II, organizada por artefacto (casos de uso, ERS, impacto, …).
  Não há um número mínimo: valoriza-se a *profundidade, coerência e complexidade adequada* de cada funcionalidade.
  Operações triviais (e.g., gerar uma miniatura a partir de um único fotograma) não são suficientes.
  Requisitos partilhados por várias funcionalidades (e.g., submeter vídeo, acompanhar o estado do processamento)
  devem ser especificados *uma só vez* (e.g., `REQ-VID-SUBMIT-001`, com origem em vários casos de uso).
]

#tab([Funcionalidades de vídeo do MVP],
  tabela(
    colunas: (1fr, 2.1cm, 2.4cm, 2cm, 2.4cm, 2.4cm),
    [Funcionalidade], [Caso de uso], [Prefixo(s) REQ], [Perfis], [Dependências], [Estado de implementação],

    [Recortar Intervalo Temporal (_Trim_)],
    [UC-VID-001],
    [REQ-VID-TRIM],
    [`free`, `premium`],
    [Nenhuma (Atómica)],
    [Implementada],
  ),
)

*Justificação no contexto do MVP:*
- *UC-VID-001 — Recortar Intervalo Temporal de Vídeo (_Trim_):* O recorte temporal é a operação atómica primordial e estruturante na manipulação de vídeo digital. Permite ao utilizador isolar excertos relevantes e descartar material supérfluo, reduzindo significativamente os volumes de armazenamento e transferência na rede. No contexto do MVP da Fase 1, esta funcionalidade é a mais crítica a construir porque valida de ponta a ponta o novo pipeline assíncrono do PictuRAS: ingestão de contentores pesados, parametrização temporal na interface web, publicação e consumo em filas RabbitMQ, execução de tarefas demoradas em _workers_ autónomos com FFmpeg, reserva atómica de quotas e entrega segura do resultado por _streaming_. Sem esta funcionalidade, toda a infraestrutura base de suporte a vídeo ficaria por validar.

== Diagrama de casos de uso (atualizado)

O diagrama de casos de uso da solução de base (centrado exclusivamente na manipulação síncrona de imagens) foi revisto e estendido para incorporar o suporte a vídeo.

#figure(
  image("../images/diagrama_casos_uso.png", width: 88%),
  caption: [Diagrama de casos de uso atualizado com suporte a vídeo (Fase 1)],
)

*Decisões de modelação e novos fluxos:*
- *Diferenciação Visual e Coerência de Perfis:* Os casos de uso legados de imagem figuram a cinzento para contextualização. As novas funcionalidades de vídeo encontram-se destacadas a verde (`UC-VID-001`), azul e roxo.
- *Controlo de Acesso e Autenticação (RN7):* Os utilizadores anónimos (`anonymous`) estão formalmente bloqueados de aceder a qualquer funcionalidade de processamento de vídeo (linha pontilhada vermelha), sendo direcionados para registo de conta.
- *Extensões Funcionais:* O caso de uso principal `UC-VID-001` inclui obrigatoriamente a monitorização periódica do progresso do _job_ (`<<include>>`), sendo estendido opcionalmente por `FA2` (Recorte Rápido em _keyframes_ para subscritores `premium`) e `FA5` (Cancelamento voluntário da tarefa com estorno de quota diária).

== Modelo de domínio (atualizado)

O modelo de domínio da _baseline_ foi reformulado para responder às especificidades da manipulação de vídeo digital:

#figure(
  image("../images/modelo_dominio.png", width: 92%),
  caption: [Modelo de domínio atualizado com especialização multimédia e tarefas de processamento],
)

*Respostas aos pontos críticos de domínio:*
1. *Relação Vídeo vs. Imagem:* `Vídeo` e `Imagem` são especializações do conceito comum abstrato `RecursoMultimédia` (com atributos herdados de identificador, nome, data e tamanho em bytes). O conceito `Vídeo` introduz atributos essenciais do problema: duração temporal em segundos, resolução espacial (largura $times$ altura), taxa de fotogramas (_framerate_) e codecs obrigatórios (vídeo H.264 e áudio AAC).
2. *Composição dos Projetos:* Um `Projeto` atua como agregador unificado de recursos, passando a conter coleções mistas de imagens e vídeos ($0..*$), permitindo a coexistência de ambas as mídias no mesmo espaço de trabalho do utilizador.
3. *Trabalho de Processamento Assíncrono (`TrimJob`):* Como o processamento de vídeo não é instantâneo, introduziu-se a entidade explícita `TrabalhoProcessamento` (`TrimJob`). Modela o ciclo de vida da tarefa assíncrona através da enumeração `EstadoJob` (`QUEUED`, `PROCESSING`, `COMPLETED`, `FAILED`, `CANCELLED`), guardando os instantes inicial e final ($t_(i n)$ e $t_(o u t)$), progresso percentual e carimbos temporais. Quando concluído, referencia o novo `Vídeo` produzido como resultado.
4. *Representação de Quotas e Limites por Perfil:* A entidade `Utilizador` rege as restrições contratuais do modelo de negócio SaaS: quota diária de operações avançadas (`quotaDiariaOps = 5` para `free`, ilimitada para `premium`) e teto de armazenamento em disco na biblioteca (`limiteStorageBytes`: 1 GB para `free`, 5 GB para `premium`).

== Regras de negócio transversais

#tab([Regras de negócio transversais],
  tabela(
    colunas: (1.6cm, 1fr, 3.2cm, 3.2cm),
    tamanho: 8.5pt,
    [ID], [Regra], [Origem / justificação], [Requisitos],

    [RNG-01],
    [Formatos e Codecs do MVP: Aceitação e exportação restrita a contentores MP4 codificados com vídeo H.264 e áudio AAC.],
    [Garante compatibilidade universal de reprodução em navegadores HTML5 sem necessidade de transcodificação no cliente.],
    [REQ-VID-TRIM-012, REQ-VID-TRIM-016],

    [RNG-02],
    [Quota Diária de Operações Avançadas: Perfil `free` limitado a 5 operações/dia com reserva atómica na submissão e estorno em falha/cancelamento. Perfil `premium` ilimitado.],
    [Alinhado com a baseline (`FREE_DAILY_OP = 5`); protege contra esgotamento de workers por concorrência.],
    [REQ-VID-TRIM-005, REQ-VID-TRIM-007, REQ-VID-TRIM-016, REQ-VID-TRIM-022],

    [RNG-03],
    [Quotas de Armazenamento em Disco: Limite de 1 GB para contas `free` e 5 GB para contas `premium` na biblioteca permanente.],
    [Sustentabilidade dos custos de alojamento na cloud e incentivo comercial à subscrição do plano pago.],
    [REQ-VID-TRIM-021, REQ-VID-TRIM-023, REQ-VID-TRIM-024],

    [RNG-04],
    [Autenticação e Streaming Seguro: Ferramentas de vídeo exclusivas a utilizadores registados. Reprodução por HTTP Range com cookie temporário de 5 minutos.],
    [Prevenção de abuso de recursos computacionais por tráfego anónimo e proteção contra fuga de credenciais.],
    [REQ-VID-TRIM-019, REQ-VID-TRIM-027],
  ),
)

== Convenções de identificação

#tabela(
  colunas: (4.2cm, 1fr),
  [Identificador], [Utilização],
  [UC-VID-nnn], [Caso de uso de vídeo (numeração única no relatório, a partir de UC-VID-001)],
  [REQ-VID-{FUNC}-nnn], [Requisito (funcional ou não funcional); {FUNC} identifica a funcionalidade ou a área do serviço (e.g., TRIM, SUBMIT, STATUS); IDs nunca se reutilizam],
  [RN#emph[k], A#emph[k], Q#emph[k], FA#emph[k]], [Regra, assunção, questão em aberto e fluxo alternativo de um caso de uso (locais ao caso de uso; qualificados, e.g. `UC-VID-001/RN2`, nas tabelas partilhadas)],
  [RNG-nn / DQ-nnn], [Regra de negócio transversal / decisão de qualidade (globais)],
  [DA-nn], [Decisão arquitetural (Capítulo de Arquitetura)],
  [TST-{FUNC}-nn], [Teste (automático ou manual)],
  [T-nn], [Tarefa de manutenção corretiva da solução de base],
  [UCnn, RFnn, RNFnn], [Elementos do documento de requisitos de base (referidos quando são alterados — ALT)],
)
