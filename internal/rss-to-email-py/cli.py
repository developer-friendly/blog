# -*- coding: utf-8 -*-

from datetime import datetime, timedelta
from custom_types import Cli

import argparse


parser = argparse.ArgumentParser()

parser.add_argument("subcommand", type=str, choices=[cli.value for cli in Cli])
parser.add_argument("-l", "--list", type=int, default=4)
parser.add_argument(
    "-c",
    "--campaign-name",
    type=str,
    default=None,
    help="Defaults to next Monday's date.",
)
parser.add_argument("-t", "--template", type=int, default=8)
parser.add_argument(
    "-s", "--subject", type=str, default="Site Reliability Engineering Newsletter"
)
parser.add_argument("-i", "--campaign-id", type=int, default=6)
parser.add_argument(
    "--send-at",
    type=str,
    default=None,
    help="Format: YYYY-MM-DDTHH:MM:SSZ00:00",
)
parser.add_argument(
    "-d", "--test-subscriber", type=str, default="meysam@developer-friendly.blog"
)
parser.add_argument(
    "--send-at-next-monday",
    action="store_true",
    default=False,
)


def next_monday():
    today = datetime.now()
    next_monday = today + timedelta(days=(7 - today.weekday()))
    send_at = next_monday.replace(hour=8, minute=0, second=0)

    return send_at
