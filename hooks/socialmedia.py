# -*- coding: utf-8 -*-
from textwrap import dedent
import urllib.parse
import re

x_intent = "https://twitter.com/intent/tweet"
x_id = "@devfriendly_"
fb_sharer = "https://www.facebook.com/sharer/sharer.php"
lnkd_sharer = "https://www.linkedin.com/sharing/share-offsite/"
reddit_sharer = "https://www.reddit.com/submit"
include = re.compile(r"[1-9].*")


def on_page_markdown(markdown, **kwargs):
    page = kwargs["page"]
    config = kwargs["config"]
    if not include.match(page.url):
        return markdown

    page_url = config.site_url + page.url
    _page_title = urllib.parse.quote(page.title + "\n")
    page_title_x = urllib.parse.quote(f"{x_id}\n{page.title}\n")

    return markdown + dedent(
        f"""
    [Share on :simple-linkedin:]({lnkd_sharer}?url={page_url}){{ .md-button .md-button--primary }}
    [Share on :simple-reddit:]({reddit_sharer}?url={page_url}&title={_page_title}){{ .md-button .md-button--primary }}
    [Share on :simple-x:]({x_intent}?text={page_title_x}&url={page_url}){{ .md-button .md-button--primary }}
    [Share on :simple-facebook:]({fb_sharer}?u={page_url}){{ .md-button .md-button--primary }}
    """
    )
