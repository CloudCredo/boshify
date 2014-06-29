module Boshify
  # Wraps running operating system commands
  class CommandRunner
    def run(cmd)
      result = `#{cmd}`
      fail "Problem running command: #{cmd}" unless $CHILD_STATUS.success?
      result
    end
  end
end
