module Aws
  module S3
    class Bucket
      def update_policy(new_policy)
        policy = self.policy.policy
        policy = policy.read if policy.is_a? StringIO
        self.policy.put(policy: new_policy) if policy != new_policy
      end
    end
  end
end
