module AdsbBubble
  class Database
    include Singleton
    
    attr_reader :handle

    def initialize
      @handle = Sequel.connect(ENV.fetch('DATABASE_URL', 'sqlite://adsb_bubble.db'))
    end
  end
end
