# -*- coding: utf-8 -*-
import argparse


parser = argparse.ArgumentParser()

parser.add_argument(
    "--from", required=False, dest="from_email", help="Sender email address"
)
parser.add_argument("--to", required=True, help="Recipient email address")
parser.add_argument("-s", "--subject", required=True, help="Email subject")
parser.add_argument("-c", "--email-content", required=False, help="Email content")
parser.add_argument("-f", "--email-content-filepath", required=False)
parser.add_argument("--bcc-sender", action="store_true", default=True)
parser.add_argument("-a", "--attachments", required=False, nargs="+")
parser.add_argument("--tracking", action="store_true", default=False)
parser.add_argument("--raw", action="store_true", default=False)
