"""
Game Logic Test Suite
Tests the core gameplay systems: PlayerData, orb collection, aura craft/equip,
door access, and scans Lua source for known bug patterns.

Run:  python test_game_logic.py
"""
import os
import re
import sys
import unittest

# ---------------------------------------------------------------------------
# Config mirrors (from GameConfig.lua / AuraData.lua / ZoneTypes.lua)
# ---------------------------------------------------------------------------
STARTING_LUMENS = 100  # TESTING value
BLUE_ORB_VALUE = 1
GREEN_ORB_VALUE = 5
RED_ORB_VALUE = 10

BLUE_AURA_COST = 10
GREEN_AURA_COST = 50
RED_AURA_COST = 100

AURA_TIERS = {"BlueAura": 1, "GreenAura": 2, "RedAura": 3}
ZONE_REQUIRED_AURA = {"Blue": "BlueAura", "Green": "GreenAura", "Red": "RedAura"}

# ---------------------------------------------------------------------------
# Simulated PlayerDataManager (mirrors PlayerDataManager.lua logic)
# ---------------------------------------------------------------------------
class PlayerData:
    """Simulates one player's cached data."""
    def __init__(self, lumens=STARTING_LUMENS):
        self.Wins = 0
        self.Lumens = lumens
        self.Auras = {"BlueAura": False, "GreenAura": False, "RedAura": False}
        self.EquippedAura = None


class PlayerDataManager:
    """Mirrors the server-side PlayerDataManager module."""
    def __init__(self):
        self._cache = {}  # userId -> PlayerData

    def load(self, user_id):
        self._cache[user_id] = PlayerData()
        return self._cache[user_id]

    def get(self, user_id):
        return self._cache.get(user_id)

    def add_lumens(self, user_id, amount):
        d = self._cache[user_id]
        d.Lumens += amount
        return d.Lumens

    def subtract_lumens(self, user_id, amount):
        d = self._cache[user_id]
        if d.Lumens >= amount:
            d.Lumens -= amount
            return True, d.Lumens
        return False, d.Lumens

    def has_aura(self, user_id, aura_name):
        d = self._cache[user_id]
        return d.Auras.get(aura_name, False)

    def give_aura(self, user_id, aura_name):
        d = self._cache[user_id]
        if aura_name in d.Auras:
            d.Auras[aura_name] = True
            return True
        return False

    def set_equipped_aura(self, user_id, aura_name):
        d = self._cache[user_id]
        d.EquippedAura = aura_name
        return True

    def get_equipped_aura(self, user_id):
        d = self._cache.get(user_id)
        return d.EquippedAura if d else None

    def reset_progress(self, user_id):
        d = self._cache[user_id]
        d.Lumens = STARTING_LUMENS
        d.Auras = {"BlueAura": False, "GreenAura": False, "RedAura": False}
        d.EquippedAura = None

    def increment_wins(self, user_id):
        d = self._cache[user_id]
        d.Wins += 1
        return d.Wins


# ---------------------------------------------------------------------------
# Simulated OrbData
# ---------------------------------------------------------------------------
class OrbData:
    def __init__(self, orb_type, value):
        self.Type = orb_type
        self.Value = value
        self.Active = True


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------
AURA_COSTS = {"BlueAura": BLUE_AURA_COST, "GreenAura": GREEN_AURA_COST, "RedAura": RED_AURA_COST}
AURA_NAMES = ["BlueAura", "GreenAura", "RedAura"]
LUA_SRC = os.path.join(os.path.dirname(__file__), "src")


def read_lua(relative_path):
    full = os.path.join(LUA_SRC, relative_path)
    with open(full, encoding="utf-8") as f:
        return f.read()


def can_pass_door(equipped_aura, required_aura):
    """Mirrors DoorController.canPassThrough logic."""
    if required_aura is None:
        return True
    player_tier = AURA_TIERS.get(equipped_aura, 0)
    required_tier = AURA_TIERS.get(required_aura, 1)
    return player_tier >= required_tier


