FROM python:3-alpine

COPY . .
RUN pip install -r docs/requirements.txt

WORKDIR /docs

EXPOSE 8000
CMD ["mkdocs", "serve", "--dev-addr=127.0.0.1:8000"]
