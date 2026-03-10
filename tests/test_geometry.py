"""
Hex Maze Geometry Test
Validates that the physical world geometry (walls, doors) is consistent
with the maze grid data. Catches bugs like:
- WALL_EDGE mapping placing walls on wrong hex edges
- Walls and doors overlapping on the same edge
- Door positions not matching the edge between two cells
"""
import math
import sys

from maze_utils import (
    DIRECTIONS, OPPOSITE, TIER, WALL_EDGE,
    HEX_RADIUS, ZONE_SIZE,
    get_cell, generate_maze,
    hex_to_world, hex_corners, wall_edge_midpoint, door_midpoint,
)

# Tolerance for floating-point position comparisons
EPSILON = 0.5


def positions_match(p1, p2):
    """Check if two (x, z) positions are close enough to be the same edge."""
    return abs(p1[0] - p2[0]) < EPSILON and abs(p1[1] - p2[1]) < EPSILON


def round_pos(x, z):
    """Round position to a grid key for set lookups."""
    return (round(x, 1), round(z, 1))


def validate_wall_edge_mapping():
    """Verify WALL_EDGE correctness: for each direction, the wall edge midpoint
    of a cell must coincide with the wall edge midpoint of its neighbor
    (viewed from the opposite direction). This ensures shared edges align.
    """
    errors = []
    q, r = 0, 0

    for i, (dq, dr) in enumerate(DIRECTIONS):
        nq, nr = q + dq, r + dr

        # Wall midpoint from cell side
        cell_mid = wall_edge_midpoint(q, r, i)
        # Wall midpoint from neighbor side (opposite direction)
        neighbor_mid = wall_edge_midpoint(nq, nr, OPPOSITE[i])

        if not positions_match(cell_mid, neighbor_mid):
            errors.append(
                f"WALL_EDGE mismatch dir {i}: cell wall at ({cell_mid[0]:.2f}, {cell_mid[1]:.2f}) "
                f"vs neighbor wall at ({neighbor_mid[0]:.2f}, {neighbor_mid[1]:.2f})"
            )

    return errors


def validate_wall_edge_on_boundary():
    """Verify that each wall edge midpoint lies on the actual boundary between
    a cell and its neighbor (i.e. coincides with the midpoint between cell centers
    projected onto the shared edge).
    """
    errors = []
    q, r = 0, 0

    for i, (dq, dr) in enumerate(DIRECTIONS):
        nq, nr = q + dq, r + dr

        wall_mid = wall_edge_midpoint(q, r, i)
        door_mid = door_midpoint(q, r, nq, nr)

        # The wall midpoint should lie on the line perpendicular to the cell-to-neighbor
        # direction, passing through the midpoint between cell centers.
        # Since hex edges are perpendicular to the cell-neighbor line, the wall midpoint's
        # projection onto that line should equal the midpoint between centers.
        cx, cz = hex_to_world(q, r)
        nx, nz = hex_to_world(nq, nr)
        dx, dz = nx - cx, nz - cz
        length = math.sqrt(dx * dx + dz * dz)
        if length == 0:
            continue

        # Project wall_mid onto the cell-to-neighbor line
        wx, wz = wall_mid[0] - cx, wall_mid[1] - cz
        t = (wx * dx + wz * dz) / (length * length)

        # t should be ~0.5 (halfway between centers)
        if abs(t - 0.5) > 0.05:
            errors.append(
                f"Dir {i}: wall edge not on boundary (t={t:.3f}, expected ~0.5)"
            )

    return errors


