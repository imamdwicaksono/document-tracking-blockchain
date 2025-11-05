#!/bin/bash

# ==============================
# Multi-service runner
# Next.js + Go backend
# ==============================

# Nama file log
NEXT_LOG="next.log"
GO_LOG="go.log"

# Direktori masing-masing service
NEXT_DIR="./doc-tracker-ui"
GO_DIR="./doc-tracker-api/cmd"

# Port yang digunakan (optional untuk debugging)
NEXT_PORT=3000
GO_PORT=3002

URL="http://172.24.10.87"

echo "🔍 Memeriksa proses yang masih menggunakan port ${NEXT_PORT} dan ${GO_PORT}..."
kill -9 $(lsof -t -i:${NEXT_PORT}) 2>/dev/null || true
kill -9 $(lsof -t -i:${GO_PORT}) 2>/dev/null || true

# Jalankan Next.js di background
echo "🚀 Menjalankan Next.js..."
cd "${NEXT_DIR}" || exit 1
nohup npm run dev > "../${NEXT_LOG}" 2>&1 &
NEXT_PID=$!
echo "✅ Next.js berjalan (PID: ${NEXT_PID}), log: ${NEXT_LOG}"
cd - >/dev/null

# Jalankan Go server di background
echo "⚙️ Menjalankan Go server..."
cd "${GO_DIR}" || exit 1
nohup go run main.go > "../../${GO_LOG}" 2>&1 &
GO_PID=$!
echo "✅ Go server berjalan (PID: ${GO_PID}), log: ${GO_LOG}"
cd - >/dev/null

echo ""
echo "🟢 Semua service telah dijalankan di background!"
echo "   - Next.js: ${URL}:${NEXT_PORT}"
echo "   - Go: ${URL}:${GO_PORT}"
echo ""
echo "📜 Untuk menghentikan semua service:"
echo "   kill -9 ${NEXT_PID} ${GO_PID}"
