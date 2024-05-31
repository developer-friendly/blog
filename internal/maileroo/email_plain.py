# -*- coding: utf-8 -*-

import httpx


from config import settings
from helpers import get_html

assert settings.MAILEROO_API_KEY, "Please set MAILEROO_API_KEY environment variable"

url = "https://smtp.maileroo.com/send"

generic_html_filepath = settings.GENERIC_HTML_FILE_PATH

payload = {
    "from": "Meysam Azad <meysam@developer-friendly.blog>",
    "tracking": "no",
    # placeholders
    "to": "To Name <to@example.com>",
    "subject": "Test Email",
    "html": "<b>This is a test email.</b>",
}

headers = {"X-API-Key": settings.MAILEROO_API_KEY}


def main(args):
    if not args.email_content and not args.email_content_filepath:
        print("Please provide --email-content or --email-content-filepath")
        exit(1)

    payload["to"] = args.to
    payload["subject"] = args.subject
    payload["from"] = args.from_email or settings.MAIL_FROM
    if args.tracking:
        payload["tracking"] = "yes"
    if args.bcc_sender:
        payload["bcc"] = payload["from"]

    print(payload)

    payload["html"] = get_html(args, generic_html_filepath=generic_html_filepath)

    response = httpx.post(url, headers=headers, data=payload)

    if response.status_code == 200:
        print(response.json())
    else:
        print(response.text)
