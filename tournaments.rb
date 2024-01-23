require_relative 'team.rb'
require_relative 'swiss.rb'

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



PRNG = Random.new #50133028578934037664189005052456582016
puts "seed: #{PRNG.seed}"

num_teams  = (ARGV[0] || 24).to_i
num_rounds = (ARGV[1] || 6).to_i

#times = 200.times.map do |i|
  #puts i

  @teams = (1..num_teams).map {|t| Team.new t }
  @swiss = Swiss.new @teams
  
  (1..num_rounds).each do |round|
  
    pairs = @swiss.next_round
    pairs.each_slice(2).with_index do |(pair_a, pair_b), i|
      print "round #{round} game #{i + 1}: ".ljust(19)
      print pair_a.map(&:inspect).join(",\t").ljust(50)
  
      print "\t\t"
  
      print "round #{round} game #{i + 1}: ".ljust(19)
      print pair_b.map(&:inspect).join(",\t").ljust(50)

      puts
    end
    puts "************"

    # This is where we can instead gauge user input for team scoring
    pairs.each_slice(2).with_index do |(pair_a, pair_b), i|
      @swiss.play_match(round, pair_a, i, "a")
      @swiss.play_match(round, pair_b, i, "b")
    end
  end
  
  waits = @swiss.teams.map do |team|
    matches = [*team.wins, *team.losses, *team.draws]
    matches = matches.filter {|m| m.time[0] != 1 } # disregard first round
    matches = matches.map(&:time).sort_by {|m| m }
    matches.each_cons(2).map do |a, b|
      1.25 * (b[0] - a[0]) + 0.25 * (b[1] - a[1])
    end
  end

  min = waits.map(&:min).min
  max = waits.map(&:max).max

  top = 8

  top_n  = @swiss.teams.sort_by(&:record)[-top..-1]
  replay = top_n.map {|t| (top_n - [t]).count {|z| t.played?(z) } / (top - 1).to_f }.avg

  puts
  puts "top #{top}:"
  top_n.each {|t| p t }

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

  [min, max, replay]
#end

#min = times.map(&:first).min
#max = times.map {|t| t[1] }.max
#replay = times.map(&:last).avg

p [min, max, replay]

