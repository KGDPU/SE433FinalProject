#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 42e8cf47c7ee2db238bf91197ea398126c546741 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 42e8cf47c7ee2db238bf91197ea398126c546741
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/models.py b/django/forms/models.py
--- a/django/forms/models.py
+++ b/django/forms/models.py
@@ -1284,7 +1284,11 @@ def to_python(self, value):
                 value = getattr(value, key)
             value = self.queryset.get(**{key: value})
         except (ValueError, TypeError, self.queryset.model.DoesNotExist):
-            raise ValidationError(self.error_messages['invalid_choice'], code='invalid_choice')
+            raise ValidationError(
+                self.error_messages['invalid_choice'],
+                code='invalid_choice',
+                params={'value': value},
+            )
         return value
 
     def validate(self, value):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/tests/forms_tests/tests/test_error_messages.py b/tests/forms_tests/tests/test_error_messages.py
index 1a6d1386c3..340c39546c 100755
--- a/tests/forms_tests/tests/test_error_messages.py
+++ b/tests/forms_tests/tests/test_error_messages.py
@@ -308,3 +308,16 @@ class ModelChoiceFieldErrorMessagesTestCase(TestCase, AssertFormErrorsMixin):
         self.assertFormErrors(['REQUIRED'], f.clean, '')
         self.assertFormErrors(['NOT A LIST OF VALUES'], f.clean, '3')
         self.assertFormErrors(['4 IS INVALID CHOICE'], f.clean, ['4'])
+
+    def test_modelchoicefield_value_placeholder(self):
+        f = ModelChoiceField(
+            queryset=ChoiceModel.objects.all(),
+            error_messages={
+                'invalid_choice': '"%(value)s" is not one of the available choices.',
+            },
+        )
+        self.assertFormErrors(
+            ['"invalid" is not one of the available choices.'],
+            f.clean,
+            'invalid',
+        )

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/forms/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 forms_tests.tests.test_error_messages
cat coverage.cover
git checkout 42e8cf47c7ee2db238bf91197ea398126c546741
git apply /root/pre_state.patch
