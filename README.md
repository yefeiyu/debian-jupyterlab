debian-jupyterlab
===============
Using
---------------
- To run a SSH daemon on port 2222 in the container:

      docker run -d -p 2222:22 -u root -e SSH_KEY="$(cat ~/.ssh/id_rsa.pub)" xxmm/debian-jupyterlab /bin/bash -c run.sh
This requires a public key in `~/.ssh/id_rsa.pub`.
- To run a `jupyter notebook` server on port 8899 with the following command:

      docker run -d -p 8888:8888 xxmm/debian-jupyterlab
Custom necessary elements
----------------
## Modify User `passwd`
- If you are pull down the image, Please build your `Dockerfile` with this command:

      RUN echo "$NB_USER:YOURPASSWORD" | chpasswd
- If you are build from THIS `Dockerfile`, Please modify this command directly:

      ARG NB_PASSWD="YOURPASSWORD"
## Modify `jupyter notebook` password
- First step, In `ipython`, You define your own password and YOUGOTALINE of tokens:

      from notebook.auth import passwd
      passwd()
- Sec step, put this command into `Dockerfile`:
    
      RUN echo "c.NotebookApp.password='sha1:JUSTNOWYOURGOT'">>/home/xx/.jupyter/jupyter_notebook_config.py  
      
