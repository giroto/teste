require 'bundler/capistrano'

set :application, "dashboard"
set :user, "ubuntu"
set :use_sudo, false
set :stages, ["staging", "production", "private"]
#set :default_stage, "staging"

set :scm, "git"
set :branch, "master"
set :repository,  "https://github.com/code-dot-org/dashboard.git"
#set :git_enable_submodules, 1

set :keep_releases, 10
set :deploy_to, "/home/#{user}/apps/#{application}"

require 'capistrano/ext/multistage'

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn #{command}"
    end
  end

  task :upload_blockly do
    rake = fetch(:rake, 'rake')
    rails_env = fetch(:rails_env, 'development')

    tar_ball = "#{release_path}/public/blockly/blockly-mooc.tgz"

    run "mkdir -p #{release_path}/public/blockly"
    top.upload(File.expand_path("#{blockly}/dist/blockly-mooc.tgz"), tar_ball)
    top.upload(File.expand_path("#{blockly}/.cache_bust"), "#{release_path}/.cache_bust")
    run "chmod +x #{tar_ball}"
    run "tar -xvf #{tar_ball} && mv /home/#{user}/package/* #{release_path}/public/blockly/"
    run "rm #{release_path}/public/blockly/blockly-mooc.tgz"
    run "cd '#{release_path}' && #{rake} youtube:thumbnails pseudolocalize RAILS_ENV=#{rails_env}"
    run "cd '#{release_path}' && #{rake} seed:all  RAILS_ENV=#{rails_env}", :only => { :primary => true }
  end

  task :setup_config, roles: :app do
    run "export RAILS_ENV=#{rails_env}"
    sudo "#{current_path}/server_setup.sh #{current_path} #{user} #{rails_env}"
  end
  before "deploy:restart", "deploy:setup_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end

  task :directory_structure do
    run "mkdir -p ~/apps/dashboard/releases"
  end

  task :install_git do
    run "which git ; if [ $? -eq 1] ; then run sudo aptitude -y install git ; fi"
  end

  task :upload_secrets do
    run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
  end
  after "deploy:finalize_update", "deploy:upload_secrets"
  after "deploy:update_code", "deploy:upload_blockly"

  task :setup_secrets do
    run "mkdir -p #{shared_path}/config"
    top.upload(File.expand_path("#{secrets}/application.yml"), File.join(shared_path, "config/application.yml"))
  end
  after "deploy:setup", "deploy:setup_secrets"


  before "deploy", "deploy:check_revision"
  after "deploy:restart", "deploy:cleanup"
end

require './config/boot'
require 'honeybadger/capistrano'
