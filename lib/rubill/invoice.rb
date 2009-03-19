# encoding: utf-8
require "prawn"
require "prawn/layout"
require "prawn/measurement_extensions"
require 'rubill/calendar'
require 'rubill/address_book'

class Invoice
  DEFAULT_ATTRS = { 
    :vertical_padding => 0.5,
    :border_width => 0,
    :align_headers => :left,
    :header_color  => 'eeeeee',
  }
  attr_reader :calendar, :address_book
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

    STDERR.puts "Generating invoice for #{@calendar.name} " +
      "from #{@from.to_s} to #{@to.to_s}"
  end
  
  def save
    invoice_num = @calendar.next_invoice
    file = "#{@options[:directory]}/#{@calendar.name}_#{invoice_num}.pdf"
    STDERR.puts "Creating pdf file #{file}"

    pdf = Prawn::Document.new(
      :left_margin => 1.25.in, :right_margin => 1.25.in )
    pdf.font_size = 10
    pdf.table address_book.address_for_company(@calendar.name).collect { 
      |v| [v]
    }, DEFAULT_ATTRS.merge(:headers => ['bill to' ]) 
    pdf.move_down 20
    
    pdf.table [
      ['Invoice #',      "#{@calendar.name.downcase}-#{@invoice_id}"],
      ['Invoice Period', [@from, @to].join(' to ')],
      ['Invoice Date',   Date.today],
      ['Rate',           @rate],
      ['Terms',          '30 days'],
    ], DEFAULT_ATTRS.merge(:align => :left)
    pdf.move_down 20
    
    attrs=DEFAULT_ATTRS.merge(
      :align         => { 2 => :right, 3 => :right },
      :width         => pdf.margin_box.width,
      :border_color  => 'ffffff',
      :border_style  => :grid,
      :border_width  => 2,
      :column_widths => { 0 => 1.in, 2 => 0.75.in, 3 => 1.in }
      )
    items, totals=line_items
    
    pdf.table items, attrs.merge(:headers => %w[date description hours amount])
    
    pdf.font 'Helvetica-Bold'
    pdf.table totals, attrs

    if l=@options[:logo]
      pdf.image l['image'], :at => [l['x'], l['y']], 
      :fit => [pdf.margin_box.width, l['height']]
    end
    pdf.render_file(file)
    
    @calendar.add_invoice invoice_num, totals[0][3],
    @from, @to, file unless @options[:todo]

  end

  def line_items
    balance=@calendar.outstanding
    t = @calendar.items_for(@from, @to).collect { |e| e << e[2] * @rate }
    
    t.sort! { |a,b| a[0] <=> b[0]}
    total = t.inject(0) { |s, r| s + r[3] }
    hours = t.inject(0) { |s, r| s + r[2]}
    
    t.each { |r| r[3] = fmt_ccy(r[3]) }

    tt = [
      ['', 'Current',   hours, fmt_ccy(total)],
      ['', 'Balance',   '',    fmt_ccy(balance)],
      ['', 'Total Due', '',    fmt_ccy(balance+total)]
    ]
    
    [t, tt]
  end
  
  def fmt_ccy v
    sprintf('%8.2f', v)
  end
end
