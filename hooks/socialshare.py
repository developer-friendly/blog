# -*- coding: utf-8 -*-
import re
import urllib.parse
from textwrap import dedent

x_intent = "https://twitter.com/intent/tweet"
x_id = "@devfriendly_"
_fb_sharer = "https://www.facebook.com/sharer/sharer.php"
lnkd_sharer = "https://www.linkedin.com/sharing/share-offsite/"
reddit_sharer = "https://www.reddit.com/submit"
hackernews = "https://news.ycombinator.com/submitlink"
include = re.compile(r"[1-9].*")


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not include.match(page.url):
        return markdown

    page_url = config.site_url + page.url
    page_title = urllib.parse.quote(page.title + "\n")
    page_title_x = urllib.parse.quote(f"{x_id}\n{page.title}\n")

    return markdown + dedent(
        f"""
    **If you enjoyed this blog post, consider sharing it with these buttons :point_down:. Please leave a comment for us at the end, we read & love 'em all. :heart_exclamation:**

    [Share on :fontawesome-brands-hacker-news:]({hackernews}?u={page_url}&t={page_title}){{ .md-button .md-button--primary }}
    [Share on :simple-linkedin:]({lnkd_sharer}?url={page_url}){{ .md-button .md-button--primary }}
    [Share on :simple-reddit:]({reddit_sharer}?url={page_url}&title={page_title}){{ .md-button .md-button--primary }}
    [Share on :simple-x:]({x_intent}?text={page_title_x}&url={page_url}){{ .md-button .md-button--primary }}
    """
    )
