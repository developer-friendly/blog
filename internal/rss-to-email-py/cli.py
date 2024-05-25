# -*- coding: utf-8 -*-

from datetime import datetime, timedelta

import argparse


parser = argparse.ArgumentParser()

parser.add_argument(
    "subcommand",
    type=str,
    choices=[
        "modify-campaign",
        "update-and-test-campaign",
        "list-subscribers",
        "list-lists",
        "create-campaign",
        "update-campaign",
    ],
)
parser.add_argument("-l", "--list", type=int, default=4)
parser.add_argument(
    "-c",
    "--campaign-name",
    type=str,
    default=datetime.now().strftime("%b %d, %Y"),
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
    help="Defaults to next Monday at 8 UTC. Format: YYYY-MM-DDTHH:MM:SSZ00:00",
)


def default_send_at():
    today = datetime.now()
    next_monday = today + timedelta(days=(7 - today.weekday()))
    send_at = next_monday.replace(hour=8, minute=0, second=0)

    return send_at.strftime("%Y-%m-%dT%H:%M:%SZ")
