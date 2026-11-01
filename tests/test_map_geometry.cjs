const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const {test}=require('node:test');

test('rectangular map world-cell transforms round-trip with translated and rotated origin',()=>{
  const context=vm.createContext({});
  const source=fs.readFileSync(path.join(__dirname,'../js/map-model.js'),'utf8').replace('export const','const');
  vm.runInContext(`${source}\nthis.model=MapModel;`,context);
  const model=context.model;
  model.loadGrid(.5,1.25,Array(15).fill(0),{width:5,height:3,origin_x:4,origin_y:-2,origin_yaw:Math.PI/2,frame_id:'map'});
  const map=model.get();
  assert.equal(map.width,5);assert.equal(map.height,3);assert.equal(map.grid.length,15);
  for(let gy=0;gy<3;gy++) for(let gx=0;gx<5;gx++) {
    const world=map.cellCenterWorld(gx,gy),cell=map.worldToCell(world.x,world.y);
    assert.deepEqual([cell.x,cell.y],[gx,gy]);
  }
  assert.equal(map.worldToCell(4,-2).index,0);
  assert.equal(map.worldToCell(2,-2),null);
});
