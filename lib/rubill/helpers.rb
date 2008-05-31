# $Id$
def init_attrs
  # use last month if from, to not specified
  return if @calendar
  @calendar = Calendar.new(options[:calendar])
  @address_book = AddressBook.new

  @from = options[:from] || @calendar.last_billed_date+1
  # default to end of of last month or today if today after
  # first week of month
  today = Date.today
  @to=options[:to] || (today.day > 7 ? today : today + 1 - today.day)
  STDERR.puts "Generating invoice for #{@calendar.name} " +
    "from #{@from.to_s} to #{@to.to_s}"
end

def line_items
  init_attrs

  t = Table(%w(date description hours))
  balance=@calendar.outstanding
  @calendar.items_for(@from, @to).each do |e|
    t << e
  end
  t.add_column('amount') { |r| sprintf "%8.2f", r.hours * rate}
  t.sort_rows_by!("date")
  @total = t.sigma('amount')
  t << ['', '', '', '']
  t << ['', '<b>Current</b>',"<b>#{t.sigma('hours')}</b>", fmt_ccy(@total)]
  t << ['', '<b>Balance</b>','',fmt_ccy(balance)]
  t << ['','<b>Total Due</b>','', fmt_ccy(balance+@total)]
end

def address_table
  a_table 'Bill To', address
  #Table('<i>Bill To</i>') { |t| address.each { |a| t << [a] } }
end

def a_table header, body
  Table("<i>#{header}</i>") { |t| body.each { |l| t << [l] } }
end

def rate
  options[:rate] ? options[:rate] :
    @address_book.rate_for_company(@calendar.name)
end

def invoice_info
  Table('label','value') do |t|
    t << ['<i>Invoice #</i>', invoice_num]
    t << ['<i>Invoice Period</i>', period.join(' to ')]
    t << ['<i>Invoice Date</i>', Date.today]
    t << ['<i>Rate</i>', rate]
    t << ['<i>Terms</i>', '30 days']
  end
end

def fmt_ccy v
  sprintf('<b>%8.2f</b>', v)
end

def address
  init_attrs
  @address_book.address_for_company(@calendar.name)
end

def period
  [@from, @to]
end

def invoice_num
  init_attrs
  @invoice_id ||= @calendar.next_invoice
end

def defaults
  {
    :heading_font_size => 10,
    :show_lines => :none,
    :shade_rows => :none,
    :position   => 90,
    :orientation=> :right,
  }
end

def add_invoice file
  init_attrs
  @calendar.add_invoice invoice_num, @total, @from, @to, file
end
