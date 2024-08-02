# -*- coding: utf-8 -*-
import csv
import sys
from pathlib import Path

from jinja2 import Environment, FileSystemLoader

rootdir = Path(__file__).resolve().parent

env = Environment(loader=FileSystemLoader(searchpath=f"{rootdir}/templates"))
template = env.get_template("affiliate-template.html.j2")


def get_html(contact_info):
    with open(contact_info) as f:
        reader = csv.DictReader(f)
        for row in reader:
            email = row["email"]
            yield (email, template.render(row))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide the path to the contact info CSV file")
        sys.exit(1)

    contact_info = sys.argv[1]

    for _email, content in get_html(contact_info):
        print(content)
