module Snowpacker
  class << self
    def activate
      return if @activated
      @activated = true

      Project::List.each &:scan_snowpacked_packages
      Project::List.each &:define_tasks
    end
  end
end
