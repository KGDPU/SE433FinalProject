#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD bceadd2788dc2dad53eba0caae172bd8522fd483 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff bceadd2788dc2dad53eba0caae172bd8522fd483
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/fields/__init__.py b/django/db/models/fields/__init__.py
--- a/django/db/models/fields/__init__.py
+++ b/django/db/models/fields/__init__.py
@@ -1709,7 +1709,7 @@ def get_prep_value(self, value):
 
     def formfield(self, **kwargs):
         return super().formfield(**{
-            'path': self.path,
+            'path': self.path() if callable(self.path) else self.path,
             'match': self.match,
             'recursive': self.recursive,
             'form_class': forms.FilePathField,

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/tests/model_fields/test_filepathfield.py b/tests/model_fields/test_filepathfield.py
new file mode 100644
index 0000000000..8931e14486
--- /dev/null
+++ b/tests/model_fields/test_filepathfield.py
@@ -0,0 +1,45 @@
+import os
+import tempfile
+
+from django import forms
+from django.db import models
+from django.test import SimpleTestCase
+
+
+class FilePathFieldTests(SimpleTestCase):
+    def test_callable_path(self):
+        with tempfile.TemporaryDirectory() as path:
+            filename = os.path.join(path, 'file.txt')
+            with open(filename, 'w'):
+                pass
+
+            calls = []
+
+            def get_path():
+                calls.append(True)
+                return path
+
+            field = models.FilePathField(path=get_path)
+            self.assertEqual(calls, [])
+
+            form_field = field.formfield()
+            self.assertIsInstance(form_field, forms.FilePathField)
+            self.assertEqual(form_field.path, path)
+            self.assertEqual(form_field.choices, [(filename, 'file.txt')])
+            self.assertEqual(calls, [True])
+            self.assertIs(field.path, get_path)
+
+    def test_callable_path_deconstruct(self):
+        calls = []
+
+        def get_path():
+            calls.append(True)
+            return '/some/path'
+
+        field = models.FilePathField(path=get_path)
+        name, path, args, kwargs = field.deconstruct()
+        self.assertIsNone(name)
+        self.assertEqual(path, 'django.db.models.FilePathField')
+        self.assertEqual(args, [])
+        self.assertIs(kwargs['path'], get_path)
+        self.assertEqual(calls, [])

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/__init__\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 model_fields.test_filepathfield
cat coverage.cover
git checkout bceadd2788dc2dad53eba0caae172bd8522fd483
git apply /root/pre_state.patch
