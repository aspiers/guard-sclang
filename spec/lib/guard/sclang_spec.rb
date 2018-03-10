require "open3"

require "guard/compat/test/helper"
require "guard/sclang"

RSpec.describe Guard::Sclang do
  def dedent(text)
    text.gsub(/^\s+/, '')
  end

  def expect_colored_text(text, color)
    expect(Guard::Compat::UI).to receive(:color).with(text, color)
  end

  def expect_output(paths, test_output, passes, fails, timeout: 3, exitcode: nil)
    expect_colored_text(/=============+/, :blue)
    expect_colored_text(%r{Running: timeout \d+ sclang .* #{paths}}, :blue)

    fake_summary = "Finished running test(s): #{passes} passes, #{fails} failures\n"
    # Don't assume the summary is the last line of the output
    fake_footer = "cleaning up OSC\n"
    fake_output = StringIO.new(test_output + "\n" + fake_summary + fake_footer)
    fake_output.rewind
    expect(PTY).to receive(:spawn).with(
      "timeout", timeout.to_s, "sclang", %r{.*/unit-test-cli\.scd$}, paths
    ) { |command, *args, &block|
      `exit #{exitcode || fails}`
      block.call(fake_output, "fake stdin", $?.pid)
    }
    expect_colored_text(fake_summary, fails == 0 ? :green : :red)
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
      expect_output("bar", dedent(<<-EOF), 5, 1)
        PASS: test passed
        FAIL: test failed
        EOF
      expect(Guard::Compat::UI).to receive(:notify).with(
        "5 passes, 1 failures",
        { title: "bar", image: :failed }
      )
      success = subject.run_all
      expect(success).to be == false
    end
  end

  describe "#run_on_modifications" do
    it "handles zero failures" do
      expect_output("baz", dedent(<<-EOF), 4, 0)
        PASS: test passed
        FAIL: test failed
        EOF
      expect_colored_text("PASS: test passed\n", :green)
      expect_colored_text("FAIL: test failed\n", :red)
      expect(Guard::Compat::UI).to receive(:notify).with(
        "4 passes, 0 failures",
        { title: "baz", image: :success }
      )
      success = subject.run_on_modifications(%w(baz))
      expect(success).to be == true
    end

    it "handles zero failures but non-zero exit code" do
      expect_output("baz", dedent(<<-EOF), 4, 0, exitcode: 1)
        PASS: test passed
        FAIL: test failed
        EOF
      expect_colored_text("PASS: test passed\n", :green)
      expect_colored_text("FAIL: test failed\n", :red)
      expect(Guard::Compat::UI).to receive(:notify).with(
        "4 passes, 0 failures",
        { title: "baz", image: :success }
      )
      success = subject.run_on_modifications(%w(baz))
      expect(success).to be == true
    end

    it "handles failures" do
      expect_output("qux", dedent(<<-EOF), 3, 2)
        PASS: test passed
        FAIL: test failed
        EOF
      expect_colored_text("PASS: test passed\n", :green)
      expect_colored_text("FAIL: test failed\n", :red)
      expect(Guard::Compat::UI).to receive(:notify).with(
        "3 passes, 2 failures",
        { title: "qux", image: :failed }
      )
      success = subject.run_on_modifications(%w(qux))
      expect(success).to be == false
    end
  end
end
