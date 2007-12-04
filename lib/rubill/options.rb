require 'optparse'
class InvoiceOptions
  def self.parse(args)
    options = { :todo  => true, :rate => nil, :config => { }, :dir=>'./output' }
    op = OptionParser.new do |op|
      op.banner = "usage: #{File.basename $0} [options] calendar"
      [
        ['from', 'Optional start date'],
        ['to', 'Optional end date']
      ].each do |o,s|
        op.on("-#{o[0..0]}", "--#{o} [DATE]", s) do |v|
          options[o.intern]=Date.parse(v)
        end
      end
      op.on('--[no-]todo', "[don't] add invoice todo to calendar") do |v|
        options[:todo]=v
      end
    end
    op.on('--directory=DIR', '-d', 'output directory') do |v|
      options[:dir]=v
    end
    op.on('--rate=RATE', '-r', 'hourly billing rate') do |v|
      options[:rate]=v.to_f
    end
    op.on('--config=FILE', '-c', 'optional yaml config file') do |v|
      require 'yaml'
      options[:config]=YAML.load(File.open(v))
    end

    op.on_tail('-h', '--help') do
      puts op
      exit
    end

    op.parse!(args)
    options
  end

end
