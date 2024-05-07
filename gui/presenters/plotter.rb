require 'glimmer-dsl-libui'

module GUI

  class Plotter
    include Glimmer

    attr_accessor :plot
    attr_accessor :margin
    attr_accessor :area

    def initialize(app, margin)
      @app    = app
      @margin = margin
    end

    def plot_info_box
    end

    def scale_area(area, plot)
      @area  = [area[:area_width], area[:area_height]]
      @scale = [area[:area_width]  / plot[0],
                area[:area_height] / plot[1]]
    end

    def select_info_box(x, y)
      #@info   = @circles.find {|c| c[:circle].contain?(x, y) }
      #@info ||= @edges.find {|e| e[:line].contain?(x,
      #                                             y,
      #                                             outline: true, 
      #                                             distance_tolerance: 25) }
    end

    def display_rounds
      app.swiss.rounds_played.each do |round|
        display_round round
      end
    end

    def display_round(round)
      rectangle(x, y, width, height) {
        stroke 0xff0000
        fill 0xd6d6d6
      }
      text(x + 5, y + 5) { string round }
    end
  end
end

