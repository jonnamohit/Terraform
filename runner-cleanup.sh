#!/bin/bash

# GitHub Actions Runner Disk Cleanup Script
# Run this on your self-hosted runner machine to free disk space

echo "================================================"
echo "GitHub Actions Runner - Aggressive Cleanup"
echo "================================================"
echo ""

echo "📊 Before cleanup:"
df -h

echo ""
echo "🧹 Starting cleanup..."
echo ""

# Stop Docker
echo "1️⃣ Stopping Docker..."
sudo systemctl stop docker 2>/dev/null || true
sleep 2

# Remove all Docker data
echo "2️⃣ Removing Docker data..."
sudo rm -rf /var/lib/docker/* 2>/dev/null || true

# Remove runner work directories (older than 7 days)
echo "3️⃣ Cleaning runner work directory..."
find /home/ubuntu/actions-runner/_work/* -maxdepth 0 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

# Clean apt cache
echo "4️⃣ Cleaning apt cache..."
sudo apt-get clean 2>/dev/null || true
sudo apt-get autoclean 2>/dev/null || true
sudo apt-get autoremove -y 2>/dev/null || true

# Remove unnecessary packages
echo "5️⃣ Removing unnecessary tools..."
sudo rm -rf /usr/share/dotnet 2>/dev/null || true
sudo rm -rf /usr/share/swift 2>/dev/null || true
sudo rm -rf /usr/local/lib/android 2>/dev/null || true
sudo rm -rf /opt/hostedtoolcache/* 2>/dev/null || true

# Clear logs
echo "6️⃣ Clearing logs..."
sudo rm -rf /var/log/* 2>/dev/null || true
sudo journalctl --vacuum=1d 2>/dev/null || true

# Clear temp directories
echo "7️⃣ Clearing temp directories..."
sudo rm -rf /tmp/* 2>/dev/null || true
sudo rm -rf /var/tmp/* 2>/dev/null || true

# Start Docker again
echo "8️⃣ Restarting Docker..."
sudo systemctl start docker 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📊 After cleanup:"
df -h

echo ""
echo "================================================"
echo "Recommended: Increase disk size if still low"
echo "================================================"
