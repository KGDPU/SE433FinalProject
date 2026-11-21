#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD eb926a1d0c1158bf43f01eaf673dc84416b5ebb1 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff eb926a1d0c1158bf43f01eaf673dc84416b5ebb1
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/printing/pretty/tests/test_pretty.py b/sympy/printing/pretty/tests/test_pretty.py
index d33795d155..c1aef892e4 100755
--- a/sympy/printing/pretty/tests/test_pretty.py
+++ b/sympy/printing/pretty/tests/test_pretty.py
@@ -3,7 +3,7 @@
     Add, And, Basic, Derivative, Dict, Eq, Equivalent, FF,
     FiniteSet, Function, Ge, Gt, I, Implies, Integral, SingularityFunction,
     Lambda, Le, Limit, Lt, Matrix, Mul, Nand, Ne, Nor, Not, O, Or,
-    Pow, Product, QQ, RR, Rational, Ray, rootof, RootSum, S,
+    E, Pow, Product, QQ, RR, Rational, Ray, rootof, RootSum, S,
     Segment, Subs, Sum, Symbol, Tuple, Trace, Xor, ZZ, conjugate,
     groebner, oo, pi, symbols, ilex, grlex, Range, Contains,
     SeqPer, SeqFormula, SeqAdd, SeqMul, fourier_series, fps, ITE,
@@ -7250,3 +7250,32 @@ def test_diffgeom():
     assert pretty(rect) == "rect"
     b = BaseScalarField(rect, 0)
     assert pretty(b) == "x"
+
+
+def test_pretty_pow_inverse_exp():
+    # Test that an exponent of exp(-1) is not mistaken for a root of
+    # degree -1.  Root notation is acceptable for a reciprocal exponent,
+    # but then the degree must be E rather than the argument of exp.
+    expressions = [
+        pi**(1/E),
+        x**(1/E),
+        (x + 1)**(1/E),
+        (x**2 + 1)**(1/E),
+        2**(1/E),
+    ]
+    for expr in expressions:
+        for use_unicode in (False, True):
+            result = xpretty(expr, use_unicode=use_unicode, wrap_line=False)
+            if '\\/' in result or '╲╱' in result:
+                assert '-1' not in result
+                assert 'E' in result or 'ℯ' in result
+            else:
+                assert result == xpretty(
+                    expr, use_unicode=use_unicode, wrap_line=False,
+                    root_notation=False)
+
+    # Reciprocal integer exponents should still use root notation.
+    assert xpretty(x**Rational(1, 3), use_unicode=False,
+                   wrap_line=False) == '3 ___\n\\/ x '
+    assert xpretty(x**Rational(1, 2), use_unicode=True,
+                   wrap_line=False) == '√x'

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/pretty/pretty\.py)' bin/test -C --verbose sympy/printing/pretty/tests/test_pretty.p
cat coverage.cover
git checkout eb926a1d0c1158bf43f01eaf673dc84416b5ebb1
git apply /root/pre_state.patch
