# -*- coding: utf-8 -*-
import logging
import os
import re
from collections import defaultdict
from functools import lru_cache

import httpx

include = re.compile(r"blog/[1-9].*")


PLAUSIBLE_BEARER_TOKEN = os.environ["PLAUSIBLE_BEARER_TOKEN"]

logger = logging.getLogger("mkdocs")
logger.setLevel(logging.INFO)


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not include.match(page.url):
        return markdown

    page_view = query_page_views()

    # NOTE: to keep backward compatibility, we remove the blog/ prefix
    old_url = page.url.replace("blog/", "")

    total_views = page_view[f"/{page.url}"] + page_view[f"/{old_url}"]
    if total_views:
        page.config.total_views = total_views
        logger.info(f"Total views for {page.url}: {page.config.total_views}")

    return markdown


@lru_cache(maxsize=1)
def query_page_views():
    page_view = defaultdict(int)
    with httpx.Client(
        base_url="https://analytics.developer-friendly.blog",
        headers={
            "authorization": f"Bearer {PLAUSIBLE_BEARER_TOKEN}",
            "user-agent": "Mozilla/5.0 (X11; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0",
        },
    ) as client:
        response = client.post(
            "/api/v2/query",
            json={
                "site_id": "developer-friendly.blog",
                "metrics": ["pageviews"],
                "date_range": "all",
                "dimensions": ["event:page"],
                "include": {"imports": True},
            },
        )
        for row in response.json()["results"]:
            if not (row["metrics"] and row["dimensions"]):
                logger.warning(f"Invalid row: {row}")
                continue
            page_view[row["dimensions"][0]] += row["metrics"][0]

        return page_view
