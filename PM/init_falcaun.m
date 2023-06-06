%% Init Script for the pacemaker model

%% Load the pacemaker model
mdl = 'Model1_Scenario1_Correct'
load_system(mdl);

% The initial pacing conditions in the Simulink model are used.
init_cond = []; 

