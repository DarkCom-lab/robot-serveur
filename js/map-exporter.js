// Pixels remain occupancy data; annotations travel as PNG metadata or JSON.
export function validateNavigation(value = {}) {
  const zones = value.zones ?? [];
  if (!Array.isArray(zones) || zones.length > 64) throw new Error('At most 64 zones are allowed.');
  const ids = new Set(), names = new Set();
  const number = v => { if (typeof v !== 'number' || !Number.isFinite(v)) throw new Error('Coordinates and radii must be finite numbers.'); return v; };
  const normalized = zones.map(z => {
    if (!z || typeof z.id !== 'string' || !z.id.trim() || z.id.length > 128 || ids.has(z.id)) throw new Error('Zone IDs must be unique.');
    if (typeof z.name !== 'string' || !z.name.trim() || z.name.trim().length > 60 || names.has(z.name.trim().toLowerCase())) throw new Error('Give every zone a unique name (1–60 characters).');
    ids.add(z.id); names.add(z.name.trim().toLowerCase());
    const radius = number(z.radius);
    if (radius < .05 || radius > 100) throw new Error('Zone radius must be between 0.05 and 100 m.');
    return { id: z.id, name: z.name.trim(), x: number(z.x), y: number(z.y), radius };
  });
  const base = value.base == null ? null : { x: number(value.base.x), y: number(value.base.y), yaw_deg: number(value.base.yaw_deg ?? 0) };
  return { zones: normalized, base };
}
export function validateBundle(value) {
  if (value?.format !== 'fabtino-map' || value.version !== 1) throw new Error('Unsupported map bundle.');
  const { resolution, radius, grid } = value, width=value.width ?? Math.ceil(2*radius/resolution), height=value.height ?? width;
  if (!Number.isFinite(resolution) || !Number.isFinite(radius) || resolution <= 0 || radius <= 0
      || !Number.isInteger(width) || !Number.isInteger(height) || width<1 || height<1 || width*height>1000000
      || !Array.isArray(grid) || grid.length !== width*height || grid.some(v => ![-1, 0, 100].includes(v))) throw new Error('Invalid map dimensions or occupancy cells.');
  const geometry={width,height,origin_x:Number(value.origin_x ?? -radius),origin_y:Number(value.origin_y ?? -radius),
    origin_yaw:Number(value.origin_yaw ?? 0),frame_id:value.frame_id ?? 'map'};
  if (![geometry.origin_x,geometry.origin_y,geometry.origin_yaw].every(Number.isFinite)) throw new Error('Invalid map origin.');
  return { resolution, radius, grid, ...geometry, navigation_config: validateNavigation(value.navigation_config) };
}
const signature = [137,80,78,71,13,10,26,10];
function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) { crc ^= byte; for (let b = 0; b < 8; b++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0); }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunks(bytes) {
  if (!signature.every((v,i) => bytes[i] === v)) return [];
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), result = [];
  for (let offset = 8; offset < bytes.length;) {
    if (offset + 12 > bytes.length) throw new Error('Truncated PNG.');
    const length = view.getUint32(offset);
    if (offset + 12 + length > bytes.length) throw new Error('Invalid PNG chunk.');
    const type = String.fromCharCode(...bytes.subarray(offset+4,offset+8));
    result.push({offset,length,type}); offset += length + 12;
    if (type === 'IEND') break;
  }
  return result;
}
export function embedPNG(bytes, metadata) {
  const end = chunks(bytes).find(c => c.type === 'IEND');
  if (!end) throw new Error('PNG has no end chunk.');
  const data = new TextEncoder().encode('fabtino_navigation\0\0\0\0\0' + JSON.stringify(metadata));
  const chunk = new Uint8Array(data.length+12), view = new DataView(chunk.buffer);
  view.setUint32(0,data.length); chunk.set([105,84,88,116],4); chunk.set(data,8);
  view.setUint32(chunk.length-4,crc32(chunk.subarray(4,chunk.length-4)));
  const output = new Uint8Array(bytes.length+chunk.length);
  output.set(bytes.subarray(0,end.offset)); output.set(chunk,end.offset); output.set(bytes.subarray(end.offset),end.offset+chunk.length);
  return output;
}
export function readPNGMetadata(bytes) {
  for (const c of chunks(bytes)) {
    if (c.type !== 'iTXt') continue;
    const data = bytes.subarray(c.offset+8,c.offset+8+c.length), keywordEnd = data.indexOf(0);
    if (new TextDecoder().decode(data.subarray(0,keywordEnd)) !== 'fabtino_navigation') continue;
    const view = new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);
    if (crc32(bytes.subarray(c.offset+4,c.offset+8+c.length)) !== view.getUint32(c.offset+8+c.length)) throw new Error('Map metadata checksum failed.');
    if (data[keywordEnd+1] !== 0 || data[keywordEnd+2] !== 0) throw new Error('Unsupported map metadata compression.');
    const languageEnd = data.indexOf(0,keywordEnd+3), titleEnd = data.indexOf(0,languageEnd+1);
    if (languageEnd < 0 || titleEnd < 0) throw new Error('Invalid map metadata.');
    return JSON.parse(new TextDecoder().decode(data.subarray(titleEnd+1)));
  }
  return null;
}
function download(blob,name) {
  const url = URL.createObjectURL(blob), link = document.createElement('a');
  link.download = name; link.href = url; link.click(); setTimeout(() => URL.revokeObjectURL(url),1000);
}

