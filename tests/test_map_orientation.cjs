const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

test('turning the robot keeps map cells and wall points fixed on screen', () => {
  const rectangles = [], rotations = [];
  const context2d = {
    setTransform() {}, fillRect: (...args) => rectangles.push(args),
    save() {}, restore() {}, translate() {}, rotate: angle => rotations.push(angle),
    beginPath() {}, moveTo() {}, lineTo() {}, closePath() {}, fill() {}, stroke() {}
  };
  const canvas = { clientWidth: 400, clientHeight: 400, width: 400, height: 400,
    getContext: () => context2d, addEventListener() {} };
  const context = vm.createContext({ devicePixelRatio: 1, canvas });
  const source = fs.readFileSync(path.join(__dirname, '../js/grid-renderer.js'), 'utf8');
  vm.runInContext(source.replace('export const', 'const'), context);
  vm.runInContext('GridRenderer.init(canvas)', context);
  context.map = { size: 2, radius: 5, resolution: 5, grid: [0, 100, -1, 100] };
  let firstMap;
  for (const yaw of [0, Math.PI/2, Math.PI, -Math.PI/2]) {
    context.robot = { x: 1, y: 0, yaw };
    rectangles.length = 0;
    vm.runInContext('GridRenderer.render(map, robot, [[2, 1]])', context);
    const actual = JSON.stringify(rectangles);
    firstMap ??= actual;
    assert.equal(actual, firstMap);
    // A +90 degree heading points up on a canvas whose +Y points down.
    const angle = rotations.at(-1);
    assert.ok(Math.abs(Math.cos(angle)-Math.cos(yaw)) < 1e-12);
    assert.ok(Math.abs(Math.sin(angle)+Math.sin(yaw)) < 1e-12);
  }
});

test('small pointer jitter remains a goal click; deliberate drag pans without selecting a goal', () => {
  const handlers={};
  const context2d={setTransform(){}};
  const canvas={clientWidth:400,clientHeight:400,width:400,height:400,
    getContext:()=>context2d,addEventListener:(name,handler)=>{handlers[name]=handler;},
    setPointerCapture(){},getBoundingClientRect:()=>({left:0,top:0})};
  const map={width:2,height:2,size:2,radius:1,resolution:1,originX:-1,originY:-1,originYaw:0,
    grid:new Int8Array(4),revision:1};
  const context=vm.createContext({devicePixelRatio:1,window:{__mapViewerMapState:()=>map},canvas});
  const source=fs.readFileSync(path.join(__dirname,'../js/grid-renderer.js'),'utf8');
  vm.runInContext(source.replace('export const','const'),context);
  vm.runInContext('GridRenderer.init(canvas)',context);
  let selected=[];
  context.handlers=handlers;
  context.onGoal=(x,y)=>selected.push([x,y]);
  vm.runInContext('GridRenderer.setClickHandler(onGoal)',context);
  const event=(x,y,extra={})=>({clientX:x,clientY:y,pointerId:1,button:0,isPrimary:true,...extra});
  handlers.pointerdown(event(200,200));
  handlers.pointermove(event(206,200));
  handlers.pointerup(event(206,200));
  assert.equal(selected.length,1);
  assert.ok(Math.abs(selected[0][0]-0.03)<1e-9);
  assert.ok(Math.abs(selected[0][1])<1e-9);

  handlers.pointerdown(event(200,200));
  handlers.pointermove(event(220,200));
  handlers.pointerup(event(220,200));
  assert.equal(selected.length,1);
  assert.notEqual(vm.runInContext('GridRenderer.getView().panX',context),0);

  const beforePan=vm.runInContext('GridRenderer.getView().panX',context);
  handlers.pointerdown(event(200,200));
  handlers.pointermove(event(212,200));
  handlers.pointerup(event(212,200));
  assert.equal(selected.length,2);
  assert.equal(vm.runInContext('GridRenderer.getView().panX',context),beforePan);

  handlers.pointerdown(event(200,200,{button:2}));
  handlers.pointermove(event(240,200,{button:2}));
  handlers.pointerup(event(240,200,{button:2}));
  assert.equal(selected.length,2);
  assert.equal(vm.runInContext('GridRenderer.getView().panX',context),beforePan);
});
