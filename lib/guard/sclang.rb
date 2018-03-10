require 'pathname'
require 'pty'

require 'guard/compat/plugin'
require 'guard/sclang/version'

module Guard
  class Sclang < Plugin
    attr_accessor :last_failed

    def initialize(options={})
      super
      options[:args] ||= []
      options[:timeout] ||= 3
      @last_failed  = false
    end

    # Calls #run_all if the :all_on_start option is present.
    def start
      run_all if options[:all_on_start]
    end

    # Defined only to make callback(:stop_begin) and callback(:stop_end) working
    def stop
    end

    # Test for all files which match this guard.
    def run_all
      run_sclang
    end

    def all_paths
      Compat.matching_files(self, Dir.glob('{,**/}*.sc{,d}'))
    end

    def run_on_additions(paths)
      run_sclang(paths)
    end

    def run_on_modifications(paths)
      run_sclang(paths)
    end

    def run_on_removals(paths)
      run_sclang(paths)
    end

    def _get_cmd_and_title(paths)
      # -i scqt is required to compile IDE libraries, otherwise we get
      # compile warnings on Quarks which extend classes provided by those
      # IDE libraries.
      here = Pathname.new(__FILE__).dirname
      runner = here.parent.parent + "unit-test-cli.scd"
      tester = ["sclang"] + options[:args] + [runner.to_s]
      cmd = ["timeout", options[:timeout].to_s] + tester
      if paths
        cmd += paths
        title = paths.join " "
      else
        title = tester.join " "
      end
      return [cmd, title]
    end

    def run_sclang(paths=nil)
      success = run_sclang_once(paths || all_paths)
      if paths && options[:all_after_pass] && success && last_failed
        success = run_all
      end
      @last_failed = !success
      return success
    end

    def run_sclang_once(paths)
      paths = paths.uniq
      cmd, title = _get_cmd_and_title(paths)

      outerr = ''
      print Compat::UI.color("=" * (ENV["COLUMNS"] || "72").to_i, :blue)
      print Compat::UI.color("Running: " + cmd.join(" ") + "\n", :blue)

      run_status, exit_status = _run_cmd(cmd, title)

      if run_status
        return run_status == :success
      else
        # Couldn't figure out the result from the output, so rely on
        # the exit code instead.
        _handle_missing_status(exit_status, title)
        return exit_status.success?
      end
    end

    # Returns [run_status, exit_status] pair.
    #
    # Run the test runner, add colour for PASS/FAIL/ERROR/WARNING, and
    # try to extract the final test result (100% pass / some failures
    # / compilation error) from the runner output.  If the test result
    # is successfully extracted from the output, the appropriate
    # notification will be sent, and the run_status value returned
    # will be :success or :failed.  However if something goes wrong
    # then we won't be able to determine the result from the output,
    # in which case at least we capture the exit status of the runner
    # process, and success is determined based on this exit status.
    #
    # Note that due to quirks in SuperCollider which are not yet
    # understood, it is possible for the exit code to be non-zero even
    # when the test suite passes 100% and the test runner is
    # apparently working as designed.
    def _run_cmd(cmd, title)
      command, *args = *cmd

      run_status = nil
      exit_status = nil

      # Using PTY instead of Open3.popen2e should work around
      # https://github.com/supercollider/supercollider/issues/3366
      begin
        PTY.spawn command, *args do |stdouterr, stdin, pid|
          begin
            stdouterr.each do |line|
              #Compat::UI.info(line)
              colors =
                if line =~ /^PASS:/
                  [:green]
                elsif line =~ /^FAIL:|^There were failures/
                  [:red]
                elsif line =~ /^ERROR:/
                  [:bright, :red]
                elsif line =~ /^WARNING:/
                  [:yellow]
                else
                  []
                end

              line_status, msg, line = _check_line_for_status(line)
              if line_status
                # Allow for multiple summary lines just in case, e.g.
                # some with no failures and others with failures.
                # Hopefully this won't happen though.
                if line_status == :success
                  run_status ||= line_status
                else
                  run_status = line_status
                end

                Compat::UI.notify(msg, title: title, image: line_status)
              end

              print Compat::UI.color(line, *colors)
            end

            # stdouterr should always raise Errno::EIO when EOF is reached.
            # If this doesn't happen, probably the test suite is running.
            raise Errno::EIO
          rescue Errno::EIO => e
            # Ran out of output to read
            exit_status = $?
            unless exit_status
              Compat::UI.error("$? returned #{exit_status}")
            end
          end
        end
      rescue PTY::ChildExited => e
        $stdout.puts "The child process exited! #{e}"
        exit_status = e.status.exitstatus
      end

      [run_status, exit_status]
    end

    def _check_line_for_status(line)
      status, msg = nil

      if line =~ /Finished running test\(s\): (\d+ pass(?:es), (\d+) failures?)/
        msg, failures = $1, $2
        status = failures == "0" ? :success : :failed  # :pending also supported
      elsif line =~ /(Library has not been compiled successfully)\./
        msg = $1
        status = :failed
      end

      if status
        line = Compat::UI.color(line, status == :success ? :green : :red)
      end

      [status, msg, line]
    end

    # Couldn't figure out the result from the output, so rely on
    # the exit code instead.
    def _handle_missing_status(exit_status, title)
      msg = "Pid %d exited with status %d" % [exit_status.pid, exit_status.exitstatus]
      status = exit_status.success? ? :success : :failed
      Compat::UI.notify(msg, title: title, image: status)
      level = status == :success ? :warning : :error
      Compat::UI.send(level, msg)
      Compat::UI.warning("Didn't find test results in output")
      exit_status.success?
    end
  end
end
