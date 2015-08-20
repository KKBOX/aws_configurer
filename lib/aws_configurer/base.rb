require 'aws-sdk'

Dir[File.join(File.dirname(__FILE__), '/aws/*.rb')].each { |file| require_relative file }

require_relative 'error'

module AwsConfigurer
  class Base

    attr_reader :errors

    def initialize(options)
      config_set :region, options['region']
      config_set :access_key_id, options['access_key_id']
      config_set :secret_access_key, options['secret_access_key']
    end

    protected

    def self.config_options_set(config_name, config_options = {})
      @config_options ||= {}
      @config_options[config_name] = config_options
    end

    def self.config_options
      @config_options
    end

    config_options_set :region, type: String, required: true
    config_options_set :access_key_id, type: String
    config_options_set :secret_access_key, type: String

    def config_set(config_name, config_value)
      @configs ||= {}
      @configs[config_name] = config_value
    end

    def config_get(config_name)
      if @configs[config_name]
        @configs[config_name]
      else
        options = self.class.config_options[config_name]
        options[:default] if options && options[:default]
      end
    end

    def config_validate
      @errors = []
      self.class.config_options.each do |name, options|
        value = @configs[name]
         @errors << "#{name} is required." if options[:required] && value.nil?
         @errors << "#{name} must be #{options[:type]}." if options[:type] && !value.nil? && !value.is_a?(options[:type])
         if options[:type] == Array && value.is_a?(Array) && options[:subtype]
           value.each_with_index do |item, index|
             @errors << "Item ##{index} of #{name} must be #{options[:subtype]}" unless item.is_a?(options[:subtype])
           end
         end
         if options[:type] == Hash && value.is_a?(Hash) && options[:subtype]
           value.each do |key, item|
             @errors << "#{key} in #{name} must be #{options[:subtype]}" unless item.is_a?(options[:subtype])
           end
         end
      end
    end

    def region
      config_get(:region)
    end

    def credentials
      if @credentials.nil? && config_get(:access_key_id) && config_get(:secret_access_key)
        @credentials = Aws::Credentials.new(config_get(:access_key_id), config_get(:secret_access_key))
      end
      @credentials
    end

    def cloud_trail
      @cloud_trail ||= Aws::CloudTrail::Client.new(region: region, credentials: credentials)
    end

    def cloud_watch
      @cloud_watch ||= Aws::CloudWatch::Client.new(region: region, credentials: credentials)
    end

    def cloud_watch_logs
      @cloud_watch_logs ||= Aws::CloudWatchLogs::Client.new(region: region, credentials: credentials)
    end

    def iam
      @iam ||= Aws::IAM::Resource.new(region: region, credentials: credentials)
    end

    def s3
      @s3 ||= Aws::S3::Resource.new(region: region, credentials: credentials)
    end

    def sns
      @sns ||= Aws::SNS::Resource.new(region: region, credentials: credentials)
    end
  end
end

