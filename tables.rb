#!/usr/bin/env ruby

require 'csv'
require 'terminal-table'
require 'time'
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

inp   = STDIN.read
teams, rounds, (start, duration) = ScoreTable.parse inp
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
next_round_start = rounds.last ? rounds.last.last[1] : start

rounds.each do |round|
  round.each {|r| r[1] = r[1].strftime '%H:%M' }

  puts
  puts Terminal::Table.new(:headings => headings,
                           :rows     => round,
                           :style    => {:border_top    => false,
                                         :border_bottom => false,
                                         :alignment     => :center})
end

court_a, court_b = swiss.next_round.partition.with_index {|_, i| i.even? }

time = next_round_start
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

time = next_round_start 
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

