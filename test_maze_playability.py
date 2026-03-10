"""
Hex Maze Playability Test Harness
Mirrors the Lua MazeGenerator + MazePlayabilityValidator logic in Python
to verify that generated hex mazes are consistently playable.

Uses axial coordinates (q, r) with center at (0, 0).
Board shape: regular hexagon with radius R.
A cell is valid when max(|q|, |r|, |q+r|) <= R.
"""
import random
from collections import deque
import sys

# --- Config (mirrors GameConfig.lua) ---
HEX_RADIUS = 5
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
                    "walls": [True, True, True, True, True, True],  # 6 walls
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

    # Starting cell is Safe zone
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
                added += 1
            elif not cell["doorTypes"][d]:
                cell["doorTypes"][d] = "Alternate"
                added += 1
    return added


# --- Validation (mirrors MazePlayabilityValidator.lua) ---

def can_pass_door(from_zone, to_zone, aura_tier):
    if from_zone == to_zone:
        return True
    required = TIER.get(to_zone, 1)
    return aura_tier >= required


def find_reachable(grid, start_q, start_r, aura_tier):
    visited = set()
    queue = deque([(start_q, start_r)])
    visited.add((start_q, start_r))

    while queue:
        cq, cr = queue.popleft()
        cell = grid[(cq, cr)]
        for i, (dq, dr) in enumerate(DIRECTIONS):
            if not cell["walls"][i]:
                nq, nr = cq + dq, cr + dr
                neighbor = get_cell(grid, nq, nr)
                if neighbor and (nq, nr) not in visited:
                    if can_pass_door(cell["zoneType"], neighbor["zoneType"], aura_tier):
                        visited.add((nq, nr))
                        queue.append((nq, nr))
    return visited


def validate_maze(grid, verbose=False):
    """Run all playability checks. Returns (passed, errors_list)."""
    errors = []
    total = len(grid)

    # Check 1: Starting position
    start = grid.get((0, 0))
    if not start:
        errors.append("Start cell (0,0) does not exist")
    else:
        if start["zoneType"] != SAFE:
            errors.append(f"Start cell is {start['zoneType']}, expected Safe")
        has_conn = any(not start["walls"][i] for i in range(6))
        if not has_conn:
            errors.append("Start cell has no connections")

    # Check 2: No isolated cells
    for pos, cell in grid.items():
        if all(cell["walls"]):
            errors.append(f"Cell ({pos[0]},{pos[1]}) is fully isolated")

    # Check 3: Full connectivity (tier 3 = red aura)
    reachable_t3 = find_reachable(grid, 0, 0, 3)
    if len(reachable_t3) < total:
        errors.append(f"Full connectivity: {len(reachable_t3)}/{total} reachable with max aura")

    # Check 4: Tier progression (Safe -> Blue -> Green -> Red)
    reachable_t0 = find_reachable(grid, 0, 0, 0)
    reachable_t1 = find_reachable(grid, 0, 0, 1)
    reachable_t2 = find_reachable(grid, 0, 0, 2)

    if len(reachable_t0) == 0:
        errors.append("Tier 0: starting cell not reachable")

    blue_in_t1 = sum(1 for pos in reachable_t1 if grid[pos]["zoneType"] == BLUE)
    if len(reachable_t1) <= len(reachable_t0):
        errors.append(f"Tier 1: blue aura doesn't expand area ({len(reachable_t1)} <= {len(reachable_t0)})")
    if blue_in_t1 == 0:
        errors.append("Tier 1: no blue zones reachable")

    green_in_t2 = sum(1 for pos in reachable_t2 if grid[pos]["zoneType"] == GREEN)
    if len(reachable_t2) <= len(reachable_t1):
        errors.append(f"Tier 2: green aura doesn't expand area ({len(reachable_t2)} <= {len(reachable_t1)})")
    if green_in_t2 == 0:
        errors.append("Tier 2: no green zones reachable")

    red_in_t3 = sum(1 for pos in reachable_t3 if grid[pos]["zoneType"] == RED)
    if len(reachable_t3) <= len(reachable_t2):
        errors.append(f"Tier 3: red aura doesn't expand area ({len(reachable_t3)} <= {len(reachable_t2)})")
    if red_in_t3 == 0:
        errors.append("Tier 3: no red zones reachable")

    # Check 5: Verify wall symmetry (both sides removed)
    asymmetric = 0
    for pos, cell in grid.items():
        for i, (dq, dr) in enumerate(DIRECTIONS):
            if not cell["walls"][i]:
                neighbor = get_cell(grid, pos[0] + dq, pos[1] + dr)
                if neighbor and neighbor["walls"][OPPOSITE[i]]:
                    asymmetric += 1
    if asymmetric > 0:
        errors.append(f"Wall asymmetry: {asymmetric} one-sided openings")

    passed = len(errors) == 0

    if verbose:
        zone_counts = {SAFE: 0, BLUE: 0, GREEN: 0, RED: 0}
        for pos, cell in grid.items():
            z = cell["zoneType"]
            if z:
                zone_counts[z] = zone_counts.get(z, 0) + 1

        print(f"  Zones: Safe={zone_counts[SAFE]} Blue={zone_counts[BLUE]} Green={zone_counts[GREEN]} Red={zone_counts[RED]}")
        print(f"  Reachable: T0={len(reachable_t0)} T1={len(reachable_t1)} T2={len(reachable_t2)} T3={len(reachable_t3)}/{total}")
        if errors:
            for e in errors:
                print(f"  FAIL: {e}")
        else:
            print("  PASS: All checks passed")

    return passed, errors


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


def main():
    num_tests = 1000
    passed = 0
    failed = 0
    failure_reasons = {}

    print(f"Running {num_tests} hex maze generation tests (radius={HEX_RADIUS})...")
    print("=" * 60)

    for i in range(num_tests):
        grid = generate_maze()
        ok, errors = validate_maze(grid, verbose=False)
        if ok:
            passed += 1
        else:
            failed += 1
            for e in errors:
                key = e.split(":")[0] if ":" in e else e
                failure_reasons[key] = failure_reasons.get(key, 0) + 1
            if failed <= 5:  # Show first 5 failures in detail
                print(f"\n--- FAILURE #{failed} (test {i+1}) ---")
                validate_maze(grid, verbose=True)

    print("\n" + "=" * 60)
    print(f"RESULTS: {passed}/{num_tests} passed ({passed/num_tests*100:.1f}%)")
    if failed > 0:
        print(f"FAILURES: {failed}/{num_tests}")
        print("Failure breakdown:")
        for reason, count in sorted(failure_reasons.items(), key=lambda x: -x[1]):
            print(f"  {reason}: {count}x")
    else:
        print("ALL TESTS PASSED - Hex maze generation is consistently playable!")

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
