require File.expand_path("../spec_helper", __FILE__)

describe "Repeated::Job" do

  describe "configuration" do

    it "has a configurable interval" do
      ENV["REPEATED_JOB_INTERVAL"] = "10"
      Repeated::Job.new.interval.should == 10
    end
    
    it "allows overriding the interval when initialized" do
      ENV["REPEATED_JOB_INTERVAL"] = "10"
      Repeated::Job.new(:interval => 15).interval.should == 15
    end

    it "has a default interval of 5 minutes" do
      ENV.delete("REPEATED_JOB_INTERVAL")
      Repeated::Job.new.interval.should == 5
    end

    it "has a configurable priority" do
      ENV["REPEATED_JOB_PRIORITY"] = "1"
      Repeated::Job.new.priority.should == 1
    end

    it "allows overriding the priority when initialized" do
      ENV["REPEATED_JOB_PRIORITY"] = "1"
      Repeated::Job.new(:priority => 2).priority.should == 2
    end

    it "has a default priority of 0" do
      ENV.delete("REPEATED_JOB_PRIORITY")
      Repeated::Job.new.priority.should == 0
    end
    
    it "has a configurable rake task" do
      ENV["REPEATED_JOB_TASK"] = "foo"
      Repeated::Job.new.task.should == "foo"
    end

    it "allows overriding the rake task when initialized" do
      ENV["REPEATED_JOB_TASK"] = "foo"
      Repeated::Job.new(:task => "baz").task.should == "baz"
    end
    
    it "has a default task of 'cron'" do
      ENV.delete("REPEATED_JOB_TASK")
      Repeated::Job.new.task.should == "cron"
    end
  end

  describe "scheduling" do

    before(:each) do
      @repeated = Repeated::Job.new
    end

    it "knows how to schedule itself" do
      ENV["REPEATED_JOB_INTERVAL"] = "5"

      Delayed::Job.should_receive(:delete_all).with(/Repeated::Job%task: cron\n%/)

      Delayed::Job.should_receive(:enqueue) do |object, priority, scheduled|
        object.should   == @repeated
        priority.should == @repeated.priority
        (scheduled - Time.now).should be_close(300, 5)
      end

      @repeated.schedule_next
    end

    it "should schedule itself again when executing" do
      @was_run = false
      task(:cron) { @was_run = true }

      @repeated.should_receive(:schedule_next)
      @repeated.perform

      @was_run.should be_true
    end

  end
  
  describe "performing" do
    it "should run the specified task" do
      @foo_was_run = false
      @cron_was_run = false
      task(:foo) {@foo_was_run = true}
      task(:cron) {@cron_was_run = true}
      repeated = Repeated::Job.new(:task => "foo")
      repeated.stub!(:schedule_next)
      repeated.perform
      @foo_was_run.should be_true
      @cron_was_run.should be_false
    end
  end

end
