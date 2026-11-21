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
diff --git a/tests/model_fields/test_filepathfield.py b/tests/model_fields/test_filepathfield.py
new file mode 100644
index 0000000000..6f027be4b6
--- /dev/null
+++ b/tests/model_fields/test_filepathfield.py
@@ -0,0 +1,31 @@
+import os
+import tempfile
+
+from django.db import models
+from django.test import SimpleTestCase
+
+
+class FilePathFieldTests(SimpleTestCase):
+    def test_path_callable(self):
+        with tempfile.TemporaryDirectory() as path:
+            with open(os.path.join(path, 'test.txt'), 'w'):
+                pass
+
+            def path_callable():
+                return path
+
+            field = models.FilePathField(path=path_callable)
+
+            # The callable is preserved when deconstructing the field so that
+            # migrations don't store the path for the machine where they were
+            # generated.
+            name, field_path, args, kwargs = field.deconstruct()
+            self.assertIs(kwargs['path'], path_callable)
+
+            # The callable is evaluated when creating the form field.
+            form_field = field.formfield()
+            self.assertEqual(form_field.path, path)
+            self.assertEqual(
+                form_field.choices,
+                [(os.path.join(path, 'test.txt'), 'test.txt')],
+            )

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/__init__\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 model_fields.test_filepathfield
cat coverage.cover
git checkout bceadd2788dc2dad53eba0caae172bd8522fd483
git apply /root/pre_state.patch
