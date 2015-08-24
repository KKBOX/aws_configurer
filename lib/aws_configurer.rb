module AwsConfigurer
  VERSION = '0.1.3'

  autoload :CloudTrail, 'aws_configurer/cloud_trail'
  autoload :RootAccountUsage, 'aws_configurer/root_account_usage'

  def self.run(config)
    begin
      config.each do |account, options|
        regions = options.delete 'regions'
        regions.each do |region|
          if options.has_key?('root_account_usage')
            puts "Configuring Root Account Usage for #{account} in #{region}...";
            RootAccountUsage.new(options.clone.merge({ 'region' => region })).run
            puts "Root Account Usage for #{account} in #{region} configured.";
          elsif options.has_key?('cloud_trail')
            puts "Configuring CloudTrail for #{account} in #{region}...";
            CloudTrail.new(options.clone.merge({ 'region' => region })).run
            puts "CloudTrail for #{account} in #{region} configured.";
          end
        end
      end
    rescue
      abort $!.to_s
    end
  end
end
