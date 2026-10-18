#import "../template.typ": *

= Conclusão

== Síntese dos contributos do MVP

A implementação e especificação da extensão de vídeo no PictuRAS na Fase 1 atingiu com sucesso o seu objetivo nuclear: validar de ponta a ponta a viabilidade funcional do suporte a vídeo digital numa arquitetura orientada a microsserviços. 

Através da funcionalidade de recorte temporal (*_Trim_*), foram estabelecidos os alicerces estruturantes do ecossistema de vídeo:
1. *Infraestrutura Assíncrona e Desacoplada:* Criação de um pipeline assíncrono baseado em filas duráveis de mensagens RabbitMQ (`video_trim_queue`), garantindo que transformações pesadas de vídeo não bloqueiam as requisições HTTP da API nem afetam a responsividade dos serviços de imagem existentes.
2. *Nó de Execução Isolado com FFmpeg:* Contentorização autónoma do microsserviço `videoTrimWorker` com o motor nativo FFmpeg, operando com diretórios efémeros e purga sistemática de fragmentos intermédios em disco.
3. *Integridade do Modelo de Negócio:* Introdução de reserva atómica de operações diárias gratuitas (`FREE_DAILY_OP = 5`) no serviço `users` com garantia de estorno em caso de falha ou cancelamento voluntário, complementada pela fiscalização de quotas em disco (1 GB para `free` e 5 GB para `premium`).
4. *Segurança no Consumo de Mídia:* Implementação de streaming seguro com HTTP Range requests autenticado via cookies temporários HttpOnly de 5 minutos, eliminando a exposição de credenciais em URLs.

== O que ficou por fazer e justificação

Em estrita consonância com a filosofia de MVP, foram identificadas e assumidas as seguintes omissões:
- *Notificações em tempo real fora da página (`REQ-VID-TRIM-015` parcial):* Quando o utilizador encerra a sessão durante o processamento, o ficheiro resultante é gravado na biblioteca, mas não é emitido um alerta global de regresso por falta de multiplexação no gateway de WebSockets.
- *Testes sistemáticos de carga e ficheiros pesados (`REQ-VID-TRIM-025` e `026` parciais):* O desempenho foi verificado em ambiente de desenvolvimento com ficheiros de 5 segundos; a medição formal de latência percentil p95 e o teste com vídeos de 1080p a 60 fps e 60 minutos ficaram diferidos para a fase de produção.
- *Testes de Interface Gráfica Automatizados:* A validação do frontend foi efetuada manualmente e por compilação do Next.js, não tendo sido integradas ferramentas de automação E2E como Cypress ou Playwright.

== Lições aprendidas

O processo de extensão salientou a importância de pensar os fluxos de vídeo como entidades de ciclo de vida demorado desde o primeiro momento. Destaca-se a necessidade imperativa de transações atómicas para governança de quotas sob concorrência e os riscos de segurança associados ao encaminhamento de credenciais em URLs de mídia. A utilização assistida de agentes de IA revelou-se um acelerador notável na formalização rigorosa da ERS e na geração do esqueleto dos microsserviços, exigindo contudo vigilância humana contínua em aspetos subtis de sincronização A/V e políticas de segurança.

== Ligação à Fase 2: Requisitos Não Funcionais prioritários

Para a Fase 2 (refatoração e consolidação arquitetural), identificam-se como prioritários os seguintes requisitos não funcionais:
1. *Eficiência de Desempenho e Escalabilidade:* Introdução de aceleração por hardware (GPU/NVENC) nos nós de computação e paralelização em blocos temporais para reduzir o rácio de processamento para $T_("proc") <= 0.3 times$ tempo real.
2. *Interoperabilidade e Streaming Adaptativo:* Evolução do streaming progressivo HTTP Range em MP4 para protocolos adaptativos como HLS ou MPEG-DASH com geração automática de múltiplos perfis de resolução (720p, 1080p).
3. *Fiabilidade e Recuperabilidade Avançada:* Implementação de retoma de processamento a partir do último _checkpoint_ de _keyframes_ persistido, evitando reprocessar jobs longos desde o início em falhas transitórias de infraestrutura.
