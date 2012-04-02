require "prawn"
require "prawn/layout"
require "prawn/measurement_extensions"
require 'rubill/calendar'
require 'rubill/address_book'

class Invoice
  DEFAULT_ATTRS = { 
    cell_style: {
      border_width: 0, 
      border_color: 'ffffff',
      padding: 1
    },
  }
  attr_reader :calendar, :address_book, :pdf
  def initialize(options={ })
    @options=options
    @calendar = Calendar.new(options[:calendar])
    @address_book = AddressBook.new
    @from = options[:from] || @calendar.last_billed_date+1
    
    # default to end of of last month or today if today after
    # first week of month
    today = Date.today
    @to=options[:to] || (today.day > 7 ? today : today - today.day)
    @rate = options[:rate] ? options[:rate] :
      address_book.rate_for_company(@calendar.name)
    @invoice_id ||= @calendar.next_invoice

    @pdf = Prawn::Document.new(
      :left_margin => 1.25.in,
      :right_margin => 1.25.in
      )
    @pdf.font_size = 10

    STDERR.puts "Generating invoice for #{@calendar.name} " +
      "from #{@from.to_s} to #{@to.to_s}"
  end
  
  def save
    invoice_num = @calendar.next_invoice
    file = "#{@options[:directory]}/#{@calendar.name}_#{invoice_num}.pdf"
    STDERR.puts "Creating pdf file #{file}"

    table(
      ['Bill to'],
      address_book.address_for_company(@calendar.name).collect { |v| [v] },
      DEFAULT_ATTRS
      )
    pdf.move_down 10
    pdf.table([
        ['Invoice #',      "#{@calendar.name.downcase}-#{@invoice_id}"],
        ['Invoice Period', [@from, @to].join(' to ')],
        ['Invoice Date',   Date.today],
        ['Rate',           @rate],
        ['Terms',          '30 days'],
      ], DEFAULT_ATTRS)
    pdf.move_down 10
    items = line_items
    table(
      %w[date description hours amount],
      items,
      header: true, width: pdf.margin_box.width,
      cell_style: {
        border_color: 'ffffff',
        borders: [:left],
        border_width: 2,
        padding: 1,
      }, 
      column_widths: { 0 => 0.8.in, 2 => 0.5.in, 3 => 0.8.in }) do |t|
      t.row(-3..-1).font = 'Helvetica-Bold'
      t.rows(1..-1).columns(-2..-1).align = :right
      t.rows(1..-1).columns(-2).padding = [1, 3, 1, 1]
    end
    if logo=@options[:logo]
      pdf.image logo['image'], at: [logo['x'], logo['y']], 
      fit: [pdf.margin_box.width, logo['height']]
    end
    pdf.render_file(file)
    @calendar.add_invoice invoice_num, items[-3][3],
    @from, @to, file unless @options[:todo]

  end

  def table(header, data, attrs, &block)
    data.unshift header
    pdf.table(data, attrs) do
      row(0).background_color = 'eeeeee'
      yield self if block_given?
    end
  end

  def line_items
    balance=@calendar.outstanding
    t = @calendar.items_for(@from, @to).collect { |e| e << e[2] * @rate }
    
    t.sort! { |a,b| a[0] <=> b[0]}
    total = t.inject(0) { |s, r| s + r[3] }
    hours = t.inject(0) { |s, r| s + r[2]}
    
    t << 
      ['', 'Current',   hours, total]   <<
      ['', 'Balance',   '',    balance] <<
      ['', 'Total Due', '',    balance+total]

    t.each { |r| r[3] = fmt_ccy(r[3]) }
  end
  
  def fmt_ccy v
    sprintf('%8.2f', v)
  end
end
