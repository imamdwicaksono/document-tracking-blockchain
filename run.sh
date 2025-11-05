#!/bin/bash

# ==============================
# Multi-service runner
# Next.js + Go backend + gRPC
# ==============================

# Nama file log
NEXT_LOG="next.log"
GO_LOG="go.log"

# Direktori masing-masing service
NEXT_DIR="./doc-tracker-ui"
GO_DIR="./doc-tracker-api"

# Port yang digunakan
NEXT_PORT=3000
GO_PORT=3002
GRPC_PORT=3003

# Base URL
URL="http://172.24.10.87"

echo "🔍 Memeriksa proses yang masih menggunakan port ${NEXT_PORT}, ${GO_PORT}, dan ${GRPC_PORT}..."

for PORT in $NEXT_PORT $GO_PORT $GRPC_PORT; do
  PID=$(lsof -t -i:${PORT})
  if [ -n "$PID" ]; then
    echo "⚠️  Menemukan proses di port ${PORT} (PID: ${PID}), menghentikan..."
    kill -9 $PID 2>/dev/null || true
  else
    echo "✅ Port ${PORT} bersih."
  fi
done

# Jalankan Next.js di background
echo "🚀 Menjalankan Next.js..."
cd "${NEXT_DIR}" || exit 1
nohup npm start > "../${NEXT_LOG}" 2>&1 &
NEXT_PID=$!
echo "✅ Next.js berjalan (PID: ${NEXT_PID}), log: ${NEXT_LOG}"
cd - >/dev/null

# Jalankan Go server di background
echo "⚙️ Menjalankan Go server..."
cd "${GO_DIR}" || exit 1
nohup ./document-tracking-api > "../${GO_LOG}" 2>&1 &
GO_PID=$!
echo "✅ Go server berjalan (PID: ${GO_PID}), log: ${GO_LOG}"
cd - >/dev/null

echo ""
echo "🟢 Semua service telah dijalankan di background!"
echo "   - Next.js: ${URL}:${NEXT_PORT}"
echo "   - Go REST API: ${URL}:${GO_PORT}"
echo "   - gRPC Server: ${URL}:${GRPC_PORT}"
echo ""
echo "📜 Untuk menghentikan semua service:"
echo "   kill -9 ${NEXT_PID} ${GO_PID}"
