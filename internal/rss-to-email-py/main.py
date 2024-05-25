#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
from logger import logger
from custom_types import Campaign, Cli
from cli import parser, default_send_at
from newsletter import (
    update_campaign,
    test_campaign,
    prepare_html_for_newsletter,
    create_campaign,
    update_template,
    list_subscribers,
    list_lists,
)


if __name__ == "__main__":
    args = parser.parse_args()

    list_id = args.list
    campaign_name = args.campaign_name
    template_id = args.template
    campaign_id = args.campaign_id
    send_at = args.send_at or default_send_at()
    test_subscriber = args.test_subscriber

    campaign = Campaign(
        name=campaign_name,
        subject=args.subject,
        lists=[list_id],
        type="regular",
        content_type="html",
        body="",
        template_id=template_id,
        send_at=send_at,
    )
    logger.debug(f"List ID: {list_id}")
    logger.debug(f"Campaign Name: {campaign_name}")
    logger.debug(f"Template ID: {template_id}")
    logger.debug(f"Campaign ID: {campaign_id}")
    logger.debug(f"Send At: {send_at}")
    logger.debug(f"Campaign: {campaign.model_dump(by_alias=True, exclude_none=True)}")

    if args.subcommand == Cli.UPDATE_CAMPAIGN:
        body = prepare_html_for_newsletter()
        campaign.body = body
        rv = update_campaign(campaign_id, campaign)
        logger.info(rv)
    elif args.subcommand == Cli.CREATE_CAMPAIGN:
        body = prepare_html_for_newsletter()
        campaign.body = body
        rv = create_campaign(campaign)
        logger.info(rv)
    elif args.subcommand == Cli.TEST_CAMPAIGN:
        body = prepare_html_for_newsletter()
        campaign.body = body
        rv = test_campaign(campaign_id, campaign, [test_subscriber])
        logger.info(rv)
    elif args.subcommand == Cli.UPDATE_TEMPLATE:
        file_rootdir = os.path.dirname(os.path.realpath(__file__))
        with open(f"{file_rootdir}/templates/newsletter.html", "r") as file:
            new_template = file.read()
        rv = update_template(template_id, new_template)
        logger.info(rv)
    elif args.subcommand == Cli.LIST_SUBSCRIBERS:
        rv = list_subscribers()
        logger.debug(rv)
        print(rv)
    elif args.subcommand == Cli.LIST_LISTS:
        rv = list_lists()
        logger.debug(rv)
        print(rv)
    else:
        parser.print_help()
