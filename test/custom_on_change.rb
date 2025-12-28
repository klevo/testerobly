# frozen_string_literal: true

require_relative "test_helper"

class CustomOnChangeTest < Minitest::Test
  def test_custom_on_change_is_runnable
    assert_equal 2, 1 + 1
  end
end
