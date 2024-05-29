#!/usr/bin/env python
# -*- coding: utf-8 -*-

import httpx
import os
import argparse
from pathlib import Path


parser = argparse.ArgumentParser()

parser.add_argument("--to", required=True, help="Recipient email address")
parser.add_argument("-s", "--subject", required=True, help="Email subject")
parser.add_argument("-c", "--email-content", required=False, help="Email content")
parser.add_argument("-f", "--email-content-filepath", required=False)

url = "https://smtp.maileroo.com/send"
root_dir = Path(__file__).resolve().parent
generic_html_filepath = root_dir / "templates/generic.html"

payload = {
    "from": "Meysam Azad <meysam@developer-friendly.blog>",
    "bcc": "Meysam Azad <meysam@developer-friendly.blog>",
    "tracking": "yes",
    # placeholders
    "to": "To Name <to@example.com>",
    "subject": "Test Email",
    "html": "<b>This is a test email.</b>",
}

headers = {"X-API-Key": os.environ["MAILEROO_API_KEY"]}


def get_html(args):
    with open(generic_html_filepath, "r") as f:
        template = f.read()

    if args.email_content:
        html_content = template.replace(
            '<div id="main"></div>', f'<div id="main">{args.email_content}</div>'
        )
    else:
        with open(args.email_content_filepath, "r") as f:
            email_content = f.read()
        html_content = template.replace(
            '<div id="main"></div>', f'<div id="main">{email_content}</div>'
        )

    return html_content


if __name__ == "__main__":
    args = parser.parse_args()

    if not args.email_content and not args.email_content_filepath:
        print("Please provide --email-content or --email-content-filepath")
        exit(1)

    payload["to"] = args.to
    payload["subject"] = args.subject
    payload["html"] = get_html(args)

    response = httpx.post(url, headers=headers, data=payload)

    if response.status_code == 200:
        print(response.json())
    else:
        print(response.text)
