#import "../template.typ": *

// =============================================================================
//  CASO DE USO — UC-VID-001: Carregar vídeo para um projeto (Upload)
// =============================================================================

== UC-VID-001 — Carregar vídeo para um projeto (_Upload_)

=== Cabeçalho

#tab([Caso de uso UC-VID-001 — Carregar vídeo para um projeto (_Upload_)],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-001],
    [Nome], [Carregar vídeo para um projeto],
    [Versão], [v2.0],
    [Autor], [Francisco Barbosa],
    [Data], [2026-10-14],
    [Objetivo], [Permitir que um utilizador carregue um vídeo para um projeto existente, ficando este associado ao projeto e disponível para processamento posterior.],
    [Âmbito], [Interface web do PictuRAS, API e serviço de armazenamento de ficheiros.],
    [Ator Principal], [Utilizador autenticado com permissão de edição no projeto.],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: Pretende adicionar um vídeo ao projeto e receber a confirmação do carregamento.
      - *Proprietário do sistema*: Pretende armazenar os vídeos de forma organizada e controlar a utilização de espaço e recursos.
      - *Equipa de desenvolvimento/operações*: Pretende disponibilizar uma referência persistente aos serviços de processamento sem prejudicar o carregamento de imagens.
    ],
    [Pré-condições], [
      - O utilizador tem sessão iniciada.
      - O projeto de destino existe e o utilizador tem permissão para o editar.
    ],
    [_Trigger_], [O utilizador escolhe a opção *Carregar vídeo* num projeto.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-001 — Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1],
    [O utilizador seleciona *Carregar vídeo* no projeto.],
    [Apresenta a opção de selecionar um ficheiro.],

    [2],
    [O utilizador seleciona um único ficheiro através do seletor do navegador.],
    [Apresenta o nome e o tamanho do ficheiro e verifica preliminarmente a extensão `.mp4` e, quando fornecido pelo navegador, o tipo declarado `video/mp4`.],

    [3],
    [O utilizador confirma o envio.],
    [Verifica se a sessão continua válida, se o utilizador mantém permissão de edição no projeto, se a versão do projeto está atual, se o tamanho do ficheiro respeita o limite do seu plano e se não existe no projeto um vídeo associado com o mesmo nome completo.],

    [4],
    [—],
    [Inicia a transferência do ficheiro e informa o utilizador de que a operação está em curso.],

    [5],
    [—],
    [Após receber o ficheiro, valida definitivamente o conteúdo real, confirmando MP4 válido e codec de vídeo H.264; se a validação for bem-sucedida, armazena o vídeo.],

    [6],
    [—],
    [Associa o vídeo ao utilizador e ao projeto existente, mantendo uma referência persistente que permite aos serviços de processamento obter o ficheiro.],

    [7],
    [—],
    [Confirma a conclusão do carregamento e apresenta o vídeo associado na lista de ficheiros do projeto, com nome e tamanho. A referência persistente fica disponível para utilização posterior por serviços de processamento.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-001 — Fluxos alternativos],
  tabela(
    colunas: (4.2cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição $->$ comportamento $->$ retorno)],
    [FA2 — Desistir antes de enviar],
    [Antes de confirmar o envio no Passo 3, o utilizador decide não prosseguir. O sistema não inicia o envio e o caso de uso termina sem adicionar um vídeo ao projeto.],
  ),
)

=== Exceções

