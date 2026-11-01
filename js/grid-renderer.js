export const GridRenderer = (() => {
  let canvas = null;
  let ctx = null;
  let zoom = 1;
  let panX = 0;
  let panY = 0;
  let dragging = false;
  let lastPX = 0;
  let lastPY = 0;
  let downPX = 0;
  let downPY = 0;
  let activePointerId = null;
  let clickHandler = null;
  let needsFullRedraw = true;
  let lastFrame = null;
  let overlays = { zones: [], base: null };
  let raster = null, rasterGrid = null, rasterRevision = null, rasterGeometry = '', overlaySignature = '';
  const DRAG_THRESHOLD_PX = 14;

  function redraw() {
    if (lastFrame) render(...lastFrame);
  }

  function init(element) {
    canvas = element;
    ctx = canvas.getContext("2d");
    resize();
    installInput();
  }

  function resize() {
    if (!canvas) return;
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    const dpr = devicePixelRatio || 1;
    if (!w || !h) return;

    if (canvas.width !== w * dpr || canvas.height !== h * dpr) {
      canvas.width = w * dpr;
      canvas.height = h * dpr;
    }

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    needsFullRedraw = true;
    redraw();
  }

  function transform(x, y, map) {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    const geometry = mapGeometry(map);
    const scale = Math.min(w / geometry.width, h / geometry.height) * zoom;

    return [
      w / 2 + (x - geometry.centerX - panX) * scale,
      h / 2 - (y - geometry.centerY - panY) * scale
    ];
  }

  function mapGeometry(map) {
    const width = map.width ?? map.size, height = map.height ?? map.size;
    const res = map.resolution, ox = map.originX ?? -map.radius, oy = map.originY ?? -map.radius;
    const yaw = map.originYaw ?? 0, c = Math.cos(yaw), s = Math.sin(yaw);
    const corners = [[0,0],[width*res,0],[0,height*res],[width*res,height*res]].map(([x,y]) =>
      [ox+c*x-s*y, oy+s*x+c*y]);
    const xs = corners.map(p=>p[0]), ys = corners.map(p=>p[1]);
    const minX=Math.min(...xs), maxX=Math.max(...xs), minY=Math.min(...ys), maxY=Math.max(...ys);
    return { width:maxX-minX,height:maxY-minY,centerX:(minX+maxX)/2,centerY:(minY+maxY)/2 };
  }

  function pointerWorld(event, map) {
    const rect=canvas.getBoundingClientRect(),geometry=mapGeometry(map);
    const scale=Math.min(canvas.clientWidth/geometry.width,canvas.clientHeight/geometry.height)*zoom;
    const px=event.clientX-rect.left,py=event.clientY-rect.top;
    return {x:geometry.centerX+panX+(px-canvas.clientWidth/2)/scale,
      y:geometry.centerY+panY-(py-canvas.clientHeight/2)/scale};
  }

  function render(map, robot, livePoints = [], liveColor = "#53d8ff",
                  secondaryPoints = [], secondaryColor = "#ff4fd8") {
    lastFrame = [map, robot, livePoints, liveColor, secondaryPoints, secondaryColor];
    if (!canvas || !ctx) return;

    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    if (!w || !h) return;

    const geometry = mapGeometry(map);
    const scale = Math.min(w / geometry.width, h / geometry.height) * zoom;
    const px = Math.max(1, map.resolution * scale);
    const width=map.width ?? map.size,height=map.height ?? map.size;

    ctx.fillStyle = "#070b10";
    ctx.fillRect(0, 0, w, h);

    if (typeof document !== 'undefined' && ctx.drawImage) {
      const geometryKey=`${width}:${height}:${map.resolution}:${map.originX}:${map.originY}:${map.originYaw}:${map.frameId}`;
      if (!raster || rasterGrid !== map.grid || rasterRevision !== map.revision || rasterGeometry !== geometryKey) {
        raster = document.createElement('canvas');raster.width=width;raster.height=height;
        const rasterContext=raster.getContext('2d'),image=rasterContext.createImageData(width,height);
        for(let y=0;y<height;y++) for(let x=0;x<width;x++) {
          const value=map.grid[y*width+x],i=((height-1-y)*width+x)*4;
          if(value>=0)image.data.set(value===100?[244,211,94,255]:[75,105,124,255],i);
        }
        rasterContext.putImageData(image,0,0);rasterGrid=map.grid;rasterRevision=map.revision;rasterGeometry=geometryKey;
      }
      ctx.imageSmoothingEnabled=false;
      const yaw=map.originYaw ?? 0, c=Math.cos(yaw),s=Math.sin(yaw),ox=map.originX ?? -map.radius,oy=map.originY ?? -map.radius;
      const topLeftX=ox-s*height*map.resolution,topLeftY=oy+c*height*map.resolution;
      const [screenX,screenY]=transform(topLeftX,topLeftY,map);
      ctx.save();
      ctx.transform(scale*map.resolution*c,-scale*map.resolution*s,
        scale*map.resolution*s,scale*map.resolution*c,screenX,screenY);
      ctx.drawImage(raster,0,0);
      ctx.restore();
    } else {
      for (let gy = 0; gy < height; gy++) for (let gx = 0; gx < width; gx++) {
        const value=map.grid[gy*width+gx]; if(value<0) continue;
        const a=map.cellCenterWorld?.(gx,gy) ?? {x:(gx+.5)*map.resolution-map.radius,y:(gy+.5)*map.resolution-map.radius};
        const [x,y]=transform(a.x,a.y,map);
        ctx.fillStyle=value===100?"#f4d35e":"#4b697c";
        ctx.fillRect(x-px/2,y-px/2,px,px);
      }
    }

    function drawPoints(points, color) {
      if (!Array.isArray(points)) return;
      ctx.fillStyle = color;
      for (const point of points) {
        if (!Array.isArray(point) || point.length < 2) continue;
        const x = Number(point[0]);
        const y = Number(point[1]);
        if (!Number.isFinite(x) || !Number.isFinite(y)) continue;
        const [pxPoint, pyPoint] = transform(x, y, map);
        ctx.fillRect(pxPoint - 2, pyPoint - 2, 4, 4);
      }
    }

    // Current LiDAR is always cyan. In known-map mode, residual/dynamic
    // returns are drawn on top in magenta so both layers remain observable.
    drawPoints(livePoints, liveColor);
    drawPoints(secondaryPoints, secondaryColor);

    ctx.save();
    for (const zone of overlays.zones || []) {
      const [x,y] = transform(zone.x,zone.y,map);
      ctx.beginPath(); ctx.arc(x,y,zone.radius*scale,0,2*Math.PI);
      ctx.fillStyle = '#ff526626'; ctx.fill(); ctx.strokeStyle = '#ff5266'; ctx.lineWidth=2; ctx.stroke();
      ctx.fillStyle = '#ffacb6'; ctx.font='12px Segoe UI'; ctx.fillText(zone.name,x+zone.radius*scale+5,y);
    }
    for (const [point,label,color] of [[overlays.base,'BASE','#39d9ff'],[overlays.target,'STOP','#e7eef5']]) {
      if (!point) continue;
      const [x,y] = transform(point.x,point.y,map); ctx.strokeStyle=color; ctx.lineWidth=2;
      ctx.strokeRect(x-5,y-5,10,10); ctx.fillStyle=color; ctx.fillText(label,x+9,y-9);
    }
    ctx.restore();
    drawRobot(robot, map);
    needsFullRedraw = false;
  }

  function drawRobot(robot, map) {
    const [rx, ry] = transform(robot.x, robot.y, map);

    ctx.save();
    ctx.translate(rx, ry);
    // Map coordinates use +X forward and +Y left. Canvas Y is downward, so
    // the visual heading is the negative mathematical yaw.
    ctx.rotate(-robot.yaw);

    ctx.fillStyle = "#38f28a";
    ctx.beginPath();
    ctx.moveTo(15, 0);
    ctx.lineTo(-10, -8);
    ctx.lineTo(-10, 8);
    ctx.closePath();
    ctx.fill();

    ctx.strokeStyle = "#ffffff";
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.restore();
  }

  function zoomBy(factor) {
    zoom = Math.max(0.4, Math.min(8, zoom * factor));
    needsFullRedraw = true;
    redraw();
  }

  function resetView() {
    zoom = 1;
    panX = 0;
    panY = 0;
    needsFullRedraw = true;
    redraw();
  }

  function installInput() {
    canvas.addEventListener("wheel", event => {
      event.preventDefault();
      zoomBy(event.deltaY < 0 ? 1.12 : 0.89);
      needsFullRedraw = true;
    }, { passive: false });

    canvas.addEventListener("pointerdown", event => {
      if (event.button !== 0 || event.isPrimary === false) return;
      dragging = true;
      activePointerId = event.pointerId;
      lastPX = event.clientX;
      lastPY = event.clientY;
      downPX = event.clientX;
      downPY = event.clientY;
      canvas.setPointerCapture(event.pointerId);
    });

    canvas.addEventListener("pointermove", event => {
      if (!dragging || event.pointerId !== activePointerId) return;

      // Do not turn the small movement of a normal click into a persistent
      // camera pan. This was especially noticeable as a small vertical shift
      // after selecting a destination on the map.
      if (Math.hypot(event.clientX - downPX, event.clientY - downPY) <= DRAG_THRESHOLD_PX) return;

      const map = window.__mapViewerMapState?.();
      if (!map) return;

      const geometry=mapGeometry(map);
      const scale = Math.min(canvas.clientWidth/geometry.width,canvas.clientHeight/geometry.height)*zoom;

      panX -= (event.clientX - lastPX) / scale;
      panY += (event.clientY - lastPY) / scale;

      lastPX = event.clientX;
      lastPY = event.clientY;
      needsFullRedraw = true;
      redraw();
    });

    canvas.addEventListener("pointerup", event => {
      if (!dragging || event.pointerId !== activePointerId) return;
      if (Math.hypot(event.clientX - downPX, event.clientY - downPY) <= DRAG_THRESHOLD_PX && clickHandler) {
        const map = window.__mapViewerMapState?.();
        if (map) {
          const point=pointerWorld(event,map);
          clickHandler(point.x,point.y);
        }
      }
      dragging = false;
      activePointerId = null;
    });
    canvas.addEventListener("pointercancel", event => {
      if (event.pointerId !== activePointerId) return;
      dragging = false;
      activePointerId = null;
    });
  }

  function getView() {
    return { zoom, panX, panY };
  }

  function needsRender() {
    return needsFullRedraw;
  }

  function setClickHandler(handler) {
    clickHandler = handler;
  }

  return {
    init,
    resize,
    render,
    zoomBy,
    resetView,
    getView,
    needsRender,
    setClickHandler
    ,setOverlays(value) { const signature=JSON.stringify(value);if(signature===overlaySignature)return;overlaySignature=signature;overlays=value;redraw(); }
  };
})();
