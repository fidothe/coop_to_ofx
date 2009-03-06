module OFX
  class Base
    class << self
      def fitid_hash
        @fitid_hash ||= {}
      end
      
      def time_to_ofx_dta(timeobj, extended=false)
        fmt = '%Y%m%d' + (extended ? '%H%M%S' : '')
        timeobj.strftime(fmt)
      end
      
      def generate_fitid(time)
        date = time_to_ofx_dta(time)
        suffix = fitid_hash[date].nil? ? 1 : fitid_hash[date] + 1
        fitid_hash[date] = suffix
        "#{date}#{suffix}"
      end
      
      def generate_trntype(amount)
        amount.match(/^-[0-9]/) ? 'DEBIT' : 'CREDIT'
      end
    end
  end
end