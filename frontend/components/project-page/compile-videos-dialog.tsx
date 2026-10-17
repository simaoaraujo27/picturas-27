"use client";

import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useQueryClient } from "@tanstack/react-query";
import { ArrowDown, ArrowUp, Film, Plus, X } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { useCanEditProject, useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { api } from "@/lib/axios";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

type Job = {
  id: string;
  state: string;
  progress: number;
  sourceIds: string[];
  error: string | null;
  resultId: string | null;
};

const MIN_VIDEOS = 2; // RN1
const ACTIVE_STATES = ["QUEUED", "PROCESSING"];
const FINAL_STATES = ["COMPLETED", "FAILED", "CANCELLED"];

const STATE_LABELS: Record<string, string> = {
  QUEUED: "Queued",
  PROCESSING: "Processing",
  COMPLETED: "Completed",
  FAILED: "Failed",
  CANCELLED: "Cancelled",
};

// Erros ao iniciar a compilação (o backend devolve { code })
const SUBMIT_ERRORS: Record<string, string> = {
  MIN_VIDEOS: "Select at least two videos.",
  TOO_MANY_VIDEOS: "You selected too many videos for a single compilation.",
  VIDEO_NOT_FOUND: "One of the selected videos no longer exists in this project.",
  UNSUPPORTED_VIDEO: "One of the selected videos is not supported.",
  PLAN_FORBIDDEN: "Your plan does not allow video processing.",
  COMPILE_TOO_LONG: "The total duration exceeds the limit allowed by your plan.",
  STORAGE_QUOTA_EXCEEDED: "You do not have enough storage space.",
  DAILY_QUOTA_EXHAUSTED: "You have reached your daily operations limit.",
  EDIT_REQUIRED: "You need edit permission to compile videos.",
  INVALID_VIDEO_NAME: "The video name is not valid.",
  COMPILE_UNAVAILABLE: "The compilation could not be started, please try again.",
};

// Erros do processamento (o worker regista o código na tarefa)
const JOB_ERRORS: Record<string, string> = {
  VIDEO_UNREADABLE: "One of the videos could not be read.",
  TOTAL_TOO_LONG: "The total duration exceeds the allowed limit.",
  STORAGE_QUOTA_EXCEEDED: "You do not have enough storage space.",
  PROCESSING_TIMEOUT: "Processing exceeded the allowed time limit.",
  FFMPEG_FAILED: "The compilation could not be completed, please try again.",
  INVALID_OUTPUT_DURATION: "The compilation could not be completed, please try again.",
  PROJECT_CHANGED: "The project changed during processing. Please try again.",
  NETWORK_FAILURE: "A connection to a service failed during processing.",
  SERVICE_UNAVAILABLE: "A processing service is temporarily unavailable.",
  QUEUE_UNAVAILABLE: "The compilation could not be started, please try again.",
  WORKER_TIMEOUT: "Processing stopped responding.",
};

export function CompileVideosDialog({ videos }: { videos: ProjectVideo[] }) {
  const { _id: pid } = useProjectInfo();
  const canEdit = useCanEditProject();
  const session = useSession();
  const search = useSearchParams();
  const ownerId = search.get("owner") ?? session.user._id;
  const shareId = search.get("share") ?? undefined;
  const queryClient = useQueryClient();

  const [open, setOpen] = useState(false);
  const [selectedIds, setSelectedIds] = useState<string[]>([]); // a ordem do array é a ordem final
  const [newName, setNewName] = useState("");
  const [job, setJob] = useState<Job>();
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const base = `/projects/${ownerId}/${pid}/video`;
  const query = shareId ? `?share=${encodeURIComponent(shareId)}` : "";
  const headers = useMemo(() => ({ Authorization: `Bearer ${session.token}` }), [session.token]);

  // Limpar a seleção sempre que o diálogo abre
  useEffect(() => {
    if (open) {
      setSelectedIds([]);
      setNewName("");
      setError("");
    }
  }, [open]);

  // Consultar o estado das tarefas enquanto o diálogo está aberto
  useEffect(() => {
    if (!open) return;
    let current = true;
    const refresh = async () => {
      try {
        const response = await api.get<Job[]>(`${base}/compile/jobs${query}`, { headers });
        if (!current) return;
        setJob((previous) => {
          const selected = previous
            ? response.data.find((item) => item.id === previous.id)
            : response.data.find((item) => ACTIVE_STATES.includes(item.state));
          return selected ?? previous;
        });
      } catch {
        /* a próxima consulta pode recuperar */
      }
    };
    refresh();
    const interval = window.setInterval(refresh, 3000);
    return () => {
      current = false;
      window.clearInterval(interval);
    };
  }, [open, base, query, headers]);

  // Quando termina, atualizar o projeto (aparece o vídeo novo) e as operações restantes
  useEffect(() => {
    if (!job?.state) return;
    if (job.state === "COMPLETED") {
      void queryClient.invalidateQueries({ queryKey: ["project"], refetchType: "all" });
    }
    if (FINAL_STATES.includes(job.state)) {
      void queryClient.invalidateQueries({ queryKey: ["session"], refetchType: "all" });
    }
  }, [job?.state, job?.id, queryClient]);

  if (!canEdit) return null;

  const byId = new Map(videos.map((v) => [v.id, v]));
  const selected = selectedIds
    .map((id) => byId.get(id))
    .filter((v): v is ProjectVideo => !!v);
  const available = videos.filter((v) => !selectedIds.includes(v.id));
  const tooFew = selected.length < MIN_VIDEOS;
  const durationKnown = selected.length > 0 && selected.every((v) => typeof v.duration === "number");
  const totalDuration = selected.reduce((sum, v) => sum + (v.duration ?? 0), 0);
  const active = !!job && ACTIVE_STATES.includes(job.state);

  const add = (id: string) => setSelectedIds((prev) => [...prev, id]);
  const remove = (id: string) => setSelectedIds((prev) => prev.filter((x) => x !== id));
  const move = (index: number, delta: -1 | 1) =>
    setSelectedIds((prev) => {
      const target = index + delta;
      if (target < 0 || target >= prev.length) return prev;
      const next = [...prev];
      [next[index], next[target]] = [next[target], next[index]];
      return next;
    });

  const submit = async () => {
    setError("");
    if (tooFew) {
      setError(SUBMIT_ERRORS.MIN_VIDEOS);
      return;
    }
    setBusy(true);
    try {
      const response = await api.post<Job>(
        `${base}/compile${query}`,
        { videoIds: selectedIds, newName: newName.trim() || undefined },
        { headers }
      );
      setJob(response.data);
      setSelectedIds([]);
      setNewName("");
      void queryClient.invalidateQueries({ queryKey: ["session"], refetchType: "all" });
    } catch (cause: unknown) {
      const code = (cause as { response?: { data?: { code?: string } } })?.response?.data?.code;
      setError((code && SUBMIT_ERRORS[code]) || "Could not start the compilation.");
    } finally {
      setBusy(false);
    }
  };

  const cancel = async () => {
    if (!job) return;
    try {
      const response = await api.delete<Job>(`${base}/compile/jobs/${job.id}${query}`, { headers });
      setJob(response.data);
    } catch {
      setError("Could not cancel the task.");
    }
  };

  return (
    <>
      <Button
        variant="outline"
        className="inline-flex gap-2"
        disabled={videos.length < MIN_VIDEOS}
        title={
          videos.length < MIN_VIDEOS
            ? "You need at least two videos to compile"
            : "Compile videos"
        }
        onClick={() => setOpen(true)}
      >
        <Film className="size-4" />
        Compile
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Film className="size-5" />
              Compile Videos
            </DialogTitle>
            <DialogDescription>
              Choose at least two videos and set their order. The originals are kept
              untouched and a new video is created.
            </DialogDescription>
          </DialogHeader>

          {/* Estado da tarefa */}
          {job && (
            <div aria-live="polite" className="space-y-2 rounded-lg border p-3">
              <p>
                Status: {STATE_LABELS[job.state] ?? job.state} · {job.progress}%
              </p>
              <progress
                className="w-full"
                value={job.progress}
                max="100"
                aria-label="Compilation progress"
              />
              {active && (
                <Button variant="destructive" onClick={cancel}>
                  Cancel
                </Button>
              )}
              {job.state === "COMPLETED" && <p>The new video is available in the project video list.</p>}
              {job.error && (
                <p className="text-destructive">
                  {JOB_ERRORS[job.error] ?? "The compilation could not be completed, please try again."}
                </p>
              )}
            </div>
          )}

          {/* Seleção (escondida enquanto há uma tarefa a decorrer) */}
          {!active && (
            <div className="space-y-4 py-2">
              <div className="space-y-1.5">
                <p className="text-xs font-medium">Available videos</p>
                <div className="max-h-40 space-y-1 overflow-y-auto rounded-lg border p-2">
                  {available.length === 0 ? (
                    <p className="p-2 text-xs text-muted-foreground">
                      All videos have already been added to the compilation.
                    </p>
                  ) : (
                    available.map((v) => (
                      <div
                        key={v.id}
                        className="flex items-center justify-between gap-2 rounded-md px-2 py-1 text-sm hover:bg-muted/50"
                      >
                        <span className="truncate">
                          {v.name}
                          {typeof v.duration === "number" && (
                            <span className="ml-2 text-xs text-muted-foreground">
                              {v.duration.toFixed(1)} s
                            </span>
                          )}
                        </span>
                        <Button
                          type="button"
                          size="sm"
                          variant="secondary"
                          className="h-7 gap-1"
                          onClick={() => add(v.id)}
                        >
                          <Plus className="size-3.5" />
                          Add
                        </Button>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div className="space-y-1.5">
                <p className="text-xs font-medium">
                  Compilation order ({selected.length} selected)
                </p>
                <div className="max-h-48 space-y-1 overflow-y-auto rounded-lg border bg-muted/30 p-2">
                  {selected.length === 0 ? (
                    <p className="p-2 text-xs text-muted-foreground">No videos selected yet.</p>
                  ) : (
                    selected.map((v, index) => (
                      <div
                        key={`${v.id}-${index}`}
                        className="flex items-center justify-between gap-2 rounded-md bg-background px-2 py-1 text-sm"
                      >
                        <span className="truncate">
                          <strong className="mr-2">{index + 1}.</strong>
                          {v.name}
                        </span>
                        <div className="flex shrink-0 gap-1">
                          <Button
                            type="button"
                            size="icon"
                            variant="ghost"
                            className="size-7"
                            title="Move up"
                            onClick={() => move(index, -1)}
                            disabled={index === 0}
                          >
                            <ArrowUp className="size-3.5" />
                          </Button>
                          <Button
                            type="button"
                            size="icon"
                            variant="ghost"
                            className="size-7"
                            title="Move down"
                            onClick={() => move(index, 1)}
                            disabled={index === selected.length - 1}
                          >
                            <ArrowDown className="size-3.5" />
                          </Button>
                          <Button
                            type="button"
                            size="icon"
                            variant="ghost"
                            className="size-7"
                            title="Remove"
                            onClick={() => remove(v.id)}
                          >
                            <X className="size-3.5" />
                          </Button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
                <div className="flex justify-between text-xs text-muted-foreground">
                  <span className={tooFew ? "text-destructive" : undefined}>
                    {tooFew ? `Select at least ${MIN_VIDEOS} videos.` : "Ready to compile."}
                  </span>
                  {durationKnown && <span>Total duration: {totalDuration.toFixed(1)} s</span>}
                </div>
              </div>

              <div className="space-y-1.5">
                <label htmlFor="compile-name" className="text-xs font-medium">
                  New video name (optional)
                </label>
                <Input
                  id="compile-name"
                  placeholder="compilation.mp4"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                />
              </div>

              <div className="flex justify-end">
                <Button disabled={busy || tooFew} onClick={submit} className="gap-2">
                  <Film className="size-4" />
                  {busy ? "Starting..." : "Compile videos"}
                </Button>
              </div>
            </div>
          )}

          {error && (
            <p role="alert" className="text-destructive">
              {error}
            </p>
          )}
        </DialogContent>
      </Dialog>
    </>
  );
}
