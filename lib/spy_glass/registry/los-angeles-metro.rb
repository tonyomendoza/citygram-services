require 'spy_glass/registry'

opts = {
  path: '/los-angeles-metro',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'http://api.metro.net/agencies/lametro/vehicles/?'+Rack::Utils.build_query({
    '$where' => <<-WHERE.oneline
      id = IS NOT NULL AND
      heading IS NOT NULL AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      predictable = true 
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
    features = collection.values[0].map do |item|
     
     routeOpts = {
      path: '/los-angeles-metro',
      cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
      source: 'http://api.metro.net/agencies/lametro/routes/' + item['route_id'] + '/runs/' + item['run_id'] + '/?'+Rack::Utils.build_query({
        '$where' => <<-WHERE.oneline
          id = IS NOT NULL
        WHERE
  })
    }
      
    # Should return ONE item, the route and run
    SpyGlass::Registry << SpyGlass::Client::Socrata.new(routeOpts) do |runCollection|
      runFeatures = runCollection.values[0].map do |rItem|
      end
    end
    
    title = <<-TITLE.oneline
    #{SpyGlass::Salutations.next} Vehicle no. #{item['id']} on route #{item['route_id']} and run #{item['run_id']}.
    Last reported #{item['seconds_since_report']} seconds ago. 
    TITLE
    if runCollection.nil?
      title = title + "Could not find name of route." + 'http://api.metro.net/agencies/lametro/routes/' + item['route_id'] + '/runs/' + item['run_id'] + '/'
    else
      #title = title + runCollection[0]['id']
    end
      
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
