import pytest

from n8n_pipe import extract_event_info


def make_emitter(info):
    async def event_emitter(event):
        # reference info to ensure it is captured in the closure
        return info
    return event_emitter


def test_extract_event_info_closure():
    captured = {"chat_id": "123", "message_id": "xyz"}
    emitter = make_emitter(captured)
    assert extract_event_info(emitter) == ("123", "xyz")
