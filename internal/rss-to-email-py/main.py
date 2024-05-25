#!/usr/bin/env python
# -*- coding: utf-8 -*-
from datetime import datetime
from typing import Optional
from time import mktime

import argparse

import pydantic
import feedparser
import httpx
import os

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

url = "https://developer-friendly.blog/feed_rss_created.xml"
authorization = os.environ["LISTMONK_AUTHORIZATION"]
headers = {
    "authorization": f"Basic {authorization}",
    "accept": "application/json",
}


class Author(pydantic.BaseModel):
    name: str
    email: Optional[str]


class FeedEntry(pydantic.BaseModel):
    title: str
    authors: list[Author]
    summary: str
    link: str
    image: Optional[str]
    published_parsed: datetime


def get_latest_post():
    feed = feedparser.parse(url)

    return feed.entries[0]


def extract_to_feed_entry():
    latest_post = get_latest_post()

    entry = FeedEntry(
        title=latest_post.title,
        authors=[
            Author(name=author.name, email=author.email)
            for author in latest_post.authors
        ],
        image=next(
            (link.href for link in latest_post.links if link.type == "image/png"),
            None,
        ),
        summary=latest_post.summary,
        link=latest_post.link,
        published_parsed=datetime.fromtimestamp(mktime(latest_post.published_parsed)),
    )

    return entry


def prepare_html_for_newsletter():
    entry = extract_to_feed_entry()
    image = f"<img src='{entry.image}' />" if entry.image else ""
    published_date = entry.published_parsed.strftime("%b %d, %Y")

    continue_reading = f"""<p><a href="{entry.link}">Continue reading...</a></p>"""

    html = f"""
    <h1><a href="{entry.link}">{image}{entry.title}</a></h1>
    <p>{entry.summary}</p>
    {continue_reading}
    <p>Published on: {published_date}</p>
    """

    return html.strip()


def modify_listmonk_compaign():
    return httpx.put(
        "https://newsletter.developer-friendly.blog/api/campaigns/5",
        headers=headers,
        json=dict(
            content_type="html",
            lists=[4],
            body=prepare_html_for_newsletter(),
        ),
    )


def test_listmonk_campaign():
    return httpx.post(
        "https://newsletter.developer-friendly.blog/api/campaigns/5/test",
        headers=headers,
        json=dict(
            subscribers=["meysam@developer-friendly.blog"],
            name="may-21-2024",
            subject="Developer Friendly Blog Newsletter",
            lists=[4],
            messenger="email",
            body=prepare_html_for_newsletter(),
        ),
    )


def update_campaign_template():
    file_rootdir = os.path.dirname(os.path.realpath(__file__))
    with open(f"{file_rootdir}/templates/newsletter.html", "r") as file:
        body = file.read()

    return httpx.put(
        "https://newsletter.developer-friendly.blog/api/templates/8",
        headers=headers,
        json=dict(
            name="developer-friendly-newsletter",
            type="campaign",
            body=body,
        ),
    )


def list_subscribers():
    return httpx.get(
        "https://newsletter.developer-friendly.blog/api/subscribers",
        headers=headers,
    )


def list_lists():
    return httpx.get(
        "https://newsletter.developer-friendly.blog/api/lists",
        headers=headers,
    )


if __name__ == "__main__":
    args = parser.parse_args()
    if args.subcommand == "modify-campaign":
        print(modify_listmonk_compaign().text)
    elif args.subcommand == "update-and-test-campaign":
        print(update_campaign_template().status_code)
        print(test_listmonk_campaign().text)
    elif args.subcommand == "list-subscribers":
        print(list_subscribers().text)
    elif args.subcommand == "list-lists":
        print(list_lists().text)
    else:
        parser.print_help()
