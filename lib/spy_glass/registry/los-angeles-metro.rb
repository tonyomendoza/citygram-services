require 'spy_glass/registry'
require 'faraday'
require 'json'

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
    
      
      #source: "http://api.metro.net/agencies/lametro/routes/#{item['route_id']}/runs/#{item['run_id']}/"
     
    routeOpts = {
      path: '/los-angeles-metro-rail',
      cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
      source: "http://api.metro.net/agencies/lametro/routes/#{item['route_id']}/runs/#{item['run_id']}/"
    }

      $run = nil
      SpyGlass::Registry << SpyGlass::Client::Socrata.new(routeOpts) do |routeCollection|
      features = routeCollection.values[0].map do |item|
        $run = item
        {
          'id' => item['id'],
          'properties' => item.merge('title' => item['id'])
        }
      end
      {'type' => 'FeatureCollection', 'features' => features}
    end
      
    title = <<-TITLE.oneline
    #{SpyGlass::Salutations.next} Vehicle no. #{item['id']} on route #{item['route_id']} and run #{item['run_id']}.
    Last reported #{item['seconds_since_report']} seconds ago. #{$run.nil?}
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
