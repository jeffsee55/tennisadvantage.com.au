set :application, 'tennis_advantage'
set :repo_url, 'git@github.com:jeffsee55/tennisadvantage.com.au.git'

set :bundle_binstubs, nil
set :deploy_to, '/home/deploy/tennis_advantage'

set :linked_files, %w{config/database.yml .env}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end
