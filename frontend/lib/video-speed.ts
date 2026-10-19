export const VIDEO_SPEEDS = [0.5, 1, 2] as const;
export type VideoSpeed = (typeof VIDEO_SPEEDS)[number];

export interface VideoSpeedInterval {
  startTime: number;
  endTime: number;
  speed: VideoSpeed;
}

export interface VideoSpeedDraft {
  id: string;
  startTime: string;
  endTime: string;
  speed: VideoSpeed;
}

export interface VideoSpeedIssue {
  code:
    | "EMPTY_INTERVALS"
    | "VIDEO_DURATION_UNAVAILABLE"
    | "INVALID_TIME"
    | "INVALID_TIME_BOUNDS"
    | "INTERVAL_OUT_OF_BOUNDS"
    | "INVALID_SPEED"
    | "OVERLAPPING_INTERVALS";
  intervalIds: string[];
}

export function parseVideoTime(value: string): number | null {
  if (typeof value !== "string" || !value.trim()) return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

export function validateVideoSpeedIntervals(
  drafts: readonly VideoSpeedDraft[],
  duration: number | null,
) {
  const issues: VideoSpeedIssue[] = [];
  const normalized: (VideoSpeedInterval & { id: string })[] = [];
  const hasDuration =
    duration !== null && Number.isFinite(duration) && duration > 0;
  if (!hasDuration)
    issues.push({ code: "VIDEO_DURATION_UNAVAILABLE", intervalIds: [] });
  if (!drafts.length) issues.push({ code: "EMPTY_INTERVALS", intervalIds: [] });

  for (const draft of drafts) {
    const startTime = parseVideoTime(draft.startTime);
    const endTime = parseVideoTime(draft.endTime);
    const issueCount = issues.length;
    const intervalIds = [draft.id];
    if (startTime === null || endTime === null) {
      issues.push({ code: "INVALID_TIME", intervalIds });
    } else if (startTime < 0 || endTime <= startTime) {
      issues.push({ code: "INVALID_TIME_BOUNDS", intervalIds });
    } else if (hasDuration && endTime > duration!) {
      issues.push({ code: "INTERVAL_OUT_OF_BOUNDS", intervalIds });
    }
    if (!VIDEO_SPEEDS.includes(draft.speed))
      issues.push({ code: "INVALID_SPEED", intervalIds });
    if (
      issues.length === issueCount &&
      startTime !== null &&
      endTime !== null
    ) {
      normalized.push({ id: draft.id, startTime, endTime, speed: draft.speed });
    }
  }

  normalized.sort((a, b) => a.startTime - b.startTime);
  for (let i = 0; i < normalized.length; i++) {
    for (
      let j = i + 1;
      j < normalized.length && normalized[j].startTime < normalized[i].endTime;
      j++
    ) {
      issues.push({
        code: "OVERLAPPING_INTERVALS",
        intervalIds: [normalized[i].id, normalized[j].id],
      });
    }
  }
  return {
    isValid: issues.length === 0,
    issues,
    intervals: normalized.map(({ startTime, endTime, speed }) => ({
      startTime,
      endTime,
      speed,
    })),
  };
}
