"use client";

import { useEffect, useRef, useState } from "react";
import {
  AlertCircle,
  Gauge,
  Loader2,
  Pencil,
  Play,
  Plus,
  Trash2,
} from "lucide-react";
import { downloadProjectVideo, type ProjectVideo } from "@/lib/projects";
import { useChangeProjectVideoSpeed } from "@/lib/mutations/projects";
import {
  parseVideoTime,
  validateVideoSpeedIntervals,
  VIDEO_SPEEDS,
  type VideoSpeed,
  type VideoSpeedDraft,
} from "@/lib/video-speed";
import { getErrorMessage } from "@/lib/error-messages";
import {
  useCanEditProject,
  useProjectInfo,
} from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useToast } from "@/hooks/use-toast";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

interface SpeedVideoDialogProps {
  video: ProjectVideo;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  ownerId?: string;
  shareId?: string;
}

function displayTime(value: string | number) {
  const number = typeof value === "string" ? parseVideoTime(value) : value;
  return number === null
    ? "-"
    : `${number.toLocaleString("en-US", { maximumFractionDigits: 3 })} s`;
}

export function SpeedVideoDialog({
  video,
  open,
  onOpenChange,
  ownerId,
  shareId,
}: SpeedVideoDialogProps) {
  const { _id: pid, version } = useProjectInfo();
  const canEdit = useCanEditProject();
  const session = useSession();
  const { toast } = useToast();
  const videoRef = useRef<HTMLVideoElement>(null);
  const submitting = useRef(false);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [duration, setDuration] = useState<number | null>(null);
  const [loadingVideo, setLoadingVideo] = useState(true);
  const [videoError, setVideoError] = useState<string | null>(null);
  const [submissionError, setSubmissionError] = useState<string | null>(null);
  const [intervals, setIntervals] = useState<VideoSpeedDraft[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const changeSpeed = useChangeProjectVideoSpeed(
    session.user._id,
    pid,
    session.token,
    ownerId,
    shareId,
  );

  useEffect(() => {
    if (!open) return;
    let active = true;
    let objectUrl: string | undefined;
    const id = crypto.randomUUID();
    setIntervals([{ id, startTime: "0", endTime: "", speed: 1 }]);
    setActiveId(id);
    setVideoUrl(null);
    setDuration(null);
    setLoadingVideo(true);
    setVideoError(null);
    setSubmissionError(null);

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
        objectUrl = URL.createObjectURL(blob);
        setVideoUrl(objectUrl);
      })
      .catch((error) => {
        if (!active) return;
        setLoadingVideo(false);
        setVideoError(getErrorMessage("video-download", error).description);
      });

    return () => {
      active = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [open, video.id, pid, session.user._id, session.token, ownerId, shareId]);

  function handleLoadedMetadata() {
    const actualDuration = videoRef.current?.duration;
    setLoadingVideo(false);
    if (
      actualDuration === undefined ||
      !Number.isFinite(actualDuration) ||
      actualDuration <= 0
    ) {
      setVideoError(
        getErrorMessage("video-speed", { code: "VIDEO_DURATION_UNAVAILABLE" })
          .description,
      );
      return;
    }
    setDuration(actualDuration);
    setIntervals((current) =>
      current.map((item, index) =>
        index === 0 && !item.endTime
          ? { ...item, endTime: String(actualDuration) }
          : item,
      ),
    );
  }

  const validation = validateVideoSpeedIntervals(intervals, duration);
  const activeInterval = intervals.find((item) => item.id === activeId);
  const activeIndex = intervals.findIndex((item) => item.id === activeId);
  const controlsDisabled =
    !canEdit ||
    changeSpeed.isPending ||
    loadingVideo ||
    duration === null ||
    !!videoError;

  function updateActive(
    patch: Partial<Pick<VideoSpeedDraft, "startTime" | "endTime" | "speed">>,
  ) {
    setSubmissionError(null);
    setIntervals((current) =>
      current.map((item) =>
        item.id === activeId ? { ...item, ...patch } : item,
      ),
    );
  }

  function addInterval() {
    const id = crypto.randomUUID();
    setIntervals((current) => [
      ...current,
      { id, startTime: "", endTime: "", speed: 1 },
    ]);
    setActiveId(id);
    setSubmissionError(null);
  }

  function removeInterval(id: string) {
    const remaining = intervals.filter((item) => item.id !== id);
    setIntervals(remaining);
    if (id === activeId) setActiveId(remaining[0]?.id ?? null);
    setSubmissionError(null);
  }

  async function handleSubmit() {
    const checked = validateVideoSpeedIntervals(intervals, duration);
    if (
      !canEdit ||
      videoError ||
      loadingVideo ||
      !checked.isValid ||
      submitting.current
    )
      return;
    submitting.current = true;
    setSubmissionError(null);
    try {
      await changeSpeed.mutateAsync({
        videoId: video.id,
        projectVersion: version,
        intervals: checked.intervals,
      });
      toast({
        title: "Processing submitted",
        description:
          "The new video will appear in the library once processing is complete.",
      });
      onOpenChange(false);
    } catch (error) {
      const info = getErrorMessage("video-speed", error);
      setSubmissionError(info.description);
      toast({ ...info, variant: "destructive" });
    } finally {
      submitting.current = false;
    }
  }

  const sliderStart =
    duration === null
      ? 0
      : Math.min(
          duration,
          Math.max(0, parseVideoTime(activeInterval?.startTime ?? "") ?? 0),
        );
  const sliderEnd =
    duration === null
      ? 0
      : Math.max(
          sliderStart,
          Math.min(
            duration,
            parseVideoTime(activeInterval?.endTime ?? "") ?? duration,
          ),
        );

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!changeSpeed.isPending) onOpenChange(next);
      }}
    >
      <DialogContent className="flex max-h-[90dvh] w-[calc(100%_-_2rem)] max-w-2xl flex-col gap-0 overflow-hidden p-0">
        <DialogHeader className="shrink-0 border-b px-5 py-4 pr-12 text-left">
          <DialogTitle className="flex items-center gap-2">
            <Gauge className="size-5 shrink-0" />
            Change video speed
          </DialogTitle>
          <DialogDescription className="break-all">
            {video.name}
          </DialogDescription>
        </DialogHeader>

        <div className="min-h-0 space-y-4 overflow-y-auto px-5 py-4">
          <div className="relative mx-auto aspect-video w-full max-w-md overflow-hidden rounded-md bg-black">
            {videoUrl && !videoError && (
              <video
                ref={videoRef}
                src={videoUrl}
                controls
                className="size-full object-contain"
                onLoadedMetadata={handleLoadedMetadata}
                onError={() => {
                  setLoadingVideo(false);
                  setDuration(null);
                  setVideoError(
                    getErrorMessage("video-speed", {
                      code: "VIDEO_DURATION_UNAVAILABLE",
                    }).description,
                  );
                }}
              />
            )}
            {loadingVideo && (
              <div
                className="absolute inset-0 flex items-center justify-center text-white"
                role="status"
                aria-label="Loading video"
              >
                <Loader2 className="size-6 animate-spin" />
              </div>
            )}
          </div>
          {duration !== null && (
            <p className="text-right text-xs text-muted-foreground">
              Duration: {displayTime(duration)}
            </p>
          )}
          {videoError && (
            <Alert variant="destructive">
              <AlertCircle className="size-4" />
              <AlertTitle>Video unavailable</AlertTitle>
              <AlertDescription>{videoError}</AlertDescription>
            </Alert>
          )}

          {activeInterval && (
            <fieldset disabled={controlsDisabled} className="min-w-0 space-y-3">
              <legend className="mb-2 text-sm font-medium">
                Interval {activeIndex + 1}
              </legend>
              {duration !== null && duration > 0 && (
                <Slider
                  min={0}
                  max={duration}
                  step={0.1}
                  minStepsBetweenThumbs={0}
                  value={[sliderStart, sliderEnd]}
                  disabled={controlsDisabled}
                  aria-label="Active time interval"
                  onValueChange={([start, end]) =>
                    updateActive({
                      startTime: String(Math.max(0, Math.min(duration, start))),
                      endTime: String(Math.max(0, Math.min(duration, end))),
                    })
                  }
                />
              )}
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                <div className="min-w-0 space-y-1.5">
                  <Label htmlFor="speed-start">Start (s)</Label>
                  <Input
                    id="speed-start"
                    type="number"
                    step="any"
                    min={0}
                    max={duration ?? undefined}
                    value={activeInterval.startTime}
                    aria-describedby="speed-validation"
                    onChange={(event) =>
                      updateActive({ startTime: event.target.value })
                    }
                  />
                </div>
                <div className="min-w-0 space-y-1.5">
                  <Label htmlFor="speed-end">End (s)</Label>
                  <Input
                    id="speed-end"
                    type="number"
                    step="any"
                    min={0}
                    max={duration ?? undefined}
                    value={activeInterval.endTime}
                    aria-describedby="speed-validation"
                    onChange={(event) =>
                      updateActive({ endTime: event.target.value })
                    }
                  />
                </div>
                <div className="col-span-2 min-w-0 space-y-1.5 sm:col-span-1">
                  <Label htmlFor="speed-value">Speed</Label>
                  <Select
                    value={String(activeInterval.speed)}
                    disabled={controlsDisabled}
                    onValueChange={(value) =>
                      updateActive({ speed: Number(value) as VideoSpeed })
                    }
                  >
                    <SelectTrigger id="speed-value">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {VIDEO_SPEEDS.map((speed) => (
                        <SelectItem key={speed} value={String(speed)}>
                          {speed}x
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </fieldset>
          )}

          <section aria-label="Configured intervals" className="space-y-2">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h3 className="text-sm font-medium">
                Intervals ({intervals.length})
              </h3>
              <Button
                type="button"
                size="sm"
                variant="outline"
                disabled={controlsDisabled}
                onClick={addInterval}
              >
                <Plus className="mr-1.5 size-4" />
                Add interval
              </Button>
            </div>
            {!intervals.length && (
              <p className="py-2 text-sm text-muted-foreground">
                No intervals configured.
              </p>
            )}
            <ul className="divide-y border-y">
              {intervals.map((item, index) => {
                const invalid = validation.issues.some((issue) =>
                  issue.intervalIds.includes(item.id),
                );
                return (
                  <li
                    key={item.id}
                    className={`flex min-w-0 flex-wrap items-center gap-2 py-2 ${item.id === activeId ? "bg-muted/40" : ""}`}
                  >
                    <div className="min-w-0 flex-1 px-2 text-sm">
                      <span className="font-medium">{index + 1}. </span>
                      <span
                        className={`break-words ${invalid ? "text-destructive" : ""}`}
                      >
                        {displayTime(item.startTime)} -{" "}
                        {displayTime(item.endTime)}
                      </span>
                      <span className="ml-2 whitespace-nowrap font-medium">
                        {item.speed}x
                      </span>
                    </div>
                    <div className="flex shrink-0 gap-1">
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="size-8"
                            disabled={controlsDisabled}
                            aria-label={`Edit interval ${index + 1}`}
                            aria-pressed={item.id === activeId}
                            onClick={() => setActiveId(item.id)}
                          >
                            <Pencil className="size-4" />
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent>
                          Edit interval {index + 1}
                        </TooltipContent>
                      </Tooltip>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="size-8 text-destructive"
                            disabled={controlsDisabled}
                            aria-label={`Remove interval ${index + 1}`}
                            onClick={() => removeInterval(item.id)}
                          >
                            <Trash2 className="size-4" />
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent>
                          Remove interval {index + 1}
                        </TooltipContent>
                      </Tooltip>
                    </div>
                  </li>
                );
              })}
            </ul>
          </section>

          <div id="speed-validation" aria-live="polite">
            {!loadingVideo && !videoError && validation.issues.length > 0 && (
              <Alert variant="destructive">
                <AlertCircle className="size-4" />
                <AlertTitle>Check the intervals</AlertTitle>
                <AlertDescription>
                  <ul className="list-inside list-disc space-y-1">
                    {validation.issues.map((issue, index) => (
                      <li key={`${issue.code}-${index}`}>
                        {issue.intervalIds.length > 0 &&
                          `Interval${issue.intervalIds.length > 1 ? "s" : ""} ${issue.intervalIds.map((id) => intervals.findIndex((item) => item.id === id) + 1).join(" and ")}: `}
                        {getErrorMessage("video-speed", issue).description}
                      </li>
                    ))}
                  </ul>
                </AlertDescription>
              </Alert>
            )}
          </div>
          {submissionError && (
            <Alert variant="destructive">
              <AlertCircle className="size-4" />
              <AlertTitle>Submission failed</AlertTitle>
              <AlertDescription>{submissionError}</AlertDescription>
            </Alert>
          )}
        </div>

        <DialogFooter className="shrink-0 gap-2 border-t px-5 py-4 sm:gap-0">
          <Button
            type="button"
            variant="outline"
            disabled={changeSpeed.isPending}
            onClick={() => onOpenChange(false)}
          >
            Cancel
          </Button>
          <Button
            type="button"
            disabled={controlsDisabled || !validation.isValid}
            onClick={handleSubmit}
          >
            {changeSpeed.isPending ? (
              <Loader2 className="mr-2 size-4 animate-spin" />
            ) : (
              <Play className="mr-2 size-4" />
            )}
            {changeSpeed.isPending ? "Submitting..." : "Process"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
