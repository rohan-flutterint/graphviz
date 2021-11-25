#!/usr/bin/env bash

set -x
set -e
set -u
set -o pipefail

if [ -f /etc/os-release ]; then
    cat /etc/os-release
    . /etc/os-release
    if [ "${OSTYPE}" = "msys" ]; then
        # MSYS2/MinGW doesn't have VERSION_ID in /etc/os-release
        VERSION_ID=$( uname -r )
    fi
else
    ID=$( uname -s )
    # remove trailing text after actual version
    VERSION_ID=$( uname -r | sed "s/\([0-9\.]*\).*/\1/")
fi
META_DATA_DIR=Metadata/${ID}/${VERSION_ID}
mkdir -p ${META_DATA_DIR}
DIR=$(pwd)/Packages/${ID}/${VERSION_ID}
mkdir -p ${DIR}
ARCH=$( uname -m )
build_system=${build_system:-autotools}
if [ "${build_system}" = "cmake" ]; then
    mkdir build
    pushd build
    cmake --log-level=VERBOSE ${CMAKE_OPTIONS:-} ..
    cmake --build .
    cpack
    popd
    if [ "${OSTYPE}" = "linux-gnu" ]; then
        GV_VERSION=$(python3 gen_version.py)
        if [ "${ID_LIKE:-}" = "debian" ]; then
            mv build/Graphviz-${GV_VERSION}-Linux.deb ${DIR}/graphviz-${GV_VERSION}-cmake.deb
        else
            mv build/Graphviz-${GV_VERSION}-Linux.rpm ${DIR}/graphviz-${GV_VERSION}-cmake.rpm
        fi
    elif [[ "${OSTYPE}" =~ "darwin" ]]; then
        mv build/*.zip ${DIR}/
    elif [ "${OSTYPE}" = "msys" ]; then
        mv build/*.zip ${DIR}/
        mv build/*.exe ${DIR}/
    elif [[ "${OSTYPE}" =~ "cygwin" ]]; then
        mv build/*.zip ${DIR}/
        mv build/*.tar.bz2 ${DIR}/
    else
        echo "Error: OSTYPE=${OSTYPE} is unknown" >&2
        exit 1
    fi
elif [[ "${CONFIGURE_OPTIONS:-}" =~ "--enable-static" ]]; then
    GV_VERSION=$( cat GRAPHVIZ_VERSION )
    tar xfz graphviz-${GV_VERSION}.tar.gz
    pushd graphviz-${GV_VERSION}
    ./configure --enable-lefty $CONFIGURE_OPTIONS --prefix=$( pwd )/build | tee >(../ci/extract-configure-log.sh >../${META_DATA_DIR}/configure.log)
    make
    make install
    popd
else
    GV_VERSION=$( cat GRAPHVIZ_VERSION )
    if [ "$OSTYPE" = "linux-gnu" ]; then
        if [ "${ID_LIKE:-}" = "debian" ]; then
            tar xfz graphviz-${GV_VERSION}.tar.gz
            (cd graphviz-${GV_VERSION}; fakeroot make -f debian/rules binary) | tee >(ci/extract-configure-log.sh >${META_DATA_DIR}/configure.log)
            tar cf - *.deb *.ddeb | xz -9 -c - >${DIR}/graphviz-${GV_VERSION}-debs.tar.xz
        else
            rm -rf ${HOME}/rpmbuild
            rpmbuild -ta graphviz-${GV_VERSION}.tar.gz | tee >(ci/extract-configure-log.sh >${META_DATA_DIR}/configure.log)
            pushd ${HOME}/rpmbuild/RPMS
            mv */*.rpm ./
            tar cf - *.rpm | xz -9 -c - >${DIR}/graphviz-${GV_VERSION}-rpms.tar.xz
            popd
        fi
    elif [[ "${OSTYPE}" =~ "darwin" ]]; then
        ./autogen.sh
        ./configure --enable-lefty --prefix=$( pwd )/build --with-quartz=yes
        make
        make install
        tar cfz graphviz-${GV_VERSION}-${ARCH}.tar.gz --options gzip:compression-level=9 build
        mv graphviz-${GV_VERSION}-${ARCH}.tar.gz ${DIR}/
    elif [ "${OSTYPE}" = "cygwin" ]; then
        if [ "${use_autogen:-no}" = "yes" ]; then
            ./autogen.sh
            ./configure --prefix=$( pwd )/build | tee >(./ci/extract-configure-log.sh >${META_DATA_DIR}/configure.log)
            make
            make install
            tar cf - -C build . | xz -9 -c - > graphviz-${GV_VERSION}-${ARCH}.tar.xz
            mv graphviz-${GV_VERSION}-${ARCH}.tar.xz ${DIR}/
        else
            tar xfz graphviz-${GV_VERSION}.tar.gz
            pushd graphviz-${GV_VERSION}
            ./configure --prefix=$( pwd )/build | tee >(../ci/extract-configure-log.sh >../${META_DATA_DIR}/configure.log)
            make
            make install
            popd
            tar cf - -C graphviz-${GV_VERSION}/build . | xz -9 -c - > graphviz-${GV_VERSION}-${ARCH}.tar.xz
            mv graphviz-${GV_VERSION}-${ARCH}.tar.xz ${DIR}/
        fi
    else
        echo "Error: OSTYPE=${OSTYPE} is unknown" >&2
        exit 1
    fi
fi
