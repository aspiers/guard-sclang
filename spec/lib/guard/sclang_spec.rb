require "open3"

require "guard/compat/test/helper"
require "guard/sclang"

RSpec.describe Guard::Sclang do
  def expect_color_calls(paths, timeout=3)
    expect(Guard::Compat::UI).to receive(:color).with(/=============+/, :blue)
    expect(Guard::Compat::UI).to receive(:color).with(
      %r{Running: timeout \d+ sclang .* #{paths}},
      :blue
    )

    status = double(Process::Status)
    expect(status).to receive(:value).and_return(7)
    expect(::Open3).to receive(:popen2e).with(
      "timeout", timeout.to_s, "sclang", %r{.*/unit-test-cli\.scd$}, paths
    ).and_yield("stdin", ["blahout"], status)

    allow(Guard::Compat::UI).to receive(:color)
  end

  describe "#start" do
    it "works" do
      subject.start
    end
  end

  describe "#stop" do
    it "works" do
      subject.stop
    end
  end

  describe "#run_all" do
    before do
      allow(Dir).to receive(:glob).and_return(%w(foo bar))
      allow(Guard::Compat).to receive(:matching_files).with(
        subject, %w(foo bar)
      ).and_return(%w(bar))
    end

    it "delegates to run_on_modifications" do
      expect_color_calls("bar")
      expect(Guard::Compat::UI).to receive(:notify).with(
        "0 passes, 1 failures",
        { title: "bar", image: :failed }
      )
      #expect($stdout).to receive(:puts).with("0 passes, 1 failures")
      subject.run_all
    end
  end

  describe "#run_on_modifications" do
    it "outputs to the screen" do
      expect_color_calls("baz")
      subject.run_on_modifications(%w(baz))
    end
  end
end
