#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c5cef2499d6eed024b0db5c792d6ec7c53baa470 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c5cef2499d6eed024b0db5c792d6ec7c53baa470
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/tensor/array/tests/test_ndim_array.py b/sympy/tensor/array/tests/test_ndim_array.py
index f0732fd7c7..f1641d40ad 100755
--- a/sympy/tensor/array/tests/test_ndim_array.py
+++ b/sympy/tensor/array/tests/test_ndim_array.py
@@ -50,3 +50,41 @@ def test_issue_20222():
     A = Array([[1, 2], [3, 4]])
     B = Matrix([[1,2],[3,4]])
     raises(TypeError, lambda: A - B)
+
+
+def test_empty_array_construction():
+    # An empty iterable has rank one and zero elements, just like the
+    # explicitly shaped array Array([], (0,)).
+    for empty in ([], (), range(0)):
+        array = Array(empty)
+        assert array.shape == (0,)
+        assert array.rank() == 1
+        assert len(array) == 0
+        assert array.tolist() == []
+
+    # Empty dimensions can also occur as inner dimensions of nested data.
+    for ArrayType in array_types:
+        array = ArrayType([[]])
+        assert array.shape == (1, 0)
+        assert array.rank() == 2
+        assert array.tolist() == [[]]
+
+        array = ArrayType([[], []])
+        assert array.shape == (2, 0)
+        assert array.rank() == 2
+        assert array.tolist() == [[], []]
+
+        array = ArrayType([[[], []], [[], []]])
+        assert array.shape == (2, 2, 0)
+        assert array.rank() == 3
+        assert array.tolist() == [[[], []], [[], []]]
+
+        # Slicing to an empty result should construct an empty array too.
+        empty_slice = ArrayType([1, 2, 3])[1:1]
+        assert empty_slice.shape == (0,)
+        assert empty_slice.rank() == 1
+        assert empty_slice.tolist() == []
+
+        # Combining empty and non-empty sublists is still ambiguous.
+        raises(ValueError, lambda: ArrayType([[], [1]]))
+        raises(ValueError, lambda: ArrayType([[1], []]))

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/tensor/array/ndim_array\.py)' bin/test -C --verbose sympy/tensor/array/tests/test_ndim_array.p
cat coverage.cover
git checkout c5cef2499d6eed024b0db5c792d6ec7c53baa470
git apply /root/pre_state.patch
