#import "../template.typ": *

= Introdução

== Propósito do incremento

O projeto PictuRAS é uma plataforma web orientada a microsserviços originalmente concebida para o processamento e transformação de imagens digitais. O presente incremento tem como propósito central estender o ecossistema com suporte à manipulação de vídeo digital, seguindo rigorosamente uma lógica de *Produto Mínimo Viável (MVP)*.

O foco da Fase 1 reside na validação funcional ponta a ponta do ciclo de vida multimédia: ingestão de ficheiros pesados, parametrização interativa de operações temporais, orquestração assíncrona orientada a filas de mensagens com RabbitMQ, execução de tarefas demoradas em nós de computação isolados com binário nativo FFmpeg e entrega segura dos artefactos gerados via _streaming_ controlado. O MVP abrange cinco casos de uso: Upload, Trim, remoção de segmento, compilação e alteração de velocidade. A evidência de implementação e validação é desigual entre os fluxos e é discriminada nos capítulos 7 e 10. As operações de vídeo coexistem com os serviços de imagem herdados da _baseline_.

== _Baseline_ e repositório

A extensão assenta sobre a solução desenvolvida no ano letivo transato e disponibilizada pelo corpo docente, operando numa lógica de extensão aditiva e não de reescrita.

#tab([Artefactos da baseline e identificação da versão entregue],
  tabela(
    colunas: (5.5cm, 1fr),
    [Artefacto], [Versão / referência],
    [Documento de requisitos de base], [doc-ext-requisitos.pdf (PictuRAS v27.1)],
    [Documento de solução arquitetural de base], [doc-sol-arquitetural.pdf (PictuRAS v27.1)],
    [Repositório de partida], [https://github.com/simaoaraujo27/picturas-27 (commit `4de8696`)],
    [Versão de trabalho da solução], [Repositório local de integração; o pacote `solucao-ext-mvp.zip` é gerado a partir desta versão para entrega.],
  ),
)

== Organização do documento

O relatório encontra-se estruturado em três partes complementares:
- *Parte I — Enquadramento e Visão Transversal (Capítulos 1 a 3):* Apresenta o contexto, a evolução dos perfis e _stakeholders_, a justificação da funcionalidade no MVP, as regras de negócio transversais e as versões atualizadas do diagrama de casos de uso e do modelo de domínio.
- *Parte II — Especificação das Funcionalidades de Vídeo (Capítulos 4 a 7):* Detalha os cinco casos de uso `UC-VID-001` a `UC-VID-005`, o catálogo formal de requisitos da ERS (funcionais com critérios _Dado… Quando… Então…_ e não funcionais segundo a ISO/IEC 25010), a análise de impacto no sistema existente e a matriz completa de rastreabilidade.
- *Parte III — Arquitetura, IA e Validação (Capítulos 8 a 12 e Anexos):* Descreve o delta da arquitetura de microsserviços, o registo de decisões arquiteturais (ADRs), o diagrama de sequência do processamento, a documentação e validação crítica do apoio de agentes de IA, a estratégia e evidência dos testes de integração executados, a manutenção corretiva da _baseline_, conclusões e manual de execução.
