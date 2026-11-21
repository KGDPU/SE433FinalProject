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
diff --git a/django/utils/functional.py b/django/utils/functional.py
--- a/django/utils/functional.py
+++ b/django/utils/functional.py
@@ -432,6 +432,12 @@ def __deepcopy__(self, memo):
             return result
         return copy.deepcopy(self._wrapped, memo)
 
+    __add__ = new_method_proxy(operator.add)
+
+    @new_method_proxy
+    def __radd__(self, other):
+        return other + self
+
 
 def partition(predicate, values):
     """

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/tests/utils_tests/test_lazyobject.py b/tests/utils_tests/test_lazyobject.py
index 9ccae595f4..579c8fb725 100755
--- a/tests/utils_tests/test_lazyobject.py
+++ b/tests/utils_tests/test_lazyobject.py
@@ -345,6 +345,23 @@ class SimpleLazyObjectTestCase(LazyObjectTestCase):
         self.assertEqual(str(x), "None")
         self.assertEqual(i, [1])
 
+    def test_radd(self):
+        setup_calls = []
+
+        def setup():
+            setup_calls.append(None)
+            return 1
+
+        obj = SimpleLazyObject(setup)
+        self.assertIs(obj._wrapped, empty)
+        self.assertEqual(1 + obj, 2)
+        self.assertEqual(len(setup_calls), 1)
+        self.assertEqual(1 + obj, 2)
+        self.assertEqual(len(setup_calls), 1)
+        self.assertEqual("a" + self.lazy_wrap("b"), "ab")
+        self.assertEqual([1] + self.lazy_wrap([2]), [1, 2])
+        self.assertEqual(sum([self.lazy_wrap(1), self.lazy_wrap(2)]), 3)
+
     def test_dict(self):
         # See ticket #18447
         lazydict = SimpleLazyObject(lambda: {"one": 1})

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/utils/functional\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 utils_tests.test_lazyobject
cat coverage.cover
git checkout 4c76ffc2d6c77c850b4bef8d9acc197d11c47937
git apply /root/pre_state.patch
