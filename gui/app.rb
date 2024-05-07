#!/usr/bin/env ruby --yjit -W0

require_relative "../swiss.rb"
require_relative "../team.rb"
require_relative "../loaders.rb"
require 'glimmer-dsl-libui'
Dir['./gui/presenters/*.rb'].each {|f| require f }

class SwissApp
  include Glimmer
  include GUI

  MARGIN   = 10
  CONTROLS = 310
  PLOT     = [800, 500]
  TABLE    = 200
  WIDTH    = TABLE + PLOT[0] + 4 * MARGIN
  HEIGHT   = CONTROLS + PLOT[1] + 4 * MARGIN

  attr_accessor :desc
  attr_accessor :swiss
  attr_accessor :plotter

  def initialize

    @files = {:teams  => 'players/saturday.csv',
              :tables => 'days/saturday.csv'}

    # basic info
    players = CSV.parse File.read(@files[:teams]), :headers => true,
                                                 #:col_sep => '|',
                                                 :header_converters => lambda {|f| f.strip },
                                                 :converters => lambda {|f| f && f.strip }
    teams, rounds, (start, duration) = ScoreTable.parse File.read(@files[:tables])
    @swiss = Swiss.new teams

    # plot
    @plotter = Plotter.new self, MARGIN
  end

  def launch
    window("Helvetican Bracketing", WIDTH, HEIGHT, true) {
      margined true

      grid {

        
      }

    }.show
  end

  def plot_area(x: nil, y: nil, xs: 3, ys: 2)
    @plot = area {
      left x; xspan xs
      top  y; yspan ys

      on_draw {|area|
        @plotter.scale_area area, PLOT

        # Background
        rectangle(0, 0, area[:area_width], area[:area_height]) {
          fill 0xffffff
        }

        # Show Rounds
        @plotter.display_rounds
      }

      on_mouse_up do |area_event|
        @plotter.select_info_box(area_event[:x], area_event[:y])
        @plot.queue_redraw_all
      end
    }
  end
end

SwissApp.new.launch

