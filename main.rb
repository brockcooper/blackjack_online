require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

set :sessions, true

helpers do 

  def make_deck(deck) # Initializes deck
    ["hearts", "diamonds", "clubs", "spades"].each do |suit|
      ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"].each do |value|
         deck << [suit, value]
      end
    end
    deck.shuffle!
  end

  def deal(player_cards) #Deals one card to the defined player
    player_cards << session[:deck].pop
  end

  def total(cards) # Calcs total of a set of cards
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

  def image_url(card) # Makes correct URL for card images
    suit = card[0]
    value = card[1]
    "<img class='card' src='/images/cards/#{suit}_#{value}.jpg'>"
  end

  def blackjack(cards, name) # Checks for blackjack
    if total(cards) == 21
      @win = "#{name} hit blackjack!!!"
      @show_hit_or_stay = false
    end
  end

  def busted(cards, name) # Checks if player busted
    if total(cards) > 21
      @lose = "It looks like #{name} busted!" #instance variables can be accessed in layout.erb
      true
    else
      false
    end
  end

  def dealer_choice(dealer, deck, user_cards, busted) # Logic for dealer to choose to hit or stay
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


  def check_winner(user, dealer) # checks who won
    if total(user) == total(dealer)
      @win = "#{session[:player_name]} and the dealer tied!!!"
    elsif total(user) < total(dealer)
      player_lose
    elsif total(user) > total(dealer)
      player_win
    end
  end

  def player_win # Displays win banner and changes money amount
    @win =  "#{session[:player_name]} won $#{session[:current_bet]} from the dealer!!!"
    session[:money] = session[:money] + session[:current_bet]
  end

  def player_lose # Displays lose banner and changes money amount
    @lose = "#{session[:player_name]} lost $#{session[:current_bet]} to the dealer!!!"
    session[:money] = session[:money] - session[:current_bet]
  end

end

  
get '/' do
  # See if player name is set or not
  if session[:player_name]
    redirect '/bet'
  else
    erb :set_name
  end


  
end

post '/set_name' do
  # Checks to see if name entry is okay
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:set_name)
  else
    # Sets name to the session and initializes betting money for the game
    session[:player_name] = params[:player_name]
    session[:money] = 500
    redirect '/bet'
  end
  
  
end

get '/game' do 
  #Initialize game variables
  @show_hit_or_stay = true
  session[:deck] = []
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_busted] = false
  make_deck(session[:deck])

  #Deal out first two cards
  deal(session[:player_cards])
  deal(session[:dealer_cards])
  deal(session[:player_cards])
  deal(session[:dealer_cards])
  
  #Check for player's blackjack based off first two cards
  blackjack(session[:player_cards], session[:player_name])

  erb :game
end

get '/bet' do 
  # First checks to see if you have enough money, then it lets you place bet
  if session[:money] == 0
    @error = "You ran out of money!!!! Try again next time! Hit Start Over link above."
    erb :game_over #game_over is a blank template
  else
    erb :bet
  end
end

post '/set_bet' do
  # Checks to see if betting amount was entered correctly
  if params[:current_bet].empty? || params[:current_bet].to_i <= 0
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
  # Deal cards and check for blackjack or bust
  deal(session[:player_cards])
  @show_hit_or_stay = true
  blackjack(session[:player_cards], session[:player_name])
  if busted(session[:player_cards], session[:player_name])
    @show_hit_or_stay = false
    session[:player_busted] = true
  end
  erb :game, layout: false
end

post '/game/player/stay' do 
  # Stop the player's turn if he stays
  @win = "#{session[:player_name]} has chosen to stay!"
  @show_hit_or_stay = false
  erb :game, layout: false
end

post '/game/dealer' do
  # Figures out what the dealer wants to do
  @dealer_continue = true
  dealer_choice(session[:dealer_cards], session[:deck], session[:player_cards], session[:player_busted])
  blackjack(session[:dealer_cards], "The dealer")
  
  # Checks if the player or dealer busted first, then runs check winner if no one busted
  if session[:player_busted] #Player loses if he busted
    player_lose
  elsif busted(session[:dealer_cards], "the dealer")
    player_win
  else
    check_winner(session[:player_cards], session[:dealer_cards])
  end
  erb :game, layout: false
end

get '/startover' do
  # Resets game
  session[:player_name] = nil
  redirect '/'
end



