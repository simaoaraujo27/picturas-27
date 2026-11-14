#set document(title: "Usabilidade — trabalho em segundo plano: métricas e avaliação")
#set page(paper: "a4", margin: 2cm)
#set text(size: 11pt, lang: "pt")
#set heading(numbering: "1.1")

= Usabilidade — trabalho em segundo plano: métricas e avaliação

Documento de trabalho iniciado em 14 de novembro de 2026.

*Responsabilidade:* diagnóstico, quantificação, baseline, refactoring do frontend e não-regressão do requisito de usabilidade.

*Objetivo:* demonstrar, com medições reproduzíveis, que o utilizador passa a poder continuar a usar a aplicação enquanto um projeto é processado, sem alterar o comportamento funcional do processamento.

*Estado (14 de novembro de 2026):* alteração do frontend feita. Baseline e medição final recolhidas no mesmo dia, com o inspetor do browser e testes manuais (ver as secções de resultados). 

== Definir o que vai ser avaliado

*Classificação:* Usabilidade → Operabilidade, segundo a ISO/IEC 25010:2011. Ideia de partida das diretrizes da Fase 2: "Usabilidade — trabalho em segundo plano". As métricas abaixo são escolhas operacionais da equipa, não prescritas pela norma.

*Âmbito:* ecrã de processamento e interação do utilizador durante o processamento, em `frontend/app/dashboard/[pid]/page.tsx`.

*Decisão de âmbito (14 de novembro de 2026):* Desbloquear interface durante o processamento.

*Commit de partida:* a baseline foi medida no commit `c98fd47111162f2a4e24948fb80287e0a35c0f26` (resultado de `git rev-parse HEAD` na `main` do fork da equipa, a 14 de novembro de 2026). O documento de manutenibilidade usa `ab3ae9cf8efcfa444e9599f8e291551c5930c289`.

*Fragilidade indicada nas diretrizes (a confirmar no código e por observação):* durante o processamento, um ecrã sobreposto bloqueia toda a aplicação; o progresso existe apenas no browser e perde-se com um refresh.

*Observação nossa (baseline, 14 de novembro de 2026):* o ecrã sobreposto cobre a área de conteúdo do projeto, mas não a barra lateral, que continua utilizável.

*Não-regressão funcional:* o processamento de imagens e de vídeos deve manter-se igual. O refactoring visa só a operabilidade durante o processamento.

== Métricas

*Área da janela obstruída durante o processamento.* É a percentagem da janela coberta pelo elemento de processamento visível: largura × altura do elemento ÷ (`innerWidth` × `innerHeight`) × 100. Mede-se com o inspetor do browser (Ctrl+Shift+C), selecionando o elemento enquanto o processamento decorre e anotando as suas dimensões. Na baseline, o ecrã sobreposto ocupava 1280 × 695 px visíveis numa janela de 1536 × 695,2 px, ou seja, 83,3 %. Na versão final, o cartão ocupa 289,6 × 169,6 px, ou seja, 4,6 %. 

*Valor na base:* 83,3 %. *Valor final medido:* 4,6 %. 

== Preparar e recolher a baseline

*Ambiente:* Windows 11, Docker Desktop com `docker compose` (v5.5.1), navegador baseado em Chromium com as DevTools do Chrome (	157.0.8103.51), CPU e RAM por registar. Janela de teste: viewport de 1536 × 695,2 px CSS, com a barra lateral a ocupar 256 px; as capturas têm 1917 px de largura, o que sugere uma escala de 125 % do Windows.

*Comando de arranque:* `docker compose up -d --build`; Ctrl+Shift+R no browser depois de reconstruir o frontend.

*Projeto de teste:* projeto `test1` com três vídeos de 6,0 s, 10,0 s e 176,6 s (`sample`), com a ferramenta de legendagem automática aplicada. O vídeo longo faz o ecrã de processamento durar tempo suficiente para medir.

*Resultados da baseline (14 de novembro de 2026, código original):*
- Janela: 1536 × 695,2 px CSS; barra lateral de 256 px.
- Elemento de bloqueio: `div` com `absolute top-0 left-0 h-screen w-screen bg-black/70 z-50` (`frontend/app/dashboard/[pid]/page.tsx`, perto da linha 903). A caixa mede 1536 × 695,2 px e é cortada pelo `overflow-hidden` do `main` do layout, ficando visíveis 1280 × 695 px. 1280 ÷ 1536 = 83,3 % da janela.

#figure(
  image("evidencias_usabilidade/baseline-01-overlay-inspetor-58pct.png", width: 90%),
  caption: [Baseline: ecrã sobreposto a 58 %, com o inspetor a mostrar 1280 × 695 px visíveis.],
)

- Cartão do ecrã de processamento: 417,6 × 169,6 px.

#figure(
  image("evidencias_usabilidade/baseline-02-cartao-inspetor-56pct.png", width: 90%),
  caption: [Baseline: cartão do ecrã de processamento a 56 %, com o inspetor a mostrar 417,6 × 169,6 px.],
)

- A barra lateral não ficou escurecida e clicar em `test1` respondeu: a vista passou para a grelha de ficheiros e o ecrã de processamento voltou a aparecer, a 38 %.
- Fim do processacapturasmento na baseline: por registar.
- Evidência: ver as figuras desta secção.

