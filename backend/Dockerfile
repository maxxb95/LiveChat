FROM ruby:3.2.2-slim

WORKDIR /rails

# Install dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install bundler
RUN gem install bundler

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy application code
COPY . .

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]