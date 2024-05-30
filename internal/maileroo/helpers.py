# -*- coding: utf-8 -*-
def get_html(args, generic_html_filepath):
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
