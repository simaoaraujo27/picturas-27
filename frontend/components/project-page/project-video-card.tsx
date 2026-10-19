"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Download, Film, Loader2, Play, Scissors, Trash } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { downloadProjectVideo } from "@/lib/projects";
import { useCanEditProject, useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useDeleteProjectVideo, useDownloadProjectVideo } from "@/lib/mutations/projects";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuTrigger,
} from "@/components/ui/context-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

interface ProjectVideoCardProps {
  video: ProjectVideo;
  onSelect: () => void;
  onTrim?: () => void;
}

export function ProjectVideoCard({ video, onSelect, onTrim }: ProjectVideoCardProps) {
  const [blobUrl, setBlobUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState(false);

  const { _id: pid, version } = useProjectInfo();
  const session = useSession();
  const searchParams = useSearchParams();
  const ownerId = searchParams.get("owner") ?? session.user._id;
  const shareId = searchParams.get("share") ?? undefined;
  const canEdit = useCanEditProject();
  const { toast } = useToast();

  const deleteVideo = useDeleteProjectVideo(session.user._id, pid, session.token, ownerId, shareId);
  const downloadVideo = useDownloadProjectVideo();

  const videoId = video.id || (video as any)._id;

  useEffect(() => {
    let active = true;
    if (!videoId) return;
    setLoading(true);

    downloadProjectVideo({
      uid: session.user._id,
      pid,
      videoId,
      token: session.token,
      ownerId,
      shareId,
    })
      .then((blob) => {
        if (!active) return;
        const url = URL.createObjectURL(blob);
        setBlobUrl(url);
        setLoading(false);
      })
      .catch(() => {
        if (!active) return;
        setLoading(false);
      });

    return () => {
      active = false;
      if (blobUrl) {
        URL.revokeObjectURL(blobUrl);
      }
    };
  }, [videoId, pid, session.user._id, session.token, ownerId, shareId]);

  async function handleDownload(e?: React.MouseEvent) {
    e?.stopPropagation();
    if (!videoId) return;
    try {
      await downloadVideo.mutateAsync({
        uid: session.user._id,
        pid,
        videoId,
        name: video.name,
        token: session.token,
        ownerId,
        shareId,
      });
      toast({ title: `Video ${video.name} downloaded.` });
    } catch (err) {
      const { title, description } = getErrorMessage("video-download", err);
      toast({ title, description, variant: "destructive" });
    }
  }

  async function handleDeleteConfirm() {
    if (!videoId) return;
    try {
      await deleteVideo.mutateAsync({
        videoId,
        projectVersion: version,
      });
      setConfirmDeleteOpen(false);
      toast({ title: `Video ${video.name} deleted.` });
    } catch (err) {
      const { title, description } = getErrorMessage("video-delete", err);
      toast({ title, description, variant: "destructive" });
    }
  }

  const formattedSize = (video.size / 1_000_000).toLocaleString("en-US", {
    maximumFractionDigits: 1,
  });

  return (
    <>
      <ContextMenu>
        <ContextMenuTrigger className="size-full block">
          <Card
            onClick={onSelect}
            className="group relative overflow-hidden size-full rounded-xl border bg-black/80 flex flex-col justify-between cursor-pointer transition-all hover:border-primary hover:shadow-xl focus:outline-none focus:ring-2 focus:ring-primary"
            title={`Open ${video.name} in video editor`}
          >
            {/* Background Video Preview Thumbnail */}
            <div className="absolute inset-0 size-full overflow-hidden bg-black flex items-center justify-center pointer-events-none">
              {loading ? (
                <div className="flex flex-col items-center gap-2 text-muted-foreground">
                  <Loader2 className="size-6 animate-spin text-primary" />
                </div>
              ) : blobUrl ? (
                <video
                  src={blobUrl}
                  preload="metadata"
                  muted
                  playsInline
                  className="size-full object-cover opacity-75 group-hover:opacity-95 group-hover:scale-105 transition-all duration-300 pointer-events-none"
                  onLoadedMetadata={(e) => {
                    try {
                      e.currentTarget.currentTime = 0.1;
                    } catch (_) {}
                  }}
                />
              ) : (
                <Film className="size-10 text-muted-foreground/40 stroke-1" />
              )}
            </div>

            {/* Dark Gradient Overlay */}
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-black/60 pointer-events-none" />

            {/* Top Bar with Video Badge */}
            <div className="relative z-10 flex items-center justify-between p-2.5">
              <Badge
                variant="secondary"
                className="gap-1.5 bg-black/70 text-primary border border-primary/40 backdrop-blur-md text-[11px] font-medium shadow-sm"
              >
                <Film className="size-3" />
                <span>VIDEO</span>
              </Badge>

              <span className="text-[11px] font-mono font-medium text-white/80 bg-black/60 backdrop-blur-md px-1.5 py-0.5 rounded border border-white/10">
                {formattedSize} MB
              </span>
            </div>

            {/* Center Play Icon on Hover */}
            <div className="relative z-10 flex items-center justify-center">
              <div className="size-11 rounded-full bg-black/60 backdrop-blur-md border border-white/20 text-white flex items-center justify-center shadow-lg group-hover:scale-110 group-hover:bg-primary group-hover:text-primary-foreground group-hover:border-primary transition-all duration-200">
                <Play className="size-5 fill-current ml-0.5" />
              </div>
            </div>

            {/* Bottom File Info Bar */}
            <div className="relative z-10 p-2.5 flex items-center justify-between gap-2">
              <div className="min-w-0 flex-1">
                <p className="text-xs font-semibold text-white truncate group-hover:text-primary transition-colors">
                  {video.name}
                </p>
                <p className="text-[10px] text-white/60">Click to edit with video tools</p>
              </div>

              {canEdit && onTrim && (
                <Button
                  size="icon"
                  variant="ghost"
                  className="size-7 text-white/80 hover:text-white hover:bg-white/20 shrink-0"
                  title="Trim video"
                  onClick={(e) => {
                    e.stopPropagation();
                    onTrim();
                  }}
                >
                  <Scissors className="size-3.5" />
                </Button>
              )}
            </div>
          </Card>
        </ContextMenuTrigger>

        <ContextMenuContent>
          <ContextMenuItem
            className="flex justify-between"
            onClick={(e) => {
              e.stopPropagation();
              onSelect();
            }}
          >
            <span>Open in Editor</span>
            <Play className="size-4" />
          </ContextMenuItem>

          {canEdit && onTrim && (
            <ContextMenuItem
              className="flex justify-between"
              onClick={(e) => {
                e.stopPropagation();
                onTrim();
              }}
            >
              <span>Trim Video</span>
              <Scissors className="size-4" />
            </ContextMenuItem>
          )}

          <ContextMenuItem className="flex justify-between" onClick={handleDownload}>
            <span>Download</span>
            <Download className="size-4" />
          </ContextMenuItem>

          {canEdit && (
            <ContextMenuItem
              className="flex justify-between text-destructive focus:text-destructive"
              onClick={(e) => {
                e.stopPropagation();
                setConfirmDeleteOpen(true);
              }}
            >
              <span>Delete</span>
              <Trash className="size-4" />
            </ContextMenuItem>
          )}
        </ContextMenuContent>
      </ContextMenu>

      {/* Delete Confirmation Modal */}
      <Dialog open={confirmDeleteOpen} onOpenChange={setConfirmDeleteOpen}>
        <DialogContent onClick={(e) => e.stopPropagation()}>
          <DialogHeader>
            <DialogTitle>Are you sure?</DialogTitle>
            <DialogDescription>
              This will permanently delete <strong>{video.name}</strong> from the project.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-2 pt-2">
            <Button
              variant="outline"
              disabled={deleteVideo.isPending}
              onClick={() => setConfirmDeleteOpen(false)}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              disabled={deleteVideo.isPending}
              onClick={handleDeleteConfirm}
            >
              {deleteVideo.isPending ? "Deleting..." : "Permanently Delete"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
