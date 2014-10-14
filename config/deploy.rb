# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, '123dazahui.com'
set :repo_url, 'git@github.com:cmingxu/123dazahui.com.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/ubuntu/codes'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5 

set :rvm_type, :user
set :rvm_ruby_version, '2.1.3'
set :default_env, { rvm_bin_path: '~/.rvm/bin' }

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command do
      on roles(:all) do |host|
        execute "/etc/init.d/unicorn_dazahui #{command}"
      end
    end
  end

  task :change_dazahui_permission do
    on roles(:all) do |host|
      execute "chmod a+x #{current_path}/config/dazahui.sh"
    end
  end
  after "deploy:published", "deploy:change_dazahui_permission"


  task :setup_config do
    on roles(:all) do |host|
      sudo "ln -nfs #{current_path}/config/123dazahui.com.conf /etc/nginx/sites-enabled/dazahui"
      sudo "ln -nfs #{current_path}/config/dazahui.sh /etc/init.d/unicorn_dazahui"
    end
  end
  after "deploy:published", "deploy:setup_config"

end



namespace :whenever do
  def setup_whenever_task(*args, &block)
    args = Array(fetch(:whenever_command)) + args

    on roles fetch(:whenever_roles) do |host|
      args = args + Array(yield(host)) if block_given?
      within release_path do
        with fetch(:whenever_command_environment_variables) do
          execute *args
        end
      end
    end
  end

  desc "Update application's crontab entries using Whenever"
  task :update_crontab do
    setup_whenever_task do |host|
      roles = host.roles_array.join(",")
      [fetch(:whenever_update_flags),  "--roles=#{roles}"]
    end
  end

  desc "Clear application's crontab entries using Whenever"
  task :clear_crontab do
    setup_whenever_task(fetch(:whenever_clear_flags))
  end

  after "deploy:updated",  "whenever:update_crontab"
  after "deploy:reverted", "whenever:update_crontab"
end

namespace :load do
  task :defaults do
    set :whenever_roles,        ->{ :db }
    set :whenever_command,      ->{ [:bundle, :exec, :whenever] }
    set :whenever_command_environment_variables, ->{ {} }
    set :whenever_identifier,   ->{ fetch :application }
    set :whenever_environment,  ->{ fetch :rails_env, fetch(:stage, "production") }
    set :whenever_variables,    ->{ "environment=#{fetch :whenever_environment}" }
    set :whenever_update_flags, ->{ "--update-crontab #{fetch :whenever_identifier} --set #{fetch :whenever_variables}" }
    set :whenever_clear_flags,  ->{ "--clear-crontab #{fetch :whenever_identifier}" }
  end
end
