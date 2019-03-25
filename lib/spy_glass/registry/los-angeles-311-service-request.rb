require 'spy_glass/registry'

opts = {
  path: '/los-angeles-311-service-request',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'https://data.lacity.org/resource/pvft-t768.json?'+Rack::Utils.build_query({
    '$order' => 'updateddate DESC',
    '$limit' => 100,
    '$where' => <<-WHERE.oneline
        srnumber IS NOT NULL AND
        latitude IS NOT NULL AND
        longitude IS NOT NULL
    WHERE
  })
}

time_zone = ActiveSupport::TimeZone['Pacific Time (US & Canada)']

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    time = Time.iso8601(item['updateddate']).in_time_zone(time_zone).strftime("%m/%d %I:%M %p")
    title = "#{SpyGlass::Salutations.next}"
    if item['createddate'] == item['updateddate']
      title += "A service request has been created for #{item['requesttype']}, "
    elsif
      title += "A service request has been updated for #{item['requesttype']}, "
    end
    if item['addressverified'] = "Y"
      title += " at #{item['address']}"
    end
    title += "Date: #{time}. Status: #{item['status']}. The following action has been taken: #{item['actiontaken']}, and assigned to the department/agency #{item['owner']}"
    if item['assignto'].blank? == false
      title += ", #{item['assignto']}"
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
