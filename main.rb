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
    cards.select{ |card| card[1] == "ace"}.count.times do
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

  def blackjack(cards, name)
    if total(cards) == 21
      @success = "#{name} hit blackjack!!!"
      @show_hit_or_stay = false
    end
  end

  def busted(cards, name)
    if total(cards) > 21
      @error = "It looks like #{name} busted!" #instance variables can be accessed in layout.erb
      true
    else
      false
    end
  end

  def dealer_choice(dealer, deck, user_cards, busted)
    begin
      remaining_deck_value = total(deck)
      ave_card_value = remaining_deck_value / deck.size
      if busted
        @dealer_continue = false
      elsif total(dealer) < 21 && (ave_card_value < (21 - total(dealer)) || ( total(user_cards) > total(dealer) ))
        dealer << deck.pop
      else
        @dealer_continue = false
      end
    end until @dealer_continue == false
  end


def check_winner(user, dealer)
  if total(user) == total(dealer)
    @success = "#{session[:player_name]} and the dealer tied!!!"
  elsif total(user) < total(dealer)
    @error = "#{session[:player_name]} lost $#{session[:current_bet]} to the dealer!!!"
    session[:money] = session[:money] - session[:current_bet]
  elsif total(user) > total(dealer)
    @success =  "#{session[:player_name]} won $#{session[:current_bet]} from the dealer!!!"
    session[:money] = session[:money] + session[:current_bet]
  end
end

end

  
get '/' do
  if session[:player_name]
    redirect '/bet'
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
    session[:money] = 500
    redirect '/bet'
  end
  
  
end

get '/game' do 
  @show_hit_or_stay = true
  session[:deck] = []
  session[:player_cards] = []
  session[:dealer_cards] = []
  make_deck(session[:deck])
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_busted] = false
  blackjack(session[:player_cards], session[:player_name])
  erb :game
end

get '/bet' do 
  if session[:money] == 0
    @error = "You ran out of money!!!! Try again next time! Hit Start Over link above."
    erb :bet
  else
    erb :bet
  end
end

post '/set_bet' do
  if params[:current_bet].empty? || params[:current_bet].to_i == 0
    @error = "Bet is required"
    halt erb(:bet)
  elsif session[:money] - params[:current_bet].to_i < 0
    @error = "Sorry, you don't have that much money to bet"
    halt erb(:bet)
  else
    session[:current_bet] = params[:current_bet].to_i
    redirect '/game'
  end
end


post '/game/player/hit' do 
  session[:player_cards] << session[:deck].pop
  @show_hit_or_stay = true
  blackjack(session[:player_cards], session[:player_name])
  if busted(session[:player_cards], session[:player_name])
    @show_hit_or_stay = false
    session[:player_busted] = true
  end
  erb :game
end

post '/game/player/stay' do 
  @success = "#{session[:player_name]} has chosen to stay!"
  @show_hit_or_stay = false
  erb :game
end

post '/game/dealer' do
  @dealer_continue = true
  dealer_choice(session[:dealer_cards], session[:deck], session[:player_cards], session[:player_busted])
  blackjack(session[:dealer_cards], "The dealer")
  if session[:player_busted]
     @error = "#{session[:player_name]} lost $#{session[:current_bet]} to the dealer!!!"
    session[:money] = session[:money] - session[:current_bet]
  else 
    dealer_choice(session[:dealer_cards], session[:deck], session[:player_cards], session[:player_busted])
  
    if busted(session[:dealer_cards], "the dealer")
      @success =  "#{session[:player_name]} won $#{session[:current_bet]} from the dealer!!!"
      session[:money] = session[:money] + session[:current_bet]
    else
      check_winner(session[:player_cards], session[:dealer_cards])
    end
  end
  erb :game
end

get '/startover' do
  session[:player_name] = nil
  redirect '/'
end



