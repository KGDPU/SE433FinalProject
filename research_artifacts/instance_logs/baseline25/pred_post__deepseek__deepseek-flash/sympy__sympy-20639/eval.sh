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
diff --git a/sympy/printing/pretty/pretty.py b/sympy/printing/pretty/pretty.py
--- a/sympy/printing/pretty/pretty.py
+++ b/sympy/printing/pretty/pretty.py
@@ -1902,12 +1902,12 @@ def _print_Mul(self, product):
             return prettyForm.__mul__(*a)/prettyForm.__mul__(*b)
 
     # A helper function for _print_Pow to print x**(1/n)
-    def _print_nth_root(self, base, expt):
+    def _print_nth_root(self, base, root):
         bpretty = self._print(base)
 
         # In very simple cases, use a single-char root sign
         if (self._settings['use_unicode_sqrt_char'] and self._use_unicode
-            and expt is S.Half and bpretty.height() == 1
+            and root == 2 and bpretty.height() == 1
             and (bpretty.width() == 1
                  or (base.is_Integer and base.is_nonnegative))):
             return prettyForm(*bpretty.left('\N{SQUARE ROOT}'))
@@ -1915,14 +1915,13 @@ def _print_nth_root(self, base, expt):
         # Construct root sign, start with the \/ shape
         _zZ = xobj('/', 1)
         rootsign = xobj('\\', 1) + _zZ
-        # Make exponent number to put above it
-        if isinstance(expt, Rational):
-            exp = str(expt.q)
-            if exp == '2':
-                exp = ''
-        else:
-            exp = str(expt.args[0])
-        exp = exp.ljust(2)
+        # Constructing the number to put on root
+        rpretty = self._print(root)
+        # roots look bad if they are not a single line
+        if rpretty.height() != 1:
+            return self._print(base)**self._print(1/root)
+        # If power is half, no number should appear on top of root sign
+        exp = '' if root == 2 else str(rpretty).ljust(2)
         if len(exp) > 2:
             rootsign = ' '*(len(exp) - 2) + rootsign
         # Stack the exponent
@@ -1954,8 +1953,9 @@ def _print_Pow(self, power):
             if e is S.NegativeOne:
                 return prettyForm("1")/self._print(b)
             n, d = fraction(e)
-            if n is S.One and d.is_Atom and not e.is_Integer and self._settings['root_notation']:
-                return self._print_nth_root(b, e)
+            if n is S.One and d.is_Atom and not e.is_Integer and (e.is_Rational or d.is_Symbol) \
+                    and self._settings['root_notation']:
+                return self._print_nth_root(b, d)
             if e.is_Rational and e < 0:
                 return prettyForm("1")/self._print(Pow(b, -e, evaluate=False))
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/printing/pretty/tests/test_pretty.py b/sympy/printing/pretty/tests/test_pretty.py
index d33795d155..a2d977b05e 100755
--- a/sympy/printing/pretty/tests/test_pretty.py
+++ b/sympy/printing/pretty/tests/test_pretty.py
@@ -7205,6 +7205,51 @@ def test_is_combining():
         [False, True, False, False]
 
 
+
+def test_issue_17616():
+    assert pretty(pi**(1/exp(1))) == \
+   '  / -1\\\n'\
+   '  \\e  /\n'\
+   'pi     '
+
+    assert upretty(pi**(1/exp(1))) == \
+   ' ⎛ -1⎞\n'\
+   ' ⎝ℯ  ⎠\n'\
+   'π     '
+
+    assert pretty(pi**(1/pi)) == \
+    '  1 \n'\
+    '  --\n'\
+    '  pi\n'\
+    'pi  '
+
+    assert upretty(pi**(1/pi)) == \
+    ' 1\n'\
+    ' ─\n'\
+    ' π\n'\
+    'π '
+
+    assert pretty(pi**(1/EulerGamma)) == \
+    '      1     \n'\
+    '  ----------\n'\
+    '  EulerGamma\n'\
+    'pi          '
+
+    assert upretty(pi**(1/EulerGamma)) == \
+    ' 1\n'\
+    ' ─\n'\
+    ' γ\n'\
+    'π '
+
+    z = Symbol("x_17")
+    assert upretty(7**(1/z)) == \
+    'x₁₇___\n'\
+    ' ╲╱ 7 '
+
+    assert pretty(7**(1/z)) == \
+    'x_17___\n'\
+    '  \\/ 7 '
+
 def test_issue_17857():
     assert pretty(Range(-oo, oo)) == '{..., -1, 0, 1, ...}'
     assert pretty(Range(oo, -oo, -1)) == '{..., 1, 0, -1, ...}'

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/pretty/pretty\.py)' bin/test -C --verbose sympy/printing/pretty/tests/test_pretty.p
cat coverage.cover
git checkout eb926a1d0c1158bf43f01eaf673dc84416b5ebb1
git apply /root/pre_state.patch
