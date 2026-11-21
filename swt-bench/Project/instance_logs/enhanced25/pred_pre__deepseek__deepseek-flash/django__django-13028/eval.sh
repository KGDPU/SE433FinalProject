#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 78ad4b4b0201003792bfdbf1a7781cbc9ee03539 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 78ad4b4b0201003792bfdbf1a7781cbc9ee03539
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/tests/queries/models.py b/tests/queries/models.py
index 247d4b7671..163627b4c4 100755
--- a/tests/queries/models.py
+++ b/tests/queries/models.py
@@ -745,3 +745,12 @@ class JSONFieldNullable(models.Model):
 
     class Meta:
         required_db_features = {'supports_json_field'}
+
+
+class FilterableFieldModel(models.Model):
+    name = models.CharField(max_length=10)
+    filterable = models.BooleanField(default=False)
+    parent = models.ForeignKey('self', models.CASCADE, null=True)
+
+    def __str__(self):
+        return self.name
diff --git a/tests/queries/test_filterable.py b/tests/queries/test_filterable.py
new file mode 100644
index 0000000000..c3bf20523e
--- /dev/null
+++ b/tests/queries/test_filterable.py
@@ -0,0 +1,30 @@
+from django.db.models import Q
+from django.test import TestCase
+
+from .models import FilterableFieldModel
+
+
+class FilterableFieldTests(TestCase):
+    @classmethod
+    def setUpTestData(cls):
+        cls.parent = FilterableFieldModel.objects.create(name='parent')
+        cls.child = FilterableFieldModel.objects.create(
+            name='child',
+            parent=cls.parent,
+        )
+
+    def test_filter_by_model_instance_with_filterable_false_field(self):
+        self.assertSequenceEqual(
+            FilterableFieldModel.objects.filter(parent=self.parent),
+            [self.child],
+        )
+        self.assertSequenceEqual(
+            FilterableFieldModel.objects.filter(Q(parent=self.parent)),
+            [self.child],
+        )
+
+    def test_exclude_by_model_instance_with_filterable_false_field(self):
+        self.assertSequenceEqual(
+            FilterableFieldModel.objects.exclude(parent=self.parent),
+            [self.parent],
+        )

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/db/models/sql/query\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 queries.models queries.test_filterable
cat coverage.cover
git checkout 78ad4b4b0201003792bfdbf1a7781cbc9ee03539
git apply /root/pre_state.patch
