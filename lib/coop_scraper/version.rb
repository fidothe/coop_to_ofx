module CoopScraper
  def self.Version
    CoopScraper::Version::FULL
  end
  
  module Version
    MAJOR = 1
    MINOR = 0
    POINT = 0
    FULL = [CoopScraper::Version::MAJOR, CoopScraper::Version::MINOR, CoopScraper::Version::POINT].join('.')
  end
end