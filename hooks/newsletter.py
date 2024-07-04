# -*- coding: utf-8 -*-
import re
import os
from functools import lru_cache
from pathlib import Path

subscribe_comment = "<!-- subscribe -->"
include = re.compile(r"[1-9].*")


@lru_cache(maxsize=1)
def get_newsletter_element():
    current_dir = Path(__file__).parent
    form_filepath = current_dir / "email-form.html"

    with open(form_filepath, "r") as f:
        return f.read()


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not include.match(page.url):
        return markdown

    if subscribe_comment not in markdown:
        return markdown

    ck_property = os.getenv("CONVERTKIT_PROPERTY")
    if not ck_property:
        return markdown

    newsletter_element = get_newsletter_element()
    newsletter_form = newsletter_element.replace("CONVERTKIT_PROPERTY", ck_property)

    return markdown.replace(subscribe_comment, newsletter_form)
