# $Id$
require 'rubill/application'
require 'Time'
require 'date'

class Calendar < Application
  def initialize(cal_name)
    @appname='iCal'
    get_app.calendars.get.each do |c|
      next unless c.name.get == cal_name
      @name = c.name.get
      @events = c.events if c.events.count > 0
      @todos  = c.todos  if c.todos.count  > 0
    end
  end

  def name
    @name
  end

  def last_billed_date
    Date.parse(last_invoice_info[2])
  end

  def last_invoice
    last_invoice_info[0].to_i
  end

  def next_invoice
    last_invoice + 1
  end

  def invoices
    invoices=@todos.summary.get.select do |i|
      i =~ /^Invoice/
    end.sort do |a,b| 
      a.split[1].to_i <=> b.split[1].to_i
    end

    # start w/ invoice 110, from beginning  of last month
    # (set invoice date to last day of month before last)
    unless invoices.length > 0
      invoices << 
        'Invoice 110 0.0 ' + ((Date.today + 1 - Date.today.day << 1) - 1).to_s
    end
    invoices
  end

  def outstanding
    @todos.get.select do |t|
      d = t.completion_date.get
      # snow leopard returns ":missing_value" instead of nil
      (d.nil? || d == :missing_value) && t.summary.get =~ /^Invoice/
    end.collect do |t|
      t.summary.get.split(' ')[2].to_f
    end.inject(0) { |sum, v| sum + v }
  end


  def add_invoice num, total, from, to, file
    summary = sprintf("Invoice %d %0.2f %s", num, total, to)
    due     = (Date.today+30).to_s

    STDERR.puts "Adding todo: '#{summary}' due on #{due}"

    @todos.end.make(:new => :todo, :with_properties => {
        :summary => summary, :due_date => Time.parse(due),
        :url => "file://#{File.expand_path file}"
      })
  end

  def items_for from, to
    @events.get.reject do |e|
      start = Date.parse(e.start_date.get.to_s)
      start < from || start > to
    end.collect do |e|
      [ Date.parse(e.start_date.get.to_s),
        e.summary.get, (
          Time.parse(e.end_date.get.to_s) - Time.parse(e.start_date.get.to_s)
          )/3600,
      ]
    end.compact
  end

  private
  def last_invoice_info
    invoices.last.split(' ')[1..3]
  end

end
