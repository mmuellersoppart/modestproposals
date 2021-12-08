FROM swift:5.5

WORKDIR /package

COPY . ./

CMD ["swift", "test", "--enable-test-discovery"]

