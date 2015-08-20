module Aws
  module CloudWatch
    class Client
      def alarm(alarm_name)
        alarm = nil
        next_token = nil
        loop do
          resp = self.describe_alarms(alarm_names: [alarm_name],
                                      max_records: 10,
                                      next_token: next_token)
          alarm = resp.metric_alarms.find { |alarm| alarm_name == alarm.alarm_name }
          next_token = resp.next_token
          return alarm if alarm
          return nil unless next_token
        end
      end
    end
  end
end
