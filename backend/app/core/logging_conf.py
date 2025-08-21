import logging
from pythonjsonlogger import jsonlogger

def configure_logging() -> None:
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    handler = logging.StreamHandler()
    fmt = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s %(pathname)s %(lineno)d"
    )
    handler.setFormatter(fmt)

    # Avoid duplicate handlers if reload
    logger.handlers = []
    logger.addHandler(handler)
