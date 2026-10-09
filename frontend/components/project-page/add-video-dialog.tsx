"use client";

import { useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { LoaderCircle, Plus } from "lucide-react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { useAddProjectVideo } from "@/lib/mutations/projects";
import { useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";

export function AddVideoDialog() {
  const [open, setOpen] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [fileError, setFileError] = useState("");
  const submitting = useRef(false);
  const input = useRef<HTMLInputElement>(null);
  const { _id: pid, version } = useProjectInfo();
  const session = useSession();
  const search = useSearchParams();
  const ownerId = search.get("owner") ?? session.user._id;
  const shareId = search.get("share") ?? undefined;
  const upload = useAddProjectVideo(session.user._id, pid, session.token, ownerId, shareId);
  const { toast } = useToast();

  function resetSelection() {
    setFile(null);
    setFileError("");
    if (input.current) input.current.value = "";
  }

  function selectFile(selected?: File) {
    setFile(null);
    setFileError("");
    upload.reset();
    if (!selected) return;
    if (!selected.name.toLowerCase().endsWith(".mp4") ||
        (selected.type && selected.type !== "video/mp4")) {
      setFileError("Seleciona um ficheiro MP4.");
      if (input.current) input.current.value = "";
      return;
    }
    if (selected.size === 0) {
      setFileError("O ficheiro está vazio.");
      if (input.current) input.current.value = "";
      return;
    }
    setFile(selected);
  }

  function handleOpenChange(next: boolean) {
    if (upload.isPending || submitting.current) return;
    if (!next) {
      resetSelection();
      upload.reset();
    }
    setOpen(next);
  }

  async function submit() {
    if (!file || submitting.current || upload.isPending) return;
    submitting.current = true;
    try {
      await upload.mutateAsync({ file, projectVersion: version });
      toast({ title: "Vídeo adicionado ao projeto." });
      setOpen(false);
      resetSelection();
    } catch (error) {
      const { title, description } = getErrorMessage("video-upload", error);
      toast({ title, description, variant: "destructive" });
      resetSelection();
    } finally {
      submitting.current = false;
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>
        <Button className="inline-flex" variant="outline"><Plus /> Add Video</Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Add Video</DialogTitle>
          <DialogDescription>Select one MP4 video for this project.</DialogDescription>
        </DialogHeader>
        <input ref={input} type="file" accept=".mp4,video/mp4" disabled={upload.isPending}
          onChange={(event) => selectFile(event.target.files?.[0])}
          className="block w-full text-sm" aria-label="Select MP4 video" />
        {file && <p className="text-sm break-all">{file.name} · {(file.size / 1_000_000).toLocaleString("pt-PT", { maximumFractionDigits: 2 })} MB</p>}
        {fileError && <p role="alert" className="text-sm text-destructive">{fileError}</p>}
        <DialogFooter>
          <Button onClick={submit} disabled={!file || upload.isPending} className="inline-flex items-center gap-1">
            {upload.isPending ? "Uploading..." : "Upload"}
            {upload.isPending && <LoaderCircle className="size-[1em] animate-spin" />}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
