#!/usr/bin/env python
# -*- coding: utf-8 -*-

from cli import parser

if __name__ == "__main__":
    args = parser.parse_args()

    if not args.email_content and not args.email_content_filepath:
        print("Please provide --email-content or --email-content-filepath")
        exit(1)

    if args.attachments:
        from email_with_attachments import main
    else:
        from email_plain import main

    main(args)
