require 'csv'
require_relative 'swiss.rb'
require_relative 'team.rb'

# the sun
# the magician
# the joker
# queen of cups
# 
# team 1    | score 1 | team 2   | score 2
# -------   | ------- | -------- | -------
# the sun   |     4   | the moon |    3   
# the joker |     4   | the moon |    3   
# 
# team 1    | score 1 | team 2   | score 2
# -------   | ------- | -------- | -------
# the sun   |     4   | the moon |    3   
# the joker |     4   | the moon |    3   
# 
# team 1    | score 1 | team 2   | score 2
# -------   | ------- | -------- | -------
# the sun   |     4   | the moon |    3   
# the joker |     4   | the moon |    3   

module ScoreTable
  extend self

  def parse(str)
    rows = CSV.parse str, :col_sep => '|'
    team_names, *rounds = split_by(rows) {|r| r.empty? }

    teams = team_names.map.with_index {|t, i| [t[0].strip, Team.new(i, t[0].strip)] }.to_h

    rounds = rounds.each {|r| parse_round teams, r }

    teams.values
  end

  # Given a list of arrays (as output from CSV parsing), split the list
  # into sublists
  #
  # so take the sample input and break it up into team names and subsequent
  # rounds
  def split_by(rows, &sep)
    rows.chunk(&sep).filter {|b, _| not b }.map {|_, v| v }
  end

  def parse_round(teams, r)
    headers, separator, *matches = *r
    matches.each {|m| parse_match teams, m }
  end

  def parse_match(teams, m)
    # team 1, score 1, team 2, score 2
    time, t_1, s_1, t_2, s_2 = *m
    time = time.split(//).filter {|x| x =~ /\d/ }.map(&:to_i)
    t_1 = teams[t_1.strip]
    t_2 = teams[t_2.strip]

    for_t_1 = Swiss::Match.new t_2, time, s_1, s_2
    for_t_2 = Swiss::Match.new t_1, time, s_2, s_1

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

