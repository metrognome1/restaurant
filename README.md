# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

## Installation
You will need Docker and Docker-compose

Ruby and Rails versions are defined in the Dockerfile but don't need to be modified

* Database creation
TODO database creation and initialization for Docker

## Authenticatin

This application uses devise-token-auth for authentication.
To successfully place an API call for the search endpoints you will need the following 4 authorization headers
- access-token
- client
- expiry
- uid

Of these 4 the headers, *access-token* and *expiry*, will expire and have to rotated out with new values from the response of a successful api-call

A user can be created by sending a POST call `#{application_path}/auth/` and providing the following fields:
- email
- password
- password_confirmation
- confirm_success_url

If you lose the authentication headers you can retrieve new authorization headers by doing a POST to `#{application_path}/auth/sign_in` with **email** and **password** as params. Make sure you update the following headers (uid should stay the same):
- client
- expiry
- access-token