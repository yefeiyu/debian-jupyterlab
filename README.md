debian-jupyterlab
===============
Using
---------------
- To run a SSH daemon on port 2222 in the container:

      docker run -d -p 2222:22 -e SSH_KEY="$(cat ~/.ssh/id_rsa.pub)" xxmm/debian-jupyterlab /bin/bash -c run.sh
This requires a public key in `~/.ssh/id_rsa.pub`.
- To run a `jupyter notebook` server on port 8888 with the following command:

      docker run -it --rm -p 8888:8888 xxmm/debian-jupyterlab
