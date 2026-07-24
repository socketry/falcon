ARG RUBY_VERSION=4.0
FROM ruby:${RUBY_VERSION}

WORKDIR /code

ENV BUNDLE_GEMFILE=/code/examples/cluster/gems.rb

COPY . .

RUN bundle install

CMD ["bundle", "exec", "async-service", "examples/cluster/falcon.rb"]
