require 'time'
require 'csv'
require_relative 'team.rb'
require_relative 'phone.rb'

# SAMPLE
# --------------------------
# start    | 09:00
# duration | 15
# 
# the sun
# the magician
# the joker
# queen of cups
# the moon
# the stars
# the empress
# the emperor
# the hierophant
# the lovers
# the chariot
# the tower
# 
# |  game  | time  |   team 1    | score 1 |  team 2   | score 2 |
# +--------+-------+-------------+---------+-----------+---------+
# | r1g1cA | 09:00 |  the tower  |    2    |  the sun  |    6    |
# | r1g2cA | 09:15 | the lovers  |    3    | the joker |    3    |
# | r1g3cA | 09:30 | the emperor |    7    | the moon  |    1    |
# 
# |  game  | time  |     team 1     | score 1 |    team 2     | score 2 |
# +--------+-------+----------------+---------+---------------+---------+
# | r1g1cB | 09:00 |  the chariot   |    3    | the magician  |    3    |
# | r1g2cB | 09:15 | the hierophant |    4    | queen of cups |    2    |
# | r1g3cB | 09:30 |  the empress   |    6    |   the stars   |    3    |

module ScoreTable
  extend self

  def parse(str)
    rows = CSV.parse str, :col_sep => '|',
                          :header_converters => lambda {|f| f.strip },
                          :converters => lambda {|f| f && f.strip }
    stats, team_names, *rounds = split_by(rows) {|r| r.empty? }

    start, duration = *parse_stats(stats)

    teams = team_names.map.with_index {|t, i| [t[0], Team.new(i, t[0])] }.to_h

    rounds = rounds.map.with_index do |r, i|
      parse_round teams, r
    end

    [teams.values, rounds, [start, duration]]
  end

  # Given a list of arrays (as output from CSV parsing), split the list
  # into sublists
  #
  # so take the sample input and break it up into team names and subsequent
  # rounds
  def split_by(rows, &sep)
    rows.chunk(&sep).filter {|b, _| not b }.map {|_, v| v }
  end

  def parse_stats(stats)
    (_, start), (_, duration) = *stats
    [Time.parse(start), duration.to_i * 60]
  end

  def parse_round(teams, r)
    headers, separator, *matches = *r

    matches.map do |m|
      parse_match teams, m
    end
  end

  def parse_match(teams, m)
    #   | game | time | team 1 | score 1 | team 2 | score 2 |
    # is parsed in CVS w/ '|' delimiter as:
    #   nil, game, _, team_1, score_1, team_2, score_2, nil
    _, game, t, t_1, s_1, t_2, s_2, _ = *m.map {|x| x && x.strip }

    time = Time.parse t.strip

    t_1 = teams[t_1]
    t_2 = teams[t_2]

    for_t_1 = Swiss::Match.new t_2, time, s_1.to_i, s_2.to_i
    for_t_2 = Swiss::Match.new t_1, time, s_2.to_i, s_1.to_i

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

    [game, time, t_1.name, s_1, t_2.name, s_2]
  end
end

class Tournament
  attr_accessor :teams
  attr_accessor :players
  attr_accessor :start
  attr_accessor :duration
  attr_accessor :rounds

  def initialize(teams, players, start, duration, rounds)
    @teams    = teams
    @players  = players
    @start    = start
    @duration = duration
    @rounds   = rounds
  end

  def text_round(round, time, court: nil)
    round.each.with_index do |(team_1, team_2), i|
      text_team team_1, time.strftime('%H:%M'), :court => court
      text_team team_2, time.strftime('%H:%M'), :court => court

      time += @duration
    end
  end

  def text_team(team, time, court: nil)
    # case insensitive
    players = @players.filter {|p| (p['Team'] || '').downcase == team.name.downcase }
    players.each do |player|
      Phone.sms :to   => player['Phone'],
                :body => "DCBP Thaw Tournament: You " +
                         "(team \"#{player['Team']}\")" +
                         " are playing at #{time} on " +
                         "court #{court}"
    end
  end
end

