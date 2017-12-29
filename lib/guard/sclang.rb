require 'open3'
require 'pathname'

require 'guard/compat/plugin'
require 'guard/sclang/version'

module Guard
  class Sclang < Plugin
    def initialize
      super
      options[:args] ||= []
      options[:timeout] ||= 3
    end

    # Calls #run_all if the :all_on_start option is present.
    def start
      run_all if options[:all_on_start]
    end

    # Defined only to make callback(:stop_begin) and callback(:stop_end) working
    def stop
    end

    # Call #run_on_change for all files which match this guard.
    def run_all
      all = Compat.matching_files(self, Dir.glob('{,**/}*.sc{,d}'))
      run_on_modifications(all)
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
      [cmd, title]
    end

    def run_sclang(paths)
      cmd, title = _get_cmd_and_title(paths)

      outerr = ''
      print Compat::UI.color("=" * (ENV["COLUMNS"] || "72").to_i, :blue)
      print Compat::UI.color("Running: " + cmd.join(" ") + "\n", :blue)

      got_status, exit_status = _run_cmd(cmd, title)

      unless got_status
        _handle_missing_status(exit_status, title)
      end
    end

    def _run_cmd(cmd, title)
      got_status = false
      exit_status = nil

      Open3.popen2e(*cmd) do |stdin, stdouterr, wait_thr|
        stdouterr.each do |line|
          #Compat::UI.info(line)
          colors =
            if line =~ /^PASS:/
              [:green]
            elsif line =~ /^FAIL:/
              [:red]
            elsif line =~ /^ERROR:/
              [:bright, :red]
            elsif line =~ /^WARNING:/
              [:yellow]
            else
              []
            end

          status, msg, line = _check_line_for_status(line)
          if status
            got_status = true
            Compat::UI.notify(msg, title: title, image: status)
          end

          print Compat::UI.color(line, *colors)
        end

        exit_status = wait_thr.value
      end

      [got_status, exit_status]
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

    def _handle_missing_status(exit_status, title)
      msg = "Pid %d exited with status %d" % [exit_status.pid, exit_status]
      status = exit_status == 0 ? :success : :failed
      Compat::UI.notify(msg, title: title, image: status)
      level = status == :success ? :warning : :error
      Compat::UI.send(level, msg)
      Compat::UI.warning("Didn't find test results in output")
    end
  end

  class Dsl
    # Easy method to display a notification
    def n(msg, title='', image=nil)
      Compat::UI.notify(msg, :title => title, :image => image)
    end

    # Eager prints the result for stdout and stderr as it would be written when
    # running the command from the terminal. This is useful for long running
    # tasks.
    def eager(command)
      require 'pty'

      begin
        PTY.spawn command do |r, w, pid|
          begin
            $stdout.puts
            r.each {|line| print line }
          rescue Errno::EIO
            # the process has finished
          end
        end
      rescue PTY::ChildExited
        $stdout.puts "The child process exited!"
      end
    end
  end
end
