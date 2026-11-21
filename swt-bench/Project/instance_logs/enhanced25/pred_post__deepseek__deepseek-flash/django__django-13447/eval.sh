#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 0456d3e42795481a186db05719300691fe2a1029 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 0456d3e42795481a186db05719300691fe2a1029
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/admin/sites.py b/django/contrib/admin/sites.py
--- a/django/contrib/admin/sites.py
+++ b/django/contrib/admin/sites.py
@@ -461,6 +461,7 @@ def _build_app_dict(self, request, label=None):
 
             info = (app_label, model._meta.model_name)
             model_dict = {
+                'model': model,
                 'name': capfirst(model._meta.verbose_name_plural),
                 'object_name': model._meta.object_name,
                 'perms': perms,

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/tests/admin_views/tests.py b/tests/admin_views/tests.py
index b1658941ee..2dc8bb32d1 100755
--- a/tests/admin_views/tests.py
+++ b/tests/admin_views/tests.py
@@ -1070,6 +1070,41 @@ class AdminViewBasicTest(AdminViewBasicTestCase):
         self.assertEqual(response.context['title'], 'Admin_Views administration')
         self.assertEqual(response.context['app_label'], 'admin_views')
 
+    def test_app_list_models_include_model_classes(self):
+        response = self.client.get(reverse('admin:index'))
+        models = {
+            model_dict['object_name']: model_dict['model']
+            for app in response.context['app_list']
+            for model_dict in app['models']
+        }
+        self.assertIs(models['Article'], Article)
+
+    def test_app_index_app_list_models_include_model_classes(self):
+        response = self.client.get(reverse('admin:app_list', args=('admin_views',)))
+        models = {
+            model_dict['object_name']: model_dict['model']
+            for app in response.context['app_list']
+            for model_dict in app['models']
+        }
+        self.assertIs(models['Article'], Article)
+
+    def test_build_app_dict_includes_model_class(self):
+        response = self.client.get(reverse('admin:index'))
+        app_dict = site.build_app_dict(response.wsgi_request)
+        models = {
+            model_dict['object_name']: model_dict['model']
+            for app in app_dict.values()
+            for model_dict in app['models']
+        }
+        self.assertIs(models['Article'], Article)
+
+        app_dict = site.build_app_dict(response.wsgi_request, 'admin_views')
+        models = {
+            model_dict['object_name']: model_dict['model']
+            for model_dict in app_dict['models']
+        }
+        self.assertIs(models['Article'], Article)
+
     def test_change_view_subtitle_per_object(self):
         response = self.client.get(
             reverse('admin:admin_views_article_change', args=(self.a1.pk,)),

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/sites\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 admin_views.tests
cat coverage.cover
git checkout 0456d3e42795481a186db05719300691fe2a1029
git apply /root/pre_state.patch
