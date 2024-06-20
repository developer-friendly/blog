# -*- coding: utf-8 -*-

import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

from config import settings
from helpers import get_html


SMTP_HOST = "smtp.maileroo.com"
SMTP_PORT = 587
SMTP_USERNAME = settings.MAILEROO_SMTP_USERNAME
SMTP_PASSWORD = settings.MAILEROO_SMTP_PASSWORD

assert SMTP_USERNAME, "Please set MAILEROO_SMTP_USERNAME environment variable"
assert SMTP_PASSWORD, "Please set MAILEROO_SMTP_PASSWORD environment variable"

generic_html_filepath = settings.GENERIC_HTML_FILE_PATH


def add_attachments(msg, attachments):
    for attachment in attachments:
        filename = os.path.basename(attachment)
        part = MIMEBase("application", "octet-stream")
        part.set_payload(open(attachment, "rb").read())
        encoders.encode_base64(part)
        part.add_header(
            "Content-Disposition",
            f"attachment; filename= {filename}",
        )
        msg.attach(part)


def main(args):
    receiver_email = args.to

    msg = MIMEMultipart()
    msg["From"] = args.from_email or settings.MAIL_FROM
    msg["To"] = receiver_email
    msg["Subject"] = args.subject

    if args.bcc_sender:
        msg["Bcc"] = msg["From"]

    print(msg.as_string())

    body = get_html(args, generic_html_filepath=generic_html_filepath)
    msg.attach(MIMEText(body, "html"))

    add_attachments(msg, args.attachments)

    try:
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
        server.starttls()
        server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.sendmail(SMTP_USERNAME, receiver_email, msg.as_string())
        server.quit()
        print("Message has been sent")
    except Exception as e:
        print(f"Message could not be sent. Error: {str(e)}")
