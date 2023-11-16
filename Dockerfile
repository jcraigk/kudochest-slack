FROM ruby:3.2.2-slim

ARG APP_NAME=biz-kudochest

ENV APP_NAME=${APP_NAME} \
    INSTALL_PATH=/${APP_NAME} \
    IN_DOCKER=true

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      # libmagickwand-dev \ # TODO: Re-enable graphical responses
      libpq-dev \
      memcached \
      postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*;

# TODO: Re-enable graphical responses
# COPY lib/image_magick/policy.xml /etc/ImageMagick-6/policy.xml
# RUN mkdir -p /storage/response_images/cache
# RUN mkdir -p /storage/response_images/tmp

WORKDIR $INSTALL_PATH

COPY . .

RUN gem install bundler && bundle install
RUN bundle exec rake assets:precompile

EXPOSE 3000
CMD bundle exec puma -p 3000
