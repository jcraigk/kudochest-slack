FROM ruby:3.2.2-slim

ARG APP_NAME=biz-kudochest

ENV APP_NAME=${APP_NAME} \
    INSTALL_PATH=/${APP_NAME} \
    IN_DOCKER=true

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libmagickwand-dev \
      libpq-dev \
      memcached \
      postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*;

# Response images
COPY lib/image_magick/policy.xml /etc/ImageMagick-6/policy.xml
RUN mkdir -p /storage/response_images/cache
RUN mkdir -p /storage/response_images/tmp

WORKDIR $INSTALL_PATH

COPY . .

RUN apt-get update -qq && apt-get install -y nodejs npm
RUN npm install -g yarn

RUN gem install bundler && bundle install
RUN bundle exec rails webpacker:install
RUN bundle exec rake assets:precompile

EXPOSE 3000
CMD bundle exec puma -p 3000
