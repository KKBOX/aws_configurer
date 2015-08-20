module Aws
  module SNS
    class Resource
      def topic(topic_name)
        topics = self.topics
        topic = topics.find { |topic| topic_name == topic.arn.split(':').last }
      end
    end

    class Client
      def subscriptions_by_topic(topic_arn)
        subscriptions = []
        next_token = nil
        loop do
          resp = self.list_subscriptions_by_topic(topic_arn: topic_arn,
                                                  next_token: next_token)
          subscriptions += resp.subscriptions
          next_token = resp.next_token
          return subscriptions unless next_token
        end
      end
    end
  end
end
