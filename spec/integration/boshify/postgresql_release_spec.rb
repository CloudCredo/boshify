require_relative '../spec_helper'
require 'pathname'
require 'pg'

# PostgreSQL integration test
module Boshify
  describe 'PostgreSQL BOSH Release' do

    let(:postgresql_node_ip) { '10.244.2.234' }

    let(:postgresql_manifest) do
      Pathname.new(__FILE__) + '../../boshify/fixtures/postgresql-manifest.yml'
    end

    it 'creates a deployable postgresql bosh release' do
      deploy_boshified package: 'postgresql-8.4',
                       stemcell: stemcell_path,
                       manifest: postgresql_manifest do
        setup_postgresql
        expect(postgresql_running?).to be true
      end
    end

    def setup_postgresql
      cmds = [
        create_database_cmd,
        allow_unauthenticated_remote_access_cmd,
        start_postgresql_cmd,
        wait_for_postgresql_cmd,
        create_postgres_user_cmd
      ]
      run_command_on_job('postgresql-8.4', cmds.join(' && '))
    end

    def postgresql_running?
      select_string('hello world') == 'hello world'
    end

    private

    def create_database_cmd
      '/var/vcap/packages/postgresql-8.4/bin/initdb /tmp/postgresql'
    end

    def allow_unauthenticated_remote_access_cmd
      %q(echo "listen_addresses = '*'" >> /tmp/postgresql/postgresql.conf &&
         echo 'host all all 0.0.0.0/0 trust' >> /tmp/postgresql/pg_hba.conf)
    end

    def start_postgresql_cmd
      '/var/vcap/packages/postgresql-8.4/bin/pg_ctl start -D /tmp/postgresql '\
        '> /tmp/postgresql.log'
    end

    def wait_for_postgresql_cmd
      'while ! nc -z localhost 5432; do sleep 1; done'
    end

    def create_postgres_user_cmd
      '/var/vcap/packages/postgresql-8.4/bin/createuser -s -r postgres'
    end

    def select_string(literal)
      conn = PG.connect(host: postgresql_node_ip,
                        user: 'postgres',
                        dbname: 'postgres')
      conn.exec("SELECT '#{literal}'") { |r| r.first.values.first }
    end

  end
end
