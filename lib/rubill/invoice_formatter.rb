# $Id$
class Invoice < Ruport::Controller
  stage :header, :body, :footer
  finalize :invoice
end

class InvoiceFormatter
  class PDF < Ruport::Formatter::PDF
    renders :pdf, :for => Invoice

    def build_header
      if options[:address]
        draw_table(
        a_table('', options[:address]),
        defaults.merge(:row_gap => 0,
        :position => :right, :orientation => :left))
      end
      draw_table(address_table, defaults.merge(:row_gap => 0))
      add_text "\n"

      draw_table(invoice_info,
        defaults.merge(:show_headings => false, :row_gap => 0))
      add_text "\n\n"
    end

    def build_body
      draw_table(line_items,
        defaults.merge(
          :shade_headings => true,
          :width => 6 * 72,
          :column_options => {
            :heading => { :justification => :center },
            'hours'  => { :justification => :right  },
            'amount' => { :justification => :right  }
          }))
    end

    def build_footer
      return unless options[:logo]
      args={ }
      options[:logo].each { |k,v| args[k.intern]=v  }
      image=args.delete(:image)
      center_image_in_box(image, args)
    end

    def finalize_invoice
      file =
        "#{options[:directory]}/#{@calendar.name}_#{@calendar.next_invoice}.pdf"
      STDERR.puts "Creating pdf file #{file}"
      File.open(file, 'w') do |f| f << render_pdf; end

      add_invoice file unless options[:todo]
    end
  end
end
