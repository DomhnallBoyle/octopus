ARG CUDA_BASE_VERSION
ARG UBUNTU_VERSION
ARG CUDNN_VERSION

# use CUDA + OpenGL
FROM nvidia/cudagl:${CUDA_BASE_VERSION}-devel-ubuntu${UBUNTU_VERSION}
MAINTAINER Domhnall Boyle (domhnallboyle@gmail.com)

# arguments from command line
ARG CUDA_BASE_VERSION
ARG UBUNTU_VERSION
ARG CUDNN_VERSION
ARG TENSORFLOW_VERSION

# set environment variables
ENV CUDA_BASE_VERSION=${CUDA_BASE_VERSION}
ENV CUDNN_VERSION=${CUDNN_VERSION}
ENV TENSORFLOW_VERSION=${TENSORFLOW_VERSION}

# install apt dependencies
RUN apt-get update && apt-get install -y \
	python \
	python-pip \
	git \
	vim \
	wget \
	zip

# install newest cmake version
RUN apt-get purge cmake && cd ~ && wget https://github.com/Kitware/CMake/releases/download/v3.14.5/cmake-3.14.5.tar.gz && tar -xvf cmake-3.14.5.tar.gz
RUN cd ~/cmake-3.14.5 && ./bootstrap && make && make install

# setting up cudnn
RUN apt-get install -y --no-install-recommends \             
	libcudnn7=$(echo $CUDNN_VERSION)-1+cuda$(echo $CUDA_BASE_VERSION) \             
	libcudnn7-dev=$(echo $CUDNN_VERSION)-1+cuda$(echo $CUDA_BASE_VERSION) 
RUN apt-mark hold libcudnn7 && rm -rf /var/lib/apt/lists/*

# install dirt python dependencies
RUN pip install tensorflow-gpu==$(echo $TENSORFLOW_VERSION)

# install dirt
ENV CUDAFLAGS='-DNDEBUG=1'
RUN cd ~ && git clone https://github.com/pmh47/dirt.git && \ 
 	pip install dirt/

# run dirt test command
RUN python ~/dirt/tests/square_test.py

# install octopus
# TODO: Not sure if I should be hosting smpl neutral model
RUN cd ~ && git clone https://github.com/thmoa/octopus.git
RUN wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1_CwZo4i48t1TxIlIuUX3JDo6K7QdYI5r' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1_CwZo4i48t1TxIlIuUX3JDo6K7QdYI5r" -O ~/octopus_weights.zip && rm -rf /tmp/cookies.txt
RUN wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=14xj4bUj2aq0DGhh_zEBqhAbc8zi26rvv' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=14xj4bUj2aq0DGhh_zEBqhAbc8zi26rvv" -O ~/octopus/assets/neutral_smpl.pkl && rm -rf /tmp/cookies.txt
RUN unzip ~/octopus_weights.zip -d ~/octopus/weights
RUN apt-get update && apt-get install -y python-scipy libsm6 libxext6 libxrender-dev
RUN cd ~/octopus && pip install Keras opencv-python tqdm chumpy
RUN cd ~/octopus && ./run_demo.sh
