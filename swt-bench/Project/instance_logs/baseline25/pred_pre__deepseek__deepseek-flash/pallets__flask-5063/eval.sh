#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 182ce3dd15dfa3537391c3efaf9c3ff407d134d4 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 182ce3dd15dfa3537391c3efaf9c3ff407d134d4
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/tests/test_cli.py b/tests/test_cli.py
index 0d9625b1..ace5df06 100755
--- a/tests/test_cli.py
+++ b/tests/test_cli.py
@@ -498,6 +498,48 @@ class TestRoutes:
         assert result.exit_code == 0
         assert "No routes were registered." in result.output
 
+    def test_subdomain(self, runner):
+        app = Flask(__name__, static_folder=None)
+        app.add_url_rule("/a", subdomain="a", endpoint="a")
+        app.add_url_rule("/b", subdomain="b", endpoint="b")
+        cli = FlaskGroup(create_app=lambda: app)
+        result = runner.invoke(cli, ["routes"])
+        assert result.exit_code == 0
+        assert result.output.splitlines()[0].split() == [
+            "Endpoint",
+            "Methods",
+            "Subdomain",
+            "Rule",
+        ]
+        rows = {}
+
+        for line in result.output.splitlines()[2:]:
+            endpoint, _, subdomain, rule = line.split()
+            rows[endpoint] = (subdomain, rule)
+
+        assert rows == {"a": ("a", "/a"), "b": ("b", "/b")}
+
+    def test_host(self, runner):
+        app = Flask(__name__, static_folder=None, host_matching=True)
+        app.add_url_rule("/a", host="a", endpoint="a")
+        app.add_url_rule("/b", host="b", endpoint="b")
+        cli = FlaskGroup(create_app=lambda: app)
+        result = runner.invoke(cli, ["routes"])
+        assert result.exit_code == 0
+        assert result.output.splitlines()[0].split() == [
+            "Endpoint",
+            "Methods",
+            "Host",
+            "Rule",
+        ]
+        rows = {}
+
+        for line in result.output.splitlines()[2:]:
+            endpoint, _, host, rule = line.split()
+            rows[endpoint] = (host, rule)
+
+        assert rows == {"a": ("a", "/a"), "b": ("b", "/b")}
+
 
 def dotenv_not_available():
     try:

EOF_114329324912
python3 /root/trace.py --count -C coverage.cover --include-pattern '/testbed/(src/flask/cli\.py)' -m pytest --no-header -rA  -p no:cacheprovider tests/test_cli.py
cat coverage.cover
git checkout 182ce3dd15dfa3537391c3efaf9c3ff407d134d4
git apply /root/pre_state.patch
