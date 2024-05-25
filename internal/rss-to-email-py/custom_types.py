# -*- coding: utf-8 -*-

from datetime import datetime
from typing import Optional


import pydantic


class Author(pydantic.BaseModel):
    name: str
    email: Optional[str]


class FeedEntry(pydantic.BaseModel):
    title: str
    authors: list[Author]
    summary: str
    link: str
    image: Optional[str]
    published_parsed: datetime


class Campaign(pydantic.BaseModel):
    name: str
    subject: str
    lists: list[int]
    from_email: Optional[str]
    type_: str = pydantic.Field(alias="type")
    content_type: str = "html"
    body: str
    altbody: Optional[str]
    send_at: Optional[str]
    messenger: Optional[str]
    template_id: Optional[int]
    tags: Optional[list[str]]
    headers: Optional[dict[str, str]]
