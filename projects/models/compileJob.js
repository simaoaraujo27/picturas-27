const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;

// Tarefa de compilação de vídeos (mesmo ciclo de vida do trimJob).
const schema = new mongoose.Schema({
  ownerId: { type: ObjectId, required: true, index: true },
  projectId: { type: ObjectId, required: true, index: true },
  sourceIds: { type: [ObjectId], required: true },   // a ordem do array é a ordem da compilação
  resultId: { type: ObjectId, required: true },
  requestedBy: { type: ObjectId, required: true },
  name: { type: String, required: true },
  state: { type: String, enum: ['QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED'],
    default: 'QUEUED', index: true },
  progress: { type: Number, default: 0 },
  attempt: { type: Number, default: 0 },
  error: String,
  result: mongoose.Schema.Types.Mixed,
  quotaReserved: { type: Boolean, default: false },
  quotaSettled: { type: Boolean, default: false },
  leaseUntil: Date,
  lastPublishedAt: Date,
  startedAt: Date,
  finishedAt: Date,
}, { timestamps: true });

module.exports = mongoose.models.CompileJob || mongoose.model('CompileJob', schema);
