default_run_options[:pty] = true
ssh_options[:paranoid] = true

set :application, "kamira"
set :repository,  "git://barrel.mitre.org/kamira/kamira.git"
set :branch, "master"

set :deploy_to, "/var/www/node_apps/kamira"

set :deploy_via, :copy
set :copy_exclude, [".git"]

set :keep_releases, 10
after "deploy:restart", "deploy:cleanup"

set :app_file, "app.coffee"

server "kamira-dev.mitre.org", :web, :app, :db, primary: true

load 'capistrano/upstart'
after 'deploy:setup', 'deploy:write_upstart_script'

namespace :deploy do
  task :start, :roles => :app do
    run "#{sudo} start #{application}"
  end
  task :stop, :roles => :app do
    run "#{sudo} stop #{application}"
  end
  task :restart, :roles => :app do
    run "#{sudo} restart #{application} || #{sudo} start #{application}"
  end
end
