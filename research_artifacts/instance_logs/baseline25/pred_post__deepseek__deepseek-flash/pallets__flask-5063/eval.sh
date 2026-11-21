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
diff --git a/src/flask/cli.py b/src/flask/cli.py
--- a/src/flask/cli.py
+++ b/src/flask/cli.py
@@ -9,7 +9,7 @@
 import traceback
 import typing as t
 from functools import update_wrapper
-from operator import attrgetter
+from operator import itemgetter
 
 import click
 from click.core import ParameterSource
@@ -989,49 +989,62 @@ def shell_command() -> None:
 @click.option(
     "--sort",
     "-s",
-    type=click.Choice(("endpoint", "methods", "rule", "match")),
+    type=click.Choice(("endpoint", "methods", "domain", "rule", "match")),
     default="endpoint",
     help=(
-        'Method to sort routes by. "match" is the order that Flask will match '
-        "routes when dispatching a request."
+        "Method to sort routes by. 'match' is the order that Flask will match routes"
+        " when dispatching a request."
     ),
 )
 @click.option("--all-methods", is_flag=True, help="Show HEAD and OPTIONS methods.")
 @with_appcontext
 def routes_command(sort: str, all_methods: bool) -> None:
     """Show all registered routes with endpoints and methods."""
-
     rules = list(current_app.url_map.iter_rules())
+
     if not rules:
         click.echo("No routes were registered.")
         return
 
-    ignored_methods = set(() if all_methods else ("HEAD", "OPTIONS"))
+    ignored_methods = set() if all_methods else {"HEAD", "OPTIONS"}
+    host_matching = current_app.url_map.host_matching
+    has_domain = any(rule.host if host_matching else rule.subdomain for rule in rules)
+    rows = []
 
-    if sort in ("endpoint", "rule"):
-        rules = sorted(rules, key=attrgetter(sort))
-    elif sort == "methods":
-        rules = sorted(rules, key=lambda rule: sorted(rule.methods))  # type: ignore
+    for rule in rules:
+        row = [
+            rule.endpoint,
+            ", ".join(sorted((rule.methods or set()) - ignored_methods)),
+        ]
 
-    rule_methods = [
-        ", ".join(sorted(rule.methods - ignored_methods))  # type: ignore
-        for rule in rules
-    ]
+        if has_domain:
+            row.append((rule.host if host_matching else rule.subdomain) or "")
 
-    headers = ("Endpoint", "Methods", "Rule")
-    widths = (
-        max(len(rule.endpoint) for rule in rules),
-        max(len(methods) for methods in rule_methods),
-        max(len(rule.rule) for rule in rules),
-    )
-    widths = [max(len(h), w) for h, w in zip(headers, widths)]
-    row = "{{0:<{0}}}  {{1:<{1}}}  {{2:<{2}}}".format(*widths)
+        row.append(rule.rule)
+        rows.append(row)
+
+    headers = ["Endpoint", "Methods"]
+    sorts = ["endpoint", "methods"]
+
+    if has_domain:
+        headers.append("Host" if host_matching else "Subdomain")
+        sorts.append("domain")
+
+    headers.append("Rule")
+    sorts.append("rule")
+
+    try:
+        rows.sort(key=itemgetter(sorts.index(sort)))
+    except ValueError:
+        pass
 
-    click.echo(row.format(*headers).strip())
-    click.echo(row.format(*("-" * width for width in widths)))
+    rows.insert(0, headers)
+    widths = [max(len(row[i]) for row in rows) for i in range(len(headers))]
+    rows.insert(1, ["-" * w for w in widths])
+    template = "  ".join(f"{{{i}:<{w}}}" for i, w in enumerate(widths))
 
-    for rule, methods in zip(rules, rule_methods):
-        click.echo(row.format(rule.endpoint, methods, rule.rule).rstrip())
+    for row in rows:
+        click.echo(template.format(*row))
 
 
 cli = FlaskGroup(

EOF_114329324912
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
