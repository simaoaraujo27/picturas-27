"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Download, FileVideo, MoreVertical, Play, Scissors, Trash } from "lucide-react";
import { TrimVideoDialog } from "./trim-video-dialog";
import { RemoveSegmentVideoDialog } from "./remove-segment-video-dialog";
import type { ProjectVideo } from "@/lib/projects";
import { useCanEditProject, useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useDeleteProjectVideo, useDownloadProjectVideo } from "@/lib/mutations/projects";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";
import { api } from "@/lib/axios";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";

export function VideoStorageUsage({ videoCount }: { videoCount: number }) {
  const { _id: pid } = useProjectInfo();
  const session = useSession();
  const search = useSearchParams();
  const ownerId = search.get("owner") ?? session.user._id;
  const shareId = search.get("share");
  const [usage, setUsage] = useState<{ used: number; limit: number }>();
  useEffect(() => {
    let current = true;
    api.get(`/projects/${ownerId}/${pid}/video/storage${shareId ? `?share=${encodeURIComponent(shareId)}` : ""}`,
      { headers: { Authorization: `Bearer ${session.token}` } }).then(response => {
      if (current) setUsage(response.data);
    }).catch(() => {});
    return () => { current = false; };
  }, [ownerId, pid, shareId, session.token, videoCount]);
  if (!usage) return null;
  return <div className="mb-2 text-xs text-muted-foreground">
    Espaço de vídeo: {(usage.used / 1_000_000).toFixed(1)} / {(usage.limit / 1_000_000).toFixed(0)} MB
    {' '}({(usage.used / usage.limit * 100).toFixed(1)}%)
    <progress className="ml-2 h-2 max-w-40 align-middle" value={usage.used} max={usage.limit} />
  </div>;
}

export function ProjectVideoItem({ video, large = false, onSelect }: {
  video: ProjectVideo; large?: boolean; onSelect?: () => void;
}) {
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [trimOpen, setTrimOpen] = useState(false);
  const [removeSegmentOpen, setRemoveSegmentOpen] = useState(false);
  const [playbackUrl, setPlaybackUrl] = useState<string>();
  const { _id: pid, version } = useProjectInfo();
  const canEdit = useCanEditProject();
  const session = useSession();
  const search = useSearchParams();
  const ownerId = search.get("owner") ?? session.user._id;
  const shareId = search.get("share") ?? undefined;
  const deleteVideo = useDeleteProjectVideo(session.user._id, pid, session.token, ownerId, shareId);
  const downloadVideo = useDownloadProjectVideo();
  const { toast } = useToast();

  useEffect(() => {
    let current = true;
    api.get<{ url: string }>(`/projects/${ownerId}/${pid}/video/${video.id}/playback${shareId ? `?share=${encodeURIComponent(shareId)}` : ""}`,
      { headers: { Authorization: `Bearer ${session.token}` } }).then(response => {
      if (current) setPlaybackUrl(response.data.url);
    }).catch(() => { if (current) setPlaybackUrl(undefined); });
    return () => { current = false; };
  }, [ownerId, pid, video.id, shareId, session.token]);

  async function confirmDelete() {
    try {
      await deleteVideo.mutateAsync({ videoId: video.id, projectVersion: version });
      setConfirmOpen(false);
      toast({ title: `Video ${video.name} deleted successfully.` });
    } catch (error) {
      const { title, description } = getErrorMessage("video-delete", error);
      toast({ title, description, variant: "destructive" });
    }
  }

  async function download() {
    try {
      await downloadVideo.mutateAsync({
        uid: session.user._id, pid, videoId: video.id, name: video.name,
        token: session.token, ownerId, shareId,
      });
      toast({ title: `Video ${video.name} downloaded.` });
    } catch (error) {
      const { title, description } = getErrorMessage("video-download", error);
      toast({ title, description, variant: "destructive" });
    }
  }

  return (
    <div className={large ? "relative flex h-full min-h-0 flex-col overflow-hidden rounded-lg border bg-background" : "group relative aspect-square overflow-hidden rounded-lg border bg-background"}>
      {large ? <div className="flex min-h-0 flex-1 items-center justify-center bg-black">
        {playbackUrl ? <video key={playbackUrl} src={playbackUrl} controls playsInline preload="metadata" className="max-h-full max-w-full" aria-label={video.name} /> : <FileVideo className="size-12 text-muted-foreground" />}
      </div> : <button type="button" onClick={onSelect} className="relative size-full bg-black" aria-label={`Abrir vídeo ${video.name}`}>
        {playbackUrl ? <video src={playbackUrl} muted playsInline preload="metadata" className="size-full object-contain pointer-events-none" aria-hidden="true" /> : <FileVideo className="mx-auto size-12 text-muted-foreground" />}
        <span className="absolute inset-0 flex items-center justify-center bg-black/20 transition-colors group-hover:bg-black/35"><Play className="size-12 fill-white text-white drop-shadow" /></span>
      </button>}
      <div className={large ? "flex items-center gap-2 px-3 py-2" : "absolute inset-x-0 bottom-0 flex items-center gap-2 bg-black/75 px-2 py-1 text-white"}>
        <span className="min-w-0 flex-1 truncate text-sm" title={video.name}>{video.name}</span>
        {video.duration != null && <span className="shrink-0 text-xs">{video.duration.toFixed(1)} s</span>}
        <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon" className="size-7 shrink-0" aria-label={`Opções de ${video.name}`}>
            <MoreVertical className="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="start">
          {canEdit && <DropdownMenuItem className="flex justify-between" onSelect={() => setTrimOpen(true)}>
            <span>Recortar vídeo</span><Scissors className="size-4" />
          </DropdownMenuItem>}
          {canEdit && <DropdownMenuItem className="flex justify-between" onSelect={() => setRemoveSegmentOpen(true)}>
            <span>Remover segmento</span><Scissors className="size-4 text-destructive" />
          </DropdownMenuItem>}
          {canEdit && <DropdownMenuItem className="flex justify-between" onSelect={() => setConfirmOpen(true)}>
            <span>Delete</span><Trash className="size-4" />
          </DropdownMenuItem>}
          <DropdownMenuItem className="flex justify-between" disabled={downloadVideo.isPending} onSelect={download}>
            <span>Download</span><Download className="size-4" />
          </DropdownMenuItem>
        </DropdownMenuContent>
        </DropdownMenu>
      </div>
      <TrimVideoDialog open={trimOpen} onOpenChange={setTrimOpen} video={video} ownerId={ownerId} projectId={pid} token={session.token} shareId={shareId} allowFast={session.user.type === "premium"} />
      <RemoveSegmentVideoDialog open={removeSegmentOpen} onOpenChange={setRemoveSegmentOpen} video={video} ownerId={ownerId} projectId={pid} projectVersion={version} token={session.token} shareId={shareId} />
      <Dialog open={confirmOpen} onOpenChange={(next) => { if (!deleteVideo.isPending) setConfirmOpen(next); }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Are you sure?</DialogTitle>
            <DialogDescription>This action cannot be undone.</DialogDescription>
          </DialogHeader>
          <div className="flex justify-end">
            <Button variant="destructive" disabled={deleteVideo.isPending} onClick={confirmDelete}>
              {deleteVideo.isPending ? "Deleting..." : "Permanently Delete"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
