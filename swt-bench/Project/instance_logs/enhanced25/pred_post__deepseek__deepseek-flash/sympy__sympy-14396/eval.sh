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
diff --git a/sympy/polys/polyoptions.py b/sympy/polys/polyoptions.py
--- a/sympy/polys/polyoptions.py
+++ b/sympy/polys/polyoptions.py
@@ -405,7 +405,7 @@ class Domain(with_metaclass(OptionType, Option)):
     _re_realfield = re.compile(r"^(R|RR)(_(\d+))?$")
     _re_complexfield = re.compile(r"^(C|CC)(_(\d+))?$")
     _re_finitefield = re.compile(r"^(FF|GF)\((\d+)\)$")
-    _re_polynomial = re.compile(r"^(Z|ZZ|Q|QQ)\[(.+)\]$")
+    _re_polynomial = re.compile(r"^(Z|ZZ|Q|QQ|R|RR|C|CC)\[(.+)\]$")
     _re_fraction = re.compile(r"^(Z|ZZ|Q|QQ)\((.+)\)$")
     _re_algebraic = re.compile(r"^(Q|QQ)\<(.+)\>$")
 
@@ -459,8 +459,12 @@ def preprocess(cls, domain):
 
                 if ground in ['Z', 'ZZ']:
                     return sympy.polys.domains.ZZ.poly_ring(*gens)
-                else:
+                elif ground in ['Q', 'QQ']:
                     return sympy.polys.domains.QQ.poly_ring(*gens)
+                elif ground in ['R', 'RR']:
+                    return sympy.polys.domains.RR.poly_ring(*gens)
+                else:
+                    return sympy.polys.domains.CC.poly_ring(*gens)
 
             r = cls._re_fraction.match(domain)
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/polys/tests/test_polyoptions.py b/sympy/polys/tests/test_polyoptions.py
index cbc968174..c8a49403d 100755
--- a/sympy/polys/tests/test_polyoptions.py
+++ b/sympy/polys/tests/test_polyoptions.py
@@ -6,7 +6,7 @@
     Frac, Formal, Polys, Include, All, Gen, Symbols, Method)
 
 from sympy.polys.orderings import lex
-from sympy.polys.domains import FF, GF, ZZ, QQ, EX
+from sympy.polys.domains import FF, GF, ZZ, QQ, RR, CC, EX
 
 from sympy.polys.polyerrors import OptionError, GeneratorsError
 
@@ -186,6 +186,21 @@ def test_Domain_preprocess():
     assert Domain.preprocess('ZZ[x,y]') == ZZ[x, y]
     assert Domain.preprocess('QQ[x,y]') == QQ[x, y]
 
+    assert Domain.preprocess('R[x]') == RR[x]
+    assert Domain.preprocess('RR[x]') == RR[x]
+
+    assert Domain.preprocess('C[x]') == CC[x]
+    assert Domain.preprocess('CC[x]') == CC[x]
+
+    assert Domain.preprocess('R[x,y]') == RR[x, y]
+    assert Domain.preprocess('RR[x,y]') == RR[x, y]
+
+    assert Domain.preprocess('C[x,y]') == CC[x, y]
+    assert Domain.preprocess('CC[x,y]') == CC[x, y]
+
+    raises(OptionError, lambda: Domain.preprocess('R[]'))
+    raises(OptionError, lambda: Domain.preprocess('C[]'))
+
     raises(OptionError, lambda: Domain.preprocess('Z()'))
 
     assert Domain.preprocess('Z(x)') == ZZ.frac_field(x)
@@ -200,6 +215,18 @@ def test_Domain_preprocess():
     assert Domain.preprocess('ZZ(x,y)') == ZZ.frac_field(x, y)
     assert Domain.preprocess('QQ(x,y)') == QQ.frac_field(x, y)
 
+    assert Domain.preprocess('R(x)') == RR.frac_field(x)
+    assert Domain.preprocess('RR(x)') == RR.frac_field(x)
+
+    assert Domain.preprocess('C(x)') == CC.frac_field(x)
+    assert Domain.preprocess('CC(x)') == CC.frac_field(x)
+
+    assert Domain.preprocess('R(x,y)') == RR.frac_field(x, y)
+    assert Domain.preprocess('RR(x,y)') == RR.frac_field(x, y)
+
+    assert Domain.preprocess('C(x,y)') == CC.frac_field(x, y)
+    assert Domain.preprocess('CC(x,y)') == CC.frac_field(x, y)
+
     assert Domain.preprocess('Q<I>') == QQ.algebraic_field(I)
     assert Domain.preprocess('QQ<I>') == QQ.algebraic_field(I)
 
diff --git a/sympy/polys/tests/test_polytools.py b/sympy/polys/tests/test_polytools.py
index 1f889e9f1..ed3a62c90 100755
--- a/sympy/polys/tests/test_polytools.py
+++ b/sympy/polys/tests/test_polytools.py
@@ -47,7 +47,7 @@
 from sympy.polys.polyclasses import DMP
 
 from sympy.polys.fields import field
-from sympy.polys.domains import FF, ZZ, QQ, RR, EX
+from sympy.polys.domains import FF, ZZ, QQ, RR, CC, EX
 from sympy.polys.domains.realfield import RealField
 from sympy.polys.orderings import lex, grlex, grevlex
 
@@ -320,6 +320,13 @@ def test_Poly__new__():
     assert Poly(3*x**2 + 2*x + 1, domain='QQ').all_coeffs() == [3, 2, 1]
     assert Poly(3*x**2 + 2*x + 1, domain='RR').all_coeffs() == [3.0, 2.0, 1.0]
 
+    assert Poly(1.2*x*y, x, domain='RR[y]').get_domain() == RR[y]
+    assert Poly(1.2*x*y*z, x, domain='RR[y,z]') == Poly(1.2*x*y*z, x)
+    assert Poly((1.2 + 2.0*I)*x*y, x, domain='CC[y]').get_domain() == CC[y]
+
+    raises(GeneratorsError,
+        lambda: Poly(1.2*x*y, x, y, domain='RR[y]'))
+
     raises(CoercionFailed, lambda: Poly(3*x**2/5 + 2*x/5 + 1, domain='ZZ'))
     assert Poly(
         3*x**2/5 + 2*x/5 + 1, domain='QQ').all_coeffs() == [S(3)/5, S(2)/5, 1]

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/polys/polyoptions\.py)' bin/test -C --verbose sympy/polys/tests/test_polyoptions.py sympy/polys/tests/test_polytools.p
cat coverage.cover
git checkout f35ad6411f86a15dd78db39c29d1e5291f66f9b5
git apply /root/pre_state.patch
