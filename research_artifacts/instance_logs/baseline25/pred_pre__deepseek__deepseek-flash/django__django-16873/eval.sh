#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD fce90950bef348803fa7cc3e6bc65f4bce429b82 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff fce90950bef348803fa7cc3e6bc65f4bce429b82
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/tests/template_tests/filter_tests/test_join.py b/tests/template_tests/filter_tests/test_join.py
index 08f68537ee..1be4908eac 100755
--- a/tests/template_tests/filter_tests/test_join.py
+++ b/tests/template_tests/filter_tests/test_join.py
@@ -55,6 +55,13 @@ class JoinTests(SimpleTestCase):
         )
         self.assertEqual(output, "alpha & beta &amp; me")
 
+    @setup({"join09": "{% autoescape off %}{{ a|join:var }}{% endautoescape %}"})
+    def test_join09(self):
+        output = self.engine.render_to_string(
+            "join09", {"a": ["alpha", "beta & me"], "var": " & "}
+        )
+        self.assertEqual(output, "alpha & beta & me")
+
 
 class FunctionTests(SimpleTestCase):
     def test_list(self):
@@ -69,7 +76,7 @@ class FunctionTests(SimpleTestCase):
     def test_autoescape_off(self):
         self.assertEqual(
             join(["<a>", "<img>", "</a>"], "<br>", autoescape=False),
-            "<a>&lt;br&gt;<img>&lt;br&gt;</a>",
+            "<a><br><img><br></a>",
         )
 
     def test_noniterable_arg(self):

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/template/defaultfilters\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 template_tests.filter_tests.test_join
cat coverage.cover
git checkout fce90950bef348803fa7cc3e6bc65f4bce429b82
git apply /root/pre_state.patch
