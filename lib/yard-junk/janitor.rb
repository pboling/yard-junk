# frozen_string_literal: true

require 'benchmark'

module YardJunk
  class Janitor
    def run(*opts)
      YARD::Registry.clear # Somehow loads all Ruby stdlib classes before Rake task started...
      Logger.instance.format = nil

      puts "Running YardJunk janitor...\n\n"

      @duration = Benchmark.realtime do
        command = YARD::CLI::Yardoc.new
        command.run('--no-save', '--no-progress', '--no-stats', '--no-output', *opts)
        Resolver.resolve_all(command.options)
      end

      self
    end

    def stats
      {
        errors: errors.count,
        problems: problems.count,
        duration: @duration || 0
      }
    end

    def report(*reporters)
      reporters.each do |reporter|
        reporter.section('Errors', 'severe code or formatting problems', errors)
        reporter.section('Problems', 'mistyped tags or other typos in documentation', problems)

        reporter.stats(stats)
        reporter.finalize
      end

      exit_code
    end

    def exit_code
      return 2 unless errors.empty?
      return 1 unless problems.empty?
      0
    end

    private

    def messages
      YardJunk::Logger.instance.messages.grep_v(Logger::Undocumentable) # FIXME: Not DRY
    end

    def errors
      messages.select(&:error?)
    end

    def problems
      messages.select(&:warn?)
    end
  end
end

require_relative 'janitor/base_reporter'
require_relative 'janitor/text_reporter'
require_relative 'janitor/html_reporter'
require_relative 'janitor/resolver'
