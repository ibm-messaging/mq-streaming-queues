#!/bin/bash
# © Copyright IBM Corporation 2021
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Runs through a set up steps that demonstrate how streaming queues work.

# Call runmqsc but remove some of the noise in the output
cleanRunmqsc()
{
    echo
    echo "$1" | runmqsc DEMO_QM | egrep -v "Starting MQSC|Copyright|MQSC commands*" | sed '/^$/d'
}

echo "*****************************************************************************"
echo "This demo will create a QM called 'DEMO_QM', start it, and walk you through  "
echo "some streaming queue demos. It relies on you having MQ_INSTALLATION_PATH set and"
echo "the MQ samples installed to MQ_INSTALLATION_PATH/samp/bin                    "
echo "*****************************************************************************"
read -p "Press any key to continue, or Ctrl-C to exit"

if command -v dspmqver >/dev/null 2>&1
then
  MQVERSION=`dspmqver -f 2 -b`
  if [[ "$MQVERSION" < "9.2.3.0" ]]; then
    echo
    echo "**********************************************************"
    echo "Please make sure you have IBM MQ 9.2.3 or higher installed"
    echo "(Your version = $MQVERSION)                               "
    echo "**********************************************************"
    exit 1
  fi
else
    echo
    echo "**********************************************************"
    echo "Please make sure you have IBM MQ 9.2.3 or higher installed"
    echo "and have the MQ commands on your PATH.                    "
    echo "**********************************************************"
    exit 1
fi

crtmqm DEMO_QM

if [ $? -ne 0 ]; then
  echo "Failed to create QM"
  exit 1
fi

strmqm DEMO_QM

if [ $? -ne 0 ]; then
  echo "Failed to start QM"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 2: Create a streaming queue to deliver duplicate messages to"
echo "*****************************************************************************"
read -p "Press any key to create the streaming queue..."
cleanRunmqsc "DEFINE QLOCAL(MY.LOG.QUEUE)"

if [ $? -ne 0 ]; then
  echo "Failed to create streaming queue"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 3: Create a queue which an application will put messages to. Every message"
echo "put to the queue will also be delivered to the streaming queue."
echo "*****************************************************************************"
read -p "Press any key to create the application queue..."
cleanRunmqsc "DEFINE QLOCAL(APP.QUEUE) STREAMQ(MY.LOG.QUEUE)"

if [ $? -ne 0 ]; then
  echo "Failed to create the application queue"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 4: Let's confirm that neither of the queues have any messages on them   "
echo "*****************************************************************************"
read -p "Press any key to create the application queue..."
cleanRunmqsc "DISPLAY QSTATUS(APP.QUEUE) CURDEPTH"

if [ $? -ne 0 ]; then
  echo "Failed to check queue depth"
  exit 1
fi

cleanRunmqsc "DISPLAY QSTATUS(MY.LOG.QUEUE) CURDEPTH"

if [ $? -ne 0 ]; then
  echo "Failed to check queue depth"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 5: Put 5 messages to APP.QUEUE"
echo "*****************************************************************************"
read -p "Press any key to put 5 messages to APP.QUEUE..." 
$MQ_INSTALLATION_PATH/samp/bin/amqsput APP.QUEUE DEMO_QM < messages.txt

if [ $? -ne 0 ]; then
  echo "Failed to put messages to APP.QUEUE"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 6: Check queue depth of APP.QUEUE"
echo "*****************************************************************************"
read -p "Press any key to check APP.QUEUE depth"
cleanRunmqsc "DISPLAY QSTATUS(APP.QUEUE) CURDEPTH"

if [ $? -ne 0 ]; then
  echo "Failed to check queue depth"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 7: Now let's check the depth of MY.LOG.QUEUE"
echo "*****************************************************************************"
read -p "Press any key to check MY.LOG.QUEUE depth"
cleanRunmqsc "DISPLAY QSTATUS(MY.LOG.QUEUE) CURDEPTH"

if [ $? -ne 0 ]; then
  echo "Failed to check queue depth"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 8: Next we'll restrict the depth of MY.LOG.QUEUE to 8 messsages and put "
echo "another 5 messages to APP.QUEUE. Since STRMQOS is set to the default value  "
echo "of BESTEF (best effort) all the messages arrive on APP.QUEUE but some can't "
echo "be delivered to MY.LOG.QUEUE.                                                "
echo "*****************************************************************************"
read -p "Press any key to change MY.LOG.QUEUE max depth to 8"
cleanRunmqsc "ALTER QLOCAL(MY.LOG.QUEUE) MAXDEPTH(8)"

if [ $? -ne 0 ]; then
  echo "Failed to alter MY.LOG.QUEUE MAXDEPTH"
  exit 1
fi

echo
$MQ_INSTALLATION_PATH/samp/bin/amqsput APP.QUEUE DEMO_QM < messages.txt

if [ $? -ne 0 ]; then
  echo "Failed to put messages to APP.QUEUE"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 9: Check queue depth of APP.QUEUE again. It should now be 10"
echo "*****************************************************************************"
read -p "Press any key to check APP.QUEUE depth"
cleanRunmqsc "DISPLAY QSTATUS(APP.QUEUE) CURDEPTH"

if [ $? -ne 0 ]; then
  echo "Failed to check queue depth"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 10: Check queue depth of MY.LOG.QUEUE again. It should be 8 because we"
echo "limited its max depth to 8 and STRMQOS was set to BESTEF (best effort)."
echo "*****************************************************************************"
read -p "Press any key to check MY.LOG.QUEUE depth"
cleanRunmqsc "DISPLAY QSTATUS(MY.LOG.QUEUE) CURDEPTH"

if [ $? -ne 0 ]; then
  echo "Failed to check queue depth"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 11: Check the streaming queue quality of service on APP.QUEUE. Note that it"
