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
diff --git a/django/utils/html.py b/django/utils/html.py
--- a/django/utils/html.py
+++ b/django/utils/html.py
@@ -59,7 +59,7 @@ def escapejs(value):
 }
 
 
-def json_script(value, element_id=None):
+def json_script(value, element_id=None, encoder=None):
     """
     Escape all the HTML/XML special characters with their unicode escapes, so
     value is safe to be output anywhere except for inside a tag attribute. Wrap
@@ -67,7 +67,9 @@ def json_script(value, element_id=None):
     """
     from django.core.serializers.json import DjangoJSONEncoder
 
-    json_str = json.dumps(value, cls=DjangoJSONEncoder).translate(_json_script_escapes)
+    json_str = json.dumps(value, cls=encoder or DjangoJSONEncoder).translate(
+        _json_script_escapes
+    )
     if element_id:
         template = '<script id="{}" type="application/json">{}</script>'
         args = (element_id, mark_safe(json_str))

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/tests/utils_tests/test_html.py b/tests/utils_tests/test_html.py
index 22a43fd4cd..a2d4854a94 100755
--- a/tests/utils_tests/test_html.py
+++ b/tests/utils_tests/test_html.py
@@ -1,3 +1,4 @@
+import json
 import os
 from datetime import datetime
 
@@ -217,6 +218,18 @@ class TestUtilsHtml(SimpleTestCase):
             '<script type="application/json">{"key": "value"}</script>',
         )
 
+    def test_json_script_with_custom_encoder(self):
+        class CustomEncoder(json.JSONEncoder):
+            def default(self, obj):
+                if isinstance(obj, set):
+                    return sorted(obj)
+                return super().default(obj)
+
+        self.assertEqual(
+            json_script({"key": {"b", "a"}}, encoder=CustomEncoder),
+            '<script type="application/json">{"key": ["a", "b"]}</script>',
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
