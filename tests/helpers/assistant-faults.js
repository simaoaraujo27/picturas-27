const fs = require('node:fs');
const path = require('node:path');
const { dockerNode, fixture } = require('./live');

function failedPreview(failure) {
  const code = `
    const data=Buffer.from(process.argv[1],'base64'),failure=process.argv[2];
    const storage=require('./utils/imageStorage');let uploaded=0,deleted=0;
    storage.get_image_internal_url=async()=>({data:{url:'fixture'}});
    storage.post_image=async()=>{if(failure==='upload')throw Error('storage unavailable');uploaded++;return {data:{data:{imageKey:'preview/test.png'}}}};
    storage.get_image_public_url=async()=>{throw Error('signing unavailable')};
    storage.delete_image=async()=>{deleted++};
    require('axios').get=async()=>({data});
    require('./controllers/project').getOne=async()=>({imgs:[{_id:'image',og_img_key:'source.png'}],tools:[]});
    const {router}=require('./routes/projects');
    const route=router.stack.find(x=>x.route?.path==='/:user/:project/assistant/suggest').route;
    const handler=route.stack.at(-1).handle;
    let status=200;handler({params:{user:'owner',project:'project'},body:{message:'mais claro',currentTools:[],imgId:'image'}},{status(n){status=n;return this},jsonp(body){console.log(JSON.stringify({status,body,uploaded,deleted}))}}).catch(e=>{console.error(e);process.exit(1)});
  `;
  const output = dockerNode('projects', code, [fs.readFileSync(fixture('pattern.png')).toString('base64'), failure]);
  return JSON.parse(output.trim().split('\n').at(-1));
}

module.exports = { failedPreview };
