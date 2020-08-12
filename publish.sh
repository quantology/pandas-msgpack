#!/bin/bash
docker run -it --rm -v `pwd`:/io quay.io/pypa/manylinux2010_x86_64 /io/ci/build_wheels.sh && \
python3 setup.py sdist && \
python3 -m twine upload --repository testpypi dist/* wheelhouse/*
