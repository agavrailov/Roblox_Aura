"""
Shared hex maze generation utilities.
Mirrors the Lua MazeGenerator logic in Python for testing.

Uses axial coordinates (q, r) with center at (0, 0).
Board shape: regular hexagon with radius R.
A cell is valid when max(|q|, |r|, |q+r|) <= R.
"""
import math
import random
from collections import deque

# --- Config (mirrors GameConfig.lua) ---
HEX_RADIUS = 5
ZONE_SIZE = 50
LOOP_PERCENTAGE = 15

# Zone types
SAFE = "Safe"
BLUE = "Blue"
GREEN = "Green"
RED = "Red"

TIER = {SAFE: 0, BLUE: 1, GREEN: 2, RED: 3}

# 6 hex directions in axial coordinates: E, NE, NW, W, SW, SE
DIRECTIONS = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
OPPOSITE = {0: 3, 1: 4, 2: 5, 3: 0, 4: 1, 5: 2}  # i -> (i+3) % 6


# --- Grid helpers ---

def is_valid_hex(q, r, radius):
    return abs(q) <= radius and abs(r) <= radius and abs(q + r) <= radius


def create_grid(radius):
    grid = {}
    for q in range(-radius, radius + 1):
        for r in range(-radius, radius + 1):
            if is_valid_hex(q, r, radius):
                grid[(q, r)] = {
                    "q": q, "r": r,
                    "visited": False,
                    "walls": [True, True, True, True, True, True],
                    "zoneType": None,
                    "doorTypes": [None, None, None, None, None, None],
                }
    return grid


def get_cell(grid, q, r):
    return grid.get((q, r))


def remove_wall(grid, cell, direction):
    """Remove wall from cell AND the opposite wall from its neighbor."""
    cell["walls"][direction] = False
    dq, dr = DIRECTIONS[direction]
    neighbor = get_cell(grid, cell["q"] + dq, cell["r"] + dr)
    if neighbor:
        neighbor["walls"][OPPOSITE[direction]] = False


# --- Maze generation steps ---

def get_unvisited_neighbors(grid, cell):
    neighbors = []
    for i, (dq, dr) in enumerate(DIRECTIONS):
        nq, nr = cell["q"] + dq, cell["r"] + dr
        neighbor = get_cell(grid, nq, nr)
        if neighbor and not neighbor["visited"]:
            neighbors.append((neighbor, i))
    return neighbors


def carve_maze(grid):
    stack = []
    current = grid[(0, 0)]
    current["visited"] = True

    while True:
        neighbors = get_unvisited_neighbors(grid, current)
        if neighbors:
            chosen, direction = random.choice(neighbors)
            stack.append(current)
            remove_wall(grid, current, direction)
            current = chosen
            current["visited"] = True
        elif stack:
            current = stack.pop()
        else:
            break


def add_loops(grid):
    cells = list(grid.keys())
    total_walls = len(cells) * 3
    loops_to_add = int(total_walls * LOOP_PERCENTAGE / 100)
    added = 0
    attempts = 0
    max_attempts = loops_to_add * 10

    while added < loops_to_add and attempts < max_attempts:
        attempts += 1
        pos = random.choice(cells)
        cell = grid[pos]
        d = random.randint(0, 5)
        if cell["walls"][d]:
            dq, dr = DIRECTIONS[d]
            neighbor = get_cell(grid, pos[0] + dq, pos[1] + dr)
            if neighbor:
                remove_wall(grid, cell, d)
                added += 1
    return added


def assign_zone_colors(grid):
    """BFS from (0,0) to assign zones based on distance."""
    start = grid[(0, 0)]
    distances = {pos: float("inf") for pos in grid}
    distances[(0, 0)] = 0
    queue = deque([(start, 0)])

    while queue:
        cell, dist = queue.popleft()
        for i, (dq, dr) in enumerate(DIRECTIONS):
            if not cell["walls"][i]:
                nq, nr = cell["q"] + dq, cell["r"] + dr
                if (nq, nr) in distances and distances[(nq, nr)] > dist + 1:
                    distances[(nq, nr)] = dist + 1
                    queue.append((grid[(nq, nr)], dist + 1))

    max_dist = max(d for d in distances.values() if d < float("inf"))
    if max_dist == 0:
        max_dist = 1

    grid[(0, 0)]["zoneType"] = SAFE

    for pos, cell in grid.items():
        if pos == (0, 0):
            continue
        d = distances[pos]
        if d == float("inf"):
            cell["zoneType"] = BLUE
            continue
        normalized = d / max_dist
        random_offset = (random.random() - 0.5) * 0.2
        adjusted = max(0, min(1, normalized + random_offset))
        if adjusted < 0.5:
            cell["zoneType"] = BLUE
        elif adjusted < 0.75:
            cell["zoneType"] = GREEN
        else:
            cell["zoneType"] = RED


def ensure_zone_connectivity(grid):
    connections_added = 0
    for pos, cell in grid.items():
        has_conn = False
        for i, (dq, dr) in enumerate(DIRECTIONS):
            if not cell["walls"][i]:
                neighbor = get_cell(grid, pos[0] + dq, pos[1] + dr)
                if neighbor and neighbor["zoneType"] != cell["zoneType"]:
                    has_conn = True
                    break
        if not has_conn:
            for i, (dq, dr) in enumerate(DIRECTIONS):
                neighbor = get_cell(grid, pos[0] + dq, pos[1] + dr)
                if neighbor and neighbor["zoneType"] != cell["zoneType"]:
                    remove_wall(grid, cell, i)
                    connections_added += 1
                    break
    return connections_added


