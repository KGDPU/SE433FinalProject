#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD fb59d703e6863ed803c98177b59197b5513332e9 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff fb59d703e6863ed803c98177b59197b5513332e9
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/printing/tests/test_latex.py b/sympy/printing/tests/test_latex.py
index 9f644f15e..5fae58e05 100755
--- a/sympy/printing/tests/test_latex.py
+++ b/sympy/printing/tests/test_latex.py
@@ -1395,6 +1395,13 @@ def test_Tr():
     assert latex(t) == r'\mbox{Tr}\left(A B\right)'
 
 
+def test_Trace():
+    from sympy.matrices import MatrixSymbol, Trace
+    A = MatrixSymbol("A", 3, 3)
+    assert latex(Trace(A)) == r"\operatorname{tr}\left(A\right)"
+    assert latex(Trace(A**2)) == r"\operatorname{tr}\left(A^{2}\right)"
+
+
 def test_Adjoint():
     from sympy.matrices import MatrixSymbol, Adjoint, Inverse, Transpose
     X = MatrixSymbol('X', 2, 2)

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/latex\.py)' bin/test -C --verbose sympy/printing/tests/test_latex.p
cat coverage.cover
git checkout fb59d703e6863ed803c98177b59197b5513332e9
git apply /root/pre_state.patch
