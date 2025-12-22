# sudo docker build -t gbhat1/ollama:latest .



FROM ollama/ollama
USER ubuntu
RUN ollama serve & \
    sleep 5 && \
    ollama pull gemma3:1b && \
    ollama pull embeddinggemma && \
    ollama pull llama3.2:1b && \
    pkill ollama
