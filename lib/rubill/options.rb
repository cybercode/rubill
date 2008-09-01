require 'optparse'
require 'optparse/date'
require 'yaml'

DEFAULT_FILE='./config/config.yaml'.freeze

class InvoiceOptions
  OPTIONS=[
    ['c', 'config FILE', 'config file', nil],
    ['f', 'from DATE',  Date, 
      'start date (last billed date from calendar todos or beginning of last month)',
      nil
    ],
    ['t', 'to DATE',    Date, 
      'end date (end of last month or today if after first week of month)',  nil
    ],
    ['T', 'todo',             "don't add invoice to calendar todos", false],
    ['d', 'directory DIR',    'output directory', '.'],
    ['r', 'rate RATE',  Float, 'billing rate', nil],
    ['a', 'address "LINE1|LINE2..."', 'your address', nil],
    ['l', 'logo "FILE,X,Y,W,H"', 'logo image and metrics', nil],
  ]
  def self.parse(args)
    arg_options={ }
    op=OptionParser.new do |op|
      op.banner ="usage: #{File.basename $0} [options] calendar"
      self.each do |o|
        default = o.pop
        sym = o.shift
        o[-1] << " (#{default})" if default
        o[0..1]="-#{o[0]}", "--#{o[1]}"
        op.on(*o) {
          |arg| arg_options[sym]=arg
        }
      end
      op.on('-h', '--help') do
        puts op
        exit
      end
      [
        'All options can be set (by long name) in the config file.',
        'Address should be an array, logo a hash.',
        'Precedence: command line > config > default.',
      ].each { |s| op.separator s}
    end
    op.parse!(args)
    if arg_options[:logo]
      a=arg_options[:logo].split(',')
      logo={ }
      %w(image x y width height).each_with_index do |f,i|
        logo[f] = i > 0 ? a[i].to_f : a[i]
      end
      arg_options[:logo]=logo
    end
    if arg_options[:address]
      arg_options[:address]=arg_options[:address].split('|')
    end

    config_options={ }
    if file=arg_options[:config] || 
        File.exist?(DEFAULT_FILE) ? DEFAULT_FILE : nil
      YAML.load_file(file).each do |k,v|
        config_options[k.intern]=
          case k.intern
          when :from, :to
            Date.parse(v)
          when :rate
            v.to_f
          else
            v
          end
      end
    end
    self.each do |o|
      #set defaults
      next if config_options[o[0]]
      config_options[o[0]]=o[-1]
    end
    config_options.merge(arg_options)
  end

  private
  def self.optsym option
    (option.class == String ? option : option[1]).split(/[ =]/)[0].intern
  end
  def self.each
    OPTIONS.each do |o|
      yield [self.optsym(o), o].flatten
    end
  end
end
