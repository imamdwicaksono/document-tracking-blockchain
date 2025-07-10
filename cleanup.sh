#!/bin/bash
echo "Stopping services..."
kill 19992 2>/dev/null
kill 19994 2>/dev/null
kill 19998 2>/dev/null
echo "Services stopped"
