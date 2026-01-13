#Get correct python version required
FROM python:3.11-slim

WORKDIR /app

#Copy application code
COPY application/ ./application/

#Install dependencies
RUN pip install --no-cache-dir -r application/requirements.txt

#Create non root user for security purposes
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

#Set environment variables (Debug to false to prevent security issue detected by bandit prev)
ENV FLASK_DEBUG=False
ENV PORT=5000

#Health check - just make sure it's good
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

EXPOSE 5000

#Run the application
CMD ["python", "application/app.py"]