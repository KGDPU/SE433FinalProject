#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 1bd6a7a0acc11e249fca11c017505ad39f15ebf6 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 1bd6a7a0acc11e249fca11c017505ad39f15ebf6
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/tests/admin_inlines/tests.py b/tests/admin_inlines/tests.py
index 261c4f0148..fe9f6c6172 100755
--- a/tests/admin_inlines/tests.py
+++ b/tests/admin_inlines/tests.py
@@ -1013,6 +1013,56 @@ class TestVerboseNameInlineForms(TestDataMixin, TestCase):
         self.assertContains(response, 'Add another Model with both - name')
         self.assertNotContains(response, '<h2>Model with both - plural name</h2>')
 
+    def test_verbose_name_inline(self):
+        class NonVerboseProfileInline(TabularInline):
+            model = Profile
+            verbose_name = 'Non-verbose childs - name'
+
+        class VerboseNameProfileInline(TabularInline):
+            model = VerboseNameProfile
+            verbose_name = 'Childs with verbose name - name'
+
+        class VerboseNamePluralProfileInline(TabularInline):
+            model = VerboseNamePluralProfile
+            verbose_name = 'Childs with verbose name plural - name'
+
+        class BothVerboseNameProfileInline(TabularInline):
+            model = BothVerboseNameProfile
+            verbose_name = 'Childs with both - name'
+
+        modeladmin = ModelAdmin(ProfileCollection, admin_site)
+        modeladmin.inlines = [
+            NonVerboseProfileInline,
+            VerboseNameProfileInline,
+            VerboseNamePluralProfileInline,
+            BothVerboseNameProfileInline,
+        ]
+        obj = ProfileCollection.objects.create()
+        url = reverse('admin:admin_inlines_profilecollection_change', args=(obj.pk,))
+        request = self.factory.get(url)
+        request.user = self.superuser
+        response = modeladmin.changeform_view(request)
+        # The plural form defaults to the inline's verbose_name, regardless of
+        # the model's verbose_name and verbose_name_plural.
+        self.assertContains(response, '<h2>Non-verbose childs - names</h2>')
+        self.assertContains(response, 'Add another Non-verbose childs - name')
+        self.assertNotContains(response, '<h2>Profiles</h2>')
+        self.assertContains(response, '<h2>Childs with verbose name - names</h2>')
+        self.assertContains(response, 'Add another Childs with verbose name - name')
+        self.assertNotContains(response, '<h2>Model with verbose name onlys</h2>')
+        self.assertContains(
+            response,
+            '<h2>Childs with verbose name plural - names</h2>',
+        )
+        self.assertContains(
+            response,
+            'Add another Childs with verbose name plural - name',
+        )
+        self.assertNotContains(response, '<h2>Model with verbose name plural only</h2>')
+        self.assertContains(response, '<h2>Childs with both - names</h2>')
+        self.assertContains(response, 'Add another Childs with both - name')
+        self.assertNotContains(response, '<h2>Model with both - plural name</h2>')
+
     def test_both_verbose_names_inline(self):
         class NonVerboseProfileInline(TabularInline):
             model = Profile

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/options\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 admin_inlines.tests
cat coverage.cover
git checkout 1bd6a7a0acc11e249fca11c017505ad39f15ebf6
git apply /root/pre_state.patch