echo "is set to BESTEF (the default). queue depth of MY.LOG.QUEUE again."
echo "*****************************************************************************"
read -p "Press any key to check MY.LOG.QUEUE depth"
cleanRunmqsc "DISPLAY QLOCAL(APP.QUEUE) STRMQOS"

if [ $? -ne 0 ]; then
  echo "Failed to check STRMQOS"
  exit 1
fi
echo
echo "*****************************************************************************"
echo "Step 12: Now we'll alter the original queue to have STRMQOS set to MUSTDUP"
echo "(must duplicate) because we want PUTs to fail if there is a problem with the"
echo "streaming queue."
echo "*****************************************************************************"
read -p "Press any key to set STRMQOS(MUSTDUP) on the original queue"
cleanRunmqsc "ALTER QLOCAL(APP.QUEUE) STRMQOS(MUSTDUP)"

if [ $? -ne 0 ]; then
  echo "Failed to set STRMQOS(MUSTDUP)"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 13: Now we'll try to put another message to APP.QUEUE. Even though     "
echo "there is space left on APP.QUEUE the puts should fail with MQRC 2053        "
echo "(MQRC_Q_FULL) because MY.LOG.QUEUE is full and STRMQOS is MUSTDUP.           "
echo "*****************************************************************************"
read -p "Press any key to try putting more messages to APP.QUEUE"

echo
$MQ_INSTALLATION_PATH/samp/bin/amqsput APP.QUEUE DEMO_QM < messages.txt

if [ $? -ne 0 ]; then
  echo "Failed to put messages to APP.QUEUE"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 14: Now we will increase the maximum depth of MY.LOG.QUEUE so we can    "
echo "continue putting messages to APP.QUEUE and streaming duplicates to          "
echo "MY.LOG.QUEUE.                                                                "
echo "*****************************************************************************"
read -p "Press any key to increase MAXDEPTH for MY.LOG.QUEUE"
cleanRunmqsc "ALTER QLOCAL(MY.LOG.QUEUE) MAXDEPTH(5000)"

if [ $? -ne 0 ]; then
  echo "Failed to increase MAXDEPTH on MY.LOG.QUEUE"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 15: Let's now put another 5 messages and check the depth of both queues."
echo "They should be 15 for APP.QUEUE and 13 for MY.LOG.QUEUE.                     "
echo "*****************************************************************************"
read -p "Press any key to put 5 more messages and check the queue depths"
$MQ_INSTALLATION_PATH/samp/bin/amqsput APP.QUEUE DEMO_QM < messages.txt
cleanRunmqsc "DISPLAY QSTATUS(APP.QUEUE) CURDEPTH"
cleanRunmqsc "DISPLAY QSTATUS(MY.LOG.QUEUE) CURDEPTH"

if [ $? -ne 0 ]; then
  echo "Failed to check queue depths"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 16: Let's look at just how similar the messages on the two queues are.  "
echo "We'll use amqsbcg and the Linux head command to show the first message on    "
echo "each queue."
echo "*****************************************************************************"
read -p "Press any key to show the first message on each queue"
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg APP.QUEUE DEMO_QM | head -n 44
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg MY.LOG.QUEUE DEMO_QM | head -n 44

if [ $? -ne 0 ]; then
  echo "Failed to browse messages"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Step 17: Since that's quite hard to digest we can make it easier to compare  "
echo "them by picking out a few specific fields side-by-side. Firstly the MsgID... "
echo "*****************************************************************************"
read -p "Press any key to compare the MsgID"
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg APP.QUEUE DEMO_QM | head -n 44 | grep MsgId
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg MY.LOG.QUEUE DEMO_QM | head -n 44 | grep MsgId

if [ $? -ne 0 ]; then
  echo "Failed to browse messages"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "The UserIdentifier..."
echo "*****************************************************************************"
read -p "Press any key to compare the UserIdentifier"
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg APP.QUEUE DEMO_QM | head -n 44 | grep UserIdentifier
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg MY.LOG.QUEUE DEMO_QM | head -n 44 | grep UserIdentifier

if [ $? -ne 0 ]; then
  echo "Failed to browse messages"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "The PutApplName..."
echo "*****************************************************************************"
read -p "Press any key to compare the PutApplName"
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg APP.QUEUE DEMO_QM | head -n 44 | grep PutApplName
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg MY.LOG.QUEUE DEMO_QM | head -n 44 | grep PutApplName

if [ $? -ne 0 ]; then
  echo "Failed to browse messages"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "The AccountingToken..."
echo "*****************************************************************************"
read -p "Press any key to compare the AccountingToken"
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg APP.QUEUE DEMO_QM | head -n 44 | grep -A 1 AccountingToken
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg MY.LOG.QUEUE DEMO_QM | head -n 44 | grep -A 1 AccountingToken

if [ $? -ne 0 ]; then
  echo "Failed to browse messages"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "And of course the message data itself..."
echo "*****************************************************************************"
read -p "Press any key to compare the message data"
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg APP.QUEUE DEMO_QM | head -n 44 | grep -A 5 "  Message  "
$MQ_INSTALLATION_PATH/samp/bin/amqsbcg MY.LOG.QUEUE DEMO_QM | head -n 44 | grep -A 5 "  Message  "

if [ $? -ne 0 ]; then
  echo "Failed to browse messages"
  exit 1
fi

echo
echo "*****************************************************************************"
echo "Demo finished. To leave the QM running quit the script now.                  "
echo "*****************************************************************************"
read -p "Press any key to stop and delete the queue manager"
endmqm -i DEMO_QM

if [ $? -ne 0 ]; then
  echo "Failed to end the queue manager"
  exit 1
fi

dltmqm DEMO_QM

