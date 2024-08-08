require 'glimmer-dsl-libui'

module GUI

  class Plotter
    include Glimmer

    COURT_WIDTH   = 450
    ROUND_SPACING = 25
    MARKER_SHIFT  = 0.95
    MATCH_HEIGHT  = 40
    MATCH_SPACING = 5
    MATCH_WIDTH   = 350

    attr_accessor :app
    attr_accessor :plot
    attr_accessor :margin
    attr_accessor :area
    attr_accessor :matches
    attr_accessor :info

    def initialize(app, margin)
      @app    = app
      @margin = margin
      @matches = []
    end

    def inspect
      "#<GUI::Plotter #{matches.size} matches>"
    end

    def plot_info_box
    end

    def scale_area(area, plot)
      @area  = [area[:area_width], area[:area_height]]
      @scale = [area[:area_width]  / plot[0],
                area[:area_height] / plot[1]]
    end

    def select_match_box(x, y)
      @info = @matches.find {|m| m[:box].contain?(x, y) }
    end

    def display_info_box
      return unless @info

      rectangle(@info[:x], @info[:y], 150, 100) {
        stroke 0xf003fc
        fill 0xeeeeee
      }
    end

    def display_courts
      @matches = app.rounds.keys.map.with_index do |court, i|
        display_court(court, i * COURT_WIDTH + 15, 0)
      end.flatten
    end

    def display_court(court, x, y)
      # Data
      display_rounds app.rounds[court], x, y + 20

      # Label
      text(x, y) { string "Court #{court}" }
    end

    def display_rounds(rnds, x, y)
      round_height = (MATCH_HEIGHT + MATCH_SPACING) * rnds[0].size

      # Build the markers
      # This one is purely cosmetic
      rnds.each.with_index do |round, i|
        display_round_marker(round, x, y, round_height, i)
      end

      # This one gives us the matches that we will check mouseclicks against
      rnds.map.with_index do |round, i|
        display_round(round, x, y, round_height, i)
      end.flatten
    end

    def display_round_marker(round, x, y, height, i)
      header_size = 15 # guess
      y          += (height + ROUND_SPACING) * i

      # Framing for the round

      rectangle(x + 5, y + header_size, 15, height + 5) {
        stroke 0xf003fc
        fill 0xeeeeee
      }

      #diameter = height
      #radius   = diameter / 2.0

      #circle(x + 5 + MARKER_SHIFT * diameter, y + header_size + radius, diameter) {
      #  stroke 0x0000ff
      #  fill 0xffffff
      #}

      rectangle(x + 15, y - height, height * 2, height * 3) {
        stroke 0xffffff
        fill 0xffffff
      }

    end

    def display_round(round, x, y, height, i)
      header_size = 15 # guess
      y          += (height + ROUND_SPACING) * i

      # Header
      round_num = round[0][:game].split(" ")[0].split(/[A-Za-z]/)[1]
      text(x, y) { string "Round #{round_num}" }

      # Individual matches
      round.map.with_index do |match, i|
        display_match(match,
                      x + header_size + 5,
                      y + header_size + 5 + (MATCH_SPACING + MATCH_HEIGHT) * i)
      end
    end

    def display_match(match, x, y)
      rect = rectangle(x, y, MATCH_WIDTH, MATCH_HEIGHT) {
        stroke 0xff0000
        fill 0xd6d6d6
      }

      #text(x + 5, y + 5) { string format_match(match) }
      text(x + 5, y + 5) do
        game_num = match[:game].split(" ")[0].split(/[A-Za-z]/)[2]
        time     = match[:time].strftime "%H:%M"
        txt = "Game:\t#{game_num}\n" +
              "Time:\t#{time}"
        string txt
      end

      txt = match[:team_1].name.center(30) + match[:team_2].name.center(30)

      text_height = 12  * (OS.mac? ? 0.75 : 1.35)
      text_width  = txt.size * (text_height * (OS.mac? ? 0.75 : 0.60)) * 0.75
      text_x = (MATCH_WIDTH - text_width) / 2.0
      text_y = (MATCH_HEIGHT - text_height) / 5.0

      text(x + text_x + 55, y + text_y) do
        string txt
      end

      txt = match[:score_1].to_s.ljust(20) + match[:score_2].to_s.rjust(20)

      text_height = 12  * (OS.mac? ? 0.75 : 1.35)
      text_width  = txt.size * (text_height * (OS.mac? ? 0.75 : 0.60)) * 0.76
      text_x = (MATCH_WIDTH - text_width) / 2.0
      text_y = text_height + 4 + (MATCH_HEIGHT - text_height) / 5.0

      text(x + text_x + 55, y + text_y) do
        string txt
      end

      {:match => match, :box => rect, :x => x, :y => y}
    end

    def format_match(match)
      game_num = match[:game].split(" ")[0].split(/[A-Za-z]/)[2]
      time     = match[:time].strftime "%H:%M"

      "Game:\t#{game_num}\t#{match[:team_1].name}\t|\t#{match[:team_2].name}\n" +
      "Time:\t#{time}\t#{match[:score_1]}\t|\t#{match[:score_2]}"
    end
  end
end

