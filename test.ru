require 'sinatra/base'

class ABC < Sinatra::Application
  get '/' do
    env.inspect
  end
end

run ABC.new
