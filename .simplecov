# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch
  add_group("Core") {|sf| !sf.project_filename.start_with?("/lib/iparty/cli") }
  add_group("CLI") {|sf| sf.project_filename.start_with?("/lib/iparty/cli") }
  add_filter "/spec/"
end
