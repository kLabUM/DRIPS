## A self-calibrating framework for the sensor-driven and dynamical modeling of combined sewer systems
Sara C. Troutman, Nathaniel Schambach, Nancy G. Love, Branko Kerkez

Publication DOI: [10.1016/j.watres.2017.08.065](https://doi.org/10.1016/j.watres.2017.08.065)

The recent availability and affordability of sensors and wireless communications is poised to transform our understanding and management of water systems.
This will enable a new generation of adaptive water models that can ingest large quantities of sensor feeds and provide the best possible estimates of current and future conditions.
To that end, this paper presents a novel sensor-driven identification/learning framework for combined sewer and stormwater systems.
The framework uses Gaussian Processes to model dry-weather flows (domestic wastewater) and dynamical System Identification to represent wet-weather flows (rainfall runoff).
By using a large and high-resolution sensor data set across a real-world combined sewer system, we illustrate that relatively simple models can achieve good forecasting performance, subject to a finely-tuned and continuous re-calibration procedure.
The data requirements of the proposed framework are evaluated, showing sensitivity to spatial heterogeneity and unique time-scales across which individuals sites remain statistically stationary.
We identify a near-optimal time record, or data "age," for which historical measurements must be available to ensure good forecasting performance.
We also show that more data do not always lead to a better model due to non-stationarity, such as shifts in climate or seasonal wastewater patterns.
Furthermore, the individual components of the model (wet- and dry-weather) often require different volumes of historical observations for optimal forecasting performance, thus highlighting the need for a flexible re-calibration framework rather than a one-size-fits-all approach. 

#### How to read
1. Obtain and save historical/training and predicting/testing data. An example is provided in Examples.zip.
   1. Data should be saved in folder ./Examples/ with names Site[site number]_hist.mat and Site[site number]_pred.mat, respectively.
2. Run initializeHyperparams.m to learn and save Gaussian Process hyperparameters.
   1. In User inputs section, enter Site number and sensor sampling frequency (Fs) of historical/training data.
   2. In User inputs section, enter diurnal_lookback length for dry-weather Gaussian Process training and testfolder for saving learned hyperparameters (this and prediction results will be saved in ./Data/Site[Site][testfolder]/).
   3. In User inputs section, set initial Threshold criteria for diurnal patterns: slope (trough-to-trough), timeSlack (length of diurnal patterns), stdMax (maximum diurnal pattern standard deviation), stdMin (minimum diurnal pattern standard deviation).
   4. In User inputs section, pick starti to be the starting index for dry-weather training data; this should be the beginning of a largely dry-weather timeperiod.
   5. Run initializeHyperparams.m.
   6. Matlab execution will pause and display Figure 1, containing filtered raw data, all diurnal (band-pass) filtered data, good diurnal patterns (those that meet threshold criteria), and good diurnal patterns that are within the specified lookback length, beginning with the specified start index.
   7. Visually confirm that the good diurnal patterns are satisfactory (i.e., do not contain diurnal patterns distorted by wet-weather).
      1. Adjust the threshold criteria as needed (more strict: decrease slope, decrease timeSlack, decrease stdMax, increase stdMin).
      2. Adjust the start index as needed to include a largely dry-weather timeperiod.
   8. Once good diurnal patterns are satisfactory, continue the paused Matlab execution to learn the Gaussian Process hyperparameters. There will be 100 function evaluations and this may take a while. If hyperparameters are determined to remain stationary for the provided data, this procedure can be performed infrequently (e.g., annually).
   9. Once Matlab is done executing, the hyperparameters and threshold criteria will be saved in ./Data/Site[site number][testfolder]/ as HypInit[site number].mat. Figure 1 will display the predicted dry-weather diurnal pattern for the select dry-weather timeperiod (results). Visually confirm satisfactory fit; otherwise, repeat process with adjusted threshold criteria.
3. Run main.m to make dry-weather and wet-weather flow predictions for predicting/testing data.
   1. In User inputs section, enter Site number and sensor sampling frequency (Fs) of data (this should be the same for historical/training and predicting/testing data).
   2. In User inputs section, enter TestFolder for saving prediction results (prediction results will be saved in ./Data/Site[Site][TestFolder]/).
   3. In User inputs section, enter diurnal_lookback length for dry-weather Gaussian Process training and hydro_lookback for wet-weather System Identification learning.
   4. In User inputs section, set reconstruct (1: combine dry-weather and wet-weather predictions; 0: wet-weather predictions only) for plotting and fit evaluation.
   5. In User inputs section, set plotem (1: plot measurements and predicted results; 0: do not plot).
   6. Run main.m.
   7. Historical/training and predicting/testing storm events will be saved in respective folders under ./Data/Site[site number][TestFolder]/. Prediction results will be saved under ./Data/Site[site number][TestFolder]/Pred/SID_[hydro_lookback]mo/. If plotem=1, figures of each predicting/testing storm measurements and predictions will be saved in ./Data/Site[site number][TestFolder]/Pred/ResultPlots/.
