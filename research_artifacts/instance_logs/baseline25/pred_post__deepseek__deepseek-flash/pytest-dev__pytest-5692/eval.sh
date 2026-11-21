#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 29e336bd9bf87eaef8e2683196ee1975f1ad4088 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 29e336bd9bf87eaef8e2683196ee1975f1ad4088
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/src/_pytest/junitxml.py b/src/_pytest/junitxml.py
--- a/src/_pytest/junitxml.py
+++ b/src/_pytest/junitxml.py
@@ -10,9 +10,11 @@
 """
 import functools
 import os
+import platform
 import re
 import sys
 import time
+from datetime import datetime
 
 import py
 
@@ -666,6 +668,8 @@ def pytest_sessionfinish(self):
             skipped=self.stats["skipped"],
             tests=numtests,
             time="%.3f" % suite_time_delta,
+            timestamp=datetime.fromtimestamp(self.suite_start_time).isoformat(),
+            hostname=platform.node(),
         )
         logfile.write(Junit.testsuites([suite_node]).unicode(indent=0))
         logfile.close()

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/testing/test_junitxml.py b/testing/test_junitxml.py
index 3196f0ebd..e9dea09af 100755
--- a/testing/test_junitxml.py
+++ b/testing/test_junitxml.py
@@ -1,4 +1,6 @@
 import os
+import platform
+from datetime import datetime
 from xml.dom import minidom
 
 import py
@@ -157,6 +159,26 @@ class TestPython:
         val = tnode["time"]
         assert round(float(val), 2) >= 0.03
 
+    def test_testsuite_hostname_and_timestamp(self, testdir):
+        testdir.makepyfile(
+            """
+            def test_pass():
+                pass
+        """
+        )
+        start_time = datetime.now().replace(microsecond=0)
+        result, dom = runandparse(testdir)
+        end_time = datetime.now()
+
+        assert result.ret == 0
+        node = dom.find_first_by_tag("testsuite")
+        assert node["hostname"] == platform.node()
+
+        timestamp = node["timestamp"]
+        assert timestamp is not None
+        timestamp_dt = datetime.strptime(timestamp[:19], "%Y-%m-%dT%H:%M:%S")
+        assert start_time <= timestamp_dt <= end_time
+
     @pytest.mark.parametrize("duration_report", ["call", "total"])
     def test_junit_duration_report(self, testdir, monkeypatch, duration_report):
 

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/junitxml\.py)' -m pytest -rA testing/test_junitxml.py
cat coverage.cover
git checkout 29e336bd9bf87eaef8e2683196ee1975f1ad4088
git apply /root/pre_state.patch
