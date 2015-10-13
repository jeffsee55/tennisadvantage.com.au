role :app, %w{deploy@104.236.173.245}
role :web, %w{deploy@104.236.173.245}
role :db,  %w{deploy@104.236.173.245}

set :stage, :production

server '104.236.173.245', user: 'deploy', roles: %w{web app}
