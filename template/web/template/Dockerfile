FROM ocaml/opam2:alpine as build

# Install system dependencies
RUN sudo apk add --update \
    make libffi-dev linux-headers m4 ncurses-dev perl pkgconf postgresql-dev \
    musl-dev git pkgconfig gmp-dev npm nodejs

RUN eval $(opam env) && opam update

WORKDIR /build
RUN sudo chown -R $(whoami) /build

# Install dependencies
ADD demo.opam demo.opam
RUN eval $(opam env) && opam install --deps-only .

# Build project
ADD . .
ADD dune dune-project Makefile ./

RUN sudo chown -R $(whoami) .

RUN eval $(opam env) && cd asset && DEMO_ENV=prod npm install
RUN eval $(opam env) && make

FROM alpine:3.12 as docker

RUN apk add --update gmp libpq

COPY --from=build /build/_build/default/bin/server.exe /bin/server

ENTRYPOINT /bin/server
EXPOSE 3000
