#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 41490b75f3621408e0468b0e7b6dc409601fc6ff >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 41490b75f3621408e0468b0e7b6dc409601fc6ff
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/printing/pretty/tests/test_pretty.py b/sympy/printing/pretty/tests/test_pretty.py
index cfaa65a7a..adfec933e 100755
--- a/sympy/printing/pretty/tests/test_pretty.py
+++ b/sympy/printing/pretty/tests/test_pretty.py
@@ -2054,23 +2054,23 @@ def test_pretty_product():
     unicode_str = \
 u("""\
     l           \n\
-┬────────┬      \n\
-│        │  ⎛ 2⎞\n\
-│        │  ⎜n ⎟\n\
-│        │ f⎜──⎟\n\
-│        │  ⎝9 ⎠\n\
-│        │      \n\
+─┬──────┬─      \n\
+ │      │   ⎛ 2⎞\n\
+ │      │   ⎜n ⎟\n\
+ │      │  f⎜──⎟\n\
+ │      │   ⎝9 ⎠\n\
+ │      │       \n\
        2        \n\
   n = k         """)
     ascii_str = \
 """\
     l           \n\
 __________      \n\
-|        |  / 2\\\n\
-|        |  |n |\n\
-|        | f|--|\n\
-|        |  \\9 /\n\
-|        |      \n\
+ |      |   / 2\\\n\
+ |      |   |n |\n\
+ |      |  f|--|\n\
+ |      |   \\9 /\n\
+ |      |       \n\
        2        \n\
   n = k         """
 
@@ -2082,23 +2082,23 @@ def test_pretty_product():
     unicode_str = \
 u("""\
     m          l           \n\
-┬────────┬ ┬────────┬      \n\
-│        │ │        │  ⎛ 2⎞\n\
-│        │ │        │  ⎜n ⎟\n\
-│        │ │        │ f⎜──⎟\n\
-│        │ │        │  ⎝9 ⎠\n\
-│        │ │        │      \n\
+─┬──────┬─ ─┬──────┬─      \n\
+ │      │   │      │   ⎛ 2⎞\n\
+ │      │   │      │   ⎜n ⎟\n\
+ │      │   │      │  f⎜──⎟\n\
+ │      │   │      │   ⎝9 ⎠\n\
+ │      │   │      │       \n\
   l = 1           2        \n\
              n = k         """)
     ascii_str = \
 """\
     m          l           \n\
 __________ __________      \n\
-|        | |        |  / 2\\\n\
-|        | |        |  |n |\n\
-|        | |        | f|--|\n\
-|        | |        |  \\9 /\n\
-|        | |        |      \n\
+ |      |   |      |   / 2\\\n\
+ |      |   |      |   |n |\n\
+ |      |   |      |  f|--|\n\
+ |      |   |      |   \\9 /\n\
+ |      |   |      |       \n\
   l = 1           2        \n\
              n = k         """
 
@@ -5514,19 +5514,19 @@ def test_issue_6359():
            2
 /  2      \\ \n\
 |______   | \n\
-||    |  2| \n\
-||    | x | \n\
-||    |   | \n\
+| |  |   2| \n\
+| |  |  x | \n\
+| |  |    | \n\
 \\x = 1    / \
 """
     assert upretty(Product(x**2, (x, 1, 2))**2) == \
 u("""\
            2
 ⎛  2      ⎞ \n\
-⎜┬────┬   ⎟ \n\
-⎜│    │  2⎟ \n\
-⎜│    │ x ⎟ \n\
-⎜│    │   ⎟ \n\
+⎜─┬──┬─   ⎟ \n\
+⎜ │  │   2⎟ \n\
+⎜ │  │  x ⎟ \n\
+⎜ │  │    ⎟ \n\
 ⎝x = 1    ⎠ \
 """)
 

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/pretty/pretty\.py)' bin/test -C --verbose sympy/printing/pretty/tests/test_pretty.p
cat coverage.cover
git checkout 41490b75f3621408e0468b0e7b6dc409601fc6ff
git apply /root/pre_state.patch
