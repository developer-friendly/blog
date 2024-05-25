# -*- coding: utf-8 -*-

from datetime import datetime
from typing import Optional
from enum import Enum


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
    from_email: Optional[str] = None
    type_: str = pydantic.Field(alias="type", serialization_alias="type")
    content_type: str = "html"
    body: str
    altbody: Optional[str] = None
    send_at: Optional[str] = None
    messenger: Optional[str] = "email"
    template_id: Optional[int] = None
    tags: Optional[list[str]] = None
    headers: Optional[dict[str, str]] = None


class Cli(Enum):
    CREATE_CAMPAIGN = "create-campaign"
    UPDATE_CAMPAIGN = "update-campaign"
    TEST_CAMPAIGN = "test-campaign"

    def __eq__(self, value) -> bool:
        if isinstance(value, str):
            return self.value == value
        if isinstance(value, Cli):
            return self.value == value.value
        raise ValueError(f"Cannot compare {type(self)} with {type(value)}")
