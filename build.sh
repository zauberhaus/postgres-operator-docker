#/bin/sh

VERSION=`cat version.txt | sed -e 's/-.*$//'`
REPO=https://github.com/CrunchyData/postgres-operator.git
ARCHS="arm64 armv6 armv7 s390x ppc64le amd64 386"

if [ ! -d ./src ]; then
    git clone --depth=1 --single-branch --branch ${VERSION} ${REPO} src
    cd src 
    echo "Checkout tag $VERSION" 
    if [ "$VERSION" != "main" ] && [ ! -z "$VERSION" ] ; then git checkout tags/${VERSION} -b $VERSION; fi
    #cp ../auth.go cmd/postgres-operator
    go mod tidy
else
    cd src
fi

mkdir -p ../build

FLAGS="-X 'main.versionString=${VERSION}' -w -s"

export CGO_ENABLED=0
export GOOS=linux

for arch in $ARCHS ; do
    if expr "$arch" : "armv6$" 1>/dev/null; then
        export GOARCH=arm 
        export GOARM=6
    elif expr "$arch" : "armv7$" 1>/dev/null; then
        export GOARCH=arm
        export GOARM=7
    else 
        export GOARCH=$arch
    fi

    echo "Build pgo.$arch $VERSION" 
    go build -o ../build/postgres-operator.$arch -ldflags "$FLAGS" ./cmd/postgres-operator
    go build -o ../build/apiserver.$arch -ldflags "$FLAGS" ./cmd/apiserver
    go build -o ../build/pgo.$arch -ldflags "$FLAGS" ./cmd/pgo
    go build -o ../build/pgo-rmdata.$arch -ldflags "$FLAGS" ./cmd/pgo-rmdata
    go build -o ../build/pgo-scheduler.$arch -ldflags "$FLAGS" ./cmd/pgo-scheduler    

    if [ "$arch" != "s390x" ] ; then
        for i in ../build/*.${arch} ; do upx $i; done    
    fi
done

