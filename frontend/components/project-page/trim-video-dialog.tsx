"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/axios";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { ProjectVideo } from "@/lib/projects";

type Job = { id: string; state: string; progress: number; sourceId: string; error: string | null; resultId: string | null };
function trimMessage(code: string) {
  const messages: Record<string, string> = {
    INVALID_INTERVAL: "Escolhe um intervalo válido de pelo menos 1 segundo.",
    OUTSIDE_VIDEO: "O fim do intervalo ultrapassa a duração do vídeo.",
    CLIP_TOO_LONG: "O excerto excede a duração permitida pelo teu plano.",
    DAILY_QUOTA_EXHAUSTED: "Atingiste o limite diário de operações.",
    STORAGE_QUOTA_EXCEEDED: "Não há espaço de vídeo disponível na conta.",
    FAST_REQUIRES_KEYFRAMES: "O recorte rápido exige que ambos os pontos coincidam com keyframes. Escolhe outros pontos ou usa o recorte preciso.",
    FAST_REQUIRES_AAC: "O recorte rápido exige áudio AAC. Usa o recorte preciso.",
    FFMPEG_FAILED: "O processamento do vídeo falhou.",
    PROCESSING_TIMEOUT: "O processamento ultrapassou o tempo permitido.",
    NETWORK_FAILURE: "A ligação a um serviço falhou durante o processamento.",
    SERVICE_UNAVAILABLE: "Um serviço de processamento está temporariamente indisponível.",
    WORKER_TIMEOUT: "O worker deixou de responder.",
  };
  return messages[code] ?? code;
}
export function TrimVideoDialog({ open, onOpenChange, video, ownerId, projectId, token, shareId, allowFast }: {
  open: boolean; onOpenChange: (value: boolean) => void; video: ProjectVideo;
  ownerId: string; projectId: string; token: string; shareId?: string; allowFast: boolean;
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
  const [fast, setFast] = useState(false);
  const player = useRef<HTMLVideoElement>(null);
  const queryClient = useQueryClient();
  const base = `/projects/${ownerId}/${projectId}/video`;
  const query = shareId ? `?share=${encodeURIComponent(shareId)}` : "";
  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token]);

  useEffect(() => {
    if (!open) return;
    let current = true;
    api.get<{ url: string }>(`${base}/${video.id}/playback${query}`, { headers }).then(response => {
      if (!current) return;
      setUrl(response.data.url);
    }).catch(() => { if (current) setError("Não foi possível abrir o vídeo."); });
    return () => { current = false; setUrl(undefined); };
  }, [open, base, video.id, query, headers]);

  useEffect(() => {
    if (!open) return;
    let current = true;
    const refresh = async () => {
      try {
        const response = await api.get<Job[]>(`${base}/trim/jobs${query}`, { headers });
        if (current) {
          setJobs(response.data);
          const selected = response.data.find(item => item.id === job?.id) ||
            response.data.find(item => item.sourceId === video.id &&
              (item.state === "QUEUED" || item.state === "PROCESSING"));
          if (selected) setJob(selected);
        }
      } catch { /* a later poll can recover */ }
    };
    refresh();
    const interval = window.setInterval(refresh, 4000);
    return () => { current = false; window.clearInterval(interval); };
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
    api.get<{ url: string }>(`${base}/${job.resultId}/playback${query}`, { headers }).then(response => {
      if (!current) return;
      setResultUrl(response.data.url);
    }).catch(() => { if (current) setError("Não foi possível abrir o resultado."); });
    return () => { current = false; setResultUrl(undefined); };
  }, [open, base, query, headers, job?.state, job?.resultId]);

  const preview = () => {
    if (!player.current) return;
    player.current.currentTime = start;
    void player.current.play();
  };
  const submit = async () => {
    setError("");
    if (!Number.isFinite(start) || !Number.isFinite(end) || start < 0 || end > duration || end - start < 1) {
      setError("Escolhe um intervalo de pelo menos 1 segundo dentro do vídeo."); return;
    }
    setBusy(true);
    try {
      const response = await api.post<Job>(`${base}/${video.id}/trim${query}`,
        { start, end, mode: fast ? "fast" : "precise" }, { headers });
      setJob(response.data);
      void queryClient.invalidateQueries({ queryKey: ["session"], refetchType: "all" });
    } catch (cause: unknown) {
      setError(trimMessage((cause as { response?: { data?: { code?: string } } })?.response?.data?.code ||
        "Não foi possível iniciar o recorte."));
    } finally { setBusy(false); }
  };
  const cancel = async () => {
    if (!job) return;
    try { const response = await api.delete<Job>(`${base}/trim/jobs/${job.id}${query}`, { headers }); setJob(response.data); }
    catch { setError("Não foi possível cancelar a tarefa."); }
  };
  return <Dialog open={open} onOpenChange={onOpenChange}>
    <DialogContent className="max-w-2xl">
      <DialogHeader><DialogTitle>Recortar vídeo: {video.name}</DialogTitle></DialogHeader>
      {url && <video ref={player} src={url} controls className="w-full rounded" onLoadedMetadata={event => {
        const value = event.currentTarget.duration; setDuration(value); setEnd(Math.floor(value * 100) / 100);
      }} onTimeUpdate={event => { if (end && event.currentTarget.currentTime >= end) event.currentTarget.pause(); }} />}
      <p>Duração total: {duration.toFixed(2)} s</p>
      <div className="grid grid-cols-2 gap-3">
        <label>Início (s)<input className="w-full rounded border bg-white p-2 text-slate-900" type="number" min="0" max={end} step="0.01" value={start} onChange={event => setStart(Number(event.target.value))} /></label>
        <label>Fim (s)<input className="w-full rounded border bg-white p-2 text-slate-900" type="number" min={start} max={duration} step="0.01" value={end} onChange={event => setEnd(Number(event.target.value))} /></label>
      </div>
      <div className="relative h-8" aria-label="Intervalo do recorte">
        <div className="absolute inset-x-0 top-1/2 h-1 -translate-y-1/2 rounded-full bg-muted" />
        <div className="absolute top-1/2 h-1 -translate-y-1/2 rounded-full bg-primary" style={{
          left: `${duration > 0 ? Math.min(100, Math.max(0, start / duration * 100)) : 0}%`,
          right: `${duration > 0 ? Math.min(100, Math.max(0, (duration - end) / duration * 100)) : 100}%`,
        }} />
        <input className="trim-range z-10" aria-label="Início na linha temporal" type="range" min="0" max={duration || 1} step="0.01" value={start} onChange={event => setStart(Math.min(Number(event.target.value), Math.max(0, end - 1)))} />
        <input className="trim-range z-20" aria-label="Fim na linha temporal" type="range" min="0" max={duration || 1} step="0.01" value={end} onChange={event => setEnd(Math.max(Number(event.target.value), Math.min(duration, start + 1)))} />
      </div>
      <p>Excerto: {Math.max(0, end - start).toFixed(2)} s</p>
      {allowFast && <label className="flex items-center gap-2"><input type="checkbox" checked={fast} onChange={event => setFast(event.target.checked)} />Recorte rápido (exige pontos em keyframes; pode falhar)</label>}
      <div className="flex gap-2"><Button variant="outline" onClick={preview}>Pré-visualizar</Button><Button disabled={busy || !duration} onClick={submit}>Recortar vídeo</Button></div>
      {job && <div aria-live="polite">
        <p>Estado: {job.state} · {job.progress}%</p>
        <progress className="w-full" value={job.progress} max="100" aria-label="Progresso do recorte" />
        {(job.state === "QUEUED" || job.state === "PROCESSING") && <Button variant="destructive" onClick={cancel}>Cancelar</Button>}
        {job.state === "COMPLETED" && <div>
          {resultUrl && <><video src={resultUrl} controls className="w-full rounded" /><a href={`${resultUrl}?download=1`} download={`trim-${job.id}.mp4`} className="underline">Descarregar resultado</a></>}
          <p>O novo vídeo está disponível na lista do projeto.</p>
        </div>}
        {job.error && <p className="text-destructive">{trimMessage(job.error)}</p>}
      </div>}
      {jobs.length > 0 && <div><p className="font-medium">Tarefas recentes</p><div className="max-h-28 overflow-auto flex flex-wrap gap-2">
        {jobs.filter(item => item.sourceId === video.id).slice(0, 10).map(item =>
          <Button key={item.id} size="sm" variant={item.id === job?.id ? "default" : "outline"} onClick={() => setJob(item)}>
            {item.state} {item.progress}%
          </Button>)}
      </div></div>}
      {error && <p role="alert" className="text-destructive">{error}</p>}
    </DialogContent>
  </Dialog>;
}
