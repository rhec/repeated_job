require "active_support"
require "rake"

module Repeated
  class Job

    attr_reader :interval, :priority, :task

    def initialize options={}
      @interval = (options[:interval] || ENV["REPEATED_JOB_INTERVAL"] || 5).to_i   # minutes
      @priority = (options[:priority] || ENV["REPEATED_JOB_PRIORITY"] || 0).to_i
      @task = (options[:task] || ENV["REPEATED_JOB_TASK"] || "cron")
    end

    def perform
      schedule_next
      Rake::Task[@task].execute
    end

    def schedule_next
      Delayed::Job.delete_all "handler like '%Repeated::Job%task: #{@task}\n%'"
      Delayed::Job.enqueue self, priority, interval.minutes.from_now.getutc
    end

  end
end
