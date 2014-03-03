class Level < ActiveRecord::Base
  belongs_to :game
  has_and_belongs_to_many :concepts
  belongs_to :solution_level_source, :class_name => "LevelSource"
  belongs_to :user
  #accepts_nested_attributes_for :concepts

  BUILDER = self.find_by_name('builder')

  def videos
    ([game.intro_video] + concepts.map(&:video)).reject(&:nil?)
  end
end