# ===================================================================
# 1. PlayerDataManager logic
# ===================================================================
class TestPlayerDataManager(unittest.TestCase):
    def setUp(self):
        self.mgr = PlayerDataManager()
        self.uid = 12345
        self.mgr.load(self.uid)

    def test_initial_data(self):
        d = self.mgr.get(self.uid)
        self.assertEqual(d.Lumens, STARTING_LUMENS)
        self.assertEqual(d.Wins, 0)
        self.assertIsNone(d.EquippedAura)
        for aura in AURA_NAMES:
            self.assertFalse(d.Auras[aura])

    def test_add_lumens(self):
        total = self.mgr.add_lumens(self.uid, 10)
        self.assertEqual(total, STARTING_LUMENS + 10)

    def test_subtract_lumens_success(self):
        ok, remaining = self.mgr.subtract_lumens(self.uid, 30)
        self.assertTrue(ok)
        self.assertEqual(remaining, STARTING_LUMENS - 30)

    def test_subtract_lumens_insufficient(self):
        ok, remaining = self.mgr.subtract_lumens(self.uid, STARTING_LUMENS + 1)
        self.assertFalse(ok)
        self.assertEqual(remaining, STARTING_LUMENS)

    def test_give_aura(self):
        self.assertTrue(self.mgr.give_aura(self.uid, "BlueAura"))
        self.assertTrue(self.mgr.has_aura(self.uid, "BlueAura"))

    def test_give_invalid_aura(self):
        self.assertFalse(self.mgr.give_aura(self.uid, "PurpleAura"))

    def test_equip_aura(self):
        self.mgr.give_aura(self.uid, "GreenAura")
        self.mgr.set_equipped_aura(self.uid, "GreenAura")
        self.assertEqual(self.mgr.get_equipped_aura(self.uid), "GreenAura")

    def test_switch_equipped_aura(self):
        self.mgr.give_aura(self.uid, "BlueAura")
        self.mgr.give_aura(self.uid, "GreenAura")
        self.mgr.set_equipped_aura(self.uid, "BlueAura")
        self.assertEqual(self.mgr.get_equipped_aura(self.uid), "BlueAura")
        self.mgr.set_equipped_aura(self.uid, "GreenAura")
        self.assertEqual(self.mgr.get_equipped_aura(self.uid), "GreenAura")

    def test_reset_progress_preserves_wins(self):
        self.mgr.add_lumens(self.uid, 500)
        self.mgr.give_aura(self.uid, "RedAura")
        self.mgr.set_equipped_aura(self.uid, "RedAura")
        self.mgr.increment_wins(self.uid)
        self.mgr.reset_progress(self.uid)
        d = self.mgr.get(self.uid)
        self.assertEqual(d.Lumens, STARTING_LUMENS)
        self.assertIsNone(d.EquippedAura)
        self.assertFalse(d.Auras["RedAura"])
        self.assertEqual(d.Wins, 1)


