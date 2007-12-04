# $Id$
require 'rubill/application'

class Calendar < Application
  def initialize(cal_name)
    @appname='iCal'
    @calendar=get_app.calendars[cal_name]
  end

  def name
    @calendar.name.get
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
    invoices=@calendar.todos.summary.get.select { |i|
      i =~ /^Invoice/
    }.sort {
      |a,b| a.split[1].to_i <=> b.split[1].to_i
    }
    # star w/ invoice 111 if no invoices
    invoices.length > 0 ? invoices : invoices << 'Invoice 110 0.0'
  end

  def outstanding
    @calendar.todos.get.select { |t|
      t.completion_date.get == nil &&  t.summary.get =~ /^Invoice/
    }.collect { |t|
      t.summary.get.split(' ')[2].to_f
    }.inject(0) { |sum, v| sum + v}
  end


  def add_invoice num, total, from, to
    summary = sprintf("Invoice %d %0.2f %s", num, total, to)
    due     = (Date.today+30).to_s

    STDERR.puts "Adding todo: '#{summary}' due on #{due}"

    @calendar.todos.end.make(:new => :todo, :with_properties => {
        :summary => summary, :due_date => Time.parse(due)
      })
  end

  def items_for from, to
    @calendar.events.get.reject { |e|
      start = Date.parse(e.start_date.get.to_s)
      start < from || start > to
    }.collect { |e|
      [ Date.parse(e.start_date.get.to_s),
        e.summary.get, (
          Time.parse(e.end_date.get.to_s) - Time.parse(e.start_date.get.to_s)
          )/3600,
      ]
    }.compact
  end

  private
  def last_invoice_info
    invoices.last.split(' ')[1..3]
  end

end
