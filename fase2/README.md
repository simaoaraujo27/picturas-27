# Fase 2

- `documentacao/`: registo de decisões, medições e evidência.
- `scripts/`: scripts de recolha reproduzível.
- `resultados/baseline/`: resultados brutos associados ao commit inicial.

Executar os comandos a partir da raiz do repositório. O procedimento e os limites das medições estão em `documentacao/manutenibilidade-notas.typ`.

Para testar o worker na imagem Docker atual e guardar o log:

```bash
python3 fase2/scripts/test_video_docker.py fase2/resultados/baseline/video-baseline-docker-pytest.txt --build
```

O script usa um container temporário e monta `Tools/video/tests` em leitura. Os testes cobrem o código do worker; a integração com RabbitMQ e `projects` é uma verificação separada.

Para repetir os três cenários de manutenção numa cópia temporária do commit inicial:

```bash
CAMINHO_PYTHON fase2/scripts/benchmark_maintenance.py > fase2/resultados/baseline/maintenance-scenarios.json
```

Este comando requer Pillow no Python usado. O ficheiro `documentacao/manutenibilidade-notas.typ` contém os critérios, os resultados e as limitações dos protótipos. Os tempos de vídeo foram recolhidos no Docker com `scripts/measure_video_cases.py` e os casos de `documentacao/video-cases.json`.
