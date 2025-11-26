# -*- coding: utf-8 -*-
import logging
import os
import re
from collections import defaultdict
from functools import lru_cache

import httpx

include = re.compile(r"blog/[1-9].*")

PIRSCH_CLIENT_ID = os.environ["PIRSCH_CLIENT_ID"]
PIRSCH_CLIENT_SECRET = os.environ["PIRSCH_CLIENT_SECRET"]
PIRSCH_HOSTNAME = os.environ.get("PIRSCH_HOSTNAME", "developer-friendly.blog")

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
def get_access_token():
    with httpx.Client(base_url="https://api.pirsch.io") as client:
        response = client.post(
            "/api/v1/token",
            json={
                "client_id": PIRSCH_CLIENT_ID,
                "client_secret": PIRSCH_CLIENT_SECRET,
            },
        )
        response.raise_for_status()
        return response.json().get("access_token")


@lru_cache(maxsize=1)
def get_domain_id(access_token, hostname):
    with httpx.Client(
        base_url="https://api.pirsch.io",
        headers={"Authorization": f"Bearer {access_token}"},
    ) as client:
        response = client.get("/api/v1/domain")
        response.raise_for_status()
        domains = response.json()
        for domain in domains:
            if domain.get("hostname") == hostname:
                return domain.get("id")
    logger.error(f"No matching domain found for hostname: {hostname}")
    return None


@lru_cache(maxsize=1)
def query_page_views():
    page_view = defaultdict(int)
    try:
        access_token = get_access_token()
        domain_id = get_domain_id(access_token, PIRSCH_HOSTNAME)

        if not domain_id:
            return page_view

        with httpx.Client(
            base_url="https://api.pirsch.io",
            headers={"Authorization": f"Bearer {access_token}"},
        ) as client:
            response = client.get(
                "/api/v1/statistics/page",
                params={
                    "id": domain_id,
                    "from": "2020-01-01",
                    "to": "2099-12-31",
                },
            )
            response.raise_for_status()
            for row in response.json():
                path = row.get("path", "")
                views = row.get("views", 0)
                if path:
                    base_path = path.split("#")[0]
                    page_view[base_path] += views

    except httpx.HTTPStatusError as e:
        logger.info(f"Failed to query page views: {e}")

    return page_view
