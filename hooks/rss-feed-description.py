# -*- coding: utf-8 -*-
import re

from markdown import markdown as md_maker

include = re.compile(r"blog/[1-9].*")


def on_page_markdown(markdown, page, config, files):
    if not include.match(page.url):
        return markdown

    abstract_delimiter = config.plugins["rss"].config["abstract_delimiter"]
    excerpt_index = markdown.find(abstract_delimiter)
    if excerpt_index:
        excerpt = md_maker(markdown[:excerpt_index], output_format="html5")

        if page.meta.get("rss"):
            page.meta["rss"]["feed_description"] = excerpt
        else:
            page.meta["rss"] = {"feed_description": excerpt}

    if feed_description := page.meta.get("rss", {}).get("feed_description"):
        page.meta["rss"]["feed_description"] = md_maker(
            feed_description, output_format="html5"
        )

    return markdown


def on_page_content(html, page, config, files):
    if not include.match(page.url):
        return html
    return html
