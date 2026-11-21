#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d4d5427571b4bf3a21c902276c2a00215c2a37cc >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d4d5427571b4bf3a21c902276c2a00215c2a37cc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/tests/utils_tests/test_html.py b/tests/utils_tests/test_html.py
index 22a43fd4cd..43ba5e311b 100755
--- a/tests/utils_tests/test_html.py
+++ b/tests/utils_tests/test_html.py
@@ -1,3 +1,4 @@
+import json
 import os
 from datetime import datetime
 
@@ -217,6 +218,29 @@ class TestUtilsHtml(SimpleTestCase):
             '<script type="application/json">{"key": "value"}</script>',
         )
 
+    def test_json_script_custom_encoder(self):
+        class CustomEncoder(json.JSONEncoder):
+            def default(self, obj):
+                if isinstance(obj, set):
+                    return sorted(obj)
+                return super().default(obj)
+
+        self.assertEqual(
+            json_script(
+                {"value": {"b", "a", "<", "&"}},
+                "test_id",
+                encoder=CustomEncoder,
+            ),
+            '<script id="test_id" type="application/json">'
+            '{"value": ["\\u0026", "\\u003C", "a", "b"]}</script>',
+        )
+
+    def test_json_script_encoder_none_uses_default_encoder(self):
+        self.assertHTMLEqual(
+            json_script({"key": "value"}, encoder=None),
+            '<script type="application/json">{"key": "value"}</script>',
+        )
+
     def test_smart_urlquote(self):
         items = (
             ("http://öäü.com/", "http://xn--4ca9at.com/"),

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/utils/html\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 utils_tests.test_html
cat coverage.cover
git checkout d4d5427571b4bf3a21c902276c2a00215c2a37cc
git apply /root/pre_state.patch
