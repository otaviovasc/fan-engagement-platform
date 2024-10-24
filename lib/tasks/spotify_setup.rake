# lib/tasks/spotify_setup.rake
namespace :spotify do
  desc 'Fetch and store all artists from Spotify'
  task setup_artists: :environment do
    require 'httparty'

    # Define how many artists to fetch per request
    limit = 50  # Spotify API typically limits the number of items per call
    eu = User.find_by(display_name: "Otávio Vasconcelos")
    eu.refresh_access_token unless eu.access_token_valid?
    access_token = eu.access_token  # Replace this with how you manage access tokens
    # search_queries = ['rock', 'pop', 'hip-hop', 'jazz']
    # search_queries = ['indie', 'funk', 'reggae', 'phonk', '']  # Example genres or keywords
    search_queries = [
      "sertanejo",
      "pagode",
      "samba",
      "bossa Nova",
      "forró",
      "MPB",
      "axé",
      "funk",
      "samba-Rock",
      "choro",
      "carimbó",
      "forró Eletrônico",
      "brega",
      "lambada",
      "Gospel",
      "Rap",
      "Rap Nacional",
      "Trap",
      "Trap Brasileiro",
      "Sertanejo Universitário",
      "Sertanejo Raiz",
      "Brega Funk",
      "Arrocha",
      "Metal",
      "indie",
      "reggae",
      "Drum and Bass",
      "Dub",
      "Dubstep",
      "EDM",
      "Electro",
      "Electronic",
      "Brazilian",
      "Acoustic",
    ]

    search_queries.each do |search_query|
      offset = 0

      loop do
        response = HTTParty.get(
          "https://api.spotify.com/v1/search",
          query: {
            q: search_query,
            type: 'artist',
            limit: limit,
            offset: offset
          },
          headers: { 'Authorization' => "Bearer #{access_token}" }
        )

        if response.code != 200
          puts "Spotify API error: #{response.body}"
          break
        end

        artists = response.parsed_response['artists']['items']
        break if artists.empty?

        artists.each do |artist_data|
          Artist.find_or_create_by(spotify_id: artist_data['id']) do |artist|
            artist.name = artist_data['name']
            artist.image_url = artist_data['images'].first['url'] if artist_data['images'].any?
            puts "Created artist: #{artist.name}"
          end
        end

        offset += limit
      end
    end
  end
end
