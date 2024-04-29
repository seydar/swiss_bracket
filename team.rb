class Team
  attr_accessor :id
  attr_accessor :name
  attr_accessor :wins
  attr_accessor :losses
  attr_accessor :draws

  def initialize(id, name=nil)
    @id     = id
    @name   = name || id
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

  def goals
    [*wins, *losses, *draws].sum {|m| m.own_score }
  end

  def goal_differential
    [*wins, *losses, *draws].sum {|m| m.own_score - m.their_score }
  end

  def played?(other)
    matches.map(&:opponent).include?(other) ||
      other.matches.map(&:opponent).include?(self)
  end

  def <=>(other)
    #record <=> other.record
    [(wins.size * 3 + draws.size), goals, goal_differential] <=>
      [(other.wins.size * 3 + other.draws.size), other.goals, other.goal_differential]
    #(wins.size * 3 + draws.size) <=> (other.wins.size * 3 + other.draws.size)
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

