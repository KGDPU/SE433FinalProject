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
