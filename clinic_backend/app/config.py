import os
from datetime import timedelta
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()


class BaseConfig:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-change-in-prod")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "jwt-dev-secret-change-in-prod")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_TOKEN_LOCATION = ["headers"]
    JWT_HEADER_NAME = "Authorization"
    JWT_HEADER_TYPE = "Bearer"

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JSON_SORT_KEYS = False

    _DB_HOST = os.getenv("DB_HOST", "localhost")
    _DB_PORT = os.getenv("DB_PORT", "3306")
    _DB_NAME = os.getenv("DB_NAME", "clinic")
    _DB_USER = os.getenv("DB_USER", "clinic")
    _DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    _DB_USER_ENCODED = quote_plus(_DB_USER)
    _DB_PASSWORD_ENCODED = quote_plus(_DB_PASSWORD)

    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{_DB_USER_ENCODED}:{_DB_PASSWORD_ENCODED}"
        f"@{_DB_HOST}:{_DB_PORT}/{_DB_NAME}?charset=utf8mb4"
    )


class DevelopmentConfig(BaseConfig):
    DEBUG = True
    SQLALCHEMY_ECHO = False


class ProductionConfig(BaseConfig):
    DEBUG = False
    SQLALCHEMY_ECHO = False


class TestingConfig(BaseConfig):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=5)


config_by_name = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "testing": TestingConfig,
    "default": DevelopmentConfig,
}