# ===================================================================
# 2. Orb collection logic
# ===================================================================
class TestOrbCollection(unittest.TestCase):
    def setUp(self):
        self.mgr = PlayerDataManager()
        self.uid = 1
        self.mgr.load(self.uid)

    def _collect(self, orb):
        """Simulate OrbManager.CollectOrb server logic."""
        if not orb.Active:
            return False
        orb.Active = False
        self.mgr.add_lumens(self.uid, orb.Value)
        return True

    def test_blue_orb_gives_1_lumen(self):
        orb = OrbData("Blue", BLUE_ORB_VALUE)
        self._collect(orb)
        self.assertEqual(self.mgr.get(self.uid).Lumens, STARTING_LUMENS + 1)

    def test_green_orb_gives_5_lumens(self):
        orb = OrbData("Green", GREEN_ORB_VALUE)
        self._collect(orb)
        self.assertEqual(self.mgr.get(self.uid).Lumens, STARTING_LUMENS + 5)

    def test_red_orb_gives_10_lumens(self):
        orb = OrbData("Red", RED_ORB_VALUE)
        self._collect(orb)
        self.assertEqual(self.mgr.get(self.uid).Lumens, STARTING_LUMENS + 10)

    def test_orb_becomes_inactive_after_collection(self):
        orb = OrbData("Blue", BLUE_ORB_VALUE)
        self._collect(orb)
        self.assertFalse(orb.Active)

    def test_double_collection_prevented(self):
        orb = OrbData("Blue", BLUE_ORB_VALUE)
        self._collect(orb)
        result = self._collect(orb)
        self.assertFalse(result)
        self.assertEqual(self.mgr.get(self.uid).Lumens, STARTING_LUMENS + 1)

    def test_multiple_orbs(self):
        for _ in range(5):
            self._collect(OrbData("Blue", BLUE_ORB_VALUE))
        self.assertEqual(self.mgr.get(self.uid).Lumens, STARTING_LUMENS + 5)


# ===================================================================
# 3. Aura craft / equip flow
# ===================================================================
class TestAuraCraftEquipFlow(unittest.TestCase):
    def setUp(self):
        self.mgr = PlayerDataManager()
        self.uid = 1
        self.mgr.load(self.uid)

    def _craft(self, aura_name):
        """Simulate Server CraftAuraEvent handler."""
        d = self.mgr.get(self.uid)
        cost = AURA_COSTS.get(aura_name)
        if cost is None:
            return False, "invalid aura"
        if d.Auras.get(aura_name):
            return False, "already owned"
        if d.Lumens < cost:
            return False, "insufficient lumens"
        self.mgr.subtract_lumens(self.uid, cost)
        self.mgr.give_aura(self.uid, aura_name)
        self.mgr.set_equipped_aura(self.uid, aura_name)
        return True, "ok"

    def _equip(self, aura_name):
        """Simulate Server EquipAuraEvent handler."""
        if not self.mgr.has_aura(self.uid, aura_name):
            return False, "not owned"
        self.mgr.set_equipped_aura(self.uid, aura_name)
        return True, "ok"

    # -- craft tests --

    def test_craft_blue_aura(self):
        ok, _ = self._craft("BlueAura")
        self.assertTrue(ok)
        d = self.mgr.get(self.uid)
        self.assertTrue(d.Auras["BlueAura"])
        self.assertEqual(d.Lumens, STARTING_LUMENS - BLUE_AURA_COST)

    def test_craft_auto_equips(self):
        self._craft("BlueAura")
        self.assertEqual(self.mgr.get_equipped_aura(self.uid), "BlueAura")

    def test_craft_insufficient_lumens(self):
        self.mgr.get(self.uid).Lumens = 5
        ok, reason = self._craft("BlueAura")
        self.assertFalse(ok)
        self.assertEqual(reason, "insufficient lumens")

    def test_craft_already_owned(self):
        self._craft("BlueAura")
        ok, reason = self._craft("BlueAura")
        self.assertFalse(ok)
        self.assertEqual(reason, "already owned")

    def test_craft_all_three_auras(self):
        self.mgr.get(self.uid).Lumens = 500
        for name in AURA_NAMES:
            ok, _ = self._craft(name)
            self.assertTrue(ok, f"Failed to craft {name}")
        d = self.mgr.get(self.uid)
        for name in AURA_NAMES:
            self.assertTrue(d.Auras[name])
        self.assertEqual(d.EquippedAura, "RedAura")  # last crafted

    # -- equip tests --

    def test_equip_owned_aura(self):
        self._craft("BlueAura")
        ok, _ = self._equip("BlueAura")
        self.assertTrue(ok)
        self.assertEqual(self.mgr.get_equipped_aura(self.uid), "BlueAura")

    def test_equip_unowned_aura(self):
        ok, reason = self._equip("GreenAura")
        self.assertFalse(ok)
        self.assertEqual(reason, "not owned")

    def test_equip_switches_aura(self):
        self.mgr.get(self.uid).Lumens = 200
        self._craft("BlueAura")
        self._craft("GreenAura")
        self._equip("BlueAura")
        self.assertEqual(self.mgr.get_equipped_aura(self.uid), "BlueAura")

    def test_equip_data_sent_to_client(self):
        """After equip, GetData should return updated EquippedAura."""
        self._craft("BlueAura")
        self._equip("BlueAura")
        d = self.mgr.get(self.uid)
        self.assertEqual(d.EquippedAura, "BlueAura")
        self.assertIsNotNone(d.EquippedAura,
            "EquippedAura must not be None when sent via SyncPlayerData")