== Refactoring

*Alteração feita:* `frontend/app/dashboard/[pid]/page.tsx`, para o ecrã de processamento deixar de bloquear a interação. Só mudamos classes CSS: o `div` exterior passou de `absolute top-0 left-0 h-screen w-screen bg-black/70 z-50 flex justify-center items-center` para `fixed bottom-4 right-4 z-50`; o `Card` perdeu `justify-center` e ganhou `shadow-lg`; a `Progress` passou de `w-96` a `w-64`.

*Decisões e alternativas consideradas:*
- Escolhida: cartão fixo no canto inferior direito, na própria página, que mantém a barra de progresso, a percentagem e o botão Cancelar.
- Alternativa: manter o ecrã sobreposto com botão de fechar. O problema de fundo mantém-se.

== Criar a verificação de não-regressão

*Funcional:* o processamento de imagens e de vídeos termina e o resultado é igual ao da baseline (número de ficheiros, nomes, tipos de resultado).

*Prova de que só mudou a apresentação:* o comando `git diff c98fd47 -- "frontend/app/dashboard/[pid]/page.tsx"` mostra três linhas alteradas, todas de `className`: o `div` exterior (de `absolute top-0 left-0 h-screen w-screen bg-black/70 z-50 flex justify-center items-center` para `fixed bottom-4 right-4 z-50`), o `Card` (sem `justify-center` e com `shadow-lg`) e a `Progress` (de `w-96` para `w-64`). A lógica de `processing`, `displayedProgress` e `cancelProcess` não foi tocada.

```diff
-        <div className="absolute top-0 left-0 h-screen w-screen bg-black/70 z-50 flex justify-center items-center">
-          <Card className="p-4 flex flex-col justify-center items-center gap-4">
+        <div className="fixed bottom-4 right-4 z-50">
+          <Card className="p-4 flex flex-col items-center gap-4 shadow-lg">
...
-            <Progress value={displayedProgress} className="w-96" />
+            <Progress value={displayedProgress} className="w-64" />
```

== Medir a versão final e entregar evidência

Na versão "final"(falta o refresh) (14 de novembro de 2026, mesmo projeto `test1` e mesma legendagem automática), o cartão de processamento ocupa 289,6 × 169,6 px, ou seja, 4,6 % da janela, contra 83,3 % na baseline. O resto do ecrã deixou de escurecer. Com o processamento em curso, abriram-se a grelha de ficheiros (14 %), o editor com a barra de ferramentas (9 %) e a janela Import (68 %).

#figure(
  image("evidencias_usabilidade/final-01-cartao-inspetor-5pct.png", width: 90%),
  caption: [Versão final: cartão no canto inferior direito a 5 %, com o inspetor a mostrar 289,6 × 169,6 px.],
)

#figure(
  image("evidencias_usabilidade/final-02-contentor-inspetor-8pct.png", width: 90%),
  caption: [Versão final: a 8 %, com o inspetor a mostrar (1280 × 640,8 px)],
)

#figure(
  image("evidencias_usabilidade/final-03-grelha-14pct.png", width: 90%),
  caption: [Versão final: grelha de ficheiros sem ecrã escurecido, com o processamento a 14 %.],
)

#figure(
  image("evidencias_usabilidade/final-04-editor-ferramentas-9pct.png", width: 90%),
  caption: [Versão final: editor com a barra de ferramentas e a legenda aplicada visíveis, com o processamento a 9 %.],
)

#figure(
  image("evidencias_usabilidade/final-05-import-aberto-68pct.png", width: 90%),
  caption: [Versão final: janela Import aberta durante o processamento, a 68 %.],
)

=== 14 de novembro de 2026 - Preparação da documentação

*Criação do documento.* A estrutura foi criada a partir do documento de manutenibilidade. A alteração do frontend foi feita em `frontend/app/dashboard/[pid]/page.tsx`.

*Baseline.* Mediu-se no código original, commit `c98fd47111162f2a4e24948fb80287e0a35c0f26`, com o projeto `test1` e a legendagem automática. O ecrã sobreposto cobria 83,3 % da janela (1280 × 695 px visíveis de 1536 × 695,2 px). Na área de conteúdo só o botão Cancelar respondeu, e a barra lateral continuou utilizável.

*Versão final.* Reconstruiu-se o frontend com `docker compose up -d --build`. O cartão fixo no canto ocupa 4,6 % da janela (289,6 × 169,6 px), o resto do ecrã deixou de escurecer e o utilizador pode mexer na interface do pictuRAS. 

*Apoio de AI* Claude ajudou na estrutura deste typ, tudo validado por nós.

=== Modelo de entrada futura

- *Data e responsável:* por preencher.
- *Tarefa e objetivo:* por preencher.
- *Commit e ambiente:* por preencher.
- *Procedimento e comandos:* por preencher.
- *Resultados e localização da evidência:* por preencher.
- *Decisão, limitações e próximo passo:* por preencher.
- *Apoio de IA e validação humana:* por preencher.

== Referências de trabalho

- Diretrizes da Fase 2, versão 1 (`fase-2-guidelines.pdf`).
- ISO/IEC 25010:2011 (Usabilidade → Operabilidade).
