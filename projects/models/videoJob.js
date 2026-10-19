const mongoose = require("mongoose");

const videoJobSchema = new mongoose.Schema(
  {
    jobId: { type: String, required: true, unique: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    callerId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ["anonymous", "free", "premium"], required: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    videoId: { type: mongoose.Schema.Types.ObjectId, required: true },
    newVideoId: { type: mongoose.Schema.Types.ObjectId, required: true },
    newVideoName: { type: String, required: true },
    startTime: { type: Number, required: true },
    endTime: { type: Number, required: true },
    fastTrim: { type: Boolean, default: false },
    status: {
      type: String,
      enum: ["queued", "processing", "completed", "failed", "cancelled"],
      default: "queued",
      index: true,
    },
    progress: { type: Number, default: 0 },
    error: { type: String },
    startedAt: { type: Date },
    completedAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model("VideoJob", videoJobSchema);
