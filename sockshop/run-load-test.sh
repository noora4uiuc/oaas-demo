#!/bin/bash

# Sock Shop - Locust Load Testing Runner
# Python-based load testing with Locust

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

RESULTS_DIR="loadtest/results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BOLD}🧦 Sock Shop Load Testing with Locust${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if in virtual environment
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}→${NC} Activating virtual environment..."
    source venv/bin/activate
fi

# Check if Sock Shop is running
echo -e "${YELLOW}→${NC} Checking if Sock Shop is running..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost" | grep -q "200"; then
    echo -e "${GREEN}✓${NC} Sock Shop is accessible"
else
    echo -e "${RED}✗${NC} Sock Shop is not running"
    echo -e "${YELLOW}→${NC} Please start Sock Shop first: ${BOLD}docker-compose up -d${NC}"
    exit 1
fi

# Create results directory
mkdir -p "$RESULTS_DIR"

echo ""
echo -e "${BOLD}Select a test mode:${NC}"
echo ""
echo "  ${BOLD}1.${NC} Quick Test        - 10 users, 2 minutes"
echo "  ${BOLD}2.${NC} Load Test         - 50 users, 5 minutes"
echo "  ${BOLD}3.${NC} Stress Test       - 100 users, 10 minutes"
echo "  ${BOLD}4.${NC} Web UI Mode       - Interactive web dashboard"
echo "  ${BOLD}5.${NC} Custom Test       - Specify your own parameters"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
  1)
    USERS=10
    SPAWN_RATE=2
    DURATION="2m"
    TEST_NAME="quick-test"
    ;;
  2)
    USERS=50
    SPAWN_RATE=5
    DURATION="5m"
    TEST_NAME="load-test"
    ;;
  3)
    USERS=100
    SPAWN_RATE=10
    DURATION="10m"
    TEST_NAME="stress-test"
    ;;
  4)
    echo ""
    echo -e "${BOLD}${GREEN}Starting Locust Web UI...${NC}"
    echo ""
    echo -e "${BLUE}📊 Open your browser to:${NC} ${BOLD}http://localhost:8089${NC}"
    echo ""
    echo -e "${YELLOW}Configure your test in the web UI:${NC}"
    echo "  • Number of users (total user count)"
    echo "  • Spawn rate (users started per second)"
    echo "  • Host is already set to: http://localhost"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop the test${NC}"
    echo ""
    locust -f locustfile.py --host=http://localhost
    exit 0
    ;;
  5)
    read -p "Number of users: " USERS
    read -p "Spawn rate (users/sec): " SPAWN_RATE
    read -p "Duration (e.g., 5m, 300s): " DURATION
    TEST_NAME="custom-test"
    ;;
  *)
    echo -e "${RED}Invalid choice${NC}"
    exit 1
    ;;
esac

REPORT_FILE="${RESULTS_DIR}/${TEST_NAME}_${TIMESTAMP}.html"

echo ""
echo -e "${BOLD}Test Configuration${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────${NC}"
echo -e "Users:         ${BOLD}${USERS}${NC}"
echo -e "Spawn Rate:    ${BOLD}${SPAWN_RATE} users/sec${NC}"
echo -e "Duration:      ${BOLD}${DURATION}${NC}"
echo -e "Report:        ${BOLD}${REPORT_FILE}${NC}"
echo ""
echo -e "${YELLOW}⚠  Note:${NC} The test will run in headless mode"
echo ""
read -p "Press Enter to start the test..."

echo ""
echo -e "${BOLD}${GREEN}▶ Starting load test...${NC}"
echo ""

# Run Locust in headless mode
locust -f locustfile.py \
    --host=http://localhost \
    --headless \
    --users $USERS \
    --spawn-rate $SPAWN_RATE \
    --run-time $DURATION \
    --html "$REPORT_FILE" \
    --csv "${RESULTS_DIR}/${TEST_NAME}_${TIMESTAMP}"

echo ""
echo -e "${BOLD}${GREEN}✓ Load test complete!${NC}"
echo ""
echo -e "${BLUE}📊 View Results:${NC}"
echo -e "   HTML Report: ${BOLD}${REPORT_FILE}${NC}"
echo -e "   CSV Files:   ${BOLD}${RESULTS_DIR}/${TEST_NAME}_${TIMESTAMP}_*.csv${NC}"
echo ""
echo -e "${BLUE}📊 View Traces in SigNoz:${NC}"
echo -e "   ${BOLD}http://localhost:3301${NC}"
echo ""
echo -e "${YELLOW}Tip:${NC} Open the HTML report in your browser:"
echo -e "   ${BOLD}open ${REPORT_FILE}${NC}"
echo ""

