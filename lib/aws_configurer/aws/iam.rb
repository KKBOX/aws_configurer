require 'cgi'

module Aws
  module IAM
    class Resource
      def account_id
        self.client.get_user.user.arn.split(':')[4]
      end
    end

    class Role
      def exists?
        begin
          self.load
          true
        rescue Aws::IAM::Errors::NoSuchEntity
          false
        end
      end

      def update_assume_role_policy_document(new_policy_document)
        policy_document = CGI.unescape(self.assume_role_policy_document)
        self.assume_role_policy.update(policy_document: new_policy_document) if policy_document != new_policy_document
      end
    end

    class RolePolicy
      def update_policy_document(new_policy_document)
        begin
          self.load
          policy_document = CGI.unescape(self.policy_document)
          if policy_document != new_policy_document
            self.put(policy_document: new_policy_document)
            self.reload
          end
        rescue Aws::IAM::Errors::NoSuchEntity
          self.put(policy_document: new_policy_document)
          self.reload
        end
      end
    end
  end
end
