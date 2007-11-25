require 'optparse'
class InvoiceOptions
  def self.parse(args)
    options = { :todo  => true }
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

    op.on_tail('-h', '--help') do
      puts op
      exit
    end

    op.parse!(args)
    options
  end

end
