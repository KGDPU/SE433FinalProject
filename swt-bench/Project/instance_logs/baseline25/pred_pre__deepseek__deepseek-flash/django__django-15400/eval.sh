#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 4c76ffc2d6c77c850b4bef8d9acc197d11c47937 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 4c76ffc2d6c77c850b4bef8d9acc197d11c47937
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/tests/utils_tests/test_lazyobject.py b/tests/utils_tests/test_lazyobject.py
index 9ccae595f4..ad4db600ab 100755
--- a/tests/utils_tests/test_lazyobject.py
+++ b/tests/utils_tests/test_lazyobject.py
@@ -317,6 +317,10 @@ class SimpleLazyObjectTestCase(LazyObjectTestCase):
         self.assertIsInstance(obj._wrapped, int)
         self.assertEqual(repr(obj), "<SimpleLazyObject: 42>")
 
+    def test_radd(self):
+        obj1 = self.lazy_wrap(1)
+        self.assertEqual(1 + obj1, 2)
+
     def test_trace(self):
         # See ticket #19456
         old_trace_func = sys.gettrace()

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/utils/functional\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 utils_tests.test_lazyobject
cat coverage.cover
git checkout 4c76ffc2d6c77c850b4bef8d9acc197d11c47937
git apply /root/pre_state.patch
