#!/bin/bash
# Start HTTP server to serve malicious PDFs automatically
# This runs as a systemd service on boot

PDF_DIR="$HOME/.msf4/local"
WEB_PORT="8080"
LOG_FILE="/tmp/pdf_server.log"

echo "[$(date)] Starting PDF HTTP server on port $WEB_PORT" >> "$LOG_FILE"

# Wait for PDF to be generated
for i in {1..30}; do
    if [ -f "$PDF_DIR/JOAN-ESPINACH-TRD.pdf" ]; then
        echo "[$(date)] PDF found, starting server" >> "$LOG_FILE"
        break
    fi
    sleep 2
done

# Start Python HTTP server
cd "$PDF_DIR"
python3 -m http.server $WEB_PORT >> "$LOG_FILE" 2>&1
