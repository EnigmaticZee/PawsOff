#!/usr/bin/env python3
"""Turns one version's entry in docs/HISTORY.md into the small page shown in the Mac update window.

Usage: python3 Tools/release-notes-html.py <version>   (prints HTML)

The update feed (appcast.xml) carries this page inline, so the update window shows just the notes,
styled for light and dark, instead of loading the whole GitHub release page. Handles the Markdown
that HISTORY.md uses: paragraphs, "- " bullets (with wrapped lines), **bold**, *italics*, `code`
and [links](https://...).
"""
import html
import re
import sys
from pathlib import Path

VERSION = sys.argv[1]
HISTORY = Path(__file__).resolve().parent.parent / "docs" / "HISTORY.md"


def section(version):
    lines, on = [], False
    for line in HISTORY.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            if on:
                break
            on = line.startswith(f"## {version} ")
            continue
        if on:
            lines.append(line)
    if not lines:
        sys.exit(f"No entry for {version} in docs/HISTORY.md")
    return lines


def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?![*\w])", r"<em>\1</em>", text)
    text = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)", r'<a href="\2">\1</a>', text)
    return text


def body(lines):
    blocks, para, items = [], [], []

    def flush_para():
        if para:
            blocks.append(f"<p>{inline(' '.join(para))}</p>")
            para.clear()

    def flush_list():
        if items:
            blocks.append("<ul>" + "".join(f"<li>{inline(i)}</li>" for i in items) + "</ul>")
            items.clear()

    for raw in lines:
        line = raw.rstrip()
        if not line.strip():
            flush_para()
            flush_list()
        elif line.startswith("- "):
            flush_para()
            items.append(line[2:].strip())
        elif line.startswith("  ") and items:
            items[-1] += " " + line.strip()
        else:
            flush_list()
            para.append(line.strip())
    flush_para()
    flush_list()
    return "\n".join(blocks)


STYLE = """
:root { color-scheme: light dark; --ink: #1b1726; --soft: #6b6478; --accent: #e8573f; --line: rgba(0,0,0,.08); }
@media (prefers-color-scheme: dark) { :root { --ink: #f3f0f8; --soft: #a49db2; --accent: #ff8a72; --line: rgba(255,255,255,.1); } }
html { -webkit-text-size-adjust: none; }
body { margin: 0; padding: 14px 18px 16px; font: 13px/1.5 -apple-system, BlinkMacSystemFont, sans-serif; color: var(--ink); }
p { margin: 0 0 10px; }
body > p:first-child { font-size: 15px; font-weight: 600; letter-spacing: -.01em; }
ul { list-style: none; margin: 0 0 12px; padding: 0; }
li { position: relative; padding: 0 0 8px 18px; }
li::before { content: ""; position: absolute; left: 3px; top: .62em; width: 6px; height: 6px; border-radius: 3px; background: var(--accent); }
strong { font-weight: 600; }
code { font: 12px ui-monospace, Menlo, monospace; padding: 1px 4px; border-radius: 4px; background: var(--line); }
a { color: var(--accent); text-decoration: none; }
footer { margin-top: 4px; padding-top: 10px; border-top: 1px solid var(--line); color: var(--soft); font-size: 12px; }
"""

print(f"""<!doctype html>
<html><head><meta charset="utf-8"><style>{STYLE}</style></head>
<body>
{body(section(VERSION))}
<footer><a href="https://github.com/EnigmaticZee/PawsOff/releases">Every version, every paw print &rarr;</a></footer>
</body></html>""")
