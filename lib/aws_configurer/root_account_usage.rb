require_relative 'base'
require_relative 'cloud_trail'

module AwsConfigurer
  class RootAccountUsage < Base

    config_options_set :log_group_name, type: String, required: true
    config_options_set :role_name, type: String, required: true
    config_options_set :topic_name, type: String, required: true
    config_options_set :subscriptions, type: Hash, subtype: String
    config_options_set :alarm_name, type: String, default: 'Root Account Usage'

    def initialize(options)
      super(options)
      config_set :log_group_name,  options['cloud_trail']['log_group_name']
      config_set :role_name, options['cloud_trail']['role_name']
      config_set :topic_name, options['root_account_usage']['topic_name']
      config_set :subscriptions, options['root_account_usage']['subscriptions']
      config_set :alarm_name, options['root_account_usage']['alarm_name']
      config_validate
      @cloud_trail_configurer = AwsConfigurer::CloudTrail.new(options)
    end

    def run
      errors = @cloud_trail_configurer.errors + self.errors
      raise AwsConfigurer::Error, errors.join("\n") unless errors.empty?

      @cloud_trail_configurer.run

      log_group_name = config_get(:log_group_name)
      filter_name = 'RootAccountUsage'
      filter_pattern = '{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS }'
      metric_name = 'RootAccountUsageCount'
      metric_namespace = 'CloudTrailMetrics'
      metric_value = '1'
      topic_name = config_get(:topic_name)
      subscriptions = config_get(:subscriptions)
      alarm_name = config_get(:alarm_name)

      puts 'Setup CloudWatch log metric filter...'
      root_account_usage_filter(log_group_name, filter_name, filter_pattern, metric_name, metric_namespace, metric_value)
      puts 'Setup SNS topic...'
      topic = root_account_usage_topic(topic_name, subscriptions)
      puts 'Setup CloudWatch alarm...'
      root_account_usage_alarm(alarm_name, topic.arn, metric_name, metric_namespace)
    end

    protected

    def root_account_usage_filter(log_group_name, filter_name, filter_pattern, metric_name, metric_namespace, metric_value)
      metric_filter = cloud_watch_logs.metric_filter(log_group_name, filter_name)
      unless metric_filter
        cloud_watch_logs.put_metric_filter(log_group_name: log_group_name,
                                         filter_name: filter_name,
                                         filter_pattern: filter_pattern,
                                         metric_transformations: [{
                                           metric_name: metric_name,
                                           metric_namespace: metric_namespace,
                                           metric_value: metric_value
                                         }])
        metric_filter = cloud_watch_logs.metric_filter(log_group_name, filter_name)
      end
      metric_filter
    end

    def root_account_usage_topic(topic_name, subscriptions = nil)
      topic = sns.topic(topic_name)
      unless topic
        topic = sns.create_topic(name: topic_name)
      end
      if subscriptions
        subscriptions = subscriptions.clone
        sns.client.subscriptions_by_topic(topic.arn).each do |subscription|
          subscriptions.delete subscription.endpoint
        end
        subscriptions.each do |endpoint, protocol|
          topic.subscribe(protocol: protocol, endpoint: endpoint)
        end
      end
      topic
    end

    def root_account_usage_alarm(alarm_name, topic_arn, metric_name, metric_namespace)
      alarm = cloud_watch.alarm(alarm_name)
      unless alarm
        cloud_watch.put_metric_alarm(alarm_name: alarm_name,
                                    actions_enabled: true,
                                    alarm_actions: [topic_arn],
                                    metric_name: metric_name,
                                    namespace: metric_namespace,
                                    statistic: 'Sum',
                                    period: 60,
                                    evaluation_periods: 1,
                                    threshold: 0.0,
                                    comparison_operator: 'GreaterThanThreshold')
      end
    end
  end
end