def validate_no_wall_door_overlap(grid):
    """For a generated maze, verify that no edge has both a wall part and a door.
    - Walls exist where cell.walls[i] == True
    - Doors exist where cell.walls[i] == False AND zones differ (directions 0-2 only,
      matching DoorController which checks first 3 directions)
    """
    errors = []
    wall_positions = set()
    door_positions = set()

    for pos, cell in grid.items():
        q, r = pos

        for i in range(6):
            dq, dr = DIRECTIONS[i]
            nq, nr = q + dq, r + dr
            neighbor = get_cell(grid, nq, nr)
            if not neighbor:
                continue

            if cell["walls"][i]:
                wp = wall_edge_midpoint(q, r, i)
                wall_positions.add(round_pos(wp[0], wp[1]))

        # DoorController only iterates directions 0-2 to avoid duplicates
        for i in range(3):
            if not cell["walls"][i]:
                dq, dr = DIRECTIONS[i]
                nq, nr = q + dq, r + dr
                neighbor = get_cell(grid, nq, nr)
                if neighbor and cell["zoneType"] != neighbor["zoneType"]:
                    dp = door_midpoint(q, r, nq, nr)
                    door_positions.add(round_pos(dp[0], dp[1]))

    overlap = wall_positions & door_positions
    if overlap:
        errors.append(f"Wall-door overlap at {len(overlap)} positions: {list(overlap)[:5]}")

    return errors


def validate_door_on_correct_edge(grid):
    """Verify that each door's position (midpoint between cell centers) matches
    the wall edge midpoint for that direction. If these don't match, walls and
    doors are on different edges even though they represent the same boundary.
    """
    errors = []

    for pos, cell in grid.items():
        q, r = pos
        for i in range(3):
            if not cell["walls"][i]:
                dq, dr = DIRECTIONS[i]
                nq, nr = q + dq, r + dr
                neighbor = get_cell(grid, nq, nr)
                if neighbor and cell["zoneType"] != neighbor["zoneType"]:
                    dp = door_midpoint(q, r, nq, nr)
                    wp = wall_edge_midpoint(q, r, i)
                    if not positions_match(dp, wp):
                        errors.append(
                            f"Cell ({q},{r}) dir {i}: door at ({dp[0]:.1f},{dp[1]:.1f}) "
                            f"vs wall edge at ({wp[0]:.1f},{wp[1]:.1f})"
                        )
    return errors


def main():
    all_errors = []

    # Static checks (no maze needed)
    print("1. Validating WALL_EDGE mapping symmetry...")
    errs = validate_wall_edge_mapping()
    all_errors.extend(errs)
    print(f"   {'PASS' if not errs else 'FAIL: ' + str(errs)}")

    print("2. Validating wall edges lie on cell boundaries...")
    errs = validate_wall_edge_on_boundary()
    all_errors.extend(errs)
    print(f"   {'PASS' if not errs else 'FAIL: ' + str(errs)}")

    # Dynamic checks across many generated mazes
    num_tests = 200
    print(f"3. Validating no wall-door overlap ({num_tests} mazes)...")
    overlap_failures = 0
    for _ in range(num_tests):
        grid = generate_maze()
        errs = validate_no_wall_door_overlap(grid)
        if errs:
            overlap_failures += 1
            if overlap_failures <= 3:
                for e in errs:
                    print(f"   FAIL: {e}")
    print(f"   {'PASS' if overlap_failures == 0 else f'FAIL: {overlap_failures}/{num_tests} mazes had overlaps'}")
    if overlap_failures:
        all_errors.append(f"Wall-door overlap in {overlap_failures}/{num_tests} mazes")

    print(f"4. Validating door positions match wall edges ({num_tests} mazes)...")
    mismatch_failures = 0
    for _ in range(num_tests):
        grid = generate_maze()
        errs = validate_door_on_correct_edge(grid)
        if errs:
            mismatch_failures += 1
            if mismatch_failures <= 3:
                for e in errs[:3]:
                    print(f"   FAIL: {e}")
    print(f"   {'PASS' if mismatch_failures == 0 else f'FAIL: {mismatch_failures}/{num_tests} mazes had mismatches'}")
    if mismatch_failures:
        all_errors.append(f"Door-edge mismatch in {mismatch_failures}/{num_tests} mazes")

    print()
    print("=" * 60)
    if all_errors:
        print(f"FAILED - {len(all_errors)} error(s):")
        for e in all_errors:
            print(f"  {e}")
        return 1
    else:
        print("ALL GEOMETRY TESTS PASSED")
        return 0


if __name__ == "__main__":
    sys.exit(main())
