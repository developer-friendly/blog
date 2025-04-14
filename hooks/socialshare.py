# -*- coding: utf-8 -*-
import re
import urllib.parse
from textwrap import dedent

x_intent = "https://twitter.com/intent/tweet"
x_id = "@devfriendly_"
_fb_sharer = "https://www.facebook.com/sharer/sharer.php"
lnkd_sharer = "https://www.linkedin.com/sharing/share-offsite/"
reddit_sharer = "https://www.reddit.com/submit"
mastodon = "https://mastodon.social/share"
bsky = "https://bsky.app/intent/compose"
include = re.compile(r"blog/[1-9].*")


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not include.match(page.url):
        return markdown

    page_url = config.site_url + page.url
    page_title = urllib.parse.quote(page.title + "\n")
    page_title_x = urllib.parse.quote(f"{x_id}\n{page.title}")

    url_and_title = urllib.parse.quote_plus(f"{page.title}\n\n{page_url}")

    return markdown + dedent(
        f"""
    Until next time :saluting_face:, *ciao* :cowboy: & happy coding! :penguin:

    _See any typos? [This blog is opensource](https://github.com/developer-friendly/blog). Consider [opening a PR]({page.edit_url})._ :heart_hands: :rose:

    [Subscribe to Newsletter :material-email-newsletter:](https://newsletter.developer-friendly.blog/subscription/form){{ .md-button .md-button--primary }}
    [Subscribe to RSS Feed :simple-rss:](/feed_rss_created.xml){{ .md-button .md-button--primary }}

    [Share on :simple-mastodon:]({mastodon}?text={url_and_title}){{ .md-button .md-button--primary }}
    [Share on :fontawesome-brands-bluesky:]({bsky}?text={url_and_title}){{ .md-button .md-button--primary }}
    [Share on :simple-reddit:]({reddit_sharer}?url={page_url}&title={page_title}){{ .md-button .md-button--primary }}
    [Share on :simple-x:]({x_intent}?text={page_title_x}&url={page_url}){{ .md-button .md-button--primary }}
    """
    )
