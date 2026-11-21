#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e7fd69d051eaa67cb17f172a39b57253e9cb831a >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e7fd69d051eaa67cb17f172a39b57253e9cb831a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/tests/file_storage/tests.py b/tests/file_storage/tests.py
index 434869554c..e66c6e98c4 100755
--- a/tests/file_storage/tests.py
+++ b/tests/file_storage/tests.py
@@ -892,8 +892,24 @@ class FileStoragePermissions(unittest.TestCase):
         actual_mode = os.stat(self.storage.path(name))[0] & 0o777
         self.assertEqual(actual_mode, 0o654)
 
-    @override_settings(FILE_UPLOAD_PERMISSIONS=None)
     def test_file_upload_default_permissions(self):
+        self.storage = FileSystemStorage(self.storage_dir)
+        self.assertEqual(self.storage.file_permissions_mode, 0o644)
+        fname = self.storage.save("some_file", ContentFile("data"))
+        mode = os.stat(self.storage.path(fname))[0] & 0o777
+        self.assertEqual(mode, 0o644)
+
+    def test_file_upload_default_permissions_temporary_file(self):
+        self.storage = FileSystemStorage(self.storage_dir)
+        with TemporaryUploadedFile('test', 'text/plain', 4, 'utf8') as uploaded_file:
+            uploaded_file.write(b'data')
+            uploaded_file.seek(0)
+            fname = self.storage.save("temporary_file", uploaded_file)
+        mode = os.stat(self.storage.path(fname))[0] & 0o777
+        self.assertEqual(mode, 0o644)
+
+    @override_settings(FILE_UPLOAD_PERMISSIONS=None)
+    def test_file_upload_setting_none(self):
         self.storage = FileSystemStorage(self.storage_dir)
         fname = self.storage.save("some_file", ContentFile("data"))
         mode = os.stat(self.storage.path(fname))[0] & 0o777

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/conf/global_settings\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 file_storage.tests
cat coverage.cover
git checkout e7fd69d051eaa67cb17f172a39b57253e9cb831a
git apply /root/pre_state.patch
