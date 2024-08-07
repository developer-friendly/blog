#!/usr/bin/env python
# -*- coding: utf-8 -*-
import atexit
import logging
from argparse import ArgumentParser
from collections import defaultdict
from functools import lru_cache

import colorlog
import psycopg2
import pydantic
import pydantic_settings
from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange,
    Dimension,
    DimensionExpression,
    Metric,
    RunReportRequest,
)


class Settings(pydantic_settings.BaseSettings):
    COLOR_LOGS: bool = True
    GA_REPORTS_DSN: pydantic.SecretStr
    GA4_PROPERTY: str
    GA4_START_DATE: str = "2024-02-13"
    LOG_LEVEL: str = "INFO"

    @pydantic.field_validator("LOG_LEVEL")
    @classmethod
    def log_level(cls, v: str) -> str:
        v = v.upper()
        if v not in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
            raise ValueError("must be a valid log level")
        return v


def get_logger(level="INFO", colored=True):
    logger = logging.getLogger(__name__)
    logger.setLevel(level)

    handler = logging.StreamHandler()
    handler.setLevel(level)

    if colored:
        formatter = colorlog.ColoredFormatter(
            "%(log_color)s[%(levelname)s] %(asctime)s - %(filename)s:%(lineno)d - %(message)s",
            log_colors={
                "DEBUG": "cyan",
                "INFO": "green",
                "WARNING": "yellow",
                "ERROR": "red",
                "CRITICAL": "bold_red",
            },
        )
    else:
        formatter = logging.Formatter(
            "[%(levelname)s] %(asctime)s - %(filename)s:%(lineno)d - %(message)s"
        )
    handler.setFormatter(formatter)

    logger.addHandler(handler)

    return logger


settings = Settings()

start_date = settings.GA4_START_DATE

page_view = defaultdict(dict)
DSN = settings.GA_REPORTS_DSN.get_secret_value()

logger = get_logger(settings.LOG_LEVEL)

parser = ArgumentParser()

parser.add_argument("action", choices=["migrate", "update", "query"])


@lru_cache(maxsize=1)
def get_db():
    conn = psycopg2.connect(DSN)
    return conn


def close_db_connection():
    conn = get_db()
    if conn:
        logger.info("Closing DB connection...")
        conn.close()
        logger.info("DB connection closed.")


atexit.register(close_db_connection)


def sample_run_report(property_id):
    client = BetaAnalyticsDataClient()

    request = RunReportRequest(
        property=f"properties/{property_id}",
        dimensions=[
            Dimension(name="pagePath"),
            Dimension(
                name="date",
                dimension_expression=DimensionExpression(
                    concatenate=DimensionExpression.ConcatenateExpression(
                        dimension_names=["year", "month"], delimiter="-"
                    )
                ),
            ),
        ],
        metrics=[Metric(name="screenPageViews")],
        date_ranges=[DateRange(start_date=start_date, end_date="today")],
    )
    response = client.run_report(request)

    for row in response.rows:
        page_path = row.dimension_values[0].value
        month = row.dimension_values[1].value
        views = int(row.metric_values[0].value)
        page_view[page_path][month] = views

    return page_view


def migration():
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS total_views (
                    page_path TEXT NOT NULL,
                    month TEXT NOT NULL,
                    views INT NOT NULL,
                    PRIMARY KEY (page_path, month)
                )
            """
            )

            return cur.rowcount


def update_db():
    with get_db() as conn:
        with conn.cursor() as cur:
            data = [
                {"page_path": page_path, "month": month, "views": views}
                for page_path, views_per_month in page_view.items()
                for month, views in views_per_month.items()
            ]
            cur.executemany(
                """
                INSERT INTO total_views (page_path, month, views)
                VALUES (%(page_path)s, %(month)s, %(views)s)
                ON CONFLICT (page_path, month)
                DO UPDATE SET views = EXCLUDED.views
                """,
                data,
            )

            return cur.rowcount


def query_page_views():
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT page_path, SUM(views) as total_views
                FROM total_views
                GROUP BY page_path
                ORDER BY total_views DESC;
                """
            )

            cols = [desc[0] for desc in cur.description]
            results = [dict(zip(cols, row)) for row in cur.fetchall()]

            return {result["page_path"]: result["total_views"] for result in results}


if __name__ == "__main__":
    args = parser.parse_args()

    match args.action:
        case "migrate":
            logger.info(("Migration result", migration()))
        case "update":
            logger.info(("Update DB result", update_db()))
        case "query":
            logger.info(("Query result", query_page_views()))
        case _:
            logger.error("Invalid action")
