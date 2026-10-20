#import "../template.typ": *

// =============================================================================
//  CASO DE USO — UC-VID-003: Remover segmento do vídeo
// =============================================================================

== UC-VID-003 — Remover segmento do vídeo

=== Cabeçalho

#tab([Caso de uso UC-VID-003 — Remover segmento do vídeo],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-003],
    [Nome], [Remover segmento do vídeo],
    [Versão], [v1.2],
    [Autor], [PG63928; Carlos André Barroso Araújo],
    [Data], [2026-10-17],
    [Objetivo], [Permitir ao utilizador eliminar um intervalo temporal indesejado de um vídeo existente num projeto, gerando um novo vídeo resultante da união das partes restantes (ou da parte contínua restante, caso o corte incida num dos extremos), preservando integralmente o ficheiro original.],
    [Âmbito], [Módulo de edição de vídeo do PictuRAS — editor no cliente e pipeline de processamento no servidor.],
    [Ator Principal], [Utilizador autenticado do PictuRAS (plano Free ou Premium), com papel de proprietário ou permissão de edição no projeto.],
    [_Stakeholders_ e Interesses], [
      - *Proprietário / Editor do Projeto*: eliminar segmentos indesejados sem risco de perda de dados, mantendo o original bruto e obtendo um novo vídeo editado no projeto.
      - *Visualizadores*: consumir vídeos finais coesos e sem pausas ou trechos desnecessários.
      - *Proprietário do Sistema*: rentabilizar os planos de subscrição (através de quotas de armazenamento e priorização de tarefas de render) e gerir o esforço computacional dos _workers_.
    ],
    [Pré-condições], [
      - O utilizador está autenticado e possui permissão de edição no projeto.
      - O vídeo de origem encontra-se carregado e registado na lista de vídeos do projeto.
      - Os serviços de _API_, _media storage_ e _workers_ de vídeo estão operacionais.
    ],
    [_Trigger_], [No editor do projeto, o utilizador seleciona a ferramenta *Remover segmento* sobre um vídeo específico.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-003 — Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1],
    [O utilizador abre o projeto e seleciona um vídeo para editar.],
    [Apresenta o editor com o reprodutor, metadados do vídeo (duração, dimensões, formato) e controlos de edição.],

    [2],
    [O utilizador seleciona a ferramenta *Remover segmento*, marca na linha temporal (_timeline_) o intervalo temporal a eliminar e confirma a marcação no diálogo.],
    [Valida a consistência do corte, destaca visualmente o segmento a eliminar e regista a operação como pendente (_staged_) no editor.],

    [3],
    [O utilizador clica no botão *Aplicar* (_Apply_) na barra de ferramentas do projeto.],
    [Valida o controlo de versões do projeto (`X-Project-Version`), cria um _job_ de render assíncrono com a operação pendente, submete-o à fila de processamento e sinaliza visualmente o estado *em processamento*.],

    [4],
    [—],
    [O _worker_ consome a tarefa: descarrega o vídeo original do armazenamento interno, extrai a(s) parte(s) restante(s) exterior(es) ao intervalo marcado e gera o novo ficheiro MP4.],

    [5],
    [—],
    [Faz o _upload_ do novo vídeo para o armazenamento de _media_, associa o novo vídeo ao projeto (gerando um novo identificador e nome derivado), preservando o vídeo original, e atualiza a versão do projeto.],

    [6],
    [—],
    [Notifica a conclusão da operação (via _WebSocket_ / evento de projeto), adiciona o novo vídeo à galeria do projeto e disponibiliza de imediato a sua reprodução.],

    [7],
    [O utilizador revê o novo vídeo gerado e fecha o editor ou continua a trabalhar no projeto.],
    [Regista a conclusão da operação e mantém ambos os vídeos (original e editado) disponíveis no projeto.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-003 — Fluxos alternativos],
  tabela(
    colunas: (4.2cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição $->$ comportamento $->$ retorno)],
    [FA1 – Pré-visualizar resultado],
    [Em qualquer momento antes do Passo 3, o utilizador solicita a pré-visualização $->$ o reprodutor no cliente simula a reprodução unindo as partes antes e depois do corte (ou saltando a parte inicial/final eliminada), sem requerer render no servidor $->$ o utilizador pode reajustar as marcas (regressa ao Passo 2) ou avançar para o Passo 3.],

    [FA2 – Cancelar ou alterar operação pendente (_staged_)],
    [Antes de acionar o botão *Aplicar* (Passo 3), o utilizador cancela a operação ou reabre a ferramenta $->$ o sistema limpa ou atualiza o estado pendente no cliente, sem gerar encargos nem tarefas no servidor.],
  ),
)

=== Exceções