# ===================================================================
# 4. Door access logic
# ===================================================================
class TestDoorAccess(unittest.TestCase):

    def test_no_aura_cannot_pass_blue_door(self):
        self.assertFalse(can_pass_door(None, "BlueAura"))

    def test_blue_aura_passes_blue_door(self):
        self.assertTrue(can_pass_door("BlueAura", "BlueAura"))

    def test_higher_aura_passes_lower_door(self):
        self.assertTrue(can_pass_door("GreenAura", "BlueAura"))
        self.assertTrue(can_pass_door("RedAura", "BlueAura"))
        self.assertTrue(can_pass_door("RedAura", "GreenAura"))

    def test_lower_aura_cannot_pass_higher_door(self):
        self.assertFalse(can_pass_door("BlueAura", "GreenAura"))
        self.assertFalse(can_pass_door("BlueAura", "RedAura"))
        self.assertFalse(can_pass_door("GreenAura", "RedAura"))

    def test_no_requirement_always_passes(self):
        self.assertTrue(can_pass_door(None, None))
        self.assertTrue(can_pass_door("BlueAura", None))

    def test_escape_and_alternate_always_passable(self):
        """Escape/Alternate doors have no requiredAura (None)."""
        self.assertTrue(can_pass_door(None, None))


# ===================================================================
# 5. Lua source-code pattern checks
# ===================================================================
class TestLuaSourcePatterns(unittest.TestCase):
    """
    Static analysis of the Lua source to detect known anti-patterns
    that cause the reported bugs.
    """

    def test_orb_touch_handler_resolves_character_properly(self):
        """
        BUG: OrbManager Touched handler uses `hit.Parent` directly.
        If an accessory handle triggers the touch, hit.Parent is the
        Accessory, not the Character, so GetPlayerFromCharacter returns nil
        and lumen collection silently fails.

        The handler should walk up to find a Humanoid ancestor, e.g.:
          local character = hit.Parent
          if not character:FindFirstChildOfClass("Humanoid") then
              character = character.Parent
          end
        """
        src = read_lua("server/OrbManager.lua")

        # Find the Touched handler block
        touched_match = re.search(
            r"orbPart\.Touched:Connect\(function\(hit\)(.*?)end\)",
            src, re.DOTALL,
        )
        self.assertIsNotNone(touched_match, "Could not find Touched handler in OrbManager.lua")
        body = touched_match.group(1)

        has_humanoid_check = (
            "FindFirstChildOfClass" in body
            or "FindFirstChild" in body
            or "FindFirstAncestor" in body
            or "Humanoid" in body
        )
        self.assertTrue(
            has_humanoid_check,
            "OrbManager Touched handler does NOT verify hit.Parent is a Character "
            "(missing Humanoid ancestor check). Accessories will prevent collection.",
        )

    def test_crafting_menu_no_handler_accumulation(self):
        """
        BUG: CraftingMenu.UpdateAuraButtons adds a new MouseButton1Click
        handler every time it is called, without disconnecting old ones.
        Combined with the original CRAFT handler from CreateMenu, this
        causes exponential event handler growth on each data sync.

        Expected: handler is connected once, or old connection is
        disconnected before adding a new one.
        """
        src = read_lua("client/CraftingMenu.lua")

        # Count how many times MouseButton1Click:Connect appears
        connects = re.findall(r"MouseButton1Click:Connect", src)

        # CreateMenu legitimately adds one per aura (inside a for-loop).
        # UpdateAuraButtons should NOT add another — it should reuse or
        # disconnect the old handler.
        in_update = re.search(
            r"function CraftingMenu\.UpdateAuraButtons.*?^end",
            src, re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(in_update, "Could not find UpdateAuraButtons")
        update_body = in_update.group(0)

        extra_connects = update_body.count("MouseButton1Click:Connect")
        has_disconnect = "Disconnect" in update_body or ":Destroy" in update_body

        self.assertTrue(
            extra_connects == 0 or has_disconnect,
            f"UpdateAuraButtons adds {extra_connects} new Click handler(s) per call "
            "without disconnecting old ones — causes handler accumulation and "
            "exponential event flood on each data sync.",
        )

    def test_orb_values_match_config(self):
        """Verify OrbManager references GameConfig orb values consistently."""
        src = read_lua("server/OrbManager.lua")
        self.assertIn("GameConfig.BLUE_ORB_VALUE", src)
        self.assertIn("GameConfig.GREEN_ORB_VALUE", src)
        self.assertIn("GameConfig.RED_ORB_VALUE", src)

    def test_aura_costs_match_config(self):
        src = read_lua("shared/AuraData.lua")
        self.assertIn("GameConfig.BLUE_AURA_COST", src)
        self.assertIn("GameConfig.GREEN_AURA_COST", src)
        self.assertIn("GameConfig.RED_AURA_COST", src)

    def test_sync_event_sent_after_equip(self):
        """Server must send SyncPlayerData after equipping so the client updates."""
        src = read_lua("server/Server.server.lua")
        equip_handler = re.search(
            r"EquipAuraEvent\.OnServerEvent:Connect\(function.*?^end\)",
            src, re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(equip_handler, "Could not find equip handler in Server.server.lua")
        body = equip_handler.group(0)
        self.assertIn("SyncPlayerDataEvent:FireClient", body,
            "Equip handler does not send SyncPlayerData back to client")
        self.assertIn("EquipAuraEvent:FireClient", body,
            "Equip handler does not send EquipAura notification to client")

    def test_client_handles_equip_event(self):
        """Client must update HUD when EquipAura event is received."""
        src = read_lua("client/Client.client.lua")
        self.assertIn("EquipAuraEvent.OnClientEvent:Connect", src)
        self.assertIn("UpdateEquippedAura", src)

    def test_hud_handles_nil_aura(self):
        """HUD must gracefully display 'No Aura' when EquippedAura is nil."""
        src = read_lua("client/HUDManager.lua")
        func = re.search(
            r"function HUDManager\.UpdateEquippedAura.*?^end",
            src, re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(func)
        body = func.group(0)
        self.assertIn("No Aura", body,
            "HUDManager.UpdateEquippedAura does not handle nil aura name")

    def test_remote_events_declared_in_project(self):
        """All RemoteEvents used in code must exist in default.project.json."""
        proj_path = os.path.join(os.path.dirname(__file__), "default.project.json")
        with open(proj_path, encoding="utf-8") as f:
            proj = f.read()

        required = [
            "CollectOrb", "CraftAura", "EquipAura",
            "CollectRelic", "TriggerRebirth", "SyncPlayerData", "GetPlayerData",
        ]
        for name in required:
            self.assertIn(f'"{name}"', proj,
                f"RemoteEvent/Function '{name}' missing from default.project.json")


# ===================================================================
# Runner
# ===================================================================
if __name__ == "__main__":
    # Nice summary header
    print("=" * 64)
    print("  Aura Maze — Game Logic Test Suite")
    print("=" * 64)
    result = unittest.main(verbosity=2, exit=False)
    sys.exit(0 if result.result.wasSuccessful() else 1)
