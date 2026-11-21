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
diff --git a/src/_pytest/python.py b/src/_pytest/python.py
--- a/src/_pytest/python.py
+++ b/src/_pytest/python.py
@@ -608,10 +608,10 @@ def _importtestmodule(self):
             if e.allow_module_level:
                 raise
             raise self.CollectError(
-                "Using pytest.skip outside of a test is not allowed. "
-                "To decorate a test function, use the @pytest.mark.skip "
-                "or @pytest.mark.skipif decorators instead, and to skip a "
-                "module use `pytestmark = pytest.mark.{skip,skipif}."
+                "Using pytest.skip outside of a test will skip the entire module. "
+                "If that's your intention, pass `allow_module_level=True`. "
+                "If you want to skip a specific test or an entire class, "
+                "use the @pytest.mark.skip or @pytest.mark.skipif decorators."
             ) from e
         self.config.pluginmanager.consider_module(mod)
         return mod

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/testing/test_skipping.py b/testing/test_skipping.py
index 53bf953a8..6ca25cf0a 100755
--- a/testing/test_skipping.py
+++ b/testing/test_skipping.py
@@ -1341,7 +1341,12 @@ def test_module_level_skip_error(pytester: Pytester) -> None:
     )
     result = pytester.runpytest()
     result.stdout.fnmatch_lines(
-        ["*Using pytest.skip outside of a test is not allowed*"]
+        [
+            "*Using pytest.skip outside of a test will skip the entire module. "
+            "If that's your intention, pass `allow_module_level=True`. "
+            "If you want to skip a specific test or an entire class, "
+            "use the @pytest.mark.skip or @pytest.mark.skipif decorators."
+        ]
     )
 
 

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/python\.py)' -m pytest -rA testing/test_skipping.py
cat coverage.cover
git checkout 69356d20cfee9a81972dcbf93d8caf9eabe113e8
git apply /root/pre_state.patch
