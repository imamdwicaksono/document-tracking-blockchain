#!/bin/bash
echo "Stopping services..."
kill 11820 2>/dev/null
kill 11822 2>/dev/null
kill 11827 2>/dev/null
echo "Services stopped"
