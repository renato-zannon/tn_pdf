require 'tn_pdf/table_column'
require 'prawn'

module TnPDF
  class Table
    attr_accessor *Configuration.table_properties_names

    def initialize
      Configuration.table_properties_names.each do |property|
        send("#{property}=", Configuration["table_#{property}"])
      end
    end

    def columns_hash
      columns_hash = ActiveSupport::OrderedHash.new
      columns.inject(columns_hash) do |hash, column|
        hash[column.header] = column.to_proc
        hash
      end
    end

    def columns_headers
      columns.map(&:header)
    end

    def collection
      @collection ||= Array.new
    end

    def collection=(collection)
      raise ArgumentError unless collection.kind_of? Array
      @collection = collection
    end

    def add_column(column)
      unless column.kind_of? Column
        column = Column.new(column)
      end
      columns << column
    end

    def rows
      collection.map do |object|
        columns.map do |column|
          column.value_for(object)
        end
      end
    end

    def render(document, max_height)
      table = document.make_table([columns_headers]+rows,
                                  :header => multipage_headers)
      x_pos = x_pos_on(document, table.width)
      document.bounding_box([x_pos, document.cursor], :width => table.width, :height => max_height) do
        table.draw
      end
    end

    def columns
      @columns ||= []
    end

    private

    def x_pos_on(document, table_width)
      case align
        when :left
          0
        when :center
          (document.bounds.right - table_width)/2.0
        when :right
          document.bounds.right - table_width
        else
          0
      end
    end

  end

end
