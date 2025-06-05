import pytest

from n8n_pipe import extract_event_info, Pipe


def make_emitter(info):
    async def event_emitter(event):
        # reference info to ensure it is captured in the closure
        return info
    return event_emitter


def test_extract_event_info_closure():
    captured = {"chat_id": "123", "message_id": "xyz"}
    emitter = make_emitter(captured)
    assert extract_event_info(emitter) == ("123", "xyz")


@pytest.mark.asyncio
async def test_pipe_no_messages_adds_assistant_reply():
    pipe = Pipe()
    events = []

    async def dummy_emitter(event):
        events.append(event)

    body = {}
    result = await pipe.pipe(body, __event_emitter__=dummy_emitter)

    assert result == "No messages found in the request body"
    assert body["messages"] == [
        {"role": "assistant", "content": "No messages found in the request body"}
    ]
