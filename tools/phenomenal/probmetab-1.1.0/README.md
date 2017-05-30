ProbMetab for Galaxy
====================

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/r-probmetab/README.html) [![Build Status](https://travis-ci.org/workflow4metabolomics/probmetab.svg?branch=master)](https://travis-ci.org/workflow4metabolomics/probmetab)

Our project
-----------
The [Workflow4Metabolomics](http://workflow4metabolomics.org), W4M in short, is a French infrastructure offering software tool processing, analyzing and annotating metabolomics data. It is based on the Galaxy platform.


ProbMetab
---------
ProbMetab, an R package that promotes substantial improvement in automatic probabilistic liquid chromatography-mass spectrometry-based metabolome annotation. The inference engine core is based on a Bayesian model implemented to (i) allow diverse source of experimental data and metadata to be systematically incorporated into the model with alternative ways to calculate the likelihood function and (ii) allow sensitive selection of biologically meaningful biochemical reaction databases as Dirichlet-categorical prior distribution. Additionally, to ensure result interpretation by system biologists, we display the annotation in a network where observed mass peaks are connected if their candidate metabolites are substrate/product of known biochemical reactions. This graph can be overlaid with other graph-based analysis, such as partial correlation networks, in a visualization scheme exported to Cytoscap, , with web and stand-alone versions.

Homepage: [http://labpib.fmrp.usp.br/methods/probmetab/](http://labpib.fmrp.usp.br/methods/probmetab/)
GitHUb: [https://github.com/rsilvabioinfo/ProbMetab](https://github.com/rsilvabioinfo/ProbMetab)

Author: Ricardo R. Silva

Citation:

Ricardo R. Silva, Fabien Jourdan, Diego M. Salvanha, Fabien Letisse, Emilien L. Jamin, Simone Guidetti-Gonzalez, Carlos A. Labate and Ricardo Z.N. Vêncio. “ProbMetab: an R package for Bayesian probabilistic annotation of LC-MS based metabolomics”. Bioinformatics (2014) doi: [10.1093/bioinformatics/btu019](http://bioinformatics.oxfordjournals.org/content/30/9/1336)



Galaxy
------
Galaxy is an open, web-based platform for data intensive biomedical research. Whether on the free public server or your own instance, you can perform, reproduce, and share complete analyses. 

Homepage: [https://galaxyproject.org/](https://galaxyproject.org/)


Dependencies using Conda
------------------------
[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/r-probmetab/README.html)

[Conda](http://conda.pydata.org/) is package manager that among many other things can be used to manage Python packages.


```
#To install miniconda2
#http://conda.pydata.org/miniconda.html
#To install the xcms R library using conda:
conda install r-snow r-probmetab==1.0 r-batch
#To set an environment:
conda create -n r-probmetab r-snow r-probmetab==1.0 r-batch`
#To activate the environment:
. activate r-probmetab
```

Travis
------
[![Build Status](https://travis-ci.org/workflow4metabolomics/probmetab.svg?branch=master)](https://travis-ci.org/workflow4metabolomics/probmetab)

Test and Deploy with Confidence. Easily sync your GitHub projects with Travis CI and you'll be testing your code in minutes!

Test Status
-----------

Planemo test using conda: passed

Planemo shed_test: not tested


Historic contributors
---------------------
 - Misharl Monsoor @mmonsoor - [ABiMS](http://abims.sb-roscoff.fr/) / [IFB](http://www.france-bioinformatique.fr/) - [CNRS](www.cnrs.fr)/[UPMC](www.upmc.fr) - [Station Biologique de Roscoff](http://www.sb-roscoff.fr/) - France
 - Yann Guitton @yguitton - [LABERCA - Laboratory of Food Contaminants and Residue Analysis](http://www.laberca.org/) - Ecole Nationale Vétérinaire, Agroalimentaire et de l'Alimentation Nantes-Atlantique - France
 - Jean-François Martin - [French Metabolomics and Fluxomics Infrastructure (MetaboHUB)](http://www.metabohub.fr/en) - [MetaToul](http://www.metatoul.fr/)
 - Gildas Le Corguillé @lecorguille - [ABiMS](http://abims.sb-roscoff.fr/) / [IFB](http://www.france-bioinformatique.fr/) - [UPMC](www.upmc.fr)/[CNRS](www.cnrs.fr) - [Station Biologique de Roscoff](http://www.sb-roscoff.fr/) - France

