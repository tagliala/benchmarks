#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'), File.dirname(__FILE__))

require 'slim'
require 'context'

require 'benchmark/ips'
require 'benchmark/memory'
require 'tilt'
require 'erubi'
require 'erb'
require 'haml'

class SlimBenchmarks
  def initialize
    @benches = []

    @erb_code  = File.read(File.dirname(__FILE__) + '/view.erb')
    @haml_code = File.read(File.dirname(__FILE__) + '/view.haml')
    @slim_code = File.read(File.dirname(__FILE__) + '/view.slim')

    init_compiled_benches
  end

  def init_compiled_benches
    context = Context.new
    context.instance_eval %{
      def run_erb; #{ERB.new(@erb_code).src}; end
      def run_temple_erb; #{Temple::ERB::Engine.new.call(@erb_code)}; end
      def run_erubi; #{Erubi::Engine.new(@erb_code).src}; end
      def run_haml; #{Haml::Engine.new(escape_attrs: false).call(@haml_code)}; end
      def run_slim; #{Slim::Engine.new.call(@slim_code)}; end
    }

    bench(:compiled, "erb #{ERB.version}")            { context.run_erb }
    bench(:compiled, "erubi #{Erubi::VERSION}")       { context.run_erubi }
    bench(:compiled, "temple erb #{Temple::VERSION}") { context.run_temple_erb }
    bench(:compiled, "haml #{Haml::VERSION}")         { context.run_haml }
    bench(:compiled, "slim #{Slim::VERSION}")         { context.run_slim }
  end

  def run
    Benchmark.ips do |x|
      @benches.each do |name, block|
        x.report(name.to_s, &block)
      end
      x.compare!
    end

    Benchmark.memory do |x|
      @benches.each do |name, block|
        x.report(name.to_s, &block)
      end
      x.compare!
    end
  end

  def bench(group, name, &block)
    @benches.push([name, block])
  end
end

SlimBenchmarks.new.run
