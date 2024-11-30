FROM python:slim

WORKDIR /app
COPY src/* .

RUN apt update && apt install git ca-certificates -y
RUN pip install -r requirements.txt

CMD ["python", "script.py"]