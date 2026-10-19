"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/axios";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { ProjectVideo } from "@/lib/projects";

type Job = {
  id: string;
  name: string;
  state: string;
  progress: number;
  sourceId: string;
  start: number;
  end: number;
  error: string | null;
  resultId: string | null;
};

function removeSegmentMessage(code: string) {
  const messages: Record<string, string> = {
    INVALID_INTERVAL: "Escolhe um intervalo temporal consistente (0 ≤ início < fim ≤ duração).",
    OUTSIDE_VIDEO: "O fim do segmento ultrapassa a duração do vídeo.",
    DURATION_TOO_SHORT: "A duração resultante do vídeo deve ser igual ou superior a 1,0 s.",
    PROJECT_CONFLICT: "O projeto foi alterado concorrencialmente por outro utilizador. Atualiza o projeto.",
    VERSION_REQUIRED: "A versão do projeto é necessária para controlo de concorrência.",
    UNSUPPORTED_VIDEO: "Formato de vídeo não suportado para edição.",
    DAILY_QUOTA_EXHAUSTED: "Atingiste o limite diário de operações.",
    STORAGE_QUOTA_EXCEEDED: "Não há espaço de vídeo disponível na conta.",
    FFMPEG_FAILED: "Não foi possível concluir a remoção do segmento.",
    PROCESSING_TIMEOUT: "O processamento ultrapassou o tempo limite.",
    NETWORK_FAILURE: "A ligação a um serviço falhou durante o processamento.",
    SERVICE_UNAVAILABLE: "Um serviço de processamento está temporariamente indisponível.",
    REMOVE_SEGMENT_UNAVAILABLE: "O serviço de remoção de segmentos está temporariamente indisponível.",
    WORKER_TIMEOUT: "O worker deixou de responder.",
  };
  return messages[code] ?? code;
}

