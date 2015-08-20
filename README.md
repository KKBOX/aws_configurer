# AWS Configurer

Configure AWS accounts for CloudTrail, Root Account Usage Monitor.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws_configurer'
```

And execute:

    $ bundle

Or install it directly:

    $ gem install aws_configurer

## Setup

Create a YAML file with the following structure.

```yaml
---
# Enable CloudTrail, send logs to CloudWatch and monitor Root Account Usage
ACCOUNT1:
  access_key_id: ACCESS_KEY_ID
  secret_access_key: SECERT_ACCESS_KEY
  regions:
    - ap-northeast-1
    - ap-southeast-1
    - ap-southeast-2
    - eu-central-1
    - eu-west-1
    # - sa-east-1 # CloudWatch Logs is not available in sa-east-1 (2015/08)
    - us-east-1
    - us-west-1
    - us-west-2
  cloud_trail:
    bucket_name: BUCKET
    bucket_region: REGION_OF_BUCKET
    log_group_name: LOG_GROUP
    role_name: IAM_ROLE
    policy_name: ROLE_POLICY
  root_account_usage:
    topic_name: SNS_TOPIC
    subscriptions:
      SUBSCRIPTION_ENDPOINT: SUBSCRIPTION_PROTOCOL
    alarm_name: CLOUD_WATCH_ALARM

# Enable CloudTrail but don't send logs to CloudWatch
ACCOUNT2:
  access_key_id: ACCESS_KEY_ID
  secret_access_key: SECERT_ACCESS_KEY
  regions:
    - sa-east-1
  cloud_trail:
    bucket_name: BUCKET
    bucket_region: REGION_OF_BUCKET
```

## Usage

If you put the YAML in `~/.aws_configurer.yml`, just execute:

    $ aws_configurer

Otherwise:

    $ aws_configurer -c YOUR_YAML_FILE_PATH
