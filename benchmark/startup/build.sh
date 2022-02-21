#!/bin/bash
for name in nvim dein jetpack plug paq packer minpac; do
  docker build -t $name $name
done
