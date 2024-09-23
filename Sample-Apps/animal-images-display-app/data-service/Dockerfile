FROM python:3.10-slim-buster

WORKDIR /app

RUN pip install fastapi uvicorn pydantic-settings

COPY main.py .

CMD ["python", "main.py"]
