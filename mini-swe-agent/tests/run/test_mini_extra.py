import os
import subprocess
import sys
from pathlib import Path

import pytest


@pytest.mark.parametrize(("args", "expected_returncode"), [(["--unknown-option"], 2), (["swe-bnech"], 2), ([], 0), (["-h"], 0)])
def test_mini_extra_exit_status(args, expected_returncode, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "minisweagent.run.utilities.mini_extra", *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=15,
        env=os.environ | {"MSWEA_GLOBAL_CONFIG_DIR": str(tmp_path), "MSWEA_SILENT_STARTUP": "1", "NO_COLOR": "1"},
    )
    assert result.returncode == expected_returncode
    if expected_returncode:
        assert f"Unknown command: {args[0]}" in result.stderr
    else:
        assert "Available sub-commands:" in result.stdout
        assert not result.stderr


def test_known_command_still_dispatches(tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "minisweagent.run.utilities.mini_extra", "config", "--help"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=15,
        env=os.environ | {"MSWEA_GLOBAL_CONFIG_DIR": str(tmp_path), "MSWEA_SILENT_STARTUP": "1", "NO_COLOR": "1"},
    )
    assert result.returncode == 0
    assert "Usage: mini-extra config" in result.stdout
    assert not result.stderr
