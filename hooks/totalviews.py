# -*- coding: utf-8 -*-
import logging
import os
import re
from collections import defaultdict
from functools import lru_cache

import psycopg2

include = re.compile(r"[1-9].*")

page_view = defaultdict(int)

logger = logging.getLogger("mkdocs")
logger.setLevel(logging.INFO)

DSN = os.environ["GA_REPORTS_DSN"]


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not include.match(page.url):
        return markdown

    query_page_views()

    logger.info(f"Total views for {page.url}: {page_view[f'/{page.url}']}")
    page.config.total_views = page_view[f"/{page.url}"] or "N/A"

    return markdown


@lru_cache(maxsize=1)
def query_page_views():
    with psycopg2.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT page_path, SUM(views) AS total_views
                FROM total_views
                GROUP BY page_path
                ORDER BY total_views DESC;
                """
            )

            cols = [desc[0] for desc in cur.description]
            results = [dict(zip(cols, row)) for row in cur.fetchall()]

            page_view.update(
                {result["page_path"]: result["total_views"] for result in results}
            )

            return page_view
