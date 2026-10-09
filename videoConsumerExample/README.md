# Exemplo mínimo de consumidor de vídeo

Este exemplo consome uma tarefa de `video_example_queue`, pede uma URL interna ao serviço `img_storage` **depois** de retirar a tarefa da fila e descarrega o MP4 em blocos para um ficheiro temporário. Compara o total de bytes com `parameters.size`, calcula SHA-256 e apaga o ficheiro no fim. Não processa nem publica resultados.

## Contrato de entrada

- Exchange: `picturas` (`direct`). Routing key e fila durável: `video_example_queue` neste exemplo; cada ferramenta real terá a sua própria fila.
- Corpo: JSON UTF-8 com `messageId` (`request-<uuid>`), `timestamp` (ISO 8601 UTC), `procedure` e `parameters`.
- `parameters.ownerId`, `projectId` e `videoId` são os ObjectIds persistidos pelo backend. `parameters.size` é o tamanho do vídeo em bytes, usado para detetar downloads incompletos.
- A mensagem contém identificadores estáveis. **Não** contém URL assinada, chave de S3, JWT, segredo interno ou conteúdo binário.

```json
{
  "messageId": "request-550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-10-09T15:00:00.000Z",
  "procedure": "video_example",
  "parameters": {
    "ownerId": "0123456789abcdef01234567",
    "projectId": "0123456789abcdef01234568",
    "videoId": "0123456789abcdef01234569",
    "size": 2232
  }
}
```

O produtor definitivo ainda não está ligado ao endpoint `/process`. `publish_test.py` publica manualmente uma mensagem com este formato para permitir testes independentes do frontend. Não use `project_queue`: o tratamento de resultados de vídeo ainda não existe.

## Teste independente

Na raiz do repositório, com os serviços Docker ativos e um vídeo já carregado:

```bash
export OWNER_ID='<id do proprietário do projeto>'
export PROJECT_ID='<id do projeto>'
export VIDEO_ID='<id devolvido pelo upload>'
export VIDEO_SIZE='<size devolvido pelo upload, em bytes>'

docker compose --profile video-example build video_example
docker compose --profile video-example up -d video_example

docker compose --profile video-example run --rm --no-deps video_example \
  python publish_test.py \
  --owner-id "$OWNER_ID" --project-id "$PROJECT_ID" \
  --video-id "$VIDEO_ID" --size "$VIDEO_SIZE"

docker compose --profile video-example logs video_example
```

A saída de sucesso inclui `status: downloaded`, `bytes` e `sha256`. Compare `sha256` com `sha256sum` do MP4 original, se o tiver disponível. Se o consumidor ainda estiver ativo, espere que termine; a opção `--once` faz o contentor sair após uma tarefa.

Para criar um vídeo de teste sem frontend, use um utilizador autenticado com permissão de edição num projeto existente. O exemplo abaixo requer `ffmpeg`, `curl` e `jq` no computador:

```bash
export TOKEN='<JWT do utilizador>'
export OWNER_ID='<id do proprietário do projeto>'
export PROJECT_ID='<id do projeto>'
export API='https://localhost:8080/api-gateway'

ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=blue:s=64x64:d=1 \
  -t 1 -c:v libx264 -pix_fmt yuv420p teste.mp4
export VIDEO_SIZE="$(stat -c%s teste.mp4)"
export PROJECT_VERSION="$(curl -skS -H "Authorization: Bearer $TOKEN" \
  "$API/projects/$OWNER_ID/$PROJECT_ID" | jq -r .version)"

curl -skS -X POST "$API/projects/$OWNER_ID/$PROJECT_ID/video/check" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Project-Version: $PROJECT_VERSION" \
  -H 'Content-Type: application/json' \
  --data "{\"name\":\"teste.mp4\",\"size\":$VIDEO_SIZE}"

curl -skS -X POST "$API/projects/$OWNER_ID/$PROJECT_ID/video" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Project-Version: $PROJECT_VERSION" \
  -H 'X-Video-Name: teste.mp4' \
  -H "X-Video-Size: $VIDEO_SIZE" \
  -F 'video=@teste.mp4;type=video/mp4'
```

Copie o `id` da resposta de upload para `VIDEO_ID` e execute os comandos do consumidor acima. Compare o SHA-256 apresentado pelo consumidor com `sha256sum teste.mp4`.

O perfil opcional `video-example` coloca o contentor na rede do projeto e fornece-lhe o mesmo `INTERNAL_VIDEO_KEY` de `img_storage`; não é necessário expor esse segredo em comandos locais. A URL é pedida após o consumo e dura 15 minutos; o ficheiro é descarregado antes de qualquer processamento.
