# -*- coding: utf-8 -*-
from datetime import datetime
from time import mktime


import feedparser
import httpx
import os

from .logger import logger
from .custom_types import Author, FeedEntry, Campaign


url = "https://developer-friendly.blog/feed_rss_created.xml"
base_url = "https://newsletter.developer-friendly.blog"
authorization = os.environ["LISTMONK_AUTHORIZATION"]
headers = {
    "authorization": f"Basic {authorization}",
    "accept": "application/json",
}


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


def update_campaign(campaign_id: int, campaign: Campaign):
    response = httpx.put(
        f"{base_url}/api/campaigns/{campaign_id}",
        headers=headers,
        json=campaign.model_dump(by_alias=True),
    )
    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def create_campaign(campaign: Campaign):
    response = httpx.post(
        f"{base_url}/api/campaigns",
        headers=headers,
        json=campaign.model_dump(by_alias=True),
    )
    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def test_campaign(campaign_id: int, campaign: Campaign, test_subscriber: list[str]):
    json = campaign.model_dump(by_alias=True, exclude_none=True)
    json["subscribers"] = test_subscriber

    logger.debug(f"Testing campaign: {json}")

    response = httpx.post(
        f"{base_url}/api/campaigns/{campaign_id}/test",
        headers=headers,
        json=json,
    )
    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def update_template(template_id, new_template):
    response = httpx.put(
        f"{base_url}/api/templates/{template_id}",
        headers=headers,
        json=dict(
            name="developer-friendly-newsletter",
            type="campaign",
            body=new_template,
        ),
    )

    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def list_subscribers():
    response = httpx.get(
        f"{base_url}/api/subscribers",
        headers=headers,
    )

    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def list_lists():
    response = httpx.get(
        f"{base_url}/api/lists",
        headers=headers,
    )

    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def change_campaign_status(campaign_id, status):
    response = httpx.put(
        f"{base_url}/api/campaigns/{campaign_id}/status",
        headers=headers,
        json=dict(status=status),
    )

    if response.status_code != 200:
        raise ValueError(response.text)

    return response.json()


def list_campaigns():
    response = httpx.get(
        f"{base_url}/api/campaigns",
        headers=headers,
    )

    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()
