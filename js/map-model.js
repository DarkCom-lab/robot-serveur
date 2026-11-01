export const MapModel = (() => {
  let resolution = 0.05;
  let radius = 20;
  let width = 0, height = 0;
  let originX = -20, originY = -20, originYaw = 0, frameId = 'map';
  let grid = null;
  let evidence = null;
  let occupiedCount = 0;
  let revision = 0;
  let changedCells = new Set();
  let freeEvidenceStep = 1;
  let occupiedEvidenceStep = 2;
  let freeThreshold = -2;
  let occupiedThreshold = 2;

  function allocateGeometry(newResolution, newWidth, newHeight, x, y, yaw = 0, frame = 'map') {
    resolution = Number(newResolution);
    width = Number(newWidth);
    height = Number(newHeight);
    originX = Number(x); originY = Number(y); originYaw = Number(yaw); frameId = String(frame || 'map');
    if (![resolution, width, height, originX, originY, originYaw].every(Number.isFinite)
        || resolution <= 0 || width < 1 || height < 1 || !Number.isInteger(width) || !Number.isInteger(height)
        || width * height > 1000000) throw new Error('Invalid occupancy map geometry');
    radius = Math.max(width, height) * resolution / 2;
    revision++;
    grid = new Int8Array(width * height);
    grid.fill(-1);
    evidence = new Int16Array(width * height);
    occupiedCount = 0;
    changedCells = new Set();
  }

  function allocate(newResolution = resolution, newRadius = radius) {
    const r = Number(newRadius), res = Number(newResolution);
    const side = Math.ceil((r * 2) / res);
    allocateGeometry(res, side, side, -r, -r, 0, 'map');
  }

  function worldToCell(x, y) {
    const dx = Number(x) - originX, dy = Number(y) - originY;
    const c = Math.cos(originYaw), s = Math.sin(originYaw);
    const localX = c * dx + s * dy, localY = -s * dx + c * dy;
    const gx = Math.floor(localX / resolution), gy = Math.floor(localY / resolution);
    if (!Number.isFinite(gx) || !Number.isFinite(gy) || gx < 0 || gy < 0 || gx >= width || gy >= height) return null;
    return { x: gx, y: gy, index: gy * width + gx, value: grid[gy * width + gx] };
  }

  function cellCenterWorld(gx, gy) {
    const localX = (gx + 0.5) * resolution, localY = (gy + 0.5) * resolution;
    const c = Math.cos(originYaw), s = Math.sin(originYaw);
    return { x: originX + c * localX - s * localY, y: originY + s * localX + c * localY };
  }

  function cellIndex(x, y) { return worldToCell(x, y)?.index ?? -1; }

  function setFree(x, y) {
    const i = cellIndex(x, y);
    if (i < 0) return;
    evidence[i] = Math.max(-12, evidence[i] - freeEvidenceStep);
    const next = evidence[i] <= freeThreshold ? 0 : -1;
    if (grid[i] !== next) {
      if (grid[i] === 100) occupiedCount--;
      if (next === 100) occupiedCount++;
      grid[i] = next; changedCells.add(i); revision++;
    }
  }

  function setOccupied(x, y) {
    const i = cellIndex(x, y);
    if (i < 0) return;
    evidence[i] = Math.min(12, evidence[i] + occupiedEvidenceStep);
    const next = evidence[i] >= occupiedThreshold ? 100 : -1;
    if (grid[i] !== next) {
      if (grid[i] === 100) occupiedCount--;
      if (next === 100) occupiedCount++;
      grid[i] = next; changedCells.add(i); revision++;
    }
  }

  function rayTrace(x0, y0, x1, y1) {
    const dx = x1 - x0, dy = y1 - y0;
    const steps = Math.max(1, Math.ceil(Math.hypot(dx, dy) / (resolution * 0.7)));
    for (let i = 0; i < steps; i++) {
      const t = i / steps; setFree(x0 + dx * t, y0 + dy * t);
    }
    setOccupied(x1, y1);
  }

  function consumeChanges() { const result = changedCells; changedCells = new Set(); return result; }
  function clear() { allocateGeometry(resolution, width, height, originX, originY, originYaw, frameId); }

  function loadGrid(newResolution, newRadius, values, geometry = {}) {
    const res = Number(newResolution), extent = Number(newRadius);
    const w = Number(geometry.width ?? Math.ceil((extent * 2) / res));
    const h = Number(geometry.height ?? w);
    const ox = Number(geometry.origin_x ?? -extent), oy = Number(geometry.origin_y ?? -extent);
    const yaw = Number(geometry.origin_yaw ?? 0);
    const frame = geometry.frame_id ?? 'map';
    if (!Number.isFinite(res) || !Number.isFinite(extent) || res <= 0 || extent <= 0
        || !Number.isInteger(w) || !Number.isInteger(h) || w < 1 || h < 1 || w * h > 1000000
        || !Array.isArray(values) || values.length !== w * h || values.some(value => ![-1, 0, 100].includes(value))) {
      throw new Error('Invalid occupancy map dimensions or cells');
    }
    allocateGeometry(res, w, h, ox, oy, yaw, frame);
    grid.set(values);
    occupiedCount = values.reduce((count, value) => count + (Number(value) === 100 ? 1 : 0), 0);
    return true;
  }

  function configureEvidence(config = {}) {
    freeEvidenceStep = Math.max(1, Number(config.free_evidence_step) || 1);
    occupiedEvidenceStep = Math.max(1, Number(config.occupied_evidence_step) || 1);
    freeThreshold = Number(config.free_threshold ?? -2);
    occupiedThreshold = Number(config.occupied_threshold ?? 2);
  }

  function get() {
    return { grid, size: width, width, height, resolution, radius, originX, originY, originYaw, frameId,
      occupiedCount, revision, worldToCell, cellCenterWorld };
  }

  return { allocate, allocateGeometry, worldToCell, cellCenterWorld, setFree, setOccupied, rayTrace,
    consumeChanges, clear, loadGrid, configureEvidence, get };
})();
