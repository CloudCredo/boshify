require 'httparty'
require 'pathname'

require_relative '../spec_helper'

# Apache integration test
module Boshify
  describe 'Apache BOSH Release' do

    let(:apache_url) do
      'http://10.244.2.230:8080/'
    end

    let(:apache_manifest) do
      Pathname.new(__FILE__) + '../../boshify/fixtures/apache2-manifest.yml'
    end

    it 'creates a deployable apache bosh release' do
      deploy_boshified package: 'apache2',
                       stemcell: stemcell_path,
                       manifest: apache_manifest do
        start_apache
        expect(apache_responds_to_request?).to be true
      end
    end

    def start_apache
      run_command_on_job('apache2', apache_cmd_line)
    end

    def apache_responds_to_request?
      HTTParty.get(apache_url).body.include?('It works')
    end

    private

    def apache_cmd_line
      (['/var/vcap/packages/apache2/bin/httpd'] +
        apache_config_arguments +
        ['-f /dev/null']).join(' ')
    end

    def apache_config_arguments
      apache_config.map { |k, v| "-C '#{k} #{v}'" }
    end

    def apache_config
      {
        'DocumentRoot' => '/var/vcap/packages/apache2/htdocs',
        'ErrorLog' => '/tmp/apache2.log',
        'Listen' => '0.0.0.0:8080',
        'PidFile' => '/tmp/apache2.pid'
      }
    end

  end
end