function mapDimensions(map) {
  const resolution=Number(map.resolution);
  const width=Number(map.width??map.size??Math.ceil(2*map.radius/resolution));
  const height=Number(map.height??map.size??width);
  const yaw=Number(map.originYaw??map.origin_yaw??0);
  const originX=Number(map.originX??map.origin_x??-map.radius),originY=Number(map.originY??map.origin_y??-map.radius);
  if(!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||width*height>1000000
      ||!Number.isFinite(resolution)||resolution<=0||!Number.isFinite(yaw)
      ||!Number.isFinite(originX)||!Number.isFinite(originY)||!map.grid||map.grid.length!==width*height)
    throw new Error('Invalid map geometry for PNG export.');
  return {width,height,resolution,yaw,originX,originY,source:map.grid};
}

/* Hough votes from occupied map cells estimate long structural line axes.
   Sampling is deterministic and bounded so large maps remain exportable. */
export function estimateMapOrientation(map) {
  const {width,height,source}=mapDimensions(map);
  let points=[];
  for(let i=0;i<width*height;i++) if(Number(source[i])===100) points.push([i%width,Math.floor(i/width)]);
  if(points.length>20000) {
    const step=Math.ceil(points.length/20000);
    points=points.filter((_,i)=>i%step===0);
  }
  const minSupport=Math.max(8,Math.floor(Math.min(width,height)*.06));
  if(points.length<minSupport*2) return {correction:0,detected_angle:0,confidence:0,line_support:0,status:'insufficient_structure'};

  const diagonal=Math.ceil(Math.hypot(width,height)),rhoCount=2*diagonal+1,angleBins=360;
  const accumulator=new Uint32Array(angleBins*rhoCount),trig=[];
  for(let a=0;a<angleBins;a++) { const t=a*Math.PI/angleBins;trig.push([Math.cos(t),Math.sin(t)]); }
  for(let a=0;a<angleBins;a++) {
    const [c,s]=trig[a],base=a*rhoCount;
    for(const [x,y] of points) {
      const rho=Math.round((x+.5-width/2)*c+(y+.5-height/2)*s)+diagonal;
      if(rho>=0&&rho<rhoCount) accumulator[base+rho]++;
    }
  }
  const family=[],lineCounts=[];
  for(let a=0;a<angleBins;a++) {
    const base=a*rhoCount,peaks=[];
    for(let r=2;r<rhoCount-2;r++) {
      const v=accumulator[base+r];
      if(v<minSupport||v<accumulator[base+r-1]||v<accumulator[base+r+1]) continue;
      if(peaks.every(p=>Math.abs(p.r-r)>Math.max(4,Math.floor(Math.min(width,height)*.025)))) peaks.push({r,v});
    }
    peaks.sort((a,b)=>b.v-a.v);
    const selected=peaks.slice(0,4);
    family[a]=selected.reduce((sum,p)=>sum+p.v*p.v,0);
    lineCounts[a]=selected.length;
  }
  let best={score:0,axis:0,support:0};
  for(let axis=0;axis<180;axis++) {
    const a=(axis+180)%angleBins,b=axis;
    const score=family[a]+family[b];
    if(score>best.score) best={score,axis,features:lineCounts[a]+lineCounts[b],support:Math.max(...[a,b].map(i=>{
      const base=i*rhoCount;let peak=0;
      for(let r=2;r<rhoCount-2;r++) peak=Math.max(peak,accumulator[base+r]);
      return peak;
    }))};
  }
  if(best.support<minSupport||best.features<2||best.score===0) return {correction:0,detected_angle:0,confidence:0,line_support:best.support,status:'insufficient_structure'};
  let angle=best.axis*.5;
  if(angle>45) angle-=90;
  const detected=angle*Math.PI/180;
  const confidence=Math.min(1,best.score/(points.length*points.length));
  return {correction:-detected,detected_angle:detected,confidence,line_support:best.support,structural_lines:best.features,
    status:Math.abs(detected)<Math.PI/720?'already_aligned':'corrected'};
}

