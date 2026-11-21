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
diff --git a/sympy/physics/units/util.py b/sympy/physics/units/util.py
--- a/sympy/physics/units/util.py
+++ b/sympy/physics/units/util.py
@@ -4,6 +4,7 @@
 
 from sympy import Add, Mul, Pow, Tuple, sympify
 from sympy.core.compatibility import reduce, Iterable, ordered
+from sympy.matrices.common import NonInvertibleMatrixError
 from sympy.physics.units.dimensions import Dimension
 from sympy.physics.units.prefixes import Prefix
 from sympy.physics.units.quantities import Quantity
@@ -30,7 +31,11 @@ def _get_conversion_matrix_for_expr(expr, target_units, unit_system):
     camat = Matrix([[dimension_system.get_dimensional_dependencies(i, mark_dimensionless=True).get(j, 0) for i in target_dims] for j in canon_dim_units])
     exprmat = Matrix([dim_dependencies.get(k, 0) for k in canon_dim_units])
 
-    res_exponents = camat.solve_least_squares(exprmat, method=None)
+    try:
+        res_exponents = camat.solve(exprmat)
+    except NonInvertibleMatrixError:
+        return None
+
     return res_exponents
 
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/physics/units/tests/test_util.py b/sympy/physics/units/tests/test_util.py
index ed2f7df27e..4793023b50 100755
--- a/sympy/physics/units/tests/test_util.py
+++ b/sympy/physics/units/tests/test_util.py
@@ -65,6 +65,21 @@ def test_convert_to_quantities():
     assert convert_to(pi, degree) == 180*degree
 
 
+def test_convert_to_incompatible_units():
+    # A target unit (or collection of units) which cannot exactly represent
+    # the dimensions of the expression should leave the expression unchanged.
+    # In particular, do not use least-squares exponents to combine orthogonal
+    # dimensions into a dimensionally different expression.
+    assert convert_to(joule*second, joule) == joule*second
+    assert convert_to(2*joule*second, joule) == 2*joule*second
+    assert convert_to(joule, joule*second) == joule
+    assert convert_to(meter**2, meter*second) == meter**2
+    assert convert_to(joule*second, [joule, kilogram]) == joule*second
+
+    # Exact conversions to a collection of units are still supported.
+    assert convert_to(joule*second, [joule, second]) == joule*second
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