#tab([UC-VID-003 — Exceções],
  tabela(
    colunas: (1fr, 1fr),
    [Condição], [Comportamento do Sistema],
    [O formato/_codec_ do vídeo não é compatível com o _pipeline_ de edição (Passo 1 / _Trigger_)],
    [Ao validar os parâmetros de entrada e metadados do vídeo, rejeita o pedido, apresenta a notificação «Formato de vídeo não suportado para edição» e mantém o projeto inalterado.],

    [Marcação temporal inconsistente ou inválida no diálogo (Passo 2)],
    [O sistema bloqueia a confirmação no diálogo, assinala os campos com erro e impede o registo da operação como pendente até correção dos valores ($0 "s" <= t_"início" < t_"fim" <= "duração"$).],

    [Duração útil restante inferior a 1,0 s no diálogo (Passo 2)],
    [O sistema rejeita a confirmação com a notificação «A duração resultante do vídeo deve ser igual ou superior a 1,0 s» e mantém o diálogo aberto para ajuste das marcas.],

    [O _job_ de render falha ou excede o tempo limite no _worker_ (Passo 4)],
    [Notifica o erro («Não foi possível concluir a remoção do segmento»), limpa o estado de processamento; o vídeo original e o projeto permanecem intactos, sem criação de ficheiros corrompidos.],

    [Conflito de versão no projeto (`X-Project-Version`) no momento de aplicar (Passo 3)],
    [Rejeita a submissão com erro de conflito de concorrência («O projeto foi alterado por outro utilizador») e solicita a atualização do projeto antes de submeter novamente a operação.],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [
    - Um novo vídeo (sem o segmento removido) é criado e adicionado ao projeto com metadados próprios e nome derivado.
    - O ficheiro original mantém-se intacto e acessível.
    - A versão do projeto é incrementada.
  ],
  [Garantia Mínima], [
    - O vídeo original permanece inalterado e reproduzível.
    - Nenhum ficheiro corrompido é associado ao projeto.
    - O estado de processamento pendente é limpo.
    - O utilizador é notificado da falha.
  ],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [*Autorização:* Apenas utilizadores autenticados (com plano Free ou Premium) com permissão de proprietário ou edição no projeto podem executar a remoção de segmentos em vídeos.],
  [RN2], [*Consistência do intervalo temporal:* A marcação do segmento a eliminar deve ser consistente: $0 "s" <= t_"início" < t_"fim" <= "duração do vídeo"$. Caso o corte seja intermédio ($0 < t_"início" < t_"fim" < "duração"$), o resultado une as partes anterior e posterior; caso o corte incida numa das extremidades ($t_"início" = 0$ ou $t_"fim" = "duração"$), o resultado corresponde à extração simples da parte restante contínua.],
  [RN3], [*Duração mínima do resultado:* A duração combinada do vídeo resultante (soma da(s) parte(s) restante(s)) tem de ser igual ou superior a 1,0 s (não é permitido eliminar a quase totalidade do vídeo).],
  [RN4], [*Não-destrutividade:* A edição é não-destrutiva por omissão no MVP: o ficheiro original nunca é sobrescrito ou eliminado pelo fluxo normal da operação; o resultado da remoção é sempre gravado como um novo recurso multimédia no projeto.],
  [RN5], [*Ciclo de staging:* A submissão do processamento ao servidor segue o ciclo de _staging_ do editor: a definição do intervalo fica pendente (_staged_) no cliente após confirmação no diálogo e só é submetida ao servidor quando o utilizador aciona o botão *Aplicar* (_Apply_), sujeita à validação da versão do projeto.],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [O PictuRAS organiza o conteúdo multimédia em torno de Projetos, com controlo de concorrência otimista (`X-Project-Version`) e partilha de acessos.],
  [A2], [O _pipeline_ de processamento assíncrono (RabbitMQ e _Workers_ com FFmpeg) é partilhado entre operações de vídeo (_Trim_, Remoção de Segmento, etc.).],
  [A3], [O editor no cliente fornece uma linha temporal (_timeline_) com precisão mínima de 0,1 s para marcação temporal.],
  [A4], [A pré-visualização (FA1) é simulada localmente no cliente através do controlo da posição de reprodução do vídeo original.],
  [A5], [O modelo de edição não-destrutiva é adotado uniformemente, salvaguardando as gravações originais do utilizador contra edições acidentais.],
  [A6], [Os metadados do novo vídeo (duração, tamanho, miniatura, _codec_ H.264/AAC) são calculados e registados na conclusão bem-sucedida do render.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Questão],
  [Q1], [Como gerir as quotas globais de armazenamento do utilizador quando múltiplos vídeos derivados (cortes e _trims_) são acumulados no mesmo projeto?],
  [Q2], [Deve ser disponibilizada uma opção opcional avançada de «Substituir original» caso o utilizador pretenda poupar espaço no seu plano de armazenamento?],
  [Q3], [Devem ser geradas miniaturas (_thumbnails_) específicas na transição do ponto de corte para permitir inspeção visual antes de aplicar o corte definitivo?],
  [Q4], [A simulação da pré-visualização no cliente deve suportar transições suaves (ex.: pequeno _crossfade_ de áudio) no ponto de junção das partes?],
)
