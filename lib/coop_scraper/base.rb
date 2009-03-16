module CoopScraper
  module Base
    def coop_date_to_time(coop_date)
      day, month, year = coop_date.match(/([0-9]{2})\/([0-9]{2})\/([0-9]{4})/).captures
      Time.utc(year, month, day)
    end
  end
end