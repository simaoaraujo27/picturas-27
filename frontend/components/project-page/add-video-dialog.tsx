"use client";

import { useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { AlertCircle, Film, LoaderCircle, Plus, Upload, X } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { useAddProjectVideo } from "@/lib/mutations/projects";
import { useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useToast } from "@/hooks/use-toast";
import { getErrorMessage } from "@/lib/error-messages";

export function AddVideoDialog() {
  const [open, setOpen] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [fileError, setFileError] = useState("");
  const [isDragging, setIsDragging] = useState(false);
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
    if (
      !selected.name.toLowerCase().endsWith(".mp4") ||
      (selected.type && selected.type !== "video/mp4")
    ) {
      setFileError("Please select a valid MP4 video file.");
      if (input.current) input.current.value = "";
      return;
    }
    if (selected.size === 0) {
      setFileError("The selected file is empty.");
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

  function handleDragOver(e: React.DragEvent) {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  }

  function handleDragLeave(e: React.DragEvent) {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    const droppedFile = e.dataTransfer.files?.[0];
    if (droppedFile) selectFile(droppedFile);
  }

  async function submit() {
    if (!file || submitting.current || upload.isPending) return;
    submitting.current = true;
    try {
      await upload.mutateAsync({ file, projectVersion: version });
      toast({ title: "Video added to project successfully." });
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
        <Button className="inline-flex items-center gap-1.5" variant="outline">
          <Plus className="size-4" /> Add Video
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[460px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Film className="size-5 text-primary" />
            Add Video
          </DialogTitle>
          <DialogDescription>
            Select or drag an MP4 video to add to this project.
          </DialogDescription>
        </DialogHeader>

        {/* Hidden native input */}
        <input
          ref={input}
          type="file"
          accept=".mp4,video/mp4"
          disabled={upload.isPending}
          onChange={(event) => selectFile(event.target.files?.[0])}
          className="hidden"
          aria-label="Select MP4 video"
        />

        {/* Drag and Drop / Selection Area */}
        {!file ? (
          <div
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            onClick={() => input.current?.click()}
            className={`group relative flex flex-col items-center justify-center rounded-xl border-2 border-dashed p-6 text-center cursor-pointer transition-all ${
              isDragging
                ? "border-primary bg-primary/10 scale-[1.01]"
                : "border-muted-foreground/25 hover:border-primary/50 hover:bg-muted/40"
            }`}
          >
            <div className="flex size-12 items-center justify-center rounded-full bg-primary/10 text-primary mb-3 group-hover:scale-110 transition-transform">
              <Upload className="size-6" />
            </div>
            <p className="text-sm font-semibold text-foreground">
              Drag and drop your video here
            </p>
            <p className="text-xs text-muted-foreground mt-0.5">
              or click the button below to browse files
            </p>

            <Button
              type="button"
              variant="outline"
              size="sm"
              className="mt-4 inline-flex items-center gap-2 shadow-xs"
              onClick={(e) => {
                e.stopPropagation();
                input.current?.click();
              }}
              disabled={upload.isPending}
            >
              <Upload className="size-3.5" />
              Choose Video File
            </Button>

            <span className="text-[11px] text-muted-foreground/75 mt-3">
              Supported format: MP4 (H.264 / AAC)
            </span>
          </div>
        ) : (
          <div className="rounded-xl border border-border/80 bg-muted/30 p-4">
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-center gap-3 min-w-0">
                <div className="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/15 text-primary">
                  <Film className="size-5" />
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-semibold truncate text-foreground">
                    {file.name}
                  </p>
                  <div className="flex items-center gap-2 mt-0.5">
                    <Badge variant="secondary" className="text-[10px] px-1.5 py-0">
                      MP4
                    </Badge>
                    <span className="text-xs text-muted-foreground">
                      {(file.size / (1024 * 1024)).toFixed(2)} MB
                    </span>
                  </div>
                </div>
              </div>
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="size-7 text-muted-foreground hover:text-foreground"
                onClick={resetSelection}
                disabled={upload.isPending}
                title="Remove selected file"
              >
                <X className="size-4" />
              </Button>
            </div>

            <div className="mt-3 pt-3 border-t border-border/50 flex justify-end">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => input.current?.click()}
                disabled={upload.isPending}
                className="text-xs h-7"
              >
                Choose another file
              </Button>
            </div>
          </div>
        )}

        {fileError && (
          <Alert variant="destructive" className="py-2">
            <AlertCircle className="size-4" />
            <AlertDescription className="text-xs">{fileError}</AlertDescription>
          </Alert>
        )}

        <DialogFooter className="gap-2 sm:gap-0">
          <Button
            type="button"
            variant="ghost"
            onClick={() => setOpen(false)}
            disabled={upload.isPending}
          >
            Cancel
          </Button>
          <Button
            onClick={submit}
            disabled={!file || upload.isPending}
            className="inline-flex items-center gap-1.5"
          >
            {upload.isPending ? "Uploading..." : "Upload Video"}
            {upload.isPending && (
              <LoaderCircle className="size-4 animate-spin" />
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
