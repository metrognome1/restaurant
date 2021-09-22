## Installation
You will need Docker and Docker-compose

Ruby and Rails versions are defined in the Dockerfile but don't need to be modified

* Database creation
TODO database creation and initialization for Docker

## Quirks in the Application

The Google Places Photos endpoint doesn't appear to support requesting a photo_url. They have a photo_reference
which can be used to create a query that would retrieve a photo. Unforutnately the query to retrieve the photo
includes the API key as query params and therefore I decided for security reasons not to leave the API key
exposed by creating a photot lookup endpoint within this same application and placing that in the response to
our regular search API

Rather than having something like the following:
	...
	"photo_url": {google_photos_endpoitn}?key={API-key}&{rest-of-params}....
	...
we have a proxy call
	...
	"photo_url": {this_application_endpoint}/v1/photo_lookup?{rest-of-params}
	...
 where the API key is still hidden but in the backend there is a call to the Google API

## Authenticating

This application uses devise-token-auth for authentication.
See https://devise-token-auth.gitbook.io/devise-token-auth/usage for general usage

Below is information on
To successfully place an API call for the search endpoints you will need the following 4 authorization headers
- access-token
- client
- expiry
- uid

Of these 4 the headers, *access-token* and *expiry*, will expire and have to rotated out with new values from the response of a successful api call

A user can be created by sending a POST call `#{application_path}/auth/` and providing the following fields:
- email
- password
- password_confirmation
- confirm_success_url

The response to user creation will include the authorization headers in the response headers.

If you lose the authentication headers you can retrieve new authorization headers by doing a POST to `#{application_path}/auth/sign_in` with **email** and **password** as params. Make sure you update the following headers (uid should stay the same) if you have an existing api call template:
- client
- expiry
- access-token