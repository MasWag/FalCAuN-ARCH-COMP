%% Init Script for the Automatic transmission  model
% We use the automatic transmission model in [Hoxha et al.,
% ARCH@CPSWeek 2014].

%% Load the AFC model
mdl = 'AbstractFuelControl_M1';
load_system(mdl);

%% Specify the model parameters
simTime        = 50;
measureTime    =  1;
fault_time     = 60;
spec_num       =  1;
fuel_inj_tol   =  1;
MAF_sensor_tol =  1;
AF_sensor_tol  =  1;