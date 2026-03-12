#!/bin/bash
#SBATCH --job-name=test_hostname
#SBATCH --output=output%j.out
#SBATCH --ntasks=1
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=2
#SBATCH --gres=gpu:1
#SBATCH --mem=16GB
#SBATCH --partition=defq

hostname
pwd
