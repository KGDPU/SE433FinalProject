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
diff --git a/django/db/models/sql/query.py b/django/db/models/sql/query.py
--- a/django/db/models/sql/query.py
+++ b/django/db/models/sql/query.py
@@ -1124,7 +1124,10 @@ def check_related_objects(self, field, value, opts):
 
     def check_filterable(self, expression):
         """Raise an error if expression cannot be used in a WHERE clause."""
-        if not getattr(expression, 'filterable', True):
+        if (
+            hasattr(expression, 'resolve_expression') and
+            not getattr(expression, 'filterable', True)
+        ):
             raise NotSupportedError(
                 expression.__class__.__name__ + ' is disallowed in the filter '
                 'clause.'

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/tests/lookup/models.py b/tests/lookup/models.py
index 6a0afaacde..ece667058c 100755
--- a/tests/lookup/models.py
+++ b/tests/lookup/models.py
@@ -107,3 +107,13 @@ class Freebie(models.Model):
         to_fields=['id', 'product'],
         on_delete=models.CASCADE,
     )
+
+
+class ProductMetaDataType(models.Model):
+    label = models.CharField(max_length=255, unique=True)
+    filterable = models.BooleanField(default=False)
+
+
+class ProductMetaData(models.Model):
+    value = models.TextField()
+    metadata_type = models.ForeignKey(ProductMetaDataType, models.CASCADE)
diff --git a/tests/lookup/tests.py b/tests/lookup/tests.py
index 9ed91a6ee0..4a4b01ac48 100755
--- a/tests/lookup/tests.py
+++ b/tests/lookup/tests.py
@@ -12,7 +12,8 @@ from django.test.utils import isolate_apps
 from django.utils.deprecation import RemovedInDjango40Warning
 
 from .models import (
-    Article, Author, Freebie, Game, IsNullWithNoneAsRHS, Player, Season, Tag,
+    Article, Author, Freebie, Game, IsNullWithNoneAsRHS, Player, ProductMetaData,
+    ProductMetaDataType, Season, Tag,
 )
 
 
@@ -1029,3 +1030,20 @@ class LookupTests(TestCase):
             with self.subTest(qs=qs):
                 with self.assertWarnsMessage(RemovedInDjango40Warning, msg):
                     qs.exists()
+
+    def test_filter_by_model_instance_with_filterable_field(self):
+        metadata_type = ProductMetaDataType.objects.create(
+            label='brand',
+            filterable=False,
+        )
+        metadata = ProductMetaData.objects.create(
+            value='Dark Vador',
+            metadata_type=metadata_type,
+        )
+        self.assertSequenceEqual(
+            ProductMetaData.objects.filter(
+                value='Dark Vador',
+                metadata_type=metadata_type,
+            ),
+            [metadata],
+        )

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/db/models/sql/query\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 lookup.models lookup.tests
cat coverage.cover
git checkout 78ad4b4b0201003792bfdbf1a7781cbc9ee03539
git apply /root/pre_state.patch
