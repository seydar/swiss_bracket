#!/usr/bin/env ruby

require_relative 'team.rb'
require_relative 'swiss.rb'
require 'optimist'

class Array
  def extract(&blk)
    ix = find_index(&blk)
    return nil unless ix
    val = self[ix]
    delete_at ix
    val
  end

  def avg
    sum.to_f / size
  end
end



opts = Optimist::options do
  version "1.0.0 (c) 2024 Ari Brown"
  banner <<-EOS
Simulate a tournament where teams are determined via Swiss rounds (each team plays the team with the closest record, no rematches).

Usage:
  tournaments.rb [options]
where [options] are:
EOS

  opt :teams, "Number of teams", :default => 24
  opt :rounds, "Number of rounds", :default => 6
  opt :iterations, "Number of iterations to simulate", :default => 1
  opt :duration, "Duration of a match (including transfer time)", :default => 0.25

  opt :elimination, "Print stats of an elimination round of the top ELIMINATION teams", :type => :int

  opt :quiet, "Suppress output", :default => false
end


PRNG = Random.new #50133028578934037664189005052456582016
puts "seed: #{PRNG.seed}" unless opts[:quiet]

times = opts[:iterations].times.map do |i|

  @teams = (1..opts[:teams]).map {|t| Team.new t }
  @swiss = Swiss.new @teams
  
  (1..opts[:rounds]).each do |round|
  
    pairs = @swiss.next_round

    unless opts[:quiet]
      pairs.each_slice(2).with_index do |(pair_a, pair_b), i|
        print "round #{round} game #{i + 1}: ".ljust(19)
        print pair_a.map(&:inspect).join(",\t").ljust(50)
  
        print "\t\t"
  
        print "round #{round} game #{i + 1}: ".ljust(19)
        print pair_b.map(&:inspect).join(",\t").ljust(50)

        puts
      end
      puts "************"
    end

    # This is where we can instead gauge user input for team scoring
    pairs.each_slice(2).with_index do |(pair_a, pair_b), i|
      @swiss.play_match(round, pair_a, i, "a")
      @swiss.play_match(round, pair_b, i, "b")
    end
  end
  
  match_time = opts[:duration]
  round_time = opts[:duration] * @teams.size / 4

  waits = @swiss.teams.map do |team|
    matches = [*team.wins, *team.losses, *team.draws]
    matches = matches.filter {|m| m.time[0] != 1 } # disregard first round
    matches = matches.map(&:time).sort_by {|m| m }
    matches.each_cons(2).map do |a, b|
      (round_time - match_time) * (b[0] - a[0]) + match_time * (b[1] - a[1])
    end
  end

  min = waits.map(&:min).min
  max = waits.map(&:max).max

  top = opts[:elimination]
  ret = [min, max]

  if top
    top_n  = @swiss.teams.sort_by(&:record)[-top..-1]
    replay = top_n.map {|t| (top_n - [t]).count {|z| t.played?(z) } / (top - 1).to_f }.avg
    ret << replay

    puts
    puts "top #{top}:"
    top_n.reverse.each.with_index do |t, i|
      puts "\t#{i + 1}. Team #{t.inspect}" 
    end

    puts
    top_n.each do |t|
      rematches = (top_n - [t]).filter {|z| t.played?(z) }.map {|z| z.id }
      if rematches.empty?
        puts "#{t.id} hasn't played any of the top #{top}"
      else
        puts "#{t.id} has played #{rematches.join ', '}"
      end
    end

    puts
    
    puts "min interval: #{min} hrs"
    puts "max interval: #{max} hrs"
    puts "avg likelihood top-#{top} rematch: #{"%.2f" % (replay * 100)}%"
    puts
  end

  ret
end

min = times.map(&:first).min
max = times.map {|t| t[1] }.max

puts "Averages over #{opts[:iterations]} iteration#{"s" if opts[:iterations] != 1}:"
puts "\tminimum time between matches: #{min}"
puts "\tmaximum time between matches: #{max}"

if opts[:elimination]
  replay = times.map(&:last).avg if opts[:elimination]
  puts "\taverage rematch probability in elimination bracket: #{replay}"
end

