# Use a lightweight Alpine-based Python image
FROM python:3.11-alpine

# Install necessary packages
RUN apk add --no-cache \
    build-base \
    cmake \
    gfortran \
    gcc \
    g++ \
    openssh \
    openmpi-dev \
    netcdf-fortran-dev \
    proj-util \
    hdf5-dev \
    musl-dev \
    gdal-dev \
    geos-dev \
    proj-dev \
    python3-dev && \
    rm -rf /var/cache/apk/*

# Set environment
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Set the working directory in the container
WORKDIR /app
ENV PATH="/app:$PATH"

# Create a virtual environment
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Install the Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Get FALL3D
RUN wget https://gitlab.com/fall3d-suite/fall3d/-/archive/master/fall3d-master.tar.gz
RUN tar -xf fall3d-master.tar.gz && \
    rm fall3d-master.tar.gz && \
    mv fall3d-master fall3d

# Configure and build FALL3D
RUN mkdir fall3d/build && cd fall3d/build && \
    cmake .. -DDETAIL_BIN=YES -DWITH-MPI=YES -DCUSTOM_COMPILER_FLAGS="-O3" && \
    make -j 10
ENV PATH="/app/fall3d/build/bin:$PATH"

# Get static files for demo
COPY createCOG.py .
COPY createSTAC.py .
COPY fill_template.py .
COPY template.inp .
COPY ERA5.tbl .
COPY lapalma.2021-09-25-06-00.rst.nc .
COPY meteo_era5_palma_20210924_20210926.nc .