// Rotate cell centers by the content-derived angle. Output resolution remains
// unchanged, and the expanded bounds prevent cropping. The returned ROS
// geometry maps every output cell back into the original map frame.
export function axisAlignedGrid(map) {
  const {width,height,resolution,yaw,originX,originY,source}=mapDimensions(map);
  const orientation=estimateMapOrientation(map),angle=orientation.correction;
  let minCellX=width,minCellY=height,maxCellX=-1,maxCellY=-1;
  for(let y=0;y<height;y++) for(let x=0;x<width;x++) if(Number(source[y*width+x])>=0) {
    minCellX=Math.min(minCellX,x);minCellY=Math.min(minCellY,y);
    maxCellX=Math.max(maxCellX,x);maxCellY=Math.max(maxCellY,y);
  }
  if(maxCellX<0) { minCellX=0;minCellY=0;maxCellX=width-1;maxCellY=height-1; }
  else {
    minCellX=Math.max(0,minCellX-2);minCellY=Math.max(0,minCellY-2);
    maxCellX=Math.min(width-1,maxCellX+2);maxCellY=Math.min(height-1,maxCellY+2);
  }
  const contentWidth=maxCellX-minCellX+1,contentHeight=maxCellY-minCellY+1;
  const c=Math.cos(angle),s=Math.sin(angle);
  const outWidth=Math.max(1,Math.ceil(Math.abs(contentWidth*c)+Math.abs(contentHeight*s)-1e-9));
  const outHeight=Math.max(1,Math.ceil(Math.abs(contentWidth*s)+Math.abs(contentHeight*c)-1e-9));
  if(outWidth*outHeight>1000000) throw new Error('Aligned map exceeds 1,000,000 cells.');
  const grid=new Int8Array(outWidth*outHeight);grid.fill(-1);
  for(let y=0;y<contentHeight;y++) for(let x=0;x<contentWidth;x++) {
    const dx=(x+.5-contentWidth/2)*c-(y+.5-contentHeight/2)*s+outWidth/2;
    const dy=(x+.5-contentWidth/2)*s+(y+.5-contentHeight/2)*c+outHeight/2;
    const ox=Math.max(0,Math.min(outWidth-1,Math.floor(dx))),oy=Math.max(0,Math.min(outHeight-1,Math.floor(dy)));
    const index=oy*outWidth+ox,value=Number(source[(y+minCellY)*width+x+minCellX]);
    if(![-1,0,100].includes(value)) throw new Error('Invalid occupancy cell in map.');
    const old=grid[index];
    if(value===100||old===-1&&value===0) grid[index]=value;
  }
  const yawOut=yaw-angle,cornerX=minCellX+contentWidth/2-(outWidth*c+outHeight*s)/2,
    cornerY=minCellY+contentHeight/2+(outWidth*s-outHeight*c)/2;
  const cy=Math.cos(yaw),sy=Math.sin(yaw);
  const outOriginX=originX+resolution*(cy*cornerX-sy*cornerY),outOriginY=originY+resolution*(sy*cornerX+cy*cornerY);
  const imageToSourceGrid=[c,-s,minCellX+contentWidth/2+c*(.5-outWidth/2)+s*(outHeight/2-.5),
    -s,-c,minCellY+contentHeight/2-s*(.5-outWidth/2)+c*(outHeight/2-.5)];
  return {width:outWidth,height:outHeight,resolution,origin_x:outOriginX,origin_y:outOriginY,origin_yaw:yawOut,
    frame_id:map.frameId??map.frame_id??'map',grid,orientation,image_to_source_grid:imageToSourceGrid};
}

