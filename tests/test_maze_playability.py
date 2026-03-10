"""
Hex Maze Playability Test
Validates that generated hex mazes are consistently playable:
- Zone reachability with tiered auras
- No isolated cells
- Full connectivity
- Wall symmetry
"""
import sys
from collections import deque

from maze_utils import (
    DIRECTIONS, OPPOSITE, TIER,
    SAFE, BLUE, GREEN, RED,
    HEX_RADIUS, get_cell, generate_maze,
)


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
            if failed <= 5:
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
