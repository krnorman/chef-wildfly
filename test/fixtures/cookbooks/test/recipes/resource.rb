# Encoding: UTF-8

openjdk_install '11'

service 'wildfly2' do
  action :nothing
end

wildfly 'wildfly2' do
  base_dir '/opt/wildfly2'
  server_properties [
    'jboss.socket.binding.port-offset=2',
    'jboss.bind.address.management=0.0.0.0',
    # 'jboss.management.http.port=9990',
    # 'jboss.management.https.port=9993',
    'jboss.bind.address=0.0.0.0',
    # 'jboss.http.port=8080',
    # 'jboss.https.port=8443',
    'jboss.bind.address.private=0.0.0.0',
    'jboss.bind.address.unsecure=0.0.0.0',
    'jboss.default.multicast.address=230.1.2.3',
    'jboss.ajp.port=8009',
  ]
  action :install
end

# include_recipe 'wildfly::mysql_connector' if node['wildfly']['mysql']['enabled']
# include_recipe 'wildfly::postgres_connector' if node['wildfly']['postgresql']['enabled']

wildfly_property 'Database URL 2' do
  property 'JdbcUrl'
  value 'jdbc:mysql://1.2.3.4:3306/testdbb123'
  action :set
  instance 'wildfly2'
  notifies :restart, 'service[wildfly2]', :delayed
end

wildfly_property 'Create DummyProperty' do
  property 'DummyProperty'
  value 'DummyValue'
  action :set
  instance 'wildfly2'
  notifies :restart, 'service[wildfly2]', :delayed
end

wildfly_property 'Remove DummyProperty' do
  property 'DummyProperty'
  action :delete
  instance 'wildfly2'
  notifies :restart, 'service[wildfly2]', :delayed
end

wildfly_mysql_connector 'wildfly2' do
  instance 'wildfly2'
  api false
  action :install
end

wildfly_postgres_connector 'wildfly2' do
  instance 'wildfly2'
  api false
  action :install
end

wildfly_attribute 'postbox jndi-name' do
  instance 'wildfly2'
  path '/subsystem=mail/mail-session=postbox'
  parameter 'jndi-name'
  value 'java:/mail/postbox'
  action :set
end

wildfly_attribute 'postbox-escaped' do
  instance 'wildfly2'
  path '/subsystem=mail/mail-session=postbox-escaped'
  parameter 'jndi-name'
  value ' WTF BRUHHH /345%20'
  action :set
end

wildfly_attribute 'postbox-noescaped' do
  instance 'wildfly2'
  path '/subsystem=mail/mail-session=postboxnoescaped'
  parameter 'jndi-name'
  value ' WTF BRUHHH /345%200'
  enable_escape false
  action :set
end

wildfly_attribute 'postbox-noescapedsafe' do
  instance 'wildfly2'
  path '/subsystem=mail/mail-session=postboxnoescapedsafe'
  parameter 'jndi-name'
  value 'WTF'
  enable_escape false
  action :set
end

wildfly_datasource 'example' do
  instance 'wildfly2'
  jndiname 'java:jboss/datasource/example'
  drivername 'mysql'
  connectionurl 'jdbc:some://127.0.0.1/example'
end

wildfly_deploy 'helloworld' do
  instance 'wildfly2'
  url 'https://github.com/efsavage/hello-world-war/raw/master/dist/hello-world.war'
end

# => BUG: The deploy resource in WildFly 12.0.0.FINAL doesn't seem to respect the name attribute when a url is specified...
# => Here, we use a remote_file instead to get around it.  It works above because runtime_name is equal to the name (runtime_name still respected)

# => File-Based Deployment
cd = remote_file 'cluster-demo' do
  source 'https://github.com/bdwyertech/cluster-demo/releases/download/011218/cluster-demo.war'
  path ::File.join(Chef::Config[:file_cache_path], 'hello-world.war')
  mode '0644'
  action :create
end

wildfly_deploy 'cluster-demo-v1' do
  instance 'wildfly2'
  path cd.path
  runtime_name 'cluster-demo.war'
end
