#import "../template.typ": *

#heading(numbering: none, outlined: false)[Histórico de versões]

#orientacao[
  Secção opcional. Registem as versões relevantes do documento (e.g., primeira versão de um caso de uso, primeira versão da
  especificação de requisitos, …, versão entregue).
]

#tab([Histórico de versões do relatório de extensão de requisitos],
  tabela(
    colunas: (1.8cm, 2.4cm, 1fr, 3.5cm),
    [Versão], [Data], [Alterações], [Autores],
    [v1.0], [2026-10-06], [Primeira versão do caso de uso de vídeo (UC-VID-001) e requisitos iniciais.], [Simão Araújo],
    [v1.1], [2026-10-14], [Atualização do caso de uso e ERS completa com critérios Dado/Quando/Então (Exercício 2).], [Simão Araújo],
    [v2.0], [2026-10-18], [Versão final da Fase 1: integração de arquitetura, testes automatizados e relatório Typst.], [Simão Araújo],
  ),
)
