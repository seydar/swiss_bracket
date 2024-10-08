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
  PLOT     = [700, 500]
  TABLE    = 200
  WIDTH    = TABLE + PLOT[0] + 4 * MARGIN
  HEIGHT   = CONTROLS + PLOT[1] + 4 * MARGIN

  attr_accessor :info
  attr_accessor :swiss
  attr_accessor :rounds
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

    # Convert the rounds from text to objects
    rounds = rounds.map do |round|
      round.map do |(game, time, team_1, score_1, team_2, score_2)|
        {:game    => game,
         :time    => time,
         :team_1  => teams.find {|t| t.name == team_1 },
         :score_1 => score_1,
         :team_2  => teams.find {|t| t.name == team_2 },
         :score_2 => score_2}
      end
    end

    @swiss  = Swiss.new teams
    @rounds = rounds.group_by do |round|
      match = round[0]
      game  = match[:game]
      court = game.split(" court ")[1]
    end
    @info   = {:start  => start, :duration => duration}

    calc_scroll_size

    # plot
    @plotter = Plotter.new self, MARGIN
  end

  def calc_scroll_size
    courts            = @rounds.values.size
    rounds_per_court  = @rounds.values[0].size - 1
    matches_per_round = @rounds.values[0][0].size
    @scroll = {:width  => courts * Plotter::COURT_WIDTH,
               :height => rounds_per_court *
                          (Plotter::ROUND_SPACING +
                            (Plotter::MATCH_HEIGHT + Plotter::MATCH_SPACING) *
                            matches_per_round.size)}
  end

  def refresh
    calc_scroll_size
  end

  def launch
    window("Helvetican Bracketing", WIDTH, HEIGHT, true) {
      margined true

      tab {
        tab_item("Rounds") {
          grid {

            plot_area x: 0, y: 0
          }
        }

        tab_item("Rankings") {
          
        }
      }

    }.show
  end

  def plot_area(x: nil, y: nil, xs: 3, ys: 2)
    @plot = scrolling_area(@scroll[:width], @scroll[:height]) {
      left x; xspan xs
      top  y; yspan ys

      on_draw {|area|
        @plotter.scale_area area, PLOT

        # Background
        rectangle(0, 0, area[:area_width], area[:area_height]) {
          fill 0xaaaaaa
        }

        # Show Rounds
        @plotter.display_courts

        # Display Info
        @plotter.display_info_box
      }

      on_mouse_up do |area_event|
        @plotter.select_match_box(area_event[:x], area_event[:y])
        pp area_event
        pp @plotter.info

        pp @plotter.matches[0]

        @plot.queue_redraw_all
      end
    }
  end
end

SwissApp.new.launch

