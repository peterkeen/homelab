FROM ghcr.io/peterkeen/u2if:main

COPY src/* .

RUN apt install git -y
RUN pip install -r requirements.txt

CMD ["python", "script.py"]