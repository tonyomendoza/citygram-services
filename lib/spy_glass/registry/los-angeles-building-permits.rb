require 'spy_glass/registry'

opts = {
  path: '/los-angeles-building-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'https://data.lacity.org/resource/nbyu-2ha9.json?'+Rack::Utils.build_query({
    '$limit' => 100,
    #'$order' => 'application_date DESC',
    '$where' => <<-WHERE.oneline
      latest_status = 'CofO Issued' AND
      pcis_permit IS NOT NULL AND
      location_1 IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
    #{SpyGlass::Salutations.next} A building permit has been submitted near you at #{item['address_start']} #{item['street_direction']} #{item['street_name']} #{item['street_suffix']} #{item['zip_code']}.
      The proposed value is #{Money.us_dollar(item['valuation'].to_i*100).format(no_cents: true)}.
      Find out more at http://ladbsdoc.lacity.org/idispublic/ and search #{item['pcis_permit']} using the Document Search By Document Number option.
    TITLE

    {
      'id' => item['pcis_permit'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['location_1']['longitude'].to_f,
          item['location_1']['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
