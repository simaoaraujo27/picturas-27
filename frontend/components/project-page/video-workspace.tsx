"use client";

import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Download, FileVideo, Film, Gauge, HardDrive, LayoutGrid, Loader2, Redo2, Scissors, Trash, Trash2, Undo2 } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { downloadProjectVideo, getVideoStorageUsage } from "@/lib/projects";
import { useDeleteProjectVideo, useDownloadProjectVideo } from "@/lib/mutations/projects";
import { useSession } from "@/providers/session-provider";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
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

interface VideoWorkspaceProps {
  video: ProjectVideo;
  videos: ProjectVideo[];
  projectId: string;
  projectVersion: number;
  onSelectVideo: (video: ProjectVideo) => void;
  onTrimVideo: (video: ProjectVideo) => void;
  onRemoveSegment: (video: ProjectVideo) => void;
  onChangeVideoSpeed: (video: ProjectVideo) => void;
  canEdit: boolean;
  ownerId?: string;
  shareId?: string;
  canUndo?: boolean;
  canRedo?: boolean;
  onUndo?: () => void;
  onRedo?: () => void;
  currentStateIndex?: number;
  totalStates?: number;
  onBackToGrid?: () => void;
  pendingTrim?: { videoId: string; startTime: number; endTime: number; fastTrim?: boolean } | null;
  onCancelPendingTrim?: () => void;
}

