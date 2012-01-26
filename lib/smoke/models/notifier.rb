module Smoke
  module Server
    # Holds notification topics and events.
    # If I was going to mirror amazon, I'd need a message subsystem
    # to publish topics to (ie rabbitmq).  I could use this to publish
    # email notifications on specific events, but this will not be completed
    # unless basic functionality is full completed.
    #
    # Topic would look like:   arn:smoke:mail:<hostname>:id:<topic>
    # Event will look like:    s3:get_object | s3:put_object ... ect.
    class Notifier < ActiveRecord::Base
      belongs_to :bucket
    end
  end
end