# mq-streaming-queues

**IBM MQ 9.2.3 CD release** we introduced the new Streaming Queue feature. Streaming Queues provide a way to create a stream of duplicate messages from an existing queue. When a message is put to the original queue a near-identical duplicate message is delivered to the stream queue. You can then consume the stream queue messages without affecting the original application.

You configure the feature on a queue-by-queue basis. For more information you can read [the blog article](https://community.ibm.com/community/user/integration/blogs/matthew-whitehead1/2021/07/26/new-streaming-queue-feature-for-mq-923) that accompanied the release or [the IBM Documentation pages](https://www.ibm.com/docs/en/ibm-mq/9.2?topic=scenarios-streaming-queues).

## Demo

This repository provides a script you can use to run through the stream queue configuration steps and is accompanied by a video that was created using the scripts.

To try the demo, navigate to the demo/Linux directory and launch the runDemo.sh script. The script creates a new queue manager and assumes you have your terminal set up with an MQ 9.2.3 environment.

## License

The scripts are licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