export function VideoWorkspace({
  video,
  videos,
  projectId,
  projectVersion,
  onSelectVideo,
  onTrimVideo,
  onRemoveSegment,
  onChangeVideoSpeed,
  canEdit,
  ownerId,
  shareId,
  canUndo,
  canRedo,
  onUndo,
  onRedo,
  currentStateIndex,
  totalStates,
  onBackToGrid,
  pendingTrim,
  onCancelPendingTrim,
}: VideoWorkspaceProps) {
  const session = useSession();
  const { toast } = useToast();
  const videoRef = useRef<HTMLVideoElement | null>(null);

  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState<boolean>(false);
  const [exportDialogOpen, setExportDialogOpen] = useState<boolean>(false);
  const [exportFileName, setExportFileName] = useState<string>("");

  const deleteVideo = useDeleteProjectVideo(
    session.user._id,
    projectId,
    session.token,
    ownerId,
    shareId
  );
  const downloadVideo = useDownloadProjectVideo();

  const storageQuery = useQuery({
    queryKey: ["videoStorage", session.user._id],
    queryFn: () => getVideoStorageUsage({ uid: session.user._id, token: session.token }),
    enabled: session.user.type !== "anonymous",
  });

  // Carregar blob do vídeo selecionado
  useEffect(() => {
    let active = true;
    setLoading(true);

    if (videoUrl) {
      URL.revokeObjectURL(videoUrl);
      setVideoUrl(null);
    }

    downloadProjectVideo({
      uid: session.user._id,
      pid: projectId,
      videoId: video.id,
      token: session.token,
      ownerId,
      shareId,
    })
      .then((blob) => {
        if (!active) return;
        const url = URL.createObjectURL(blob);
        setVideoUrl(url);
        setLoading(false);
      })
      .catch((err) => {
        if (!active) return;
        setLoading(false);
        const { title, description } = getErrorMessage("video-download", err);
        toast({ title, description, variant: "destructive" });
      });

    return () => {
      active = false;
      if (videoUrl) {
        URL.revokeObjectURL(videoUrl);
      }
    };
  }, [video.id, projectId, session.user._id, session.token, ownerId, shareId]);

  const baseDisplayName = videos[0]?.name || video.name;

  function handleOpenExport() {
    const cleanName = baseDisplayName.replace(/\.mp4$/i, "");
    setExportFileName(`${cleanName}.mp4`);
    setExportDialogOpen(true);
  }

  async function handleConfirmExport() {
    let targetName = exportFileName.trim();
    if (!targetName) return;
    if (!targetName.toLowerCase().endsWith(".mp4")) {
      targetName = `${targetName}.mp4`;
    }

    try {
      await downloadVideo.mutateAsync({
        uid: session.user._id,
        pid: projectId,
        videoId: video.id,
        name: targetName,
        token: session.token,
        ownerId,
        shareId,
      });
      setExportDialogOpen(false);
      toast({ title: `Video ${targetName} exported successfully.` });
    } catch (error) {
      const { title, description } = getErrorMessage("video-download", error);
      toast({ title, description, variant: "destructive" });
    }
  }

  async function handleConfirmDelete() {
    try {
      await deleteVideo.mutateAsync({
        videoId: video.id,
        projectVersion,
      });
      setConfirmDeleteOpen(false);
      toast({ title: `Video ${video.name} deleted successfully.` });
    } catch (error) {
      const { title, description } = getErrorMessage("video-delete", error);
      toast({ title, description, variant: "destructive" });
    }
  }

  const formattedSize = (video.size / 1_000_000).toLocaleString("en-US", {
    maximumFractionDigits: 2,
  });

  return (
    <div className="flex-1 h-full min-h-0 flex flex-col bg-background/40 overflow-hidden">
      {/* Video Monitor Control Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b bg-card/50 px-4 py-2.5 backdrop-blur-sm shrink-0">
        <div className="flex items-center gap-3">
          {onBackToGrid && (
            <>
              <Button
                size="sm"
                variant="ghost"
                onClick={onBackToGrid}
                className="h-8 px-2.5 gap-1.5 text-xs text-muted-foreground hover:text-foreground"
                title="Back to all project media items (Grid)"
              >
                <LayoutGrid className="size-3.5" />
                <span>All Media</span>
              </Button>
              <div className="h-4 w-px bg-border hidden sm:block" />
            </>
          )}

          <div className="flex items-center gap-2">
            <Film className="size-5 text-primary" />
            <span className="font-semibold text-sm max-w-[200px] sm:max-w-xs truncate" title={baseDisplayName}>
              {baseDisplayName}
            </span>
          </div>

          <Badge variant="outline" className="text-xs font-mono">
            {formattedSize} MB
          </Badge>

          {/* Undo / Redo State Controls */}
          {totalStates !== undefined && totalStates > 1 && (
            <div className="flex items-center gap-1.5 pl-2 border-l">
              <Button
                size="sm"
                variant="outline"
                disabled={!canUndo}
                onClick={onUndo}
                className="h-8 gap-1.5 text-xs px-2.5"
                title="Undo (Previous video state)"
              >
                <Undo2 className="size-3.5" />
                <span className="hidden sm:inline">Undo</span>
              </Button>

              <span className="text-xs text-muted-foreground px-1 whitespace-nowrap">
                State {currentStateIndex ?? 1} / {totalStates}
              </span>

              <Button
                size="sm"
                variant="outline"
                disabled={!canRedo}
                onClick={onRedo}
                className="h-8 gap-1.5 text-xs px-2.5"
                title="Redo (Next video state)"
              >
                <span className="hidden sm:inline">Redo</span>
                <Redo2 className="size-3.5" />
              </Button>
            </div>
          )}
        </div>

        {/* Monitor Actions */}
        <div className="flex max-w-full flex-wrap items-center gap-2">
          {storageQuery.data && (
            <div className="hidden lg:flex items-center gap-1.5 text-xs text-muted-foreground mr-1">
              <HardDrive className="size-3.5 text-muted-foreground" />
              <span>Storage:</span>
              <span className="font-medium text-foreground">
                {(storageQuery.data.usedBytes / (1024 * 1024)).toFixed(0)}MB /{" "}
                {(storageQuery.data.maxBytes / (1024 * 1024 * 1024)).toFixed(0)}GB
              </span>
            </div>
          )}

          {canEdit && (
            <Button
              size="sm"
              onClick={() => onTrimVideo(video)}
              className="gap-2 bg-primary hover:bg-primary/90 text-primary-foreground shadow-sm"
              title="Open video trim tool"
            >
              <Scissors className="size-4" />
              <span>Trim Video</span>
            </Button>
          )}

          {canEdit && (
            <Button size="sm" variant="outline" onClick={() => onRemoveSegment(video)} title="Remover segmento" className="gap-2">
              <Trash2 className="size-4" />
              <span>Remover segmento</span>
            </Button>
          )}

          {canEdit && (
            <Button size="sm" variant="outline" onClick={() => onChangeVideoSpeed(video)} title="Modificar velocidade" className="gap-2">
              <Gauge className="size-4" />
              <span>Modificar velocidade</span>
            </Button>
          )}

          <Button
            size="sm"
            variant="outline"
            disabled={downloadVideo.isPending}
            onClick={handleOpenExport}
            title="Export video to MP4 file"
          >
            <Download className="size-4" />
            <span className="hidden sm:inline ml-1.5">Export</span>
          </Button>

          {canEdit && (
            <Button
              size="sm"
              variant="ghost"
              className="text-destructive hover:bg-destructive/10"
              onClick={() => setConfirmDeleteOpen(true)}
              title="Delete video from project"
            >
              <Trash className="size-4" />
            </Button>
          )}
        </div>
      </div>

      {pendingTrim && (
        <div className="flex items-center justify-between gap-3 px-4 py-2 bg-primary/10 border-b border-primary/20 text-xs text-foreground shrink-0">
          <div className="flex items-center gap-2">
            <Scissors className="size-4 text-primary shrink-0" />
            <span>
              Trim markers staged: <strong>{pendingTrim.startTime}s</strong> to <strong>{pendingTrim.endTime}s</strong>
              {pendingTrim.fastTrim && (
                <span className="ml-1 text-amber-500 font-medium">(Fast Trim)</span>
              )}. Click the <strong>Apply</strong> button in the top header to process and update live preview.
            </span>
          </div>
          {onCancelPendingTrim && (
            <Button
              size="sm"
              variant="ghost"
              className="h-6 px-2 text-xs text-muted-foreground hover:text-foreground"
              onClick={onCancelPendingTrim}
            >
              Cancel
            </Button>
          )}
        </div>
      )}

      {/* Monitor Preview Canvas */}
      <div className="flex-1 min-h-0 flex flex-col items-center justify-center p-4 sm:p-6 bg-black/90">
        <div className="relative w-full max-w-4xl max-h-full aspect-video flex items-center justify-center rounded-lg overflow-hidden border border-border/40 shadow-2xl bg-black">
          {loading ? (
            <div className="flex flex-col items-center gap-3 text-white">
              <Loader2 className="size-8 animate-spin text-primary" />
              <span className="text-sm font-medium text-muted-foreground">
                Loading video player...
              </span>
            </div>
          ) : videoUrl ? (
            <video
              ref={videoRef}
              src={videoUrl}
              controls
              className="size-full object-contain"
            />
          ) : (
            <div className="flex flex-col items-center gap-2 text-muted-foreground">
              <FileVideo className="size-10 stroke-1" />
              <span className="text-sm">Unable to preview video.</span>
            </div>
          )}
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      <Dialog open={confirmDeleteOpen} onOpenChange={setConfirmDeleteOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Are you sure?</DialogTitle>
            <DialogDescription>
              This action will permanently delete <strong>{video.name}</strong> from the project.
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
              onClick={handleConfirmDelete}
            >
              {deleteVideo.isPending ? "Deleting..." : "Permanently Delete"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Export Video Modal */}
      <Dialog open={exportDialogOpen} onOpenChange={setExportDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Download className="size-5" />
              Export Video
            </DialogTitle>
            <DialogDescription>
              Choose a file name for your exported video.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2 py-2">
            <Label htmlFor="export-video-name" className="text-xs font-medium">
              File Name
            </Label>
            <Input
              id="export-video-name"
              value={exportFileName}
              onChange={(e) => setExportFileName(e.target.value)}
              placeholder="e.g. final_video.mp4"
              disabled={downloadVideo.isPending}
            />
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              disabled={downloadVideo.isPending}
              onClick={() => setExportDialogOpen(false)}
            >
              Cancel
            </Button>
            <Button
              disabled={downloadVideo.isPending || !exportFileName.trim()}
              onClick={handleConfirmExport}
              className="gap-2"
            >
              {downloadVideo.isPending ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  Exporting...
                </>
              ) : (
                <>
                  <Download className="size-4" />
                  Export
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
