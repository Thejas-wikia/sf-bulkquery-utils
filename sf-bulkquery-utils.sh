function login() {
  USERNAME="$1"
  PASSWORD="$2"
  LOGIN_RESPONSE=`echo $LOGIN | curl -s -H "Content-Type: text/xml; charset=UTF-8" -H "SOAPAction: login" -d "<?xml version=\"1.0\" encoding=\"utf-8\" ?><env:Envelope xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"><env:Body><n1:login xmlns:n1=\"urn:partner.soap.sforce.com\"> <n1:username>$USERNAME</n1:username> <n1:password>$PASSWORD</n1:password></n1:login></env:Body></env:Envelope>" https://login.salesforce.com/services/Soap/u/29.0`
  sessionId=`echo $LOGIN_RESPONSE | sed -n -e 's|.*<sessionId>\(.*\)</sessionId>.*|\1|p'`
  instance=`echo $LOGIN_RESPONSE | sed -n -e 's|.*<serverUrl>https://\([A-z,0-9]*\).*|\1|p'`
}

function createJob() {
  OBJECT="$1"
  JOB_RESPONSE=`curl -s -H "X-SFDC-Session: ${sessionId}" -H "Content-Type: application/xml; charset=UTF-8" -d "<?xml version=\"1.0\" encoding=\"UTF-8\"?><jobInfo xmlns=\"http://www.force.com/2009/06/asyncapi/dataload\"><operation>query</operation><object>$OBJECT</object><concurrencyMode>Parallel</concurrencyMode><contentType>CSV</contentType></jobInfo>" https://${instance}.salesforce.com/services/async/29.0/job`
  jobId=`echo $JOB_RESPONSE | sed -n -e 's|.*<id>\(.*\)</id>.*|\1|p'`
}

function createBatch() {
  QUERY="$1"
  BATCH_RESPONSE=`curl -s -H "X-SFDC-Session: ${sessionId}" -H "Content-Type: text/csv; charset=UTF-8" -d "$1" https://${instance}.salesforce.com/services/async/29.0/job/${jobId}/batch`
  batchId=`echo $BATCH_RESPONSE | sed -n -e 's|.*<id>\(.*\)</id>.*|\1|p'`
}

function updateCompletedStatus() {
  JOB_COMPLETED=`curl -s -H "X-SFDC-Session: ${sessionId}" https://${instance}.salesforce.com/services/async/29.0/job/${jobId}`
  numberBatchesCompleted=`echo $JOB_COMPLETED | sed -n -e 's|.*<numberBatchesCompleted>\([0-9]*\)</numberBatchesCompleted>.*|\1|p'`
  numberBatchesTotal=`echo $JOB_COMPLETED | sed -n -e 's|.*<numberBatchesTotal>\([0-9]*\)</numberBatchesTotal>.*|\1|p'`
  numberBatchesFailed=`echo $JOB_COMPLETED | sed -n -e 's|.*<numberBatchesFailed>\([0-9]*\)</numberBatchesFailed>.*|\1|p'`
  echo "completed: $numberBatchesCompleted"
  echo "total: $numberBatchesTotal"
  echo "failed: $numberBatchesFailed"
}


function waitForJobCompletion() {
  updateCompletedStatus
  while [ $numberBatchesFailed -lt 1 ] && [ $numberBatchesCompleted -ne $numberBatchesTotal ]
  do
    echo "$numberBatchesFailed"
    echo "sleeping"
    sleep 5
    updateCompletedStatus
  done
}

function getResults() {
  OUTPUT="$1"
  RESULT_RESPONSE=`curl -s -H "X-SFDC-Session: ${sessionId}" https://${instance}.salesforce.com/services/async/29.0/job/${jobId}/batch/${batchId}/result`
  for result in `echo $RESULT_RESPONSE | sed -e 's|<result>|\'$'\n&|g' | grep "<result>" | sed -n -e 's|<result>\(.*\)</result>.*|\1|p'`;
    do curl -s -H "X-SFDC-Session: ${sessionId}" https://${instance}.salesforce.com/services/async/29.0/job/${jobId}/batch/${batchId}/result/$result -o "$OUTPUT"
  done
}

function runQuery() {
  OBJECT="$1"
  QUERY="$2"
  OUTPUT="$3"
  createJob "$OBJECT"
  createBatch "$QUERY"
  waitForJobCompletion
  getResults "$OUTPUT"
}
