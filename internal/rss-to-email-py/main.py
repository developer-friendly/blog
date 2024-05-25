#!/usr/bin/env python
# -*- coding: utf-8 -*-
from logger import logger
from cli import parser
from newsletter import (
    modify_listmonk_compaign,
    test_listmonk_campaign,
    update_campaign_template,
    list_subscribers,
    list_lists,
)


if __name__ == "__main__":
    args = parser.parse_args()

    list_id = args.list
    campaign_name = args.campaign_name
    template_id = args.template

    logger.info(f"List ID: {list_id}")
    logger.info(f"Campaign Name: {campaign_name}")
    logger.info(f"Template ID: {template_id}")

    if args.subcommand == "modify-campaign":
        print(modify_listmonk_compaign(list_id).text)
    elif args.subcommand == "update-and-test-campaign":
        print(update_campaign_template(template_id).status_code)
        print(test_listmonk_campaign(list_id, campaign_name).text)
    elif args.subcommand == "list-subscribers":
        print(list_subscribers().text)
    elif args.subcommand == "list-lists":
        print(list_lists().text)
    else:
        parser.print_help()
