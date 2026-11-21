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
diff --git a/django/conf/global_settings.py b/django/conf/global_settings.py
--- a/django/conf/global_settings.py
+++ b/django/conf/global_settings.py
@@ -304,7 +304,7 @@ def gettext_noop(s):
 
 # The numeric mode to set newly-uploaded files to. The value should be a mode
 # you'd pass directly to os.chmod; see https://docs.python.org/library/os.html#files-and-directories.
-FILE_UPLOAD_PERMISSIONS = None
+FILE_UPLOAD_PERMISSIONS = 0o644
 
 # The numeric mode to assign to newly-created directories, when uploading files.
 # The value should be a mode as you'd pass to os.chmod;

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/tests/file_storage/tests.py b/tests/file_storage/tests.py
index 434869554c..7e90a7224c 100755
--- a/tests/file_storage/tests.py
+++ b/tests/file_storage/tests.py
@@ -892,8 +892,28 @@ class FileStoragePermissions(unittest.TestCase):
         actual_mode = os.stat(self.storage.path(name))[0] & 0o777
         self.assertEqual(actual_mode, 0o654)
 
-    @override_settings(FILE_UPLOAD_PERMISSIONS=None)
     def test_file_upload_default_permissions(self):
+        self.storage = FileSystemStorage(self.storage_dir)
+        self.assertEqual(self.storage.file_permissions_mode, 0o644)
+
+        # Uploaded files should have the same permissions regardless of
+        # whether they were held in memory or in a temporary file. Temporary
+        # files may be created with restrictive permissions and moved into
+        # place without going through the normal file creation path.
+        with TemporaryUploadedFile('temporary.txt', 'text/plain', 4, 'utf8') as temp_file:
+            temp_file.write(b'data')
+            temp_file.seek(0)
+            temporary_name = self.storage.save('temporary.txt', temp_file)
+        memory_file = SimpleUploadedFile('memory.txt', b'data')
+        memory_name = self.storage.save('memory.txt', memory_file)
+
+        temporary_mode = os.stat(self.storage.path(temporary_name))[0] & 0o777
+        memory_mode = os.stat(self.storage.path(memory_name))[0] & 0o777
+        self.assertEqual(temporary_mode, 0o644)
+        self.assertEqual(memory_mode, 0o644)
+
+    @override_settings(FILE_UPLOAD_PERMISSIONS=None)
+    def test_file_upload_none_permissions(self):
         self.storage = FileSystemStorage(self.storage_dir)
         fname = self.storage.save("some_file", ContentFile("data"))
         mode = os.stat(self.storage.path(fname))[0] & 0o777

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(django/conf/global_settings\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 file_storage.tests
cat coverage.cover
git checkout e7fd69d051eaa67cb17f172a39b57253e9cb831a
git apply /root/pre_state.patch
