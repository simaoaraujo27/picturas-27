#import "../template.typ": *

#set heading(numbering: "A.1.")
#counter(heading).update(0)

= Instruções de execução

== Pré-requisitos
Para lançar e validar a solução entregue (`solucao-ext-mvp.zip`), é necessário dispor de:
- Docker Engine versão $>= 24.0$ e Docker Compose v2 instalados;
- Python 3.9+ com a biblioteca `requests` para execução da suite de testes (`pip install requests`);
- Utilitário `ffprobe` (pacote `ffmpeg`) instalado localmente para inspeção de streams no teste de integração.

== Procedimento de arranque da plataforma
1. *Navegar para a diretoria do projeto:*
   ```bash
   cd picturas-27
   ```
2. *Lançar a orquestração de microsserviços:*
   ```bash
   docker compose up -d --build
   ```
   _Nota:_ O comando constrói e inicializa todos os serviços necessários: `api_gateway`, `projects`, `users`, `mediaStorageService`, `video_trim_worker`, `frontend`, `rabbitMQ`, `seaweedfs`, bem como as instâncias do MongoDB.
3. *Verificar o estado dos contentores:*
   ```bash
   docker compose ps
   ```
   Todos os serviços devem figurar em estado `Up` ou `running`.
4. *Aceder à aplicação web:*
   Abrir o navegador em `https://localhost:8080/` (aceitar o certificado TLS autoassinado de desenvolvimento).

== Execução dos testes

=== Integração ponta a ponta
A validação funcional ponta a ponta do Trim é executada através do script de integração em Python:
```bash
python3 tests/trim_integration.py
```
*O que o teste valida automaticamente:*
- Autenticação e criação temporária de utilizador e projeto;
- Upload de vídeo MP4 e cálculo de hash SHA-256 de referência;
- Submissão de recorte com parâmetros válidos e obtenção de Job ID;
- Monitorização de ciclo de vida assíncrono até ao estado `COMPLETED`;
- Verificação de metadados do vídeo resultante (duração $2.52$s para corte de $2.50$s, codecs H.264 e AAC);
- Preservação estrita da integridade do ficheiro original (verificação de hash invariante);
- Débito e esgotamento da quota diária Free após 5 operações;
- Cancelamento voluntário de tarefas em fila com estorno automático de quota;
- Streaming seguro via cookie temporário e pedidos parciais HTTP Range (HTTP 206);
- Limpeza sistemática de todos os dados e utilizadores de teste criados.

=== Suites por componente e verificação manual

Os comandos seguintes partem da raiz do repositório, com dependências npm instaladas nos serviços, Node compatível com o script frontend, Python com as dependências de videoSpeedWorker/requirements.txt e FFmpeg/ffprobe no PATH para os testes sintéticos. São instruções de reprodução; não foram executadas nesta edição documental.

#raw("npm --prefix projects test\nnpm --prefix apiGateway test\nnpm --prefix frontend run test:video-speed\npython -m unittest discover -s videoSpeedWorker -p test_worker.py -v", block: true, lang: "powershell")

Estas suites não são um E2E automatizado de speed. Para confirmar o percurso real, usar a stack Docker com video_speed e um utilizador com edição, carregar um MP4/H.264 de 10 s e submeter os casos de duração do capítulo de testes. Verificar HTTP 202, logs de Projects/video_speed, upload do novo objeto, resultado e add-video; confirmar a biblioteca, o incremento de versão e a disponibilidade do original. Inspecionar o output com ffprobe, sem usar a duração para estimar bytes da quota.

Para consultar os serviços sem os reiniciar:

#raw("docker compose ps\ndocker compose logs --since 10m projects video_speed img_storage api_gateway", block: true, lang: "powershell")

As imagens têm de corresponder ao código atual; o serviço de speed usa ./videoSpeedWorker e a chave interna de vídeo configurada nos serviços envolvidos. A inclusão de speed não altera o procedimento de integração de Trim acima.

= Glossário

#tab([Glossário de termos técnicos do domínio de vídeo],
  tabela(
    colunas: (4.2cm, 1fr),
    [Termo], [Definição no contexto do PictuRAS],

    [Recorte Temporal (_Trim_)],
    [Operação de edição digital que consiste em isolar um intervalo contínuo delimitado por instantes $[t_(i n), t_(o u t)]$, descartando o material anterior e posterior.],

    [Fotograma-chave (_Keyframe_ / I-frame)],
    [Fotograma completo comprimido sem referência a outros fotogramas. Serve de ponto de ancoragem temporal em fluxos de vídeo compactados.],

    [Cópia de Fluxo (_Stream Copy_)],
    [Técnica de recorte rápido sem descompressão nem recodificação de fotogramas, copiando pacotes diretamente entre contentores em tempo quasi-instantâneo.],

    [Transcodificação / Recodificação],
    [Processo de descodificar fluxos comprimidos de áudio/vídeo e voltar a codificá-los, permitindo cortes com precisão exata ao fotograma (_frame-accurate_).],

    [Contentor MP4],
    [Formato de ficheiro padrão (ISO/IEC 14496-14) que encapsula fluxos de vídeo (comumente H.264/AVC) e fluxos de áudio (AAC) com suporte nativo em navegadores HTML5.],

    [Trabalho de Processamento (_Job_)],
    [Registo que acompanha o ciclo de vida de uma tarefa computacional assíncrona, transitando entre os estados `QUEUED`, `PROCESSING`, `COMPLETED`, `FAILED` e `CANCELLED`.],

    [HTTP Range Requests],
    [Mecanismo da norma HTTP (RFC 7233) que permite ao cliente solicitar segmentos parciais de um recurso multimédia (bytes $x-y$), viabilizando navegação temporal (_seeking_) sem descarregar o ficheiro completo.],
  ),
)
