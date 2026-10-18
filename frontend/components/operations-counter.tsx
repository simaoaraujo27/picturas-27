"use client";

import { useEffect, useState } from "react";
import { useSession } from "@/providers/session-provider";
import { Zap } from "lucide-react";

export default function OperationsCounter() {
  const session = useSession();
  const user = session.user;
  const [, setTick] = useState(0);

  // Escutar eventos de atualização de sessão para re-render imediato
  useEffect(() => {
    const handleUpdate = () => setTick((t) => t + 1);
    window.addEventListener("session-updated", handleUpdate);
    return () => window.removeEventListener("session-updated", handleUpdate);
  }, []);

  // Apenas relevante para utilizadores free e anonymous
  if (user.type === "premium") return null;

  const remaining = user.remaining_operations ?? 0;
  const total = 5;
  const percent = Math.min(100, Math.max(0, (remaining / total) * 100));

  const isLow = remaining <= 1;
  const isZero = remaining === 0;

  return (
    <div className="rounded-lg border border-sidebar-border/80 bg-sidebar-accent/40 p-2.5 shadow-xs transition-colors hover:bg-sidebar-accent/60">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-1.5">
          <Zap
            className={`size-3.5 ${
              isZero
                ? "text-muted-foreground"
                : isLow
                ? "text-amber-500 fill-amber-500/20"
                : "text-emerald-500 fill-emerald-500/20"
            }`}
          />
          <span className="text-xs font-medium text-foreground">
            Daily Operations
          </span>
        </div>
        <span
          className={`inline-flex items-center rounded-md px-1.5 py-0.5 text-[11px] font-semibold tabular-nums border ${
            isZero
              ? "bg-destructive/15 text-destructive border-destructive/30"
              : isLow
              ? "bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30"
              : "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30"
          }`}
        >
          {remaining} / {total}
        </span>
      </div>

      <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-sidebar-border/50">
        <div
          className={`h-full transition-all duration-300 rounded-full ${
            isZero
              ? "bg-destructive"
              : isLow
              ? "bg-amber-500"
              : "bg-emerald-500"
          }`}
          style={{ width: `${percent}%` }}
        />
      </div>

      <div className="mt-1.5 flex items-center justify-between text-[10px] text-muted-foreground">
        <span>{isZero ? "Limit reached today" : `${remaining} remaining`}</span>
        <span>Resets at 00:00</span>
      </div>
    </div>
  );
}
