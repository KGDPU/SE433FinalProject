import logging

from minisweagent.utils.log import add_file_handler


def test_file_logging_preserves_unicode(tmp_path):
    path = tmp_path / "agent.log"
    logger = logging.getLogger("minisweagent")
    add_file_handler(path, print_path=False)
    handler = logger.handlers[-1]
    try:
        logger.debug("Task output: 中文 🚀 α")
        handler.flush()
        assert "Task output: 中文 🚀 α" in path.read_text(encoding="utf-8")
    finally:
        logger.removeHandler(handler)
        handler.close()
