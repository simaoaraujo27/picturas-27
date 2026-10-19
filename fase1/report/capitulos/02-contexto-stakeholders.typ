#import "../template.typ": *

= Contexto, Perfis e _Stakeholders_ (revisão)

#orientacao[
  Capítulo de *revisão*: só registam o que muda com o vídeo. Não copiem o documento de base.
  - Os *perfis de utilização* (anónimo, registado, premium) continuam válidos? Que limites passam a
    existir para vídeo (duração, tamanho, resolução, nº de operações)? Um vídeo conta como uma operação?
  - Surgem *novos _stakeholders_* ou *interesses novos* nos existentes (e.g., custo de processamento e armazenamento
    para o proprietário do sistema; equipa de operações)?
  - Os _stakeholders_ aqui listados devem ser os mesmos que aparecem na secção "_Stakeholders_ e Interesses"
    de cada caso de uso — usem os mesmos nomes.
]

== Perfis de utilização e vídeo

A introdução de mídia em vídeo, pelo seu elevado consumo de tempo de computação e espaço em disco, exige uma revisão e densificação dos limites atribuídos a cada perfil de utilização do PictuRAS:

#tab([Perfis de utilização e respetivo acesso a vídeo],
  tabela(
    colunas: (2.4cm, 3.8cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [Perfil], [Situação na _baseline_], [Alteração introduzida para vídeo], [Regras / requisitos],

    [Anónimo \ (`anonymous`)],
    [Acesso livre a operações básicas de edição de imagem sem autenticação.],
    [Estritamente impedido de aceder ou executar processamento de vídeo. Encaminhado na interface para a criação de conta gratuita ou início de sessão.],
    [RN7, RNG-04, \ REQ-VID-TRIM-019],

    [Registado \ (`free`)],
    [Quota diária de 5 operações para transformações síncronas de imagens.],
    [Mantém a quota de 5 operações avançadas por dia (`FREE_DAILY_OP = 5`), onde 1 recorte de vídeo concluído consome exatamente 1 operação (com reserva atómica provisória). Limite de duração de excerto de 180 s (3 minutos) e quota de armazenamento na biblioteca de 1 GB.],
    [RN1, RN2, RN6, RNG-02, \ REQ-VID-TRIM-005, \ REQ-VID-TRIM-006, \ REQ-VID-TRIM-021],

    [Subscritor \ (`premium`)],
    [Uso ilimitado de transformações e ferramentas avançadas de IA.],
    [Operações diárias ilimitadas. Limite alargado de duração de excerto até 60 minutos (1 hora). Acesso à funcionalidade de Recorte Rápido (_stream copy_ em keyframes) e quota de armazenamento em disco alargada para 5 GB.],
    [RN1, RN2, RN6, \ REQ-VID-TRIM-011, \ REQ-VID-TRIM-021],
  ),
)

== _Stakeholders_ e interesses

Os agentes com interesse no sistema viram os seus requisitos e preocupações evoluírem face aos desafios colocados pelo vídeo digital:

#tab([_Stakeholders_ e interesses revistos com o suporte a vídeo],
  tabela(
    colunas: (3.2cm, 1.8cm, 1fr, 1.8cm, 2.6cm),
    tamanho: 8.5pt,
    [_Stakeholder_], [Estado], [Interesse(s) relativamente ao vídeo], [Influência], [UC / requisitos],

    [Utilizador],
    [Revisto],
    [Pretende isolar excertos de vídeo de forma rápida, com interface interativa, controlo temporal rigoroso ao centésimo de segundo e sem perda de sincronização áudio/vídeo.],
    [Alta],
    [UC-VID-002, \ REQ-VID-TRIM-001..003, \ REQ-VID-TRIM-010],

    [Proprietário do Sistema (SaaS)],
    [Revisto],
    [Pretende rentabilizar a plataforma fazendo cumprir o modelo comercial (limite de 5 ops/dia e 1 GB em `free`, incentivando o upgrade `premium` com 5 GB), controlando custos de infraestrutura e prevenindo o abuso de nós de computação por tráfego anónimo.],
    [Alta],
    [UC-VID-002, RN1, RN6, \ REQ-VID-TRIM-005, \ REQ-VID-TRIM-019, \ REQ-VID-TRIM-021],

    [Equipa de Desenvolvimento e Operações],
    [Novo],
    [Pretende garantir a estabilidade e manutenibilidade do sistema, isolando a carga pesada de vídeo em filas assíncronas e workers Docker com FFmpeg, sem bloquear o gateway nem degradar o tráfego existente de imagens.],
    [Média],
    [UC-VID-002, DQ-001, \ REQ-VID-TRIM-008, \ REQ-VID-TRIM-028],
  ),
)

== Elicitação de requisitos e fundamentação dos valores-alvo

A elicitação dos requisitos, regras e valores numéricos resultou da análise aprofundada da base de código legada do PictuRAS (`users.js`, `mediaStorageService`), de sessões de levantamento de requisitos baseadas nas _guidelines_ da Fase 1, e do estudo comparativo de plataformas de manipulação multimédia na nuvem. Os valores-alvo numéricos obedecem às seguintes justificações:
1. *Quota diária de 5 operações no perfil Free (`FREE_DAILY_OP = 5`):* Herdada da _baseline_ de imagens para preservar a coerência das regras de negócio existentes. Decidiu-se que 1 trabalho assíncrono de recorte equivale ao consumo de 1 unidade de quota avançada.
2. *Quotas de armazenamento em disco (1 GB para `free` e 5 GB para `premium`):* Dimensionadas a partir da taxa de dados média de vídeo MP4 a 1080p ($approx 8$ Mbps $approx$ 60 MB/minuto). Uma conta gratuita de 1 GB permite armazenar aproximadamente 15 a 17 minutos de vídeo agregado, permitindo experimentação real sem onerar os custos de armazenamento do serviço. O teto de 5 GB para `premium` cobre projetos extensos com margem substancial.
3. *Limites de duração (180 segundos em `free` vs. 60 minutos em `premium`):* O teto de 3 minutos no escalão gratuito foi estabelecido para garantir que o tempo de recodificação em CPU padrão (2 vCPUs) não ultrapasse 2 a 3 minutos, prevenindo filas de espera prolongadas e partilha justa de nós de computação.
4. *Duração mínima de 1.0 segundo e precisão de centésimos (RN3):* Necessária para prevenir erros de divisão por zero em utilitários de mídia e evitar a geração de contentores MP4 vazios ou sem fotogramas-chave viáveis.
