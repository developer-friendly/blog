# -*- coding: utf-8 -*-

from .custom_types import Cli, CampaignStatus

import argparse


parser = argparse.ArgumentParser()

subparser = parser.add_subparsers(dest="subcommand")

customized = [
    Cli.CREATE_CAMPAIGN,
    Cli.UPDATE_CAMPAIGN,
    Cli.TEST_CAMPAIGN,
    Cli.CHANGE_CAMPAIGN_STATUS,
]

# global
for cli in Cli:
    if cli not in customized:
        subparser.add_parser(cli.value)

parser.add_argument("-l", "--list", type=int, default=4)
parser.add_argument(
    "-n",
    "--campaign-name",
    type=str,
    default=None,
    help="Defaults to next Monday's date.",
)
parser.add_argument("-t", "--template", type=int, default=8)
parser.add_argument(
    "-s", "--subject", type=str, default="Site Reliability Engineering Newsletter"
)
parser.add_argument("-c", "--campaign-id", type=int, default=6)

# test campaign
test_subscriber = subparser.add_parser(Cli.TEST_CAMPAIGN.value)
test_subscriber.add_argument(
    "-d", "--test-subscriber", type=str, default="meysam@developer-friendly.blog"
)

# create campaign
create_campaign = subparser.add_parser(Cli.CREATE_CAMPAIGN.value)
create_campaign.add_argument(
    "--send-at",
    type=str,
    default=None,
    help="Format: YYYY-MM-DDTHH:MM:SSZ00:00",
)
create_campaign.add_argument(
    "--send-at-next-monday",
    action="store_true",
    default=False,
)

# update campaign
update_campaign = subparser.add_parser(Cli.UPDATE_CAMPAIGN.value)
update_campaign.add_argument(
    "--send-at",
    type=str,
    default=None,
    help="Format: YYYY-MM-DDTHH:MM:SSZ00:00",
)
update_campaign.add_argument(
    "--send-at-next-monday",
    action="store_true",
    default=False,
)

# change campaign status
change_campaign_status = subparser.add_parser(Cli.CHANGE_CAMPAIGN_STATUS.value)
change_campaign_status.add_argument(
    "-s",
    "--status",
    type=str,
    choices=[status.value for status in CampaignStatus],
    required=True,
)
