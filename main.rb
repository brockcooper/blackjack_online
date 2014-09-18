require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

set :sessions, true
  
get '/' do
  erb :set_name
end

post '/set_name' do
  if params[:player_name] != ""
    session[:player_name] = params[:player_name]
    redirect '/game'
  else
    redirect '/'
  end
  
end

get '/game' do 
  session[:deck] = []
    ["Hearts", "Diamonds", "Clubs", "Spades"].each do |suit|
      ["2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King", "Ace"].each do |value|
         session[:deck] << [suit, value]
      end
    end
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop
  erb :game
end

get '/hello' do 
  erb :"/user/hello"
end




