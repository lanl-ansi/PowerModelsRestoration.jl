# PowerModelsRestoration.jl

![CI](https://github.com/lanl-ansi/PowerModelsRestoration.jl/workflows/CI/badge.svg) [![codecov](https://codecov.io/gh/lanl-ansi/PowerModelsRestoration.jl/branch/master/graph/badge.svg?token=ADfcIkUOqH)](https://codecov.io/gh/lanl-ansi/PowerModelsRestoration.jl) [![Documentation](https://github.com/lanl-ansi/PowerModelsRestoration.jl/workflows/Documentation/badge.svg)](https://lanl-ansi.github.io/PowerModelsRestoration.jl/stable/)

A PowerModelsRestoration provides extensions to [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) for solving the power system restoration tasks.  A core building block in PowerModelsRestoration is the Maximum Load Delivery (MLD) problem, which provides a reliable numerical method for solving challenging N-k damage scenarios, such as those that arise in the analysis of extreme events.

## Core Problem Specifications

* Restoration Ordering Problem (rop)
* Minimum Restoration Set Problem (mrsp)
* Forward Restoration Redispatch
* Maximum Load Delivery with Discrete Variables (mld_uc)
* Maximum Load Delivery with Continuous Variables (mld)

## Core Network Formulations

* AC (polar coordinates)
* DC Approximation (polar coordinates)
* SOC Relaxation (W-space)
* SDP Relaxation (W-space)

## Citing PowerModelsRestoration
If you find the PowerModelsRestoration package useful in your work, we request that you cite the following [publication](https://doi.org/10.1016/j.epsr.2020.106736):
```
@article{rhodes2021powermodelsrestoration,
  title={PowerModelsRestoration. jl: An open-source framework for exploring power network restoration algorithms},
  author={Rhodes, Noah and Fobes, David M and Coffrin, Carleton and Roald, Line},
  journal={Electric Power Systems Research},
  volume={190},
  pages={106736},
  year={2021},
  publisher={Elsevier}
}
```

In addition, if the MLD problem from PowerModelsRestoration useful in your work, we kindly request that you cite the following [publication](https://ieeexplore.ieee.org/document/8494809):
```
@article{8494809,
  author={Carleton Coffrin and Russell Bent and Byron Tasseff and Kaarthik Sundar and Scott Backhaus},
  title={Relaxations of AC Maximal Load Delivery for Severe Contingency Analysis},
  journal={IEEE Transactions on Power Systems},
  volume={34}, number={2}, pages={1450-1458},
  month={March}, year={2019},
  doi={10.1109/TPWRS.2018.2876507}, ISSN={0885-8950}
}
```


Citation of the [PowerModels framework](https://ieeexplore.ieee.org/document/8442948/) is also encouraged when publishing works that use PowerModels extension packages.


## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
