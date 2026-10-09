"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Download, FileVideo, Trash } from "lucide-react";
import type { ProjectVideo } from "@/lib/projects";
import { useCanEditProject, useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useDeleteProjectVideo, useDownloadProjectVideo } from "@/lib/mutations/projects";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";

export function ProjectVideoList({ videos }: { videos: ProjectVideo[] }) {
  if (!videos.length) return null;
  return (
    <section aria-label="Project videos" className="border-b px-4 py-3">
      <h2 className="mb-2 text-sm font-semibold">Videos</h2>
      <ul className="flex flex-wrap gap-2">
        {videos.map((video) => <ProjectVideoItem key={video.id} video={video} />)}
      </ul>
    </section>
  );
}

function ProjectVideoItem({ video }: { video: ProjectVideo }) {
  const [confirmOpen, setConfirmOpen] = useState(false);
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
    <li className="max-w-full">
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="outline" className="h-auto max-w-full gap-2 px-3 py-2 text-sm font-normal" aria-label={`Options for ${video.name}`}>
            <FileVideo className="size-4 shrink-0" aria-hidden="true" />
            <span className="break-all text-left">{video.name}</span>
            <span className="shrink-0 text-muted-foreground">{(video.size / 1_000_000).toLocaleString("pt-PT", { maximumFractionDigits: 2 })} MB</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="start">
          {canEdit && <DropdownMenuItem className="flex justify-between" onSelect={() => setConfirmOpen(true)}>
            <span>Delete</span><Trash className="size-4" />
          </DropdownMenuItem>}
          <DropdownMenuItem className="flex justify-between" disabled={downloadVideo.isPending} onSelect={download}>
            <span>Download</span><Download className="size-4" />
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
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
    </li>
  );
}
