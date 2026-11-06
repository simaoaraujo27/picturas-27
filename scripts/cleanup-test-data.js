// Remove only account IDs recorded when this test suite created them.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { dockerNode } = require('../tests/helpers/live');
const registry = process.argv[2];
if (!registry || !fs.existsSync(registry)) process.exit(0);
const records = fs.readFileSync(registry, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse);
const ids = [...new Set(records.map(x => x.id))];
for (const id of ids) assert.match(id, /^[a-f0-9]{24}$/);
if (!ids.length) process.exit(0);

const remove = `const m=require('mongoose');(async()=>{await m.connect(process.argv[1]);const strings=JSON.parse(process.argv[2]);const ids=[...strings,...strings.map(x=>new m.Types.ObjectId(x))];const subs=await m.connection.db.collection('subscriptions').find({user_id:{$in:ids}}).toArray();if(subs.length)await m.connection.db.collection('cards').deleteMany({subscriptionId:{$in:subs.map(x=>x._id)}});for(const c of await m.connection.db.listCollections().toArray()){const filter=c.name==='users'?{_id:{$in:ids}}:{$or:['user_id','owner_id','userId','ownerId'].map(k=>({[k]:{$in:ids}}))};await m.connection.db.collection(c.name).deleteMany(filter)}await m.disconnect()})().catch(e=>{console.error(e.message);process.exit(1)})`;
for (const [service, url] of [['projects', 'mongodb://projects_mongoDB:27018/project'], ['subscriptions', 'mongodb://subscriptions_mongoDB:27017/subscription'], ['users', 'mongodb://users_mongoDB:27019/user']]) {
  dockerNode(service, remove, [url, JSON.stringify(ids)]);
}
dockerNode('img_storage', `const s=require('./services/s3Client');const {BUCKET}=require('./services/storage');(async()=>{for(const id of JSON.parse(process.argv[1])){let token;do{const r=await s.listObjectsV2({Bucket:BUCKET,Prefix:'users/'+id+'/',ContinuationToken:token}).promise();if(r.Contents?.length)await s.deleteObjects({Bucket:BUCKET,Delete:{Objects:r.Contents.map(x=>({Key:x.Key}))}}).promise();token=r.IsTruncated?r.NextContinuationToken:undefined}while(token)}})().catch(e=>{console.error(e.message);process.exit(1)})`, [JSON.stringify(ids)]);
dockerNode('projects', `const fs=require('fs');for(const id of JSON.parse(process.argv[1]))fs.rmSync('./images/users/'+id,{recursive:true,force:true})`, [JSON.stringify(ids)]);
fs.renameSync(registry, registry + '.cleaned');
console.log(`Cleaned ${ids.length} test account IDs and their related data`);
