# Installation

Dependencies Docker and Docker-Compose installed and available.
	Ruby and Rails versions are defined in the Dockerfile but don't need to be modified

In a terminal where the current working directory is this application's repo, referred to as `search-api` from here on forward, perform the following steps:
1. Copy the **.env** file that I will provide to the top level of the git repo. 
The file would be at `search-api/.env`
1. Run `docker-compose up` in `search-api`
1. In a separate terminal in the same directory run `docker-compose run web rake db:create` and then `docker-compose run web rake db:migrate`
1. The application homepage should now be available at http://localhost:3003 but since it's primarily an Rails API application there won't be viewable web pages at the endpoints.





# Using the API
Note because of authentication requirements any HTTP request will fail with an unauthorized response. To remedy this
see the [authentication section](#Authentication) below for how to authenticate. Ideally there is a Postman collection that allows you go through the API
usage flow.

## Restaurant Search API (/v1/search)
The restaurant search API endpoint can be found at http://localhost:3003/v1/search

## Restaurant Search API (/v1/photo_lookup)

The Google Places Photos endpoint doesn't appear to support requesting a photo_url. They return an id labeled *photo_reference*
which can be used to create a query that would retrieve a photo. Unfortunately the query to retrieve the photo
includes the API key as query params and therefore I decided, for security reasons, to create a photo lookup api that 
does not expose the API key.

Instead the api at /v1/photo_lookup takes the same parameters that the google photo api would use but without the API key visible

Rather than having something like the following:
```
"photo_url": {google_photos_endpoint}?key={API-key}&{rest-of-params}....
```
we have a call that hides this information
```
"photo_url": localhost:3003/v1/photo_lookup?{rest-of-params}
```
 where the API key is still hidden but in the backend there is a call to the Google API

# Authentication

This application uses devise-token-auth for authentication.
See https://devise-token-auth.gitbook.io/devise-token-auth/usage for general usage

Below is information on how to successfully place an API call for the search endpoints. You will need the following 4 authorization headers
- access-token
- client
- expiry
- uid

Of these 4 the headers, *access-token* and *expiry*, will expire and have to rotated out with new values from the response of each api call to the search endpoints

A user can be created by sending a POST call `localhost:3003/auth/` and providing the following fields:
- email
- password
- password_confirmation
- confirm_success_url

The response to user creation will include the authorization headers in the response headers.

If you lose the authentication headers you can retrieve new authorization headers by doing a POST to `localhost:3003/auth/sign_in` with **email** and **password** as params. Make sure you update the following headers (uid should stay the same) if you have an existing api call template:
- client
- expiry
- access-token