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
diff --git a/tests/admin_widgets/tests.py b/tests/admin_widgets/tests.py
index 3c41d9cdfa..c0f3c663e6 100755
--- a/tests/admin_widgets/tests.py
+++ b/tests/admin_widgets/tests.py
@@ -20,6 +20,7 @@ from django.db.models import (
 from django.test import SimpleTestCase, TestCase, override_settings
 from django.urls import reverse
 from django.utils import translation
+from django.utils.html import escape
 
 from .models import (
     Advisor, Album, Band, Bee, Car, Company, Event, Honeycomb, Individual,
@@ -243,15 +244,16 @@ class AdminForeignKeyRawIdWidget(TestDataMixin, TestCase):
         # Try posting with a nonexistent pk in a raw id field: this
         # should result in an error message, not a server exception.
         response = self.client.post(reverse('admin:admin_widgets_event_add'), post_data)
-        self.assertContains(response, 'Select a valid choice. That choice is not one of the available choices.')
+        msg = 'Select a valid choice. %s is not one of the available choices.' % pk
+        self.assertContains(response, escape(msg))
 
     def test_invalid_target_id(self):
 
         for test_str in ('Iñtërnâtiônàlizætiøn', "1234'", -1234):
             # This should result in an error message, not a server exception.
             response = self.client.post(reverse('admin:admin_widgets_event_add'), {"main_band": test_str})
-
-            self.assertContains(response, 'Select a valid choice. That choice is not one of the available choices.')
+            msg = 'Select a valid choice. %s is not one of the available choices.' % test_str
+            self.assertContains(response, escape(msg))
 
     def test_url_params_from_lookup_dict_any_iterable(self):
         lookup1 = widgets.url_params_from_lookup_dict({'color__in': ('red', 'blue')})
diff --git a/tests/forms_tests/tests/test_error_messages.py b/tests/forms_tests/tests/test_error_messages.py
index 1a6d1386c3..55d15c1002 100755
--- a/tests/forms_tests/tests/test_error_messages.py
+++ b/tests/forms_tests/tests/test_error_messages.py
@@ -270,6 +270,17 @@ class FormsErrorMessagesTestCase(SimpleTestCase, AssertFormErrorsMixin):
             'available choices.</li></ul></li></ul>'
         )
 
+        class SomeForm(Form):
+            field = ModelChoiceField(ChoiceModel.objects.all())
+
+        f = SomeForm({'field': '<script>'})
+        self.assertHTMLEqual(
+            t.render(Context({'form': f})),
+            '<ul class="errorlist"><li>field<ul class="errorlist">'
+            '<li>Select a valid choice. &lt;script&gt; is not one of the '
+            'available choices.</li></ul></li></ul>'
+        )
+
         class SomeForm(Form):
             field = ModelMultipleChoiceField(ChoiceModel.objects.all())
 
@@ -292,11 +303,11 @@ class ModelChoiceFieldErrorMessagesTestCase(TestCase, AssertFormErrorsMixin):
         # ModelChoiceField
         e = {
             'required': 'REQUIRED',
-            'invalid_choice': 'INVALID CHOICE',
+            'invalid_choice': '%(value)s IS INVALID CHOICE',
         }
         f = ModelChoiceField(queryset=ChoiceModel.objects.all(), error_messages=e)
         self.assertFormErrors(['REQUIRED'], f.clean, '')
-        self.assertFormErrors(['INVALID CHOICE'], f.clean, '4')
+        self.assertFormErrors(['4 IS INVALID CHOICE'], f.clean, '4')
 
         # ModelMultipleChoiceField
         e = {
diff --git a/tests/model_forms/test_modelchoicefield.py b/tests/model_forms/test_modelchoicefield.py
index 8f41ce9c40..9d4ffcb134 100755
--- a/tests/model_forms/test_modelchoicefield.py
+++ b/tests/model_forms/test_modelchoicefield.py
@@ -51,17 +51,41 @@ class ModelChoiceFieldTests(TestCase):
         # instantiated. This proves clean() checks the database during clean()
         # rather than caching it at instantiation time.
         Category.objects.get(url='4th').delete()
-        msg = "['Select a valid choice. That choice is not one of the available choices.']"
+        msg = "['Select a valid choice. %s is not one of the available choices.']" % c4.id
         with self.assertRaisesMessage(ValidationError, msg):
             f.clean(c4.id)
 
+    def test_invalid_choice_error_message_includes_value(self):
+        field = forms.ModelChoiceField(Category.objects.all())
+        invalid_pk = 1000
+        with self.assertRaises(ValidationError) as cm:
+            field.clean(invalid_pk)
+        self.assertEqual(
+            cm.exception.messages,
+            ['Select a valid choice. 1000 is not one of the available choices.'],
+        )
+        self.assertEqual(cm.exception.code, 'invalid_choice')
+        self.assertEqual(cm.exception.params, {'value': invalid_pk})
+
+    def test_invalid_choice_error_message_with_custom_message(self):
+        field = forms.ModelChoiceField(
+            Category.objects.all(),
+            error_messages={'invalid_choice': '%(value)s is not a valid choice.'},
+        )
+        with self.assertRaises(ValidationError) as cm:
+            field.clean('invalid-pk')
+        self.assertEqual(cm.exception.messages, ['invalid-pk is not a valid choice.'])
+        self.assertEqual(cm.exception.code, 'invalid_choice')
+        self.assertEqual(cm.exception.params, {'value': 'invalid-pk'})
+
     def test_clean_model_instance(self):
         f = forms.ModelChoiceField(Category.objects.all())
         self.assertEqual(f.clean(self.c1), self.c1)
         # An instance of incorrect model.
-        msg = "['Select a valid choice. That choice is not one of the available choices.']"
+        book = Book.objects.create()
+        msg = "['Select a valid choice. %s is not one of the available choices.']" % book
         with self.assertRaisesMessage(ValidationError, msg):
-            f.clean(Book.objects.create())
+            f.clean(book)
 
     def test_clean_to_field_name(self):
         f = forms.ModelChoiceField(Category.objects.all(), to_field_name='slug')
@@ -216,7 +240,10 @@ class ModelChoiceFieldTests(TestCase):
         form = ModelChoiceForm({}, instance=book)
         self.assertEqual(
             form.errors['author'],
-            ['Select a valid choice. That choice is not one of the available choices.']
+            [
+                'Select a valid choice. %s is not one of the available choices.' %
+                form.initial['author']
+            ],
         )
 
     def test_disabled_modelchoicefield_has_changed(self):
diff --git a/tests/model_forms/tests.py b/tests/model_forms/tests.py
index 9931fa50e3..d535a2ec8b 100755
--- a/tests/model_forms/tests.py
+++ b/tests/model_forms/tests.py
@@ -1675,7 +1675,7 @@ class ModelFormBasicTests(TestCase):
         self.assertIs(form.is_valid(), False)
         self.assertEqual(
             form.errors,
-            {'writer': ['Select a valid choice. That choice is not one of the available choices.']},
+            {'writer': ['Select a valid choice. %s is not one of the available choices.' % w.pk]},
         )
 
     def test_validate_foreign_key_to_model_with_overridden_manager(self):
diff --git a/tests/model_formsets/tests.py b/tests/model_formsets/tests.py
index 98fd501ad6..87a5a3489e 100755
--- a/tests/model_formsets/tests.py
+++ b/tests/model_formsets/tests.py
@@ -1748,7 +1748,10 @@ class ModelFormsetTest(TestCase):
         formset = AuthorFormSet(data)
         self.assertEqual(
             formset.errors,
-            [{'id': ['Select a valid choice. That choice is not one of the available choices.']}],
+            [{'id': [
+                'Select a valid choice. %s is not one of the available choices.' %
+                data['form-0-id']
+            ]}],
         )
 
     def test_validation_with_nonexistent_id(self):
@@ -1763,7 +1766,10 @@ class ModelFormsetTest(TestCase):
         formset = AuthorFormSet(data)
         self.assertEqual(
             formset.errors,
-            [{'id': ['Select a valid choice. That choice is not one of the available choices.']}],
+            [{'id': [
+                'Select a valid choice. %s is not one of the available choices.' %
+                data['form-0-id']
+            ]}],
         )
 
     def test_initial_form_count_empty_data(self):

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/forms/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 admin_widgets.tests forms_tests.tests.test_error_messages model_forms.test_modelchoicefield model_forms.tests model_formsets.tests
cat coverage.cover
git checkout 42e8cf47c7ee2db238bf91197ea398126c546741
git apply /root/pre_state.patch
