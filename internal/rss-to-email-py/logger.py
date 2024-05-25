# -*- coding: utf-8 -*-

import logging

import colorlog

from config import settings


logger = logging.getLogger("rss-to-email-py")
handler = logging.StreamHandler()
handler.setFormatter(
    colorlog.ColoredFormatter(
        "%(log_color)s%(asctime)s [%(levelname)s]: %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
        log_colors={
            "DEBUG": "cyan",
            "INFO": "green",
            "WARNING": "yellow",
            "ERROR": "red",
            "CRITICAL": "red,bg_white",
        },
    )
)
logging.basicConfig(
    level=settings.LOG_LEVEL,
    handlers=[handler],
)

additional_non_detected = [
    "httpx",
    "httpcore.connection",
    "httpcore.http11",
]

for logger_name in (
    list(logging.Logger.manager.loggerDict.keys()) + additional_non_detected
):
    if logger_name == "rss-to-email-py":
        continue
    logging.getLogger(logger_name).setLevel(logging.CRITICAL)
