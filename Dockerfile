FROM circleci/buildpack-deps:focal

# Requirements
RUN sudo apt-get update && \
 sudo apt-get install -y \
 git ssh tar gzip ca-certificates \
 cmake clang mysql-client \
 libboost-dev libboost-filesystem-dev libboost-iostreams-dev libboost-program-options-dev libboost-regex-dev libboost-system-dev libboost-thread-dev libssl-dev libmysqlclient-dev libreadline-dev libncurses-dev zlib1g-dev libbz2-dev ccache

#Setup
RUN git config --global user.email "circleci@build.bot" && git config --global user.name "Circle CI"
RUN sudo update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
 sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100
COPY scripts/ scripts/
RUN sudo chmod a+x -R /scripts
