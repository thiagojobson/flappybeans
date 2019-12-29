require 'gosu'
require_relative 'config'
require_relative 'gameobjs'

module Flappy
  class Game < Gosu::Window
    def initialize(width, height, caption)
      super width, height
      self.caption = caption
      @game_over = false

      @background_image = Flappy::IMAGES[:background]
      # Game objects
      @player = create_player
      @obstacles = []
      @stars = []
      @floor = []
    end

    def game_objects
      [@player] + @obstacles + @floor + @stars
    end

    def update
      game_objects.each(&:update)

      # Create random obstacles
      if @obstacles.size < 10
        @obstacles += create_obstacle
      end
      # Create random stars
      if rand(100) < 4 and @stars.size < 5
        @stars << create_star
      end
      # Create floor (only need 2 to fill the screen horizontally)
      if @floor.count < 2
        @floor << create_floor
      end

      # Check collision beetween player and obstacles and floor
      (@obstacles + @floor).each do |obj|
        game_over if obj.collide?(@player)
      end

      # Clean up old gameobjs
      cleanup_gameobjects
    end

    def draw
      @background_image.draw(0, 0, Flappy::Z[:background])
      game_objects.each(&:draw)
      debug_bodies if Flappy::DEBUG
    end

    def button_down(id)
      if id == Gosu::KB_UP
        @player.flap unless @game_over
      else
        super
      end
    end

    def debug_bodies
      game_objects.each do |obj|
        x, y, width, height = obj.rect
        z = Flappy::Z[:debug]
        Gosu::draw_rect(x, y, width, height, Gosu::Color::GREEN, z)
      end
    end

    private

      def game_over
        @game_over = true
        @player.allow_gravity = false
        @player.vel_x = @player.vel_y = 0
      end

      def create_player
        x = self.width/2
        y = self.height/2
        z = Flappy::Z[:player] 
        frames = Flappy::IMAGES[:player]
        Flappy::FlappyBean.new(x, y, z, frames)
      end

      def create_obstacle
        offset_x =
          if @obstacles.empty?
            # Create first obstacle at the right border
            self.width
          else
            # Take care not to create and obstacle on top of another
            @obstacles.last.x
          end

        # Place the obstacle at a random position
        x = offset_x + rand(200..250)
        y = rand(-225..0)
        z = Flappy::Z[:obstacle]
        # Spacing beetween top and bottom obstacles
        v_spacing = Flappy::OBSTACLE_VSPACING

        # Create random looking obstacles
        top = Flappy::IMAGES[:obstacle_top].sample
        bottom = Flappy::IMAGES[:obstacle_bottom].sample
        return [
          Flappy::Obstacle.new(x, y, z, top),
          Flappy::Obstacle.new(x, y + top.height + v_spacing, z, bottom)
        ]
      end

      def create_floor
        width = Flappy::IMAGES[:floor].width
        x =
          if @floor.empty?
            0
          else
            @floor.last.x + width - 1
          end
        y = self.height - 60
        z = Flappy::Z[:floor]
        Flappy::Floor.new(x, y, z, Flappy::IMAGES[:floor])
      end

      def create_star
        x = rand(self.width..self.height*2)
        y = rand(0..250)
        z = Flappy::Z[:star]
        vel_x = -rand(5..10)/10.0
        Flappy::Star.new(x, y, z, Flappy::IMAGES[:star], vel_x)
      end

      def cleanup_gameobjects
        @obstacles.reject!(&:destroy?)
        @floor.reject!(&:destroy?)
        @stars.reject!(&:destroy?)
      end
  end
end
