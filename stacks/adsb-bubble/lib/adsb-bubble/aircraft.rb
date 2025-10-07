require 'sorbet-runtime'

module AdsbBubble
  class Aircraft < T::Struct
    const :hex, String
    const :type, T.nilable(String)
    const :r, T.nilable(String)
    const :rc, T.nilable(Integer)
    const :t, T.nilable(String)
    const :desc, T.nilable(String)
    const :ownOp, T.nilable(String)
    const :year, T.nilable(String)
    const :gs, T.nilable(Float)
    const :track, T.nilable(Float)
    const :geom_rate, T.nilable(Integer)
    const :nav_qnh, T.nilable(Float)
    const :nav_altitude_mcp, T.nilable(Integer)
    const :nav_heading, T.nilable(Float)
    const :version, T.nilable(Integer)
    const :nic_baro, T.nilable(Integer)
    const :nac_p, T.nilable(Integer)
    const :nac_v, T.nilable(Integer)
    const :sil, T.nilable(Integer)
    const :sil_type, T.nilable(String)
    const :gva, T.nilable(Integer)
    const :sda, T.nilable(Integer)
    const :alert, T.nilable(Integer)
    const :spi, T.nilable(Integer)
    const :mlat, T.nilable(Array[T.untyped])
    const :tisb, T.nilable(Array[T.untyped])
    const :messages, T.nilable(Integer)
    const :seen, T.nilable(Float)
    const :rssi, T.nilable(Float)
    const :flight, T.nilable(String)
    const :alt_baro, T.nilable(Integer)
    const :baro_rate, T.nilable(Integer)
    const :squawk, T.nilable(String)
    const :emergency, T.nilable(String)
    const :category, T.nilable(String)
    const :lat, T.nilable(Float)
    const :lon, T.nilable(Float)
    const :nic, T.nilable(Integer)
    const :seen_pos, T.nilable(Float)
    const :r_dst, T.nilable(Float)
    const :r_dir, T.nilable(Float)
    const :nav_modes, Array[T.untyped], default: []

    def in_bubble?
      baro = [alt_baro, nic_baro].detect { |b| !b.nil? && b.to_i > 0}
      return false if baro.nil?

      !r_dst.nil? && r_dst <= 3 && baro <= 5000
    end
  end
end
