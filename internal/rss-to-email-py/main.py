#!/usr/bin/env python
# -*- coding: utf-8 -*-
from logger import logger
from custom_types import Campaign
from cli import parser, default_send_at
from newsletter import (
    update_campaign,
    test_listmonk_campaign,
    update_campaign_template,
    prepare_html_for_newsletter,
    list_subscribers,
    create_campaign,
    list_lists,
)


if __name__ == "__main__":
    args = parser.parse_args()

    list_id = args.list
    campaign_name = args.campaign_name
    template_id = args.template
    campaign_id = args.campaign_id
    send_at = args.send_at or default_send_at()

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

    if args.subcommand == "modify-campaign":
        print(update_campaign(list_id).text)
    elif args.subcommand == "update-campaign":
        body = prepare_html_for_newsletter()
        campaign.body = body
        rv = update_campaign(campaign_id, campaign)
        logger.info(rv)
    elif args.subcommand == "update-and-test-campaign":
        print(update_campaign_template(template_id).status_code)
        print(test_listmonk_campaign(list_id, campaign_name).text)
    elif args.subcommand == "list-subscribers":
        print(list_subscribers().text)
    elif args.subcommand == "list-lists":
        print(list_lists().text)
    elif args.subcommand == "create-campaign":
        body = prepare_html_for_newsletter()
        campaign.body = body
        rv = create_campaign(campaign)
        logger.info(rv)
    else:
        parser.print_help()
