#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 69356d20cfee9a81972dcbf93d8caf9eabe113e8 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 69356d20cfee9a81972dcbf93d8caf9eabe113e8
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/testing/test_skipping.py b/testing/test_skipping.py
index 53bf953a8..01d43aa2a 100755
--- a/testing/test_skipping.py
+++ b/testing/test_skipping.py
@@ -1329,7 +1329,7 @@ def test_xfail_item(pytester: Pytester) -> None:
 
 
 def test_module_level_skip_error(pytester: Pytester) -> None:
-    """Verify that using pytest.skip at module level causes a collection error."""
+    """Using pytest.skip at module level points users to allow_module_level."""
     pytester.makepyfile(
         """
         import pytest
@@ -1340,8 +1340,13 @@ def test_module_level_skip_error(pytester: Pytester) -> None:
     """
     )
     result = pytester.runpytest()
-    result.stdout.fnmatch_lines(
-        ["*Using pytest.skip outside of a test is not allowed*"]
+    stdout = result.stdout.str()
+    assert (
+        "Using pytest.skip outside of a test will skip the entire module" in stdout
+    )
+    assert "If that's your intention, pass `allow_module_level=True`" in stdout
+    assert (
+        "use the @pytest.mark.skip or @pytest.mark.skipif decorators" in stdout
     )
 
 

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/python\.py)' -m pytest -rA testing/test_skipping.py
cat coverage.cover
git checkout 69356d20cfee9a81972dcbf93d8caf9eabe113e8
git apply /root/pre_state.patch
