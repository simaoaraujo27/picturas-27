"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { AlertCircle, HardDrive, Loader2, Play, Scissors, ShieldAlert, Sparkles, Square, UserPlus } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { downloadProjectVideo, getVideoStorageUsage } from "@/lib/projects";
import { useTrimProjectVideo } from "@/lib/mutations/projects";
import { useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Slider } from "@/components/ui/slider";
import { Checkbox } from "@/components/ui/checkbox";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
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
  onConfirmRange?: (range: { videoId: string; startTime: number; endTime: number; fastTrim?: boolean }) => void;
  initialStartTime?: number;
  initialEndTime?: number;
}

function formatSeconds(seconds: number): string {
  if (isNaN(seconds) || seconds < 0) return "00:00.0s";
  const mins = Math.floor(seconds / 60);
  const secs = (seconds % 60).toFixed(1);
  return `${mins.toString().padStart(2, "0")}:${Number(secs) < 10 ? "0" : ""}${secs}s`;
}

export function TrimVideoDialog({
  video,
  open,
  onOpenChange,
  ownerId,
  shareId,
  onConfirmRange,
  initialStartTime,
  initialEndTime,
}: TrimVideoDialogProps) {
  const { _id: pid, version } = useProjectInfo();
  const session = useSession();
  const { toast } = useToast();

  const isAnonymous = session.user.type === "anonymous";
  const isPremium = session.user.type === "premium";
  const isFree = session.user.type === "free";

  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [loadingVideo, setLoadingVideo] = useState(false);
  const [duration, setDuration] = useState<number>(0);
  const [startTime, setStartTime] = useState<number>(initialStartTime ?? 0);
  const [endTime, setEndTime] = useState<number>(initialEndTime ?? 1);
  const [fastTrim, setFastTrim] = useState<boolean>(false);
  const [previewing, setPreviewing] = useState(false);

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const trimVideo = useTrimProjectVideo(
    session.user._id,
    pid,
    session.token,
    ownerId,
    shareId
  );

  // Consulta de armazenamento da conta (REQ-VID-TRIM-024)
  const storageQuery = useQuery({
    queryKey: ["videoStorage", session.user._id],
    queryFn: () => getVideoStorageUsage({ uid: session.user._id, token: session.token }),
    enabled: open && !isAnonymous,
  });

  // Inicializar tempos por omissão ao abrir
  useEffect(() => {
    if (open) {
      setStartTime(initialStartTime ?? 0);
      setEndTime(initialEndTime ?? 1);
      setDuration(0);
      setFastTrim(false);
      setPreviewing(false);
    }
  }, [open, initialStartTime, initialEndTime]);

  // Carregar o vídeo como Blob para o player local
  useEffect(() => {
    if (!open || isAnonymous) {
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
  }, [open, video.id, pid, session.user._id, session.token, ownerId, shareId, isAnonymous]);

  function handleLoadedMetadata() {
    if (videoRef.current) {
      const dur = videoRef.current.duration;
      if (Number.isFinite(dur) && dur > 0) {
        const roundedDur = Number(dur.toFixed(1));
        setDuration(roundedDur);
        setStartTime(0);
        setEndTime(roundedDur > 1 ? roundedDur : 1);
      }
    }
  }

  // Controlo da pré-visualização local do trecho (REQ-VID-TRIM-003)
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

  function handleSliderChange(values: number[]) {
    if (values.length !== 2) return;
    let [newStart, newEnd] = values;
    newStart = Math.max(0, Number(newStart.toFixed(1)));
    const maxBound = duration > 0 ? duration : Math.max(10, newEnd);
    newEnd = Math.min(maxBound, Number(newEnd.toFixed(1)));

    // Garantir que newEnd é pelo menos 1s superior a newStart (REQ-VID-TRIM-004)
    if (newEnd < newStart + 1.0) {
      if (newStart !== startTime) {
        newEnd = Math.min(maxBound, Number((newStart + 1.0).toFixed(1)));
      } else {
        newStart = Math.max(0, Number((newEnd - 1.0).toFixed(1)));
      }
    }

    setStartTime(newStart);
    setEndTime(newEnd);

    if (videoRef.current && !previewing && videoRef.current.paused) {
      if (Math.abs(videoRef.current.currentTime - newStart) > 0.3) {
        videoRef.current.currentTime = newStart;
      }
    }
  }

  function handleStartInputChange(val: number) {
    const validVal = isNaN(val) ? 0 : Math.max(0, Number(val.toFixed(1)));
    const maxBound = duration > 0 ? duration : 9999;
    let newEnd = endTime;

    if (validVal >= newEnd - 1.0) {
      newEnd = Math.min(maxBound, Number((validVal + 1.0).toFixed(1)));
    }
    setStartTime(validVal);
    setEndTime(newEnd);
    if (videoRef.current && !previewing) {
      videoRef.current.currentTime = validVal;
    }
  }

  function handleEndInputChange(val: number) {
    const maxBound = duration > 0 ? duration : 9999;
    const validVal = isNaN(val) ? startTime + 1.0 : Math.min(maxBound, Number(val.toFixed(1)));
    let newStart = startTime;

    if (validVal <= newStart + 1.0) {
      newStart = Math.max(0, Number((validVal - 1.0).toFixed(1)));
    }
    setStartTime(newStart);
    setEndTime(validVal);
  }

  function setStartToCurrent() {
    if (videoRef.current) {
      const cur = Math.max(0, Number(videoRef.current.currentTime.toFixed(1)));
      handleStartInputChange(cur);
    }
  }

  function setEndToCurrent() {
    if (videoRef.current) {
      const cur = Math.min(
        duration || 9999,
        Number(videoRef.current.currentTime.toFixed(1))
      );
      handleEndInputChange(cur);
    }
  }

  const trimDuration = Math.max(0, endTime - startTime);
  const maxSliderValue = duration > 0 ? duration : Math.max(10, endTime);

  // Validação de limites de duração por perfil (RN2, REQ-VID-TRIM-006)
  const exceedsFreeDuration = isFree && trimDuration > 180;
  const exceedsPremiumDuration = isPremium && trimDuration > 3600;
  const isInvalidInterval =
    endTime <= startTime ||
    trimDuration < 1.0 ||
    exceedsFreeDuration ||
    exceedsPremiumDuration;

  async function handleConfirmTrim() {
    if (isAnonymous) {
      toast({
        title: "Registration required",
        description: "Video processing requires an account. Please sign up or log in.",
        variant: "destructive",
      });
      return;
    }

    if (isInvalidInterval) {
      toast({
        title: "Invalid range",
        description: exceedsFreeDuration
          ? "Free tier clips cannot exceed 180 seconds (3 minutes)."
          : "The end time must be at least 1.0s after start time.",
        variant: "destructive",
      });
      return;
    }

    const vid = video.id || (video as any)._id;

    if (onConfirmRange) {
      onConfirmRange({
        videoId: vid,
        startTime,
        endTime,
        fastTrim,
      });
      toast({
        title: "Trim range set!",
        description: "Click the 'Apply' button in the header to process the video cut.",
      });
      onOpenChange(false);
      return;
    }

    try {
      await trimVideo.mutateAsync({
        videoId: vid,
        projectVersion: version,
        startTime,
        endTime,
        fastTrim,
      });
      toast({
        title: "Trim initiated!",
        description: "Applying trim to video. The updated state will appear once processing finishes.",
      });
      onOpenChange(false);
    } catch (error) {
      const { title, description } = getErrorMessage("video-trim", error);
      toast({ title, description, variant: "destructive" });
    }
  }

  // REQ-VID-TRIM-019: Bloqueio estrito a utilizadores anónimos com convite a registo
  if (isAnonymous) {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-destructive">
              <ShieldAlert className="size-5" />
              Registered Account Required
            </DialogTitle>
            <DialogDescription>
              Video processing tools are exclusive to registered PictuRAS accounts.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2 text-sm text-muted-foreground">
            <p>
              O processamento de vídeo requer uma conta PictuRAS. Crie uma conta gratuita (<strong>Free</strong>) com <strong>5 operações diárias</strong> e <strong>1 GB de armazenamento</strong> na biblioteca, ou inicie sessão se já tiver conta.
            </p>
            <div className="rounded-lg border bg-muted/40 p-3 text-xs space-y-1.5">
              <div className="font-semibold text-foreground">Benefícios da conta Free:</div>
              <div>• 5 operações diárias gratuitas</div>
              <div>• 1 GB de armazenamento permanente</div>
              <div>• Recorte temporal de vídeos até 3 minutos</div>
            </div>
          </div>

          <DialogFooter className="flex-col sm:flex-row gap-2">
            <Button variant="outline" asChild onClick={() => onOpenChange(false)}>
              <Link href="/login">Sign In</Link>
            </Button>
            <Button asChild onClick={() => onOpenChange(false)} className="gap-1.5">
              <Link href="/register">
                <UserPlus className="size-4" />
                Create Free Account
              </Link>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onOpenChange={(next) => { if (!trimVideo.isPending) onOpenChange(next); }}>
      <DialogContent className="max-w-xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Scissors className="size-5" />
            Trim Video
          </DialogTitle>
          <DialogDescription>
            Choose the section of <strong>{video.name}</strong> you want to keep.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Indicador de Espaço em Disco da Conta (REQ-VID-TRIM-024) */}
          {storageQuery.data && (
            <div className="rounded-md border bg-muted/20 px-3 py-2 text-xs space-y-1.5">
              <div className="flex items-center justify-between text-muted-foreground">
                <span className="inline-flex items-center gap-1.5 font-medium text-foreground">
                  <HardDrive className="size-3.5" />
                  Library Storage ({storageQuery.data.plan.toUpperCase()})
                </span>
                <span>
                  {(storageQuery.data.usedBytes / (1024 * 1024)).toFixed(1)} MB /{" "}
                  {(storageQuery.data.maxBytes / (1024 * 1024 * 1024)).toFixed(0)} GB (
                  {storageQuery.data.percentage}%)
                </span>
              </div>
              <div className="h-1.5 w-full overflow-hidden rounded-full bg-secondary">
                <div
                  className={`h-full transition-all ${
                    storageQuery.data.percentage >= 90 ? "bg-destructive" : "bg-primary"
                  }`}
                  style={{ width: `${Math.min(100, storageQuery.data.percentage)}%` }}
                />
              </div>
            </div>
          )}

          {/* Video Preview Player */}
          <div className="relative aspect-video w-full overflow-hidden rounded-md bg-black flex items-center justify-center">
            {loadingVideo ? (
              <div className="flex flex-col items-center gap-2 text-white">
                <Loader2 className="size-6 animate-spin" />
                <span className="text-xs">Loading video...</span>
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
              <span className="text-xs text-muted-foreground">Video unavailable</span>
            )}
          </div>

          {/* Range Preview Button (REQ-VID-TRIM-003) */}
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
              {previewing ? "Stop Preview" : "Preview Trim"}
            </Button>
            <div className="text-xs text-muted-foreground">
              Selected duration:{" "}
              <strong
                className={exceedsFreeDuration || exceedsPremiumDuration ? "text-destructive" : "text-foreground"}
              >
                {trimDuration.toFixed(1)}s
              </strong>
              {duration > 0 && ` (Total: ${duration.toFixed(1)}s)`}
            </div>
          </div>

          {/* Alerta de Duração Máxima (REQ-VID-TRIM-006) */}
          {exceedsFreeDuration && (
            <Alert variant="destructive" className="py-2">
              <AlertCircle className="size-4" />
              <AlertTitle className="text-xs">Exceeds Free plan limit</AlertTitle>
              <AlertDescription className="text-xs">
                Free accounts are limited to snippets up to 3 minutes (180s). Reduce the selected interval or upgrade to Premium.
              </AlertDescription>
            </Alert>
          )}

          {/* Visual Dual-Thumb Range Slider (REQ-VID-TRIM-001, REQ-VID-TRIM-002) */}
          <div className="space-y-2 rounded-lg border bg-muted/30 p-3">
            <div className="flex justify-between text-xs font-medium text-muted-foreground">
              <span>Start: <strong className="text-foreground">{formatSeconds(startTime)}</strong></span>
              <span>End: <strong className="text-foreground">{formatSeconds(endTime)}</strong></span>
            </div>
            <Slider
              min={0}
              max={maxSliderValue}
              step={0.1}
              minStepsBetweenThumbs={10}
              value={[startTime, endTime]}
              onValueChange={handleSliderChange}
              disabled={loadingVideo || trimVideo.isPending}
              className="my-3"
            />
            <div className="flex justify-between text-[11px] text-muted-foreground">
              <span>00:00.0s</span>
              <span>{formatSeconds(maxSliderValue)}</span>
            </div>
          </div>

          {/* Numeric Fields for Precise Adjustment */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="start-time" className="text-xs font-medium">
                Start (seconds)
              </Label>
              <div className="flex gap-2">
                <Input
                  id="start-time"
                  type="number"
                  step="0.1"
                  min="0"
                  max={Math.max(0, endTime - 1.0)}
                  value={startTime}
                  onChange={(e) => handleStartInputChange(parseFloat(e.target.value))}
                  disabled={trimVideo.isPending}
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  title="Use current video position"
                  onClick={setStartToCurrent}
                  disabled={loadingVideo}
                >
                  Current
                </Button>
              </div>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="end-time" className="text-xs font-medium">
                End (seconds)
              </Label>
              <div className="flex gap-2">
                <Input
                  id="end-time"
                  type="number"
                  step="0.1"
                  min={startTime + 1.0}
                  max={duration > 0 ? duration : 9999}
                  value={endTime}
                  onChange={(e) => handleEndInputChange(parseFloat(e.target.value))}
                  disabled={trimVideo.isPending}
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  title="Use current video position"
                  onClick={setEndToCurrent}
                  disabled={loadingVideo}
                >
                  Current
                </Button>
              </div>
            </div>
          </div>

          {/* Opção de Recorte Rápido para Premium (FA2, REQ-VID-TRIM-011) */}
          {isPremium && (
            <div className="flex items-center space-x-2 rounded-md border border-amber-500/20 bg-amber-500/5 p-2.5">
              <Checkbox
                id="fast-trim"
                checked={fastTrim}
                onCheckedChange={(checked) => setFastTrim(Boolean(checked))}
                disabled={trimVideo.isPending}
              />
              <div className="grid gap-0.5 leading-none">
                <label
                  htmlFor="fast-trim"
                  className="text-xs font-medium text-foreground cursor-pointer flex items-center gap-1.5"
                >
                  <Sparkles className="size-3 text-amber-500" />
                  Fast Trim (Stream Copy without re-encoding)
                </label>
                <p className="text-[11px] text-muted-foreground">
                  Cuts instantly on keyframes without re-encoding audio and video streams.
                </p>
              </div>
            </div>
          )}
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={trimVideo.isPending}
          >
            Cancel
          </Button>
          <Button
            onClick={handleConfirmTrim}
            disabled={trimVideo.isPending || loadingVideo || isInvalidInterval}
            className="gap-2"
          >
            {trimVideo.isPending ? (
              <>
                <Loader2 className="size-4 animate-spin" />
                Processing...
              </>
            ) : (
              <>
                <Scissors className="size-4" />
                Set Trim Range
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
