FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 7860
CMD ["python", "app.py", "--host", "0.0.0.0", "--port", "7860", "--ollama-url", "http://ollama-svc:11434"]
