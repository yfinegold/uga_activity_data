### Degradation in Uganda

25 Feb - 1 March 2019
Entebbe, Uganda

The scripts in this repository should be run in SEPAL (https://sepal.io)

### How to run the processing chain
In SEPAL, open a terminal and start an instance #2

Clone the repository with the following command:

``` git clone https://github.com/yfinegold/uga_degradation ```

Open another SEPAL tab, go to the Process tab and click on RStudio and under the directory, "uga_degradation" in your root folder open and ``` source()``` the following scripts:

##### download_data.R
This script needs to be ONCE to download the data needed for the following exercises 

##### s1_threshold.R
This script creates a mask from tropical high forest and generates an automatic thresholded output from BFAST results
