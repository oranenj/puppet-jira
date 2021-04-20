require 'spec_helper.rb'

describe 'jira' do
  describe 'jira::config' do
    context 'supported operating systems' do
      on_supported_os.each do |os, facts|
        context "on #{os}" do
          let(:facts) do
            facts
          end

          context 'default params' do
            let(:params) do
              {
                javahome: '/opt/java'
              }
            end

            it { is_expected.to compile.with_all_deps }
            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/setenv.sh').
                with_content(%r{#DISABLE_NOTIFICATIONS=})
            end
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/user.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml') }
            # Also ensure that we actually omit elements by default
            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{jdbc:postgresql://localhost:5432/jira}).
                with_content(%r{<schema-name>public</schema-name>}).
                without_content(%r{<pool})
            end
            it { is_expected.not_to contain_file('/home/jira/cluster.properties') }
            it { is_expected.not_to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/check-java.sh') }
          end

          context 'default params with java install' do
            let(:params) do
              {
                javahome: '/usr/lib/jvm/jre-11-openjdk',
                java_package: 'java-11-openjdk-headless',
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_package('java-11-openjdk-headless') }
          end

          context 'database settings' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                connection_settings: 'TEST-SETTING;',
                pool_max_size: 20,
                pool_min_size: 10,
                validation_query: 'SELECT version();',
              }
            end

            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/setenv.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/user.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml') }
            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{<connection-settings>TEST-SETTING;</connection-settings>}).
                with_content(%r{<pool-max-size>20</pool-max-size>}).
                with_content(%r{<pool-min-size>10</pool-min-size>}).
                with_content(%r{<validation-query>SELECT version\(\);</validation-query>})
            end
          end

          context 'mysql params' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                db: 'mysql'
              }
            end

            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/setenv.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/user.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml') }
            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{jdbc:mysql://localhost:3306/jira})
            end
          end

          context 'oracle params' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                db: 'oracle',
                dbname: 'mydatabase',
              }
            end

            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{jdbc:oracle:thin:@localhost:1521:mydatabase}).
                with_content(%r{<database-type>oracle10g}).
                with_content(%r{<driver-class>oracle.jdbc.OracleDriver})
            end
          end

          context 'oracle servicename' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                db: 'oracle',
                dbport: 1522,
                dbserver: 'oracleserver',
                oracle_use_sid: false,
                dbname: 'mydatabase',
              }
            end

            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{jdbc:oracle:thin:@oracleserver:1522/mydatabase})
            end
          end

          context 'sqlserver params' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                db: 'sqlserver',
                dbport: '1433',
                dbschema: 'public'
              }
            end

            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/setenv.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/user.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml') }
            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{<schema-name>public</schema-name>})
            end
          end

          context 'custom dburl' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                dburl: 'my custom dburl'
              }
            end

            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{<url>my custom dburl</url>})
            end
          end

          context 'customise tomcat connector' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_port: 9229
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{<Connector port=\"9229\"\s+relaxedPathChars=}m)
            end
          end

          context 'server.xml listeners' do
            context 'version greater than 8' do
              let(:params) do
                {
                  version: '8.1.0',
                  javahome: '/opt/java'
                }
              end

              it do
                is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.1.0-standalone/conf/server.xml').
                  with_content(%r{<Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener\"})
              end
            end
          end

          context 'customise tomcat connector with a binding address' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_port: 9229,
                tomcat_address: '127.0.0.1'
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{<Connector port=\"9229\"\s+address=\"127\.0\.0\.1\"\s+relaxedPathChars=}m)
            end
          end

          context 'tomcat context path' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                contextpath: '/jira'
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{path="/jira"})
            end
          end

          context 'tomcat port' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_port: 8888
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{port="8888"})
            end
          end

          context 'tomcat acceptCount' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_accept_count: 200
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{acceptCount="200"})
            end
          end

          context 'tomcat MaxHttpHeaderSize' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_max_http_header_size: 4096
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{maxHttpHeaderSize="4096"})
            end
          end

          context 'tomcat MinSpareThreads' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_min_spare_threads: 50
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{minSpareThreads="50"})
            end
          end

          context 'tomcat ConnectionTimeout' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_connection_timeout: 25_000
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{connectionTimeout="25000"})
            end
          end

          context 'tomcat EnableLookups' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_enable_lookups: true
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{enableLookups="true"})
            end
          end

          context 'tomcat Protocol' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_protocol: 'HTTP/1.1'
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{protocol="HTTP/1.1"})
            end
          end

          context 'tomcat UseBodyEncodingForURI' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_use_body_encoding_for_uri: false
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{useBodyEncodingForURI="false"})
            end
          end

          context 'tomcat DisableUploadTimeout' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_disable_upload_timeout: false
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{disableUploadTimeout="false"})
            end
          end

          context 'tomcat EnableLookups' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_enable_lookups: true
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{enableLookups="true"})
            end
          end

          context 'tomcat maxThreads' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_max_threads: 300
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{maxThreads="300"})
            end
          end

          context 'tomcat proxy path' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                proxy: {
                  'scheme'    => 'https',
                  'proxyName' => 'www.example.com',
                  'proxyPort' => '9999'
                }
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{proxyName = 'www\.example\.com'}).
                with_content(%r{scheme = 'https'}).
                with_content(%r{proxyPort = '9999'})
            end
          end

          context 'ajp proxy' do
            context 'with valid config including protocol AJP/1.3' do
              let(:params) do
                {
                  version: '8.13.5',
                  javahome: '/opt/java',
                  ajp: {
                    'port'     => '8009',
                    'protocol' => 'AJP/1.3'
                  }
                }
              end

              it do
                is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                  with_content(%r{<Connector enableLookups="false" URIEncoding="UTF-8"\s+port = "8009"\s+protocol = "AJP/1.3"\s+/>})
              end
            end
            context 'with valid config including protocol org.apache.coyote.ajp.AjpNioProtocol' do
              let(:params) do
                {
                  version: '8.13.5',
                  javahome: '/opt/java',
                  ajp: {
                    'port'     => '8009',
                    'protocol' => 'org.apache.coyote.ajp.AjpNioProtocol'
                  }
                }
              end

              it do
                is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                  with_content(%r{<Connector enableLookups="false" URIEncoding="UTF-8"\s+port = "8009"\s+protocol = "org.apache.coyote.ajp.AjpNioProtocol"\s+/>})
              end
            end
          end

          context 'tomcat additional connectors, without default' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_default_connector: false,
                tomcat_additional_connectors: {
                  8081 => {
                    'URIEncoding' => 'UTF-8',
                    'connectionTimeout' => '20000',
                    'protocol' => 'HTTP/1.1',
                    'proxyName' => 'foo.example.com',
                    'proxyPort' => '8123',
                    'secure' => true,
                    'scheme' => 'https'
                  },
                  8082 => {
                    'URIEncoding' => 'UTF-8',
                    'connectionTimeout' => '20000',
                    'protocol' => 'HTTP/1.1',
                    'proxyName' => 'bar.example.com',
                    'proxyPort' => '8124',
                    'scheme' => 'http'
                  }
                }
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                without_content(%r{<Connector port="8080"}).
                with_content(%r{<Connector port="8081"}).
                with_content(%r{connectionTimeout="20000"}).
                with_content(%r{protocol="HTTP/1\.1"}).
                with_content(%r{proxyName="foo\.example\.com"}).
                with_content(%r{proxyPort="8123"}).
                with_content(%r{scheme="https"}).
                with_content(%r{secure="true"}).
                with_content(%r{URIEncoding="UTF-8"}).
                with_content(%r{<Connector port="8082"}).
                with_content(%r{connectionTimeout="20000"}).
                with_content(%r{protocol="HTTP/1\.1"}).
                with_content(%r{proxyName="bar\.example\.com"}).
                with_content(%r{proxyPort="8124"}).
                with_content(%r{scheme="http"}).
                with_content(%r{URIEncoding="UTF-8"})
            end
          end

          context 'tomcat access log format' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_accesslog_format: '%a %{jira.request.id}r %{jira.request.username}r %t %I'
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{pattern="%a %{jira.request.id}r %{jira.request.username}r %t %I"/>})
            end
          end

          context 'tomcat access log format with x-forward-for handling' do
            let(:params) do
              {
                version: '8.16.0',
                javahome: '/opt/java',
                tomcat_accesslog_enable_xforwarded_for: true,
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/conf/server.xml').
                with_content(%r{org.apache.catalina.valves.RemoteIpValve}).
                with_content(%r{requestAttributesEnabled="true"})
            end
          end

          context 'with script_check_java_managed enabled' do
            let(:params) do
              {
                script_check_java_manage: true,
                version: '8.1.0',
                javahome: '/opt/java'
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.1.0-standalone/bin/check-java.sh').
                with_content(%r{Wrong JVM version})
            end
          end

          context 'context resources' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                resources: { 'testdb' => { 'auth' => 'Container' } }
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/context.xml').
                with_content(%r{<Resource name = "testdb"\n        auth = "Container"\n    />})
            end
          end

          context 'disable notifications' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                disable_notifications: true
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/bin/setenv.sh').
                with_content(%r{^DISABLE_NOTIFICATIONS=})
            end
          end

          context 'native ssl support default params' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_native_ssl: true
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{redirectPort="8443"}).
                with_content(%r{port="8443"}).
                with_content(%r{keyAlias="jira"}).
                with_content(%r{keystoreFile="/home/jira/jira.jks"}).
                with_content(%r{keystorePass="changeit"}).
                with_content(%r{keystoreType="JKS"}).
                with_content(%r{port="8443".*acceptCount="100"}m).
                with_content(%r{port="8443".*maxThreads="150"}m)
            end
          end

          context 'native ssl support custom params' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                tomcat_native_ssl: true,
                tomcat_https_port: 9443,
                tomcat_address: '127.0.0.1',
                tomcat_max_threads: 600,
                tomcat_accept_count: 600,
                tomcat_key_alias: 'keystorealias',
                tomcat_keystore_file: '/tmp/keyfile.ks',
                tomcat_keystore_pass: 'keystorepass',
                tomcat_keystore_type: 'PKCS12'
              }
            end

            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.13.5-standalone/conf/server.xml').
                with_content(%r{redirectPort="9443"}).
                with_content(%r{port="9443"}).
                with_content(%r{keyAlias="keystorealias"}).
                with_content(%r{keystoreFile="/tmp/keyfile.ks"}).
                with_content(%r{keystorePass="keystorepass"}).
                with_content(%r{keystoreType="PKCS12"}).
                with_content(%r{port="9443".*acceptCount="600"}m).
                with_content(%r{port="9443".*maxThreads="600"}m).
                with_content(%r{port="9443".*address="127\.0\.0\.1"}m)
            end
          end

          context 'enable secure admin sessions' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                enable_secure_admin_sessions: true
              }
            end

            it do
              is_expected.to contain_file('/home/jira/jira-config.properties').
                with_content(%r{jira.websudo.is.disabled = false})
            end
          end

          context 'disable secure admin sessions' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                enable_secure_admin_sessions: false
              }
            end

            it do
              is_expected.to contain_file('/home/jira/jira-config.properties').
                with_content(%r{jira.websudo.is.disabled = true})
            end
          end

          context 'jira-config.properties' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                jira_config_properties: {
                  'ops.bar.group.size.opsbar-transitions' => '4'
                }
              }
            end

            it do
              is_expected.to contain_file('/home/jira/jira-config.properties').
                with_content(%r{jira.websudo.is.disabled = false}).
                with_content(%r{ops.bar.group.size.opsbar-transitions = 4})
            end
          end

          context 'enable clustering' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                datacenter: true,
                shared_homedir: '/mnt/jira_shared_home_dir'
              }
            end

            it do
              is_expected.to contain_file('/home/jira/cluster.properties').
                with_content(%r{jira.node.id = \S+}).
                with_content(%r{jira.shared.home = /mnt/jira_shared_home_dir})
            end
          end

          context 'enable clustering with ehcache options' do
            let(:params) do
              {
                version: '8.13.5',
                javahome: '/opt/java',
                datacenter: true,
                shared_homedir: '/mnt/jira_shared_home_dir',
                ehcache_listener_host: 'jira.foo.net',
                ehcache_listener_port: 42,
                ehcache_object_port: 401
              }
            end

            it do
              is_expected.to contain_file('/home/jira/cluster.properties').
                with_content(%r{jira.node.id = \S+}).
                with_content(%r{jira.shared.home = /mnt/jira_shared_home_dir}).
                with_content(%r{ehcache.listener.hostName = jira.foo.net}).
                with_content(%r{ehcache.listener.port = 42}).
                with_content(%r{ehcache.object.port = 401})
            end
          end

          context 'jira-8.12 - OpenJDK jvm params' do
            let(:params) do
              {
                version: '8.16.0',
                javahome: '/opt/java',
                jvm_type: 'openjdk-11'
              }
            end

            it { is_expected.to compile.with_all_deps }
            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/bin/setenv.sh').
                with_content(%r{#DISABLE_NOTIFICATIONS=}).
                with_content(%r{JVM_SUPPORT_RECOMMENDED_ARGS=''}).
                with_content(%r{JVM_GC_ARGS='.+ \-XX:\+ExplicitGCInvokesConcurrent}).
                with_content(%r{JVM_CODE_CACHE_ARGS='\S+InitialCodeCacheSize=32m \S+ReservedCodeCacheSize=512m}).
                with_content(%r{JVM_REQUIRED_ARGS='.+InterningDocumentFactory})
            end
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/bin/user.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/conf/server.xml') }
            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{jdbc:postgresql://localhost:5432/jira}).
                with_content(%r{<schema-name>public</schema-name>})
            end
            it { is_expected.not_to contain_file('/home/jira/cluster.properties') }
            it { is_expected.not_to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/bin/check-java.sh') }
          end

          context 'jira-8.12 - custom jvm params' do
            let(:params) do
              {
                version: '8.16.0',
                javahome: '/opt/java',
                java_opts: '-XX:-TEST_OPTIONAL',
                jvm_gc_args: '-XX:-TEST_GC_ARG',
                jvm_code_cache_args: '-XX:-TEST_CODECACHE',
                jvm_extra_args: '-XX:-TEST_EXTRA'
              }
            end

            it { is_expected.to compile.with_all_deps }
            it do
              is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/bin/setenv.sh').
                with_content(%r{#DISABLE_NOTIFICATIONS=}).
                with_content(%r{JVM_SUPPORT_RECOMMENDED_ARGS=\S+TEST_OPTIONAL}).
                with_content(%r{JVM_GC_ARGS=\S+TEST_GC_ARG}).
                with_content(%r{JVM_CODE_CACHE_ARGS=\S+TEST_CODECACHE}).
                with_content(%r{JVM_EXTRA_ARGS=\S+TEST_EXTRA})
            end
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/bin/user.sh') }
            it { is_expected.to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/conf/server.xml') }
            it do
              is_expected.to contain_file('/home/jira/dbconfig.xml').
                with_content(%r{jdbc:postgresql://localhost:5432/jira}).
                with_content(%r{<schema-name>public</schema-name>})
            end
            it { is_expected.not_to contain_file('/home/jira/cluster.properties') }
            it { is_expected.not_to contain_file('/opt/jira/atlassian-jira-software-8.16.0-standalone/bin/check-java.sh') }
          end
        end
      end
    end
  end
end
