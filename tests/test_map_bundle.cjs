const fs=require('node:fs');
const assert=require('node:assert/strict');
const {test}=require('node:test');
const code=fs.readFileSync(require('node:path').join(__dirname,'../js/map-exporter.js'),'utf8');
const modulePromise=import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
const nav={zones:[{id:'a',name:'Livraison café',x:1,y:-2,radius:.4}],base:{x:0,y:0,yaw_deg:90}};
test('JSON export/import preserves exact occupancy, scale, UTF-8 zones and base',async()=>{
  const m=await modulePromise;
  const original=m.MapExporter.bundle({resolution:1,radius:1,grid:new Int8Array([-1,0,100,0])},nav);
  assert.deepEqual(m.validateBundle(JSON.parse(JSON.stringify(original))),{resolution:1,radius:1,width:2,height:2,
    origin_x:-1,origin_y:-1,origin_yaw:0,frame_id:'map',grid:[-1,0,100,0],navigation_config:nav});
});
test('rectangular map bundle preserves dimensions and rotated world origin',async()=>{
  const m=await modulePromise;
  const value={format:'fabtino-map',version:1,resolution:.5,radius:1.25,width:5,height:3,
    origin_x:4,origin_y:-2,origin_yaw:Math.PI/2,frame_id:'map',grid:Array(15).fill(0),navigation_config:nav};
  const loaded=m.validateBundle(value);
  for(const key of ['resolution','radius','width','height','origin_x','origin_y','origin_yaw','frame_id','grid','navigation_config'])
    assert.deepEqual(loaded[key],value[key]);
});
test('PNG alignment keeps a rectangular unrotated map cell-for-cell at native resolution',async()=>{
  const m=await modulePromise;
  const aligned=m.axisAlignedGrid({width:3,height:2,resolution:.1,radius:.2,originX:1,originY:2,originYaw:0,frameId:'map',grid:[100,0,-1,0,100,0]});
  assert.equal(aligned.width,3);assert.equal(aligned.height,2);assert.equal(aligned.origin_x,1);assert.equal(aligned.origin_y,2);assert.equal(aligned.origin_yaw,0);
  assert.deepEqual(Array.from(aligned.grid),[100,0,-1,0,100,0]);
});
test('PNG orientation is estimated from long map walls and the output bounds grow at native resolution',async()=>{
  const m=await modulePromise;
  const width=160,height=120,grid=new Int8Array(width*height);grid.fill(-1);
  const put=(x,y)=>{const px=Math.round(x),py=Math.round(y);if(px>=0&&py>=0&&px<width&&py<height)grid[py*width+px]=100;};
  const c=Math.cos(Math.PI/6),s=Math.sin(Math.PI/6),cx=width/2,cy=height/2;
  for(const side of [-25,25]) for(let u=-55;u<=55;u++) put(cx+u*c-side*s,cy+u*s+side*c);
  for(const side of [-55,55]) for(let v=-25;v<=25;v++) put(cx+side*c-v*s,cy+side*s+v*c);
  const aligned=m.axisAlignedGrid({width,height,resolution:.05,radius:4,originX:-4,originY:-3,originYaw:0,grid});
  assert.ok(Math.abs(aligned.orientation.detected_angle-Math.PI/6)<Math.PI/180);
  assert.ok(Math.abs(aligned.orientation.correction+Math.PI/6)<Math.PI/180);
  assert.ok(aligned.width>120);assert.ok(aligned.height>120);assert.ok(Math.abs(aligned.resolution-.05)<1e-12);
  assert.ok(Math.abs(aligned.origin_yaw-Math.PI/6)<Math.PI/180);
  const [a,b,tx,d,e,ty]=aligned.image_to_source_grid,px=80,py=75;
  const sourceX=-4+(a*px+b*py+tx)*.05,sourceY=-3+(d*px+e*py+ty)*.05;
  const gy=aligned.height-1-py,c=Math.cos(aligned.origin_yaw),s=Math.sin(aligned.origin_yaw);
  const outputX=aligned.origin_x+c*(px+.5)*.05-s*(gy+.5)*.05;
  const outputY=aligned.origin_y+s*(px+.5)*.05+c*(gy+.5)*.05;
  assert.ok(Math.hypot(sourceX-outputX,sourceY-outputY)<1e-8);
});
test('PNG export reports insufficient structure and retains source ROS orientation when no walls can be estimated',async()=>{
  const m=await modulePromise;
  const aligned=m.axisAlignedGrid({width:3,height:2,resolution:.1,radius:.2,originX:0,originY:0,originYaw:Math.PI/6,grid:Array(6).fill(0)});
  assert.equal(aligned.width,3);assert.equal(aligned.height,2);assert.ok(Math.abs(aligned.resolution-.1)<1e-12);
  assert.equal(aligned.orientation.status,'insufficient_structure');assert.equal(aligned.origin_yaw,Math.PI/6);
});
test('PNG annotation chunk preserves UTF-8 geometry without altering image chunks',async()=>{
  const m=await modulePromise;
  const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=','base64');
  const metadata={format:'fabtino-map',version:1,resolution:.1,radius:6,navigation_config:nav};
  const encoded=m.embedPNG(png,metadata);
  assert.deepEqual(m.readPNGMetadata(encoded),metadata);
  assert.deepEqual(Buffer.from(encoded.subarray(0,png.length-12)),png.subarray(0,png.length-12));
  assert.equal(m.readPNGMetadata(png),null);
  encoded[png.length+15]^=1;
  assert.throws(()=>m.readPNGMetadata(encoded),/checksum/);
});
test('invalid occupancy, unbounded dimensions, zone radii and duplicate names fail before import',async()=>{
  const m=await modulePromise;
  for(const bad of [0,-1,NaN,Infinity]) assert.throws(()=>m.validateNavigation({zones:[{...nav.zones[0],radius:bad}]}));
  assert.throws(()=>m.validateNavigation({zones:[nav.zones[0],{...nav.zones[0],id:'b'}]}));
  assert.throws(()=>m.validateBundle({format:'fabtino-map',version:1,resolution:.001,radius:100,grid:[]}));
  assert.throws(()=>m.validateBundle({format:'fabtino-map',version:1,resolution:1,radius:1,grid:[0,0,0,50]}));
});
