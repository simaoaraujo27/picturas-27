import assert from "node:assert/strict";
import { test } from "node:test";
import {
  parseVideoTime,
  validateVideoSpeedIntervals,
} from "../lib/video-speed.ts";

const draft = (startTime = "1", endTime = "3", speed = 2, id = "first") => ({
  id,
  startTime,
  endTime,
  speed,
});

for (const speed of [0.5, 1, 2]) {
  test(`accepts speed ${speed} and produces numeric worker intervals`, () => {
    const result = validateVideoSpeedIntervals([draft("1", "3.5", speed)], 10);
    assert.equal(result.isValid, true);
    assert.deepEqual(result.intervals, [{ startTime: 1, endTime: 3.5, speed }]);
  });
}

for (const [name, row, code] of [
  ["speed 0.25", draft("1", "3", 0.25), "INVALID_SPEED"],
  ["speed 4", draft("1", "3", 4), "INVALID_SPEED"],
  ["string speed", draft("1", "3", "2"), "INVALID_SPEED"],
  ["boolean speed", draft("1", "3", true), "INVALID_SPEED"],
  ["equal bounds", draft("2", "2"), "INVALID_TIME_BOUNDS"],
  ["reversed bounds", draft("3", "2"), "INVALID_TIME_BOUNDS"],
  ["negative start", draft("-1", "3"), "INVALID_TIME_BOUNDS"],
  ["outside duration", draft("1", "10.001"), "INTERVAL_OUT_OF_BOUNDS"],
  ["empty start", draft("", "3"), "INVALID_TIME"],
  ["empty end", draft("1", ""), "INVALID_TIME"],
  ["blank start", draft(" ", "3"), "INVALID_TIME"],
  ["NaN", draft("NaN", "3"), "INVALID_TIME"],
  ["infinity", draft("1", "Infinity"), "INVALID_TIME"],
  ["overflow", draft("1", "1e999"), "INVALID_TIME"],
]) {
  test(`rejects ${name} and identifies the interval`, () => {
    const result = validateVideoSpeedIntervals([row], 10);
    assert.equal(result.isValid, false);
    assert.deepEqual(result.issues, [{ code, intervalIds: ["first"] }]);
  });
}

test("rejects an empty list", () => {
  assert.deepEqual(validateVideoSpeedIntervals([], 10).issues, [
    { code: "EMPTY_INTERVALS", intervalIds: [] },
  ]);
});

for (const duration of [null, 0, -1, NaN, Infinity]) {
  test(`requires real finite duration: ${duration}`, () => {
    const result = validateVideoSpeedIntervals([draft()], duration);
    assert.equal(result.isValid, false);
    assert.equal(result.issues[0].code, "VIDEO_DURATION_UNAVAILABLE");
  });
}

test("identifies both conflicting intervals even when input is unsorted", () => {
  const result = validateVideoSpeedIntervals(
    [draft("4", "7", 0.5, "second"), draft("2", "5", 2)],
    10,
  );
  assert.equal(result.isValid, false);
  assert.deepEqual(result.issues, [
    { code: "OVERLAPPING_INTERVALS", intervalIds: ["first", "second"] },
  ]);
});

test("identifies all conflicts with a containing interval", () => {
  const result = validateVideoSpeedIntervals(
    [
      draft("0", "10", 1, "outer"),
      draft("1", "2", 2, "inner1"),
      draft("3", "4", 0.5, "inner2"),
    ],
    10,
  );
  assert.deepEqual(
    result.issues.map((issue) => issue.intervalIds),
    [
      ["outer", "inner1"],
      ["outer", "inner2"],
    ],
  );
});

test("accepts adjacent and multiple intervals without changing the drafts", () => {
  const rows = [
    draft("4", "6", 0.5, "second"),
    draft("2", "4", 2),
    draft("8", "9", 1, "third"),
  ];
  const original = structuredClone(rows);
  const result = validateVideoSpeedIntervals(rows, 10);
  assert.equal(result.isValid, true);
  assert.deepEqual(result.intervals, [
    { startTime: 2, endTime: 4, speed: 2 },
    { startTime: 4, endTime: 6, speed: 0.5 },
    { startTime: 8, endTime: 9, speed: 1 },
  ]);
  assert.deepEqual(rows, original);
});

test("accepts sub-second intervals and the exact duration without rounding", () => {
  const duration = 3.456789;
  assert.equal(
    validateVideoSpeedIntervals([draft("3.45", String(duration))], duration)
      .isValid,
    true,
  );
  assert.equal(
    validateVideoSpeedIntervals([draft("3.45", "3.5")], duration).isValid,
    false,
  );
  assert.equal(
    validateVideoSpeedIntervals([draft("0", "0.001")], 0.001).isValid,
    true,
  );
});

test("does not interpret an empty field as zero", () => {
  assert.equal(parseVideoTime(""), null);
  assert.equal(parseVideoTime("  "), null);
  assert.equal(parseVideoTime("0"), 0);
  assert.equal(parseVideoTime("0.5"), 0.5);
});
