from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class MeetingConfiguration(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    uses_waiting_room: bool = True
    is_microphone_enabled: bool = True
    is_camera_enabled: bool = False
    is_speaker_enabled: bool = True


class MeetingCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    code: str | None = Field(default=None, max_length=240)
    starts_at: datetime
    participant_count: int = Field(default=1, ge=1, le=500)
    configuration: MeetingConfiguration = Field(default_factory=MeetingConfiguration)


class Meeting(MeetingCreate):
    id: UUID


class HealthResponse(BaseModel):
    status: str
    api_version: str
