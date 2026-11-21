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
index f0732fd7c7..9768bb84b5 100755
--- a/sympy/tensor/array/tests/test_ndim_array.py
+++ b/sympy/tensor/array/tests/test_ndim_array.py
@@ -50,3 +50,11 @@ def test_issue_20222():
     A = Array([[1, 2], [3, 4]])
     B = Matrix([[1,2],[3,4]])
     raises(TypeError, lambda: A - B)
+
+
+def test_issue_17851():
+    for array_type in array_types:
+        A = array_type([])
+        assert isinstance(A, array_type)
+        assert A.shape == (0,)
+        assert list(A) == []

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/tensor/array/ndim_array\.py)' bin/test -C --verbose sympy/tensor/array/tests/test_ndim_array.p
cat coverage.cover
git checkout c5cef2499d6eed024b0db5c792d6ec7c53baa470
git apply /root/pre_state.patch
