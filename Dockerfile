FROM jackjoe/elixir-phx AS builder

ARG BUILD_ENV
ARG DEPLOY_ENV
ARG MIX_ENV=prod

# Create and set home directory
ENV HOME /opt/app
WORKDIR $HOME

# Copy all application files
COPY . ./

# Install all production dependencies
RUN source .env.$DEPLOY_ENV && \
    mix deps.get --only $BUILD_ENV && \
    mix deps.compile --include-children

# Compile the entire project
RUN source .env.$DEPLOY_ENV && \
    yarn install --pure-lockfile && \
    make _build_production_js && \
    make _build_production_styles && \
    mix phx.digest

RUN cat .env.$DEPLOY_ENV

RUN source .env.$DEPLOY_ENV && \
    mix release production

##################################################

FROM jackjoe/alpine

ARG APP_VSN
ARG APP_NAME
ARG BUILD_ENV
ARG DEPLOY_ENV
ARG MIX_ENV=prod

# Env vars
# Create and set home directory
ENV HOME /opt/app
ENV APP_NAME $APP_NAME
ENV PORT ${PORT:-5050}

WORKDIR $HOME
EXPOSE $PORT

COPY --from=builder $HOME/_build/$MIX_ENV/rel/production $HOME

ADD rel/start.sh .
RUN chmod +x $HOME/start.sh

HEALTHCHECK --interval=3s --timeout=3s --retries=10 CMD curl --fail -s http://localhost:$PORT/health || exit 1

ENTRYPOINT ["/opt/app/start.sh"]
