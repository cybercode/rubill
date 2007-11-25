# $Id$
class Invoice < Ruport::Renderer
  stage :header, :body, :footer
  finalize :invoice
end

class InvoiceFormatter
  class PDF < Ruport::Formatter::PDF
    renders :pdf, :for => Invoice

    def build_header
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
      center_image_in_box(
        'data/logo.png', :x => 0, :y => 50, :width => 600, :height => 40
        )
    end

    def finalize_invoice
      file = "output/#{@calendar.name}_#{@calendar.next_invoice}.pdf"
      STDERR.puts "Creating pdf file #{file}"
      File.open(file, 'w') do |f| f << render_pdf; end

      add_invoice if options[:todo]
    end
  end
end
