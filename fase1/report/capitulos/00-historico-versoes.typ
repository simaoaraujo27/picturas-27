#import "../template.typ": *

#heading(numbering: none, outlined: false)[Histórico de versões]

#orientacao[
  Evolução da extensão de vídeo segundo os commits do repositório, por ordem cronológica decrescente.
  Commits consecutivos do mesmo autor estão reunidos; quando o autor volta a contribuir depois de outro,
  surge numa nova entrada.
]

#tab([Histórico de versões da extensão de vídeo e do respetivo relatório],
  tabela(
    colunas: (1.8cm, 2.4cm, 1fr, 3.5cm),
    [Versão], [Data], [Alterações], [Autores],
    [v2.8], [2026-10-22], [Inclusão no relatório da ERS, do impacto, da rastreabilidade, da arquitetura e dos testes da remoção de segmento de vídeo (UC-VID-003), com extensão das regras transversais RNG-01/RNG-02 e atualização do caso de uso para a v1.3.], [Carlos],
    [v2.7], [2026-10-21], [Inclusão no relatório do caso de uso de compilação de vídeos (UC-VID-004), com atualização das regras transversais, do impacto, da rastreabilidade e dos testes.], [Lara],
    [v2.6], [2026-10-20], [Inclusão no relatório do caso de uso de remoção de segmento de vídeo (UC-VID-003; 2828a21).], [Carlos],
    [v2.5], [2026-10-19], [Integração da compilação de vídeos no Docker e sincronização com a branch principal (d388b72, 3fd696b).], [Lara],
    [v2.4], [2026-10-19], [Especificação do carregamento de vídeo (UC-VID-001), revisão dos requisitos, arquitetura e rastreabilidade, e testes de upload (1f58c3e, 2cc4981).], [Francisco],
    [v2.3], [2026-10-19], [Integração da funcionalidade de remoção de segmento na branch principal (e739432).], [Carlos],
    [v2.2], [2026-10-19], [Implementação e integração do ajuste de velocidade de vídeo, com interface, serviço, worker e testes (58d4414, f2663d1).], [Nuno],
    [v2.1], [2026-10-19], [Implementação da remoção de segmento de vídeo, incluindo interface, processamento assíncrono, quotas e testes de integração (ab8f51c).], [Carlos],
    [v2.0], [2026-10-18], [Criação e desenvolvimento do relatório Typst; especificação do recorte, arquitetura, rastreabilidade, validação e diagramas. Correções na interface, no Docker e no processamento de recorte (cff2647–7ffe318).], [Simão],
    [v1.4], [2026-10-17], [Implementação da compilação de vídeos, com diálogo, fila de tarefas, worker e testes (3762b2d).], [Lara],
    [v1.3], [2026-10-15], [Desenvolvimento do requisito de recorte temporal no frontend, API e worker, com auditoria e testes (feca8c7).], [Simão],
    [v1.2], [2026-10-15], [Implementação do fluxo de recorte de vídeo, quotas, recuperação de tarefas, interface e testes de integração (eba7273).], [Francisco],
    [v1.1], [2026-10-14], [Primeira implementação do recorte temporal; evolução da interface de vídeo, exportação, validações e testes, seguida de melhorias no editor e na grelha de multimédia (c69f1d6–ef951b6).], [Simão],
    [v1.0], [2026-10-09], [Base de carregamento, armazenamento e acesso a vídeos; integração no frontend e na API (421adbc–43eda7a).], [Francisco],
  ),
)
