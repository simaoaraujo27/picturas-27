"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import {
  useAssistantSuggest,
  useReorderProjectTools,
} from "@/lib/mutations/projects";
import type { ProjectToolResponse } from "@/lib/projects";
import { getErrorMessage } from "@/lib/error-messages";
import { AiSuggestionEditor } from "@/components/assistant/ai-suggestion-editor";

export type Suggestion = {
  name: string;
  description: string;
  tools: ProjectToolResponse[];
  previewUrl?: string | null;

};

export function AiAssistantDialog(props: {
  uid: string;
  pid: string;
  token: string;
  ownerId?: string;
  shareId?: string;
  projectVersion: number;
  currentTools: ProjectToolResponse[];
  currentImgId?: string
}) {
  const { toast } = useToast();
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState("");

  const suggest = useAssistantSuggest(
    props.uid,
    props.pid,
    props.token,
    props.ownerId,
    props.shareId,
  );

  const reorder = useReorderProjectTools(
    props.uid,
    props.pid,
    props.token,
    props.ownerId,
    props.shareId,
  );

  const [suggestions, setSuggestions] = useState<Suggestion[]>([]);
  const [editing, setEditing] = useState<Suggestion | null>(null);

  const onSend = () => {
    const m = message.trim();
    if (m.length < 2) return;

    suggest.mutate(
      {
        message: m,
        currentTools: props.currentTools,
        projectVersion: props.projectVersion,
        imgId: props.currentImgId, 
      },
      {
        onSuccess: (resp) => {
          setSuggestions(
            (resp.suggestions ?? []).map((s) => ({
              name: s.name,
              description: s.description,
              previewUrl: s.previewUrl ?? null,
              tools: (s.tools ?? []).map((t, i) => ({
                _id: `tmp-${i}`,
                position: i,
                procedure: t.procedure,
                params: structuredClone(t.params ?? {}),
              })),
            })),
          );
        },
        onError: (err) => {
          const { title, description } = getErrorMessage("assistant-suggest", err);
          toast({ title, description, variant: "destructive" });
        },
      },
    );
  };

  const onApplySuggestion = (s: Suggestion) => {
    const toolsNoId = s.tools.map(({ _id, ...rest }, i) => ({
      ...rest,
      position: i,
      params: rest.params ?? {},
    }));

    reorder.mutate(
      { tools: toolsNoId as any, projectVersion: props.projectVersion },
      {
        onSuccess: () => {
          toast({
            title: "Suggestion applied",
            description: "The tool sequence has been updated.",
          });
          setEditing(null);
          setOpen(false);
        },
        onError: (err) => {
          const { title, description } = getErrorMessage("project-reorder", err);
          toast({ title, description, variant: "destructive" });
        },
      },
    );
  };

  return (
    <Dialog open={open} onOpenChange={(v) => {
      setOpen(v);
      if (!v) setEditing(null);
    }}>
      <DialogTrigger asChild>
        <Button type="button" variant="outline">AI Assistant</Button>
      </DialogTrigger>

      <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>AI Assistant</DialogTitle>
        </DialogHeader>

        <div className="flex gap-2">
          <Input
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder='e.g., "vintage look", "increase contrast"'
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  onSend();
                }
              }}
            disabled={suggest.isPending}
          />
        <Button type="button" onClick={onSend} disabled={suggest.isPending}>
          {suggest.isPending ? "Suggesting..." : "Send"}
        </Button>
        </div>

        {/* Editor (when editing) */}
        {editing && (
          <Card className="p-3 mt-2">
            <div className="flex items-center justify-between gap-2 mb-3">
              <div className="min-w-0">
                <div className="font-semibold truncate">{editing.name}</div>
                <div className="text-sm text-muted-foreground">
                  {editing.description}
                </div>
              </div>

            <Button type="button" variant="outline" onClick={() => setEditing(null)}>
              Back
            </Button>
            </div>

            <AiSuggestionEditor
              suggestion={editing}
              onChange={setEditing}
              onApply={onApplySuggestion}
            />
          </Card>
        )}

        {/* Suggestions list */}
        {!editing && (
          <div className="flex flex-col gap-3 mt-2">
            {suggestions.map((s, idx) => (
              <Card key={idx} className="p-3 flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <div className="font-semibold truncate">{s.name}</div>
                  <div className="text-sm text-muted-foreground">{s.description}</div>

                {s.previewUrl && (
                    <div className="mt-2">
                      <img
                        src={s.previewUrl}
                        alt={`Preview ${s.name}`}
                        className="w-full max-h-56 object-contain rounded-md border"
                      />
                    </div>
                  )}
                  <div className="text-xs text-muted-foreground mt-2">
                    Tools: {s.tools.map((t) => t.procedure).join(" → ")}
                  </div>
                </div>

                <div className="flex flex-col gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setEditing(structuredClone(s))}
                    disabled={reorder.isPending}
                  >
                    Edit
                  </Button>

              <Button type="button" onClick={() => onApplySuggestion(s)}>
                Apply
              </Button>
                </div>
              </Card>
            ))}

            {suggestions.length === 0 && (
              <div className="text-sm text-muted-foreground">
                Describe the look you want (e.g. "more color", "black and white", "vintage") to receive suggestions.
              </div>
            )}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
