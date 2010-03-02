module AltRecord
  class SerialColumn < IntegerColumn
    def primary_key?
      true
    end
  end
end