require 'graph_matching'

class Swiss
  attr_accessor :teams

  Match = Struct.new :opponent, :time, :own_score, :their_score

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
        [t1, t2].max
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

  def play_match(round, pair, game, court)
    a, b = *pair
  
    # lower seeds are better
    val = PRNG.rand
    val += (a.id - b.id) / 100.0 # so some teams are better than others
  
    if val < 0.5
      a.wins   << Match.new(b, [round, game])
      b.losses << Match.new(a, [round, game])
  
      #a.name = "winner of R#{round} G#{game} C#{court}"
      #b.name = "loser of R#{round} G#{game} C#{court}"
    elsif val >= 0.55
      a.losses << Match.new(b, [round, game])
      b.wins   << Match.new(a, [round, game])
  
      #a.name = "loser of R#{round} G#{game} C#{court}"
      #b.name = "winner of R#{round} G#{game} C#{court}"
    else # 0.4 <= val < 0.6, draw
      a.draws << Match.new(b, [round, game])
      b.draws << Match.new(a, [round, game])
  
      #a.name = "left of R#{round} G#{game} C#{court}"
      #b.name = "right of R#{round} G#{game} C#{court}"
    end
  
    a.name = a.record
    b.name = b.record
  end
end

