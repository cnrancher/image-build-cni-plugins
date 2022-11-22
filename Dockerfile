ARG ARCH="amd64"
ARG TAG="v0.9.1"
ARG BCI_IMAGE=registry.suse.com/bci/bci-base:15.4.27.14.13
ARG GO_IMAGE=hub.oepkgs.net/rfolabs/hardened-build-base:v1.17.13

### Build the cni-plugins ###
FROM ${GO_IMAGE} as cni_plugins
ARG ARCH
ARG TAG
RUN git clone --depth=1 https://github.com/containernetworking/plugins.git $GOPATH/src/github.com/containernetworking/plugins \
    && cd $GOPATH/src/github.com/containernetworking/plugins \
    && git fetch --all --tags --prune \
    && git checkout tags/${TAG} -b ${TAG} \
    && sh -ex ./build_linux.sh -v \
    -gcflags=-trimpath=/go/src \
    -ldflags " \
        -X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=${TAG} \
        -linkmode=external -extldflags \"-static -Wl,--fatal-warnings\" \
    "
WORKDIR $GOPATH/src/github.com/containernetworking/plugins
RUN mkdir -vp /opt/cni/bin \
    && install -D -s bin/* /opt/cni/bin

# Create image with the cni-plugins
FROM ${BCI_IMAGE}
COPY --from=cni_plugins /opt/cni/ /opt/cni/
WORKDIR /
COPY install-cnis.sh .
ENTRYPOINT ["./install-cnis.sh"]
