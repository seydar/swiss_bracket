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

  def next_round
    ranked = teams.sort {|a, b| a.record <=> b.record  }.reverse
    p ranked.map {|t| [t.id, t.record] }

    pairs      = []   # potential match pairings
    hunting    = nil  # if we're stuck in a weird loop because of a pairing mismatch, this the one we're looking for a match for
    interleave = 1    # how much are we going to backtrack when finding a pair for `hunting`?
    until ranked.empty?
      first  = ranked.shift
      second = ranked.extract {|t| not first.played? t }

      if second
        pairs << [first, second]

        # we did it! we found a suitable match!
        # reset everything
        if first == hunting
          hunting = nil
          interleave = 1
        end

      # backtrack by an increasing number of matches
      else
        hunting = first
        
        # swap every other element
        # [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        # [2, 1, 4, 3, 6, 5, 8, 7, 10, 9]
        puts "finding a match for #{first.id}, #{first.record}"
        puts "#{first.id} has played #{first.matches.map {|m| m.opponent.id }.inspect}"
        p ranked.map {|t| [t.id, t.record] }
        teams = [*interleave.times.map { pairs.pop }.reverse.flatten, first]
        puts "working with: #{teams.map {|t| [t.id, t.record] }.inspect}"
        reorder = teams.reverse.each_slice(2).map {|a, b, c| b ? [b, a] : [a] }.flatten.reverse
        ranked  = reorder + ranked
        p ranked
        p ranked.map {|t| [t.id, t.record] }
        interleave += 1

        STDIN.gets
      end
    end

    pairs
  end
end

PRNG = Random.new 50133028578934037664189005052456582016
p PRNG.seed

def play_match(round, pair, game, court)
  a, b = *pair

  str = pair.map(&:inspect).join(",\t").ljust(50)

  val = PRNG.rand
  val += (a.id - b.id) / 100.0 # so some teams are better than others

  if val < 0.4
    a.wins   << Swiss::Match.new(b, [round, game])
    b.losses << Swiss::Match.new(a, [round, game])

    a.name = "winner of R#{round} G#{game} C#{court}"
    b.name = "loser of R#{round} G#{game} C#{court}"
  elsif val >= 0.6
    a.losses << Swiss::Match.new(b, [round, game])
    b.wins   << Swiss::Match.new(a, [round, game])

    a.name = "loser of R#{round} G#{game} C#{court}"
    b.name = "winner of R#{round} G#{game} C#{court}"
  else # 0.4 <= val < 0.6, draw
    a.draws << Swiss::Match.new(b, [round, game])
    b.draws << Swiss::Match.new(a, [round, game])

    a.name = "left of R#{round} G#{game} C#{court}"
    b.name = "right of R#{round} G#{game} C#{court}"
  end

  str
end

num_teams  = (ARGV[0] || 12).to_i
num_rounds = (ARGV[1] || 5).to_i

#times = 30.times.map do |i|
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
    matches = [*team.wins, *team.losses, *team.draws].map(&:time).sort_by {|m| m }
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
#
#min = times.map(&:first).min
#max = times.map(&:last).max
#
#p [min, max]
