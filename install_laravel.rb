version = node[:platform_version][0]
project = node['env']['project']
token = node['env']['token']

package "epel-release"
package "http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm"
package "http://rpms.famillecollet.com/enterprise/remi-release-#{version}.rpm"
package "http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm"


file "/etc/yum.repos.d/remi.repo" do
  action :edit
  block do |content|
    content.gsub!("mirrorlist=http://rpms.remirepo.net/enterprise/7/remi/mirror\nenabled=0", "mirrorlist=http://rpms.remirepo.net/enterprise/7/remi/mirror\nenabled=1")
    content.gsub!("mirrorlist=http://rpms.remirepo.net/enterprise/7/php56/mirror\n# WARNING: If you enable this repository, you must also enable \"remi\"\nenabled=0",
    "mirrorlist=http://rpms.remirepo.net/enterprise/7/php56/mirror\n# WARNING: If you enable this repository, you must also enable \"remi\"\nenabled=1")
    content.gsub!("baseurl=http://rpms.remirepo.net/enterprise/7/debug-php56/$basearch/\nenabled=0","baseurl=http://rpms.remirepo.net/enterprise/7/debug-php56/$basearch/\nenabled=1")
  end
end

%w{
    git
    nginx
    php
    php-gd
    php-mbstring
    php-xml
    php-pdo
    php-mysql
    php-fpm
    composer
    mysql-community-server
}.each do |pkg_name|
  package pkg_name do
    action :install
  end
end

file "/etc/php-fpm.d/www.conf" do
  action :edit
  block do |content|
    content.gsub!("user = apache", "user = nginx")
    content.gsub!("group = apache","group = nginx")
    content.gsub!("group = apache","group = nginx")
    content.gsub!("listen = 127.0.0.1:9000", "listen = /var/run/php-fpm/php-fpm.sock")
    content.gsub!(";listen.owner = nobody", "listen.owner = nginx")
    content.gsub!(";listen.group = nobody", "listen.group = nginx")
    content.gsub!(";listen.mode = 0660", "listen.mode = 0660")
  end
end

template "/etc/nginx/conf.d/default.conf" do
    action :create
    source "/vagrant/laravel.conf"
    variables(project: project)
end

service "nginx" do
    action [:enable, :start]
end

service "php-fpm" do
    action [:enable, :start]
end

service "mysqld" do
    action [:enable, :start]
end

service "firewalld" do
    action [:disable, :stop]
end

execute "add token" do
    command "composer config --global github-oauth.github.com #{token}"
end

execute "create project" do
    command "composer create-project laravel/laravel --prefer-dist #{project}"
    cwd "/usr/share/nginx"
end

execute "change create permision" do
    command "chown -R nginx:nginx #{project}"
    cwd "/usr/share/nginx"
end
