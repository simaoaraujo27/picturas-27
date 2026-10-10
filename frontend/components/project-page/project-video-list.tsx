"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Download, FileVideo, Scissors, Trash } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { useCanEditProject, useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useDeleteProjectVideo, useDownloadProjectVideo } from "@/lib/mutations/projects";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { TrimVideoDialog } from "./trim-video-dialog";

interface ProjectVideoListProps {
  videos: ProjectVideo[];
  selectedVideoId?: string;
  onSelectVideo?: (video: ProjectVideo) => void;
  onTrimVideo?: (video: ProjectVideo) => void;
}

export function ProjectVideoList({
  videos,
  selectedVideoId,
  onSelectVideo,
  onTrimVideo,
}: ProjectVideoListProps) {
  if (!videos.length) return null;
  return (
    <section aria-label="Project videos" className="border-t px-4 py-3 bg-card/60 backdrop-blur-sm shrink-0">
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-sm font-semibold flex items-center gap-1.5">
          <FileVideo className="size-4 text-primary" />
          Vídeos do Projeto ({videos.length})
        </h2>
        <span className="text-xs text-muted-foreground">
          Clique num vídeo para reproduzir e editar no monitor central
        </span>
      </div>
      <ul className="flex flex-wrap gap-2">
        {videos.map((video) => (
          <ProjectVideoItem
            key={video.id}
            video={video}
            isSelected={video.id === selectedVideoId}
            onSelect={() => onSelectVideo?.(video)}
            onTrim={() => onTrimVideo?.(video)}
          />
        ))}
      </ul>
    </section>
  );
}

function ProjectVideoItem({
  video,
  isSelected,
  onSelect,
  onTrim,
}: {
  video: ProjectVideo;
  isSelected?: boolean;
  onSelect?: () => void;
  onTrim?: () => void;
}) {
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [trimOpen, setTrimOpen] = useState(false);
  const { _id: pid, version } = useProjectInfo();
  const canEdit = useCanEditProject();
  const session = useSession();
  const search = useSearchParams();
  const ownerId = search.get("owner") ?? session.user._id;
  const shareId = search.get("share") ?? undefined;
  const deleteVideo = useDeleteProjectVideo(session.user._id, pid, session.token, ownerId, shareId);
  const downloadVideo = useDownloadProjectVideo();
  const { toast } = useToast();

  async function confirmDelete() {
    try {
      await deleteVideo.mutateAsync({ videoId: video.id, projectVersion: version });
      setConfirmOpen(false);
      toast({ title: `Vídeo ${video.name} eliminado com sucesso.` });
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
      toast({ title: `Vídeo ${video.name} descarregado com sucesso.` });
    } catch (error) {
      const { title, description } = getErrorMessage("video-download", error);
      toast({ title, description, variant: "destructive" });
    }
  }

  function handleTrimClick() {
    if (onTrim) {
      onTrim();
    } else {
      setTrimOpen(true);
    }
  }

  return (
    <li className="max-w-full flex items-center">
      <div
        className={`group flex items-center rounded-md border text-sm transition-all ${
          isSelected
            ? "border-primary bg-primary/10 shadow-sm ring-1 ring-primary"
            : "border-input bg-background hover:bg-accent/50"
        }`}
      >
        <button
          type="button"
          onClick={onSelect}
          className="flex items-center gap-2 px-3 py-2 text-left"
          title={`Ver ${video.name} no monitor central`}
        >
          <FileVideo className={`size-4 shrink-0 ${isSelected ? "text-primary" : "text-muted-foreground"}`} />
          <span className="font-medium truncate max-w-[180px] sm:max-w-[240px]">{video.name}</span>
          <span className="shrink-0 text-xs text-muted-foreground">
            {(video.size / 1_000_000).toLocaleString("pt-PT", { maximumFractionDigits: 1 })} MB
          </span>
        </button>

        {canEdit && (
          <Button
            variant="ghost"
            size="sm"
            onClick={handleTrimClick}
            className="h-8 px-2 text-primary hover:text-primary hover:bg-primary/15"
            title="Recortar vídeo (Trim)"
          >
            <Scissors className="size-3.5" />
          </Button>
        )}

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button
              variant="ghost"
              size="sm"
              className="h-8 px-1.5 text-muted-foreground hover:text-foreground"
              aria-label={`Mais opções para ${video.name}`}
            >
              •••
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            {canEdit && (
              <DropdownMenuItem className="flex justify-between" onSelect={handleTrimClick}>
                <span>Recortar (Trim)</span>
                <Scissors className="size-4" />
              </DropdownMenuItem>
            )}
            <DropdownMenuItem className="flex justify-between" disabled={downloadVideo.isPending} onSelect={download}>
              <span>Download</span>
              <Download className="size-4" />
            </DropdownMenuItem>
            {canEdit && (
              <DropdownMenuItem className="flex justify-between text-destructive" onSelect={() => setConfirmOpen(true)}>
                <span>Eliminar</span>
                <Trash className="size-4" />
              </DropdownMenuItem>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      <Dialog open={confirmOpen} onOpenChange={(next) => { if (!deleteVideo.isPending) setConfirmOpen(next); }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Tem a certeza?</DialogTitle>
            <DialogDescription>Esta ação não pode ser anulada.</DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setConfirmOpen(false)}>
              Cancelar
            </Button>
            <Button variant="destructive" disabled={deleteVideo.isPending} onClick={confirmDelete}>
              {deleteVideo.isPending ? "A eliminar..." : "Eliminar Definitivamente"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <TrimVideoDialog
        video={video}
        open={trimOpen}
        onOpenChange={setTrimOpen}
        ownerId={ownerId}
        shareId={shareId}
      />
    </li>
  );
}
