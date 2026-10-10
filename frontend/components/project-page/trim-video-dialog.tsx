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
import { Slider } from "@/components/ui/slider";
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
}: TrimVideoDialogProps) {
  const { _id: pid, version } = useProjectInfo();
  const session = useSession();
  const { toast } = useToast();

  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [loadingVideo, setLoadingVideo] = useState(false);
  const [duration, setDuration] = useState<number>(0);
  const [startTime, setStartTime] = useState<number>(0);
  const [endTime, setEndTime] = useState<number>(1);
  const [previewing, setPreviewing] = useState(false);

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const trimVideo = useTrimProjectVideo(
    session.user._id,
    pid,
    session.token,
    ownerId,
    shareId
  );

  // Inicializar tempos por omissão ao abrir
  useEffect(() => {
    if (open) {
      setStartTime(0);
      setEndTime(1);
      setDuration(0);
      setPreviewing(false);
    }
  }, [open]);

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
        const roundedDur = Number(dur.toFixed(1));
        setDuration(roundedDur);
        setStartTime(0);
        setEndTime(roundedDur > 1 ? roundedDur : 1);
      }
    }
  }

  // Controlo da pré-visualização local do trecho
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

    // Garantir que newEnd é pelo menos 1s superior a newStart
    if (newEnd < newStart + 1.0) {
      if (newStart !== startTime) {
        newEnd = Math.min(maxBound, Number((newStart + 1.0).toFixed(1)));
      } else {
        newStart = Math.max(0, Number((newEnd - 1.0).toFixed(1)));
      }
    }

    setStartTime(newStart);
    setEndTime(newEnd);

    // Sincronizar posição do vídeo com o início se não estiver a reproduzir
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

    // Impedir que o início ultrapasse o fim
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

    // Impedir que o fim seja inferior ou igual ao início (mínimo 1s de diferença)
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

  async function handleConfirmTrim() {
    if (startTime < 0 || endTime <= startTime || endTime - startTime < 1.0) {
      toast({
        title: "Invalid range",
        description: "The end time must be at least 1.0 second greater than the start time.",
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

  const trimDuration = Math.max(0, endTime - startTime);
  const maxSliderValue = duration > 0 ? duration : Math.max(10, endTime);
  const isInvalidInterval = endTime <= startTime || trimDuration < 1.0;

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

          {/* Range Preview Button */}
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
              Selected duration: <strong className="text-foreground">{trimDuration.toFixed(1)}s</strong>
              {duration > 0 && ` (Total: ${duration.toFixed(1)}s)`}
            </div>
          </div>

          {/* Visual Dual-Thumb Range Slider */}
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
                Confirm Trim
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

