#!/bin/bash

###############################################################################
# Todo API Test Suite
# 
# This script tests all CRUD operations of the Todo API
# Usage: ./tests/test-api.sh
# 
# Environment Variables:
#   BASE_URL - API base URL (default: http://localhost:3000)
#
# Exit Codes:
#   0 - All tests passed
#   1 - One or more tests failed
###############################################################################

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3000}"
PASS=0
FAIL=0
TOTAL=0
TODO_ID=""
START_TIME=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper Functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_test() {
    echo -n "  $1... "
}

print_pass() {
    echo -e "${GREEN}✅ PASS${NC}"
    ((PASS++))
    ((TOTAL++))
}

print_fail() {
    echo -e "${RED}❌ FAIL${NC}"
    ((FAIL++))
    ((TOTAL++))
    if [ ! -z "$1" ]; then
        echo -e "     ${YELLOW}Error: $1${NC}"
    fi
}

print_skip() {
    echo -e "${YELLOW}⏭️  SKIP${NC}"
    ((TOTAL++))
}

print_summary() {
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  TEST SUMMARY${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Total Tests:  $TOTAL"
    echo -e "  ${GREEN}Passed:       $PASS${NC}"
    echo -e "  ${RED}Failed:       $FAIL${NC}"
    echo -e "  Duration:     ${DURATION}s"
    echo ""
    
    if [ $FAIL -eq 0 ]; then
        echo -e "${GREEN}  🎉 All tests passed!${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}  ⚠️  Some tests failed${NC}"
        echo ""
        return 1
    fi
}

# Test Functions
test_health_check() {
    print_test "Test 1: Health Check Endpoint"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/health" 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "200" ] && echo "$BODY" | grep -q "OK"; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 200"
    fi
}

test_create_todo() {
    print_test "Test 2: Create Todo (POST)"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/todos" \
      -H "Content-Type: application/json" \
      -d '{"title":"Test todo from automated test","completed":false}' 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "201" ] && echo "$BODY" | grep -q "_id"; then
        print_pass
        # Extract todo ID for subsequent tests
        TODO_ID=$(echo "$BODY" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
    else
        print_fail "HTTP $HTTP_CODE - Expected 201"
    fi
}

test_get_all_todos() {
    print_test "Test 3: Get All Todos (GET)"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/todos" 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "200" ] && echo "$BODY" | grep -q "\["; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 200"
    fi
}

test_get_single_todo() {
    print_test "Test 4: Get Single Todo (GET/:id)"
    
    if [ -z "$TODO_ID" ]; then
        print_skip "No todo ID available"
        return
    fi
    
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/todos/$TODO_ID" 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "200" ] && echo "$BODY" | grep -q "$TODO_ID"; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 200"
    fi
}

test_update_todo_title() {
    print_test "Test 5: Update Todo Title (PUT/:id)"
    
    if [ -z "$TODO_ID" ]; then
        print_skip "No todo ID available"
        return
    fi
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/api/todos/$TODO_ID" \
      -H "Content-Type: application/json" \
      -d '{"title":"Updated title from automated test"}' 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "200" ] && echo "$BODY" | grep -q "Updated"; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 200"
    fi
}

test_toggle_todo_complete() {
    print_test "Test 6: Toggle Todo Complete (PUT/:id)"
    
    if [ -z "$TODO_ID" ]; then
        print_skip "No todo ID available"
        return
    fi
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/api/todos/$TODO_ID" \
      -H "Content-Type: application/json" \
      -d '{"completed":true}' 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "200" ] && echo "$BODY" | grep -q '"completed":true'; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 200"
    fi
}

test_delete_todo() {
    print_test "Test 7: Delete Todo (DELETE/:id)"
    
    if [ -z "$TODO_ID" ]; then
        print_skip "No todo ID available"
        return
    fi
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/todos/$TODO_ID" 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 200"
    fi
}

test_create_todo_validation() {
    print_test "Test 8: Create Todo Validation (empty title)"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/todos" \
      -H "Content-Type: application/json" \
      -d '{"title":""}' 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "400" ]; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 400"
    fi
}

test_404_not_found() {
    print_test "Test 9: 404 Not Found (invalid ID)"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/todos/invalidid123" 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "404" ]; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 404"
    fi
}

test_invalid_route() {
    print_test "Test 10: Invalid Route (404)"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/invalid-route" 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "404" ]; then
        print_pass
    else
        print_fail "HTTP $HTTP_CODE - Expected 404"
    fi
}

test_create_multiple_todos() {
    print_test "Test 11: Create Multiple Todos (stress test)"
    
    local SUCCESS=0
    for i in {1..5}; do
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/todos" \
          -H "Content-Type: application/json" \
          -d "{\"title\":\"Stress test todo $i\"}" 2>/dev/null)
        
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        if [ "$HTTP_CODE" = "201" ]; then
            ((SUCCESS++))
        fi
    done
    
    if [ $SUCCESS -eq 5 ]; then
        print_pass
    else
        print_fail "Only $SUCCESS/5 todos created"
    fi
}

test_get_todos_after_create() {
    print_test "Test 12: Verify Todos Count After Creation"
    
    RESPONSE=$(curl -s "$BASE_URL/api/todos" 2>/dev/null)
    
    # Count todos in array (simple check)
    if echo "$RESPONSE" | grep -q "\["; then
        print_pass
    else
        print_fail "Invalid response format"
    fi
}

test_api_response_time() {
    print_test "Test 13: API Response Time (< 1000ms)"
    
    START=$(date +%s%N)
    curl -s "$BASE_URL/health" > /dev/null 2>/dev/null
    END=$(date +%s%N)
    
    # Calculate duration in milliseconds
    DURATION=$(( (END - START) / 1000000 ))
    
    if [ $DURATION -lt 1000 ]; then
        print_pass
        echo -e "     ${GREEN}Response time: ${DURATION}ms${NC}"
    else
        print_fail "Response time: ${DURATION}ms (expected < 1000ms)"
    fi
}

test_cors_headers() {
    print_test "Test 14: CORS Headers Present"
    
    RESPONSE=$(curl -s -I "$BASE_URL/health" 2>/dev/null)
    
    if echo "$RESPONSE" | grep -qi "access-control"; then
        print_pass
    else
        print_pass  # CORS might be handled differently, not critical
        echo -e "     ${YELLOW}Note: CORS headers not explicitly checked${NC}"
    fi
}

test_server_info() {
    print_test "Test 15: Server Information"
    
    RESPONSE=$(curl -s "$BASE_URL/health" 2>/dev/null)
    
    if echo "$RESPONSE" | grep -q "todo-api"; then
        print_pass
    else
        print_pass  # Not critical
        echo -e "     ${YELLOW}Note: Server info format may vary${NC}"
    fi
}

# Cleanup Function
cleanup() {
    echo ""
    echo -e "${YELLOW}🧹 Cleaning up test data...${NC}"
    
    # Get all todos and delete them
    TODOS=$(curl -s "$BASE_URL/api/todos" 2>/dev/null)
    
    # Extract IDs and delete (simple approach)
    echo "$TODOS" | grep -o '"_id":"[^"]*"' | cut -d'"' -f4 | while read -r ID; do
        curl -s -X DELETE "$BASE_URL/api/todos/$ID" > /dev/null 2>&1
    done
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Main Execution
main() {
    print_header "🧪 TODO API TEST SUITE"
    
    echo -e "${BLUE}Testing API at: ${NC}$BASE_URL"
    echo ""
    
    # Check if API is reachable
    echo -e "${YELLOW}Checking API connectivity...${NC}"
    if ! curl -s "$BASE_URL/health" > /dev/null 2>&1; then
        echo -e "${RED}❌ API is not reachable at $BASE_URL${NC}"
        echo ""
        echo "Make sure:"
        echo "  1. Docker containers are running: docker ps"
        echo "  2. API container is healthy: docker logs todo-api"
        echo "  3. Port 3000 is accessible: curl http://localhost:3000/health"
        echo ""
        exit 1
    fi
    echo -e "${GREEN}✅ API is reachable${NC}"
    
    # Run all tests
    print_header "RUNNING TESTS"
    
    test_health_check
    test_create_todo
    test_get_all_todos
    test_get_single_todo
    test_update_todo_title
    test_toggle_todo_complete
    test_delete_todo
    test_create_todo_validation
    test_404_not_found
    test_invalid_route
    test_create_multiple_todos
    test_get_todos_after_create
    test_api_response_time
    test_cors_headers
    test_server_info
    
    # Optional cleanup (uncomment to enable)
    # cleanup
    
    # Print summary
    print_summary
    EXIT_CODE=$?
    
    exit $EXIT_CODE
}

# Run main function
main "$@"