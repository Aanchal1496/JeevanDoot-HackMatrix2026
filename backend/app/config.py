from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_name: str = "JeevanDoot API"
    debug: bool = True
    api_prefix: str = "/api"

    database_url: str = "sqlite:///./jeevandoot.db"

    jwt_secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24

    # AI (optional; triage is deterministic without it)
    ai_api_key: str = ""
    ai_base_url: str = ""
    ai_model: str = ""

    # WebRTC / real-time consultation
    webrtc_signaling_url: str = ""
    webrtc_ice_servers: str = "[]"
    turn_server_url: str = ""
    turn_username: str = ""
    turn_credential: str = ""

    # Notifications
    fcm_server_key: str = ""
    notification_provider: str = "in_app"

    # SMS / IVR
    sms_provider: str = ""
    sms_api_key: str = ""
    sms_from: str = ""
    ivr_provider: str = ""
    ivr_api_key: str = ""

    # Maps
    maps_api_key: str = ""


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()