#tab([UC-VID-001 — Exceções],
  tabela(
    colunas: (1fr, 1fr),
    [Condição], [Comportamento do Sistema],
    [No Passo 2, o tipo de ficheiro declarado não corresponde ao formato MP4.],
    [O sistema recusa o ficheiro, informa o utilizador e não inicia o envio.],

    [No Passo 3, o ficheiro excede 1 GB (1 000 000 000 bytes) para um utilizador do plano Free ou 5 GB (5 000 000 000 bytes) para um utilizador do plano Premium.],
    [O sistema recusa o envio e informa o utilizador.],

    [No Passo 3, a sessão expirou ou a autorização para editar o projeto deixou de ser válida.],
    [O sistema recusa o pedido e informa o utilizador de que tem de iniciar sessão novamente ou obter acesso ao projeto.],

    [No Passo 3, já existe no mesmo projeto um vídeo associado com o mesmo nome completo do ficheiro selecionado.],
    [No fluxo normal da interface, o sistema recusa o novo carregamento na pré-validação, antes de iniciar o pedido de transferência do ficheiro, e informa o utilizador de que precisa de alterar o nome. O vídeo existente mantém-se associado ao projeto.],

    [No Passo 3, a versão do projeto apresentada ao utilizador está desatualizada.],
    [O sistema recusa o pedido, atualiza os dados do projeto e informa o utilizador de que deve repetir a operação; não associa um novo vídeo.],

    [Durante o Passo 4, a ligação é interrompida.],
    [O sistema informa o utilizador de que o envio não foi concluído e não associa nem disponibiliza o vídeo para processamento. Uma nova tentativa começa desde o início.],

    [No Passo 5, a validação definitiva deteta que o conteúdo real do ficheiro não corresponde a um vídeo MP4 válido ou que o codec de vídeo não é H.264.],
    [O sistema rejeita o ficheiro, informa o utilizador e não associa nem disponibiliza o vídeo no projeto.],

    [No Passo 5, o armazenamento do vídeo falha ou o serviço de armazenamento fica indisponível.],
    [O sistema informa o utilizador de que o carregamento falhou e não associa nem disponibiliza o vídeo para processamento.],

    [No Passo 6, a associação ao projeto falha.],
    [O sistema informa o utilizador de que o carregamento não foi concluído e não apresenta o vídeo como disponível para processamento.],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [
    - O vídeo recebido, validado e armazenado fica associado ao utilizador e ao projeto existente, com referência persistente para processamento posterior.
    - O ficheiro de origem no dispositivo do utilizador não é alterado.
  ],
  [Garantia Mínima], [
    - Em caso de falha, o vídeo não fica associado como disponível para processamento.
    - O ficheiro de origem no dispositivo do utilizador não é alterado.
  ],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [*Autorização:* Só um utilizador autenticado com permissão de edição no projeto pode carregar um vídeo para esse projeto.],
  [RN2], [*Validação do ficheiro:* O sistema deve aceitar apenas ficheiros de vídeo no formato MP4 com codec de vídeo H.264. Após a receção do ficheiro, a validação definitiva deve verificar o conteúdo real, sem confiar apenas na extensão ou no tipo declarado. O tamanho máximo permitido por ficheiro é de 1 GB (1 000 000 000 bytes) para utilizadores do plano Free e de 5 GB (5 000 000 000 bytes) para utilizadores do plano Premium.],
  [RN3], [*Organização:* Cada vídeo carregado com sucesso deve ficar associado ao utilizador e ao projeto de destino.],
  [RN4], [*Integridade:* O sistema só deve indicar o vídeo como disponível para processamento depois de confirmar a transferência, validação, armazenamento e associação bem-sucedidos.],
  [RN5], [*Eficiência na transferência:* Cada upload deve usar transferência progressiva, sem manter o conteúdo integral do ficheiro em memória, e o pico de memória atribuível à transferência não deve exceder 1 000 000 000 bytes (1 GB), mesmo para ficheiros até ao limite máximo do plano.],
  [RN6], [*Nome repetido no projeto:* Se já existir um vídeo associado ao projeto com o mesmo nome completo do ficheiro selecionado, o sistema deve, no fluxo normal do frontend, rejeitar o novo carregamento na pré-validação antes de iniciar o pedido de transferência do ficheiro e informar o utilizador de que precisa de alterar o nome.],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [A premissa de que o SeaweedFS pode armazenar vídeos e de que os projetos no MongoDB podem manter as respetivas referências foi confirmada pela implementação e por um teste de integração com um MP4 pequeno.],
)

A1 mantém-se como assunção registada na baseline v1.10, entretanto sustentada pela evidência descrita. As decisões DQ-001 a DQ-005, introduzidas para a qualidade, constam da secção 4.3 do dossiê de requisitos; não representam decisões atribuídas ao docente ou à equipa.

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 5.5cm),
  [ID], [Questão], [Resolução],
  [QA-001],
  [Que valores quantitativos de tempo de resposta e disponibilidade devem ser aprovados para produção?],
  [O limite de memória por upload está definido em 1 000 000 000 bytes; a medição do pico continua pendente. Os alvos de resposta e disponibilidade ficam por fixar e medir.],

  [QA-002],
  [Deve existir uma política de retenção ou expiração dos vídeos? Se sim, qual?],
  [A ERS só exige persistência da referência; não define eliminação automática.],

  [QA-003],
  [Qual o nível de concorrência de uploads a suportar em produção?],
  [Alvo inicial: até 5 uploads simultâneos por instância do serviço `projects` e até 2 por utilizador. A capacidade deve ser confirmada por ensaios de carga antes da produção; o alvo ainda não foi validado.],
)