def add_escape_routes(grid):
    added = 0
    for pos, cell in grid.items():
        cell_tier = TIER.get(cell["zoneType"], 1)
        if cell_tier <= 1:
            continue
        has_escape = False
        for i, (dq, dr) in enumerate(DIRECTIONS):
            if not cell["walls"][i]:
                neighbor = get_cell(grid, cell["q"] + dq, cell["r"] + dr)
                if neighbor:
                    n_tier = TIER.get(neighbor["zoneType"], 1)
                    if n_tier < cell_tier:
                        has_escape = True
                        break
        if not has_escape:
            for i, (dq, dr) in enumerate(DIRECTIONS):
                neighbor = get_cell(grid, cell["q"] + dq, cell["r"] + dr)
                if neighbor:
                    n_tier = TIER.get(neighbor["zoneType"], 1)
                    if n_tier < cell_tier:
                        remove_wall(grid, cell, i)
                        cell["doorTypes"][i] = "Escape"
                        neighbor["doorTypes"][OPPOSITE[i]] = "Escape"
                        added += 1
                        break
    return added


def add_alternate_paths(grid):
    cells = list(grid.keys())
    to_add = max(1, int(len(cells) * 0.05))
    added = 0
    attempts = 0
    max_attempts = to_add * 10

    while added < to_add and attempts < max_attempts:
        attempts += 1
        pos = random.choice(cells)
        cell = grid[pos]
        d = random.randint(0, 5)
        dq, dr = DIRECTIONS[d]
        neighbor = get_cell(grid, pos[0] + dq, pos[1] + dr)
        if neighbor and cell["zoneType"] != neighbor["zoneType"]:
            if cell["walls"][d]:
                remove_wall(grid, cell, d)
                cell["doorTypes"][d] = "Alternate"
                neighbor["doorTypes"][OPPOSITE[d]] = "Alternate"
                added += 1
            elif not cell["doorTypes"][d]:
                cell["doorTypes"][d] = "Alternate"
                neighbor["doorTypes"][OPPOSITE[d]] = "Alternate"
                added += 1
    return added


def generate_maze(radius=HEX_RADIUS):
    """Full maze generation pipeline matching the Lua code."""
    grid = create_grid(radius)
    carve_maze(grid)
    add_loops(grid)
    assign_zone_colors(grid)
    ensure_zone_connectivity(grid)
    add_escape_routes(grid)
    add_alternate_paths(grid)
    return grid


# --- Geometry helpers (mirrors WorldBuilder.lua) ---

def hex_to_world(q, r):
    """Convert axial (q, r) to world (x, z) for flat-top hexagons."""
    size = ZONE_SIZE / 2
    x = size * (3 / 2 * q)
    z = size * (math.sqrt(3) / 2 * q + math.sqrt(3) * r)
    return x, z


def hex_corners(cx, cz):
    """Get the 6 corner positions of a flat-top hex centered at (cx, cz).
    Corners numbered 0-5 (stored as indices 0-5), starting from right (0°), counter-clockwise.
    """
    size = ZONE_SIZE / 2
    corners = []
    for i in range(6):
        angle = math.radians(60 * i)
        corners.append((cx + size * math.cos(angle), cz + size * math.sin(angle)))
    return corners


# Mirrors WorldBuilder.lua WALL_EDGE
# Each direction's wall is on the edge perpendicular to the neighbor direction.
WALL_EDGE = [
    (0, 1),  # E:  edge at 30°, between corners at 0° and 60°
    (0, 5),  # NE: edge at 330°, between corners at 0° and 300°
    (4, 5),  # NW: edge at 270°, between corners at 240° and 300°
    (3, 4),  # W:  edge at 210°, between corners at 180° and 240°
    (2, 3),  # SW: edge at 150°, between corners at 120° and 180°
    (1, 2),  # SE: edge at 90°, between corners at 60° and 120°
]


def edge_midpoint_key(x1, z1, x2, z2):
    """Rounded midpoint key for deduplicating shared edges."""
    mx = round((x1 + x2) * 10) / 10
    mz = round((z1 + z2) * 10) / 10
    return (mx, mz)


def wall_edge_midpoint(q, r, direction):
    """Compute the world midpoint of the wall on a given direction for cell (q, r)."""
    cx, cz = hex_to_world(q, r)
    corners = hex_corners(cx, cz)
    c1_idx, c2_idx = WALL_EDGE[direction]
    c1 = corners[c1_idx]
    c2 = corners[c2_idx]
    return ((c1[0] + c2[0]) / 2, (c1[1] + c2[1]) / 2)


def door_midpoint(q1, r1, q2, r2):
    """Compute the world midpoint between two cell centers (where DoorController places doors)."""
    fx, fz = hex_to_world(q1, r1)
    tx, tz = hex_to_world(q2, r2)
    return ((fx + tx) / 2, (fz + tz) / 2)
