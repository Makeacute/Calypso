from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[2]
TOOL = REPOSITORY / "tools" / "calypso-migrate-settings"
FIXTURES = Path(__file__).with_name("fixtures")


class MigrationCliTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def copy_fixture(self, name: str, target_name: str = "settings.json") -> Path:
        target = self.directory / target_name
        shutil.copyfile(FIXTURES / name, target)
        return target

    def run_tool(
        self,
        settings: Path,
        *arguments: str | Path,
    ) -> tuple[subprocess.CompletedProcess[str], dict]:
        command = [str(TOOL), str(settings), *(str(value) for value in arguments)]
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(completed.stderr, "")
        try:
            result = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            self.fail(f"stdout was not one JSON result: {error}: {completed.stdout!r}")
        self.assertIsInstance(result, dict)
        return completed, result

    def backup_files(self) -> list[Path]:
        return sorted(self.directory.glob("settings.v3.*.json"))

    def test_current_v4_example_is_canonical_and_byte_preserving(self) -> None:
        settings = self.directory / "settings.json"
        shutil.copyfile(REPOSITORY / "settings.example.json", settings)
        original = settings.read_bytes()

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        self.assertEqual(result["status"], "noop")
        self.assertEqual(result["backup"], None)
        self.assertEqual(settings.read_bytes(), original)
        migrated = json.loads(settings.read_text())
        self.assertEqual(
            list(migrated),
            [
                "app",
                "bar",
                "migration",
                "modules",
                "panels",
                "services",
                "theme",
                "ui",
                "version",
            ],
        )
        self.assertEqual(migrated["version"], 4)
        self.assertEqual(migrated["bar"]["height"], 26)
        self.assertEqual(migrated["bar"]["position"], "top")
        self.assertEqual(migrated["theme"]["fontFamilyMono"], "JetBrainsMono Nerd Font")
        self.assertEqual(migrated["services"]["compositor"]["backend"], "auto")
        self.assertEqual(
            migrated["services"]["polling"]["cpuMs"],
            13000,
        )
        self.assertEqual(migrated["panels"]["launcher"]["maxResults"], 12)
        self.assertEqual(migrated["panels"]["notifications"]["showActions"], True)
        self.assertEqual(migrated["modules"]["left"][0], "media")
        self.assertEqual(migrated["modules"]["center"][0], "clock")
        self.assertEqual(migrated["modules"]["instances"]["audio"]["type"], "audio")
        self.assertEqual(
            migrated["modules"]["instances"]["audio"]["settings"],
            {"showDeviceName": False, "showPercentage": True},
        )
        self.assertEqual(
            migrated["modules"]["instances"]["workspaces"]["settings"]["maxAppIcons"],
            4,
        )
        self.assertEqual(migrated["migration"]["unmapped"], {})
        serialized = json.dumps(migrated)
        self.assertNotIn("moduleRegistry", serialized)
        self.assertNotIn("availableModules", serialized)
        self.assertNotIn("themeRecipes", serialized)

    def test_migrates_current_settings_shape_without_unmapped_keys(self) -> None:
        settings = self.directory / "settings.json"
        shutil.copyfile(REPOSITORY / "settings.json", settings)

        completed, _ = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        migrated = json.loads(settings.read_text())
        self.assertEqual(migrated["version"], 4)
        self.assertEqual(migrated["migration"]["unmapped"], {})

    def test_creates_timestamped_same_directory_backup_with_original_bytes(self) -> None:
        settings = self.copy_fixture("v3-duplicates-aliases.json")
        original = settings.read_bytes()

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        backups = self.backup_files()
        self.assertEqual(len(backups), 1)
        self.assertRegex(
            backups[0].name,
            r"^settings\.v3\.\d{8}T\d{12}Z\.json$",
        )
        self.assertEqual(backups[0].read_bytes(), original)
        self.assertEqual(Path(result["backup"]), backups[0])
        self.assertEqual(list(self.directory.glob(".*.tmp")), [])

    def test_canonicalizes_aliases_and_suffixes_duplicates_deterministically(self) -> None:
        settings = self.copy_fixture("v3-duplicates-aliases.json")

        completed, _ = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        migrated = json.loads(settings.read_text())
        modules = migrated["modules"]
        self.assertEqual(modules["left"], ["memory", "memory-2", "dashboard"])
        self.assertEqual(modules["center"], ["clock", "clock-2"])
        self.assertEqual(
            modules["right"],
            ["audio", "audio-2", "media", "media-2"],
        )
        self.assertEqual(
            modules["instances"]["memory"],
            {
                "type": "memory",
                "enabled": True,
                "settings": {"showGraph": True},
            },
        )
        self.assertEqual(modules["instances"]["memory-2"], modules["instances"]["memory"])
        self.assertTrue(modules["instances"]["dashboard"]["enabled"])
        self.assertFalse(modules["instances"]["clock"]["enabled"])
        self.assertTrue(modules["instances"]["media-2"]["enabled"])
        self.assertEqual(
            migrated["panels"]["dashboard"]["performanceModules"],
            ["memory", "network", "battery"],
        )
        self.assertEqual(
            migrated["migration"]["unmapped"],
            {"futureSetting": {"enabled": True}},
        )

    def test_instance_ids_do_not_collide_with_suffix_shaped_module_types(self) -> None:
        settings = self.directory / "settings.json"
        settings.write_text(
            json.dumps(
                {
                    "version": 3,
                    "leftModules": ["memory", "memory", "memory-2"],
                }
            )
        )

        completed, _ = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        migrated = json.loads(settings.read_text())
        self.assertEqual(
            migrated["modules"]["left"],
            ["memory", "memory-2", "memory-2-2"],
        )
        self.assertEqual(
            migrated["modules"]["instances"]["memory-2-2"]["type"],
            "memory-2",
        )

    def test_unknown_keys_are_preserved_in_unmapped(self) -> None:
        settings = self.directory / "settings.json"
        original = {
            "version": 3,
            "leftModules": [],
            "newScalar": 42,
            "newObject": {"nested": ["value"]},
        }
        settings.write_text(json.dumps(original))

        completed, _ = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        migrated = json.loads(settings.read_text())
        self.assertEqual(
            migrated["migration"]["unmapped"],
            {"newObject": {"nested": ["value"]}, "newScalar": 42},
        )

    def test_v4_is_a_byte_preserving_noop_without_backup(self) -> None:
        settings = self.copy_fixture("v4.json")
        original = settings.read_bytes()

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        self.assertEqual(result["status"], "noop")
        self.assertEqual(result["backup"], None)
        self.assertEqual(settings.read_bytes(), original)
        self.assertEqual(self.backup_files(), [])

    def test_second_migration_is_idempotent(self) -> None:
        settings = self.copy_fixture("v3-duplicates-aliases.json")
        first_completed, _ = self.run_tool(settings)
        first_bytes = settings.read_bytes()
        first_backups = self.backup_files()

        second_completed, second_result = self.run_tool(settings)

        self.assertEqual(first_completed.returncode, 0)
        self.assertEqual(second_completed.returncode, 0)
        self.assertEqual(second_result["status"], "noop")
        self.assertEqual(settings.read_bytes(), first_bytes)
        self.assertEqual(self.backup_files(), first_backups)

    def test_rollback_restores_exact_backup_and_is_idempotent(self) -> None:
        settings = self.copy_fixture("v3-duplicates-aliases.json")
        original = settings.read_bytes()
        migrated_completed, migrated_result = self.run_tool(settings)
        backup = Path(migrated_result["backup"])

        rollback_completed, rollback_result = self.run_tool(
            settings,
            "--rollback",
            backup,
        )

        self.assertEqual(migrated_completed.returncode, 0)
        self.assertEqual(rollback_completed.returncode, 0)
        self.assertEqual(rollback_result["status"], "rolled_back")
        self.assertEqual(settings.read_bytes(), original)

        repeated_completed, repeated_result = self.run_tool(
            settings,
            "--rollback",
            backup,
        )
        self.assertEqual(repeated_completed.returncode, 0)
        self.assertEqual(repeated_result["status"], "noop")
        self.assertEqual(settings.read_bytes(), original)

    def test_rejects_malformed_json_without_backup_or_write(self) -> None:
        settings = self.copy_fixture("malformed.json")
        original = settings.read_bytes()

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 2)
        self.assertFalse(result["ok"])
        self.assertEqual(result["error"], "malformed_json")
        self.assertEqual(settings.read_bytes(), original)
        self.assertEqual(self.backup_files(), [])

    def test_rejects_malformed_module_shape(self) -> None:
        settings = self.directory / "settings.json"
        original = b'{"version": 3, "leftModules": "clock"}\n'
        settings.write_bytes(original)

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 2)
        self.assertEqual(result["error"], "malformed_settings")
        self.assertEqual(settings.read_bytes(), original)
        self.assertEqual(self.backup_files(), [])

    def test_rejects_unsupported_version_without_backup_or_write(self) -> None:
        settings = self.copy_fixture("unsupported-version.json")
        original = settings.read_bytes()

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 2)
        self.assertEqual(result["error"], "unsupported_version")
        self.assertEqual(settings.read_bytes(), original)
        self.assertEqual(self.backup_files(), [])

    def test_rejects_non_integer_version(self) -> None:
        settings = self.directory / "settings.json"
        original = b'{"version": "3", "leftModules": []}\n'
        settings.write_bytes(original)

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 2)
        self.assertEqual(result["error"], "unsupported_version")
        self.assertEqual(settings.read_bytes(), original)
        self.assertEqual(self.backup_files(), [])

    def test_rejects_rollback_from_non_v3_backup(self) -> None:
        settings = self.copy_fixture("v3-duplicates-aliases.json")
        original = settings.read_bytes()
        backup = FIXTURES / "v4.json"

        completed, result = self.run_tool(settings, "--rollback", backup)

        self.assertEqual(completed.returncode, 2)
        self.assertEqual(result["error"], "unsupported_version")
        self.assertEqual(settings.read_bytes(), original)

    def test_executable_and_result_paths_are_absolute(self) -> None:
        self.assertTrue(TOOL.stat().st_mode & 0o111)
        settings = self.copy_fixture("v4.json")

        completed, result = self.run_tool(settings)

        self.assertEqual(completed.returncode, 0)
        self.assertTrue(Path(result["path"]).is_absolute())
        self.assertIsNone(result["backup"])


if __name__ == "__main__":
    unittest.main()
