import asyncio
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

from fastapi import APIRouter, FastAPI, status

from .schemas import HealthResponse, Meeting, MeetingCreate, MeetingConfiguration


app = FastAPI(
    title="Onda API",
    summary="Versioned REST API for meetings and real-time collaboration.",
    version="1.0.0",
)
api_v1 = APIRouter(prefix="/api/v1")

_meetings_lock = asyncio.Lock()
_meetings: dict[UUID, Meeting] = {}


def _seed_meetings() -> None:
    meeting = Meeting(
        id=UUID("ea2abf7e-02b1-4c2a-bd58-4b8a697da2f4"),
        title="Design sync",
        code="design-sync",
        starts_at=datetime.now(UTC) + timedelta(hours=2),
        participant_count=4,
        configuration=MeetingConfiguration(),
    )
    _meetings[meeting.id] = meeting


_seed_meetings()


@api_v1.get("/health", response_model=HealthResponse, tags=["system"])
async def health() -> HealthResponse:
    return HealthResponse(status="ok", api_version="v1")


@api_v1.get("/meetings/upcoming", response_model=list[Meeting], tags=["meetings"])
async def upcoming_meetings() -> list[Meeting]:
    now = datetime.now(UTC)
    async with _meetings_lock:
        return sorted(
            (meeting for meeting in _meetings.values() if meeting.starts_at >= now),
            key=lambda meeting: meeting.starts_at,
        )


@api_v1.post(
    "/meetings",
    response_model=Meeting,
    status_code=status.HTTP_201_CREATED,
    tags=["meetings"],
)
async def create_meeting(payload: MeetingCreate) -> Meeting:
    meeting = Meeting(id=uuid4(), **payload.model_dump())
    async with _meetings_lock:
        _meetings[meeting.id] = meeting
    return meeting


app.include_router(api_v1)
