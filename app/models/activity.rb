class Activity < ActiveRecord::Base
  MINIMUM_FINISHED_RESULT = 10
  MINIMUM_PASS_RESULT = 20
  FREE_PLAY_RESULT = 30
  BEST_PASS_RESULT = 100

  belongs_to :level
  belongs_to :user
  belongs_to :level_source

  def best?
    (test_result == BEST_PASS_RESULT)
  end

  def finished?
    (test_result >= MINIMUM_FINISHED_RESULT)
  end

  def passing?
    (test_result >= MINIMUM_PASS_RESULT)
  end
end
