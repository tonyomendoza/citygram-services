require 'spy_glass/registry'

opts = {
  path: '/los-angeles-311-service-request',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'https://data.lacity.org/resource/h65r-yf5i.json?'+Rack::Utils.build_query({
    '$order' => 'updateddate DESC',
    '$limit' => 100,
    '$where' => <<-WHERE.oneline
        srnumber IS NOT NULL AND
        latitude IS NOT NULL AND
        longitude IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = "#{SpyGlass::Salutations.next} "
    if createddate == updateddate
      title += <<-TITLE.oneline
      A service request has been created for #{item['requesttype']}
        TITLE
    elsif
      title += <<-TITLE.oneline
      A service request has been updated for #{item['requesttype']}
        TITLE
    end
    if addressverified = "Y"
      title += <<-TITLE.oneline
       at #{item['address']}
        TITLE
    end
        {
          'id' => item['srnumber'],
          'type' => 'Feature',
          'geometry' => {
            'type' => 'Point',
            'coordinates' => [
              item['longitude'].to_f,
              item['latitude'].to_f
            ]
          },
          'properties' => item.merge('title' => title)
        }
    #end
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
