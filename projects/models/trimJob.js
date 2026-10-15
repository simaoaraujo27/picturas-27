const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  ownerId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
  projectId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
  sourceId: { type: mongoose.Schema.Types.ObjectId, required: true },
  resultId: { type: mongoose.Schema.Types.ObjectId, required: true },
  requestedBy: { type: mongoose.Schema.Types.ObjectId, required: true },
  name: { type: String, required: true },
  start: { type: Number, required: true },
  end: { type: Number, required: true },
  mode: { type: String, enum: ['precise', 'fast'], default: 'precise' },
  state: { type: String, enum: ['QUEUED','PROCESSING','COMPLETED','FAILED','CANCELLED'], default: 'QUEUED', index: true },
  progress: { type: Number, default: 0 },
  attempt: { type: Number, default: 0 },
  error: String,
  quotaReserved: { type: Boolean, default: false },
  quotaSettled: { type: Boolean, default: false },
  result: mongoose.Schema.Types.Mixed,
  leaseUntil: Date,
  lastPublishedAt: Date,
  startedAt: Date,
  finishedAt: Date,
}, { timestamps: true });
schema.index({ projectId: 1, createdAt: -1 });
module.exports = mongoose.model('TrimJob', schema);
