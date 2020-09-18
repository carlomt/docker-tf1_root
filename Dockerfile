FROM tensorflow/tensorflow:1.15.2-gpu-py3 as builder

WORKDIR /workspace

ENV LANG=C.UTF-8
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

COPY packages .

RUN DEBIAN_FRONTEND=noninteractive \
apt-get -y update && \ 
apt-get -y install \
git \
$(cat packages) \
&& rm -rf /var/lib/apt/lists/*

RUN git clone --branch v6-22-00-patches https://github.com/root-project/root.git root_src \
&& mkdir root_build root && cd root_build \
&& cmake -Dpython3="ON" -DPYTHON_EXECUTABLE="/usr/local/bin/python" -Dlibcxx="ON" -Dmathmore="ON" -Dminuit2="ON" -Droofit="ON" -Dtmva="ON" -DCMAKE_INSTALL_PREFIX=../root ../root_src \
&& cmake --build . -- install -j `nproc` 


#######################################################################

FROM tensorflow/tensorflow:1.15.2-gpu-py3

ENV LANG=C.UTF-8
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

COPY packages .

RUN DEBIAN_FRONTEND=noninteractive \
apt-get -y update && \
apt-get -y install \
emacs-nox \
git \
wget \
python3-pygraphviz \
$(cat packages) \
&& rm -rf /var/lib/apt/lists/*

COPY cuda/include/cudnn*.h /usr/local/cuda/include/
COPY cuda/lib64/libcudnn* /usr/local/cuda/lib64/
RUN chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*

COPY --from=builder /workspace/root /opt/root
COPY entry-point.sh /opt/entry-point.sh
COPY set-aliases.sh /opt/set-aliases.sh
# RUN chmod a+rwx OB/opt/entry-point.sh

RUN /usr/local/bin/python -m pip install --upgrade pip \ 
&& /usr/local/bin/python -m pip install \
matplotlib \
ipython keras==2.3.1 \
pydot \
&& source /opt/root/bin/thisroot.sh && /usr/local/bin/python -m pip install root_numpy

ENTRYPOINT ["/opt/entry-point.sh"]
CMD ["/bin/bash"]
