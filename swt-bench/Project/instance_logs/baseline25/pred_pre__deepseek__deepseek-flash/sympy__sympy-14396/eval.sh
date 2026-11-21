#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD f35ad6411f86a15dd78db39c29d1e5291f66f9b5 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff f35ad6411f86a15dd78db39c29d1e5291f66f9b5
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/polys/tests/test_polyoptions.py b/sympy/polys/tests/test_polyoptions.py
index cbc968174..628e268aa 100755
--- a/sympy/polys/tests/test_polyoptions.py
+++ b/sympy/polys/tests/test_polyoptions.py
@@ -6,7 +6,7 @@
     Frac, Formal, Polys, Include, All, Gen, Symbols, Method)
 
 from sympy.polys.orderings import lex
-from sympy.polys.domains import FF, GF, ZZ, QQ, EX
+from sympy.polys.domains import FF, GF, ZZ, QQ, RR, CC, EX
 
 from sympy.polys.polyerrors import OptionError, GeneratorsError
 
@@ -176,15 +176,23 @@ def test_Domain_preprocess():
 
     assert Domain.preprocess('Z[x]') == ZZ[x]
     assert Domain.preprocess('Q[x]') == QQ[x]
+    assert Domain.preprocess('R[x]') == RR[x]
+    assert Domain.preprocess('C[x]') == CC[x]
 
     assert Domain.preprocess('ZZ[x]') == ZZ[x]
     assert Domain.preprocess('QQ[x]') == QQ[x]
+    assert Domain.preprocess('RR[x]') == RR[x]
+    assert Domain.preprocess('CC[x]') == CC[x]
 
     assert Domain.preprocess('Z[x,y]') == ZZ[x, y]
     assert Domain.preprocess('Q[x,y]') == QQ[x, y]
+    assert Domain.preprocess('R[x,y]') == RR[x, y]
+    assert Domain.preprocess('C[x,y]') == CC[x, y]
 
     assert Domain.preprocess('ZZ[x,y]') == ZZ[x, y]
     assert Domain.preprocess('QQ[x,y]') == QQ[x, y]
+    assert Domain.preprocess('RR[x,y]') == RR[x, y]
+    assert Domain.preprocess('CC[x,y]') == CC[x, y]
 
     raises(OptionError, lambda: Domain.preprocess('Z()'))
 
diff --git a/sympy/polys/tests/test_polytools.py b/sympy/polys/tests/test_polytools.py
index 1f889e9f1..1ee3b65c6 100755
--- a/sympy/polys/tests/test_polytools.py
+++ b/sympy/polys/tests/test_polytools.py
@@ -319,6 +319,8 @@ def test_Poly__new__():
     assert Poly(3*x**2 + 2*x + 1, domain='ZZ').all_coeffs() == [3, 2, 1]
     assert Poly(3*x**2 + 2*x + 1, domain='QQ').all_coeffs() == [3, 2, 1]
     assert Poly(3*x**2 + 2*x + 1, domain='RR').all_coeffs() == [3.0, 2.0, 1.0]
+    assert Poly(1.2*x*y*z, x, domain='RR[y,z]') == \
+        Poly(1.2*x*y*z, x, domain=RR[y, z])
 
     raises(CoercionFailed, lambda: Poly(3*x**2/5 + 2*x/5 + 1, domain='ZZ'))
     assert Poly(

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/polys/polyoptions\.py)' bin/test -C --verbose sympy/polys/tests/test_polyoptions.py sympy/polys/tests/test_polytools.p
cat coverage.cover
git checkout f35ad6411f86a15dd78db39c29d1e5291f66f9b5
git apply /root/pre_state.patch
