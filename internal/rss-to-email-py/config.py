# -*- coding: utf-8 -*-

import warnings

import pydantic
import pydantic_settings


class Settings(pydantic_settings.BaseSettings):
    LOG_LEVEL: str = "INFO"

    @pydantic.field_validator("LOG_LEVEL")
    @classmethod
    def validate_log_level(cls, value: str) -> str:
        if value not in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
            warnings.warn(f"Invalid log level: {value}. Defaulting to DEBUG.")
            return "INFO"
        return value.upper()


settings = Settings()
