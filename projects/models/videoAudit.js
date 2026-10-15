const mongoose = require("mongoose");

const videoAuditSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    jobId: { type: String, required: true, index: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    videoId: { type: mongoose.Schema.Types.ObjectId, required: true },
    newVideoId: { type: mongoose.Schema.Types.ObjectId },
    startTime: { type: Number, required: true },
    endTime: { type: Number, required: true },
    fastTrim: { type: Boolean, default: false },
    executionTimeMs: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ["success", "failed", "cancelled"],
      required: true,
      index: true,
    },
    error: { type: String },
    createdAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model("VideoAudit", videoAuditSchema);
