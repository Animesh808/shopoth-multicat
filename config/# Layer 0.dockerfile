# Layer 0. Download base ruby image.
ARG RUBY_VERSION=3.1.3
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Layer 2. Creating environment variables which used further in Dockerfile.
ENV APP_HOME /shopoth-multicat

# Layer 3. Adding config options for bundler.
RUN echo "gem: --no-rdoc --no-ri" > /etc/gemrc

# Layer 4. Creating and specifying the directory in which the application will be placed.
WORKDIR $APP_HOME

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base as build

# Layer 1. Updating and installing the necessary software for the Web server. Cleansing to reduce image size.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips pkg-config

# Layer 5. Copying Gemfile and Gemfile.lock.
COPY Gemfile Gemfile.lock ./

# Layer 6. Installing dependencies.
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile


# Layer 7. Copying full application.
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build $APP_HOME $APP_HOME

# Run and own only the runtime files as a non-root user for security
RUN useradd shopoth-multicat --create-home --shell /bin/bash && \
    chown -R shopoth-multicat:shopoth-multicat db log storage tmp
USER shopoth-multicat:shopoth-multicat

# Layer 8. Make file executable
RUN chmod +x ./dev-docker-entrypoint.sh

# Layer 9. Run migrations
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Layer 10. Command to run application.
CMD ["rails", "s", "-p", "8000", "-b", "0.0.0.0"]
