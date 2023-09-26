FROM registry.gitlab.com/jack-joe-open-source/docker-images/elixir-phx AS builder

ARG MIX_ENV=prod
ENV PORT ${PORT:-5050}
ENV HOST ${HOST:-localhost}

# Create and set home directory
ENV HOME /opt/app
WORKDIR $HOME

# Copy all application files
COPY . ./

# Install all production dependencies + digest
RUN mix deps.get --only prod && \
    mix deps.compile --include-children && \
    mix phx.digest

RUN mix release production

##################################################

FROM registry.gitlab.com/jack-joe-open-source/docker-images/alpine

ARG APP_VSN
ARG APP_NAME
ARG MIX_ENV=prod

# Env vars
# Create and set home directory
ENV HOME /opt/app
ENV APP_NAME $APP_NAME
ENV PORT ${PORT:-5050}

WORKDIR $HOME
EXPOSE $PORT

COPY --from=builder $HOME/_build/$MIX_ENV/rel/production $HOME
COPY --from=builder $HOME/script/wait-for $HOME

COPY rel/start.sh .
RUN chmod +x $HOME/start.sh
RUN chmod +x $HOME/wait-for

HEALTHCHECK --interval=3s --timeout=3s --retries=10 CMD curl --fail -s http://localhost:$PORT/health || exit 1

ENTRYPOINT ["/opt/app/start.sh"]
