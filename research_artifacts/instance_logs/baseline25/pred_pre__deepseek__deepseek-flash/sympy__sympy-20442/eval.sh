#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 1abbc0ac3e552cb184317194e5d5c5b9dd8fb640 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 1abbc0ac3e552cb184317194e5d5c5b9dd8fb640
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/physics/units/tests/test_util.py b/sympy/physics/units/tests/test_util.py
index ed2f7df27e..966ef93792 100755
--- a/sympy/physics/units/tests/test_util.py
+++ b/sympy/physics/units/tests/test_util.py
@@ -65,6 +65,12 @@ def test_convert_to_quantities():
     assert convert_to(pi, degree) == 180*degree
 
 
+def test_convert_to_orthogonal_units():
+    # An incompatible target unit must not be combined with the original
+    # expression to produce an unphysical fractional power.
+    assert convert_to(joule*second, joule) == joule*second
+
+
 def test_convert_to_tuples_of_quantities():
     assert convert_to(speed_of_light, [meter, second]) == 299792458 * meter / second
     assert convert_to(speed_of_light, (meter, second)) == 299792458 * meter / second

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sympy/physics/units/util\.py)' bin/test -C --verbose sympy/physics/units/tests/test_util.p
cat coverage.cover
git checkout 1abbc0ac3e552cb184317194e5d5c5b9dd8fb640
git apply /root/pre_state.patch
