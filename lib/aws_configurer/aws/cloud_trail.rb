module Aws
  module CloudTrail
    CLOUD_TRAIL_ARNS = [
      'arn:aws:iam::903692715234:root',
      'arn:aws:iam::859597730677:root',
      'arn:aws:iam::814480443879:root',
      'arn:aws:iam::216624486486:root',
      'arn:aws:iam::086441151436:root',
      'arn:aws:iam::388731089494:root',
      'arn:aws:iam::284668455005:root',
      'arn:aws:iam::113285607260:root',
      'arn:aws:iam::035351147821:root'
    ]

    class Client
      def trail(trail_name)
        resp = self.describe_trails
        resp.trail_list.find { |trail| trail_name == trail.name }
      end
    end
  end
end
