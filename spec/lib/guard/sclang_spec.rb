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

  def expect_output(paths, test_output, passes, fails, timeout: 5, exitcode: nil)
    expect_colored_text(/=============+/, :blue)
    expect_colored_text(%r{Running: timeout \d+ sclang .* #{paths}}, :blue)

    fake_summary = "Finished running test(s): #{passes} passes, #{fails} failures\n"
    # Don't assume the summary is the last line of the output
    fake_footer = "cleaning up OSC\n"
    fake_output = StringIO.new(test_output + "\n" + fake_summary + fake_footer)
    fake_output.rewind
    expect(PTY).to receive(:spawn).with(
      "timeout", timeout.to_s, "sclang", %r{.*/unit-test-cli\.scd$}, *paths
    ) { |command, *args, &block|
      `exit #{exitcode || fails}`
      block.call(fake_output, "fake stdin", $?.pid)
    }
    expect_colored_text(fake_summary, fails == 0 ? :green : :red)
    allow(Guard::Compat::UI).to receive(:color)
  end

  def expect_run(paths, test_output, passes, fails, expected_success, **extra)
    expect_output(paths, test_output, passes, fails, **extra)
    expect(Guard::Compat::UI).to receive(:notify).with(
      "#{passes} passes, #{fails} failures",
      { title: paths.join(" "), image: expected_success ? :success : :failed }
    )
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

    def test_success
      expect_run(["bar"], dedent(<<-EOF), 5, 0, true)
        PASS: test passed
        EOF
      got_success = subject.run_all
      expect(got_success).to be == true
    end

    def test_failure
      expect_run(["bar"], dedent(<<-EOF), 5, 1, false)
        PASS: test passed
        FAIL: test failed
        EOF
      got_success = subject.run_all
      expect(got_success).to be == false
    end

    it "handles success" do
      test_success
    end

    it "handles a failure" do
      test_failure
    end

    it "doesn't trigger all_after_pass" do
      subject.options[:all_after_pass] = true
      test_failure
      test_success
    end
  end

  describe "#run_on_modifications" do
    def expect_success(paths)
      expect_run(paths, dedent(<<-EOF), 4, 0, true)
        PASS: test passed
        EOF
      expect_colored_text("PASS: test passed\n", :green)
    end

    def expect_failure(paths)
      expect_run(paths, dedent(<<-EOF), 3, 2, false)
        PASS: test passed
        FAIL: test failed
        EOF
      expect_colored_text("PASS: test passed\n", :green)
      expect_colored_text("FAIL: test failed\n", :red)
    end

    it "handles zero failures" do
      expect_success(["baz"])
      success = subject.run_on_modifications(%w(baz))
      expect(success).to be == true
    end

    it "handles zero failures but non-zero exit code" do
      expect_run(["baz"], dedent(<<-EOF), 4, 0, exitcode: 1)
        PASS: test passed
        EOF
      expect_colored_text("PASS: test passed\n", :green)
      success = subject.run_on_modifications(%w(baz))
      expect(success).to be == true
    end

    it "handles failures" do
      paths = ["qux"]
      expect_failure(paths)
      success = subject.run_on_modifications(paths)
      expect(success).to be == false
    end

    it "triggers all_after_pass and everything passes" do
      subject.options[:all_after_pass] = true

      paths = ["qux"]

      # fail the 1st run
      expect_failure(paths)
      success = subject.run_on_modifications(paths)
      expect(success).to be == false

      # Pass the 2nd; this should trigger 3rd run (run_all).
      # Set up expectations for 2nd run:
      expect_success(paths)

      # Set up expectations for 3rd run to pass:
      all = %w(foo bar baz qux)
      expect(Guard::Compat).to receive(:matching_files).and_return(all)
      expect_success(all)

      # Now trigger 2nd and 3rd:
      success = subject.run_on_modifications(paths)
      expect(success).to be == true
    end

    it "triggers all_after_pass and final run_all fails" do
      subject.options[:all_after_pass] = true

      paths = ["qux"]

      # fail the 1st run
      expect_failure(paths)
      success = subject.run_on_modifications(paths)
      expect(success).to be == false

      # Pass the 2nd; this should trigger 3rd run (run_all).
      # Set up expectations for 2nd run:
      expect_success(paths)

      # Set up expectations for 3rd run to pass:
      all = %w(foo bar baz qux)
      expect(Guard::Compat).to receive(:matching_files).and_return(all)
      expect_failure(all)

      # Now trigger 2nd and 3rd:
      success = subject.run_on_modifications(paths)
      expect(success).to be == false
    end
  end
end
