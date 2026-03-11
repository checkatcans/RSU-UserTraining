# 🧠 LLM+Container Workshop

Workshop สำหรับการรัน ML App และ LLM บน HPC Cluster ด้วย Docker, Singularity/Apptainer และ SLURM

---

## 📋 สารบัญ

1. [Tech Stack Advisor without Docker (Train on SLURM via CommandLine)](#1-tech-stack-advisor-without-docker-train-on-slurm-via-commandline)
2. [Tech Stack Advisor without Docker (Train on SLURM via JupyterHub)](#2-tech-stack-advisor-without-docker-train-on-slurm-via-jupyterhub)
3. [Build the tech-stack-advisor container on rsu-login for testing](#3-build-the-tech-stack-advisor-container-on-rsu-login-for-testing)
4. [Build the tech-stack-advisor image from Dockerfile on rsu-login](#4-build-the-tech-stack-advisor-image-from-dockerfile-on-rsu-login)
5. [Build latest and push and use HF](#5-build-latest-and-push-and-use-hf)
6. [Pull the tech-stack-advisor docker image to SIF](#6-pull-the-tech-stack-advisor-docker-image-to-sif)
7. [Build Singularity image from Singularity Sandbox](#7-build-singularity-image-from-singularity-sandbox)
8. [LLM Docker on rsu-training (Demo)](#8-demo-llm-docker-on-rsu-training)
9. [Ollama + Gradio + SLURM](#9-ollama--gradio--slurm)

---

## 1. Tech Stack Advisor without Docker (Train on SLURM via CommandLine)

```bash
# SSH to rsu-login
$ git clone https://github.com/docker-aiml/tech-stack-advisor
$ cd tech-stack-advisor/
$ ls

# Create and activate conda environment
$ conda env list
$ conda create -n tsa python=3.11
$ conda activate tsa
$ conda config --append channels conda-forge
$ conda install -y -c file:///cm/shared/apps/jupyter/current/share/conda-repo cm-jupyter-eg-kernel-wlm

# Install dependencies (append huggingface_hub==0.19.4 to requirements.txt first)
$ vim requirements.txt
$ cat requirements.txt
$ conda install --file requirements.txt

# Submit a SLURM Interactive Job
$ srun --gres=gpu:1 --mem=8G --pty bash
$ conda activate tsa
$ python train.py
$ ls
```

### รัน app และ SSH Tunnel

```bash
# Edit port to 310xx (e.g. user test06 = port 31006)
$ vim app.py
$ python app.py

# On your local machine, open a new terminal and create SSH Tunnel
$ ssh -L 31006:rsu-training:31006 test06@171.102.216.177 -N

# Open Browser
http://171.102.216.177:31006/

# To stop: close browser and Ctrl+C from SSH Tunnel
```

---

## 2. Tech Stack Advisor without Docker (Train on SLURM via JupyterHub)

```python
# Open JupyterHub
# Create a new kernel template
# Start a notebook using the kernel template

!hostname
%cd /home/test06/tech-stack-advisor
%pwd
!ls -l

%run train.py
!ls -l

# Edit app.py — change port to 310xx (e.g. test06 = 31006)
%run app.py
```

```bash
# On your local machine, create SSH Tunnel
$ ssh -L 31006:rsu-training:31006 test06@171.102.216.177 -N

# Open Browser
http://171.102.216.177:31006/

# To stop: close browser and Ctrl+C from SSH Tunnel
```

---

## 3. Build the tech-stack-advisor container on rsu-login for testing

แนวทางนี้ใช้ `docker run` จาก base image แล้ว `docker cp` โค้ดเข้าไป ทดสอบภายใน container ก่อน แล้วค่อย commit เป็น image

```bash
# Run a base python container with port mapping
$ docker run -idt --name dev -p 31006:31006 python:3.11-slim bash

# Verify container is running
$ docker ps

# Copy project files into container
$ docker cp . dev:/app

# Enter the container
$ docker exec -it dev bash

# Inside container
$ cd app
$ ls
$ pip install -r requirements.txt
$ python app.py

# Open Browser: http://171.102.216.177:31006/
# Ctrl+C to stop, then exit
$ exit

# Commit container state to a new image (v1)
$ docker container commit dev choocku/test06-tech-stack-advisor:v1
```

---

## 4. Build the tech-stack-advisor image from Dockerfile on rsu-login

แนวทางนี้ใช้ Dockerfile สร้าง image ซึ่งเป็น **best practice** สำหรับ production

```bash
# Create Dockerfile (see project README for content)
# Build image from Dockerfile (v2)
$ docker build -t choocku/test06-tech-stack-advisor:v2 .

# Run container from new image
$ docker run -idt --name dev -p 31006:31006 choocku/test06-tech-stack-advisor:v2

# Push image to Docker Hub
$ docker push choocku/test06-tech-stack-advisor:v2

# Cleanup
$ docker rm -f dev

# Open Browser: http://171.102.216.177:31006/
```

---

## 5. Build latest and push and use HF

Deploy app ขึ้น Hugging Face Spaces โดยใช้ Docker SDK

```bash
# Tag image as latest
$ docker tag choocku/test06-tech-stack-advisor:v2 choocku/test06-tech-stack-advisor:latest

# Add Hugging Face remote
$ git remote add hf https://huggingface.co/spaces/choocku/tech-stack-advisor

# Edit app.py and Dockerfile — change port back to 7860 (HF default)

# Commit and push to GitHub
$ git add .
$ git commit -am "add Dockerfile with model"
$ git push origin main

# Push to Hugging Face Spaces
$ git push hf main --force
# Username: choocku
# Password: <HF access token>
```

> 💡 Hugging Face Spaces จะ auto-build Docker image และ deploy ให้อัตโนมัติ

---

## 6. Pull the tech-stack-advisor docker image to SIF

แปลง Docker image เป็น Singularity Image Format (`.sif`) เพื่อใช้บน HPC ที่ไม่มี root

### 6.1 Interactive Job

```bash
# Load apptainer module
$ module load apptainer

# Pull Docker image and convert to SIF
$ apptainer pull tech-stack.sif docker://choocku/test06-tech-stack-advisor:v2

# Request interactive GPU job
$ srun -c2 --gres=gpu:1 --mem=8G --pty bash

# Run app inside SIF with GPU support
$ singularity exec --nv tech-stack.sif python app.py

# SSH Tunnel from local machine
$ ssh -L 31006:rsu-training:31006 test06@171.102.216.177 -N

# Open Browser: http://171.102.216.177:31006/
```

### 6.2 Batch Script

```bash
# run_singularity.sh
$ cat run_singularity.sh
```

```bash
#!/bin/bash
#SBATCH --job-name=tsa  --gres=gpu:1
#SBATCH --mem=16G       --time=00:30:00

singularity exec --nv \
  tech-stack.sif python app.py
```

```bash
# Submit batch job
$ sbatch run_singularity.sh

# SSH Tunnel from local machine
$ ssh -L 31006:rsu-training:31006 test06@171.102.216.177 -N

# Open Browser: http://171.102.216.177:31006/

# Cancel job when done
$ scancel -f <JOBID>
```

---

## 7. Build Singularity image from Singularity Sandbox

สร้าง Singularity image แบบ sandbox (writable directory) แล้ว build เป็น `.sif`

```bash
# Request interactive GPU job
$ srun -c2 --gres=gpu:1 --mem=8G --pty bash

$ mkdir docker-aiml/
$ cd docker-aiml/
$ git clone https://github.com/docker-aiml/tech-stack-advisor
$ cd tech-stack-advisor/

# Build sandbox from Docker base image (requires --fakeroot)
$ apptainer build --fakeroot --sandbox tsa-dev docker://python:3.11-slim

# Enter sandbox shell
$ apptainer shell --fakeroot tsa-dev

# Inside Apptainer sandbox
Apptainer> cd docker-aiml/tech-stack-advisor/
Apptainer> pip install -r requirements.txt
Apptainer> python train.py
Apptainer> python app.py

# SSH Tunnel from local machine
# ssh -L 31006:rsu-training:31006 test06@171.102.216.177 -N
# Open Browser: http://171.102.216.177:31006/

Apptainer> exit

# Convert sandbox directory to .sif file
$ apptainer build --fakeroot tsa-dev.sif tsa-dev/

# Run from .sif
$ apptainer exec --nv tsa-dev.sif python app.py
```

---

## 8. (Demo) LLM Docker on rsu-training

รัน Ollama LLM container บน rsu-training โดยแต่ละ user ได้ port ของตัวเองโดยอัตโนมัติ

```bash
# Calculate unique port per user (base 11400 + UID mod 1000)
$ MY_PORT=$((11400 + $(id -u) % 1000))
$ echo "My Ollama port: $MY_PORT"
# My Ollama port: 11443

# Run Ollama container with GPU (--runtime=runc for NVIDIA)
$ docker run -d --runtime=runc \
    --name ollama-$USER \
    -p ${MY_PORT}:11434 \
    -v $HOME/ollama_models:/root/.ollama \
    ollama/ollama

# Verify container is running
$ docker ps

# Pull a small LLM model
$ docker exec -it ollama-$USER ollama pull tinyllama

# Test inference
$ docker exec -it ollama-$USER \
    ollama run tinyllama "What is Docker?"
```

---

## 9. Ollama + Gradio + SLURM

รัน Ollama พร้อม Gradio UI ผ่าน SLURM batch job บน rsu-training

### Setup

```bash
# เพิ่ม OLLAMA_MODELS ใน ~/.bashrc
export OLLAMA_MODELS=~/ollama_models

# Copy ตัวอย่าง deepseek project
$ cp -r /cm/shared/examples/deepseek-with-ollama-on-supercomputer/ ~
$ cd ~/deepseek-with-ollama-on-supercomputer/

# Submit batch job
$ sbatch ollama_gradio_run.sh

# SSH Tunnel (port จาก job output)
$ ssh -L localhost:34742:rsu-training:34742 test06@171.102.216.177
```

### Test Temperature Effect

```bash
$ PORT=40318

# temperature=0.0 → output เหมือนกันทุกครั้ง (deterministic)
$ for i in 1 2 3; do
    curl -s http://127.0.0.1:$PORT/api/generate -d '{
      "model": "scb10x/llama3.1-typhoon2-8b-instruct",
      "prompt": "ต่อประโยค: วันนี้อากาศดีมาก จึงตัดสินใจ",
      "stream": false,
      "options": {"temperature": 0.0}
    }' | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])"
  done

# temperature=1.0 → output หลากหลายขึ้น (creative)
$ for i in 1 2 3; do
    curl -s http://127.0.0.1:$PORT/api/generate -d '{
      "model": "scb10x/llama3.1-typhoon2-8b-instruct",
      "prompt": "ต่อประโยค: วันนี้อากาศดีมาก จึงตัดสินใจ",
      "stream": false,
      "options": {"temperature": 1.0}
    }' | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])"
  done

# temperature=1.2 → สร้างสรรค์มากขึ้น (more random)
$ for i in 1 2 3; do
    curl -s http://127.0.0.1:$PORT/api/generate -d '{
      "model": "scb10x/llama3.1-typhoon2-8b-instruct",
      "prompt": "แมวตัวหนึ่งเดินเข้าร้านกาแฟ แล้ว",
      "stream": false,
      "options": {"temperature": 1.2}
    }' | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])"
    echo "---"
  done
```

### Cancel SLURM Job

```bash
$ squeue
$ scancel -f <JOBID>
```

---
