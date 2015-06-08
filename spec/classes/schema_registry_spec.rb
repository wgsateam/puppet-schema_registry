require 'spec_helper'

describe 'schema_registry' do
  context 'supported operating systems' do
    ['RedHat'].each do |osfamily|
      ['RedHat', 'CentOS', 'Amazon', 'Fedora'].each do |operatingsystem|
        let(:facts) {{
          :osfamily        => osfamily,
          :operatingsystem => operatingsystem,
        }}

        default_configuration_file  = '/etc/schema-registry/schema-registry.properties'
        default_logging_configuration_file = '/etc/schema-registry/log4j.properties'

        context "with explicit data (no Hiera) on #{osfamily}" do

          describe "with default settings" do
            let(:params) {{ }}
            # We must mock $::operatingsystem because otherwise this test will
            # fail when you run the tests on e.g. Mac OS X.
            it { should compile.with_all_deps }

            it { should contain_class('schema_registry::params') }
            it { should contain_class('schema_registry') }
            it { should contain_class('schema_registry::users').that_comes_before('schema_registry::install') }
            it { should contain_class('schema_registry::install').that_comes_before('schema_registry::config') }
            it { should contain_class('schema_registry::config') }
            it { should contain_class('schema_registry::service').that_subscribes_to('schema_registry::config') }

            it { should contain_package('confluent-schema-registry').with({
              'ensure' => 'present',
              'name'   => 'confluent-schema-registry',
            })}

            it { should contain_group('schema-registry').with({
              'ensure' => 'present',
              'gid'    => 55001,
            })}

            it { should contain_user('schema-registry').with({
              'ensure'     => 'present',
              'home'       => '/home/schema-registry',
              'shell'      => '/bin/bash',
              'uid'        => 55001,
              'comment'    => 'Confluent schema registry system account',
              'gid'        => 'schema-registry',
              'managehome' => true,
            })}

            it { should contain_file(default_configuration_file).with({
                'ensure' => 'file',
                'owner'  => 'root',
                'group'  => 'root',
                'mode'   => '0644',
              }).
              with_content(/^port=8081$/).
              with_content(/^kafkastore\.connection\.url=localhost:2181$/)
            }

            it { should contain_file(default_logging_configuration_file).with({
                'ensure' => 'file',
                'owner'  => 'root',
                'group'  => 'root',
                'mode'   => '0644',
              }).
              with_content(/^log4j\.rootLogger=INFO, stdout$/).
              with_content(/^log4j\.logger\.kafka=ERROR, stdout$/).
              with_content(/^log4j\.logger\.org\.apache\.zookeeper=ERROR, stdout$/).
              with_content(/^log4j\.logger\.org\.apache\.kafka=ERROR, stdout$/).
              with_content(/^log4j\.logger\.org\.I0Itec\.zkclient=ERROR, stdout$/)
            }

            it { should contain_supervisor__service('confluent-schema-registry').with({
              'ensure'      => 'present',
              'enable'      => true,
              'command'     => '/usr/bin/schema-registry-start /etc/schema-registry/schema-registry.properties',
              'user'        => 'schema-registry',
              'group'       => 'schema-registry',
              'autorestart' => true,
              'startsecs'   => 10,
              'retries'     => 999,
              'stopsignal'  => 'INT',
              'stopasgroup' => true,
              'stopwait'    => 120,
              'stdout_logfile_maxsize' => '20MB',
              'stdout_logfile_keep'    => 5,
              'stderr_logfile_maxsize' => '20MB',
              'stderr_logfile_keep'    => 10,
            })}
          end

          describe "with disabled user management" do
            let(:params) {{
              :user_manage  => false,
            }}
            it { should_not contain_group('schema-registry') }
            it { should_not contain_user('schema-registry') }
          end

          describe "with custom user and group" do
            let(:params) {{
              :user_manage      => true,
              :gid              => 456,
              :group            => 'mygroup',
              :uid              => 123,
              :user             => 'myuser',
              :user_description => 'My custom user',
              :user_home        => '/home/myuser',
            }}

            it { should_not contain_group('schema-registry') }
            it { should_not contain_user('schema-registry') }

            it { should contain_user('myuser').with({
              'ensure'     => 'present',
              'home'       => '/home/myuser',
              'shell'      => '/bin/bash',
              'uid'        => 123,
              'comment'    => 'My custom user',
              'gid'        => 'mygroup',
              'managehome' => true,
            })}

            it { should contain_group('mygroup').with({
              'ensure'     => 'present',
              'gid'        => 456,
            })}
          end

          describe "with a custom port" do
            let(:params) {{
              :port => 9093,
            }}

            it { should contain_file(default_configuration_file).with_content(/^port=9093$/) }
          end

          describe "with a single custom ZK server for kafkastore.connection.url" do
            let(:params) {{
              :kafkastore_connection_url => ['zookeeper1:1234'],
            }}

            it { should contain_file(default_configuration_file).
              with_content(/^kafkastore\.connection\.url=zookeeper1:1234$/)
            }
          end

          describe "with a custom three-node ZK quorum for kafkastore.connection.url" do
            let(:params) {{
              :kafkastore_connection_url => ['zookeeper1:1234', 'zookeeper2:5678','zkserver3:2181'],
            }}

            it { should contain_file(default_configuration_file).
              with_content(/^kafkastore\.connection\.url=zookeeper1:1234,zookeeper2:5678,zkserver3:2181$/)
            }
          end

          describe "with a custom $config_map" do
            let(:params) {{
              :config_map => {
                'avro.compatibility.level' => 'full',
              },
            }}

            it { should contain_file(default_configuration_file).
              with_content(/^avro\.compatibility\.level=full$/)
            }
          end
        end

        context "with Hiera data on #{osfamily}" do

          describe "with custom port and avro.compatibility.level" do
            let(:hiera_config) { Hiera_yaml }
            hiera = Hiera.new(:config => Hiera_yaml)
            port = hiera.lookup('schema_registry::port', nil, nil)
            config_map = hiera.lookup('schema_registry::config_map', nil, nil)
            let(:params) {{
              :port => port,
              :config_map => config_map,
            }}

            it { should contain_file(default_configuration_file).with_content(/^port=8888$/) }
            it { should contain_file(default_configuration_file).with_content(/^avro\.compatibility\.level=full$/) }
          end

        end

      end
    end
  end

  context 'unsupported operating system' do
    describe 'without any parameters on Debian' do
      let(:facts) {{
        :osfamily => 'Debian',
      }}

      it { expect { should contain_class('schema_registry') }.to raise_error(Puppet::Error,
        /The schema_registry module is not supported on a Debian based system./) }
    end
  end
end
