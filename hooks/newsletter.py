# -*- coding: utf-8 -*-
import re
import os

subscribe_comment = "<!-- subscribe -->"
newsletter_script = '<script async data-uid="CONVERTKIT_PROPERTY" src="https://developer-friendly.ck.page/CONVERTKIT_PROPERTY/index.js"></script>'
include = re.compile(r"[1-9].*")


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not include.match(page.url):
        return markdown

    if subscribe_comment not in markdown:
        return markdown

    convertkit_property = os.getenv("CONVERTKIT_PROPERTY")
    if not convertkit_property:
        return markdown

    convertkit_property = newsletter_script.replace(
        "CONVERTKIT_PROPERTY", convertkit_property
    )

    return markdown.replace(subscribe_comment, convertkit_property)
