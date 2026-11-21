#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b90661d6a46aa3619d3eec94d5281f5888add501 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b90661d6a46aa3619d3eec94d5281f5888add501
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/linear_model/tests/test_ridge.py b/sklearn/linear_model/tests/test_ridge.py
index ee44da5d5..31102b00b 100755
--- a/sklearn/linear_model/tests/test_ridge.py
+++ b/sklearn/linear_model/tests/test_ridge.py
@@ -598,6 +598,32 @@ def test_ridgecv_store_cv_values():
     assert_equal(r.cv_values_.shape, (n_samples, n_responses, n_alphas))
 
 
+def test_ridge_classifier_cv_store_cv_values():
+    # Test RidgeClassifierCV's store_cv_values attribute.
+    x = np.array([[-1.0, -1.0], [-1.0, 0], [-.8, -1.0],
+                  [1.0, 1.0], [1.0, 0.0]])
+    y = np.array([1, 1, 1, -1, -1])
+
+    n_samples = x.shape[0]
+    alphas = [1e-1, 1e0, 1e1]
+    n_alphas = len(alphas)
+
+    r = RidgeClassifierCV(alphas=alphas, cv=None, store_cv_values=True)
+
+    # with len(y.shape) == 1
+    n_targets = 1
+    r.fit(x, y)
+    assert_equal(r.cv_values_.shape, (n_samples, n_targets, n_alphas))
+
+    # with len(y.shape) == 2
+    y = np.array([[1, 1, 1, -1, -1],
+                  [1, -1, 1, -1, 1],
+                  [-1, -1, 1, -1, -1]]).transpose()
+    n_targets = y.shape[1]
+    r.fit(x, y)
+    assert_equal(r.cv_values_.shape, (n_samples, n_targets, n_alphas))
+
+
 def test_ridgecv_sample_weight():
     rng = np.random.RandomState(0)
     alphas = (0.1, 1.0, 10.0)

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sklearn/linear_model/ridge\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/linear_model/tests/test_ridge.py
cat coverage.cover
git checkout b90661d6a46aa3619d3eec94d5281f5888add501
git apply /root/pre_state.patch
