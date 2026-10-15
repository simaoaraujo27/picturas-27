const mongoose = require('mongoose');
const entry = new mongoose.Schema({ videoId: { type: mongoose.Schema.Types.ObjectId, required: true },
  size: { type: Number, required: true }, state: { type: String, enum: ['reserved', 'committed', 'released'], required: true } },
{ _id: false });
const schema = new mongoose.Schema({ ownerId: { type: mongoose.Schema.Types.ObjectId, required: true, unique: true },
  used: { type: Number, required: true, default: 0 }, entries: { type: [entry], default: [] } });
module.exports = mongoose.model('VideoStorageAccount', schema);
