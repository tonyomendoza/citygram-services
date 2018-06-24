require 'spy_glass/registry'

opts = {
  path: '/los-angeles-metro',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'http://api.metro.net/agencies/lametro/vehicles/?'+Rack::Utils.build_query({
    '$where' => <<-WHERE.oneline
      id = IS NOT NULL AND
      heading IS NOT NULL AND
      id = IS NOT NULL AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      predictable = true 
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
    features = collection.values[0].map do |item|
      
     routeOpts = {
      cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
      source: 'http://api.metro.net/agencies/lametro/vehicles/' + item['route_id'] + '/runs/' + item['run_id'] + '/'
    }
      
    # Should return ONE item, the route and run
    runItem = null
    SpyGlass::Registry << SpyGlass::Client::Socrata.new(routeOpts) do |collection|
      runItem = collection.values[0].map do |item|
      end
    end
      
    title = <<-TITLE.oneline
    #{SpyGlass::Salutations.next} Vehicle no. #{item['id']} on route: #{runItem[0]['display_name']};.
    Last reported #{item['seconds_since_report']} seconds ago.
    TITLE
      
    {
      'id' => item['id'],
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
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
