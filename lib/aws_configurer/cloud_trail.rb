require_relative 'base'

module AwsConfigurer
  class CloudTrail < Base

    config_options_set :bucket_name, type: String, required: true
    config_options_set :bucket_region, type: String, required: true
    config_options_set :log_group_name, type: String
    config_options_set :role_name, type: String
    config_options_set :policy_name, type: String, default: 'CloudWatchLogs-CloudTrail'

    def initialize(options)
      super(options)
      config_set :bucket_name, options['cloud_trail']['bucket_name']
      config_set :bucket_region, options['cloud_trail']['bucket_region']
      config_set :log_group_name,  options['cloud_trail']['log_group_name']
      config_set :role_name, options['cloud_trail']['role_name']
      config_set :policy_name, options['cloud_trail']['policy_name']
      config_validate
    end

    def run
      raise AwsConfigurer::Error, errors.join("\n") unless errors.empty?

      bucket_name = config_get(:bucket_name)
      bucket_region = config_get(:bucket_region)
      log_group_name = config_get(:log_group_name)
      role_name = config_get(:role_name)
      policy_name = config_get(:policy_name)
      trail_name = 'Default'

      puts 'Setup S3 bucket...'
      cloud_trail_bucket(bucket_name, bucket_region)
      if log_group_name && role_name
        puts 'Setup CloudWatch log group...'
        log_group = cloud_trail_log_group(log_group_name)
        puts 'Setup IAM role...'
        role = cloud_trail_role(role_name, policy_name, log_group_name)
        puts 'Setup CloudTrail trail...'
        cloud_trail_trail(trail_name, bucket_name, log_group.arn, role.arn)
      else
        cloud_trail_trail(trail_name, bucket_name)
      end
    end

    protected

    def s3
      @s3 ||= Aws::S3::Resource.new(region: config_get(:bucket_region), credentials: credentials)
    end

    def cloud_trail_bucket(bucket_name, region)
      bucket = s3.bucket(bucket_name)
      unless bucket.exists?
        bucket.create(create_bucket_configuration: { location_constraint: region })
      end
      cloud_trail_policy = JSON({
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Principal: {
              AWS: Aws::CloudTrail::CLOUD_TRAIL_ARNS
            },
            Action: "s3:GetBucketAcl",
            Resource: "arn:aws:s3:::#{bucket.name}"
          },
          {
            Effect: "Allow",
            Principal: {
              AWS: Aws::CloudTrail::CLOUD_TRAIL_ARNS
            },
            Action: "s3:PutObject",
            Resource: "arn:aws:s3:::#{bucket.name}/AWSLogs/#{iam.account_id}/*",
            Condition: {
              StringEquals: {
                "s3:x-amz-acl" => "bucket-owner-full-control"
              }
            }
          }
        ]
      })
      bucket.update_policy(cloud_trail_policy)
      bucket
    end

    def cloud_trail_log_group(log_group_name)
      log_group = cloud_watch_logs.log_group(log_group_name)
      unless log_group
        cloud_watch_logs.create_log_group(log_group_name: log_group_name)
        log_group = cloud_watch_logs.log_group(log_group_name)
      end
      log_group
    end

    def cloud_trail_role(role_name, policy_name, log_group_name)
      role = iam.role(role_name)
      assume_role_policy_document = JSON({
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Principal: {
            Service: "cloudtrail.amazonaws.com"
          },
          Action: "sts:AssumeRole"
        }]
      })
      if role.exists?
        role.update_assume_role_policy_document(assume_role_policy_document)
      else
        role = iam.create_role(role_name: role_name, assume_role_policy_document: assume_role_policy_document)
      end

      account_id = iam.account_id
      policy_document = JSON({
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Action: [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            Resource: Aws::REGIONS.map do |region|
              "arn:aws:logs:#{region}:#{account_id}:log-group:#{log_group_name}:log-stream:*"
            end
          }
        ]
      })
      role_policy = role.policy(policy_name)
      role_policy.update_policy_document(policy_document)
      role
    end

    def cloud_trail_trail(trail_name, bucket_name, log_group_arn = nil, role_arn = nil)
      trail = cloud_trail.trail(trail_name)
      if trail
        if bucket_name != trail.s3_bucket_name ||
          log_group_arn != trail.cloud_watch_logs_log_group_arn ||
          role_arn != trail.cloud_watch_logs_role_arn
          trail = cloud_trail.update_trail(name: trail_name,
                                           s3_bucket_name: bucket_name,
                                           cloud_watch_logs_log_group_arn: log_group_arn,
                                           cloud_watch_logs_role_arn: role_arn,
                                           include_global_service_events: true)
        end
      else
        trail = cloud_trail.create_trail(name: trail_name,
                                         s3_bucket_name: bucket_name,
                                         cloud_watch_logs_log_group_arn: log_group_arn,
                                         cloud_watch_logs_role_arn: role_arn,
                                         include_global_service_events: true)
      end
      resp = cloud_trail.get_trail_status(name: trail_name)
      cloudtrail.start_logging(name: trail_name) unless resp.is_logging
      trail
    end
  end
end
