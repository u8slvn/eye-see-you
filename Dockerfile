# Build stage
FROM elixir:1.15-alpine AS builder

RUN apk add --no-cache build-base git
WORKDIR /app
RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
ENV MIX_ENV=prod
RUN mix deps.get --only=prod
RUN mix deps.compile

COPY lib ./lib
RUN mix release

# --- Runtime Stage ---
FROM alpine:3.18

RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++ \
    libgcc \
    && addgroup -g 1001 -S monitor \
    && adduser -u 1001 -S monitor -G monitor

COPY --from=builder --chown=monitor:monitor /app/_build/prod/rel/eye_see_you /opt/eye_see_you

USER monitor
WORKDIR /opt/eye_see_you

ENV URLS=""
ENV CHECK_INTERVAL="300"
ENV SMTP_SERVER=""
ENV SMTP_PORT="587"
ENV EMAIL_USER=""
ENV EMAIL_PASSWORD=""
ENV RECIPIENT_EMAIL=""
ENV REPLACE_OS_VARS=true
ENV RELEASE_DISTRIBUTION=name
ENV RELEASE_NODE=eye_see_you@localhost

CMD ["bin/eye_see_you", "start"]
