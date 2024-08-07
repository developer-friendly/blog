def on_page_markdown(markdown, *, page, config, files):
    canonical_url = page.meta.get("canonical_url")

    if canonical_url is None:
        return

    page.canonical_url = canonical_url
