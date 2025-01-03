require 'sinatra/base'
require 'rack-flash'

require_relative 'team.rb'
require_relative 'tournament.rb'
require_relative 'swiss.rb'
require_relative 'phone.rb'

# login info
# https://stackoverflow.com/questions/2691997/sinatra-how-do-i-provide-access-to-a-login-form-while-preventing-access-to-the

class ThawApp < Sinatra::Base

  def save_tournaments(file="tourns.msl")
    open(file, "w") do |f|
      f.write Marshal.dump(settings.tournaments)
    end
  end

  def self.load_tournaments(file="tourns.msl")
    return unless File.exist? file

    settings.tournaments = Marshal.load File.read(file)
  end

  configure do
    #set :environment, :production
    set :public_folder, 'public'
    set :server, 'puma'
    enable :sessions
    set :session_secret, '19028309u23oirhjknes-pl]]*&^%$#[];/../faskljdhf0923i4902734y9uihrqwejkf'

    use Rack::Flash

    set :tournaments, []
    load_tournaments
  end

  helpers do
    def link_to(obj, text: nil, mode: :read, **args)
      if obj.is_a? Tournament
        link = case mode
               when :create
                 "/new"
               when :read
                 "/#{obj.id}"
               when :update
                 "/edit/#{obj.id}"
               when :delete
                 "/delete/#{obj.id}"
               end

        text ||= "Tournament #{obj.id}"
      else
        link ||= obj.to_s
        text ||= obj.to_s
      end

      params = args.map {|k, v| "#{k}=#{v}" }.join ' '

      "<a href=#{link} #{params}>#{text}</a>"
    end

    def refresh_swiss_matches(tourn)
      # Reset these since we're about to repopulate them based on updated
      # score information
      tourn.swiss.teams.each do |t|
        t.wins   = []
        t.losses = []
        t.draws  = []
      end

      # Take the score info from the matches and turn them into wins and losses
      tourn.rounds.each do |round|
        round.each do |pairing|
          t_1 = pairing.team_1
          t_2 = pairing.team_2

          s_1 = pairing.score_1
          s_2 = pairing.score_2

          for_t_1 = Swiss::Match.new t_2, pairing.time, s_1, s_2
          for_t_2 = Swiss::Match.new t_1, pairing.time, s_2, s_1

          if s_1 > s_2
            t_1.wins   << for_t_1
            t_2.losses << for_t_2
          elsif s_2 > s_1
            t_1.losses << for_t_1
            t_2.wins   << for_t_2
          else # draw
            t_1.draws << for_t_1
            t_2.draws << for_t_2
          end
        end
      end
    end
  end

  before do
    response.headers['x-clocks-overhead'] = "GNU Terry Pratchett"
  end

  get '/' do
    erb :index
  end

  get '/new' do
    erb :create
  end

  post '/new' do
    teams = params[:teams].map {|t| [t, []] }.to_h

    teams_list = params[:teams].map.with_index {|t, i| Team.new(i, t) }
    swiss = Swiss.new teams_list

    tourn = Tournament.new teams_list,
                           Time.parse(params[:start].strip),
                           params[:duration].strip.to_i,
                           params[:courts].strip.to_i,
                           swiss,
                           []

    settings.tournaments << tourn

    save_tournaments

    redirect "/#{tourn.id}"
  end

  get '/:id' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    @rankings = @tournament.swiss.teams.sort.reverse.map do |team|
      [team, team.record, team.goals, team.goal_differential]
    end

    erb :read
  end

  get '/edit/:id' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    @rankings = @tournament.swiss.teams.sort.reverse.map do |team|
      [team, team.record, team.goals, team.goal_differential]
    end

    erb :update
  end

  post '/edit/:id' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    @tournament.start    = Time.parse(params[:start].strip)
    @tournament.duration = params[:duration].strip.to_i
    @tournament.courts   = params[:courts].strip.to_i

    params[:points].each do |id, points|
      m = @tournament.rounds.flatten.find {|m| m.object_id.to_s == id }
      m.score_1 = points["1"].empty? ? nil : points["1"].to_i
      m.score_2 = points["2"].empty? ? nil : points["2"].to_i
    end

    save_tournaments

    redirect "/#{@tournament.id}"
  end

  get '/players/:id' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    erb :players_read
  end

  get '/players/:id/edit' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    erb :players_update
  end

  post '/players/:id' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    if params[:players]
      params[:players].each do |team_id, players|
        players = players["names"].zip players["phones"]

        team = @tournament.teams.find {|t| t.id == team_id.to_i }
        redirect "/#{@tournament.id}" unless team

        team.players = players
      end

      save_tournaments
    end

    redirect "/players/#{@tournament.id}"
  end

  get '/new_round/:id' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    refresh_swiss_matches @tournament

    pairings = @tournament.swiss.next_round

    last_round = @tournament.rounds.last
    start = last_round ? last_round.last.time : @tournament.start - @tournament.duration * 60

    formatted_pairs = pairings.map.with_index do |(t1, t2), i|
      start += @tournament.duration * 60 if i % @tournament.courts == 0
      court = ('A'..'Z').to_a[i % @tournament.courts]
      Tournament::Pairing.new start, t1, nil, t2, nil, court
    end

    @tournament.rounds << formatted_pairs

    save_tournaments

    redirect "/edit/#{params[:id]}"
  end

  get '/text/:id' do
    @tournament = settings.tournaments.find {|t| t.id == params[:id].to_i }
    redirect '/new' unless @tournament

    redirect "/#{params[:id]}" unless @tournament.rounds.last
    @tournament.text_round @tournament.rounds.last

    redirect "/#{params[:id]}"
  end

  not_found do
    status 404
    File.read 'public/404.html'
  end
end

ThawApp.run!

