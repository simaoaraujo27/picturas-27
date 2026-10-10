"use client";

import { useEffect, useRef, useState } from "react";
import { Download, FileVideo, Film, Loader2, Play, Scissors, Trash } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { downloadProjectVideo } from "@/lib/projects";
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
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface VideoWorkspaceProps {
  video: ProjectVideo;
  videos: ProjectVideo[];
  projectId: string;
  projectVersion: number;
  onSelectVideo: (video: ProjectVideo) => void;
  onTrimVideo: (video: ProjectVideo) => void;
  canEdit: boolean;
  ownerId?: string;
  shareId?: string;
}

export function VideoWorkspace({
  video,
  videos,
  projectId,
  projectVersion,
  onSelectVideo,
  onTrimVideo,
  canEdit,
  ownerId,
  shareId,
}: VideoWorkspaceProps) {
  const session = useSession();
  const { toast } = useToast();
  const videoRef = useRef<HTMLVideoElement | null>(null);

  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState<boolean>(false);

  const deleteVideo = useDeleteProjectVideo(
    session.user._id,
    projectId,
    session.token,
    ownerId,
    shareId
  );
  const downloadVideo = useDownloadProjectVideo();

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

  async function handleDownload() {
    try {
      await downloadVideo.mutateAsync({
        uid: session.user._id,
        pid: projectId,
        videoId: video.id,
        name: video.name,
        token: session.token,
        ownerId,
        shareId,
      });
      toast({ title: `Video ${video.name} downloaded successfully.` });
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
          <div className="flex items-center gap-2">
            <Film className="size-5 text-primary" />
            <span className="font-semibold text-sm max-w-[200px] sm:max-w-xs truncate" title={video.name}>
              {video.name}
            </span>
          </div>

          <Badge variant="outline" className="text-xs font-mono">
            {formattedSize} MB
          </Badge>

          {videos.length > 1 && (
            <div className="flex items-center gap-2 pl-2 border-l">
              <span className="text-xs text-muted-foreground hidden sm:inline">Video:</span>
              <Select
                value={video.id}
                onValueChange={(val) => {
                  const target = videos.find((v) => v.id === val);
                  if (target) onSelectVideo(target);
                }}
              >
                <SelectTrigger className="h-8 text-xs w-[180px]">
                  <SelectValue placeholder="Select video" />
                </SelectTrigger>
                <SelectContent>
                  {videos.map((v) => (
                    <SelectItem key={v.id} value={v.id} className="text-xs">
                      {v.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}
        </div>

        {/* Monitor Actions */}
        <div className="flex items-center gap-2">
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

          <Button
            size="sm"
            variant="outline"
            disabled={downloadVideo.isPending}
            onClick={handleDownload}
            title="Download MP4 file"
          >
            <Download className="size-4" />
            <span className="hidden sm:inline ml-1.5">Download</span>
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

        {/* Monitor Footer Trim Prompt */}
        {canEdit && (
          <div className="mt-3 flex items-center gap-3 text-xs text-muted-foreground">
            <span>Want to trim a section of this video?</span>
            <Button
              variant="link"
              size="sm"
              onClick={() => onTrimVideo(video)}
              className="h-auto p-0 text-primary font-medium hover:underline gap-1.5"
            >
              <Scissors className="size-3.5" />
              Click here to set start and end markers
            </Button>
          </div>
        )}
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
    </div>
  );
}
