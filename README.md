# What-if scenario: real cases

This is the CWL-based workflow for the what-if scenario 
demonstration to be run in the Terradue platform. 
The FALL3D model is driven by ERA5 data to generate a 24-h forecast
of the 2018 Etna eruption started on 24 December at 09:30 UTC and La Palma
eruption in 2021.

This simulation are started using initial conditions from a previous simulation (restart).

The Etna test case can be executed using the command:

```console
cwltool fall3d-what-if.0.1.6-etna.cwl#demo arguments_etna.yml
```

and La Palma case with:

```console
cwltool fall3d-what-if.0.1.6-lapalma.cwl#demo arguments_lapalma.yml
```

It runs the FALL3D model using 6 MPI processes (by default) and generates a STAC catalog as an output.

# Requirements

## CWL runner

A CWL runner is required for running the CWL workflow. For example, you can
install `cwltool`, a Python Open Source project maintained by the CWL
community:

```console
pip install cwltool
```

## Docker container

By default the job is executed in a [Docker container][Dockerhub].
If you prefer Podman runtime for running containers, use:
```console
cwltool --podman fall3d-what-if-0.1.0.cwl#demo arguments.yml
```
or
```console
cwltool --singularity fall3d-what-if-0.1.0.cwl#demo arguments.yml
```
for singularity/apptainer.

<!----------------------------------------------------------------------------->

[Dockerhub]: docker.io/dtgeo/get-it-what-if-demo-etna:last_version
