FROM ruby:3.0.2

RUN apt-get update -qq && apt-get install -y postgresql-client