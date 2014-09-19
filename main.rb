require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

set :sessions, true

helpers do 

  def make_deck(deck)
    ["hearts", "diamonds", "clubs", "spades"].each do |suit|
      ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"].each do |value|
         deck << [suit, value]
      end
    end
    deck.shuffle!
  end

  def total(cards)
    sum = 0
    cards.each do |array|
      if array[1] == "king" || array[1] == "queen" || array[1] == "jack"
        sum += 10
      elsif array[1] == "ace"
        sum += 11
      else
        sum += array[1].to_i
      end
    end
    
    # Correct for aces
    cards.select{ |card| card == "ace"}.count.times do
      break if sum <= 21
      sum -= 10
    end

    sum
  end

  def image_url(card)
    suit = card[0]
    value = card[1]
    "<img class='card' src='/images/cards/#{suit}_#{value}.jpg'>"
  end

  def blackjack(cards)
    if total(cards) == 21
      @success = "Congratulations #{session[:player_name]}! You hit blackjack"
      @show_hit_or_stay = false
    end
  end

end

before do 
  @show_hit_or_stay = true
end
  
get '/' do
  if session[:player_name]
    redirect '/game'
  else
    erb :set_name
  end


  
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:set_name)
  else
    session[:player_name] = params[:player_name]
    redirect '/game'
  end
  
  
end

get '/game' do 
  session[:deck] = []
  session[:player_cards] = []
  session[:dealer_cards] = []
  make_deck(session[:deck])
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  blackjack(session[:player_cards])
  erb :game
end

get '/hello' do 
  erb :"/user/hello"
end

post '/game/player/hit' do 
  session[:player_cards] << session[:deck].pop
  blackjack(session[:player_cards])
  if total(session[:player_cards]) > 21
    @error = "Sorry, it looks like #{session[:player_name]} busted!" #instance variables can be accessed in layout.erb
    @show_hit_or_stay = false
  end
  erb :game
end

post '/game/player/stay' do 
  @success = "#{session[:player_name]} has chosen to stay!"
  @show_hit_or_stay = false
  erb :game
end

