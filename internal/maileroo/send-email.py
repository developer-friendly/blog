# -*- coding: utf-8 -*-
import subprocess
import tempfile
from pathlib import Path

from templator import get_html

rootdir = Path(__file__).resolve().parent


csv = f"{rootdir}/../concrete/contact-info.csv"
main = f"{rootdir}/main.py"

for email, html in get_html(csv):
    tmpfile = tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".html")

    with open(tmpfile.name, "w") as f:
        f.write(html)

    args = [
        main,
        "--to",
        f"Business <{email}>",
        "-s",
        "Collaboration Opportunity",
        "--email-content-filepath",
        tmpfile.name,
    ]

    rv = subprocess.run(args)
    print(rv)
