set :rails_env, 'staging'
server "staging.dev-code.org", :app, :web, :db, :primary => true
