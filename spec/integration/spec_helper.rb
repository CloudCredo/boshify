require 'bosh_lite_helpers'

include BoshLiteHelpers::Api

def boshify(options)
  BoshLiteHelpers::CommandRunner.new.run(
    "boshify -m #{mirror_url} -p #{options[:package]}")
end

def deploy_boshified(options)
  bosh_prepare(options)
  with_new_empty_directory do
    boshify package: options[:package]
    bosh_lite do
      create_release
      upload_release
      deploy options[:manifest]
      yield if block_given?
    end
  end
end

def deployment_name(name)
  "#{name}-warden"
end

def mirror_url
  ENV['MIRROR_URL'] || 'http://us.archive.ubuntu.com/ubuntu/'
end

def run_command_on_job(job_name, command)
  bosh %Q(ssh #{job_name} 0 "#{command.gsub('"', '\"')}")
end

def stemcell_path
  if ENV['STEMCELL_PATH']
    Pathname.new(ENV['STEMCELL_PATH'])
  else
    URI.parse('https://s3.amazonaws.com/bosh-jenkins-artifacts/'\
    'bosh-stemcell/warden/'\
    'bosh-stemcell-60-warden-boshlite-ubuntu-lucid-go_agent.tgz')
  end
end

private

def bosh_prepare(options)
  bosh_lite do
    delete_deployment(deployment_name(options[:package]))
    delete_release(options[:package])
    upload_stemcell(options[:stemcell])
  end
end
