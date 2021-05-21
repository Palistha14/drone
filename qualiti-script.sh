#!/bin/bash
 
  set -ex
 
  PROJECT_ID='332'
  API_KEY='Pb9poC8pBq1pBEUp7Snqb1YAenroSrxx9sh6gafd'
  CLIENT_ID='6c257dc76a5bfc6423950330b7c9ffec'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://7iggpnqgq9.execute-api.us-east-2.amazonaws.com/udbodh/api'
  INTEGRATION_JWT_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9qZWN0X2lkIjozMzIsImFwaV9rZXlfaWQiOjQ5MTgsIm5hbWUiOiIiLCJkZXNjcmlwdGlvbiI6IiIsImljb24iOiIiLCJpbnRlZ3JhdGlvbl9uYW1lIjoiY2lyY2xlY2kiLCJvcHRpb25zIjp7fSwiaWF0IjoxNjIxNTc1MzA5fQ.47OET9uijh1P5n7ZwXyX96cmXpilHabK-ZrYq2iGSLI'
  INTEGRATIONS_API_URL='http://8c35247bda35.ngrok.io'
 
  apt-get update -y
  apt-get install -y jq
 
  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/api/integrations/circleci/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"
 
  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client_id: '${CLIENT_ID}'' \
    -H 'scopes: '${SCOPES}'' \
    | jq -r '.token')"
 
  # Wait until the test run has finished
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
    fi
      sleep 15;
  done
 
  # # Once finished, verify the test result is created and that its passed
  TEST_RUN_RESULT="$( \
    curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].status' \
  )"
  echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
