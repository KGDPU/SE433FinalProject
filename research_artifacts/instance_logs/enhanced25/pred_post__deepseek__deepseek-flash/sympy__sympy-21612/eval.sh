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
diff --git a/sympy/parsing/tests/test_latex.py b/sympy/parsing/tests/test_latex.py
index f5c61cde13..9871f11030 100755
--- a/sympy/parsing/tests/test_latex.py
+++ b/sympy/parsing/tests/test_latex.py
@@ -251,6 +251,22 @@ def test_parseable():
     for latex_str, sympy_expr in GOOD_PAIRS:
         assert parse_latex(latex_str) == sympy_expr, latex_str
 
+
+def test_nested_fraction_string():
+    from sympy.parsing.latex import parse_latex
+
+    # A reciprocal fraction in the denominator must stay parenthesized when
+    # printed, otherwise the output is interpreted as division by the
+    # reciprocal's numerator and denominator separately.
+    expr = parse_latex(r"\frac{\frac{a^3+b}{c}}{\frac{1}{c^2}}")
+    assert str(expr) == "((a**3 + b)/c)/(1/(c**2))"
+
+    expr = parse_latex(r"\frac{a}{\frac{1}{b}}")
+    assert str(expr) == "a/(1/b)"
+
+    expr = parse_latex(r"\frac{\frac{a}{b}}{\frac{1}{c + d}}")
+    assert str(expr) == "(a/b)/(1/(c + d))"
+
 # These bad LaTeX strings should raise a LaTeXParsingError when parsed
 BAD_STRINGS = [
     r"(",
diff --git a/sympy/printing/tests/test_str.py b/sympy/printing/tests/test_str.py
index 690b1a8bbf..d317d01bbf 100755
--- a/sympy/printing/tests/test_str.py
+++ b/sympy/printing/tests/test_str.py
@@ -253,6 +253,14 @@ def test_Mul():
     assert str(Mul(-2, x, Pow(Mul(y,y,evaluate=False), -1, evaluate=False),
                                                 evaluate=False)) == '-2*x/(y*y)'
 
+    # A denominator that is itself a reciprocal must be parenthesized so that
+    # the string representation preserves the structure of the unevaluated Mul.
+    assert str(Mul(x, Pow(Pow(y, -1, evaluate=False), -1, evaluate=False),
+                   evaluate=False)) == 'x/(1/y)'
+    assert str(Mul(Mul(x, Pow(y, -1, evaluate=False), evaluate=False),
+                   Pow(Pow(z, -1, evaluate=False), -1, evaluate=False),
+                   evaluate=False)) == '(x/y)/(1/z)'
+
 
     class CustomClass1(Expr):
         is_commutative = True

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/str\.py)' bin/test -C --verbose sympy/parsing/tests/test_latex.py sympy/printing/tests/test_str.p
cat coverage.cover
git checkout b4777fdcef467b7132c055f8ac2c9a5059e6a145
git apply /root/pre_state.patch
