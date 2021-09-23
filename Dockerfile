FROM ruby:3.0.0

RUN apt-get update -qq && apt-get install -y postgresql-client

ADD . /usr/src/app
WORKDIR /usr/src/app
RUN bundle install

# Add a script to be executed every time the container starts.
# This script fixes a rail issue see https://docs.docker.com/samples/rails/
COPY entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]