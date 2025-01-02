class Tournament
  Pairing = Struct.new :time, :team_1, :score_1, :team_2, :score_2

  attr_accessor :teams # {team => [player, ...]}
  attr_accessor :start
  attr_accessor :duration
  attr_accessor :courts
  attr_accessor :swiss
  attr_accessor :rounds
  attr_accessor :id

  def initialize(teams, start, duration, courts, swiss, rounds)
    @teams    = teams
    @start    = start
    @duration = duration
    @courts   = courts
    @swiss    = swiss
    @rounds   = rounds
    @id       = object_id
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

