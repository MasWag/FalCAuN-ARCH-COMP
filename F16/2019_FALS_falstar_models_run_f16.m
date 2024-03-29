function result = run_f16(u, T)
    model_err = false;
    analysisOn = false;
    printOn = false;
    plotOn = false;
    backCalculateBestSamp = false;

    powg = 9;                   % Power
    % Default alpha & beta
    alphag = deg2rad(2.1215);   % Trim Angle of Attack (rad)
    betag = 0;                  % Side slip angle (rad)

    % Initial Attitude (for simpleGCAS)
    altg   = evalin('base', 'altg');
    Vtg    = evalin('base', 'Vtg');
    phig   = evalin('base', 'phig');
    thetag = evalin('base', 'thetag');
    psig   = evalin('base', 'psig');
    t_vec = 0:0.01:T;

    % Set Flight & Ctrl Limits (for pass-fail conditions)
    [flightLimits,ctrlLimits,autopilot] = getDefaultSettings();
    ctrlLimits.ThrottleMax = 0.7;   % Limit to Mil power (no afterburner)
    autopilot.simpleGCAS = true;    % Run GCAS simulation

    % Build Initial Condition Vectors
    initialState = [Vtg alphag betag phig thetag psig 0 0 0 0 0 altg powg];
    orient = 4;             % Orientation for trim

    % Select Desired F-16 Plant
    % Table Lookup
    [output, passFail] = RunF16Sim(initialState, t_vec, orient, 'stevens',...
        flightLimits, ctrlLimits, autopilot, printOn, plotOn);

	result.tout = t_vec;
	result.yout = output(12,:);
end
