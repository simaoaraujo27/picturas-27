"use client";

import { useEffect, useRef, useState } from "react";
import { Loader2, Play, Scissors, Square } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { downloadProjectVideo } from "@/lib/projects";
import { useTrimProjectVideo } from "@/lib/mutations/projects";
import { useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

interface TrimVideoDialogProps {
  video: ProjectVideo;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  ownerId?: string;
  shareId?: string;
}

export function TrimVideoDialog({
  video,
  open,
  onOpenChange,
  ownerId,
  shareId,
}: TrimVideoDialogProps) {
  const { _id: pid, version } = useProjectInfo();
  const session = useSession();
  const { toast } = useToast();

  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [loadingVideo, setLoadingVideo] = useState(false);
  const [duration, setDuration] = useState<number>(0);
  const [startTime, setStartTime] = useState<number>(0);
  const [endTime, setEndTime] = useState<number>(1);
  const [newName, setNewName] = useState("");
  const [previewing, setPreviewing] = useState(false);

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const trimVideo = useTrimProjectVideo(
    session.user._id,
    pid,
    session.token,
    ownerId,
    shareId
  );

  // Inicializar nome por omissão ao abrir
  useEffect(() => {
    if (open) {
      const baseName = video.name.replace(/\.mp4$/i, "");
      setNewName(`${baseName}-trimmed.mp4`);
      setStartTime(0);
      setEndTime(1);
      setPreviewing(false);
    }
  }, [open, video.name]);

  // Carregar o vídeo como Blob para o player local
  useEffect(() => {
    if (!open) {
      if (videoUrl) {
        URL.revokeObjectURL(videoUrl);
        setVideoUrl(null);
      }
      return;
    }

    let active = true;
    setLoadingVideo(true);

    downloadProjectVideo({
      uid: session.user._id,
      pid,
      videoId: video.id,
      token: session.token,
      ownerId,
      shareId,
    })
      .then((blob) => {
        if (!active) return;
        const url = URL.createObjectURL(blob);
        setVideoUrl(url);
        setLoadingVideo(false);
      })
      .catch((err) => {
        if (!active) return;
        setLoadingVideo(false);
        const { title, description } = getErrorMessage("video-download", err);
        toast({ title, description, variant: "destructive" });
      });

    return () => {
      active = false;
    };
  }, [open, video.id, pid, session.user._id, session.token, ownerId, shareId]);

  function handleLoadedMetadata() {
    if (videoRef.current) {
      const dur = videoRef.current.duration;
      if (Number.isFinite(dur) && dur > 0) {
        setDuration(dur);
        setEndTime(Math.min(dur, Math.max(1, Math.round(dur))));
      }
    }
  }

  // Controlo da pré-visualização local (FA1 / REQ-VID-TRIM-003)
  function handleTimeUpdate() {
    if (previewing && videoRef.current) {
      if (videoRef.current.currentTime >= endTime) {
        videoRef.current.pause();
        videoRef.current.currentTime = startTime;
        setPreviewing(false);
      }
    }
  }

  function handleTogglePreview() {
    if (!videoRef.current) return;
    if (previewing) {
      videoRef.current.pause();
      setPreviewing(false);
    } else {
      videoRef.current.currentTime = startTime;
      videoRef.current
        .play()
        .then(() => setPreviewing(true))
        .catch(() => setPreviewing(false));
    }
  }

  function setStartToCurrent() {
    if (videoRef.current) {
      const cur = Math.max(0, Math.min(videoRef.current.currentTime, endTime - 1));
      setStartTime(Number(cur.toFixed(2)));
    }
  }

  function setEndToCurrent() {
    if (videoRef.current) {
      const cur = Math.min(duration || 9999, Math.max(videoRef.current.currentTime, startTime + 1));
      setEndTime(Number(cur.toFixed(2)));
    }
  }

  async function handleConfirmTrim() {
    if (startTime < 0 || endTime <= startTime || endTime - startTime < 1.0) {
      toast({
        title: "Intervalo inválido",
        description: "O instante final tem de ser pelo menos 1.0 segundo superior ao inicial.",
        variant: "destructive",
      });
      return;
    }

    try {
      await trimVideo.mutateAsync({
        videoId: video.id,
        projectVersion: version,
        startTime,
        endTime,
        newName: newName.trim(),
      });
      toast({
        title: "Recorte submetido!",
        description: `A processar o recorte temporal para ${newName}. O vídeo aparecerá na lista quando concluído.`,
      });
      onOpenChange(false);
    } catch (error) {
      const { title, description } = getErrorMessage("video-trim", error);
      toast({ title, description, variant: "destructive" });
    }
  }

  const trimDuration = Math.max(0, endTime - startTime);

  return (
    <Dialog open={open} onOpenChange={(next) => { if (!trimVideo.isPending) onOpenChange(next); }}>
      <DialogContent className="max-w-xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Scissors className="size-5" />
            Recortar Vídeo (Trim)
          </DialogTitle>
          <DialogDescription>
            Define o intervalo temporal [$t_{'{in}'}$, $t_{'{out}'}$] a preservar do vídeo <strong>{video.name}</strong>.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Player de Pré-visualização */}
          <div className="relative aspect-video w-full overflow-hidden rounded-md bg-black flex items-center justify-center">
            {loadingVideo ? (
              <div className="flex flex-col items-center gap-2 text-white">
                <Loader2 className="size-6 animate-spin" />
                <span className="text-xs">A carregar vídeo...</span>
              </div>
            ) : videoUrl ? (
              <video
                ref={videoRef}
                src={videoUrl}
                controls
                className="h-full w-full object-contain"
                onLoadedMetadata={handleLoadedMetadata}
                onTimeUpdate={handleTimeUpdate}
              />
            ) : (
              <span className="text-xs text-muted-foreground">Vídeo indisponível</span>
            )}
          </div>

          {/* Botão de Pré-visualização do Intervalo */}
          <div className="flex items-center justify-between">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              disabled={loadingVideo || !videoUrl}
              onClick={handleTogglePreview}
              className="gap-2"
            >
              {previewing ? <Square className="size-3.5" /> : <Play className="size-3.5" />}
              {previewing ? "Parar Pré-visualização" : "Pré-visualizar Excerto"}
            </Button>
            <div className="text-xs text-muted-foreground">
              Duração resultante: <strong className="text-foreground">{trimDuration.toFixed(2)}s</strong>
              {duration > 0 && ` (Total: ${duration.toFixed(2)}s)`}
            </div>
          </div>

          {/* Seletores Temporais */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="start-time" className="text-xs">
                Início ($t_{'{in}'}$ em segundos)
              </Label>
              <div className="flex gap-2">
                <Input
                  id="start-time"
                  type="number"
                  step="0.1"
                  min="0"
                  max={Math.max(0, endTime - 1)}
                  value={startTime}
                  onChange={(e) => setStartTime(Number(e.target.value))}
                  disabled={trimVideo.isPending}
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  title="Usar posição atual do player"
                  onClick={setStartToCurrent}
                  disabled={loadingVideo}
                >
                  Usar atual
                </Button>
              </div>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="end-time" className="text-xs">
                Fim ($t_{'{out}'}$ em segundos)
              </Label>
              <div className="flex gap-2">
                <Input
                  id="end-time"
                  type="number"
                  step="0.1"
                  min={startTime + 1}
                  max={duration || 9999}
                  value={endTime}
                  onChange={(e) => setEndTime(Number(e.target.value))}
                  disabled={trimVideo.isPending}
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  title="Usar posição atual do player"
                  onClick={setEndToCurrent}
                  disabled={loadingVideo}
                >
                  Usar atual
                </Button>
              </div>
            </div>
          </div>

          {/* Nome do novo vídeo */}
          <div className="space-y-1.5">
            <Label htmlFor="new-video-name" className="text-xs">
              Nome do vídeo resultante (.mp4)
            </Label>
            <Input
              id="new-video-name"
              type="text"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              placeholder="ex: video-cortado.mp4"
              disabled={trimVideo.isPending}
            />
          </div>
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={trimVideo.isPending}
          >
            Cancelar
          </Button>
          <Button
            onClick={handleConfirmTrim}
            disabled={trimVideo.isPending || loadingVideo}
            className="gap-2"
          >
            {trimVideo.isPending ? (
              <>
                <Loader2 className="size-4 animate-spin" />
                A submeter...
              </>
            ) : (
              <>
                <Scissors className="size-4" />
                Confirmar Recorte
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
