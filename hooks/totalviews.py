# -*- coding: utf-8 -*-
import logging
import os
import re
from collections import defaultdict
from functools import lru_cache

from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange,
    Dimension,
    Metric,
    RunReportRequest,
)

start_date = os.getenv("GA4_START_DATE", "2024-02-13")
include = re.compile(r"[1-9].*")

page_view = defaultdict(int)

logger = logging.getLogger("mkdocs")
logger.setLevel(logging.INFO)


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not os.getenv("GA4_PROPERTY"):
        return markdown

    if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        return markdown

    if not include.match(page.url):
        return markdown

    sample_run_report(os.environ["GA4_PROPERTY"])

    logger.info(f"Total views for {page.url}: {page_view[f'/{page.url}']}")
    page.config.total_views = page_view[f"/{page.url}"] or "N/A"

    return markdown


@lru_cache(maxsize=1)
def sample_run_report(property_id):
    client = BetaAnalyticsDataClient()

    request = RunReportRequest(
        property=f"properties/{property_id}",
        dimensions=[Dimension(name="pagePath")],
        metrics=[Metric(name="screenPageViews")],
        date_ranges=[DateRange(start_date=start_date, end_date="today")],
    )
    response = client.run_report(request)

    for row in response.rows:
        page_view[row.dimension_values[0].value] = row.metric_values[0].value

    return page_view


if __name__ == "__main__":
    from pprint import pprint as pp

    pp(sample_run_report(os.environ["GA4_PROPERTY"]))
