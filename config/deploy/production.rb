set :rails_env, 'production'
server 'dashboard-production-b1.code.org', :app, :web, :db, :primary => true
server 'dashboard-production-c1.code.org', :app, :web
server 'dashboard-production-d1.code.org', :app, :web
