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
diff --git a/testing/test_junitxml.py b/testing/test_junitxml.py
index 3196f0ebd..5b1ef37d7 100755
--- a/testing/test_junitxml.py
+++ b/testing/test_junitxml.py
@@ -1,4 +1,6 @@
+import datetime
 import os
+import socket
 from xml.dom import minidom
 
 import py
@@ -1118,6 +1120,32 @@ def test_root_testsuites_tag(testdir):
     assert suite_node.tag == "testsuite"
 
 
+@pytest.mark.parametrize("num_tests", [0, 1, 2])
+def test_testsuite_hostname_and_timestamp(testdir, num_tests):
+    source = "\n".join("def test_{}(): pass".format(i) for i in range(num_tests))
+    testdir.makepyfile(source)
+    start = datetime.datetime.now()
+    _, dom = runandparse(testdir)
+    end = datetime.datetime.now()
+
+    suite_node = dom.find_first_by_tag("testsuite")
+    suite_node.assert_attr(hostname=socket.gethostname())
+
+    timestamp = suite_node["timestamp"]
+    assert timestamp is not None
+    try:
+        parsed_timestamp = datetime.datetime.strptime(
+            timestamp, "%Y-%m-%dT%H:%M:%S.%f"
+        )
+    except ValueError:
+        parsed_timestamp = datetime.datetime.strptime(timestamp, "%Y-%m-%dT%H:%M:%S")
+
+    # The timestamp should record when this test run started, in local time.
+    # Allow for implementations which only include second-level precision.
+    tolerance = datetime.timedelta(seconds=1)
+    assert start - tolerance <= parsed_timestamp <= end + tolerance
+
+
 def test_runs_twice(testdir):
     f = testdir.makepyfile(
         """

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/junitxml\.py)' -m pytest -rA testing/test_junitxml.py
cat coverage.cover
git checkout 29e336bd9bf87eaef8e2683196ee1975f1ad4088
git apply /root/pre_state.patch
