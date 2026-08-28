from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_endpoint_is_versioned() -> None:
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "api_version": "v1"}


def test_upcoming_meetings_match_ios_contract() -> None:
    response = client.get("/api/v1/meetings/upcoming")

    assert response.status_code == 200
    meeting = response.json()[0]
    assert meeting["title"] == "Design sync"
    assert meeting["configuration"]["uses_waiting_room"] is True
    assert meeting["participant_count"] == 4


def test_create_meeting_returns_created_resource() -> None:
    payload = {
        "title": "API architecture review",
        "code": "architecture-review",
        "starts_at": (datetime.now(UTC) + timedelta(days=1)).isoformat(),
        "participant_count": 3,
        "configuration": {
            "uses_waiting_room": True,
            "is_microphone_enabled": False,
            "is_camera_enabled": True,
            "is_speaker_enabled": True,
        },
    }

    response = client.post("/api/v1/meetings", json=payload)

    assert response.status_code == 201
    assert response.json()["title"] == payload["title"]
    assert response.json()["configuration"]["is_camera_enabled"] is True
