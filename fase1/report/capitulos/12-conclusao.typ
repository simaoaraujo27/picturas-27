#import "../template.typ": *

= Conclusão

== Síntese dos contributos do MVP

A implementação e especificação da extensão de vídeo no PictuRAS procurou validar a viabilidade funcional do suporte a vídeo numa arquitetura orientada a microsserviços, incluindo os contributos complementares de: o carregamento de vídeos para projetos existentes (UC-VID-001), o recorte temporal (UC-VID-002) e a alteração de velocidade (UC-VID-005).

O UC-VID-001 integra nos projetos existentes o carregamento de ficheiros MP4 com vídeo H.264, condicionado por autenticação, permissão de edição e limites por ficheiro definidos para os planos Free (1 000 000 000 bytes) e Premium (5 000 000 000 bytes). O pedido é encaminhado em stream pelo API Gateway e pelo `mediaStorageService` até ao SeaweedFS; os metadados e a referência do vídeo ficam associados ao projeto no MongoDB. O fluxo usa armazenamento temporário em disco e buffers limitados, pelo que o streaming evita manter o ficheiro completo em memória, sem significar memória constante nem comprovar, por si só, o limite de pico especificado.

O UC-VID-002 complementa esta ingestão e estabelece os alicerces do processamento de vídeo:
1. *Infraestrutura Assíncrona e Desacoplada:* Criação de um pipeline baseado em filas duráveis RabbitMQ (`video_trim_queue`), para que as transformações não bloqueiem os pedidos HTTP nem os serviços de imagem existentes.
2. *Nó de Execução Isolado com FFmpeg:* Contentorização autónoma do microsserviço `videoTrimWorker`, com diretórios efémeros e limpeza de ficheiros intermédios.
3. *Integridade do Modelo de Negócio:* Reserva atómica de operações diárias gratuitas (`FREE_DAILY_OP = 5`), com estorno em caso de falha ou cancelamento, e aplicação de quotas de armazenamento por perfil (1 GB para `free` e 5 GB para `premium`).
4. *Segurança no Consumo de Média:* Reprodução segura com pedidos HTTP Range e cookies temporários HttpOnly, sem expor credenciais em URLs.

O UC-VID-005 acrescenta alteração de velocidade por múltiplos intervalos (0,5x/1x/2x), mantendo a escala 1x no restante conteúdo e ajustando o áudio existente. O worker independente e o contrato assíncrono existente produzem um novo vídeo no projeto sem substituir o original. O tamanho real é integrado em videoQuota, com confirmação ou compensação condicionada. A evidência é histórica e distingue testes isolados, FFmpeg real e E2E manual comunicado.

== O que ficou por fazer e justificação

Em estrita consonância com a filosofia de MVP, foram identificadas e assumidas as seguintes omissões:
- *Notificações em tempo real fora da página (`REQ-VID-TRIM-015` parcial):* Quando o utilizador encerra a sessão durante o processamento, o ficheiro resultante é gravado na biblioteca, mas não é emitido um alerta global de regresso por falta de multiplexação no gateway de WebSockets.
- *Testes sistemáticos de carga e ficheiros pesados (`REQ-VID-TRIM-025` e `026` parciais):* O desempenho foi verificado em ambiente de desenvolvimento com ficheiros de 5 segundos; a medição formal de latência percentil p95 e o teste com vídeos de 1080p a 60 fps e 60 minutos ficaram diferidos para a fase de produção.
- *Validação de desempenho do Upload:* O Capítulo 10 regista uma medição de memória para um ficheiro de 128 000 000 bytes; não documenta medições para ficheiros nos limites dos planos nem ensaios de concorrência. A capacidade e a configuração do SeaweedFS também devem ser avaliadas sob carga. O carregamento por arrastar e largar permanece adiado, conforme o dossiê.
- *Cobertura E2E abrangente:* Apesar dos testes automatizados registados para o Upload e da suite de integração do Trim, não existe cobertura E2E abrangente de todos os fluxos da aplicação.
- *Acompanhamento e robustez das operações de velocidade:* Progresso persistente, cancelamento após submissão e alerta terminal de falha estão adiados (REQ-VID-SPEED-013, 016 e 038). A quota diária, as metas de desempenho e a precisão geral não estão aprovadas. Recolha de órfãos, falhas persistentes e concorrência real exigem consolidação e ensaios próprios.

== Lições aprendidas

O processo de extensão salientou a importância de considerar o ciclo de vida completo dos vídeos. No Upload, o encaminhamento progressivo e os buffers limitados reduzem a necessidade de manter o ficheiro integral em memória, mas só medições em ficheiros de maior dimensão permitem avaliar o consumo real. A coordenação entre o objeto no SeaweedFS e os metadados no MongoDB, bem como a limpeza e a recuperação perante falhas, são essenciais para evitar referências incompletas. Os ensaios devem também considerar a capacidade efetiva da infraestrutura. No Trim, destacam-se a necessidade de reservas atómicas de quota sob concorrência e os riscos de expor credenciais em URLs de média. A utilização assistida de agentes de IA apoiou a especificação e a implementação, mantendo necessária a revisão humana de aspetos como a sincronização A/V e as políticas de segurança.

== Ligação à Fase 2: Requisitos Não Funcionais prioritários

Para a Fase 2 (refatoração e consolidação arquitetural), identificam-se como prioritários os seguintes requisitos não funcionais:
1. *Eficiência de Desempenho e Escalabilidade:* Introdução de aceleração por hardware (GPU/NVENC) nos nós de computação e paralelização em blocos temporais para reduzir o rácio de processamento para $T_("proc") <= 0.3 times$ tempo real. Para o Upload, realizar ensaios com ficheiros de maior dimensão e concorrência, medindo memória e utilização de disco, e avaliar a otimização dos recursos utilizados.
2. *Interoperabilidade e Streaming Adaptativo:* Evolução do streaming progressivo HTTP Range em MP4 para protocolos adaptativos como HLS ou MPEG-DASH com geração automática de múltiplos perfis de resolução (720p, 1080p).
3. *Fiabilidade e Recuperabilidade Avançada:* Implementação de retoma de processamento a partir do último _checkpoint_ de _keyframes_ persistido, evitando reprocessar jobs longos desde o início em falhas transitórias. Para o Upload, avaliar a configuração, a capacidade e a monitorização dos volumes do SeaweedFS, reforçar a limpeza de objetos e temporários e a recuperação de falhas de transferência; poderá também ser avaliada a retoma de uploads interrompidos.
