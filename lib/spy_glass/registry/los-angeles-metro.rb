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

    title = "#{SpyGlass::Salutations.next} Bus no. #{item['id']} on route #{item['route_id']}"

    # Returns the run
    routeUrl = URI("http://api.metro.net/agencies/lametro/routes/#{item['route_id']}/runs/#{item['run_id']}/")
    routeConnection = Faraday.new(url: routeUrl.to_s)
    routeResponse = routeConnection.get
    route = JSON.parse(routeResponse.body)

    hasRoute = true
    if !route["message"].nil?
        if route["message"].include? "no run with that id"
            hasRoute = false
            route.store("display_name", "")
            route.store("direction_name", "")
            title = title + ", an undetermined run (#{item['run_id']})."
        end
    else
        route.store("message", "")
        title = title + ", run #{route['display_name']}."
    end

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
        'direction_name' => route['direction_name'],
        'display_name' => route['display_name']
        }
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
