import { useSearchParams } from "next/navigation";
import BrightnessTool from "./brightness-tool";
import ContrastTool from "./contrast-tool";
import CropTool from "./crop-tool";
import ResizeTool from "./resize-tool";
import RotateTool from "./rotate-tool";
import SaturationTool from "./saturation-tool";
import BorderTool from "./border-tool";
import BinarizationTool from "./binarization-tool";
import WatermarkTool from "./watermark-tool";
import CropAITool from "./ai-crop-tool";
import BgRemovalAITool from "./ai-bg-removal";
import ObjectAITool from "./object-ai-tool";
import PeopleAITool from "./people-ai-tool";
import TextAITool from "./text-ai-tool";
import UpgradeAITool from "./upgrade-ai-tool";
import { useClearProjectTools } from "@/lib/mutations/projects";
import { useSession } from "@/providers/session-provider";
import { useProjectInfo } from "@/providers/project-provider";
import { Button } from "../ui/button";
import { AppliedToolsList } from "./applied-tools-list";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../ui/dialog";
import { Tooltip, TooltipContent, TooltipTrigger } from "../ui/tooltip";
import { Eraser, Gauge, Redo2, Scissors, Trash2, Undo2 } from "lucide-react";
import { useState } from "react";
import ExpandAITool from "./expand-ai-tool";

interface ToolbarProps {
  activeMediaTab?: "images" | "videos";
  onTrimVideo?: () => void;
  onRemoveSegment?: () => void;
  onChangeVideoSpeed?: () => void;
  canEdit?: boolean;
  canUndo?: boolean;
  canRedo?: boolean;
  onUndo?: () => void;
  onRedo?: () => void;
  videoSelected?: boolean;
}

export function Toolbar({
  activeMediaTab = "images",
  onTrimVideo,
  onRemoveSegment,
  onChangeVideoSpeed,
  canEdit = true,
  canUndo = false,
  canRedo = false,
  onUndo,
  onRedo,
  videoSelected = false,
}: ToolbarProps = {}) {
  const searchParams = useSearchParams();
  const view = searchParams.get("view") ?? "grid";
  const mode = searchParams.get("mode") ?? "edit";

  // desativar ferramentas se estiver em grid OU em results OU com video selecionado
  const disabled = view === "grid" || mode === "results" || videoSelected;

  const project = useProjectInfo();
  const session = useSession();

  const [open, setOpen] = useState<boolean>(false);
  const ownerParam = searchParams.get("owner") ?? session.user._id;
  const shareId = searchParams.get("share") ?? undefined;

  const clearTools = useClearProjectTools(
    session.user._id,
    project._id,
    session.token,
    ownerParam,
    shareId,
  );

  if (activeMediaTab === "videos") {
    return (
      <div className="flex h-full w-24 flex-col justify-between items-stretch border-r bg-background p-2">
        <div className="flex flex-col gap-2 items-center">
          <span className="text-sm text-gray-500">Tools</span>

          {/* Trim Video Tool */}
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="outline"
                className="size-8 relative"
                disabled={!canEdit || !onTrimVideo}
                onClick={onTrimVideo}
                title="Trim Video"
              >
                <Scissors className="size-4" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right">
              <p>Trim Video</p>
            </TooltipContent>
          </Tooltip>

          {/* Remove Segment Tool */}
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="outline"
                className="size-8 relative"
                disabled={!canEdit || !onRemoveSegment}
                onClick={onRemoveSegment}
                title="Remove Segment"
              >
                <Trash2 className="size-4" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right">
              <p>Remove Segment</p>
            </TooltipContent>
          </Tooltip>

          {canEdit && (
            <Tooltip>
              <TooltipTrigger asChild>
                <Button variant="outline" className="size-8 relative" disabled={!onChangeVideoSpeed}
                  onClick={onChangeVideoSpeed} aria-label="Change Speed" title="Change Speed">
                  <Gauge className="size-4" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="right"><p>Change Speed</p></TooltipContent>
            </Tooltip>
          )}

          {/* History Undo / Redo Tools */}
          {(onUndo || onRedo) && (
            <div className="flex flex-col gap-2 pt-2 border-t w-full items-center">
              {onUndo && (
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button
                      variant="outline"
                      className="size-8 relative"
                      disabled={!canUndo}
                      onClick={onUndo}
                      title="Undo"
                    >
                      <Undo2 className="size-4" />
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent side="right">
                    <p>Undo</p>
                  </TooltipContent>
                </Tooltip>
              )}

              {onRedo && (
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button
                      variant="outline"
                      className="size-8 relative"
                      disabled={!canRedo}
                      onClick={onRedo}
                      title="Redo"
                    >
                      <Redo2 className="size-4" />
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent side="right">
                    <p>Redo</p>
                  </TooltipContent>
                </Tooltip>
              )}
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full w-24 flex-col justify-between items-stretch border-r bg-background p-2">
      <div className="flex flex-col gap-2 items-center">
        <span className="text-sm text-gray-500">Tools</span>
        <BrightnessTool disabled={disabled} />
        <ContrastTool disabled={disabled} />
        <SaturationTool disabled={disabled} />
        <BinarizationTool disabled={disabled} />
        <RotateTool disabled={disabled} />
        <CropTool disabled={disabled} />
        <ResizeTool disabled={disabled} />
        <BorderTool disabled={disabled} />
        <WatermarkTool disabled={disabled} />
        <BgRemovalAITool disabled={disabled} />
        <CropAITool disabled={disabled} />
        <ObjectAITool disabled={disabled} />
        <PeopleAITool disabled={disabled} />
        <TextAITool disabled={disabled} />
        <ExpandAITool disabled={disabled} />
        <UpgradeAITool disabled={disabled} />
        <AppliedToolsList />
      </div>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogTrigger asChild>
          <Button
            variant="outline"
            className="text-red-400 size-8"
            disabled={project.tools.length === 0}
          >
            <Eraser />
          </Button>
        </DialogTrigger>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Clear Tools?</DialogTitle>
            <DialogDescription>
              This will remove <b>all</b> edits from the current project.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="destructive"
              onClick={() => {
                clearTools.mutate({
                  toolIds: project.tools.map((t) => t._id),
                  projectVersion: project.version,
                });
                setOpen(false);
              }}
            >
              Clear
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
