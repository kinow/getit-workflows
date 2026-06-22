#!/usr/bin/env cwl-runner
cwlVersion: v1.2
$namespaces:
  s: https://schema.org/
schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf

s:softwareVersion: 0.2.1

s:author:
  - class: s:Person
    s:name: Leonardo Mingari
    s:email: mailto:lmingari@csic.es
    s:identifier: https://orcid.org/0000-0002-6584-4699

s:contributor:
  - class: s:Person
    s:name: Eva Hernández
    s:email: mailto:ehernandez@geo3bcn.csic.es

s:codeRepository: https://gitlab.geo3bcn.csic.es/fall3d/what-if-demo

$graph:
  ######################################################################
  # 1) MAIN WORKFLOW 
  ######################################################################
  - id: fall3d-what-if-volcanos 
    class: Workflow
    label: fall3d-what-if-volcanos
    doc: >
      Workflow for the FALL3D demonstration case considering
      three possible what-if scenarios for two volcanic eruptions, 2018 Etna 
      eruption and 2021 La Palma eruption. The scenario type is a user input 
      controlling the initial eruptive column height. The initial conditions 
      are defined from an analysis based on the assimilation of SEVIRI satellite
      data when the parameter initial-condition-type is set to RESTART
    requirements:
      InlineJavascriptRequirement: {}
      SubworkflowFeatureRequirement: {}
      MultipleInputFeatureRequirement: {}
      NetworkAccess:
        networkAccess: true
      ResourceRequirement:
        coresMax: 14
        ramMax: 16000
    inputs:
      volcano:
        label: volcano-name 
        doc: Name of the volcano to be simulated
        type:
        - symbols:
          - Etna
          - La Palma
          type: enum
      meteo_database:
        label: meteorological-dataset-type
        doc: >
          Type of input meteorological dataset provided:
          GFS for the Global Forecast System (GFS) from NCEP
          WRF for the mesoscale model WRF-ARW
          ERA5 for the ECMWF reanalysis in pressure levels
          ERA5 for the ECMWF reanalysis in model levels
        type:
        - symbols:
          - GFS
          - WRF
          - ERA5
          - ERA5ML
          type: enum
      initial_condition:
        label: initial-condition-type
        doc: >
          Type of initial condition for the FALL3D model:
          RESTART for setting the initial condition from a previous run
          INSERTION for defining the initial conditions from satellite data
          NONE for a zero concentration initial concentration
        type:
        - symbols:
          - NONE
          - RESTART
          - INSERTION
          type: enum
      scenario: 
        label: eruptive-scenario
        doc: >
          Type of eruptive scenario. It defines the what-if scenario 
          in terms of three possible eruptive column heights:
          low for a column height of 1000 m above vent level
          medium for a column height of 3000 m above vent level
          high for a column height of 5000 m above vent level
        type:
        - symbols:
          - low
          - medium
          - high
          type: enum
      start_date_time: 
        label: start-time-in-hours
        doc: >
          Simulation start time in hours since the reference date 
          (reference-date) at 00:00. The range of allowed values 
          depends on the time range available in the meteorological 
          dataset and the parameter reference-date.
          **Example**: If you want to start your simulation on 
          2008-04-29 at 12:00Z, define:
          date: 20080429
          start_time: 12
        type: string
      end_date_time: 
        label: end-time-in-hours
        doc: >
          Simulation end time in hours since the reference date 
          (reference-date) at 00:00. The range of allowed values 
          depends on the time range available in the meteorological 
          dataset and the parameters start-time-in-hours and reference-date.
          **Example**: If you want to perform a 48-h simulation starting on 
          2008-04-29 at 12:00Z, define:
          date: 20080429
          start_time: 12
          end_time: 60
        type: string
      wkt:
        label: Domain geometry (WKT)
        type: string
      dx:
        label: longitude-grid-resolution
        doc: >
          Longitudinal resolution in degrees for the lat-lon regular 
          mesh. Grid size is assumed to be uniform over the domain
        type: float
      dy:
        label: latitude-grid-resolution
        doc: >
          Latitudinal resolution in degrees for the lat-lon regular
          mesh. Grid size is assumed to be uniform over the domain
        type: float
      vent_lon:
        label: Volcano vent longitude
        type: float
      vent_lat:
        label: Volcano vent latitude
        type: float
      vent_height:
        label: Volcano vent height
        type: int
      nlevels:
        label: vertical-levels
        doc: >
          Number of vertical levels in the FALL3D computation domain.
          The vertical distribution of levels is automatically defined 
          by the dispersal model
        type: int
      times:
        label: plot-times
        doc: >
          List of times for plotting in hours since the simulation 
          start time. For example, if you want to generate images 
          for the 6-h and 12-h forecasts, define:
          times: [6,12]
        type: int
      keys:
        label: plot-keys
        doc: >
          List of variable keys to be processed for generating figures. 
          Each key represents a variables within the FALL3D output file. 
          Possible values are:
          * tephra_col_mass
          * tephra_cloud_top
          * tephra_grn_load
          * tephra_fl
          * tephra_con_layer
          * SO2_col_mass
          * SO2_cloud_top
          * SO2_grn_load
          * SO2_fl
          * SO2_con_layer
        type: string[]
      nx_mpi:
        label: mpi-along-x
        doc: >
          Number of MPI processes along dimension X used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 3
      ny_mpi:
        label: mpi-along-y
        doc: >
          Number of MPI processes along dimension Y used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 2
      nz_mpi:
        label: mpi-along-z
        doc: >
          Number of MPI processes along dimension Z used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 1
    outputs:
      stac:
        label: stac-catalog
        doc: >
          STAC catalog generated by the workflow including:
          (i) The FALL3D output file (*.res.nc) in netCDF format.
          (ii) A list of COG files (*.tif) for the list of times 
          and variables specified by the user.
          (iii) A list of associated json files required by the 
          STAC specification
        type: Directory
        outputSource: 
          - run_etna/stac
          - run_lapalma/stac
        pickValue: first_non_null
    steps:
      run_etna:
        run: "#demo-etna"
        in:
          volcano: volcano
          meteo_database: meteo_database
          initial_condition: initial_condition
          scenario: scenario
          start_date_time: start_date_time
          end_date_time: end_date_time
          wkt: wkt
          dx: dx
          dy: dy
          vent_lon: vent_lon
          vent_lat: vent_lat
          vent_height: vent_height
          nlevels: nlevels
          times: times
          keys: keys
          nx_mpi: nx_mpi
          ny_mpi: ny_mpi
          nz_mpi: nz_mpi
        out: [stac]
        when: $(inputs.volcano === "Etna")
      run_lapalma:
        run: "#demo-lapalma"
        in:
          volcano: volcano
          meteo_database: meteo_database
          initial_condition: initial_condition
          scenario: scenario
          start_date_time: start_date_time
          end_date_time: end_date_time
          wkt: wkt
          dx: dx
          dy: dy
          vent_lon: vent_lon
          vent_lat: vent_lat
          vent_height: vent_height
          nlevels: nlevels
          times: times
          keys: keys
          nx_mpi: nx_mpi
          ny_mpi: ny_mpi
          nz_mpi: nz_mpi
        out: [stac]
        when: $(inputs.volcano === "La Palma")

  ######################################################################
  # 1.1) SUBWORKFLOW ETNA
  ######################################################################
  - id: demo-etna 
    class: Workflow
    label: fall3d-what-if-etna
    doc: >
      Workflow for the FALL3D demonstration case considering
      three possible what-if scenarios for the 2018 Etna 
      eruption. The scenario type is a user input controlling 
      the initial eruptive column height. The initial 
      conditions are defined from an analysis based on the 
      assimilation of SEVIRI satellite data when the parameter
      initial-condition-type is set to RESTART
    requirements:
      StepInputExpressionRequirement: {}
      ScatterFeatureRequirement: {}
      InlineJavascriptRequirement: {}
      NetworkAccess:
        networkAccess: true
      ResourceRequirement:
        coresMax: 14
        ramMax: 16000
    inputs:
      volcano:
        label: Name of the volcano to be simulated
        type:
        - symbols:
          - Etna
          - La Palma
          type: enum      
      meteo_database:
        label: meteorological-dataset-type
        doc: >
          Type of input meteorological dataset provided:
          GFS for the Global Forecast System (GFS) from NCEP
          WRF for the mesoscale model WRF-ARW
          ERA5 for the ECMWF reanalysis in pressure levels
          ERA5 for the ECMWF reanalysis in model levels
        type:
        - symbols:
          - GFS
          - WRF
          - ERA5
          - ERA5ML
          type: enum
      initial_condition:
        label: initial-condition-type
        doc: >
          Type of initial condition for the FALL3D model:
          RESTART for setting the initial condition from a previous run
          INSERTION for defining the initial conditions from satellite data
          NONE for a zero concentration initial concentration
        type:
        - symbols:
          - NONE
          - RESTART
          - INSERTION
          type: enum
      scenario: 
        label: eruptive-scenario
        doc: >
          Type of eruptive scenario. It defines the what-if scenario 
          in terms of three possible eruptive column heights:
          low for a column height of 1000 m above vent level
          medium for a column height of 3000 m above vent level
          high for a column height of 5000 m above vent level
        type:
        - symbols:
          - low
          - medium
          - high
          type: enum
      start_date_time: 
        label: start-time-in-hours
        doc: >
          Simulation start time in hours since the reference date 
          (reference-date) at 00:00. The range of allowed values 
          depends on the time range available in the meteorological 
          dataset and the parameter reference-date.
          **Example**: If you want to start your simulation on 
          2008-04-29 at 12:00Z, define:
          date: 20080429
          start_time: 12
        type: string
      end_date_time: 
        label: end-time-in-hours
        doc: >
          Simulation end time in hours since the reference date 
          (reference-date) at 00:00. The range of allowed values 
          depends on the time range available in the meteorological 
          dataset and the parameters start-time-in-hours and reference-date.
          **Example**: If you want to perform a 48-h simulation starting on 
          2008-04-29 at 12:00Z, define:
          date: 20080429
          start_time: 12
          end_time: 60
        type: string
      wkt:
        label: Domain geometry (WKT)
        type: string
      dx:
        label: longitude-grid-resolution
        doc: >
          Longitudinal resolution in degrees for the lat-lon regular 
          mesh. Grid size is assumed to be uniform over the domain
        type: float
      dy:
        label: latitude-grid-resolution
        doc: >
          Latitudinal resolution in degrees for the lat-lon regular
          mesh. Grid size is assumed to be uniform over the domain
        type: float
      vent_lon:
        label: Volcano vent longitude
        type: float
      vent_lat:
        label: Volcano vent latitude
        type: float
      vent_height:
        label: Volcano vent height
        type: int
      nlevels:
        label: vertical-levels
        doc: >
          Number of vertical levels in the FALL3D computation domain.
          The vertical distribution of levels is automatically defined 
          by the dispersal model
        type: int
      times:
        label: plot-times
        doc: >
          List of times for plotting in hours since the simulation 
          start time. For example, if you want to generate images 
          for the 6-h and 12-h forecasts, define:
          times: [6,12]
        type: int
      keys:
        label: plot-keys
        doc: >
          List of variable keys to be processed for generating figures. 
          Each key represents a variables within the FALL3D output file. 
          Possible values are:
          * tephra_col_mass
          * tephra_cloud_top
          * tephra_grn_load
          * tephra_fl
          * tephra_con_layer
          * SO2_col_mass
          * SO2_cloud_top
          * SO2_grn_load
          * SO2_fl
          * SO2_con_layer
        type: string[]
      nx_mpi:
        label: mpi-along-x
        doc: >
          Number of MPI processes along dimension X used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 3
      ny_mpi:
        label: mpi-along-y
        doc: >
          Number of MPI processes along dimension Y used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 2
      nz_mpi:
        label: mpi-along-z
        doc: >
          Number of MPI processes along dimension Z used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 1
      # Let the user specify the model binary.
      exe: string
      # Let the user specify the input files.
      template: string
      meteo: string
      restart: string
      dictionary: string
      levels: string
    outputs:
      stac:
        label: stac-catalog
        doc: >
          STAC catalog generated by the workflow including:
          (i) The FALL3D output file (*.res.nc) in netCDF format.
          (ii) A list of COG files (*.tif) for the list of times 
          and variables specified by the user.
          (iii) A list of associated json files required by the 
          STAC specification
        type: Directory
        outputSource: create_catalog/stac
    steps:
      configure:
        run: "#config-etna"
        in:
          template: template
          meteo: meteo
          restart: restart
          dictionary: dictionary
          levels: levels
          meteo_database: meteo_database
          start_date_time: start_date_time
          end_date_time: end_date_time
          date: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var yyyy = s.getUTCFullYear();
                var mm = ("0" + (s.getUTCMonth()+1)).slice(-2);
                var dd = ("0" + s.getUTCDate()).slice(-2);
                return yyyy + mm + dd;
               }
          start_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var midnight = Date.UTC(s.getUTCFullYear(), s.getUTCMonth(), s.getUTCDate());
                return (s.getTime() - midnight) / 3600000;
               }
          end_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var e = new Date(inputs.end_date_time);
                return (e.getTime() - s.getTime()) / 3600000;
               }
          wkt: wkt
          dx: dx
          dy: dy
          vent_lon: vent_lon
          vent_lat: vent_lat
          vent_height: vent_height
          nlevels: nlevels
          initial_condition: initial_condition
        out: [inp]
      set_scenario:
        run: "#phases-etna"
        in:
          scenario: scenario
          start_date_time: start_date_time
          end_date_time: end_date_time
          start_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var midnight = Date.UTC(s.getUTCFullYear(), s.getUTCMonth(), s.getUTCDate());
                return (s.getTime() - midnight) / 3600000;
               }  
          end_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var e = new Date(inputs.end_date_time);
                return (e.getTime() - s.getTime()) / 3600000;
               }
        out: [phases]
      run_fall3d:
        run: "#runner-etna"
        in:
          inp: configure/inp
          nx: nx_mpi
          ny: ny_mpi
          nz: nz_mpi
          phases: set_scenario/phases
          # Pass the model executable.
          exe: exe
          # Pass the files required by FALL3D.
          meteo: meteo
          restart: restart
        out: [log,res,rst]
      create_cogs:
        run: "#figures-etna"
        scatter: key
        in:
          netcdf: run_fall3d/res
          key: keys
          times: times
        out: [tif]
      create_catalog:
        run: "#catalog-etna"
        in:
          tifs: 
            source: create_cogs/tif
            valueFrom: $(self.flat())
          scenario: scenario
        out: [stac]


  ###################################################################### 
  # 1.1.1) CLT: config (ETNA VARIANT) 
  ######################################################################
  - id: config-etna
    class: CommandLineTool
    label: Fill out a configuration file template for FALL3D
    baseCommand: ["fill_template.py"]
    arguments: []
    doc: >
      This tool fill out an input template to generate a 
      full FALL3D configuration file. In the template are 
      hardcoded those parameters that are intended to be 
      fixed for the present simulation case
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-etna:last_version
    requirements:
      ResourceRequirement:
        coresMax: 14
        ramMax: 16000
    inputs:
      template:
        label: Template file to be filled in
        type: string
        inputBinding: {prefix: --template}
      initial_condition:
        label: FALL3D initial condition
        doc: FALL3D initial condition
        inputBinding: {prefix: --INITIAL}
        type:
        - symbols:
          - NONE
          - RESTART
          - INSERTION
          type: enum
      meteo_database:
        label: Type of meteorological dataset
        doc: Type of meteorological dataset
        inputBinding: {prefix: --METEO_DATABASE}
        type:
        - symbols:
          - GFS
          - WRF
          - ERA5
          - ERA5ML
          type: enum
      meteo:
        label: Input meteorological file in netCDF format
        type: string
        inputBinding: {prefix: --METEO_FILE}
      dictionary:
        label: Input dictionary for variable decoding
        type: string?
        inputBinding: {prefix: --METEO_DICTIONARY}
      restart:
        label: Restart file in netCDF format
        type: string?
        inputBinding: {prefix: --RESTART_FILE}
      levels:
        label: Two-columns file with coefficients for hybrid levels
        type: string?
        inputBinding: {prefix: --LEVELS_FILE}
      start_date_time:
        label: 2018-12-25T00:00:00Z
        type: string
        inputBinding: {prefix: --start_date_time}
      end_date_time:
        label: 2018-12-26T00:00:00Z
        type: string
        inputBinding: {prefix: --end_date_time}
      wkt:
        label: Domain geometry in WKT
        type: string
        inputBinding: {prefix: --WKT}
      dx:
        label: Grid resolution for longitudes
        type: float
        inputBinding: {prefix: --DX}
      dy:
        label: Grid resolution for latitudes
        type: float
        inputBinding: {prefix: --DY}
      vent_lon:
        label: Volcano vent longitude
        type: float
        inputBinding: {prefix: --VENT_LON}
      vent_lat:
        label: Volcano vent latitude
        type: float
        inputBinding: {prefix: --VENT_LAT}
      vent_height:
        label: Volcano vent height
        type: int
        inputBinding: {prefix: --VENT_HEIGHT}
      nlevels:
        label: Number of vertical levels
        type: int
        inputBinding: {prefix: --NZ}
    outputs:
      inp:
        label: FALL3D configuration file
        type: File
        outputBinding:
          glob: "*.inp"
    

  ###################################################################### 
  # 1.1.2) CLT: phases (ETNA VARIANT) 
  ######################################################################
  - id: phases-etna
    class: CommandLineTool
    label: Generate eruptive phases file for FALL3D
    baseCommand: echo
    arguments: ["Creating phases file"]
    doc: >
      This tool generates an input file for FALL3D with 
      the definition of the emission phases depending on 
      the eruptive scenario (low,medium,high)
    inputs:
      scenario: 
        label: Eruptive scenario type
        doc: Eruptive scenario type
        inputBinding: {prefix: --path}
        type:
        - symbols:
          - low
          - medium
          - high
          type: enum
      start_time: 
        label: Emission start time 
        type: float
      end_time:
        label: Emission end time
        type: float
    outputs:
      phases:
        label: Eruptive phases file for FALL3D
        type: File
        outputBinding:
          glob: "phases.dat"
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-etna:last_version
    requirements:
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
          - entryname: "phases.dat"
            entry: |
              ${
                if (inputs.scenario == "high") {
                  return [inputs.start_time,inputs.end_time,"5000"].join(" ");
                } else if (inputs.scenario == "low") {
                  return [inputs.start_time,inputs.end_time,"1000"].join(" ");
                } else {
                  return [inputs.start_time,inputs.end_time,"3000"].join(" ");
                }
              }

  ###################################################################### 
  # 1.1.3) CLT: runner (ETNA VARIANT) 
  ######################################################################
  - id: runner-etna
    class: CommandLineTool
    label: Run FALL3D model
    baseCommand: []
    doc: >
      Launch an MPI job in order to run FALL3D in parallel.
      Parallelisation in FALL3D is based on a 3D domain 
      decomposition with (NX,NY,NZ) MPI processes 
      along the dimensions X, Y and Z, respectively.
      This CLT supports only the task "all"
    inputs:
      # Pass the executable to the container. Before it was hard-coded in the arguments list.
      exe:
        label: FALL3D executable location
        doc: |
          The FALL3D executable location.

          If a string is provided, it is assumed to be the path inside the container.

          If a File is provided, you must use with --no-container and provide the
          host-compiled binary to be used.
        type: string
        inputBinding: {position: 0}
      task:
        label: FALL3D task
        type: string
        default: all
        inputBinding: {position: 1}
      inp:
        label: FALL3D configuration file
        type: File
        inputBinding: {position: 2}
      nx:
        label: Number of MPI processes along dimension X
        type: int
        inputBinding: {position: 3}
      ny:
        label: Number of MPI processes along dimension Y
        type: int
        inputBinding: {position: 4}
      nz:
        label: Number of MPI processes along dimension Z
        type: int
        inputBinding: {position: 5}
      phases:
        label: Eruptive phases file for FALL3D
        type: File
      # Add files required by FALL3D. It works in the container because the file exists in the container folder.
      meteo:
        type: string
      restart:
        type: string
    outputs:
      stdout:
        label: Standard output
        type: stdout
      stderr:
        label: Standard error
        type: stderr
      log:
        label: FALL3D log file
        type: File
        outputBinding:
          glob: "*.Fall3d.log"
      res:
        label: FALL3D output file in netCDF format
        type: File
        outputBinding:
          glob: "*.res.nc"
      rst:
        label: FALL3D restart file
        type: File
        outputBinding:
          glob: "*.rst.nc"
    stdout: fall3d.out
    stderr: fall3d.err
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-etna:last_version
    requirements:
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
          - $(inputs.inp)
          - $(inputs.phases)
      cwltool:MPIRequirement:
        processes: $(inputs.nx * inputs.ny * inputs.nz)

  ######################################################################
  # 1.1.4) CLT: figures (ETNA VARIANT) 
  ######################################################################
  - id: figures-etna
    class: CommandLineTool
    label: Generate a tif output from a netcdf
    baseCommand: "createCOG.py"
    arguments: []
    doc: >
      This tool reads a variable (key) from a FALL3D output 
      file in netCDF format (netcdf) and produces a single
      Cloud-Optimized GeoTIFF (COG) file in geotiff format
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-etna:last_version
    inputs:
      netcdf:
        label: FALL3D output file in netCDF format
        type: File
        inputBinding: {prefix: --fname}
      key:
        label: Variable key name to be plotted
        type: string
        inputBinding: {prefix: --key}
      times:
        label: Time frequency
        type: int
        inputBinding: {prefix: --times}
    outputs:
      tif:
        label: Georeferenced image in GeoTIFF file format
        type: File[]
        outputBinding:
          glob: "*.tif"

  ###################################################################### 
  # 1.1.5) CLT: catalog (ETNA VARIANT) 
  ######################################################################
  - id: catalog-etna
    class: CommandLineTool
    label: Generate a STAC catalog
    baseCommand: "createSTAC.py"
    arguments: []
    doc: >
      This tool produces a STAC catalog from a set of 
      GeoTIFF images and a FALL3D output file in netCDF
      format. The netCDF file is provided as an argument, 
      while the GeoTIFF images are automatically detected 
      in the working folder
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-etna:last_version
    inputs:
      scenario: 
        label: Eruptive scenario type
        doc: Eruptive scenario type
        inputBinding: {prefix: --path}
        type:
        - symbols:
          - low
          - medium
          - high
          type: enum
      tifs:
        label: List of files in GeoTIFF format
        type: File[]
        inputBinding: {prefix: --cogs}
    outputs:
      stac:
        label: STAC catalog
        type: Directory
        outputBinding:
          glob: $(inputs.scenario)


  ######################################################################
  # 1.2) SUBWORKFLOW LA PALMA
  ######################################################################
  - id: demo-lapalma 
    class: Workflow
    label: fall3d-what-if-lapalma
    doc: >
      Workflow for the FALL3D demonstration case considering
      three possible what-if scenarios for the 2021 La Palma
      eruption. The scenario type is a user input controlling 
      the initial eruptive column height. The initial 
      conditions are defined from an analysis based on the 
      assimilation of SEVIRI satellite data when the parameter
      initial-condition-type is set to RESTART
    requirements:
      StepInputExpressionRequirement: {}
      ScatterFeatureRequirement: {}
      InlineJavascriptRequirement: {}
      NetworkAccess:
        networkAccess: true
      ResourceRequirement:
        coresMax: 14
        ramMax: 16000
    inputs:
      volcano:
        label: Name of the volcano to be simulated
        type:
        - symbols:
          - Etna
          - La Palma
          type: enum      
      meteo_database:
        label: meteorological-dataset-type
        doc: >
          Type of input meteorological dataset provided:
          GFS for the Global Forecast System (GFS) from NCEP
          WRF for the mesoscale model WRF-ARW
          ERA5 for the ECMWF reanalysis in pressure levels
          ERA5 for the ECMWF reanalysis in model levels
        type:
        - symbols:
          - GFS
          - WRF
          - ERA5
          - ERA5ML
          type: enum
      initial_condition:
        label: initial-condition-type
        doc: >
          Type of initial condition for the FALL3D model:
          RESTART for setting the initial condition from a previous run
          INSERTION for defining the initial conditions from satellite data
          NONE for a zero concentration initial concentration
        type:
        - symbols:
          - NONE
          - RESTART
          - INSERTION
          type: enum
      scenario: 
        label: eruptive-scenario
        doc: >
          Type of eruptive scenario. It defines the what-if scenario 
          in terms of three possible eruptive column heights:
          low for a column height of 1000 m above vent level
          medium for a column height of 3000 m above vent level
          high for a column height of 5000 m above vent level
        type:
        - symbols:
          - low
          - medium
          - high
          type: enum
      start_date_time: 
        label: start-time-in-hours
        doc: >
          Simulation start time in hours since the reference date 
          (reference-date) at 00:00. The range of allowed values 
          depends on the time range available in the meteorological 
          dataset and the parameter reference-date.
          **Example**: If you want to start your simulation on 
          2008-04-29 at 12:00Z, define:
          date: 20080429
          start_time: 12
        type: string
      end_date_time: 
        label: end-time-in-hours
        doc: >
          Simulation end time in hours since the reference date 
          (reference-date) at 00:00. The range of allowed values 
          depends on the time range available in the meteorological 
          dataset and the parameters start-time-in-hours and reference-date.
          **Example**: If you want to perform a 48-h simulation starting on 
          2008-04-29 at 12:00Z, define:
          date: 20080429
          start_time: 12
          end_time: 60
        type: string
      wkt:
        label: Domain geometry (WKT)
        type: string
      dx:
        label: longitude-grid-resolution
        doc: >
          Longitudinal resolution in degrees for the lat-lon regular 
          mesh. Grid size is assumed to be uniform over the domain
        type: float
      dy:
        label: latitude-grid-resolution
        doc: >
          Latitudinal resolution in degrees for the lat-lon regular
          mesh. Grid size is assumed to be uniform over the domain
        type: float
      vent_lon:
        label: Volcano vent longitude
        type: float
      vent_lat:
        label: Volcano vent latitude
        type: float
      vent_height:
        label: Volcano vent height
        type: int
      nlevels:
        label: vertical-levels
        doc: >
          Number of vertical levels in the FALL3D computation domain.
          The vertical distribution of levels is automatically defined 
          by the dispersal model
        type: int
      times:
        label: plot-times
        doc: >
          List of times for plotting in hours since the simulation 
          start time. For example, if you want to generate images 
          for the 6-h and 12-h forecasts, define:
          times: [6,12]
        type: int
      keys:
        label: plot-keys
        doc: >
          List of variable keys to be processed for generating figures. 
          Each key represents a variables within the FALL3D output file. 
          Possible values are:
          * tephra_col_mass
          * tephra_cloud_top
          * tephra_grn_load
          * tephra_fl
          * tephra_con_layer
          * SO2_col_mass
          * SO2_cloud_top
          * SO2_grn_load
          * SO2_fl
          * SO2_con_layer
        type: string[]
      nx_mpi:
        label: mpi-along-x
        doc: >
          Number of MPI processes along dimension X used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 3
      ny_mpi:
        label: mpi-along-y
        doc: >
          Number of MPI processes along dimension Y used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 2
      nz_mpi:
        label: mpi-along-z
        doc: >
          Number of MPI processes along dimension Z used for the 
          domain decomposition. FALL3D is run in parallel using 
          a total number of N MPI processes, where:
          N = nx_mpi*ny_mpi*nz_mpi
        type: int
        default: 1
    outputs:
      stac:
        label: stac-catalog
        doc: >
          STAC catalog generated by the workflow including:
          (i) The FALL3D output file (*.res.nc) in netCDF format.
          (ii) A list of COG files (*.tif) for the list of times 
          and variables specified by the user.
          (iii) A list of associated json files required by the 
          STAC specification
        type: Directory
        outputSource: create_catalog/stac
    steps:
      configure:
        run: "#config-lapalma"
        in:
          template: 
            default: "/app/template.inp"
          meteo: 
            default: "/app/meteo.nc"
          restart:
            default: "/app/restart.nc"
          dictionary:
            default: "/app/ERA5.tbl"
          levels:
            default: "/app/L137_ECMWF.levels"
          meteo_database: meteo_database
          start_date_time: start_date_time
          end_date_time: end_date_time
          date: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var yyyy = s.getUTCFullYear();
                var mm = ("0" + (s.getUTCMonth()+1)).slice(-2);
                var dd = ("0" + s.getUTCDate()).slice(-2);
                return yyyy + mm + dd;
               }
          start_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var midnight = Date.UTC(s.getUTCFullYear(), s.getUTCMonth(), s.getUTCDate());
                return (s.getTime() - midnight) / 3600000;
               }
          end_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var e = new Date(inputs.end_date_time);
                return (e.getTime() - s.getTime()) / 3600000;
               }
          wkt: wkt
          dx: dx
          dy: dy
          vent_lon: vent_lon
          vent_lat: vent_lat
          vent_height: vent_height
          nlevels: nlevels
          initial_condition: initial_condition
        out: [inp]
      set_scenario:
        run: "#phases-lapalma"
        in:
          scenario: scenario
          start_date_time: start_date_time
          end_date_time: end_date_time
          start_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var midnight = Date.UTC(s.getUTCFullYear(), s.getUTCMonth(), s.getUTCDate());
                return (s.getTime() - midnight) / 3600000;
               }  
          end_time: 
            valueFrom: |
              ${
                var s = new Date(inputs.start_date_time);
                var e = new Date(inputs.end_date_time);
                return (e.getTime() - s.getTime()) / 3600000;
               }
        out: [phases]
      run_fall3d:
        run: "#runner-lapalma"
        in:
          inp: configure/inp
          nx: nx_mpi
          ny: ny_mpi
          nz: nz_mpi
          phases: set_scenario/phases
        out: [log,res,rst]
      create_cogs:
        run: "#figures-lapalma"
        scatter: key
        in:
          netcdf: run_fall3d/res
          key: keys
          times: times
        out: [tif]
      create_catalog:
        run: "#catalog-lapalma"
        in:
          tifs: 
            source: create_cogs/tif
            valueFrom: $(self.flat())
          scenario: scenario
        out: [stac]

  ###################################################################### 
  # 1.2.1) CLT: config (LAPALMA VARIANT) 
  ######################################################################
  - id: config-lapalma
    class: CommandLineTool
    label: Fill out a configuration file template for FALL3D
    baseCommand: ["fill_template.py"]
    arguments: []
    doc: >
      This tool fill out an input template to generate a 
      full FALL3D configuration file. In the template are 
      hardcoded those parameters that are intended to be 
      fixed for the present simulation case
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-lapalma:last_version
    requirements:
      ResourceRequirement:
        coresMax: 14
        ramMax: 16000
    inputs:
      template:
        label: Template file to be filled in
        type: string
        inputBinding: {prefix: --template}
      initial_condition:
        label: FALL3D initial condition
        doc: FALL3D initial condition
        inputBinding: {prefix: --INITIAL}
        type:
        - symbols:
          - NONE
          - RESTART
          - INSERTION
          type: enum
      meteo_database:
        label: Type of meteorological dataset
        doc: Type of meteorological dataset
        inputBinding: {prefix: --METEO_DATABASE}
        type:
        - symbols:
          - GFS
          - WRF
          - ERA5
          - ERA5ML
          type: enum
      meteo:
        label: Input meteorological file in netCDF format
        type: string
        inputBinding: {prefix: --METEO_FILE}
      dictionary:
        label: Input dictionary for variable decoding
        type: string?
        inputBinding: {prefix: --METEO_DICTIONARY}
      restart:
        label: Restart file in netCDF format
        type: string?
        inputBinding: {prefix: --RESTART_FILE}
      levels:
        label: Two-columns file with coefficients for hybrid levels
        type: string?
        inputBinding: {prefix: --LEVELS_FILE}
      start_date_time:
        label: 2018-12-25T00:00:00Z
        type: string
        inputBinding: {prefix: --start_date_time}
      end_date_time:
        label: 2018-12-26T00:00:00Z
        type: string
        inputBinding: {prefix: --end_date_time}
      wkt:
        label: Domain geometry in WKT
        type: string
        inputBinding: {prefix: --WKT}
      dx:
        label: Grid resolution for longitudes
        type: float
        inputBinding: {prefix: --DX}
      dy:
        label: Grid resolution for latitudes
        type: float
        inputBinding: {prefix: --DY}
      vent_lon:
        label: Volcano vent longitude
        type: float
        inputBinding: {prefix: --VENT_LON}
      vent_lat:
        label: Volcano vent latitude
        type: float
        inputBinding: {prefix: --VENT_LAT}
      vent_height:
        label: Volcano vent height
        type: int
        inputBinding: {prefix: --VENT_HEIGHT}
      nlevels:
        label: Number of vertical levels
        type: int
        inputBinding: {prefix: --NZ}
    outputs:
      inp:
        label: FALL3D configuration file
        type: File
        outputBinding:
          glob: "*.inp"
    

  ###################################################################### 
  # 1.2.2) CLT: phases (LAPALMA VARIANT) 
  ######################################################################
  - id: phases-lapalma
    class: CommandLineTool
    label: Generate eruptive phases file for FALL3D
    baseCommand: echo
    arguments: ["Creating phases file"]
    doc: >
      This tool generates an input file for FALL3D with 
      the definition of the emission phases depending on 
      the eruptive scenario (low,medium,high)
    inputs:
      scenario: 
        label: Eruptive scenario type
        doc: Eruptive scenario type
        inputBinding: {prefix: --path}
        type:
        - symbols:
          - low
          - medium
          - high
          type: enum
      start_time: 
        label: Emission start time 
        type: float
      end_time:
        label: Emission end time
        type: float
    outputs:
      phases:
        label: Eruptive phases file for FALL3D
        type: File
        outputBinding:
          glob: "phases.dat"
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-lapalma:last_version
    requirements:
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
          - entryname: "phases.dat"
            entry: |
              ${
                if (inputs.scenario == "high") {
                  return [inputs.start_time,inputs.end_time,"5000"].join(" ");
                } else if (inputs.scenario == "low") {
                  return [inputs.start_time,inputs.end_time,"1000"].join(" ");
                } else {
                  return [inputs.start_time,inputs.end_time,"3000"].join(" ");
                }
              }

  ###################################################################### 
  # 1.2.3) CLT: runner (LAPALMA VARIANT) 
  ######################################################################
  - id: runner-lapalma
    class: CommandLineTool
    label: Run FALL3D model
    baseCommand: mpirun
    arguments:
      - prefix: -n
        valueFrom: $(inputs.nx * inputs.ny * inputs.nz)
      - "Fall3d.GNU.r8.mpi.cpu.x"
    doc: >
      Launch an MPI job in order to run FALL3D in parallel.
      Parallelisation in FALL3D is based on a 3D domain 
      decomposition with (NX,NY,NZ) MPI processes 
      along the dimensions X, Y and Z, respectively.
      This CLT supports only the task "all"
    inputs:
      task:
        label: FALL3D task
        type: string
        default: all
        inputBinding: {position: 0}
      inp: 
        label: FALL3D configuration file
        type: File
        inputBinding: {position: 1}
      nx:
        label: Number of MPI processes along dimension X
        type: int
        inputBinding: {position: 2}
      ny:
        label: Number of MPI processes along dimension Y
        type: int
        inputBinding: {position: 3}
      nz:
        label: Number of MPI processes along dimension Z
        type: int
        inputBinding: {position: 4}
      phases:
        label: Eruptive phases file for FALL3D
        type: File
    outputs:
      stdout:
        label: Standard output
        type: stdout
      stderr:
        label: Standard error
        type: stderr
      log:
        label: FALL3D log file
        type: File
        outputBinding:
          glob: "*.Fall3d.log"
      res:
        label: FALL3D output file in netCDF format
        type: File
        outputBinding:
          glob: "*.res.nc"
      rst:
        label: FALL3D restart file
        type: File
        outputBinding:
          glob: "*.rst.nc"
    stdout: fall3d.out
    stderr: fall3d.err
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-lapalma:last_version
    requirements:
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
          - $(inputs.inp)
          - $(inputs.phases)

  ###################################################################### 
  # 1.2.4) CLT: figures (LAPALMA VARIANT) 
  ######################################################################
  - id: figures-lapalma
    class: CommandLineTool
    label: Generate a tif output from a netcdf
    baseCommand: "createCOG.py"
    arguments: []
    doc: >
      This tool reads a variable (key) from a FALL3D output 
      file in netCDF format (netcdf) and produces a single
      Cloud-Optimized GeoTIFF (COG) file in geotiff format
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-lapalma:last_version
    inputs:
      netcdf:
        label: FALL3D output file in netCDF format
        type: File
        inputBinding: {prefix: --fname}
      key:
        label: Variable key name to be plotted
        type: string
        inputBinding: {prefix: --key}
      times:
        label: Time frequency
        type: int
        inputBinding: {prefix: --times}
    outputs:
      tif:
        label: Georeferenced image in GeoTIFF file format
        type: File[]
        outputBinding:
          glob: "*.tif"

  ###################################################################### 
  # 1.2.5) CLT: catalog (LAPALMA VARIANT) 
  ######################################################################
  - id: catalog-lapalma
    class: CommandLineTool
    label: Generate a STAC catalog
    baseCommand: "createSTAC.py"
    arguments: []
    doc: >
      This tool produces a STAC catalog from a set of 
      GeoTIFF images and a FALL3D output file in netCDF
      format. The netCDF file is provided as an argument, 
      while the GeoTIFF images are automatically detected 
      in the working folder
    hints:
      DockerRequirement:
        dockerPull: docker.io/dtgeo/get-it-what-if-demo-lapalma:last_version
    inputs:
      scenario: 
        label: Eruptive scenario type
        doc: Eruptive scenario type
        inputBinding: {prefix: --path}
        type:
        - symbols:
          - low
          - medium
          - high
          type: enum
      tifs:
        label: List of files in GeoTIFF format
        type: File[]
        inputBinding: {prefix: --cogs}
    outputs:
      stac:
        label: STAC catalog
        type: Directory
        outputBinding:
          glob: $(inputs.scenario)