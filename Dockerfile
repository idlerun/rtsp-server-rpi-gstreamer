FROM raspbian/stretch as build
ENV DEBIAN_FRONTEND=noninteractive
ENV TARGET_DIR=/opt/gstreamer
ENV PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig"
ENV PATH=$TARGET_DIR:$TARGET_DIR/bin:$PATH
RUN mkdir -p /src $TARGET_DIR/lib/pkgconfig
ENV SRC_DIR=/src

RUN apt-get update
RUN apt-get install -y \
    wget git libtool autoconf \
    cmake build-essential pkg-config\
    patchelf
WORKDIR $SRC_DIR

RUN apt-get install -y \
    libasound2-dev autopoint bison flex python3 libglib2.0-dev gettext


FROM build as dep-gstreamer
RUN git clone --depth 1 --branch 1.14 git://anongit.freedesktop.org/git/gstreamer/gstreamer
WORKDIR /src/gstreamer
RUN ./autogen.sh --noconfigure
RUN ./configure --prefix=$TARGET_DIR --disable-check --disable-tests --disable-examples --disable-benchmarks --disable-debug
RUN make -j4
RUN make install


FROM build as dep-openssl
RUN wget -q https://www.openssl.org/source/openssl-1.1.1a.tar.gz
RUN tar xf openssl-1.1.1a.tar.gz
WORKDIR /src/openssl-1.1.1a
RUN ./config shared --prefix=$TARGET_DIR
RUN make -j4
RUN make install


FROM build as dep-x264
RUN git clone --depth 1 --branch stable https://code.videolan.org/videolan/x264.git
WORKDIR /src/x264
RUN ./configure --prefix=$TARGET_DIR --enable-shared --disable-opencl --enable-pic
RUN make -j4
RUN make install


FROM build as dep-plugins-base
COPY --from=dep-gstreamer $TARGET_DIR $TARGET_DIR
COPY --from=dep-openssl $TARGET_DIR $TARGET_DIR
COPY --from=dep-x264 $TARGET_DIR $TARGET_DIR
RUN git clone --depth 1 --branch 1.14 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-base
WORKDIR /src/gst-plugins-base
RUN ./autogen.sh --noconfigure
RUN ./configure --prefix=$TARGET_DIR --disable-examples --disable-debug
RUN make -j4
RUN make install
WORKDIR /src


FROM dep-plugins-base as dep-plugins-good
RUN git clone --depth 1 --branch 1.14 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-good
WORKDIR /src/gst-plugins-good
RUN ./autogen.sh --noconfigure
RUN ./configure --prefix=$TARGET_DIR --disable-examples --disable-debug
RUN make -j4
RUN make install


FROM dep-plugins-base as dep-plugins-bad
RUN git clone --depth 1 --branch 1.14 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-bad
WORKDIR /src/gst-plugins-bad
RUN ./autogen.sh --noconfigure
RUN ./configure --prefix=$TARGET_DIR --disable-examples --disable-debug
RUN make -j4
RUN make install


FROM dep-plugins-base as dep-plugins-ugly
RUN git clone --depth 1 --branch 1.14 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-ugly
WORKDIR /src/gst-plugins-ugly
RUN ./autogen.sh --noconfigure
RUN ./configure --prefix=$TARGET_DIR --disable-examples --disable-debug
RUN make -j4
RUN make install


FROM dep-plugins-base as dep-gst-rtsp
RUN git clone --depth 1 --branch 1.14 git://anongit.freedesktop.org/git/gstreamer/gst-rtsp-server
WORKDIR /src/gst-rtsp-server
RUN ./autogen.sh --noconfigure
RUN ./configure --prefix=$TARGET_DIR
RUN make -j4
RUN make install


FROM dep-plugins-base as dep-rpicamsrc
# needed to avoid "configure: error: Raspberry Pi files not found in /opt/vc/include"
COPY . /opt/vc
ENV LD_LIBRARY_PATH=/opt/vc/lib
RUN git clone --depth 1 --branch master https://github.com/thaytan/gst-rpicamsrc.git
WORKDIR /src/gst-rpicamsrc
RUN ./autogen.sh --noconfigure
RUN ./configure --prefix=$TARGET_DIR
RUN make -j4
RUN make install


FROM build
COPY --from=dep-gstreamer $TARGET_DIR $TARGET_DIR
COPY --from=dep-plugins-good $TARGET_DIR $TARGET_DIR
COPY --from=dep-plugins-bad $TARGET_DIR $TARGET_DIR
COPY --from=dep-plugins-ugly $TARGET_DIR $TARGET_DIR
COPY --from=dep-gst-rtsp $TARGET_DIR $TARGET_DIR
COPY --from=dep-rpicamsrc $TARGET_DIR $TARGET_DIR
