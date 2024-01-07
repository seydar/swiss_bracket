require 'graph_matching'

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

class Team
  attr_accessor :id
  attr_accessor :name
  attr_accessor :wins
  attr_accessor :losses
  attr_accessor :draws

  def initialize(name)
    @id     = name
    @name   = name
    @wins   = []
    @losses = []
    @draws  = []
  end

  def record
    [wins.size, losses.size, draws.size]
  end

  def matches
    [*wins, *losses, *draws].sort_by(&:time)
  end

  def rounds
    record.sum
  end

  def played?(other)
    matches.map(&:opponent).include?(other) ||
      other.matches.map(&:opponent).include?(self)
  end

  def <=>(other)
    record <=> other.record
  end

  def differential(other)
    s = record
    o = other.record

    # if a team somehow has more wins but everything else the same,
    # that shouldn't be viewed the same as another team having a loss
    # [3, 0, 0] should be farther from [0, 3, 0] than [0, 0, 3]
    [(o[0] - s[0]).abs * 0.25,
     (o[1] - s[1]).abs * 1.0,
     (o[2] - s[2]).abs * 0.5].sum
  end

  def inspect
    "#{@id}: (#{@name})"
  end
end

class Swiss
  attr_accessor :teams

  Match = Struct.new :opponent, :time

  def initialize(teams)
    @teams = teams
  end

  def rounds_played
    @teams[0].rounds
  end

  # This is a minimum-weight matching problem.
  #
  # Given a graph (nodes are teams, edges are the score differences between
  # the unplayed teams), find the set of edges that have the lowest total weight.
  def next_round
    ranked = teams.sort {|a, b| a.record <=> b.record  }.reverse

    # possibilities
    # A list of unplayed teams
    posses = teams.map do |team|
      [team,
       teams.filter {|t| t != team && ! t.played?(team) }]
    end.to_h

    pairs = best_pairing posses

    sort_by_min_rest pairs
  end

  # Sort by the minimum amount of rest that a single team will have
  # Not concerned with averages
  def sort_by_min_rest(pairs)
    pairs.sort_by do |left, right|
      unless left.matches.empty? || right.matches.empty?
        t1 = left.matches.last.time
        t2 = right.matches.last.time
        t1.zip(t2).map(&:max)
      else
        0
      end
    end
  end
  
  def best_pairing(possibilities)
    ids = possibilities.keys.map {|t| [t.id, t] }.to_h

    # In order for this to work as a MINIMUM weight problem, we have to
    # invert all the weights
    edges = possibilities.map do |team, ts|
      ts.map {|t| [team.id, t.id, -1 * team.differential(t)] }
    end.flatten 1
  
    g = GraphMatching::Graph::WeightedGraph[
      *edges
    ]
  
    # The magic
    m = g.maximum_weighted_matching true

    # Coverting from IDs back to our objects
    m.edges.map {|(l, r)| [ids[l], ids[r]] }
  end
end

PRNG = Random.new #50133028578934037664189005052456582016
puts "seed: #{PRNG.seed}"

def play_match(round, pair, game, court)
  a, b = *pair

  str = pair.map(&:inspect).join(",\t").ljust(50)

  val = PRNG.rand
  val += (a.id - b.id) / 100.0 # so some teams are better than others

  if val < 0.4
    a.wins   << Swiss::Match.new(b, [round, game])
    b.losses << Swiss::Match.new(a, [round, game])

    #a.name = "winner of R#{round} G#{game} C#{court}"
    #b.name = "loser of R#{round} G#{game} C#{court}"
  elsif val >= 0.6
    a.losses << Swiss::Match.new(b, [round, game])
    b.wins   << Swiss::Match.new(a, [round, game])

    #a.name = "loser of R#{round} G#{game} C#{court}"
    #b.name = "winner of R#{round} G#{game} C#{court}"
  else # 0.4 <= val < 0.6, draw
    a.draws << Swiss::Match.new(b, [round, game])
    b.draws << Swiss::Match.new(a, [round, game])

    #a.name = "left of R#{round} G#{game} C#{court}"
    #b.name = "right of R#{round} G#{game} C#{court}"
  end

  a.name = a.record
  b.name = b.record

  str
end

num_teams  = (ARGV[0] || 12).to_i
num_rounds = (ARGV[1] || 5).to_i

#times = 5.times.map do |i|
#  puts i

  @teams = (1..num_teams).map {|t| Team.new t }
  @swiss = Swiss.new @teams
  
  (1..num_rounds).each do |round|
  
    @swiss.next_round.each_slice(2).with_index do |(pair_a, pair_b), i|
      print "round #{round} game #{i + 1}: ".ljust(19)
      print play_match(round, pair_a, i, "a")
  
      print "\t\t"
  
      print "round #{round} game #{i + 1}: ".ljust(19)
      print play_match(round, pair_b, i, "b")
  
      puts
    end
    puts "************"
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
  
  puts "min interval: #{min} hrs"
  puts "max interval: #{max} hrs"
  [min, max]
#end

#min = times.map(&:first).min
#max = times.map(&:last).max
#
#p [min, max]
