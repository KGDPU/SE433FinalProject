#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b4777fdcef467b7132c055f8ac2c9a5059e6a145 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b4777fdcef467b7132c055f8ac2c9a5059e6a145
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/printing/str.py b/sympy/printing/str.py
--- a/sympy/printing/str.py
+++ b/sympy/printing/str.py
@@ -333,7 +333,7 @@ def apow(i):
                     b.append(apow(item))
                 else:
                     if (len(item.args[0].args) != 1 and
-                            isinstance(item.base, Mul)):
+                            isinstance(item.base, (Mul, Pow))):
                         # To avoid situations like #14160
                         pow_paren.append(item)
                     b.append(item.base)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/printing/tests/test_str.py b/sympy/printing/tests/test_str.py
index 690b1a8bbf..68c7d63769 100755
--- a/sympy/printing/tests/test_str.py
+++ b/sympy/printing/tests/test_str.py
@@ -252,6 +252,8 @@ def test_Mul():
     # For issue 14160
     assert str(Mul(-2, x, Pow(Mul(y,y,evaluate=False), -1, evaluate=False),
                                                 evaluate=False)) == '-2*x/(y*y)'
+    # issue 21537
+    assert str(Mul(x, Pow(1/y, -1, evaluate=False), evaluate=False)) == 'x/(1/y)'
 
 
     class CustomClass1(Expr):

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/str\.py)' bin/test -C --verbose sympy/printing/tests/test_str.p
cat coverage.cover
git checkout b4777fdcef467b7132c055f8ac2c9a5059e6a145
git apply /root/pre_state.patch
