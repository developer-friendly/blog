# -*- coding: utf-8 -*-
from datetime import datetime
from time import mktime


import feedparser
import httpx
import os

from custom_types import Author, FeedEntry, Campaign


url = "https://developer-friendly.blog/feed_rss_created.xml"
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
        f"https://newsletter.developer-friendly.blog/api/campaigns/{campaign_id}",
        headers=headers,
        json=campaign.dict(),
    )
    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def create_campaign(campaign: Campaign):
    response = httpx.post(
        "https://newsletter.developer-friendly.blog/api/campaigns",
        headers=headers,
        json=campaign.dict(),
    )
    if response.status_code != 200:
        raise ValueError(response.text)
    return response.json()


def test_listmonk_campaign(list_id, campaign_name):
    return httpx.post(
        "https://newsletter.developer-friendly.blog/api/campaigns/5/test",
        headers=headers,
        json=dict(
            subscribers=["meysam@developer-friendly.blog"],
            name=campaign_name,
            subject="Site Reliability Engineering Newsletter",
            lists=[list_id],
            messenger="email",
            body=prepare_html_for_newsletter(),
        ),
    )


def update_campaign_template(template_id):
    file_rootdir = os.path.dirname(os.path.realpath(__file__))
    with open(f"{file_rootdir}/templates/newsletter.html", "r") as file:
        body = file.read()

    return httpx.put(
        f"https://newsletter.developer-friendly.blog/api/templates/{template_id}",
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
