require 'net/http'
require 'json'

class V1::ApiController < ApplicationController
	before_action :authenticate_user!

	rescue_from Error::GoogleApiError, with: :render_server_unavailable
	rescue_from Error::RequestParamsError, with: :render_bad_params

	# TODO might want to add support for paginization and pagetoken in the future

	def	search
		result = query_google_places
		render :json => result
	end

	def	photo_lookup
		img_data = get_google_photo
		send_data img_data.body, :type => 'image/jpeg'
	end

	private
		PLACES_FILTER_FIELDS = ["business_status", "formatted_address",
				"formatted_phone_number", "geometry", "name", "opening_hours",
				"photos", "plus_code", "price_level", "rating",
				"user_ratings_total","website", "vicinity"]

		def query_google_places
			if !(params.include?(:location) && params.include?(:radius))
				raise Error::RequestParamsError
			end

			search_type = 'nearbysearch'

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

		def get_google_photo
			if !params.include?(:photo_reference)
				raise Error::RequestParamsError
			end

			photos_endpoint = "https://maps.googleapis.com/maps/api/place/photo"
			query_params = params.permit(:photo_reference, :maxwidth, :maxheight).to_h

			# Give defaults for maxwidth and maxheight
			if !query_params.include?(:maxwidth) && !query_params.include?(:maxheight)
				query_params['maxwidth'] = 400
				query_params['maxheight'] = 400
			end

			response = http_get_google_endpoint(photos_endpoint, query_params)
			return response
		end

		def http_get_google_endpoint(url, query_params)
			query_params['key'] = Rails.application.credentials.google[:places_api_key]

			url = "#{url}?#{query_params.to_query}"
			puts url

			# Kludge to deal with redirects in the case of Places Photos
			begin
				response = Net::HTTP.get_response(URI.parse(url))
				url = response['location']
			end while response.is_a?(Net::HTTPRedirection)
			response
		end

		def process_google_places_response(json_response)
			response_hash = JSON.parse(json_response)
			puts response_hash["status"]

			if response_hash['status'].downcase == 'ok'
				get_processed_results(response_hash)
			elsif response_hash['status'].downcase == 'zero_results'
				[]
			elsif response_hash['status'].downcase == 'invalid_request'
				raise Error::RequestParamsError
			else
				raise Error::GoogleApiError
			end
		end

		def get_processed_results(response_hash)
			filtered_response = response_hash['results'].map { |result|
				filtered_result = result.slice(*PLACES_FILTER_FIELDS)
				filtered_result['photos'] = set_photo(filtered_result)
				filtered_result
			}

			filtered_response
		end

		def set_photo(result)
			# See https://developers.google.com/maps/documentation/places/web-service/search-find-place#PlacePhoto
			# for more information on the 'photo_info' structure
			if result.include?("photos")
				result["photos"].map { |photo_info|
					photo_url_params = photo_info.slice("photo_reference")

					{
						"html_attributions": photo_info["html_attributions"],
						"photo_url": "#{v1_photo_lookup_url}?#{photo_url_params.to_query}"
					}
				}
			else
				{"html_attributions": [], "photo_url": ""}
			end
		end

		def render_server_unavailable
			render json: { message: 'Server unavailable, try again later'}, status: :service_unavailable
		end

		def render_bad_params
			render json: { message: 'One or more parameters is not valid'}, status: :bad_request
		end
end
