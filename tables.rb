#!/usr/bin/env ruby

require 'optimist'
require 'csv'
require 'terminal-table'
require 'time'
require_relative 'swiss.rb'
require_relative 'team.rb'
require_relative 'phone.rb'

opts = Optimist::options do
  version "1.0.0 (c) 2024 Ari Brown"
  banner <<-EOS
Run a tournament where teams are determined via Swiss rounds (each team plays
the team with the closest record, no rematches).

Text the teams when the new rounds are calculated.

Output the next round, and take that as input.

Usage:
  #{__FILE__} [options]
where [options] are:
EOS

  opt :teams, "CSV of teams and their players and their phone numbers", :type => :string
  opt :tables, "CSV tables of the rounds", :type => :string

  opt :quiet, "Suppress output", :default => false
end

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
    rows = CSV.parse str, :col_sep => '|'
    stats, team_names, *rounds = split_by(rows) {|r| r.empty? }

    start, duration = *parse_stats(stats)

    teams = team_names.map.with_index {|t, i| [t[0].strip, Team.new(i, t[0].strip)] }.to_h

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
    [Time.parse(start.strip), duration.strip.to_i * 60]
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
    players = @players.filter {|p| p['Team'].downcase == team.name.downcase }
    players.each do |player|
      Phone.sms :to   => player['Phone'],
                :body => "DCBP Thaw Tournament: You (#{player['Name']} of team" +
                         " #{player['Team']}) are playing at #{time} on " +
                         "court #{court}"
    end
  end
end

players = CSV.parse File.read(opts[:teams]), :headers => true,
                                             :col_sep => '|',
                                             :header_converters => lambda {|f| f.strip },
                                             :converters => lambda {|f| f && f.strip }
teams, rounds, (start, duration) = ScoreTable.parse File.read(opts[:tables])

tourney = Tournament.new teams, players, start, duration, rounds

round = rounds.size / 2 + 1
swiss = Swiss.new teams
headings = ['game', 'time', 'team 1', 'score 1', 'team 2', 'score 2']

########################
# Reprint everything to so that the output can be the input
# I guess that makes it a monoid?

puts "start    | #{start.strftime '%H:%M'}"
puts "duration | #{duration / 60}"

puts

teams.each do |team|
  puts team.name
end

# used further down, before we change the value here
next_round_end = rounds.last ? rounds.last.last[1] : start - duration

rounds.each do |round|
  # We overwrite the Time object to be a string, which is why we
  # pull the time object above
  round.each {|r| r[1] = r[1].strftime '%H:%M' }

  puts
  puts Terminal::Table.new(:headings => headings,
                           :rows     => round,
                           :style    => {:border_top    => false,
                                         :border_bottom => false,
                                         :alignment     => :center})
end

court_a, court_b = swiss.next_round.partition.with_index {|_, i| i.even? }

next_round_start = next_round_end + duration
time = next_round_end

tourney.text_round court_a, next_round_start, :court => "A"
tourney.text_round court_b, next_round_start, :court => "B"

rows = court_a.map.with_index do |(team_1, team_2), i|
  time += duration

  ["r#{round}g#{i + 1}cA",
   time.strftime('%H:%M'),
   team_1.name,
   "",
   team_2.name,
   ""]
end

puts
puts Terminal::Table.new(:headings => headings,
                         :rows     => rows,
                         :style    => {:border_top    => false,
                                       :border_bottom => false})

time = next_round_end
rows = court_b.map.with_index do |(team_1, team_2), i|
  time += duration

  ["r#{round}g#{i + 1}cB",
   time.strftime('%H:%M'),
   team_1.name,
   "",
   team_2.name,
   ""]
end

puts
puts Terminal::Table.new(:headings => headings,
                         :rows     => rows,
                         :style    => {:border_top    => false,
                                       :border_bottom => false})
puts

