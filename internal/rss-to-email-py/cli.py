# -*- coding: utf-8 -*-

from datetime import datetime

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
