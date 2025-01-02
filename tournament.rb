class Tournament
  Pairing = Struct.new :time, :team_1, :score_1, :team_2, :score_2, :court

  attr_accessor :teams
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

  def text_round(round)
    round.each {|pairing| text_match pairing }
  end

  def text_team(team, time, court)
    team.players.each do |player, phone|
      next unless phone =~ /\d{11}/

      Phone.sms :to   => phone,
                :body => "DCBP Thaw Tournament: You " +
                         "(team \"#{team.name}\")" +
                         " are playing at #{time} on " +
                         "court #{court}"
    end
  end

  def text_match(pairing)
    time = pairing.time.strftime '%H:%M'
    text_team pairing.team_1, time, pairing.court
    text_team pairing.team_2, time, pairing.court
  end
end

