#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3aefc834dce72e850bff48689bea3c7dff5f3fad >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3aefc834dce72e850bff48689bea3c7dff5f3fad
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/ensemble/tests/test_iforest.py b/sklearn/ensemble/tests/test_iforest.py
index 67ba2d7f9..0bb9f6869 100755
--- a/sklearn/ensemble/tests/test_iforest.py
+++ b/sklearn/ensemble/tests/test_iforest.py
@@ -359,3 +359,65 @@ def test_iforest_chunks_works2(
 ):
     test_iforest_works(contamination)
     assert mocked_get_chunk.call_count == n_predict_calls
+
+
+def test_iforest_warm_start():
+    """Test IsolationForest exposes and supports warm_start."""
+    rng = check_random_state(0)
+    X = rng.randn(50, 2)
+
+    clf = IsolationForest(
+        n_estimators=5,
+        warm_start=True,
+        random_state=0,
+        contamination="auto",
+        behaviour="new",
+    )
+    clf.fit(X)
+    assert_equal(clf.warm_start, True)
+    assert_equal(len(clf.estimators_), 5)
+    first_estimators = clf.estimators_[:]
+
+    # Adding trees must preserve the previously fitted trees.
+    clf.set_params(n_estimators=10)
+    clf.fit(X)
+    assert_equal(len(clf.estimators_), 10)
+    assert all(
+        old_tree is new_tree
+        for old_tree, new_tree in zip(first_estimators, clf.estimators_)
+    )
+
+    # A warm-started fit is equivalent to fitting all trees at once.
+    clf_batch = IsolationForest(
+        n_estimators=10,
+        warm_start=False,
+        random_state=0,
+        contamination="auto",
+        behaviour="new",
+    )
+    clf_batch.fit(X)
+    assert_array_equal(clf.estimators_features_, clf_batch.estimators_features_)
+    assert_array_equal(clf.score_samples(X), clf_batch.score_samples(X))
+    assert_array_equal(clf.predict(X), clf_batch.predict(X))
+
+    # Fitting without increasing n_estimators should not modify the forest.
+    assert_warns_message(
+        UserWarning,
+        "Warm-start fitting without increasing n_estimators",
+        clf.fit,
+        X,
+    )
+    assert_equal(len(clf.estimators_), 10)
+    assert_array_equal(clf.score_samples(X), clf_batch.score_samples(X))
+
+    # The default is to fit a new forest, and reducing the number of trees
+    # while warm-starting is invalid.
+    assert_equal(IsolationForest().warm_start, False)
+    clf.set_params(n_estimators=9)
+    assert_raises_regex(
+        ValueError,
+        "must be larger or equal to",
+        clf.fit,
+        X,
+    )
+    assert_equal(len(clf.estimators_), 10)

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(sklearn/ensemble/iforest\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/ensemble/tests/test_iforest.py
cat coverage.cover
git checkout 3aefc834dce72e850bff48689bea3c7dff5f3fad
git apply /root/pre_state.patch
