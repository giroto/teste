class Game < ActiveRecord::Base
  has_many :levels
  belongs_to :intro_video, foreign_key: 'intro_video_id', class_name: 'Video'

  CUSTOM = self.find_by_name("Custom")
end
