require 'spy_glass/registry'

opts = {
  path: '/los-angeles-metro-rail',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'http://api.metro.net/agencies/lametro-rail/vehicles/?'
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
    features = collection.values[0].map do |item|

    title = "#{SpyGlass::Salutations.next} Vehicle no. #{item['id']} on route #{item['route_id']}"

    # Set up JSON here
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
      'properties' => item.merge('title' => title),
      'route' => {
        }
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