export function RemoveSegmentVideoDialog({
  open,
  onOpenChange,
  video,
  ownerId,
  projectId,
  projectVersion,
  token,
  shareId,
}: {
  open: boolean;
  onOpenChange: (value: boolean) => void;
  video: ProjectVideo;
  ownerId: string;
  projectId: string;
  projectVersion: number;
  token: string;
  shareId?: string;
}) {
  const [url, setUrl] = useState<string>();
  const [duration, setDuration] = useState(0);
  const [start, setStart] = useState(0);
  const [end, setEnd] = useState(0);
  const [job, setJob] = useState<Job>();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [resultUrl, setResultUrl] = useState<string>();
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [isPreviewing, setIsPreviewing] = useState(false);
  const player = useRef<HTMLVideoElement>(null);
  const queryClient = useQueryClient();

  const base = `/projects/${ownerId}/${projectId}/video`;
  const query = shareId ? `?share=${encodeURIComponent(shareId)}` : "";
  const headers = useMemo(
    () => ({
      Authorization: `Bearer ${token}`,
      "X-Project-Version": String(projectVersion),
    }),
    [token, projectVersion]
  );

  useEffect(() => {
    if (!open) return;
    let current = true;
    api
      .get<{ url: string }>(`${base}/${video.id}/playback${query}`, { headers })
      .then((response) => {
        if (!current) return;
        setUrl(response.data.url);
      })
      .catch(() => {
        if (current) setError("Não foi possível abrir o vídeo.");
      });
    return () => {
      current = false;
      setUrl(undefined);
    };
  }, [open, base, video.id, query, headers]);

  useEffect(() => {
    if (!open) return;
    let current = true;
    const refresh = async () => {
      try {
        const response = await api.get<Job[]>(`${base}/remove-segment/jobs${query}`, { headers });
        if (current) {
          setJobs(response.data);
          const selected =
            response.data.find((item) => item.id === job?.id) ||
            response.data.find(
              (item) =>
                item.sourceId === video.id &&
                (item.state === "QUEUED" || item.state === "PROCESSING")
            );
          if (selected) setJob(selected);
        }
      } catch {
        /* a later poll can recover */
      }
    };
    refresh();
    const interval = window.setInterval(refresh, 4000);
    return () => {
      current = false;
      window.clearInterval(interval);
    };
  }, [open, base, query, headers, job?.id, video.id]);

  useEffect(() => {
    if (job?.state === "COMPLETED") {
      void queryClient.invalidateQueries({ queryKey: ["project"], refetchType: "all" });
    }
    if (job?.state && ["COMPLETED", "FAILED", "CANCELLED"].includes(job.state)) {
      void queryClient.invalidateQueries({ queryKey: ["session"], refetchType: "all" });
    }
  }, [job?.state, job?.id, queryClient]);

  useEffect(() => {
    if (!open || job?.state !== "COMPLETED" || !job.resultId) return;
    let current = true;
    api
      .get<{ url: string }>(`${base}/${job.resultId}/playback${query}`, { headers })
      .then((response) => {
        if (!current) return;
        setResultUrl(response.data.url);
      })
      .catch(() => {
        if (current) setError("Não foi possível abrir o resultado.");
      });
    return () => {
      current = false;
      setResultUrl(undefined);
    };
  }, [open, base, query, headers, job?.state, job?.resultId]);

  const remainingDuration = Math.max(0, duration - Math.max(0, end - start));

  // FA1: Simulação local no reprodutor saltando o trecho marcado a eliminar
  const preview = () => {
    if (!player.current) return;
    setIsPreviewing(true);
    if (start <= 0.05) {
      player.current.currentTime = end;
    } else {
      player.current.currentTime = 0;
    }
    void player.current.play();
  };

  const handleTimeUpdate = (currentTime: number) => {
    if (!isPreviewing) return;
    // Se o corte for intermédio e chegarmos ao início do segmento a eliminar, saltar para o fim
    if (start > 0.05 && currentTime >= start && currentTime < end) {
      if (player.current) {
        player.current.currentTime = end;
      }
    }
  };

  const submit = async () => {
    setError("");
    if (
      !Number.isFinite(start) ||
      !Number.isFinite(end) ||
      start < 0 ||
      end <= start ||
      end > duration + 0.05
    ) {
      setError("Escolhe um intervalo temporal consistente (0 ≤ início < fim ≤ duração).");
      return;
    }
    if (duration - (end - start) < 1.0 - 0.05) {
      setError("A duração resultante do vídeo deve ser igual ou superior a 1,0 s.");
      return;
    }

    setBusy(true);
    try {
      const response = await api.post<Job>(
        `${base}/${video.id}/remove-segment${query}`,
        { start: Math.round(start * 100) / 100, end: Math.round(end * 100) / 100 },
        { headers }
      );
      setJob(response.data);
      void queryClient.invalidateQueries({ queryKey: ["session"], refetchType: "all" });
    } catch (cause: unknown) {
      const resp = (cause as { response?: { data?: { code?: string; message?: string } } })?.response;
      setError(removeSegmentMessage(resp?.data?.code || "NÃO foi possível iniciar a remoção do segmento."));
    } finally {
      setBusy(false);
    }
  };

  const cancel = async () => {
    if (!job) return;
    try {
      const response = await api.delete<Job>(`${base}/remove-segment/jobs/${job.id}${query}`, {
        headers,
      });
      setJob(response.data);
    } catch {
      setError("Não foi possível cancelar a tarefa.");
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Remover segmento de vídeo: {video.name}</DialogTitle>
        </DialogHeader>

        {url && (
          <video
            ref={player}
            src={url}
            controls
            className="w-full rounded bg-black"
            onLoadedMetadata={(event) => {
              const value = event.currentTarget.duration;
              setDuration(value);
              // Default: 1/3 of the video or up to 2 seconds marked
              const defaultEnd = Math.min(value, Math.max(1, value * 0.4));
              setStart(Math.floor(value * 0.1 * 100) / 100);
              setEnd(Math.floor(defaultEnd * 100) / 100);
            }}
            onTimeUpdate={(event) => {
              handleTimeUpdate(event.currentTarget.currentTime);
            }}
            onPause={() => setIsPreviewing(false)}
            onEnded={() => setIsPreviewing(false)}
          />
        )}

        <div className="flex justify-between text-sm text-muted-foreground">
          <span>Duração original: {duration.toFixed(2)} s</span>
          <span>Segmento a eliminar: {Math.max(0, end - start).toFixed(2)} s</span>
          <span className={remainingDuration < 1.0 ? "text-destructive font-semibold" : "font-semibold"}>
            Duração resultante: {remainingDuration.toFixed(2)} s
          </span>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <label className="text-sm font-medium">
            Início a eliminar (s)
            <input
              className="mt-1 w-full rounded border bg-white p-2 text-slate-900"
              type="number"
              min="0"
              max={end}
              step="0.01"
              value={start}
              onChange={(event) => setStart(Number(event.target.value))}
            />
          </label>
          <label className="text-sm font-medium">
            Fim a eliminar (s)
            <input
              className="mt-1 w-full rounded border bg-white p-2 text-slate-900"
              type="number"
              min={start}
              max={duration}
              step="0.01"
              value={end}
              onChange={(event) => setEnd(Number(event.target.value))}
            />
          </label>
        </div>

        <div className="relative h-8" aria-label="Intervalo do segmento a eliminar">
          <div className="absolute inset-x-0 top-1/2 h-1 -translate-y-1/2 rounded-full bg-muted" />
          {/* Destaque visual do segmento a eliminar a vermelho */}
          <div
            className="absolute top-1/2 h-1 -translate-y-1/2 rounded-full bg-destructive"
            style={{
              left: `${duration > 0 ? Math.min(100, Math.max(0, (start / duration) * 100)) : 0}%`,
              right: `${duration > 0 ? Math.min(100, Math.max(0, ((duration - end) / duration) * 100)) : 100}%`,
            }}
          />
          <input
            className="trim-range z-10"
            aria-label="Início do corte na linha temporal"
            type="range"
            min="0"
            max={duration || 1}
            step="0.01"
            value={start}
            onChange={(event) => setStart(Math.min(Number(event.target.value), Math.max(0, end - 0.1)))}
          />
          <input
            className="trim-range z-20"
            aria-label="Fim do corte na linha temporal"
            type="range"
            min="0"
            max={duration || 1}
            step="0.01"
            value={end}
            onChange={(event) => setEnd(Math.max(Number(event.target.value), Math.min(duration, start + 0.1)))}
          />
        </div>

        <div className="flex gap-2">
          <Button variant="outline" onClick={preview}>
            Pré-visualizar resultado
          </Button>
          <Button
            disabled={busy || !duration || remainingDuration < 1.0}
            onClick={submit}
          >
            Aplicar corte
          </Button>
        </div>

        {job && (
          <div aria-live="polite" className="mt-2 space-y-2 rounded border p-3">
            <p className="text-sm font-medium">
              Estado: {job.state} · {job.progress}%
            </p>
            <progress
              className="w-full h-2 rounded bg-muted"
              value={job.progress}
              max="100"
              aria-label="Progresso da remoção de segmento"
            />
            {(job.state === "QUEUED" || job.state === "PROCESSING") && (
              <Button variant="destructive" size="sm" onClick={cancel}>
                Cancelar
              </Button>
            )}
            {job.state === "COMPLETED" && (
              <div className="space-y-2">
                {resultUrl && (
                  <>
                    <video src={resultUrl} controls className="w-full rounded" />
                    <a
                      href={`${resultUrl}?download=1`}
                      download={job.name || `cut-${job.id}.mp4`}
                      className="text-sm text-primary underline"
                    >
                      Descarregar vídeo editado ({job.name})
                    </a>
                  </>
                )}
                <p className="text-sm text-green-600">
                  O novo vídeo editado foi adicionado à lista de vídeos do projeto preservando o original.
                </p>
              </div>
            )}
            {job.error && (
              <p className="text-sm text-destructive font-medium">
                {removeSegmentMessage(job.error)}
              </p>
            )}
          </div>
        )}

        {jobs.length > 0 && (
          <div className="mt-2">
            <p className="text-xs font-semibold text-muted-foreground uppercase">Tarefas recentes</p>
            <div className="max-h-24 overflow-auto flex flex-wrap gap-2 mt-1">
              {jobs
                .filter((item) => item.sourceId === video.id)
                .slice(0, 10)
                .map((item) => (
                  <Button
                    key={item.id}
                    size="sm"
                    variant={item.id === job?.id ? "default" : "outline"}
                    onClick={() => setJob(item)}
                  >
                    {item.state} {item.progress}%
                  </Button>
                ))}
            </div>
          </div>
        )}

        {error && (
          <p role="alert" className="text-sm text-destructive font-medium">
            {error}
          </p>
        )}
      </DialogContent>
    </Dialog>
  );
}
