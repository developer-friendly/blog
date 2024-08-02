# -*- coding: utf-8 -*-

import warnings
from typing import Optional

import pydantic
import pydantic_settings


class Settings(pydantic_settings.BaseSettings):
    LOG_LEVEL: str = "INFO"
    NEWSLETTER_CAMPAIGN_LIST: Optional[int] = None

    @pydantic.field_validator("LOG_LEVEL")
    @classmethod
    def validate_log_level(cls, value: str) -> str:
        value_upper = value.upper()
        if value_upper not in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
            warnings.warn(f"Invalid log level: {value}. Defaulting to DEBUG.")
            return "INFO"
        return value_upper


settings = Settings()
