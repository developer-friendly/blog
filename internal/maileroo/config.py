# -*- coding: utf-8 -*-
from pathlib import Path

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    GENERIC_HTML_FILE_PATH: str | Path = (
        Path(__file__).resolve().parent / "templates/generic.html"
    )

    MAILEROO_SMTP_USERNAME: str = "meysam@developer-friendly.blog"
    MAILEROO_SMTP_PASSWORD: str = ""

    MAILEROO_API_KEY: str = ""

    MAIL_FROM: str = "Meysam Azad <meysam@developer-friendly.blog>"


settings = Settings()
