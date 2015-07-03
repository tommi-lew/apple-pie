require_relative File.join('config', 'shared.rb')

get '/' do
  '200'
end

post '/' do
  puts JSON.parse(request.body.read)
end
