"""Collect reproducible, dependency-free video module inventory."""

import ast
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VIDEO = ROOT / "Tools" / "video"


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def collect():
    modules = []
    for path in sorted(VIDEO.glob("*.py")):
        source = path.read_text()
        tree = ast.parse(source)
        imports = sorted({
            alias.name.split(".")[0]
            for node in ast.walk(tree)
            if isinstance(node, ast.Import)
            for alias in node.names
        } | {
            (node.module or "").split(".")[0]
            for node in ast.walk(tree)
            if isinstance(node, ast.ImportFrom)
        })
        modules.append({
            "path": str(path.relative_to(ROOT)),
            "physical_lines": len(source.splitlines()),
            "functions": sum(isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) for node in ast.walk(tree)),
            "classes": sum(isinstance(node, ast.ClassDef) for node in ast.walk(tree)),
            "imports": imports,
        })
    return {"commit": git("rev-parse", "HEAD"), "scope": "Tools/video/*.py", "modules": modules}


if __name__ == "__main__":
    print(json.dumps(collect(), indent=2, ensure_ascii=False))
