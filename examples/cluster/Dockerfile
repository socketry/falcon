ARG RUBY_VERSION=4.0
FROM ruby:${RUBY_VERSION}

WORKDIR /code

ENV BUNDLE_GEMFILE=/code/gems.rb

COPY gems.rb .

RUN bundle install

COPY . .

CMD ["bundle", "exec", "async-service", "falcon.rb"]
