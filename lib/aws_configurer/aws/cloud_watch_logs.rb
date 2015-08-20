module Aws
  module CloudWatchLogs
    class Client
      def log_group(log_group_name)
        log_group = nil
        next_token = nil
        loop do
          resp = self.describe_log_groups(log_group_name_prefix: log_group_name,
                                          limit: 10,
                                          next_token: next_token)
          log_group = resp.log_groups.find { |log_group| log_group_name == log_group.log_group_name }
          next_token = resp.next_token
          return log_group if log_group
          return nil unless next_token
        end
      end

      def metric_filter(log_group_name, filter_name)
        metric_filter = nil
        next_token = nil
        loop do
          resp = self.describe_metric_filters(log_group_name: log_group_name,
                                              filter_name_prefix: filter_name,
                                              limit: 10,
                                              next_token: next_token)
          metric_filter = resp.metric_filters.find { |metric_filter| filter_name == metric_filter.filter_name }
          next_token = resp.next_token
          return metric_filter if metric_filter
          return nil unless next_token
        end
      end
    end
  end
end