export const MapExporter = {
  bundle(map, navigation) { return { format: 'fabtino-map', version: 1, resolution: map.resolution, radius: map.radius,
    width:map.width??map.size??Math.ceil(2*map.radius/map.resolution),
    height:map.height??map.size??Math.ceil(2*map.radius/map.resolution),origin_x:map.originX??-map.radius,origin_y:map.originY??-map.radius,
    origin_yaw:map.originYaw??0,frame_id:map.frameId??'map',grid: Array.from(map.grid), navigation_config: validateNavigation(navigation) }; },
  exportJSON(map,navigation) { download(new Blob([JSON.stringify(this.bundle(map,navigation))],{type:'application/json'}),'fabtino_map.json'); },
  async exportPNG(map,navigation) {
    const aligned=axisAlignedGrid(map),{width,height,resolution,origin_x,origin_y,origin_yaw,frame_id,grid,image_to_source_grid}=aligned;
    const canvas = document.createElement('canvas'); canvas.width=width;canvas.height=height;
    const ctx = canvas.getContext('2d'), pixels = ctx.createImageData(width,height);
    for (let y=0;y<height;y++) for(let x=0;x<width;x++) {
      const v=grid[y*width+x], color=v<0?128:v===100?0:255, i=((height-1-y)*width+x)*4;
      pixels.data.set([color,color,color,255],i);
    }
    ctx.putImageData(pixels,0,0);
    const blob = await new Promise(resolve => canvas.toBlob(resolve,'image/png'));
    if (!blob) throw new Error('Could not encode the map.');
    const metadata = { format:'fabtino-map', version:1, resolution, radius:Math.max(width,height)*resolution/2,width,height,
      origin_x,origin_y,origin_yaw,frame_id,navigation_config:validateNavigation(navigation),
    orientation_correction:{...aligned.orientation,method:'occupied-cell Hough line voting'},
      pixel_to_map:{origin_x,origin_y,origin_yaw,resolution,pixel_center_offset:.5,row_order:'top_to_bottom',frame_id},
      image_to_source_grid:{matrix:image_to_source_grid,pixel_coordinates:'centers; x right, y down',source_coordinates:'grid cells; x right, y up'},
      source_map:{width:map.width??map.size,height:map.height??map.size,resolution:map.resolution,
        origin_x:map.originX??map.origin_x??-map.radius,origin_y:map.originY??map.origin_y??-map.radius,
        origin_yaw:map.originYaw??map.origin_yaw??0,frame_id:map.frameId??map.frame_id??'map'}};
    download(new Blob([embedPNG(new Uint8Array(await blob.arrayBuffer()),metadata)],{type:'image/png'}),'fabtino_2d_map.png');
  }
};
