require 'net/http'
require 'json'

class V1::ApiController < ApplicationController
	# include Error:ErrorHandler
	rescue_from Error::GoogleApiError, with: :render_server_unavailable
	rescue_from Error::RequestParamsError, with: :render_bad_params

	def	search
		# TODO Give user option to specify which kind of search to do.

		# TODO See if the OmniAuth gem can make token auth easier
		# TODO Decide which params are valid to send to Google
		# TODO might want to add support for paginization and pagetoken
		# TODO add OpenAPI for API

		result = query_google_places

		render :json => result
	end

	def	photo_lookup
		if !params.include?(:photo_reference)
			raise Error::RequestParamsError
		end


		img_data = get_google_photo
		send_data img_data.body, :filename => 'temp.jpg', :type => 'image/jpeg'
	end

	private
		def query_google_places
			if !params.include?(:location)
				raise Error::RequestParamsError
			end

			search_type = 'nearbysearch'
			#TODO add support for photo sizes using the Google Place photos endpoint?

			if params.include?(:query)
				search_type = 'textsearch'
				query_params = params.permit(:query, :location, :maxprice, :minprice, :opennow, :radius)
			else
				query_params = params.permit(:location, :maxprice, :minprice, :opennow, :radius)
			end

			# Filter to only restaurants
			query_params['type'] = 'restaurant'

			places_endpoint = "https://maps.googleapis.com/maps/api/place/#{search_type}/json"
			json_response = http_get_google_endpoint(places_endpoint, query_params).body
			processed_response = process_google_places_response(json_response)

			return processed_response
		end

		def process_google_places_response(json_response)
			hashed_response = JSON.parse(json_response)
			puts hashed_response["status"]
			filter_fields = ["business_status", "formatted_address",
				 "formatted_phone_number", "geometry", "name", "opening_hours",
				 "photos", "plus_code", "price_level", "rating",
				 "user_ratings_total","website", "vicinity"]
			if hashed_response['status'].downcase == 'ok'
				filtered_response = hashed_response['results'].map { |result|
					filtered_result = result.slice(*filter_fields)
					filtered_result['photos'] = set_photo(filtered_result)
					filtered_result
				}
			elsif hashed_response['status'].downcase != 'zero_results'
				return []
			else
				raise Error::GoogleApiError
			end

			return filtered_response
		end

		def set_photo(result)
			# See https://developers.google.com/maps/documentation/places/web-service/search-find-place#PlacePhoto
			# for more information on the 'photo_info' structure
			if result.include?("photos")
				result["photos"].map { |photo_info|

					photo_url_params = photo_info.slice("photo_reference")
					{"html_attributions": photo_info["html_attributions"], "photo_url": "#{v1_photo_lookup_url}?#{photo_url_params.to_query}"}
				}
			else
				{"html_attributions": [], "photo_url": ""}
			end
		end

		def get_google_photo
			photos_endpoint = "https://maps.googleapis.com/maps/api/place/photo"
			query_params = params.permit(:photo_reference, :maxwidth, :maxheight).to_h
			if !query_params.include?(:maxwidth) && !query_params.include?(:maxheight)
				query_params['maxwidth'] = 400
			end
			response = http_get_google_endpoint(photos_endpoint, query_params)
			return response
		end

		def render_server_unavailable
			render json: { message: 'Server unavailable, try again later'}, status: :service_unavailable
		end

		def render_bad_params
			render json: { message: 'One or more parameters is not valid'}, status: :bad_request
		end

		def http_get_google_endpoint(url, query_params)
			query_params['key'] = Rails.application.credentials.google[:places_api_key]

			url = "#{url}?#{query_params.to_query}"
			uri = URI(url)
			puts uri

			# Kludge to deal with redirects in the case Places Photos
			begin
				response = Net::HTTP.get_response(URI.parse(url))
				url = response['location']
			end while response.is_a?(Net::HTTPRedirection)
			response
		end
end
