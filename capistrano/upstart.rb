# Sourced and modified from:
# http://dev.nuclearrooster.com/2010/07/18/capistrano-scripts-for-node-js/

namespace :deploy do

  task :write_upstart_script, :roles => :app do

    upstart_script = <<-UPSTART
description "#{application}"

start on startup
stop on shutdown

script
  export HOME="/root"
  export PORT="80"
  export NODE_ENV="production"
  cd #{current_path}
  exec /usr/bin/coffee #{current_path}/#{app_file} >> #{shared_path}/log/#{application}.log 2>&1
end script

respawn
UPSTART

    put upstart_script, "/tmp/#{application}_upstart.conf"
    run "#{sudo} mv /tmp/#{application}_upstart.conf /etc/init/#{application}.conf"
  end

end
