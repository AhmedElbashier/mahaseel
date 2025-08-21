PY=python
UVICORN=uvicorn
APP=app.main:app

.PHONY: run format lint test

run:
	$(UVICORN) $(APP) --host $${API_HOST:-0.0.0.0} --port $${API_PORT:-8000} --reload

format:
	black backend
	ruff check backend --fix

lint:
	ruff check backend
	black --check backend

test:
	pytest -q
